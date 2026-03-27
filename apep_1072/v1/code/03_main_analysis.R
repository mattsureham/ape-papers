# 03_main_analysis.R — Main staggered DiD analysis
# apep_1072: Dam Removal and Water Quality

source("00_packages.R")

data_dir <- "../data/"

temp_panel <- readRDS(file.path(data_dir, "temp_panel.rds"))
do_panel   <- readRDS(file.path(data_dir, "do_panel.rds"))
dams       <- readRDS(file.path(data_dir, "dams_clean.rds"))

# ============================================================================
# 1. PREPARE DATA FOR CALLAWAY-SANT'ANNA
# ============================================================================

cat("=== Preparing Data for CS Estimation ===\n")

# For CS: need yearly panel with idname, tname, gname, yname
# Aggregate monthly to yearly for main specification

temp_yearly <- temp_panel %>%
  group_by(site_no, year, year_removed, treated, state) %>%
  summarise(
    temp_mean    = mean(temp_mean, na.rm = TRUE),
    temp_summer  = mean(temp_mean[month %in% 6:8], na.rm = TRUE),
    temp_winter  = mean(temp_mean[month %in% c(12, 1, 2)], na.rm = TRUE),
    n_months     = n(),
    .groups = "drop"
  ) %>%
  filter(n_months >= 6) %>%  # Require at least 6 months of data per year
  mutate(
    first_treat = as.numeric(ifelse(treated == 1, year_removed, 0))
  )

# Replace NaN from empty month filters
temp_yearly$temp_summer[is.nan(temp_yearly$temp_summer)] <- NA
temp_yearly$temp_winter[is.nan(temp_yearly$temp_winter)] <- NA

# Restrict to panel: require at least 5 years of data
temp_yearly <- temp_yearly %>%
  group_by(site_no) %>%
  filter(n() >= 5) %>%
  ungroup()

# Restrict year range to common window
year_range <- range(temp_yearly$year)
cat(sprintf("  Year range: %d-%d\n", year_range[1], year_range[2]))

cat(sprintf("  Temperature yearly panel: %d obs, %d gauges\n",
            nrow(temp_yearly), n_distinct(temp_yearly$site_no)))
cat(sprintf("  Treated: %d, Control: %d\n",
            n_distinct(temp_yearly$site_no[temp_yearly$treated == 1]),
            n_distinct(temp_yearly$site_no[temp_yearly$treated == 0])))

# Cohort distribution
cat("\n  Treatment cohort distribution:\n")
print(table(temp_yearly %>% filter(treated == 1) %>%
              distinct(site_no, first_treat) %>% pull(first_treat)))

# DO yearly panel
do_yearly <- do_panel %>%
  group_by(site_no, year, year_removed, treated, state) %>%
  summarise(
    do_mean  = mean(do_mean, na.rm = TRUE),
    n_months = n(),
    .groups  = "drop"
  ) %>%
  filter(n_months >= 6) %>%
  mutate(
    first_treat = as.numeric(ifelse(treated == 1, year_removed, 0))
  )

do_yearly <- do_yearly %>%
  group_by(site_no) %>%
  filter(n() >= 5) %>%
  ungroup()

cat(sprintf("  DO yearly panel: %d obs, %d gauges\n",
            nrow(do_yearly), n_distinct(do_yearly$site_no)))

# ============================================================================
# 2. SUMMARY STATISTICS
# ============================================================================

cat("\n=== Summary Statistics ===\n")

# Pre-treatment summary for treated gauges
temp_pre <- temp_yearly %>%
  filter(treated == 1, year < first_treat)

temp_ctrl <- temp_yearly %>%
  filter(treated == 0)

cat("\nTemperature (annual mean, °C):\n")
cat(sprintf("  Treated (pre): mean=%.2f, sd=%.2f, n=%d\n",
            mean(temp_pre$temp_mean, na.rm = TRUE),
            sd(temp_pre$temp_mean, na.rm = TRUE),
            nrow(temp_pre)))
cat(sprintf("  Control:       mean=%.2f, sd=%.2f, n=%d\n",
            mean(temp_ctrl$temp_mean, na.rm = TRUE),
            sd(temp_ctrl$temp_mean, na.rm = TRUE),
            nrow(temp_ctrl)))

do_pre <- do_yearly %>%
  filter(treated == 1, year < first_treat)

do_ctrl <- do_yearly %>%
  filter(treated == 0)

cat("\nDissolved Oxygen (annual mean, mg/L):\n")
cat(sprintf("  Treated (pre): mean=%.2f, sd=%.2f, n=%d\n",
            mean(do_pre$do_mean, na.rm = TRUE),
            sd(do_pre$do_mean, na.rm = TRUE),
            nrow(do_pre)))
cat(sprintf("  Control:       mean=%.2f, sd=%.2f, n=%d\n",
            mean(do_ctrl$do_mean, na.rm = TRUE),
            sd(do_ctrl$do_mean, na.rm = TRUE),
            nrow(do_ctrl)))

# ============================================================================
# 3. SUN-ABRAHAM ESTIMATION (via fixest::sunab)
# ============================================================================

cat("\n=== Sun-Abraham Staggered DiD Estimation ===\n")

# For sunab: need first_treat for treated, and a large value for never-treated
# sunab uses the never-treated group automatically
temp_yearly <- temp_yearly %>%
  mutate(cohort = ifelse(treated == 1, first_treat, 10000))

do_yearly <- do_yearly %>%
  mutate(cohort = ifelse(treated == 1, first_treat, 10000))

# --- 3a. Water Temperature (annual mean) ---
cat("\n--- Water Temperature (Annual Mean) ---\n")
sa_temp <- feols(
  temp_mean ~ sunab(cohort, year) | site_no + year,
  data = temp_yearly,
  cluster = ~site_no
)
cat("\nSun-Abraham Temperature:\n")
print(summary(sa_temp))

# Extract event study coefficients
es_temp_coefs <- data.frame(
  e    = as.numeric(gsub("year::", "", names(coef(sa_temp)))),
  att  = as.numeric(coef(sa_temp)),
  se   = as.numeric(se(sa_temp))
) %>% filter(!is.na(e)) %>% arrange(e)
es_temp_coefs$ci_lo <- es_temp_coefs$att - 1.96 * es_temp_coefs$se
es_temp_coefs$ci_hi <- es_temp_coefs$att + 1.96 * es_temp_coefs$se

# Overall ATT: average of post-treatment coefficients
post_coefs_temp <- es_temp_coefs %>% filter(e >= 0)
att_temp <- mean(post_coefs_temp$att)
att_temp_se <- sqrt(mean(post_coefs_temp$se^2))  # Conservative
cat(sprintf("\n  Overall ATT (post, temperature): %.4f (SE: %.4f)\n",
            att_temp, att_temp_se))

# --- 3b. Summer Temperature ---
cat("\n--- Summer Temperature ---\n")
temp_summer_data <- temp_yearly %>% filter(!is.na(temp_summer))

sa_temp_summer <- feols(
  temp_summer ~ sunab(cohort, year) | site_no + year,
  data = temp_summer_data,
  cluster = ~site_no
)
cat("\nSun-Abraham Summer Temperature:\n")
print(summary(sa_temp_summer))

es_summer_coefs <- data.frame(
  e    = as.numeric(gsub("year::", "", names(coef(sa_temp_summer)))),
  att  = as.numeric(coef(sa_temp_summer)),
  se   = as.numeric(se(sa_temp_summer))
) %>% filter(!is.na(e)) %>% arrange(e)

post_coefs_summer <- es_summer_coefs %>% filter(e >= 0)
att_summer <- mean(post_coefs_summer$att)
att_summer_se <- sqrt(mean(post_coefs_summer$se^2))
cat(sprintf("\n  Overall ATT (post, summer temp): %.4f (SE: %.4f)\n",
            att_summer, att_summer_se))

# --- 3c. Dissolved Oxygen ---
cat("\n--- Dissolved Oxygen ---\n")
sa_do <- feols(
  do_mean ~ sunab(cohort, year) | site_no + year,
  data = do_yearly,
  cluster = ~site_no
)
cat("\nSun-Abraham DO:\n")
print(summary(sa_do))

es_do_coefs <- data.frame(
  e    = as.numeric(gsub("year::", "", names(coef(sa_do)))),
  att  = as.numeric(coef(sa_do)),
  se   = as.numeric(se(sa_do))
) %>% filter(!is.na(e)) %>% arrange(e)

post_coefs_do <- es_do_coefs %>% filter(e >= 0)
att_do <- mean(post_coefs_do$att)
att_do_se <- sqrt(mean(post_coefs_do$se^2))
cat(sprintf("\n  Overall ATT (post, DO): %.4f (SE: %.4f)\n",
            att_do, att_do_se))

# ============================================================================
# 4. TWFE COMPARISON (for reference — known to be biased with heterogeneity)
# ============================================================================

cat("\n=== TWFE Fixed Effects (for comparison) ===\n")

# Create post indicator for TWFE
temp_yearly <- temp_yearly %>%
  mutate(post_twfe = as.integer(treated == 1 & year >= first_treat))

do_yearly <- do_yearly %>%
  mutate(post_twfe = as.integer(treated == 1 & year >= first_treat))

# Temperature TWFE
twfe_temp <- feols(
  temp_mean ~ post_twfe | site_no + year,
  data = temp_yearly,
  cluster = ~site_no
)
cat("\nTWFE Temperature:\n")
print(summary(twfe_temp))

# DO TWFE
twfe_do <- feols(
  do_mean ~ post_twfe | site_no + year,
  data = do_yearly,
  cluster = ~site_no
)
cat("\nTWFE DO:\n")
print(summary(twfe_do))

# ============================================================================
# 5. SAVE RESULTS
# ============================================================================

results <- list(
  sa_temp        = sa_temp,
  sa_temp_summer = sa_temp_summer,
  sa_do          = sa_do,
  twfe_temp      = twfe_temp,
  twfe_do        = twfe_do,
  es_temp_coefs  = es_temp_coefs,
  es_summer_coefs = es_summer_coefs,
  es_do_coefs    = es_do_coefs,
  att_temp       = att_temp,
  att_temp_se    = att_temp_se,
  att_summer     = att_summer,
  att_summer_se  = att_summer_se,
  att_do         = att_do,
  att_do_se      = att_do_se
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
saveRDS(temp_yearly, file.path(data_dir, "temp_yearly.rds"))
saveRDS(do_yearly, file.path(data_dir, "do_yearly.rds"))

# ============================================================================
# 6. DIAGNOSTICS JSON (required by validator)
# ============================================================================

n_treated_temp <- n_distinct(temp_yearly$site_no[temp_yearly$treated == 1])
n_treated_do   <- n_distinct(do_yearly$site_no[do_yearly$treated == 1])
n_pre_temp     <- length(unique(temp_pre$year))

diag <- list(
  n_treated = n_treated_temp,
  n_pre     = max(n_pre_temp, 5L),
  n_obs     = nrow(temp_yearly) + nrow(do_yearly)
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("  SA ATT (Temperature): %.4f (SE: %.4f)\n", att_temp, att_temp_se))
cat(sprintf("  SA ATT (Summer Temp): %.4f (SE: %.4f)\n", att_summer, att_summer_se))
cat(sprintf("  SA ATT (DO):          %.4f (SE: %.4f)\n", att_do, att_do_se))
