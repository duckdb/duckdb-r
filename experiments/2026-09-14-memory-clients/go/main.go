// The cross-client scenarios, Go side (go-duckdb over database/sql): one scenario per process, one CSV line out.
package main

import (
	"bufio"
	"database/sql"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	_ "github.com/marcboeker/go-duckdb/v2"
)

func peakMB() int {
	f, _ := os.Open("/proc/self/status")
	defer f.Close()
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		if strings.HasPrefix(sc.Text(), "VmHWM") {
			kb, _ := strconv.ParseFloat(strings.Fields(sc.Text())[1], 64)
			return int(kb / 1024)
		}
	}
	return 0
}

func main() {
	image, scenario := os.Args[1], os.Args[2]
	// ROWS scales the result: 50 million rows of two doubles are 800 MB.
	n := 50_000_000
	if v, err := strconv.Atoi(os.Getenv("ROWS")); err == nil && v > 0 {
		n = v
	}
	q := fmt.Sprintf("SELECT i::DOUBLE AS a, (i * 2)::DOUBLE AS b FROM range(%d) t(i)", n)
	qs := fmt.Sprintf("SELECT i::DOUBLE AS a, ((i * 7919) %% 1000003)::DOUBLE AS b FROM range(%d) t(i) ORDER BY b", n)
	db, err := sql.Open("duckdb", "")
	if err != nil {
		panic(err)
	}
	t0 := time.Now()
	rows := 0
	switch scenario {
	case "version":
		var v string
		db.QueryRow("SELECT version()").Scan(&v)
		fmt.Printf("go,%s,version,go-duckdb,%s,\n", image, v)
		return
	case "materialize":
		rs, err := db.Query(q)
		if err != nil {
			panic(err)
		}
		var as, bs []float64
		for rs.Next() {
			var a, b float64
			rs.Scan(&a, &b)
			as = append(as, a)
			bs = append(bs, b)
		}
		rows = len(as)
	case "stream_discard", "stream_sorted_limited":
		query := q
		if scenario == "stream_sorted_limited" {
			db.Exec("SET memory_limit = '200MB'")
			query = qs
		}
		rs, err := db.Query(query)
		if err != nil {
			panic(err)
		}
		for rs.Next() {
			var a, b float64
			rs.Scan(&a, &b)
			rows++
		}
	default:
		panic("unknown scenario " + scenario)
	}
	fmt.Printf("go,%s,%s,%d,%d,%.1f\n", image, scenario, rows, peakMB(), time.Since(t0).Seconds())
}
