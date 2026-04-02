## ============================================================================
## 01_fetch_data.R — Data acquisition for apep_1327
## Chain pharmacy closures → Medicaid utilization
##
## Strategy:
##   Step 1: Identify chain pharmacy NPIs via NPPES
##   Step 2: Extract their billing history from T-MSIS to detect closures
##   Step 3: Aggregate chain pharmacy billing to ZIP × month (pharmacy outcomes)
##   Step 4: Small targeted query for ED codes only (health outcomes)
## ============================================================================

source("00_packages.R")

SHARED_DATA <- file.path("..", "..", "..", "..", "data", "medicaid_provider_spending")
DATA <- "../data"
dir.create(DATA, showWarnings = FALSE, recursive = TRUE)

## ---- 1. Load NPPES extract ----
cat("Loading NPPES extract...\n")
nppes_path <- file.path(SHARED_DATA, "nppes_extract.parquet")
stopifnot(file.exists(nppes_path))
nppes <- as.data.table(read_parquet(nppes_path))
nppes[, npi := as.character(npi)]
cat(sprintf("NPPES: %s providers loaded\n", format(nrow(nppes), big.mark = ",")))

## ---- 2. Identify chain pharmacy NPIs ----
pharmacy_taxonomies <- c("3336C0003X", "332B00000X", "333600000X")
pharmacies <- nppes[taxonomy_1 %in% pharmacy_taxonomies | taxonomy_2 %in% pharmacy_taxonomies]

chain_patterns <- list(
  "CVS" = "CVS|CAREMARK|LONGS DRUG",
  "WALGREENS" = "WALGREEN|WAG.STORE|DUANE READE",
  "RITE_AID" = "RITE.AID|RITE AID"
)

pharmacies[, chain := NA_character_]
for (cn in names(chain_patterns)) {
  pharmacies[is.na(chain) & grepl(chain_patterns[[cn]], toupper(org_name)), chain := cn]
}

chain_pharm <- pharmacies[!is.na(chain)]
chain_pharm[, zip5 := substr(gsub("[^0-9]", "", zip), 1, 5)]
chain_pharm <- chain_pharm[nchar(zip5) == 5 & zip5 != ""]

cat(sprintf("Chain pharmacy NPIs: CVS=%d, Walgreens=%d, RiteAid=%d, Total=%d\n",
            sum(chain_pharm$chain == "CVS"),
            sum(chain_pharm$chain == "WALGREENS"),
            sum(chain_pharm$chain == "RITE_AID"),
            nrow(chain_pharm)))

## ---- 3. Extract chain pharmacy billing from T-MSIS ----
cat("\nOpening T-MSIS...\n")
tmsis_path <- file.path(SHARED_DATA, "tmsis.parquet")
stopifnot(file.exists(tmsis_path))
tmsis_ds <- open_dataset(tmsis_path)

chain_npi_set <- unique(chain_pharm$npi)

cat(sprintf("Querying T-MSIS for %d chain pharmacy NPIs...\n", length(chain_npi_set)))
chain_billing <- tmsis_ds |>
  filter(BILLING_PROVIDER_NPI_NUM %in% chain_npi_set) |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH) |>
  summarize(
    total_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    total_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    total_paid = sum(TOTAL_PAID, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(chain_billing, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"), c("npi", "month"))
chain_billing[, month_date := as.Date(paste0(month, "-01"))]

cat(sprintf("Chain billing: %s rows, %d unique NPIs\n",
            format(nrow(chain_billing), big.mark = ","), uniqueN(chain_billing$npi)))

## ---- 4. Detect closures from billing patterns ----
npi_span <- chain_billing[, .(
  first_month = min(month_date),
  last_month = max(month_date),
  n_months = uniqueN(month_date),
  total_claims = sum(total_claims),
  avg_monthly_claims = mean(total_claims)
), by = npi]

data_end <- as.Date("2024-12-01")
# Closed = stopped billing at least 3 months before data end + had 6+ months
npi_span[, closed := (last_month <= data_end - 90) & (n_months >= 6)]
npi_span[, closure_month := fifelse(closed, last_month, as.Date(NA))]

# Join chain + geography info
npi_span <- merge(npi_span, chain_pharm[, .(npi, chain, zip5, state)],
                  by = "npi", all.x = TRUE)

cat(sprintf("\nClosures detected: %d / %d NPIs\n",
            sum(npi_span$closed, na.rm = TRUE), nrow(npi_span)))
cat("By chain:\n")
print(npi_span[closed == TRUE, .N, by = chain])
cat("By year:\n")
print(npi_span[closed == TRUE, .(N = .N), by = .(year = format(closure_month, "%Y"))][order(year)])

## ---- 5. Build ZIP-level treatment variables ----
zip_pharmacy <- npi_span[!is.na(zip5), .(
  n_chain_npis = .N,
  n_open = sum(!closed, na.rm = TRUE),
  n_closed = sum(closed, na.rm = TRUE),
  has_rite_aid = any(chain == "RITE_AID"),
  rite_aid_closed = any(chain == "RITE_AID" & closed == TRUE),
  first_closure_date = suppressWarnings(min(closure_month[closed == TRUE], na.rm = TRUE))
), by = zip5]

zip_pharmacy[is.infinite(first_closure_date), first_closure_date := as.Date(NA)]
zip_pharmacy[, treated := !is.na(first_closure_date)]
zip_pharmacy[, last_pharmacy_closed := (n_open == 0 & n_closed > 0)]

cat(sprintf("\nZIP treatment: %d ZIPs, %d treated, %d control, %d last-pharmacy\n",
            nrow(zip_pharmacy), sum(zip_pharmacy$treated),
            sum(!zip_pharmacy$treated), sum(zip_pharmacy$last_pharmacy_closed)))

## ---- 6. Build ZIP × month pharmacy outcome from chain billing ----
cat("\nBuilding ZIP × month pharmacy panel from chain billing...\n")

# Join ZIP to chain billing
chain_billing_zip <- merge(chain_billing, npi_span[, .(npi, zip5, chain)],
                           by = "npi", all.x = TRUE)
chain_billing_zip <- chain_billing_zip[!is.na(zip5)]

# ZIP × month pharmacy outcomes
zip_pharmacy_monthly <- chain_billing_zip[, .(
  pharmacy_claims = sum(total_claims),
  pharmacy_beneficiaries = sum(total_beneficiaries),
  pharmacy_paid = sum(total_paid),
  pharmacy_providers = uniqueN(npi)
), by = .(zip5, month, month_date)]

cat(sprintf("ZIP × month pharmacy panel: %s rows\n",
            format(nrow(zip_pharmacy_monthly), big.mark = ",")))

## ---- 7. Targeted T-MSIS query for ED visits ----
cat("\nQuerying T-MSIS for ED visit codes (small query)...\n")

# Only query ED codes — this is a tiny fraction of 227M rows
ed_codes <- c("99281", "99282", "99283", "99284", "99285")

ed_billing <- tmsis_ds |>
  filter(HCPCS_CODE %in% ed_codes) |>
  group_by(BILLING_PROVIDER_NPI_NUM, CLAIM_FROM_MONTH) |>
  summarize(
    ed_claims = sum(TOTAL_CLAIMS, na.rm = TRUE),
    ed_beneficiaries = sum(TOTAL_UNIQUE_BENEFICIARIES, na.rm = TRUE),
    ed_paid = sum(TOTAL_PAID, na.rm = TRUE),
    .groups = "drop"
  ) |>
  collect() |>
  as.data.table()

setnames(ed_billing, c("BILLING_PROVIDER_NPI_NUM", "CLAIM_FROM_MONTH"),
         c("billing_npi", "month"))
cat(sprintf("ED billing: %s rows\n", format(nrow(ed_billing), big.mark = ",")))

# Get NPI → ZIP mapping
npi_zip <- nppes[!is.na(zip5) & zip5 != "" & nchar(zip5) >= 5,
                 .(npi = as.character(npi),
                   zip5 = substr(gsub("[^0-9]", "", zip), 1, 5))]

# Join ZIP, filter to target ZIPs
ed_billing <- merge(ed_billing, npi_zip, by.x = "billing_npi", by.y = "npi", all.x = TRUE)
ed_billing <- ed_billing[!is.na(zip5) & zip5 %in% zip_pharmacy$zip5]

# Aggregate to ZIP × month
zip_ed_monthly <- ed_billing[, .(
  ed_claims = sum(ed_claims),
  ed_beneficiaries = sum(ed_beneficiaries),
  ed_paid = sum(ed_paid),
  ed_providers = uniqueN(billing_npi)
), by = .(zip5, month)]

zip_ed_monthly[, month_date := as.Date(paste0(month, "-01"))]
cat(sprintf("ZIP × month ED panel: %s rows\n", format(nrow(zip_ed_monthly), big.mark = ",")))

## ---- 8. Merge into final panel ----
cat("\nMerging pharmacy + ED panels...\n")

panel <- merge(zip_pharmacy_monthly, zip_ed_monthly[, .(zip5, month, ed_claims, ed_beneficiaries, ed_paid, ed_providers)],
               by = c("zip5", "month"), all = TRUE)

# Fill NAs with 0
for (col in c("pharmacy_claims", "pharmacy_beneficiaries", "pharmacy_paid",
              "ed_claims", "ed_beneficiaries", "ed_paid")) {
  panel[is.na(get(col)), (col) := 0]
}

# Ensure month_date exists
panel[is.na(month_date), month_date := as.Date(paste0(month, "-01"))]

# Merge treatment info
panel <- merge(panel, zip_pharmacy, by = "zip5", all.x = TRUE)

# Event time
panel[, event_time := as.integer(round(as.numeric(
  difftime(month_date, first_closure_date, units = "days")) / 30.44))]

# Post indicator
panel[, post := !is.na(first_closure_date) & month_date > first_closure_date]

# Rite Aid IV
panel[, rite_aid_iv := as.integer(has_rite_aid == TRUE) *
        as.integer(month_date >= as.Date("2023-10-01"))]

# Year-month for FE
panel[, ym := as.integer(format(month_date, "%Y")) * 12 +
        as.integer(format(month_date, "%m"))]

# Derived variables
panel[, log_pharmacy_claims := log(pharmacy_claims + 1)]
panel[, log_ed_claims := log(ed_claims + 1)]
panel[, log_pharmacy_beneficiaries := log(pharmacy_beneficiaries + 1)]
panel[, log_pharmacy_paid := log(pharmacy_paid + 1)]
panel[, asinh_pharmacy_claims := asinh(pharmacy_claims)]
panel[, asinh_ed_claims := asinh(ed_claims)]

# Treatment group labels
panel[, ever_treated := treated == TRUE & !is.na(treated)]
panel[, control := !treated | is.na(treated)]
panel[, last_pharm := last_pharmacy_closed == TRUE & !is.na(last_pharmacy_closed)]
panel[, event_time_binned := pmax(pmin(event_time, 24), -24)]

# Pre-treatment flag
panel[, pre_treatment := fifelse(ever_treated, month_date < first_closure_date, TRUE)]

cat(sprintf("\n=== Final Panel ===\n"))
cat(sprintf("  Rows: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  ZIPs: %s (treated=%d, control=%d)\n",
            format(uniqueN(panel$zip5), big.mark = ","),
            sum(zip_pharmacy$treated), sum(!zip_pharmacy$treated)))
cat(sprintf("  Months: %d (%s to %s)\n",
            uniqueN(panel$month_date), min(panel$month_date), max(panel$month_date)))

## ---- 9. Save ----
saveRDS(panel, file.path(DATA, "panel.rds"))
saveRDS(zip_pharmacy, file.path(DATA, "zip_pharmacy.rds"))
saveRDS(npi_span, file.path(DATA, "npi_span.rds"))

cat("=== Data preparation complete ===\n")
