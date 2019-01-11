defaults:
  timer_type: histogram
  buckets: [.005, .01, .025, .05, .1, .25, .5, 1, 2.5 ]
  match_type: glob
  glob_disable_ordering: false
  ttl: 0 # metrics do not expire
