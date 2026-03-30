## 03_main_analysis.R — Main regressions
## apep_1154: EU Transposition Delay and Firm Entry

source("00_packages.R")

cat("\n=== Main Analysis: Transposition Delay and Firm Entry ===\n")

df <- readRDS("../data/analysis_df.rds")

cat("Panel dimensions:", nrow(df), "observations\n")
cat("  Countries:", n_distinct(df$country2), "\n")
cat("  Sectors:", n_distinct(df$nace_section), "\n")
cat("  Years:", paste(range(df$year), collapse = " - "), "\n")

# ---- 3a. Summary statistics ----
cat("\n--- Summary Statistics ---\n")
summ_stats <- df %>%
  summarise(
    `Firm births` = sprintf("%.0f (%.0f)", mean(births, na.rm = TRUE), sd(births, na.rm = TRUE)),
    `Active enterprises` = sprintf("%.0f (%.0f)", mean(active_ent, na.rm = TRUE), sd(active_ent, na.rm = TRUE)),
    `Birth rate (%)` = sprintf("%.2f (%.2f)", mean(birth_rate, na.rm = TRUE), sd(birth_rate, na.rm = TRUE)),
    `Any directive in limbo` = sprintf("%.3f (%.3f)", mean(any_limbo), sd(any_limbo)),
    `N directives in limbo` = sprintf("%.2f (%.2f)", mean(n_limbo), sd(n_limbo)),
    `Limbo share` = sprintf("%.3f (%.3f)", mean(limbo_share), sd(limbo_share))
  )

cat("Mean (SD):\n")
for (nm in names(summ_stats)) {
  cat("  ", nm, ":", summ_stats[[nm]], "\n")
}

# Pre-treatment SD of birth rate (for SDE calculation)
pre_sd_birth_rate <- sd(df$birth_rate[df$any_limbo == 0], na.rm = TRUE)
pre_sd_log_births <- sd(df$log_births[df$any_limbo == 0], na.rm = TRUE)
cat("\nPre-treatment SD(birth_rate):", round(pre_sd_birth_rate, 3), "\n")
cat("Pre-treatment SD(log_births):", round(pre_sd_log_births, 3), "\n")

# ---- 3b. Main specification: TWFE ----
# With only 3 sectors, country×year FE + sector×year FE + cs FE is too demanding.
# Use: cs_id FE + year FE (absorbs country-sector time-invariant + common year shocks)
# Then progressively add controls.

cat("\n--- Model 1: Binary limbo — cs + year FE ---\n")
m1 <- feols(
  log_births ~ any_limbo | cs_id + year,
  data = df,
  cluster = ~country2
)
cat("Coefficient on any_limbo:", round(coef(m1)["any_limbo"], 4),
    "SE:", round(se(m1)["any_limbo"], 4), "\n")

cat("\n--- Model 2: Binary limbo — cs + sector×year FE ---\n")
m2 <- feols(
  log_births ~ any_limbo | cs_id + nace_section^year,
  data = df,
  cluster = ~country2
)
cat("Coefficient on any_limbo:", round(coef(m2)["any_limbo"], 4),
    "SE:", round(se(m2)["any_limbo"], 4), "\n")

cat("\n--- Model 3: Limbo share (continuous) — cs + year FE ---\n")
m3 <- feols(
  log_births ~ limbo_share | cs_id + year,
  data = df,
  cluster = ~country2
)
cat("Coefficient on limbo_share:", round(coef(m3)["limbo_share"], 4),
    "SE:", round(se(m3)["limbo_share"], 4), "\n")

cat("\n--- Model 4: Birth rate (levels) — cs + year FE ---\n")
m4 <- feols(
  birth_rate ~ any_limbo | cs_id + year,
  data = df,
  cluster = ~country2
)
cat("Coefficient on any_limbo:", round(coef(m4)["any_limbo"], 4),
    "SE:", round(se(m4)["any_limbo"], 4), "\n")

cat("\n--- Model 5: Active enterprises — cs + year FE ---\n")
m5 <- feols(
  log_active ~ any_limbo | cs_id + year,
  data = df,
  cluster = ~country2
)
cat("Coefficient on any_limbo:", round(coef(m5)["any_limbo"], 4),
    "SE:", round(se(m5)["any_limbo"], 4), "\n")

# ---- 3c. Wild cluster bootstrap (20 clusters — use Webb 6-point) ----
cat("\n--- Wild Cluster Bootstrap for Model 1 ---\n")
boot_m1 <- tryCatch({
  set.seed(42)
  boottest(m1, param = "any_limbo", B = 9999, type = "webb",
           clustid = "country2", nthreads = 1)
}, error = function(e) {
  cat("Wild bootstrap error:", e$message, "\n")
  # Fallback: CR3 small-sample correction
  m1_cr3 <- feols(log_births ~ any_limbo | cs_id + year, data = df,
                   vcov = ~country2, ssc = ssc(adj = TRUE, cluster.adj = TRUE))
  list(p_val = pvalue(m1_cr3)["any_limbo"],
       conf_int = c(coef(m1_cr3)["any_limbo"] - 1.96*se(m1_cr3)["any_limbo"],
                     coef(m1_cr3)["any_limbo"] + 1.96*se(m1_cr3)["any_limbo"]),
       fallback = TRUE)
})

if (!is.null(boot_m1)) {
  cat("Bootstrap p-value:", round(boot_m1$p_val, 4), "\n")
  cat("Bootstrap 95% CI: [", round(boot_m1$conf_int[1], 4), ",",
      round(boot_m1$conf_int[2], 4), "]\n")
}

# ---- 3d. Event study ----
cat("\n--- Event Study ---\n")

first_limbo <- df %>%
  filter(any_limbo == 1) %>%
  group_by(cs_id) %>%
  summarise(first_limbo_year = min(year), .groups = "drop")

df_es <- df %>%
  left_join(first_limbo, by = "cs_id") %>%
  mutate(
    event_time = year - first_limbo_year,
    event_time_binned = case_when(
      is.na(event_time) ~ NA_integer_,
      event_time <= -4L ~ -4L,
      event_time >= 4L ~ 4L,
      TRUE ~ as.integer(event_time)
    ),
    first_treat = ifelse(is.na(first_limbo_year), 10000L, as.integer(first_limbo_year))
  )

# Use simpler FE for event study: country + sector + year
es_model <- tryCatch({
  feols(
    log_births ~ sunab(first_treat, year) | country2 + nace_section + year,
    data = df_es,
    cluster = ~country2
  )
}, error = function(e) {
  cat("Sun-Abraham error:", e$message, "\n")
  # Fallback: manual event study
  tryCatch({
    df_es_sub <- df_es %>% filter(!is.na(event_time_binned))
    feols(
      log_births ~ i(event_time_binned, ref = -1) | country2 + nace_section + year,
      data = df_es_sub,
      cluster = ~country2
    )
  }, error = function(e2) {
    cat("Manual event study also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(es_model)) {
  cat("Event study computed.\n")
  print(summary(es_model))
} else {
  cat("Event study could not be estimated.\n")
}

# ---- 3e. Save results ----
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_model = es_model,
  boot_m1 = boot_m1,
  pre_sd_birth_rate = pre_sd_birth_rate,
  pre_sd_log_births = pre_sd_log_births,
  n_obs = nrow(df),
  n_countries = n_distinct(df$country2),
  n_sectors = n_distinct(df$nace_section),
  n_cs = n_distinct(df$cs_id),
  n_treated = sum(df$any_limbo),
  n_control = sum(df$any_limbo == 0)
)

saveRDS(results, "../data/results.rds")

# Write diagnostics.json for validator
# Pre-periods: years before the median first-treatment year across treated units
first_limbo_years <- df %>%
  filter(any_limbo == 1) %>%
  group_by(cs_id) %>%
  summarise(first_year = min(year), .groups = "drop")
median_first_treat <- median(first_limbo_years$first_year)
n_pre_periods <- length(unique(df$year[df$year < median_first_treat]))

diag <- list(
  n_treated = n_distinct(df$cs_id[df$any_limbo == 1]),
  n_pre = n_pre_periods,
  n_obs = nrow(df)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Results saved ===\n")
cat("n_treated units:", diag$n_treated, "\n")
cat("n_pre periods:", diag$n_pre, "\n")
cat("n_obs:", diag$n_obs, "\n")
