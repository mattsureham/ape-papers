## 03_main_analysis.R — Main regressions
## apep_0670: Comment Period Length and Public Participation

source("00_packages.R")

cat("=== Main Analysis ===\n")

df <- read_csv("../data/rules_analysis.csv", show_col_types = FALSE)
cat(sprintf("Analysis sample: %d rules\n", nrow(df)))

# ============================================================
# Table 2: Main specification — OLS with agency×year FE
# ============================================================

cat("\n--- Main Results: log(comments+1) ~ comment period days ---\n")

# Specification 1: Simple OLS
m1 <- feols(log_comments ~ comment_days, data = df)

# Specification 2: + rule-level controls
m2 <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant,
            data = df)

# Specification 3: + agency FE
m3 <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
              agency_top, data = df)

# Specification 4: + agency × year FE (preferred)
m4 <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
              agency_top^year, data = df)

# Specification 5: Restrict to 20-90 day bandwidth
m5 <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
              agency_top^year,
            data = df |> filter(comment_days >= 20, comment_days <= 90))

cat("\nMain results:\n")
etable(m1, m2, m3, m4, m5,
       headers = c("OLS", "+Controls", "+Agency FE", "+Ag×Year FE", "20-90d BW"))

# ============================================================
# Mechanism: Extensive vs Intensive margin
# ============================================================

cat("\n--- Mechanism: Extensive vs Intensive Margin ---\n")

# Extensive margin: does the rule receive ANY comments?
m_ext <- feols(has_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
                 agency_top^year, data = df)

# Intensive margin: conditional on having comments, log count
m_int <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts + is_significant |
                 agency_top^year,
               data = df |> filter(has_comments))

cat("\nExtensive vs Intensive:\n")
etable(m_ext, m_int, headers = c("Pr(Comments > 0)", "log(Comments) | > 0"))

# ============================================================
# Heterogeneity: Significant vs non-significant rules
# ============================================================

cat("\n--- Heterogeneity: Significant Rules ---\n")

m_sig <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts |
                 agency_top^year,
               data = df |> filter(is_significant))

m_nonsig <- feols(log_comments ~ comment_days + log_pages + n_cfr_parts |
                    agency_top^year,
                  data = df |> filter(!is_significant))

cat("Significant rules:\n")
etable(m_sig, m_nonsig, headers = c("Significant", "Non-Significant"))

# ============================================================
# RD Analysis around 30-day cutoff
# ============================================================

cat("\n--- RD at 30-day APA floor ---\n")

df_rd <- df |> filter(comment_days >= 15, comment_days <= 60)
cat(sprintf("RD sample (15-60 days): %d rules\n", nrow(df_rd)))

# Nonparametric RD
rd_result <- tryCatch({
  rdrobust(
    y = df_rd$log_comments,
    x = df_rd$dist_30,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
}, error = function(e) {
  cat(sprintf("rdrobust failed: %s\n", conditionMessage(e)))
  NULL
})

if (!is.null(rd_result)) {
  cat("\nrdrobust results:\n")
  summary(rd_result)

  rd_coefs <- tibble(
    estimate = rd_result$coef[1],
    se = rd_result$se[1],
    p_value = rd_result$pv[1],
    bandwidth = rd_result$bws[1, 1],
    n_left = rd_result$N_h[1],
    n_right = rd_result$N_h[2]
  )
  write_csv(rd_coefs, "../data/rd_coefficients.csv")
}

# Parametric RD
m_rd <- feols(log_comments ~ above_30 + dist_30 + above_30:dist_30 +
                log_pages + n_cfr_parts + is_significant,
              data = df_rd)

cat("\nParametric RD:\n")
etable(m_rd)

# ============================================================
# Save model objects
# ============================================================

save(m1, m2, m3, m4, m5, m_ext, m_int, m_sig, m_nonsig, m_rd,
     file = "../data/models.RData")

# Diagnostics
diagnostics <- list(
  n_treated = as.integer(sum(df$above_30)),
  n_pre = as.integer(length(unique(df$year[df$year < 2015]))),
  n_obs = as.integer(nrow(df)),
  n_agencies = as.integer(length(unique(df$agency_top))),
  mean_comment_days = round(mean(df$comment_days), 1),
  mean_comments = round(mean(df$total_comments), 1),
  median_comments = as.integer(median(df$total_comments)),
  coef_preferred = round(coef(m4)["comment_days"], 6),
  se_preferred = round(se(m4)["comment_days"], 6)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Analysis complete ===\n")
