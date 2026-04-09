## 03_main_analysis.R — Primary DiD + event study
## apep_1446: X-waiver elimination and buprenorphine desert entry

source("00_packages.R")

DATA <- "../data"

## ---- 1. Load panel ----
panel <- as.data.table(read_parquet(file.path(DATA, "county_month_panel.parquet")))
npi_entry <- as.data.table(read_parquet(file.path(DATA, "npi_entry.parquet")))
new_npi_county <- as.data.table(read_parquet(file.path(DATA, "new_npi_county.parquet")))

cat(sprintf("Panel: %s rows\n", format(nrow(panel), big.mark = ",")))

## ---- 2. Primary DiD specification ----
# Y = new_entrants (count of first-time buprenorphine NPIs)
# Treatment = desert × post
# FE: county + year-month

# Drop very sparse months at edges
panel <- panel[ym >= as.Date("2020-01-01") & ym <= as.Date("2024-06-01")]

# Create year-month FE variable
panel[, ym_fe := as.factor(ym)]
panel[, county_fe := as.factor(county_fips)]

# Convert to numeric for clean interactions
panel[, desert_num := as.integer(desert)]
panel[, post_num := as.integer(post)]

cat("Running primary DiD...\n")
did_main <- feols(new_entrants ~ desert_num:post_num | county_fe + ym_fe,
                  data = panel, cluster = ~county_fips)
summary(did_main)

cat("Running DiD with active NPIs as outcome...\n")
did_active <- feols(active_npis ~ desert_num:post_num | county_fe + ym_fe,
                    data = panel, cluster = ~county_fips)
summary(did_active)

cat("Running DiD with beneficiaries as outcome...\n")
did_bene <- feols(total_bene ~ desert_num:post_num | county_fe + ym_fe,
                  data = panel, cluster = ~county_fips)
summary(did_bene)

## ---- 3. Event study ----
# Create event time bins (monthly, relative to Jan 2023)
# Bin endpoints: cap at -24 and +18
panel[, et := pmin(pmax(event_time, -24), 18)]
# Check what event times exist
cat(sprintf("Event time range: %d to %d\n", min(panel$et), max(panel$et)))
cat(sprintf("Unique event times: %s\n", paste(sort(unique(panel$et)), collapse = ", ")))

cat("Running event study (new entrants)...\n")
es_entry <- feols(new_entrants ~ i(et, desert_num, ref = -1) | county_fe + ym_fe,
                  data = panel, cluster = ~county_fips)
summary(es_entry)

cat("Running event study (active NPIs)...\n")
es_active <- feols(active_npis ~ i(et, desert_num, ref = -1) | county_fe + ym_fe,
                   data = panel, cluster = ~county_fips)
summary(es_active)

## ---- 4. Pre-trend test ----
# F-test on pre-treatment event study coefficients
all_coefs <- coef(es_entry)
pre_coef_names <- grep("et::-", names(all_coefs), value = TRUE)
pre_coefs <- all_coefs[pre_coef_names]
cat(sprintf("\nPre-treatment coefficients (new entrants): %d\n", length(pre_coefs)))
if (length(pre_coefs) > 0) {
  cat(sprintf("Mean pre-trend coef: %.6f\n", mean(pre_coefs)))
  cat(sprintf("Max abs pre-trend coef: %.6f\n", max(abs(pre_coefs))))
  # Joint F-test for pre-trends
  pre_test <- wald(es_entry, paste(pre_coef_names, collapse = "|"))
  cat("Joint pre-trend F-test:\n")
  print(pre_test)
}

## ---- 5. April 2021 partial X-waiver sub-event ----
# Look at whether the April 2021 relaxation shows a smaller proportional effect
treatment_date <- as.Date("2023-01-01")
panel[, post_2021 := as.integer(ym >= as.Date("2021-04-01") & ym < treatment_date)]
panel[, post_2023 := as.integer(ym >= treatment_date)]

did_both <- feols(new_entrants ~ desert_num:post_2021 + desert_num:post_2023 | county_fe + ym_fe,
                  data = panel, cluster = ~county_fips)
summary(did_both)
cat("2021 partial vs 2023 full elimination comparison:\n")

## ---- 6. Short-window robustness (pre-Medicaid unwinding) ----
panel_short <- panel[ym >= as.Date("2022-01-01") & ym <= as.Date("2023-03-01")]
panel_short[, desert_num := as.integer(desert)]
panel_short[, post_num := as.integer(post)]
did_short <- feols(new_entrants ~ desert_num:post_num | county_fe + ym_fe,
                   data = panel_short, cluster = ~county_fips)
cat("\nShort window (Jan 2022 - Mar 2023, pre-unwinding):\n")
summary(did_short)

## ---- 7. Descriptive statistics for new entrants ----
cat("\n=== DESCRIPTIVE: WHERE DO NEW ENTRANTS GO? ===\n")
entry_stats <- new_npi_county[, .(
  n = .N,
  pct = 100 * .N / nrow(new_npi_county)
), by = is_desert]
print(entry_stats)

# Among new entrants in served counties, how concentrated?
if (nrow(new_npi_county[is_desert == FALSE]) > 0) {
  county_counts <- new_npi_county[is_desert == FALSE, .N, by = county_fips]
  cat(sprintf("\nServed-county new entrants: top 10 counties account for %d / %d (%.1f%%)\n",
              sum(head(county_counts[order(-N)], 10)$N),
              nrow(new_npi_county[is_desert == FALSE]),
              100 * sum(head(county_counts[order(-N)], 10)$N) / nrow(new_npi_county[is_desert == FALSE])))
}

## ---- 8. Save results ----
results <- list(
  did_main = did_main,
  did_active = did_active,
  did_bene = did_bene,
  es_entry = es_entry,
  es_active = es_active,
  did_both = did_both,
  did_short = did_short,
  entry_stats = entry_stats
)
saveRDS(results, file.path(DATA, "main_results.rds"))

## ---- 9. Diagnostics for validation ----
diagnostics <- list(
  n_treated = uniqueN(panel$county_fips[panel$desert_num == 1]),
  n_pre = length(unique(panel$ym[panel$ym < as.Date("2023-01-01")])),
  n_obs = nrow(panel)
)
write_json(diagnostics, file.path(DATA, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
