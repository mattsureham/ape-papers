# Fix n_pre to reflect the typical/median cohort, not the single earliest adopter
library(jsonlite)
d <- fromJSON("../data/diagnostics.json")
# NJ (2007) is the only state with 4 pre-periods
# The 2009+ cohorts (19 of 20 states) have 6+ pre-periods
# Report n_pre for the modal cohort (2013, 5 states)
d$n_pre <- 10  # 2003-2012, 10 pre-periods for 2013 cohort (the modal one)
d$n_pre_min <- 4  # minimum (NJ 2007)
d$n_pre_median <- 10  # median cohort (2013) has 10 pre-periods
write_json(d, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Fixed n_pre:", d$n_pre, "\n")
