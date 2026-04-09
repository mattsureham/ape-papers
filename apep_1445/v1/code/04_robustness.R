# 04_robustness.R — Robustness checks for CQC RDD
source("00_packages.R")

dt_panel <- fread("../data/cqc_panel_closures.csv")
dt <- dt_panel[!is.na(composite_2024)]
dt[, D := as.integer(composite_2024 >= 17)]
dt[, rv := composite_2024 - 16.5]

# === 1. Placebo thresholds ===
cat("=== Placebo Thresholds ===\n")
placebo_cuts <- c(11.5, 12.5, 13.5, 14.5, 15.5)
placebo_results <- lapply(placebo_cuts, function(c_val) {
  dt_sub <- dt[D == 0]  # Only control group (below real threshold)
  dt_sub[, D_placebo := as.integer(composite_2024 >= c_val + 0.5)]
  dt_sub[, rv_p := composite_2024 - c_val]
  bw <- 4
  dt_sub_bw <- dt_sub[abs(rv_p) <= bw]
  if (sum(dt_sub_bw$D_placebo) < 10 | sum(1 - dt_sub_bw$D_placebo) < 10) return(NULL)
  m <- lm(closed_by_2026 ~ D_placebo + rv_p, data = dt_sub_bw)
  list(cutoff = c_val, coef = coef(m)["D_placebo"],
       se = sqrt(vcovHC(m, type = "HC2")["D_placebo", "D_placebo"]),
       n = nrow(dt_sub_bw))
})
placebo_df <- rbindlist(Filter(Negate(is.null), placebo_results))
cat("Placebo cutoff results (should be insignificant):\n")
print(placebo_df)

# === 2. Bandwidth sensitivity ===
cat("\n=== Bandwidth Sensitivity ===\n")
bws <- c(2, 3, 4, 5, 6, 7)
bw_results <- lapply(bws, function(bw) {
  dt_sub <- dt[abs(rv) <= bw]
  if (sum(dt_sub$D) < 10) return(NULL)
  m <- lm(closed_by_2026 ~ D + rv, data = dt_sub)
  list(bw = bw, coef = coef(m)["D"],
       se = sqrt(vcovHC(m, type = "HC2")["D", "D"]),
       n = nrow(dt_sub))
})
bw_df <- rbindlist(Filter(Negate(is.null), bw_results))
cat("Bandwidth sensitivity:\n")
print(bw_df)

# === 3. Donut RDD (exclude composite = 16 and 17) ===
cat("\n=== Donut RDD ===\n")
dt_donut <- dt[!composite_2024 %in% c(16, 17)]
dt_donut_bw <- dt_donut[abs(rv) <= 4]
if (sum(dt_donut_bw$D) >= 10) {
  m_donut <- lm(closed_by_2026 ~ D + rv, data = dt_donut_bw)
  cat(sprintf("Donut estimate: %.3f (SE: %.3f, n=%d)\n",
              coef(m_donut)["D"], sqrt(vcovHC(m_donut, type = "HC2")["D", "D"]),
              nrow(dt_donut_bw)))
}

# === 4. Logit specification ===
cat("\n=== Logit ===\n")
dt_bw <- dt[abs(rv) <= 4]
m_logit <- glm(closed_by_2026 ~ D + rv, data = dt_bw, family = binomial)
cat(sprintf("Logit marginal effect: %.3f\n",
            mean(predict(m_logit, newdata = transform(dt_bw, D = 1), type = "response")) -
            mean(predict(m_logit, newdata = transform(dt_bw, D = 0), type = "response"))))

# === 5. Save robustness results ===
rob_results <- list(
  placebo = placebo_df,
  bandwidth = bw_df
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
