## 04_robustness.R — Robustness checks
## apep_0616: Police Austerity and Criminal Justice Quality

suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
})

data_dir <- "data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

main <- panel |>
  filter(year >= 2014, year <= 2021) |>
  mutate(
    log_officers = log(officers_fte),
    charge_rate_pct = charge_rate * 100,
    cut_intensity = -pct_officer_cut / 100
  )

cat("=== Robustness Checks ===\n")

# R1: Exclude Metropolitan Police (outlier in size)
cat("\nR1: Excluding Metropolitan Police\n")
r1 <- feols(charge_rate_pct ~ log_officers | force_name + year,
            data = main |> filter(force_name != "Metropolitan Police"),
            cluster = ~force_name)
cat(sprintf("  β = %.3f (SE = %.3f), p = %.4f, N = %d\n",
            coef(r1), se(r1), pvalue(r1), nobs(r1)))

# R2: Exclude London forces (Met + City of London)
cat("\nR2: Excluding London forces\n")
r2 <- feols(charge_rate_pct ~ log_officers | force_name + year,
            data = main |> filter(!force_name %in% c("Metropolitan Police", "London, City of")),
            cluster = ~force_name)
cat(sprintf("  β = %.3f (SE = %.3f), p = %.4f, N = %d\n",
            coef(r2), se(r2), pvalue(r2), nobs(r2)))

# R3: Drop 2020 (COVID year)
cat("\nR3: Excluding COVID year 2020\n")
r3 <- feols(charge_rate_pct ~ log_officers | force_name + year,
            data = main |> filter(year != 2020),
            cluster = ~force_name)
cat(sprintf("  β = %.3f (SE = %.3f), p = %.4f, N = %d\n",
            coef(r3), se(r3), pvalue(r3), nobs(r3)))

# R4: Region × year FE (absorb regional trends)
cat("\nR4: Region × year FE\n")
r4 <- feols(charge_rate_pct ~ log_officers | force_name + region^year,
            data = main, cluster = ~force_name)
cat(sprintf("  β = %.3f (SE = %.3f), p = %.4f, N = %d\n",
            coef(r4), se(r4), pvalue(r4), nobs(r4)))

# R5: Headcount instead of FTE
cat("\nR5: Using headcount instead of FTE\n")
r5 <- feols(charge_rate_pct ~ log(officers_headcount) | force_name + year,
            data = main, cluster = ~force_name)
cat(sprintf("  β = %.3f (SE = %.3f), p = %.4f, N = %d\n",
            coef(r5), se(r5), pvalue(r5), nobs(r5)))

# R6: Pre-trend test — is charge rate correlated with FUTURE officer cuts?
# Among 2014-2016 only (early post), do forces with larger cuts have different trends?
cat("\nR6: Placebo — pre-2014 charge trends vs. officer cuts\n")
# Use the old outcome framework (2007-2013) for pre-trends
# Outcome: log(charges), since rates aren't comparable
extended <- panel |>
  filter(year >= 2007, year <= 2013) |>
  mutate(
    log_charges = log(charged + 1),
    cut_intensity = -pct_officer_cut / 100
  )

r6 <- feols(log_charges ~ cut_intensity:i(year, ref = 2007) | force_name + year,
            data = extended |> filter(charged > 0),
            cluster = ~force_name)
cat("  Pre-trend coefficients (cut_intensity × year, ref = 2007):\n")
print(coeftable(r6))

# R7: Controlling for total recorded crime (log)
cat("\nR7: Controlling for log(total recorded crimes)\n")
r7 <- feols(charge_rate_pct ~ log_officers + log(total_outcomes) | force_name + year,
            data = main, cluster = ~force_name)
cat(sprintf("  β(officers) = %.3f (SE = %.3f), p = %.4f\n",
            coef(r7)["log_officers"], se(r7)["log_officers"], pvalue(r7)["log_officers"]))

# Save all robustness models
saveRDS(list(r1 = r1, r2 = r2, r3 = r3, r4 = r4, r5 = r5, r6 = r6, r7 = r7),
        file.path(data_dir, "robustness_models.rds"))

cat("\nAll robustness checks complete.\n")
