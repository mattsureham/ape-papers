# 03_main_analysis.R — CS-DiD estimation of sports betting cannibalization
# apep_0720

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

stc <- readRDS(file.path(data_dir, "stc_analysis.rds"))

# Filter to states with known treatment status
df <- stc %>% filter(!is.na(g))
cat(sprintf("Analysis sample: %d state-years\n", nrow(df)))

# ===================================================================
# MAIN ANALYSIS: TWFE as baseline (then CS-DiD)
# ===================================================================

cat("=== TWFE Estimation ===\n\n")

# Model 1: T11 (Amusement/Gambling tax) — should INCREASE
m1_t11 <- feols(log_T11 ~ post | state_fips + year,
                 data = df, cluster = ~state_fips)
cat("T11 (Amusement/Gambling Tax):\n")
summary(m1_t11)

# Model 2: T20 (Pari-mutuel) — test for cannibalization
m2_t20 <- feols(log_T20 ~ post | state_fips + year,
                 data = df %>% filter(!is.na(log_T20)),
                 cluster = ~state_fips)
cat("\nT20 (Pari-mutuel Tax):\n")
summary(m2_t20)

# Model 3: T10 (Alcoholic beverages) — cross-market
m3_t10 <- feols(log_T10 ~ post | state_fips + year,
                 data = df %>% filter(!is.na(log_T10)),
                 cluster = ~state_fips)
cat("\nT10 (Alcohol Tax):\n")
summary(m3_t10)

# Model 4: T09 (General sales) — PLACEBO
m4_t09 <- feols(log_T09 ~ post | state_fips + year,
                 data = df %>% filter(!is.na(log_T09)),
                 cluster = ~state_fips)
cat("\nT09 (General Sales — Placebo):\n")
summary(m4_t09)

# Model 5: T16 (Tobacco) — another placebo
m5_t16 <- feols(log(T16) ~ post | state_fips + year,
                 data = df %>% filter(T16 > 0),
                 cluster = ~state_fips)
cat("\nT16 (Tobacco — Placebo):\n")
summary(m5_t16)

# ===================================================================
# CS-DiD (Callaway-Sant'Anna)
# ===================================================================

cat("\n=== Callaway-Sant'Anna DiD ===\n\n")

# Prepare data for CS-DiD
df_cs <- df %>%
  filter(!is.na(log_T11)) %>%
  mutate(
    id = state_fips,
    first_treat = g
  ) %>%
  as.data.frame()

# CS-DiD for T11
cs_t11 <- tryCatch({
  att_gt(
    yname = "log_T11",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_cs,
    control_group = "nevertreated"
  )
}, error = function(e) {
  cat("CS-DiD T11 error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_t11)) {
  cat("CS-DiD T11 aggregate:\n")
  agg_t11 <- aggte(cs_t11, type = "simple")
  print(summary(agg_t11))
}

# CS-DiD for T20 (pari-mutuel)
df_cs_t20 <- df %>%
  filter(!is.na(log_T20)) %>%
  mutate(id = state_fips, first_treat = g) %>%
  as.data.frame()

cs_t20 <- tryCatch({
  att_gt(
    yname = "log_T20",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_cs_t20,
    control_group = "nevertreated"
  )
}, error = function(e) {
  cat("CS-DiD T20 error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_t20)) {
  cat("\nCS-DiD T20 aggregate:\n")
  agg_t20 <- aggte(cs_t20, type = "simple")
  print(summary(agg_t20))
}

# ===================================================================
# SAVE RESULTS
# ===================================================================

results <- list(
  m1_t11 = m1_t11,
  m2_t20 = m2_t20,
  m3_t10 = m3_t10,
  m4_t09 = m4_t09,
  m5_t16 = m5_t16,
  cs_t11 = cs_t11,
  cs_t20 = cs_t20,
  agg_t11 = if (!is.null(cs_t11)) agg_t11 else NULL,
  agg_t20 = if (!is.null(cs_t20)) agg_t20 else NULL
)

saveRDS(results, file.path(data_dir, "regression_results.rds"))

# Diagnostics
n_treated <- length(unique(df$state_fips[df$g > 0]))
n_control <- length(unique(df$state_fips[df$g == 0]))
n_pre <- length(unique(df$year[df$year < 2019]))

diagnostics <- list(
  n_treated = as.integer(n_treated),
  n_pre = as.integer(n_pre),
  n_obs = as.integer(nrow(df)),
  n_states = length(unique(df$state_fips)),
  n_years = length(unique(df$year)),
  n_control_states = as.integer(n_control)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\nAll results saved.\n")
