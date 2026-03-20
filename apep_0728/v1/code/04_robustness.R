## 04_robustness.R — apep_0728
## Robustness checks and placebo tests

source("00_packages.R")

qwi <- readRDS("../data/qwi_clean.rds")
models <- readRDS("../data/models.rds")

df <- qwi %>%
  filter(race %in% c("BK", "WH"))

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 4: Robustness Checks
# ══════════════════════════════════════════════════════════════════════════════

cat("=== ROBUSTNESS CHECKS ===\n")

# R1. County-level clustering (instead of state)
r1_county <- feols(
  log_earnings ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df,
  cluster = ~county_fips
)
cat("R1 County clustering - coef:", round(coef(r1_county), 4),
    "SE:", round(sqrt(vcov(r1_county)[1,1]), 4), "\n")

# R2. Two-way clustering (state × industry)
r2_twoway <- feols(
  log_earnings ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df,
  cluster = ~state_fips + naics3
)
cat("R2 Two-way clustering - coef:", round(coef(r2_twoway), 4),
    "SE:", round(sqrt(vcov(r2_twoway)[1,1]), 4), "\n")

# R3. Drop top 5 and bottom 5 NTR gap industries
ntr_quantiles <- quantile(unique(df$ntr_gap), probs = c(0.25, 0.75))
r3_trim <- feols(
  log_earnings ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df %>% filter(ntr_gap >= ntr_quantiles[1] & ntr_gap <= ntr_quantiles[2]),
  cluster = ~state_fips
)
cat("R3 Trimmed NTR range - coef:", round(coef(r3_trim), 4),
    "SE:", round(sqrt(vcov(r3_trim)[1,1]), 4), "\n")

# R4. Exclude Southern states (historical racial composition may drive results)
southern <- c("01", "05", "12", "13", "21", "22", "24", "28", "37", "40",
              "45", "47", "48", "51", "54")
r4_nosouth <- feols(
  log_earnings ~ ntr_x_black_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df %>% filter(!state_fips %in% southern),
  cluster = ~state_fips
)
cat("R4 Exclude South - coef:", round(coef(r4_nosouth), 4),
    "SE:", round(sqrt(vcov(r4_nosouth)[1,1]), 4), "\n")

# R5. Pre-trend falsification: use only pre-PNTR data (1995-2000)
#     with placebo "post" = 1998-2000
df_pre <- df %>%
  filter(year <= 2000) %>%
  mutate(
    placebo_post = as.integer(year >= 1998),
    ntr_x_black_x_placebo = ntr_gap * is_black * placebo_post
  )

r5_placebo <- feols(
  log_earnings ~ ntr_x_black_x_placebo |
    county_industry + county_quarter + industry_quarter,
  data = df_pre,
  cluster = ~state_fips
)
cat("R5 Placebo (pre-PNTR) - coef:", round(coef(r5_placebo), 4),
    "SE:", round(sqrt(vcov(r5_placebo)[1,1]), 4), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 5: Placebo Race (Asian Workers)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n=== PLACEBO RACE: ASIAN WORKERS ===\n")

# Asian vs White (should show no differential DDD effect if the result
# is driven by Black workers' specific occupational sorting, not
# general minority status)
df_aw <- qwi %>%
  filter(race %in% c("AS", "WH")) %>%
  mutate(
    is_asian = as.integer(race == "AS"),
    ntr_x_asian = ntr_gap * is_asian,
    asian_x_post = is_asian * post_pntr,
    ntr_x_asian_x_post = ntr_gap * is_asian * post_pntr
  )

r6_asian <- feols(
  log_earnings ~ ntr_x_asian_x_post |
    county_industry + county_quarter + industry_quarter,
  data = df_aw,
  cluster = ~state_fips
)
cat("R6 Asian placebo - coef:", round(coef(r6_asian), 4),
    "SE:", round(sqrt(vcov(r6_asian)[1,1]), 4), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# Save robustness models
# ══════════════════════════════════════════════════════════════════════════════

robust_models <- list(
  r1_county = r1_county,
  r2_twoway = r2_twoway,
  r3_trim = r3_trim,
  r4_nosouth = r4_nosouth,
  r5_placebo = r5_placebo,
  r6_asian = r6_asian
)
saveRDS(robust_models, "../data/robust_models.rds")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
