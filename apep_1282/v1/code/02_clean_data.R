# 02_clean_data.R — Construct analysis panel
# apep_1282: The Double Squeeze

source("00_packages.R")
load("../data/raw_data.RData")

cat("=== Constructing analysis panel ===\n")

# --- 1. Reshape employment data to wide by age group ---
emp_wide <- emp |>
  pivot_wider(names_from = age, values_from = emp_rate, names_prefix = "emp_") |>
  rename(
    emp_youth = `emp_Y15-24`,
    emp_young_adult = `emp_Y25-34`,
    emp_older = `emp_Y55-64`,
    emp_prime = `emp_Y45-54`,
    emp_total = emp_Y_GE15
  )

# Handle Y18-24 if present (for robustness)
if ("emp_Y18-24" %in% names(emp_wide)) {
  emp_wide <- emp_wide |> rename(emp_18_24 = `emp_Y18-24`)
}

# --- 2. Merge NEET rates ---
panel <- emp_wide |>
  left_join(neet, by = c("region", "year"))

cat(sprintf("Panel before treatment merge: %d obs, %d regions, years %d-%d\n",
            nrow(panel), n_distinct(panel$region),
            min(panel$year), max(panel$year)))

# --- 3. Merge treatment variables ---
# Fornero bite (time-invariant, region-level)
panel <- panel |>
  left_join(fornero_bite |> select(region, fornero_bite), by = "region")

# RdC take-up rate (time-invariant, region-level)
panel <- panel |>
  left_join(rdc_rates |> select(region, rdc_rate, region_name), by = "region")

# --- 4. Create treatment timing indicators ---
panel <- panel |>
  mutate(
    post_fornero = as.integer(year >= 2012),
    post_rdc = as.integer(year >= 2019),
    post_rdc_abolition = as.integer(year >= 2024),
    # Continuous DiD terms
    fornero_x_post = fornero_bite * post_fornero,
    rdc_x_post = rdc_rate * post_rdc,
    # Triple interaction: the key coefficient
    triple = fornero_bite * rdc_rate * post_rdc
  )

# --- 5. Standardize treatment variables for interpretability ---
panel <- panel |>
  mutate(
    fornero_bite_sd = (fornero_bite - mean(fornero_bite, na.rm = TRUE)) /
      sd(fornero_bite, na.rm = TRUE),
    rdc_rate_sd = (rdc_rate - mean(rdc_rate, na.rm = TRUE)) /
      sd(rdc_rate, na.rm = TRUE),
    fornero_x_post_sd = fornero_bite_sd * post_fornero,
    rdc_x_post_sd = rdc_rate_sd * post_rdc,
    triple_sd = fornero_bite_sd * rdc_rate_sd * post_rdc
  )

# --- 6. Summary statistics ---
cat("\n=== Panel summary ===\n")
cat(sprintf("Regions: %d\n", n_distinct(panel$region)))
cat(sprintf("Years: %d (%d-%d)\n", n_distinct(panel$year),
            min(panel$year), max(panel$year)))
cat(sprintf("Total obs: %d\n", nrow(panel)))
cat(sprintf("NEET non-missing: %d\n", sum(!is.na(panel$neet_rate))))
cat(sprintf("Youth employment non-missing: %d\n", sum(!is.na(panel$emp_youth))))

cat("\nFornero bite distribution:\n")
print(summary(panel$fornero_bite[!duplicated(panel$region)]))

cat("\nRdC rate distribution:\n")
print(summary(panel$rdc_rate[!duplicated(panel$region)]))

cat("\nCorrelation(fornero_bite, rdc_rate):",
    round(cor(panel$fornero_bite[!duplicated(panel$region)],
              panel$rdc_rate[!duplicated(panel$region)], use = "complete"), 3), "\n")

# --- 7. Drop regions with missing treatment ---
panel <- panel |> filter(!is.na(fornero_bite) & !is.na(rdc_rate))

cat(sprintf("\nFinal panel: %d obs, %d regions\n", nrow(panel), n_distinct(panel$region)))

# --- 8. Save ---
save(panel, file = "../data/analysis_panel.RData")
cat("Analysis panel saved to data/analysis_panel.RData\n")
