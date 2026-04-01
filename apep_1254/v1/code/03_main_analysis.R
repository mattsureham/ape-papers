## 03_main_analysis.R — Primary DiD estimation
## apep_1254: Portugal Golden Visa Geographic Restriction

source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat(sprintf("Loaded analysis panel: %d obs, %d regions, %d months\n",
            nrow(df), n_distinct(df$geocod), n_distinct(df$date)))

# ============================================================
# 1. Primary DiD specification
# ============================================================
cat("\n=== Primary DiD: Levels ===\n")

# TWFE DiD
did_levels <- feols(
  value ~ treated:post | geocod + ym,
  data = df,
  cluster = ~nuts3_approx
)
summary(did_levels)

# Log specification
cat("\n=== Primary DiD: Log ===\n")
did_log <- feols(
  log_value ~ treated:post | geocod + ym,
  data = df,
  cluster = ~nuts3_approx
)
summary(did_log)

# ============================================================
# 2. Anticipation test: separate announcement from enactment
# ============================================================
cat("\n=== Anticipation test ===\n")

did_anticipation <- feols(
  log_value ~ treated:anticipation + treated:post | geocod + ym,
  data = df,
  cluster = ~nuts3_approx
)
summary(did_anticipation)

# ============================================================
# 3. Event study
# ============================================================
cat("\n=== Event Study ===\n")

# Bin endpoints: group event_time <= -24 and >= 24
df <- df %>%
  mutate(
    event_time_binned = case_when(
      event_time <= -24 ~ -24L,
      event_time >= 24 ~ 24L,
      TRUE ~ event_time
    )
  )

es_model <- feols(
  log_value ~ i(event_time_binned, treated, ref = -1) | geocod + ym,
  data = df,
  cluster = ~nuts3_approx
)
summary(es_model)

# Save event study coefficients for table
es_coefs <- broom::tidy(es_model) %>%
  filter(grepl("event_time_binned", term)) %>%
  mutate(
    event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", term))
  ) %>%
  arrange(event_time)

write_csv(es_coefs, "../data/event_study_coefs.csv")

# ============================================================
# 4. Region-specific linear trends (addresses pre-trend)
# ============================================================
cat("\n=== Region-specific linear trends ===\n")

df <- df %>%
  mutate(time_index = as.integer(difftime(date, min(date), units = "days")) / 30)

did_trend <- feols(
  log_value ~ treated:post | geocod[time_index] + ym,
  data = df,
  cluster = ~nuts3_approx
)
summary(did_trend)

# Also: no-COVID version with trends
df_no_covid_trends <- df %>% filter(!(year %in% c(2020, 2021)))
did_trend_nocovid <- feols(
  log_value ~ treated:post | geocod[time_index] + ym,
  data = df_no_covid_trends,
  cluster = ~nuts3_approx
)
cat("\n=== Region trends, excluding COVID ===\n")
summary(did_trend_nocovid)

# ============================================================
# 5. Save diagnostics for validation
# ============================================================
n_treated <- n_distinct(df$geocod[df$treated == 1])
n_pre <- df %>% filter(date < as.Date("2022-01-01")) %>% pull(date) %>% n_distinct()
n_obs <- nrow(df)
n_clusters <- n_distinct(df$nuts3_approx)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_distinct(df$geocod[df$treated == 0]),
  n_regions = n_distinct(df$geocod),
  n_clusters = n_clusters,
  n_months = n_distinct(df$date),
  did_coef_log = coef(did_log)[["treated:post"]],
  did_se_log = sqrt(vcov(did_log)[["treated:post", "treated:post"]]),
  did_coef_levels = coef(did_levels)[["treated:post"]],
  did_se_levels = sqrt(vcov(did_levels)[["treated:post", "treated:post"]])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d, n_clusters=%d\n",
            n_treated, n_pre, n_obs, n_clusters))

# Save model objects for tables
save(did_levels, did_log, did_anticipation, es_model, did_trend, did_trend_nocovid,
     file = "../data/main_models.RData")
cat("Main models saved.\n")
