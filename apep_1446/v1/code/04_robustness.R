## 04_robustness.R — Robustness checks and placebo tests
## apep_1446: X-waiver elimination and buprenorphine desert entry

source("00_packages.R")

DATA <- "../data"

## ---- 1. Load data ----
panel <- as.data.table(read_parquet(file.path(DATA, "county_month_panel.parquet")))
panel <- panel[ym >= as.Date("2020-01-01") & ym <= as.Date("2024-06-01")]
panel[, ym_fe := as.factor(ym)]
panel[, county_fe := as.factor(county_fips)]
panel[, post := ym >= as.Date("2023-01-01")]
panel[, post_num := as.integer(post)]
panel[, desert_num := as.integer(desert)]
panel[, desert_1_num := as.integer(desert_1)]
panel[, desert_2_num := as.integer(desert_2)]

## ---- 2. Alternative desert thresholds ----
cat("=== Alternative desert thresholds ===\n")

did_d1 <- feols(new_entrants ~ desert_1_num:post_num | county_fe + ym_fe,
                data = panel, cluster = ~county_fips)
cat("Desert ≤ 1 NPI:\n")
summary(did_d1)

did_d2 <- feols(new_entrants ~ desert_2_num:post_num | county_fe + ym_fe,
                data = panel, cluster = ~county_fips)
cat("Desert ≤ 2 NPIs:\n")
summary(did_d2)

## ---- 3. Placebo test: non-buprenorphine J-codes ----
# Load T-MSIS for placebo drugs (e.g., J1745 infliximab - common non-OUD injectable)
cat("=== Placebo: non-buprenorphine injectables ===\n")
SHARED_DATA <- file.path("..", "..", "..", "..", "data", "medicaid_provider_spending")
tmsis_ds <- open_dataset(file.path(SHARED_DATA, "tmsis.parquet"))

# Use J1745 (infliximab) as placebo — common injectable, unrelated to OUD
placebo_codes <- c("J1745")
placebo_raw <- tmsis_ds |>
  filter(HCPCS_CODE %in% placebo_codes) |>
  select(BILLING_PROVIDER_NPI_NUM, SERVICING_PROVIDER_NPI_NUM,
         HCPCS_CODE, CLAIM_FROM_MONTH) |>
  collect()
setDT(placebo_raw)

placebo_raw[, ym := as.Date(paste0(CLAIM_FROM_MONTH, "-01"))]
placebo_raw[, provider_npi := fifelse(
  !is.na(SERVICING_PROVIDER_NPI_NUM) & SERVICING_PROVIDER_NPI_NUM != "",
  SERVICING_PROVIDER_NPI_NUM,
  BILLING_PROVIDER_NPI_NUM
)]

# Count new entrants for placebo drug
npi_county <- as.data.table(read_parquet(file.path(DATA, "npi_county.parquet")))
placebo_geo <- merge(placebo_raw, npi_county[, .(npi, county_fips)],
                     by.x = "provider_npi", by.y = "npi", all.x = FALSE)
placebo_entry <- placebo_geo[, .(first_month = min(ym)), by = provider_npi]
placebo_entry[, new_entrant := first_month >= as.Date("2023-01-01")]

placebo_new <- placebo_geo[provider_npi %in% placebo_entry[new_entrant == TRUE, provider_npi]]
placebo_new <- placebo_new[, .SD[ym == min(ym)], by = provider_npi]
placebo_counts <- placebo_new[, .(placebo_entrants = .N), by = .(county_fips, ym)]

# Merge into panel
panel_placebo <- merge(panel[, .(county_fips, ym, desert, post, county_fe, ym_fe)],
                       placebo_counts, by = c("county_fips", "ym"), all.x = TRUE)
panel_placebo[is.na(placebo_entrants), placebo_entrants := 0]

panel_placebo[, desert_num := as.integer(desert)]
panel_placebo[, post_num := as.integer(post)]
did_placebo <- feols(placebo_entrants ~ desert_num:post_num | county_fe + ym_fe,
                     data = panel_placebo, cluster = ~county_fips)
cat("Placebo (infliximab J1745):\n")
summary(did_placebo)

## ---- 4. Permutation inference ----
cat("\n=== Permutation inference ===\n")
set.seed(42)
n_perm <- 500

# Get the actual coefficient
actual_coef <- coef(feols(new_entrants ~ desert_num:post_num | county_fe + ym_fe,
                          data = panel, cluster = ~county_fips))["desert_num:post_num"]

# Permute desert labels across counties
counties_unique <- unique(panel[, .(county_fips, desert_num)])
perm_coefs <- numeric(n_perm)

for (i in 1:n_perm) {
  perm_labels <- copy(counties_unique)
  perm_labels[, desert_perm := sample(desert_num)]
  panel_perm <- merge(panel[, .(county_fips, ym, new_entrants, post_num, county_fe, ym_fe)],
                      perm_labels[, .(county_fips, desert_perm)],
                      by = "county_fips")
  fit_perm <- tryCatch(
    feols(new_entrants ~ desert_perm:post_num | county_fe + ym_fe,
          data = panel_perm, cluster = ~county_fips),
    error = function(e) NULL
  )
  if (!is.null(fit_perm)) {
    perm_coefs[i] <- coef(fit_perm)["desert_perm:post_num"]
  } else {
    perm_coefs[i] <- NA
  }
  if (i %% 100 == 0) cat(sprintf("  Permutation %d / %d\n", i, n_perm))
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("Actual coefficient: %.5f\n", actual_coef))
cat(sprintf("Permutation p-value (two-sided): %.3f\n", perm_p))
cat(sprintf("Permutations completed: %d\n", length(perm_coefs)))

## ---- 5. Entrant survival (stop billing within 6 months) ----
cat("\n=== New entrant survival ===\n")
npi_entry <- as.data.table(read_parquet(file.path(DATA, "npi_entry.parquet")))
bup <- as.data.table(read_parquet(file.path(DATA, "bup_claims.parquet")))

new_npis <- npi_entry[new_entrant == TRUE, provider_npi]
# For each new entrant, check if they bill again 6+ months after first billing
survival <- bup[provider_npi %in% new_npis,
                .(first_month = min(ym), last_month = max(ym), n_months = uniqueN(ym)),
                by = provider_npi]
survival[, survived_6m := as.numeric(last_month) - as.numeric(first_month) >= 180]
new_npi_county <- as.data.table(read_parquet(file.path(DATA, "new_npi_county.parquet")))
survival <- merge(survival, new_npi_county[, .(provider_npi, is_desert)],
                  by = "provider_npi", all.x = TRUE)

surv_stats <- survival[, .(
  n = .N,
  survived = sum(survived_6m, na.rm = TRUE),
  surv_rate = mean(survived_6m, na.rm = TRUE),
  median_months = median(n_months)
), by = is_desert]
cat("Survival by desert status:\n")
print(surv_stats)

## ---- 6. Save robustness results ----
rob_results <- list(
  did_d1 = did_d1,
  did_d2 = did_d2,
  did_placebo = did_placebo,
  perm_p = perm_p,
  perm_coefs = perm_coefs,
  actual_coef = actual_coef,
  surv_stats = surv_stats
)
saveRDS(rob_results, file.path(DATA, "robustness_results.rds"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
