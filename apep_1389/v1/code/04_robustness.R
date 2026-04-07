## 04_robustness.R — Robustness checks and validity tests
source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "panel_clean.csv"))

# ── 1. McCrary density test ──
message("=== 1. McCrary density test ===")
# Test for bunching at 100 in Appendix B post-2024
post_b <- df[year == 2024 & appendix_b == 1 & emp >= 50 & emp <= 200]
pre_b <- df[year == 2023 & appendix_b == 1 & emp >= 50 & emp <= 200]
non_b <- df[year == 2024 & appendix_b == 0 & emp >= 50 & emp <= 200]

if (nrow(post_b) > 100) {
  dens_post <- rddensity(X = post_b$emp_centered, c = 0)
  message("Post-2024 Appendix B: T=", round(dens_post$test$t_jk, 3),
          ", p=", round(dens_post$test$p_jk, 3))
}
if (nrow(pre_b) > 100) {
  dens_pre <- rddensity(X = pre_b$emp_centered, c = 0)
  message("Pre-2024 Appendix B: T=", round(dens_pre$test$t_jk, 3),
          ", p=", round(dens_pre$test$p_jk, 3))
}
if (nrow(non_b) > 100) {
  dens_non <- rddensity(X = non_b$emp_centered, c = 0)
  message("Post-2024 Non-Appendix B: T=", round(dens_non$test$t_jk, 3),
          ", p=", round(dens_non$test$p_jk, 3))
}

# ── 2. Covariate balance at threshold ──
message("\n=== 2. Covariate balance ===")
# Use pre-period data to check if establishments above/below 100 are comparable
pre_df <- df[year < 2024 & in_bandwidth_narrow == TRUE & appendix_b == 1]

# Balance on industry composition, state composition
pre_df[, emp_c_pos := pmax(emp_centered, 0)]
bal_vars <- c("total_hours_worked", "naics2")

# Hours worked balance
bal_hours <- feols(hours ~ above100 + emp_centered + emp_c_pos | year,
                   data = pre_df[!is.na(hours)], cluster = ~naics4)
message("Hours worked balance: coef=", round(coef(bal_hours)["above100"], 2),
        ", p=", round(coeftable(bal_hours)["above100", "Pr(>|t|)"], 3))

# ── 3. Placebo cutoffs ──
message("\n=== 3. Placebo cutoffs ===")
placebo_cuts <- c(70, 80, 90, 110, 120, 130)
placebo_res <- data.table(cutoff = integer(), coef = numeric(),
                          se = numeric(), pval = numeric())

for (pc in placebo_cuts) {
  sub <- df[year == 2024 & appendix_b == 1 & !is.na(tcr) &
            abs(emp - pc) <= 20]
  if (nrow(sub) < 50) next

  sub[, x := emp - pc]
  rd <- rdrobust(y = sub$tcr, x = sub$x, c = 0)
  placebo_res <- rbind(placebo_res, data.table(
    cutoff = pc, coef = rd$coef[1], se = rd$se[3], pval = rd$pv[3]
  ))
}
print(placebo_res)

# ── 4. Bandwidth sensitivity ──
message("\n=== 4. Bandwidth sensitivity ===")
bw_list <- c(10, 15, 20, 30, 40, 50)
bw_res <- data.table(bandwidth = integer(), coef = numeric(),
                     se = numeric(), pval = numeric(), n = integer())

post_b_all <- df[year == 2024 & appendix_b == 1 & !is.na(tcr)]
for (bw in bw_list) {
  sub <- post_b_all[abs(emp_centered) <= bw]
  if (nrow(sub) < 50) next

  rd <- rdrobust(y = sub$tcr, x = sub$emp_centered, c = 0)
  bw_res <- rbind(bw_res, data.table(
    bandwidth = bw, coef = rd$coef[1], se = rd$se[3],
    pval = rd$pv[3], n = nrow(sub)
  ))
}
print(bw_res)

# ── 5. Donut hole test ──
message("\n=== 5. Donut hole test ===")
# Exclude establishments exactly at 100 ± 2
donut <- post_b_all[abs(emp_centered) > 2]
if (nrow(donut) > 50) {
  rd_donut <- rdrobust(y = donut$tcr, x = donut$emp_centered, c = 0)
  message("Donut (exclude 98-102): coef=", round(rd_donut$coef[1], 3),
          ", se=", round(rd_donut$se[3], 3))
}

# ── 6. Polynomial order sensitivity ──
message("\n=== 6. Polynomial order ===")
for (p in 1:3) {
  sub <- post_b_all[abs(emp_centered) <= 30]
  if (nrow(sub) < 50) next
  rd <- rdrobust(y = sub$tcr, x = sub$emp_centered, c = 0, p = p)
  message("p=", p, ": coef=", round(rd$coef[1], 3),
          ", se=", round(rd$se[3], 3))
}

# ── Save robustness results ──
rob_results <- list(
  placebo_cutoffs = placebo_res,
  bandwidth_sensitivity = bw_res,
  density_post_b = if (exists("dens_post")) list(t = dens_post$test$t_jk, p = dens_post$test$p_jk) else NULL,
  density_pre_b = if (exists("dens_pre")) list(t = dens_pre$test$t_jk, p = dens_pre$test$p_jk) else NULL
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
message("\nRobustness checks complete.")
