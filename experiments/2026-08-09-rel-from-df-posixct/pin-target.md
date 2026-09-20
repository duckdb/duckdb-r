# Which zone the alignment names

Recorded by `pin-target.R`; `README.md` says what it asks.

```
machine TZ = America/New_York 
session as opened (UTC), tz_out=UTC      naive ok    (label UTC             ) | tz ok    (label UTC)
session as opened (UTC), tz_out=NY       naive ok    (label America/New_York) | tz ok    (label UTC)
session set to timezone_out, tz_out=NY   naive MOVED (label America/New_York) | tz ok    (label America/New_York)
session set to the machine zone, tz_out=UTC naive MOVED (label UTC             ) | tz ok    (label America/New_York)
```
