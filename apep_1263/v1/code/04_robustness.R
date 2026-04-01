## 04_robustness.R — Robustness checks
## apep_1263: The Opt-Out Illusion

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")

## ---- 1. Leave-one-out: Drop each nation and re-estimate ----
cat("=== Leave-One-Out Sensitivity ===\n\n")

nations <- unique(panel$nation)
loo_results <- list()

for (drop_nation in nations) {
  m_loo <- feols(dd_pmp ~ optout | nation + year,
                 data = panel[nation != drop_nation],
                 vcov = "hetero")

  loo_results[[drop_nation]] <- data.table(
    dropped = drop_nation,
    beta = coef(m_loo)["optout"],
    se = sqrt(vcov(m_loo, vcov = "hetero")["optout","optout"]),
    n = nrow(panel[nation != drop_nation])
  )

  cat(sprintf("Drop %s: beta = %.2f (SE = %.2f)\n",
              drop_nation, coef(m_loo)["optout"],
              sqrt(vcov(m_loo, vcov = "hetero")["optout","optout"])))
}

loo_dt <- rbindlist(loo_results)

## ---- 2. Placebo outcome: Living donor rate ----
# Living donors should NOT respond to deceased consent legislation
cat("\n=== Placebo: Living Donor Rate ===\n")
m_placebo <- feols(ld_pmp ~ optout | nation + year, data = panel, vcov = "hetero")
summary(m_placebo)

## ---- 3. Alternative timing: Wales treated from 2015-16 ----
# Wales law effective Dec 2015 — 4 months of FY 2015-16
# Test sensitivity to coding Wales as treated from 2015-16 instead of 2016-17
cat("\n=== Alternative: Wales treated from 2015-16 ===\n")
panel_alt <- copy(panel)
panel_alt[nation == "Wales" & year == 2015, optout := 1L]
m_alt <- feols(dd_pmp ~ optout | nation + year, data = panel_alt, vcov = "hetero")
summary(m_alt)

## ---- 4. Exclude NI (latest adopter, shortest post-period) ----
cat("\n=== Exclude Northern Ireland ===\n")
m_noNI <- feols(dd_pmp ~ optout | nation + year,
                data = panel[nation != "Northern Ireland"],
                vcov = "hetero")
summary(m_noNI)

## ---- 5. Log specification ----
cat("\n=== Log Specification ===\n")
m_log <- feols(ln_dd_pmp ~ optout | nation + year, data = panel, vcov = "hetero")
summary(m_log)
cat(sprintf("Implied percentage change: %.1f%%\n",
            (exp(coef(m_log)["optout"]) - 1) * 100))

## ---- 6. Summary of robustness ----
cat("\n=== Robustness Summary ===\n")
rob_summary <- data.table(
  Specification = c("Main (levels)", "Excl. COVID year",
                    "Excl. NI", "Wales from 2015-16",
                    "Log specification"),
  Beta = c(
    coef(feols(dd_pmp ~ optout | nation + year, data = panel))["optout"],
    coef(feols(dd_pmp ~ optout | nation + year, data = panel[covid == 0]))["optout"],
    coef(m_noNI)["optout"],
    coef(m_alt)["optout"],
    coef(m_log)["optout"]
  )
)
print(rob_summary)

saveRDS(list(loo = loo_dt, rob_summary = rob_summary), "../data/robustness_results.rds")
cat("\nRobustness analysis complete.\n")
