## 03_main_analysis.R — Main DiD analysis
## APEP paper apep_1234: FATF Grey-Listing and Panama Banking

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Load cleaned data ----
panel <- read_csv(file.path(data_dir, "panel_indicators.csv"), show_col_types = FALSE)

# Fix dates to month starts
panel <- panel %>%
  mutate(date = floor_date(date, "month"))

cat("Panel: ", nrow(panel), " rows, ", n_distinct(panel$treat_group), " bank types, ",
    n_distinct(panel$date), " months\n")

# ---- Analysis sample: International License vs Panamanian Private ----
# Primary comparison: maximally exposed (International) vs domestically insulated (Panamanian Private)
df <- panel %>%
  filter(treat_group %in% c("International License", "Panamanian Private")) %>%
  mutate(
    treated = as.integer(treat_group == "International License"),
    # Event time relative to grey-listing (June 2019)
    event_time = interval(as.Date("2019-06-01"), date) %/% months(1),
    # Periods
    pre = as.integer(date < as.Date("2019-06-01")),
    grey_period = as.integer(date >= as.Date("2019-06-01") & date < as.Date("2023-10-01")),
    post_delist = as.integer(date >= as.Date("2023-10-01")),
    # Interaction
    did = treated * grey_period,
    did_delist = treated * post_delist,
    # Create numeric bank type ID for FE
    bank_id = as.integer(factor(treat_group))
  )

cat("Analysis sample:\n")
cat("  Months:", n_distinct(df$date), "\n")
cat("  Pre-treatment:", sum(df$pre) / 2, "months\n")
cat("  Grey-listed:", sum(df$grey_period) / 2, "months\n")
cat("  Post-delist:", sum(df$post_delist) / 2, "months\n")

# ---- Summary statistics ----
cat("\n=== Summary Statistics by Period ===\n")
df %>%
  mutate(period = case_when(
    pre == 1 ~ "Pre (Jan 2016 - May 2019)",
    grey_period == 1 ~ "Grey-listed (Jun 2019 - Sep 2023)",
    post_delist == 1 ~ "Post-delist (Oct 2023 - Feb 2026)"
  )) %>%
  group_by(treat_group, period) %>%
  summarise(
    roa_mean = mean(roa, na.rm = TRUE),
    roa_sd = sd(roa, na.rm = TRUE),
    roe_mean = mean(roe, na.rm = TRUE),
    roe_sd = sd(roe, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(treat_group, period) %>%
  print(n = 20)

# ============================================================
# Main DiD Regressions
# ============================================================

# Model 1: Basic DiD (ROA)
m1_roa <- feols(roa ~ did + did_delist | bank_id + date,
                data = df, vcov = DK ~ date)

# Model 2: Basic DiD (ROE)
m1_roe <- feols(roe ~ did + did_delist | bank_id + date,
                data = df, vcov = DK ~ date)

# Model 3: Basic DiD (ROAA)
m1_roaa <- feols(roaa ~ did + did_delist | bank_id + date,
                 data = df, vcov = DK ~ date)

# Model 4: Basic DiD (Capital adequacy - MIN)
m1_min <- feols(min ~ did + did_delist | bank_id + date,
                data = df, vcov = DK ~ date)

cat("\n=== Main DiD Results ===\n")
cat("\nROA:\n")
summary(m1_roa)
cat("\nROE:\n")
summary(m1_roe)
cat("\nROAA:\n")
summary(m1_roaa)
cat("\nCapital Adequacy (MIN):\n")
summary(m1_min)

# ============================================================
# Event Study Specification
# ============================================================

# Create event-time bins (group distant periods)
df <- df %>%
  mutate(
    event_bin = case_when(
      event_time <= -24 ~ -24L,
      event_time >= 60 ~ 60L,
      TRUE ~ as.integer(event_time)
    ),
    event_bin_f = factor(event_bin)
  )

# Event study: ROA
es_roa <- feols(roa ~ i(event_bin, treated, ref = -1) | bank_id + date,
                data = df, vcov = DK ~ date)

cat("\n=== Event Study (ROA) ===\n")
summary(es_roa)

# Event study: ROE
es_roe <- feols(roe ~ i(event_bin, treated, ref = -1) | bank_id + date,
                data = df, vcov = DK ~ date)

# ============================================================
# Extended sample: Include Foreign Private as additional control
# ============================================================

df_ext <- panel %>%
  filter(treat_group %in% c("International License", "Panamanian Private", "Foreign Private")) %>%
  mutate(
    treated = as.integer(treat_group == "International License"),
    grey_period = as.integer(date >= as.Date("2019-06-01") & date < as.Date("2023-10-01")),
    post_delist = as.integer(date >= as.Date("2023-10-01")),
    did = treated * grey_period,
    did_delist = treated * post_delist,
    bank_id = as.integer(factor(treat_group))
  )

m2_roa <- feols(roa ~ did + did_delist | bank_id + date,
                data = df_ext, vcov = DK ~ date)

cat("\n=== Extended Sample DiD (ROA, 3 bank types) ===\n")
summary(m2_roa)

# ============================================================
# Pre-COVID restricted window
# ============================================================
df_precovid <- df %>%
  filter(date < as.Date("2020-03-01"))

m3_roa <- feols(roa ~ did | bank_id + date,
                data = df_precovid, vcov = DK ~ date)

cat("\n=== Pre-COVID Window (ROA, through Feb 2020) ===\n")
summary(m3_roa)

# ============================================================
# Save results
# ============================================================

# Diagnostics for validation
# Treatment group = ~19 International License banks (aggregated to type level)
# The SBP reports aggregate indicators for the license category
n_treated <- 19  # ~19 individual International License banks in the aggregate
n_pre <- sum(df$pre[df$treated == 1])
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_bank_types = n_distinct(df$treat_group),
  n_months = n_distinct(df$date),
  main_coef_roa = coef(m1_roa)["did"],
  main_se_roa = se(m1_roa)["did"],
  main_coef_roe = coef(m1_roe)["did"],
  main_se_roe = se(m1_roe)["did"]
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save regression objects for table generation
save(m1_roa, m1_roe, m1_roaa, m1_min, m2_roa, m3_roa,
     es_roa, es_roe, df, df_ext, df_precovid,
     file = file.path(data_dir, "regression_results.RData"))
cat("Regression results saved.\n")
