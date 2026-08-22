# What the defaults do, per machine zone

Recorded by `run-defaults.sh`; `README.md` says what the columns
mean. `rel` is `rel_from_df()` then `rel_to_altrep()`; `dbi` is
`dbWriteTable()` then `dbReadTable()`. Nothing calls `SET TimeZone`.

## shipped

```
   policy  TZ  col              tz_out           session rel       rel_back         dbi       dbi_back
1  shipped UTC UTC              UTC              UTC     ok        UTC              ok        UTC     
2  shipped UTC <empty>          UTC              UTC     refused   <NA>             relabeled UTC     
3  shipped UTC <absent>         UTC              UTC     refused   <NA>             relabeled UTC     
4  shipped UTC America/New_York UTC              UTC     refused   <NA>             relabeled UTC     
5  shipped UTC UTC              <empty>          UTC     refused   <NA>             ok        UTC     
6  shipped UTC <empty>          <empty>          UTC     relabeled <absent>         relabeled UTC     
7  shipped UTC <absent>         <empty>          UTC     ok        <absent>         relabeled UTC     
8  shipped UTC America/New_York <empty>          UTC     refused   <NA>             relabeled UTC     
9  shipped UTC UTC              America/New_York UTC     refused   <NA>             ok        UTC     
10 shipped UTC <empty>          America/New_York UTC     refused   <NA>             relabeled UTC     
11 shipped UTC <absent>         America/New_York UTC     refused   <NA>             relabeled UTC     
12 shipped UTC America/New_York America/New_York UTC     ok        America/New_York relabeled UTC     
   policy  TZ      col              tz_out           session rel       rel_back         dbi       dbi_back
1  shipped Etc/UTC UTC              UTC              Etc/UTC ok        UTC              relabeled Etc/UTC 
2  shipped Etc/UTC <empty>          UTC              Etc/UTC refused   <NA>             relabeled Etc/UTC 
3  shipped Etc/UTC <absent>         UTC              Etc/UTC refused   <NA>             relabeled Etc/UTC 
4  shipped Etc/UTC America/New_York UTC              Etc/UTC refused   <NA>             relabeled Etc/UTC 
5  shipped Etc/UTC UTC              <empty>          Etc/UTC refused   <NA>             relabeled Etc/UTC 
6  shipped Etc/UTC <empty>          <empty>          Etc/UTC relabeled <absent>         relabeled Etc/UTC 
7  shipped Etc/UTC <absent>         <empty>          Etc/UTC ok        <absent>         relabeled Etc/UTC 
8  shipped Etc/UTC America/New_York <empty>          Etc/UTC refused   <NA>             relabeled Etc/UTC 
9  shipped Etc/UTC UTC              America/New_York Etc/UTC refused   <NA>             relabeled Etc/UTC 
10 shipped Etc/UTC <empty>          America/New_York Etc/UTC refused   <NA>             relabeled Etc/UTC 
11 shipped Etc/UTC <absent>         America/New_York Etc/UTC refused   <NA>             relabeled Etc/UTC 
12 shipped Etc/UTC America/New_York America/New_York Etc/UTC ok        America/New_York relabeled Etc/UTC 
   policy  TZ            col              tz_out           session       rel       rel_back         dbi       dbi_back     
1  shipped Europe/Zurich UTC              UTC              Europe/Zurich ok        UTC              relabeled Europe/Zurich
2  shipped Europe/Zurich <empty>          UTC              Europe/Zurich refused   <NA>             relabeled Europe/Zurich
3  shipped Europe/Zurich <absent>         UTC              Europe/Zurich refused   <NA>             relabeled Europe/Zurich
4  shipped Europe/Zurich America/New_York UTC              Europe/Zurich refused   <NA>             relabeled Europe/Zurich
5  shipped Europe/Zurich UTC              <empty>          Europe/Zurich refused   <NA>             relabeled Europe/Zurich
6  shipped Europe/Zurich <empty>          <empty>          Europe/Zurich relabeled <absent>         relabeled Europe/Zurich
7  shipped Europe/Zurich <absent>         <empty>          Europe/Zurich ok        <absent>         relabeled Europe/Zurich
8  shipped Europe/Zurich America/New_York <empty>          Europe/Zurich refused   <NA>             relabeled Europe/Zurich
9  shipped Europe/Zurich UTC              America/New_York Europe/Zurich refused   <NA>             relabeled Europe/Zurich
10 shipped Europe/Zurich <empty>          America/New_York Europe/Zurich refused   <NA>             relabeled Europe/Zurich
11 shipped Europe/Zurich <absent>         America/New_York Europe/Zurich refused   <NA>             relabeled Europe/Zurich
12 shipped Europe/Zurich America/New_York America/New_York Europe/Zurich ok        America/New_York relabeled Europe/Zurich
```

## pin-session

```
   policy      TZ  col              tz_out           session          rel       rel_back         dbi       dbi_back        
1  pin-session UTC UTC              UTC              UTC              ok        UTC              ok        UTC             
2  pin-session UTC <empty>          UTC              UTC              refused   <NA>             relabeled UTC             
3  pin-session UTC <absent>         UTC              UTC              refused   <NA>             relabeled UTC             
4  pin-session UTC America/New_York UTC              UTC              refused   <NA>             relabeled UTC             
5  pin-session UTC UTC              <empty>          UTC              refused   <NA>             ok        UTC             
6  pin-session UTC <empty>          <empty>          UTC              relabeled UTC              relabeled UTC             
7  pin-session UTC <absent>         <empty>          UTC              relabeled UTC              relabeled UTC             
8  pin-session UTC America/New_York <empty>          UTC              refused   <NA>             relabeled UTC             
9  pin-session UTC UTC              America/New_York America/New_York refused   <NA>             relabeled America/New_York
10 pin-session UTC <empty>          America/New_York America/New_York refused   <NA>             relabeled America/New_York
11 pin-session UTC <absent>         America/New_York America/New_York refused   <NA>             relabeled America/New_York
12 pin-session UTC America/New_York America/New_York America/New_York ok        America/New_York ok        America/New_York
   policy      TZ      col              tz_out           session          rel       rel_back         dbi       dbi_back        
1  pin-session Etc/UTC UTC              UTC              UTC              ok        UTC              ok        UTC             
2  pin-session Etc/UTC <empty>          UTC              UTC              refused   <NA>             relabeled UTC             
3  pin-session Etc/UTC <absent>         UTC              UTC              refused   <NA>             relabeled UTC             
4  pin-session Etc/UTC America/New_York UTC              UTC              refused   <NA>             relabeled UTC             
5  pin-session Etc/UTC UTC              <empty>          Etc/UTC          refused   <NA>             relabeled Etc/UTC         
6  pin-session Etc/UTC <empty>          <empty>          Etc/UTC          relabeled Etc/UTC          relabeled Etc/UTC         
7  pin-session Etc/UTC <absent>         <empty>          Etc/UTC          relabeled Etc/UTC          relabeled Etc/UTC         
8  pin-session Etc/UTC America/New_York <empty>          Etc/UTC          refused   <NA>             relabeled Etc/UTC         
9  pin-session Etc/UTC UTC              America/New_York America/New_York refused   <NA>             relabeled America/New_York
10 pin-session Etc/UTC <empty>          America/New_York America/New_York refused   <NA>             relabeled America/New_York
11 pin-session Etc/UTC <absent>         America/New_York America/New_York refused   <NA>             relabeled America/New_York
12 pin-session Etc/UTC America/New_York America/New_York America/New_York ok        America/New_York ok        America/New_York
   policy      TZ            col              tz_out           session          rel       rel_back         dbi       dbi_back        
1  pin-session Europe/Zurich UTC              UTC              UTC              ok        UTC              ok        UTC             
2  pin-session Europe/Zurich <empty>          UTC              UTC              refused   <NA>             relabeled UTC             
3  pin-session Europe/Zurich <absent>         UTC              UTC              refused   <NA>             relabeled UTC             
4  pin-session Europe/Zurich America/New_York UTC              UTC              refused   <NA>             relabeled UTC             
5  pin-session Europe/Zurich UTC              <empty>          Europe/Zurich    refused   <NA>             relabeled Europe/Zurich   
6  pin-session Europe/Zurich <empty>          <empty>          Europe/Zurich    relabeled Europe/Zurich    relabeled Europe/Zurich   
7  pin-session Europe/Zurich <absent>         <empty>          Europe/Zurich    relabeled Europe/Zurich    relabeled Europe/Zurich   
8  pin-session Europe/Zurich America/New_York <empty>          Europe/Zurich    refused   <NA>             relabeled Europe/Zurich   
9  pin-session Europe/Zurich UTC              America/New_York America/New_York refused   <NA>             relabeled America/New_York
10 pin-session Europe/Zurich <empty>          America/New_York America/New_York refused   <NA>             relabeled America/New_York
11 pin-session Europe/Zurich <absent>         America/New_York America/New_York refused   <NA>             relabeled America/New_York
12 pin-session Europe/Zurich America/New_York America/New_York America/New_York ok        America/New_York ok        America/New_York
```
