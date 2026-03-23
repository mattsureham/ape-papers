# 04_robustness.R — Robustness checks
# apep_0785: Quiet zone designations and property values

source("00_packages.R")

cat("=== Loading data ===\n")
panel_analysis <- readRDS("../data/panel_analysis.rds")
cs_out <- readRDS("../data/cs_results.rds")
agg_es <- readRDS("../data/cs_event_study.rds")

# --- 1. Eventual adopter control group ---
cat("\n=== 1. Eventual adopters as control ===\n")

panel_eventual <- panel_analysis %>%
  filter(ever_treated)

cs_eventual <- att_gt(
  yname = "log_zhvi",
  tname = "year",
  idname = "RegionID",
  gname = "cohort_binned",
  data = as.data.frame(panel_eventual),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_eventual <- aggte(cs_eventual, type = "simple")
cat("Eventual adopter ATT:\n")
summary(agg_eventual)

agg_eventual_es <- aggte(cs_eventual, type = "dynamic", min_e = -5, max_e = 10)
cat("Eventual adopter event study:\n")
summary(agg_eventual_es)

saveRDS(agg_eventual, "../data/cs_eventual_overall.rds")
saveRDS(agg_eventual_es, "../data/cs_eventual_es.rds")

# --- 2. Levels instead of logs ---
cat("\n=== 2. Levels specification ===\n")

twfe_levels <- feols(
  zhvi ~ post_qz | RegionID + year,
  data = panel_analysis,
  cluster = ~RegionID
)
cat("TWFE in levels:\n")
summary(twfe_levels)

saveRDS(twfe_levels, "../data/twfe_levels.rds")

# --- 3. Restrict to 2005-2019 (pre-COVID) ---
cat("\n=== 3. Pre-COVID sample (2000-2019) ===\n")

panel_precovid <- panel_analysis %>%
  filter(year <= 2019)

twfe_precovid <- feols(
  log_zhvi ~ post_qz | RegionID + year,
  data = panel_precovid,
  cluster = ~RegionID
)
cat("Pre-COVID TWFE:\n")
summary(twfe_precovid)

saveRDS(twfe_precovid, "../data/twfe_precovid.rds")

# --- 4. Placebo: cities with crossings but NO quiet zone, random treatment ---
cat("\n=== 4. Placebo test (random treatment dates) ===\n")

set.seed(42)
control_cities <- panel_analysis %>%
  filter(!ever_treated) %>%
  distinct(RegionID) %>%
  mutate(
    fake_cohort = sample(2006:2018, n(), replace = TRUE),
    fake_treat = TRUE
  )

panel_placebo <- panel_analysis %>%
  filter(!ever_treated) %>%
  left_join(control_cities, by = "RegionID") %>%
  mutate(
    fake_post = as.integer(year >= fake_cohort)
  )

twfe_placebo <- feols(
  log_zhvi ~ fake_post | RegionID + year,
  data = panel_placebo,
  cluster = ~RegionID
)
cat("Placebo test (random dates, control cities only):\n")
summary(twfe_placebo)

saveRDS(twfe_placebo, "../data/twfe_placebo.rds")

# --- 5. Heterogeneity by number of crossings ---
cat("\n=== 5. Heterogeneity by city crossing count ===\n")

panel_analysis <- panel_analysis %>%
  mutate(
    many_crossings = n_public_crossings >= median(n_public_crossings[ever_treated]),
    post_many = as.integer(post_qz == 1 & many_crossings),
    post_few = as.integer(post_qz == 1 & !many_crossings & ever_treated)
  )

hetero_crossings <- feols(
  log_zhvi ~ post_many + post_few | RegionID + year,
  data = panel_analysis,
  cluster = ~RegionID
)
cat("Heterogeneity by crossing count:\n")
summary(hetero_crossings)

saveRDS(hetero_crossings, "../data/hetero_crossings.rds")

# --- 6. Heterogeneity by population (SizeRank proxy) ---
cat("\n=== 6. Heterogeneity: small vs large cities ===\n")

# Use SizeRank from Zillow (lower = larger city)
panel_sizes <- readRDS("../data/zhvi_long.rds") %>%
  distinct(RegionID, SizeRank)

panel_analysis <- panel_analysis %>%
  left_join(panel_sizes, by = "RegionID") %>%
  mutate(
    small_city = SizeRank > median(SizeRank, na.rm = TRUE),
    post_small = as.integer(post_qz == 1 & small_city),
    post_large = as.integer(post_qz == 1 & !small_city & ever_treated)
  )

hetero_size <- feols(
  log_zhvi ~ post_small + post_large | RegionID + year,
  data = panel_analysis,
  cluster = ~RegionID
)
cat("Heterogeneity by city size:\n")
summary(hetero_size)

saveRDS(hetero_size, "../data/hetero_size.rds")
saveRDS(panel_analysis, "../data/panel_analysis.rds")

cat("\n=== Robustness checks complete ===\n")
