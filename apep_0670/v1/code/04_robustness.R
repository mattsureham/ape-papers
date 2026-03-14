## 04_robustness.R — Robustness checks and placebo tests
## apep_0670: Comment Period Length and Public Participation

source("00_packages.R")

cat("=== Robustness Checks ===\n")

df_analysis <- read_csv("../data/rules_analysis.csv", show_col_types = FALSE)

# ============================================================
# 1. Poisson regression for count outcome
# ============================================================

cat("\n--- Poisson Model ---\n")

m_poisson <- fepois(total_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
                      agency_top^year, data = df_analysis)

cat("Poisson (total_comments ~ comment_days | agency×year FE):\n")
etable(m_poisson)

# ============================================================
# 2. Exclude "significant" rules (potential endogenous selection)
# ============================================================

cat("\n--- Excluding Significant Rules ---\n")

m_nonsig <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts |
                    agency_top^year,
                  data = df_analysis |> filter(!is_significant))

cat(sprintf("Non-significant rules: %d obs\n",
            nrow(df_analysis |> filter(!is_significant))))
etable(m_nonsig)

# ============================================================
# 3. Agency-by-agency heterogeneity
# ============================================================

cat("\n--- Agency Heterogeneity ---\n")

top_agencies <- df_analysis |>
  count(agency_top) |>
  filter(n >= 30) |>
  pull(agency_top)

agency_results <- lapply(top_agencies, function(ag) {
  df_ag <- df_analysis |> filter(agency_top == ag)
  if (nrow(df_ag) < 20) return(NULL)

  m <- tryCatch(
    feols(log_comments ~ comment_days + log_pages + n_cfr_parts, data = df_ag),
    error = function(e) NULL
  )

  if (is.null(m)) return(NULL)

  tibble(
    agency = ag,
    n = nrow(df_ag),
    beta = coef(m)["comment_days"],
    se = se(m)["comment_days"],
    p = pvalue(m)["comment_days"]
  )
})

df_agency_het <- bind_rows(agency_results)
cat("\nAgency-level estimates:\n")
print(df_agency_het)
write_csv(df_agency_het, "../data/agency_heterogeneity.csv")

# ============================================================
# 4. Placebo: page length as outcome
# ============================================================

cat("\n--- Placebo: Page Length (should be null) ---\n")

# If comment period is quasi-random conditional on controls,
# it shouldn't predict rule complexity (page length)
m_placebo <- feols(log_pages ~ comment_days + n_cfr_parts + is_significant |
                     agency_top^year, data = df_analysis)

cat("Placebo (log_pages ~ comment_days):\n")
etable(m_placebo)

# ============================================================
# 5. Bandwidth sensitivity
# ============================================================

cat("\n--- Bandwidth Sensitivity ---\n")

bandwidths <- list(
  "20-50d" = c(20, 50),
  "25-60d" = c(25, 60),
  "20-90d" = c(20, 90),
  "15-120d" = c(15, 120),
  "Full" = c(10, 180)
)

bw_results <- lapply(names(bandwidths), function(bw_name) {
  bw <- bandwidths[[bw_name]]
  df_bw <- df_analysis |> filter(comment_days >= bw[1], comment_days <= bw[2])

  if (nrow(df_bw) < 30) return(NULL)

  m <- tryCatch(
    feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
            agency_top^year, data = df_bw),
    error = function(e) {
      # Fall back to simpler FE if agency×year has too few obs
      tryCatch(
        feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
                agency_top, data = df_bw),
        error = function(e2) NULL
      )
    }
  )

  if (is.null(m)) return(NULL)

  tibble(
    bandwidth = bw_name,
    n = nrow(df_bw),
    beta = coef(m)["comment_days"],
    se = se(m)["comment_days"]
  )
})

df_bw <- bind_rows(bw_results)
cat("\nBandwidth sensitivity:\n")
print(df_bw)
write_csv(df_bw, "../data/bandwidth_sensitivity.csv")

# ============================================================
# 6. Non-linear effects (quadratic, log)
# ============================================================

cat("\n--- Non-linear Specifications ---\n")

# Quadratic
m_quad <- feols(log_comments ~ comment_days + I(comment_days^2) +
                  log_pages + n_cfr_parts + is_significant |
                  agency_top^year, data = df_analysis)

# Log-log
m_loglog <- feols(log_comments ~ log(comment_days) +
                    log_pages + n_cfr_parts + is_significant |
                    agency_top^year, data = df_analysis)

cat("Non-linear specifications:\n")
etable(m_quad, m_loglog, headers = c("Quadratic", "Log-Log"))

# Save all robustness models
save(m_poisson, m_nonsig, m_placebo, m_quad, m_loglog,
     file = "../data/robustness_models.RData")

cat("\n=== Robustness complete ===\n")
