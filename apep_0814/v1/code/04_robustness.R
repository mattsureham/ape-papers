## 04_robustness.R — Robustness checks
## APEP paper apep_0814: El Salvador gang removal and homicide geography

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel.csv"))
load(file.path(data_dir, "models.RData"))

message("Panel: ", nrow(panel), " obs")

# ─────────────────────────────────────────────────────────────────────────────
# 1. Placebo tests: false treatment dates
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Placebo tests ===")

placebo_results <- list()
for (placebo_year in c(2010, 2012, 2014, 2016)) {
  panel_pre <- panel[year < 2019]  # Only pre-treatment data
  panel_pre[, post_placebo := as.integer(year >= placebo_year)]

  mp <- feols(ln_hom ~ gang_rate_std:post_placebo | muni_id + year,
              data = panel_pre, cluster = ~muni_id)

  placebo_results[[as.character(placebo_year)]] <- data.frame(
    placebo_year = placebo_year,
    coef = as.numeric(coef(mp)),
    se = as.numeric(se(mp)),
    pvalue = as.numeric(pvalue(mp))
  )

  cat("Placebo ", placebo_year, ": β =", round(coef(mp), 4),
      " SE =", round(se(mp), 4),
      " p =", round(pvalue(mp), 4), "\n")
}

placebo_df <- rbindlist(placebo_results)

# ─────────────────────────────────────────────────────────────────────────────
# 2. Leave-one-out: drop each department
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Leave-one-out by department ===")

depts <- unique(panel$NAME_1[!is.na(panel$NAME_1)])
loo_results <- list()

for (d in depts) {
  panel_loo <- panel[NAME_1 != d | is.na(NAME_1)]
  m_loo <- feols(ln_hom ~ gang_rate_std:post | muni_id + year,
                 data = panel_loo, cluster = ~muni_id)
  loo_results[[d]] <- data.frame(
    dropped = d,
    coef = as.numeric(coef(m_loo)),
    se = as.numeric(se(m_loo)),
    n_obs = nrow(panel_loo)
  )
}

loo_df <- rbindlist(loo_results)
cat("\nLeave-one-out coefficient range: [",
    round(min(loo_df$coef), 4), ", ",
    round(max(loo_df$coef), 4), "]\n")
cat("Main estimate: ", round(coef(m1), 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 3. Drop San Salvador (capital, largest department)
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Drop San Salvador ===")
panel_no_ss <- panel[NAME_1 != "San Salvador" | is.na(NAME_1)]
m_no_ss <- feols(ln_hom ~ gang_rate_std:post | muni_id + year,
                 data = panel_no_ss, cluster = ~muni_id)
cat("Without San Salvador: β =", round(coef(m_no_ss), 4),
    " SE =", round(se(m_no_ss), 4),
    " p =", round(pvalue(m_no_ss), 4),
    " N =", nrow(panel_no_ss), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 4. Winsorized outcome (99th percentile)
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Winsorized outcome ===")
p99 <- quantile(panel$hom_rate_10k, 0.99, na.rm = TRUE)
panel[, hom_winsor := pmin(hom_rate_10k, p99)]
panel[, ln_hom_winsor := log(hom_winsor + 1)]

m_winsor <- feols(ln_hom_winsor ~ gang_rate_std:post | muni_id + year,
                  data = panel, cluster = ~muni_id)
cat("Winsorized (99th): β =", round(coef(m_winsor), 4),
    " SE =", round(se(m_winsor), 4),
    " p =", round(pvalue(m_winsor), 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Quintile treatment (non-parametric)
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Quintile treatment ===")
# Compare Q5 (highest gang) vs Q1 (lowest gang)
for (q in 2:5) {
  panel[, paste0("Q", q) := as.integer(gang_quintile == q)]
}

m_quint <- feols(ln_hom ~ Q2:post + Q3:post + Q4:post + Q5:post | muni_id + year,
                 data = panel, cluster = ~muni_id)
cat("Quintile effects (relative to Q1):\n")
print(round(coeftable(m_quint), 4))

# ─────────────────────────────────────────────────────────────────────────────
# 6. Alternative clustering: department level
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Alternative clustering ===")
panel[, dept_id := as.integer(as.factor(NAME_1))]
panel_dept_cl <- panel[!is.na(dept_id)]

m_dept_cl <- feols(ln_hom ~ gang_rate_std:post | muni_id + year,
                   data = panel_dept_cl, cluster = ~dept_id)
cat("Department-clustered: β =", round(coef(m_dept_cl), 4),
    " SE =", round(se(m_dept_cl), 4),
    " p =", round(pvalue(m_dept_cl), 4), "\n")

# Two-way clustering
m_2way <- feols(ln_hom ~ gang_rate_std:post | muni_id + year,
                data = panel_dept_cl, cluster = ~muni_id + year)
cat("Two-way clustered (muni + year): β =", round(coef(m_2way), 4),
    " SE =", round(se(m_2way), 4),
    " p =", round(pvalue(m_2way), 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Save robustness objects
# ─────────────────────────────────────────────────────────────────────────────
save(placebo_df, loo_df, m_no_ss, m_winsor, m_quint, m_dept_cl, m_2way,
     file = file.path(data_dir, "robustness.RData"))

message("\n=== Robustness checks complete ===")
