# 03_main_analysis.R — Main DiD analysis

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

cat("=== MAIN ANALYSIS ===\n")
cat("Sample: ", nrow(df), " city-month obs\n")
cat("Cities: ", n_distinct(df$city_en), "\n")
cat("Treated: ", n_distinct(df$city_en[df$treated == 1]), "\n")
cat("Pre periods: ", n_distinct(df$date[df$post == 0]), "\n\n")

# ══════════════════════════════════════════════════════════════
# 1. MAIN SPECIFICATION: Price Volatility (|MoM change|)
# ══════════════════════════════════════════════════════════════
# Primary outcome: absolute month-on-month price change
# Hypothesis: batching → lumpy information → higher short-run volatility

# (1) Baseline: city + time FE
m1 <- feols(new_abs_mom ~ treated:post | city_id + time_id, data = df,
            cluster = ~city_id)

# (2) With controls for city tier
m2 <- feols(new_abs_mom ~ treated:post + tier1:post | city_id + time_id, data = df,
            cluster = ~city_id)

# (3) Used house volatility (mechanism: less affected by land auctions)
m3 <- feols(used_abs_mom ~ treated:post | city_id + time_id, data = df,
            cluster = ~city_id)

# (4) New-used price divergence
m4 <- feols(new_used_gap ~ treated:post | city_id + time_id, data = df,
            cluster = ~city_id)

cat("\n=== MAIN RESULTS ===\n")
cat("(1) New house |MoM|:\n")
print(summary(m1))
cat("\n(2) New house |MoM| + tier1 control:\n")
print(summary(m2))
cat("\n(3) Used house |MoM| (placebo-ish):\n")
print(summary(m3))
cat("\n(4) New-used divergence:\n")
print(summary(m4))

# ══════════════════════════════════════════════════════════════
# 2. SECONDARY: Level effects (MoM price change)
# ══════════════════════════════════════════════════════════════
m5 <- feols(new_mom_pct ~ treated:post | city_id + time_id, data = df,
            cluster = ~city_id)

m6 <- feols(used_mom_pct ~ treated:post | city_id + time_id, data = df,
            cluster = ~city_id)

cat("\n(5) New house MoM level:\n")
print(summary(m5))
cat("\n(6) Used house MoM level:\n")
print(summary(m6))

# ══════════════════════════════════════════════════════════════
# 3. EVENT STUDY
# ══════════════════════════════════════════════════════════════
# Create event-time indicators (bin endpoints)
df <- df %>%
  mutate(
    rel_month_binned = case_when(
      rel_month <= -12 ~ -12L,
      rel_month >= 24 ~ 24L,
      TRUE ~ as.integer(rel_month)
    ),
    rel_month_factor = factor(rel_month_binned)
  )

# Event study for main outcome
es1 <- feols(new_abs_mom ~ i(rel_month_binned, treated, ref = -1) |
               city_id + time_id,
             data = df, cluster = ~city_id)

cat("\n=== EVENT STUDY (|MoM new house|) ===\n")
print(summary(es1))

# Event study for level
es2 <- feols(new_mom_pct ~ i(rel_month_binned, treated, ref = -1) |
               city_id + time_id,
             data = df, cluster = ~city_id)

# ══════════════════════════════════════════════════════════════
# 4. WILD CLUSTER BOOTSTRAP (70 clusters is moderate)
# ══════════════════════════════════════════════════════════════
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Bootstrap p-value for main specification
boot1 <- tryCatch({
  boottest(m1, param = "treated:post", clustid = "city_id",
           B = 999, type = "webb")
}, error = function(e) {
  cat("  Bootstrap failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot1)) {
  cat("Main spec bootstrap p-value:", boot1$p_val, "\n")
  cat("Bootstrap CI:", boot1$conf_int, "\n")
}

# ══════════════════════════════════════════════════════════════
# 5. SAVE RESULTS FOR TABLES
# ══════════════════════════════════════════════════════════════
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m5 = m5, m6 = m6,
  es1 = es1, es2 = es2,
  boot1 = boot1
)
saveRDS(results, "../data/main_results.rds")

# ══════════════════════════════════════════════════════════════
# 6. DIAGNOSTICS for validate_v1.py
# ══════════════════════════════════════════════════════════════
diag <- list(
  n_treated = n_distinct(df$city_en[df$treated == 1]),
  n_pre = n_distinct(df$date[df$post == 0]),
  n_obs = nrow(df)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics written to data/diagnostics.json\n")
cat("  n_treated:", diag$n_treated, "\n")
cat("  n_pre:", diag$n_pre, "\n")
cat("  n_obs:", diag$n_obs, "\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
