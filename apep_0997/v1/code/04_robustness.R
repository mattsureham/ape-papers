## 04_robustness.R — Robustness checks
## apep_0997: Romania Construction Tax Holiday

source("00_packages.R")

panel_a <- readRDS("../data/panel_annual.rds")
panel_q <- readRDS("../data/panel_quarterly.rds")

panel_a <- panel_a %>%
  mutate(et = year - 2019,
         covid_2020 = ifelse(year == 2020, 1L, 0L),
         covid_2021 = ifelse(year == 2021, 1L, 0L))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ================================================================
# 1. Restricted Window (2015-2023 = 4 pre + 5 post)
# ================================================================
cat("--- 1. Restricted Window (2015-2023) ---\n")

panel_r <- panel_a %>% filter(year >= 2015, year <= 2023)

r1_sal <- feols(log_sal ~ treat | nace_r2 + year,
                data = panel_r, cluster = ~nace_r2)

r1_self <- feols(self_emp_share ~ treat | nace_r2 + year,
                 data = panel_r, cluster = ~nace_r2)

cat("Salaried (2015-2023):\n")
print(summary(r1_sal))
cat("\nSelf-emp share (2015-2023):\n")
print(summary(r1_self))

# ================================================================
# 2. Wild Cluster Bootstrap (few clusters = 10)
# ================================================================
cat("\n--- 2. Wild Cluster Bootstrap ---\n")

# Self-employment share (main result)
m_self_full <- feols(self_emp_share ~ treat | nace_r2 + year,
                     data = panel_a, cluster = ~nace_r2)

wcb_self <- tryCatch({
  boot_res <- boottest(m_self_full, param = "treat",
                       clustid = ~nace_r2,
                       B = 9999,
                       type = "webb")
  cat("WCB p-value (self-emp share):", boot_res$p_val, "\n")
  cat("WCB 95% CI:", boot_res$conf_int[1], "to", boot_res$conf_int[2], "\n")
  boot_res
}, error = function(e) {
  cat("WCB failed:", conditionMessage(e), "\n")
  NULL
})

# Salaried employment
m_sal_full <- feols(log_sal ~ treat | nace_r2 + year,
                    data = panel_a, cluster = ~nace_r2)

wcb_sal <- tryCatch({
  boot_res <- boottest(m_sal_full, param = "treat",
                       clustid = ~nace_r2,
                       B = 9999,
                       type = "webb")
  cat("\nWCB p-value (log salaried):", boot_res$p_val, "\n")
  cat("WCB 95% CI:", boot_res$conf_int[1], "to", boot_res$conf_int[2], "\n")
  boot_res
}, error = function(e) {
  cat("WCB for salaried failed:", conditionMessage(e), "\n")
  NULL
})

# ================================================================
# 3. Placebo: Real Estate (L) as treated (adjacent sector)
# ================================================================
cat("\n--- 3. Placebo: Real Estate as Treated ---\n")

panel_placebo <- panel_a %>%
  mutate(placebo_treat = ifelse(nace_r2 == "L", 1L, 0L),
         placebo_did = placebo_treat * post)

r3_placebo <- feols(self_emp_share ~ placebo_did | nace_r2 + year,
                    data = panel_placebo %>% filter(nace_r2 != "F"),
                    cluster = ~nace_r2)
cat("Real estate placebo (self-emp share):\n")
print(summary(r3_placebo))

# ================================================================
# 4. Excluding closest sector (Manufacturing as main control)
# ================================================================
cat("\n--- 4. Dropping Sectors One-at-a-Time ---\n")

controls <- unique(panel_a$nace_r2[panel_a$construction == 0])
leave_one_out <- data.frame()

for (s in controls) {
  df_loo <- panel_a %>% filter(nace_r2 != s)
  m_loo <- feols(self_emp_share ~ treat | nace_r2 + year,
                 data = df_loo, cluster = ~nace_r2)
  leave_one_out <- bind_rows(leave_one_out,
                             data.frame(dropped = s,
                                        coef = coef(m_loo)["treat"],
                                        se = se(m_loo)["treat"]))
}

cat("Leave-one-out sensitivity (self-emp share):\n")
print(leave_one_out)
cat(sprintf("Range: [%.4f, %.4f]\n",
            min(leave_one_out$coef), max(leave_one_out$coef)))

# ================================================================
# 5. Trend-adjusted specification
# ================================================================
cat("\n--- 5. Sector-specific linear trends ---\n")

panel_a <- panel_a %>%
  mutate(trend = year - 2014)

r5_trend <- feols(self_emp_share ~ treat + i(nace_r2, trend) | nace_r2 + year,
                  data = panel_a, cluster = ~nace_r2)
cat("Self-emp share with sector-specific trends:\n")
print(summary(r5_trend, keep = "treat"))

r5_sal_trend <- feols(log_sal ~ treat + i(nace_r2, trend) | nace_r2 + year,
                      data = panel_a, cluster = ~nace_r2)
cat("\nLog salaried with sector-specific trends:\n")
print(summary(r5_sal_trend, keep = "treat"))

# ================================================================
# 6. Narrower control group: Manufacturing only
# ================================================================
cat("\n--- 6. Construction vs Manufacturing Only ---\n")

panel_cf <- panel_a %>% filter(nace_r2 %in% c("F", "C"))

r6_self <- feols(self_emp_share ~ treat | nace_r2 + year,
                 data = panel_cf, vcov = "hetero")

r6_sal <- feols(log_sal ~ treat | nace_r2 + year,
                data = panel_cf, vcov = "hetero")

cat("Self-emp share (F vs C):\n")
print(summary(r6_self))
cat("\nLog salaried (F vs C):\n")
print(summary(r6_sal))

# ================================================================
# 7. Save robustness results
# ================================================================
cat("\n=== Saving Robustness Results ===\n")

rob_results <- list(
  r1_sal = r1_sal,
  r1_self = r1_self,
  wcb_self = wcb_self,
  wcb_sal = wcb_sal,
  r3_placebo = r3_placebo,
  leave_one_out = leave_one_out,
  r5_trend = r5_trend,
  r5_sal_trend = r5_sal_trend,
  r6_self = r6_self,
  r6_sal = r6_sal
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n04_robustness.R complete.\n")
