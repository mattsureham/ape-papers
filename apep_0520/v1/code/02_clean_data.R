## ============================================================================
## 02_clean_data.R — Construct analysis samples and validate panel
## ============================================================================

source("00_packages.R")

DATA <- "../data"
panel <- readRDS(file.path(DATA, "panel_state_month.rds"))
waiver_dates <- fread(file.path(DATA, "waiver_dates.csv"))

## ---- 1. Analysis Sample: Exclude Always-Treated ----
# Main analysis: states with ≥6 months pre-treatment + never-treated controls
# Exclude early adopters (waiver before July 2018) from main DiD estimation

main_sample <- panel[always_treated == FALSE | is.na(waiver_date)]
cat(sprintf("Main sample: %d states (%d treated, %d never-treated)\n",
            uniqueN(main_sample$state),
            uniqueN(main_sample[!is.na(waiver_date), state]),
            uniqueN(main_sample[is.na(waiver_date), state])))

## ---- 2. Summary Statistics ----
cat("\n--- Pre-treatment means (2018) ---\n")
pre_means <- main_sample[year(month_date) == 2018, .(
  mean_bh_providers = mean(bh_providers),
  mean_sud_providers = mean(sud_providers),
  mean_mat_providers = mean(mat_providers),
  mean_bh_claims = mean(bh_claims),
  mean_sud_claims = mean(sud_claims),
  mean_bh_beneficiaries = mean(bh_beneficiaries),
  mean_pc_providers = mean(pc_providers),
  mean_bh_paid = mean(bh_paid),
  sd_bh_providers = sd(bh_providers)
), by = .(has_waiver = !is.na(waiver_date))]

print(pre_means)

## ---- 3. Provider Entry/Exit Panel ----
# For extensive margin analysis: track new NPI entries per state × month
# A "new entrant" = NPI that bills H-codes in state s at month t but did NOT
# bill H-codes in state s in any prior month.

# We need NPI-level data for this. Reload a subset.
cat("Building provider entry panel from T-MSIS...\n")

tmsis_ds <- open_dataset(file.path("..", "..", "..", "..", "data",
                                    "medicaid_provider_spending", "tmsis.parquet"))

# Get NPI → state mapping
nppes <- as.data.table(read_parquet(
  file.path("..", "..", "..", "..", "data", "medicaid_provider_spending", "nppes_extract.parquet")
))
nppes[, npi := as.character(npi)]
npi_state <- nppes[!is.na(state) & state != "", .(npi, state, entity_type)]

load(file.path(DATA, "hcpcs_classification.RData"))

# Aggregate: which NPIs bill H-codes in which month?
h_npi_month <- tmsis_ds |>
  filter(substr(HCPCS_CODE, 1, 1) == "H") |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH) |>
  summarize(
    h_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    h_paid = sum(TOTAL_PAID, na.rm = TRUE),
    h_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(h_npi_month, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"),
         c("billing_npi", "month_str"))
h_npi_month[, month_date := as.Date(paste0(month_str, "-01"))]

# Join state
h_npi_month <- merge(h_npi_month, npi_state, by.x = "billing_npi", by.y = "npi", all.x = TRUE)
h_npi_month <- h_npi_month[!is.na(state)]

# Track first appearance per NPI × state
h_npi_month[, first_month := min(month_date), by = .(billing_npi, state)]
h_npi_month[, is_entrant := month_date == first_month]

# Count entrants per state × month
entry_panel <- h_npi_month[, .(
  new_bh_providers = sum(is_entrant),
  total_bh_npis = uniqueN(billing_npi),
  new_org_providers = sum(is_entrant & entity_type == "2"),
  new_indiv_providers = sum(is_entrant & entity_type == "1")
), by = .(state, month_date)]

# Merge onto main panel
main_sample <- merge(main_sample, entry_panel, by = c("state", "month_date"), all.x = TRUE)
for (col in c("new_bh_providers", "total_bh_npis", "new_org_providers", "new_indiv_providers")) {
  main_sample[is.na(get(col)), (col) := 0]
}

main_sample[, `:=`(
  ln_new_bh_providers = log(new_bh_providers + 1),
  ln_new_org_providers = log(new_org_providers + 1),
  ln_total_bh_npis = log(total_bh_npis + 1)
)]

## ---- 4. SUD-specific provider entry ----
sud_npi_month <- tmsis_ds |>
  filter(HCPCS_CODE %in% sud_h_codes) |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH) |>
  summarize(
    sud_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    sud_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(sud_npi_month, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"),
         c("billing_npi", "month_str"))
sud_npi_month[, month_date := as.Date(paste0(month_str, "-01"))]
sud_npi_month <- merge(sud_npi_month, npi_state, by.x = "billing_npi", by.y = "npi", all.x = TRUE)
sud_npi_month <- sud_npi_month[!is.na(state)]

sud_npi_month[, first_month := min(month_date), by = .(billing_npi, state)]
sud_npi_month[, is_entrant := month_date == first_month]

sud_entry_panel <- sud_npi_month[, .(
  new_sud_providers = sum(is_entrant),
  total_sud_npis = uniqueN(billing_npi)
), by = .(state, month_date)]

main_sample <- merge(main_sample, sud_entry_panel, by = c("state", "month_date"), all.x = TRUE)
for (col in c("new_sud_providers", "total_sud_npis")) {
  main_sample[is.na(get(col)), (col) := 0]
}
main_sample[, ln_new_sud_providers := log(new_sud_providers + 1)]

## ---- 5. Intensive margin: claims per provider ----
main_sample[, `:=`(
  bh_claims_per_provider = fifelse(bh_providers > 0, bh_claims / bh_providers, 0),
  sud_claims_per_provider = fifelse(sud_providers > 0, sud_claims / sud_providers, 0),
  bh_benef_per_provider = fifelse(bh_providers > 0, bh_beneficiaries / bh_providers, 0),
  sud_benef_per_provider = fifelse(sud_providers > 0, sud_beneficiaries / sud_providers, 0)
)]

## ---- 6. Save analysis datasets ----
saveRDS(main_sample, file.path(DATA, "main_sample.rds"))
fwrite(main_sample, file.path(DATA, "main_sample.csv"))

# Save entry-level data for mechanism analysis
saveRDS(h_npi_month, file.path(DATA, "h_npi_month.rds"))

cat(sprintf("\nMain analysis sample: %d obs, %d states, %d months\n",
            nrow(main_sample), uniqueN(main_sample$state), uniqueN(main_sample$month_date)))
cat(sprintf("Treated states in main sample: %d\n",
            uniqueN(main_sample[!is.na(waiver_date), state])))
cat(sprintf("Never-treated states: %d\n",
            uniqueN(main_sample[is.na(waiver_date), state])))
cat("\n=== Clean data complete ===\n")

rm(tmsis_ds, nppes, h_npi_month, sud_npi_month)
gc()
