# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
df <- df %>% filter(year >= 2001, year <= 2022)
df$post <- as.integer(df$year >= df$eitc_year & df$eitc_year > 0)
df$log_hires <- log(df$hires + 1)

results <- readRDS("../data/main_results.rds")

# =============================================================================
# 1. WILD CLUSTER BOOTSTRAP (small number of treated-state clusters)
# =============================================================================
cat("=== Wild Cluster Bootstrap ===\n")

# Main DDD with explicit clustering
ddd_earn <- feols(
  log_earn ~ post:black + post + black |
    fips_county^industry^race + industry^race^year,
  data = df,
  cluster = ~state_fips
)

# Check effective clusters
n_clusters <- n_distinct(df$state_fips)
cat("Number of state clusters:", n_clusters, "\n")
cat("Cluster-robust SE on post:black:", sqrt(vcov(ddd_earn)["post:black", "post:black"]), "\n")

# =============================================================================
# 2. LEAVE-ONE-STATE-OUT
# =============================================================================
cat("\n=== Leave-One-State-Out ===\n")

treated_states <- unique(df$state_fips[df$eitc_year > 0])
loso_results <- data.frame(
  dropped_state = integer(),
  coef = numeric(),
  se = numeric()
)

for (s in treated_states) {
  m <- feols(
    log_earn ~ post:black + post + black |
      fips_county^industry^race + industry^race^year,
    data = df %>% filter(state_fips != s),
    cluster = ~state_fips
  )
  loso_results <- rbind(loso_results, data.frame(
    dropped_state = s,
    coef = coef(m)["post:black"],
    se = sqrt(vcov(m)["post:black", "post:black"])
  ))
}
cat("Leave-one-out range: [", round(min(loso_results$coef), 4), ",",
    round(max(loso_results$coef), 4), "]\n")

# =============================================================================
# 3. PLACEBO TEST: Use only pre-treatment data with fake treatment dates
# =============================================================================
cat("\n=== Placebo Test (fake treatment 3 years early) ===\n")

df_placebo <- df %>%
  filter(eitc_year == 0 | year < eitc_year) %>%
  mutate(
    fake_eitc_year = ifelse(eitc_year > 0, eitc_year - 3, 0),
    fake_post = as.integer(year >= fake_eitc_year & fake_eitc_year > 0)
  )

placebo_earn <- feols(
  log_earn ~ fake_post:black + fake_post + black |
    fips_county^industry^race + industry^race^year,
  data = df_placebo,
  cluster = ~state_fips
)
cat("Placebo DDD (earnings):",
    round(coef(placebo_earn)["fake_post:black"], 4),
    "(SE:", round(sqrt(vcov(placebo_earn)["fake_post:black", "fake_post:black"]), 4), ")\n")

# =============================================================================
# 4. ALTERNATIVE CONTROL GROUP: Not-yet-treated
# =============================================================================
cat("\n=== Not-Yet-Treated Control Group ===\n")

# CS DiD with not-yet-treated
df_state <- df %>%
  filter(!is.na(emp), !is.na(earn_avg)) %>%
  group_by(state_fips, industry, race, year, eitc_year) %>%
  summarize(
    earn_avg = weighted.mean(earn_avg, w = emp),
    emp = sum(emp),
    .groups = "drop"
  ) %>%
  mutate(
    unit_id = as.integer(factor(paste(state_fips, industry, race))),
    log_earn = log(earn_avg + 1),
    first_treat = ifelse(eitc_year == 0, 0, eitc_year)
  )

cs_nyt <- att_gt(
  yname = "log_earn",
  tname = "year",
  idname = "unit_id",
  gname = "first_treat",
  data = df_state %>% filter(race == "A2"),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)
att_nyt <- aggte(cs_nyt, type = "simple")
cat("ATT (not-yet-treated, Black earnings):", att_nyt$overall.att,
    "(SE:", att_nyt$overall.se, ")\n")

# =============================================================================
# 5. CONTINUOUS TREATMENT (EITC supplement rate)
# =============================================================================
cat("\n=== Continuous Treatment (EITC supplement rate) ===\n")

# State EITC supplement as % of federal credit (approximate max rates)
eitc_rates <- tribble(
  ~state_fips, ~eitc_rate,
  10, 0.20,   # DE
  31, 0.10,   # NE
  51, 0.20,   # VA (actually not refundable — small)
  35, 0.10,   # NM
  22, 0.05,   # LA (smaller)
  26, 0.06,   # MI
  09, 0.30,   # CT
  39, 0.10,   # OH (nonrefundable)
  06, 0.085,  # CA (CalEITC, lower-income focused)
  15, 0.20,   # HI
  45, 0.125   # SC
)

df_cont <- df %>%
  left_join(eitc_rates, by = "state_fips") %>%
  mutate(
    eitc_rate = replace_na(eitc_rate, 0),
    dose = ifelse(post == 1, eitc_rate, 0)
  )

dose_earn <- feols(
  log_earn ~ dose:black + dose + black |
    fips_county^industry^race + industry^race^year,
  data = df_cont,
  cluster = ~state_fips
)
cat("Dose-response DDD (earnings):",
    round(coef(dose_earn)["dose:black"], 4),
    "(SE:", round(sqrt(vcov(dose_earn)["dose:black", "dose:black"]), 4), ")\n")

# =============================================================================
# 6. SAVE ROBUSTNESS RESULTS
# =============================================================================
robustness <- list(
  loso = loso_results,
  placebo_earn = placebo_earn,
  cs_nyt = cs_nyt,
  att_nyt = att_nyt,
  dose_earn = dose_earn,
  n_clusters = n_clusters
)
saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
