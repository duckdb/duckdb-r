// The ingest scenarios, Go side (duckdb-go v2): one scenario per process, one CSV line out.
// Built with -tags=duckdb_arrow so the Arrow view route is compiled in.
package main

import (
	"bufio"
	"context"
	"database/sql"
	"database/sql/driver"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/apache/arrow-go/v18/arrow"
	"github.com/apache/arrow-go/v18/arrow/array"
	"github.com/apache/arrow-go/v18/arrow/memory"
	"github.com/duckdb/duckdb-go/v2"
)

// ROWS scales the data: 50 million rows of two doubles are 800 MB.
var N = func() int {
	if v, err := strconv.Atoi(os.Getenv("ROWS")); err == nil && v > 0 {
		return v
	}
	return 50_000_000
}()

func stat(key string) int {
	f, _ := os.Open("/proc/self/status")
	defer f.Close()
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		if strings.HasPrefix(sc.Text(), key) {
			kb, _ := strconv.ParseFloat(strings.Fields(sc.Text())[1], 64)
			return int(kb / 1024)
		}
	}
	return 0
}

// genReader yields ROWS / 1e6 batches of a million rows, generated as they are pulled.
type genReader struct {
	schema *arrow.Schema
	i, n   int
	rec    arrow.Record
}

func (r *genReader) Retain()                        {}
func (r *genReader) Release()                       {}
func (r *genReader) Schema() *arrow.Schema          { return r.schema }
func (r *genReader) Err() error                     { return nil }
func (r *genReader) Record() arrow.Record           { return r.rec }
func (r *genReader) RecordBatch() arrow.RecordBatch { return r.rec }
func (r *genReader) Next() bool {
	if r.i >= r.n {
		return false
	}
	const m = 1_000_000
	a := make([]float64, m)
	b := make([]float64, m)
	for k := 0; k < m; k++ {
		a[k] = float64(r.i*m + k)
		b[k] = 2 * a[k]
	}
	ab := array.NewFloat64Data(array.NewData(arrow.PrimitiveTypes.Float64, m, []*memory.Buffer{nil, memory.NewBufferBytes(arrow.Float64Traits.CastToBytes(a))}, nil, 0, 0))
	bb := array.NewFloat64Data(array.NewData(arrow.PrimitiveTypes.Float64, m, []*memory.Buffer{nil, memory.NewBufferBytes(arrow.Float64Traits.CastToBytes(b))}, nil, 0, 0))
	r.rec = array.NewRecord(r.schema, []arrow.Array{ab, bb}, int64(m))
	r.i++
	return true
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	image, target, scenario := os.Args[1], os.Args[2], os.Args[3]
	dsn := ""
	if target == "file" {
		dsn = fmt.Sprintf("/tmp/ingest-%d.duckdb", os.Getpid())
	}
	c, err := duckdb.NewConnector(dsn, nil)
	must(err)
	con, err := c.Connect(context.Background())
	must(err)
	db := sql.OpenDB(c)
	exec := func(q string) {
		_, err := con.(driver.ExecerContext).ExecContext(context.Background(), q, nil)
		must(err)
	}
	exec("SET memory_limit = '300MB'")
	count := func() int {
		var n int
		must(db.QueryRow("SELECT count(*) FROM t").Scan(&n))
		return n
	}
	var base int
	var t0 time.Time
	start := func() { os.WriteFile("/proc/self/clear_refs", []byte("5"), 0); base = stat("VmRSS"); t0 = time.Now() }
	rows := 0
	switch scenario {
	case "stream_appender_rows":
		exec("CREATE TABLE t (a DOUBLE, b DOUBLE)")
		start()
		app, err := duckdb.NewAppenderFromConn(con, "", "t")
		must(err)
		for i := 0; i < N; i++ {
			must(app.AppendRow(float64(i), float64(2*i)))
		}
		must(app.Close())
		rows = count()
	case "frame_slices_appender":
		a := make([]float64, N)
		b := make([]float64, N)
		for i := range a {
			a[i] = float64(i)
			b[i] = float64(2 * i)
		}
		exec("CREATE TABLE t (a DOUBLE, b DOUBLE)")
		start()
		app, err := duckdb.NewAppenderFromConn(con, "", "t")
		must(err)
		for i := range a {
			must(app.AppendRow(a[i], b[i]))
		}
		must(app.Close())
		rows = count()
	case "stream_arrow_view":
		start()
		ar, err := duckdb.NewArrowFromConn(con)
		must(err)
		schema := arrow.NewSchema([]arrow.Field{{Name: "a", Type: arrow.PrimitiveTypes.Float64}, {Name: "b", Type: arrow.PrimitiveTypes.Float64}}, nil)
		release, err := ar.RegisterView(&genReader{schema: schema, n: N / 1_000_000}, "src")
		must(err)
		exec("CREATE TABLE t AS SELECT a, b FROM src")
		release()
		rows = count()
	case "stream_stdin_csv":
		exec("CREATE TABLE t (a DOUBLE, b DOUBLE)")
		start()
		exec("COPY t FROM '/dev/stdin' (FORMAT CSV, HEADER false)")
		rows = count()
	case "file_read_parquet":
		start()
		exec("CREATE TABLE t AS SELECT a, b FROM read_parquet('/data/src.parquet')")
		rows = count()
	case "file_read_csv":
		start()
		exec("CREATE TABLE t AS SELECT a, b FROM read_csv('/data/src.csv')")
		rows = count()
	case "engine_generate":
		start()
		exec(fmt.Sprintf("CREATE TABLE t AS SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(%d) t(i)", N))
		rows = count()
	default:
		panic("unknown scenario " + scenario)
	}
	peak := stat("VmHWM")
	fmt.Printf("go,%s,%s,%s,%d,%d,%d,%d,%.1f\n", image, scenario, target, rows, base, peak, peak-base, time.Since(t0).Seconds())
}
