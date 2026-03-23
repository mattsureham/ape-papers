# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# APEP Working Paper apep_0800
# =============================================================================

source("00_packages.R")

df <- arrow::read_parquet("../data/analysis_panel.parquet")
results <- readRDS("../data/main_results.rds")
ban_states <- readRDS("../data/ban_states.rds")

# Pre-construct interaction terms
df <- df %>%
  mutate(
    ban = as.integer(ban_state),
    ddd = black * ban * post,
    bd = black * post,
    bp = ban * post
  )

# ---------------------------------------------------------------------------
# 1. Agriculture Placebo (NAICS 11 — credit checks never used)
# ---------------------------------------------------------------------------
cat("=== Agriculture Placebo (NAICS 11) ===\n")

df_ag <- df %>% filter(industry == "11")

m_ag <- feols(
  asinh_hirn ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_ag,
  cluster = ~state_fips
)
cat("Agriculture DDD coefficient:\n")
summary(m_ag)

# ---------------------------------------------------------------------------
# 2. White-worker placebo within ban states (finance)
# ---------------------------------------------------------------------------
cat("\n=== White Worker Placebo (Finance, Ban States Only) ===\n")

df_fin_ban_white <- df %>% filter(industry == "52", ban_state == TRUE, race == "A1")

m_white <- feols(
  asinh_hirn ~ post | county_fips + cal_quarter,
  data = df_fin_ban_white,
  cluster = ~state_fips
)
cat("White worker DD coefficient in ban states:\n")
summary(m_white)

# ---------------------------------------------------------------------------
# 3. Wild cluster bootstrap for DDD coefficient
# ---------------------------------------------------------------------------
cat("\n=== Wild Cluster Bootstrap ===\n")

df_fin <- df %>% filter(industry == "52")

m_ddd <- feols(
  asinh_hirn ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_fin,
  cluster = ~state_fips
)

boot_result <- tryCatch({
  boottest(
    m_ddd,
    param = "ddd",
    clustid = ~state_fips,
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("Wild bootstrap error:", e$message, "\n")
  cat("Falling back to standard clustered SEs.\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
  cat("Bootstrap CI:", boot_result$conf_int, "\n")
}

# ---------------------------------------------------------------------------
# 4. Excluding earliest adopter (Washington, 2007)
# ---------------------------------------------------------------------------
cat("\n=== Excluding Washington (earliest adopter) ===\n")

df_no_wa <- df %>% filter(industry == "52", state_fips != "53")

m_no_wa <- feols(
  asinh_hirn ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_no_wa,
  cluster = ~state_fips
)
summary(m_no_wa)

# ---------------------------------------------------------------------------
# 5. Alternative outcome: employment stock
# ---------------------------------------------------------------------------
cat("\n=== Employment Stock DDD ===\n")

m_emp_stock <- feols(
  asinh_emp ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_fin,
  cluster = ~state_fips
)
summary(m_emp_stock)

# ---------------------------------------------------------------------------
# 6. Log specification (dropping zeros)
# ---------------------------------------------------------------------------
cat("\n=== Log Specification (dropping zero hires) ===\n")

df_fin_pos <- df_fin %>% filter(HirN > 0)

m_log <- feols(
  log_hirn ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_fin_pos,
  cluster = ~state_fips
)
summary(m_log)

# ---------------------------------------------------------------------------
# 7. Annual aggregation (reduce noise)
# ---------------------------------------------------------------------------
cat("\n=== Annual Aggregation ===\n")

df_annual <- df_fin %>%
  group_by(county_fips, state_fips, year, race, industry,
           ban_state, first_treat_yr, black) %>%
  summarise(
    HirN = sum(HirN, na.rm = TRUE),
    Emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    asinh_hirn = asinh(HirN),
    asinh_emp = asinh(Emp),
    ban = as.integer(ban_state),
    post = if_else(ban_state & year >= first_treat_yr, 1L, 0L),
    ddd = black * ban * post,
    bd = black * post,
    bp = ban * post
  )

m_annual <- feols(
  asinh_hirn ~ ddd + bd + bp |
    county_fips^race + year,
  data = df_annual,
  cluster = ~state_fips
)
cat("Annual DDD:\n")
summary(m_annual)

# ---------------------------------------------------------------------------
# Save all robustness results
# ---------------------------------------------------------------------------
rob_results <- list(
  ag_placebo = m_ag,
  white_placebo = m_white,
  boot_result = boot_result,
  no_wa = m_no_wa,
  emp_stock = m_emp_stock,
  log_spec = m_log,
  annual = m_annual
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
