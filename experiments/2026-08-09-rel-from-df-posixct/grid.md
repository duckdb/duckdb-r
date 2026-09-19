# `rel_from_df()` POSIXct grid

Recorded by `run.sh`; what each column means is in `README.md`.

## default session zone

Which grid row a user lands in without `SET TimeZone`, per machine
zone. One process each: icu reads the zone once, when it loads.

```
TZ=UTC                session UTC                ts label UTC      tstz label UTC
TZ=Etc/UTC            session Etc/UTC            ts label UTC      tstz label Etc/UTC
TZ=Europe/Zurich      session Europe/Zurich      ts label UTC      tstz label Europe/Zurich
TZ=America/New_York   session America/New_York   ts label UTC      tstz label America/New_York
TZ=Asia/Tokyo         session Asia/Tokyo         ts label UTC      tstz label Asia/Tokyo
```

## baseline

```
policy baseline | duckdb 1.5.5.9013 | DuckDB 1.5.5 | local zone Etc/UTC 

   policy   col              tz_out           session          verdict   back            
1  baseline UTC              UTC              UTC              ok        UTC             
2  baseline <empty>          UTC              UTC              refused   <NA>            
3  baseline <absent>         UTC              UTC              refused   <NA>            
4  baseline America/New_York UTC              UTC              refused   <NA>            
5  baseline UTC              <empty>          UTC              refused   <NA>            
6  baseline <empty>          <empty>          UTC              relabeled <absent>        
7  baseline <absent>         <empty>          UTC              ok        <absent>        
8  baseline America/New_York <empty>          UTC              refused   <NA>            
9  baseline UTC              America/New_York UTC              refused   <NA>            
10 baseline <empty>          America/New_York UTC              refused   <NA>            
11 baseline <absent>         America/New_York UTC              refused   <NA>            
12 baseline America/New_York America/New_York UTC              ok        America/New_York
13 baseline UTC              UTC              Etc/UTC          ok        UTC             
14 baseline <empty>          UTC              Etc/UTC          refused   <NA>            
15 baseline <absent>         UTC              Etc/UTC          refused   <NA>            
16 baseline America/New_York UTC              Etc/UTC          refused   <NA>            
17 baseline UTC              <empty>          Etc/UTC          refused   <NA>            
18 baseline <empty>          <empty>          Etc/UTC          relabeled <absent>        
19 baseline <absent>         <empty>          Etc/UTC          ok        <absent>        
20 baseline America/New_York <empty>          Etc/UTC          refused   <NA>            
21 baseline UTC              America/New_York Etc/UTC          refused   <NA>            
22 baseline <empty>          America/New_York Etc/UTC          refused   <NA>            
23 baseline <absent>         America/New_York Etc/UTC          refused   <NA>            
24 baseline America/New_York America/New_York Etc/UTC          ok        America/New_York
25 baseline UTC              UTC              America/New_York ok        UTC             
26 baseline <empty>          UTC              America/New_York refused   <NA>            
27 baseline <absent>         UTC              America/New_York refused   <NA>            
28 baseline America/New_York UTC              America/New_York refused   <NA>            
29 baseline UTC              <empty>          America/New_York refused   <NA>            
30 baseline <empty>          <empty>          America/New_York relabeled <absent>        
31 baseline <absent>         <empty>          America/New_York ok        <absent>        
32 baseline America/New_York <empty>          America/New_York refused   <NA>            
33 baseline UTC              America/New_York America/New_York refused   <NA>            
34 baseline <empty>          America/New_York America/New_York refused   <NA>            
35 baseline <absent>         America/New_York America/New_York refused   <NA>            
36 baseline America/New_York America/New_York America/New_York ok        America/New_York

tally:

       ok   refused relabeled 
        9        24         3 
```

## timestamp-rel

```
policy timestamp-rel | duckdb 1.5.5.9013 | DuckDB 1.5.5 | local zone Etc/UTC 

   policy        col              tz_out           session          verdict   back            
1  timestamp-rel UTC              UTC              UTC              ok        UTC             
2  timestamp-rel <empty>          UTC              UTC              refused   <NA>            
3  timestamp-rel <absent>         UTC              UTC              refused   <NA>            
4  timestamp-rel America/New_York UTC              UTC              refused   <NA>            
5  timestamp-rel UTC              <empty>          UTC              refused   <NA>            
6  timestamp-rel <empty>          <empty>          UTC              relabeled <absent>        
7  timestamp-rel <absent>         <empty>          UTC              ok        <absent>        
8  timestamp-rel America/New_York <empty>          UTC              refused   <NA>            
9  timestamp-rel UTC              America/New_York UTC              refused   <NA>            
10 timestamp-rel <empty>          America/New_York UTC              refused   <NA>            
11 timestamp-rel <absent>         America/New_York UTC              refused   <NA>            
12 timestamp-rel America/New_York America/New_York UTC              ok        America/New_York
13 timestamp-rel UTC              UTC              Etc/UTC          ok        UTC             
14 timestamp-rel <empty>          UTC              Etc/UTC          refused   <NA>            
15 timestamp-rel <absent>         UTC              Etc/UTC          refused   <NA>            
16 timestamp-rel America/New_York UTC              Etc/UTC          refused   <NA>            
17 timestamp-rel UTC              <empty>          Etc/UTC          refused   <NA>            
18 timestamp-rel <empty>          <empty>          Etc/UTC          relabeled <absent>        
19 timestamp-rel <absent>         <empty>          Etc/UTC          ok        <absent>        
20 timestamp-rel America/New_York <empty>          Etc/UTC          refused   <NA>            
21 timestamp-rel UTC              America/New_York Etc/UTC          refused   <NA>            
22 timestamp-rel <empty>          America/New_York Etc/UTC          refused   <NA>            
23 timestamp-rel <absent>         America/New_York Etc/UTC          refused   <NA>            
24 timestamp-rel America/New_York America/New_York Etc/UTC          ok        America/New_York
25 timestamp-rel UTC              UTC              America/New_York ok        UTC             
26 timestamp-rel <empty>          UTC              America/New_York refused   <NA>            
27 timestamp-rel <absent>         UTC              America/New_York refused   <NA>            
28 timestamp-rel America/New_York UTC              America/New_York refused   <NA>            
29 timestamp-rel UTC              <empty>          America/New_York refused   <NA>            
30 timestamp-rel <empty>          <empty>          America/New_York relabeled <absent>        
31 timestamp-rel <absent>         <empty>          America/New_York ok        <absent>        
32 timestamp-rel America/New_York <empty>          America/New_York refused   <NA>            
33 timestamp-rel UTC              America/New_York America/New_York refused   <NA>            
34 timestamp-rel <empty>          America/New_York America/New_York refused   <NA>            
35 timestamp-rel <absent>         America/New_York America/New_York refused   <NA>            
36 timestamp-rel America/New_York America/New_York America/New_York ok        America/New_York

tally:

       ok   refused relabeled 
        9        24         3 
```

## follow

```
policy follow | duckdb 1.5.5.9013 | DuckDB 1.5.5 | local zone Etc/UTC 

   policy col              tz_out           session          verdict   back            
1  follow UTC              UTC              UTC              ok        UTC             
2  follow <empty>          UTC              UTC              refused   <NA>            
3  follow <absent>         UTC              UTC              refused   <NA>            
4  follow America/New_York UTC              UTC              refused   <NA>            
5  follow UTC              <empty>          UTC              refused   <NA>            
6  follow <empty>          <empty>          UTC              relabeled UTC             
7  follow <absent>         <empty>          UTC              relabeled UTC             
8  follow America/New_York <empty>          UTC              refused   <NA>            
9  follow UTC              America/New_York UTC              refused   <NA>            
10 follow <empty>          America/New_York UTC              refused   <NA>            
11 follow <absent>         America/New_York UTC              refused   <NA>            
12 follow America/New_York America/New_York UTC              relabeled UTC             
13 follow UTC              UTC              Etc/UTC          relabeled Etc/UTC         
14 follow <empty>          UTC              Etc/UTC          refused   <NA>            
15 follow <absent>         UTC              Etc/UTC          refused   <NA>            
16 follow America/New_York UTC              Etc/UTC          refused   <NA>            
17 follow UTC              <empty>          Etc/UTC          refused   <NA>            
18 follow <empty>          <empty>          Etc/UTC          relabeled Etc/UTC         
19 follow <absent>         <empty>          Etc/UTC          relabeled Etc/UTC         
20 follow America/New_York <empty>          Etc/UTC          refused   <NA>            
21 follow UTC              America/New_York Etc/UTC          refused   <NA>            
22 follow <empty>          America/New_York Etc/UTC          refused   <NA>            
23 follow <absent>         America/New_York Etc/UTC          refused   <NA>            
24 follow America/New_York America/New_York Etc/UTC          relabeled Etc/UTC         
25 follow UTC              UTC              America/New_York relabeled America/New_York
26 follow <empty>          UTC              America/New_York refused   <NA>            
27 follow <absent>         UTC              America/New_York refused   <NA>            
28 follow America/New_York UTC              America/New_York refused   <NA>            
29 follow UTC              <empty>          America/New_York refused   <NA>            
30 follow <empty>          <empty>          America/New_York relabeled America/New_York
31 follow <absent>         <empty>          America/New_York relabeled America/New_York
32 follow America/New_York <empty>          America/New_York refused   <NA>            
33 follow UTC              America/New_York America/New_York refused   <NA>            
34 follow <empty>          America/New_York America/New_York refused   <NA>            
35 follow <absent>         America/New_York America/New_York refused   <NA>            
36 follow America/New_York America/New_York America/New_York ok        America/New_York

tally:

       ok   refused relabeled 
        2        24        10 
```

## session-tz

```
policy session-tz | duckdb 1.5.5.9013 | DuckDB 1.5.5 | local zone Etc/UTC 

   policy     col              tz_out           session          verdict back            
1  session-tz UTC              UTC              UTC              ok      UTC             
2  session-tz <empty>          UTC              UTC              refused <NA>            
3  session-tz <absent>         UTC              UTC              refused <NA>            
4  session-tz America/New_York UTC              UTC              refused <NA>            
5  session-tz UTC              <empty>          UTC              ok      UTC             
6  session-tz <empty>          <empty>          UTC              refused <NA>            
7  session-tz <absent>         <empty>          UTC              refused <NA>            
8  session-tz America/New_York <empty>          UTC              refused <NA>            
9  session-tz UTC              America/New_York UTC              ok      UTC             
10 session-tz <empty>          America/New_York UTC              refused <NA>            
11 session-tz <absent>         America/New_York UTC              refused <NA>            
12 session-tz America/New_York America/New_York UTC              refused <NA>            
13 session-tz UTC              UTC              Etc/UTC          refused <NA>            
14 session-tz <empty>          UTC              Etc/UTC          refused <NA>            
15 session-tz <absent>         UTC              Etc/UTC          refused <NA>            
16 session-tz America/New_York UTC              Etc/UTC          refused <NA>            
17 session-tz UTC              <empty>          Etc/UTC          refused <NA>            
18 session-tz <empty>          <empty>          Etc/UTC          refused <NA>            
19 session-tz <absent>         <empty>          Etc/UTC          refused <NA>            
20 session-tz America/New_York <empty>          Etc/UTC          refused <NA>            
21 session-tz UTC              America/New_York Etc/UTC          refused <NA>            
22 session-tz <empty>          America/New_York Etc/UTC          refused <NA>            
23 session-tz <absent>         America/New_York Etc/UTC          refused <NA>            
24 session-tz America/New_York America/New_York Etc/UTC          refused <NA>            
25 session-tz UTC              UTC              America/New_York refused <NA>            
26 session-tz <empty>          UTC              America/New_York refused <NA>            
27 session-tz <absent>         UTC              America/New_York refused <NA>            
28 session-tz America/New_York UTC              America/New_York ok      America/New_York
29 session-tz UTC              <empty>          America/New_York refused <NA>            
30 session-tz <empty>          <empty>          America/New_York refused <NA>            
31 session-tz <absent>         <empty>          America/New_York refused <NA>            
32 session-tz America/New_York <empty>          America/New_York ok      America/New_York
33 session-tz UTC              America/New_York America/New_York refused <NA>            
34 session-tz <empty>          America/New_York America/New_York refused <NA>            
35 session-tz <absent>         America/New_York America/New_York refused <NA>            
36 session-tz America/New_York America/New_York America/New_York ok      America/New_York

tally:

     ok refused 
      6      30 
```

## relaxed

```
policy relaxed | duckdb 1.5.5.9013 | DuckDB 1.5.5 | local zone Etc/UTC 

   policy  col              tz_out           session          verdict   back            
1  relaxed UTC              UTC              UTC              ok        UTC             
2  relaxed <empty>          UTC              UTC              relabeled UTC             
3  relaxed <absent>         UTC              UTC              relabeled UTC             
4  relaxed America/New_York UTC              UTC              relabeled UTC             
5  relaxed UTC              <empty>          UTC              ok        UTC             
6  relaxed <empty>          <empty>          UTC              relabeled UTC             
7  relaxed <absent>         <empty>          UTC              relabeled UTC             
8  relaxed America/New_York <empty>          UTC              relabeled UTC             
9  relaxed UTC              America/New_York UTC              ok        UTC             
10 relaxed <empty>          America/New_York UTC              relabeled UTC             
11 relaxed <absent>         America/New_York UTC              relabeled UTC             
12 relaxed America/New_York America/New_York UTC              relabeled UTC             
13 relaxed UTC              UTC              Etc/UTC          relabeled Etc/UTC         
14 relaxed <empty>          UTC              Etc/UTC          relabeled Etc/UTC         
15 relaxed <absent>         UTC              Etc/UTC          relabeled Etc/UTC         
16 relaxed America/New_York UTC              Etc/UTC          relabeled Etc/UTC         
17 relaxed UTC              <empty>          Etc/UTC          relabeled Etc/UTC         
18 relaxed <empty>          <empty>          Etc/UTC          relabeled Etc/UTC         
19 relaxed <absent>         <empty>          Etc/UTC          relabeled Etc/UTC         
20 relaxed America/New_York <empty>          Etc/UTC          relabeled Etc/UTC         
21 relaxed UTC              America/New_York Etc/UTC          relabeled Etc/UTC         
22 relaxed <empty>          America/New_York Etc/UTC          relabeled Etc/UTC         
23 relaxed <absent>         America/New_York Etc/UTC          relabeled Etc/UTC         
24 relaxed America/New_York America/New_York Etc/UTC          relabeled Etc/UTC         
25 relaxed UTC              UTC              America/New_York relabeled America/New_York
26 relaxed <empty>          UTC              America/New_York relabeled America/New_York
27 relaxed <absent>         UTC              America/New_York relabeled America/New_York
28 relaxed America/New_York UTC              America/New_York ok        America/New_York
29 relaxed UTC              <empty>          America/New_York relabeled America/New_York
30 relaxed <empty>          <empty>          America/New_York relabeled America/New_York
31 relaxed <absent>         <empty>          America/New_York relabeled America/New_York
32 relaxed America/New_York <empty>          America/New_York ok        America/New_York
33 relaxed UTC              America/New_York America/New_York relabeled America/New_York
34 relaxed <empty>          America/New_York America/New_York relabeled America/New_York
35 relaxed <absent>         America/New_York America/New_York relabeled America/New_York
36 relaxed America/New_York America/New_York America/New_York ok        America/New_York

tally:

       ok relabeled 
        6        30 
```
