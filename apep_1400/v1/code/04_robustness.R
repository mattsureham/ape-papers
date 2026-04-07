# =============================================================================
# 04_robustness.R — Robustness and heterogeneity
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
sq <- results$sa_bal  # Use same balanced panel as main analysis
pfl_states <- readRDS("../data/pfl_states.rds")

# ============================================================================
# 1. Not-yet-treated controls (sensitivity to control group)
# ============================================================================

cat("CS-DiD with not-yet-treated controls...\n")

cs_nyt <- att_gt(
  yname = "log_hira_ratio",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_yr",
  data = sq,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)

agg_nyt <- aggte(cs_nyt, type = "simple")
es_nyt <- aggte(cs_nyt, type = "dynamic", min_e = -10, max_e = 10)

cat("NYT ATT:", agg_nyt$overall.att, "(SE:", agg_nyt$overall.se, ")\n")

# ============================================================================
# 2. Placebo: pre-treatment TWFE on pre-period only
# ============================================================================

cat("Placebo test...\n")

# Use earliest treatment (CA 2004) as cutoff
earliest_treat_yr <- min(sq$first_treat_yr[sq$first_treat_yr > 0])

sq_pre <- sq %>%
  filter(year < earliest_treat_yr) %>%
  mutate(
    fake_treat_yr = ifelse(first_treat_yr > 0, first_treat_yr - 2, 0),
    fake_post = as.integer(year >= fake_treat_yr & fake_treat_yr > 0)
  )

if (sum(sq_pre$fake_post) > 0) {
  twfe_placebo <- feols(log_hira_ratio ~ fake_post | state_id + year,
                        data = sq_pre, cluster = ~state_id)
  cat("Placebo TWFE coef:", coef(twfe_placebo)["fake_post"],
      "SE:", se(twfe_placebo)["fake_post"], "\n")
} else {
  twfe_placebo <- NULL
  cat("Placebo: insufficient pre-data for fake treatment\n")
}

# ============================================================================
# 3. Heterogeneity by benefit generosity
# ============================================================================

cat("Heterogeneity by benefit generosity...\n")

sq_generous <- sq %>%
  filter(treated == 1) %>%
  mutate(generous = benefit_rate >= 0.75)

# High-generosity cohorts
sq_high <- bind_rows(
  sq %>% filter(treated == 0),
  sq_generous %>% filter(generous == TRUE)
) %>%
  mutate(state_id2 = as.integer(factor(state_fips)))

cs_high <- att_gt(
  yname = "log_hira_ratio", tname = "year", idname = "state_id2",
  gname = "first_treat_yr", data = sq_high,
  control_group = "nevertreated", est_method = "dr",
  bstrap = TRUE, biters = 1000
)
agg_high <- aggte(cs_high, type = "simple")

# Low-generosity cohorts
sq_low <- bind_rows(
  sq %>% filter(treated == 0),
  sq_generous %>% filter(generous == FALSE)
) %>%
  mutate(state_id2 = as.integer(factor(state_fips)))

cs_low <- att_gt(
  yname = "log_hira_ratio", tname = "year", idname = "state_id2",
  gname = "first_treat_yr", data = sq_low,
  control_group = "nevertreated", est_method = "dr",
  bstrap = TRUE, biters = 1000
)
agg_low <- aggte(cs_low, type = "simple")

cat("High-generosity ATT:", agg_high$overall.att, "\n")
cat("Low-generosity ATT:", agg_low$overall.att, "\n")

# ============================================================================
# 4. Heterogeneity by job protection
# ============================================================================

cat("Heterogeneity by job protection...\n")

sq_jp <- sq %>%
  filter(treated == 1) %>%
  mutate(has_jp = job_protection == TRUE)

sq_jp_yes <- bind_rows(sq %>% filter(treated == 0), sq_jp %>% filter(has_jp)) %>%
  mutate(state_id2 = as.integer(factor(state_fips)))
sq_jp_no <- bind_rows(sq %>% filter(treated == 0), sq_jp %>% filter(!has_jp)) %>%
  mutate(state_id2 = as.integer(factor(state_fips)))

cs_jp_yes <- att_gt(yname = "log_hira_ratio", tname = "year", idname = "state_id2",
                    gname = "first_treat_yr", data = sq_jp_yes,
                    control_group = "nevertreated", est_method = "dr",
                    bstrap = TRUE, biters = 1000)
agg_jp_yes <- aggte(cs_jp_yes, type = "simple")

cs_jp_no <- att_gt(yname = "log_hira_ratio", tname = "year", idname = "state_id2",
                   gname = "first_treat_yr", data = sq_jp_no,
                   control_group = "nevertreated", est_method = "dr",
                   bstrap = TRUE, biters = 1000)
agg_jp_no <- aggte(cs_jp_no, type = "simple")

cat("Job protection ATT:", agg_jp_yes$overall.att, "\n")
cat("No job protection ATT:", agg_jp_no$overall.att, "\n")

# ============================================================================
# 5. Early vs late adopters
# ============================================================================

cat("Heterogeneity: early vs late adopters...\n")

sq_early <- sq %>%
  filter(treated == 1) %>%
  mutate(early = pfl_year <= 2014)

sq_early_sub <- bind_rows(sq %>% filter(treated == 0), sq_early %>% filter(early)) %>%
  mutate(state_id2 = as.integer(factor(state_fips)))
sq_late_sub <- bind_rows(sq %>% filter(treated == 0), sq_early %>% filter(!early)) %>%
  mutate(state_id2 = as.integer(factor(state_fips)))

cs_early <- att_gt(yname = "log_hira_ratio", tname = "year", idname = "state_id2",
                   gname = "first_treat_yr", data = sq_early_sub,
                   control_group = "nevertreated", est_method = "dr",
                   bstrap = TRUE, biters = 1000)
agg_early <- aggte(cs_early, type = "simple")

cs_late <- att_gt(yname = "log_hira_ratio", tname = "year", idname = "state_id2",
                  gname = "first_treat_yr", data = sq_late_sub,
                  control_group = "nevertreated", est_method = "dr",
                  bstrap = TRUE, biters = 1000)
agg_late <- aggte(cs_late, type = "simple")

cat("Early adopters ATT:", agg_early$overall.att, "\n")
cat("Late adopters ATT:", agg_late$overall.att, "\n")

# ============================================================================
# Save robustness results
# ============================================================================

rob_results <- list(
  cs_nyt = cs_nyt, agg_nyt = agg_nyt, es_nyt = es_nyt,
  twfe_placebo = twfe_placebo,
  agg_high = agg_high, agg_low = agg_low,
  agg_jp_yes = agg_jp_yes, agg_jp_no = agg_jp_no,
  agg_early = agg_early, agg_late = agg_late
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("Robustness analysis complete.\n")
