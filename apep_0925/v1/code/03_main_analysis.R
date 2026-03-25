# 03_main_analysis.R — Triple-difference estimation
# England × Food services × Post-2022 (calorie labeling regulation)

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- 1. Load data ----
agg_panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

cat("=== Analysis panel loaded ===\n")
cat(sprintf("N = %d | Units = %d | Years = %d\n",
  nrow(agg_panel), length(unique(agg_panel$unit_id)),
  length(unique(agg_panel$year))))

# ---- 2. Triple-difference: Log total enterprises ----
cat("\n=== Model 1: Log total enterprises (triple-diff) ===\n")

# Full triple-diff with all two-way FE
m1 <- feols(
  ln_total ~ treated + eng_food + eng_post + food_post |
    unit_id + country_year + industry_year,
  data = agg_panel,
  cluster = ~unit_id
)
summary(m1)

# Without FE (for transparency about what variation identifies the effect)
m1b <- feols(
  ln_total ~ treated + england*food + england*post + food*post,
  data = agg_panel,
  cluster = ~unit_id
)

# ---- 3. Triple-difference: Large enterprise share ----
cat("\n=== Model 2: Large enterprise share (250+/total) ===\n")

m2 <- feols(
  large_share ~ treated + eng_food + eng_post + food_post |
    unit_id + country_year + industry_year,
  data = agg_panel,
  cluster = ~unit_id
)
summary(m2)

# ---- 4. Triple-difference: Threshold ratio (250-499 / 100-249) ----
cat("\n=== Model 3: Threshold ratio ===\n")

# Drop observations where ratio is undefined (denominator = 0)
panel_ratio <- agg_panel |>
  filter(!is.na(threshold_ratio), near_100_249 > 0)

m3 <- feols(
  threshold_ratio ~ treated + eng_food + eng_post + food_post |
    unit_id + country_year + industry_year,
  data = panel_ratio,
  cluster = ~unit_id
)
summary(m3)

# ---- 5. Triple-difference: Log large enterprises ----
cat("\n=== Model 4: Log large (250+) enterprises ===\n")

m4 <- feols(
  ln_large ~ treated + eng_food + eng_post + food_post |
    unit_id + country_year + industry_year,
  data = agg_panel,
  cluster = ~unit_id
)
summary(m4)

# ---- 6. Event study ----
cat("\n=== Model 5: Event study (log total enterprises) ===\n")

# Create event-time factor (reference: 2022 = last pre-treatment year)
agg_panel <- agg_panel |>
  mutate(
    event_time = year - 2022,
    # Create interaction: england × food × event_time
    ef_event = england * food * event_time
  )

# Event study using i() syntax in fixest
m5 <- feols(
  ln_total ~ i(event_time, eng_food, ref = 0) |
    unit_id + country_year + industry_year,
  data = agg_panel,
  cluster = ~unit_id
)
summary(m5)

cat("\n=== Event study coefficients ===\n")
coef_df <- data.frame(
  event_time = as.numeric(gsub("event_time::", "", gsub(":eng_food", "",
    names(coef(m5))))),
  coef = coef(m5),
  se = sqrt(diag(vcov(m5)))
)
coef_df$ci_lo <- coef_df$coef - 1.96 * coef_df$se
coef_df$ci_hi <- coef_df$coef + 1.96 * coef_df$se
print(coef_df)

# Joint pre-trend test
cat("\nPre-trend F-test (H0: all pre-treatment coefficients = 0):\n")
pre_coefs <- names(coef(m5))[grepl("event_time::-", names(coef(m5)))]
if (length(pre_coefs) > 0) {
  wald_test <- wald(m5, keep = pre_coefs)
  print(wald_test)
}

# ---- 7. Simple DD (England vs Scotland/Wales, food services only) ----
cat("\n=== Model 6: Simple DiD (food services only) ===\n")

food_panel <- agg_panel |> filter(food == 1)

m6 <- feols(
  ln_total ~ england:post | country + year,
  data = food_panel,
  cluster = ~country
)
summary(m6)

# ---- 8. Power calculation for the null ----
cat("\n=== Power analysis / MDE ===\n")

# Pre-treatment SD of ln_total for England food services
eng_food_pre <- agg_panel |>
  filter(england == 1, food == 1, post == 0)

sd_y <- sd(eng_food_pre$ln_total)
mean_y <- mean(eng_food_pre$ln_total)

# SE from triple-diff
se_treated <- sqrt(diag(vcov(m1)))["treated"]

# MDE at 80% power, 5% significance
mde <- 2.8 * se_treated  # approx (z_alpha/2 + z_beta) * SE

cat(sprintf("Mean of Y (pre-treatment, England food): %.4f\n", mean_y))
cat(sprintf("SD of Y (pre-treatment, England food): %.4f\n", sd_y))
cat(sprintf("SE of treatment effect: %.4f\n", se_treated))
cat(sprintf("MDE (80%% power, 5%% sig): %.4f (%.1f%% of pre-treatment mean)\n",
  mde, 100 * mde / mean_y))

# In levels: exp(MDE) - 1
cat(sprintf("MDE in levels: %.1f%% change in enterprise count\n",
  100 * (exp(mde) - 1)))

# ---- 9. Diagnostics for validation ----
cat("\n=== Writing diagnostics.json ===\n")

# Count treated units, pre-periods, observations
n_treated_units <- agg_panel |>
  filter(england == 1, food == 1) |>
  nrow()

n_pre <- agg_panel |>
  filter(post == 0) |>
  pull(year) |>
  unique() |>
  length()

diagnostics <- list(
  n_treated = 1,  # 1 country (England) × 1 industry (food) treated
  n_pre = n_pre,
  n_obs = nrow(agg_panel),
  n_units = length(unique(agg_panel$unit_id)),
  n_years = length(unique(agg_panel$year)),
  n_clusters = length(unique(agg_panel$unit_id)),
  countries = unique(agg_panel$country),
  industries = sort(unique(agg_panel$sic2)),
  post_years = sort(unique(agg_panel$year[agg_panel$post == 1])),
  main_coef = coef(m1)["treated"],
  main_se = se_treated,
  main_pval = summary(m1)$coeftable["treated", "Pr(>|t|)"],
  mde_80 = mde,
  pre_trend_test = tryCatch(
    wald(m5, keep = pre_coefs)$p,
    error = function(e) NA
  )
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
  auto_unbox = TRUE, pretty = TRUE)

# Save model objects
saveRDS(list(m1 = m1, m1b = m1b, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
  file.path(DATA_DIR, "models.rds"))

cat("\n✓ Main analysis complete. Models saved.\n")
