## ============================================================================
## 02_clean_data.R — Merge data and construct RDD analysis sample
## ============================================================================

source("00_packages.R")

DATA <- "../data"

## ============================================================================
## 1. Load all datasets
## ============================================================================

cat("\n=== Loading data ===\n")
medicaid_drugs  <- readRDS(file.path(DATA, "medicaid_drugs.rds"))
medicaid_nondrug <- readRDS(file.path(DATA, "medicaid_nondrug.rds"))
medicaid_hcbs   <- readRDS(file.path(DATA, "medicaid_hcbs.rds"))
hcris_panel     <- readRDS(file.path(DATA, "hcris_panel.rds"))
medicare_raw    <- readRDS(file.path(DATA, "medicare_drugs_raw.rds"))

SHARED_DATA <- file.path("..", "..", "..", "..", "data", "medicaid_provider_spending")
nppes <- as.data.table(read_parquet(file.path(SHARED_DATA, "nppes_extract.parquet")))
nppes[, npi := as.character(npi)]

## ============================================================================
## 2. Construct hospital-level HCRIS panel
## ============================================================================

cat("\n=== Constructing HCRIS hospital panel ===\n")

hcris_panel[, rpt_rec_num := as.integer(rpt_rec_num)]
hcris_hosp <- hcris_panel[!is.na(dsh_pct),
                           .SD[which.max(rpt_rec_num)],
                           by = .(prvdr_num, fiscal_year)]

# Provider type from 6-digit CCN: digits 3-6 = 0001-0879 for general acute care
hcris_hosp[, prvdr_suffix := as.integer(substr(prvdr_num, 3, 6))]
hcris_hosp[, is_general_acute := prvdr_suffix >= 1 & prvdr_suffix <= 879]

hcris_acute <- hcris_hosp[is_general_acute == TRUE]

# DSH stored as proportion; convert to percentage
hcris_acute[, dsh_pct := dsh_pct * 100]

# Running variable
hcris_acute[, dsh_centered := dsh_pct - 11.75]
hcris_acute[, treated := as.integer(dsh_pct >= 11.75)]

# State from CCN
state_xwalk <- data.table(
  state_code = c("01","02","03","04","05","06","07","08","09","10",
                 "11","12","13","14","15","16","17","18","19","20",
                 "21","22","23","24","25","26","27","28","29","30",
                 "31","32","33","34","35","36","37","38","39","40",
                 "41","42","43","44","45","46","47","48","49","50",
                 "51","52","53","54","55"),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","PR",
                 "RI","SC","SD","TN","TX","UT","VT","VA","VI","WA",
                 "WV","WI","WY","GU","AS")
)
hcris_acute[, state_code := substr(prvdr_num, 1, 2)]
hcris_acute <- merge(hcris_acute, state_xwalk, by = "state_code", all.x = TRUE)

cat(sprintf("General acute care: %d hospital-years, %d unique\n",
            nrow(hcris_acute), uniqueN(hcris_acute$prvdr_num)))
cat(sprintf("DSH: mean=%.1f%%, median=%.1f%%\n",
            mean(hcris_acute$dsh_pct), median(hcris_acute$dsh_pct)))
cat(sprintf("Below 11.75%%: %d (%.1f%%)\n",
            sum(hcris_acute$dsh_pct < 11.75),
            100 * mean(hcris_acute$dsh_pct < 11.75)))
cat(sprintf("Within ±10pp: %d, ±5pp: %d, ±3pp: %d\n",
            sum(abs(hcris_acute$dsh_centered) <= 10),
            sum(abs(hcris_acute$dsh_centered) <= 5),
            sum(abs(hcris_acute$dsh_centered) <= 3)))

## ============================================================================
## 3. Extract hospital ZIP codes from HCRIS
## ============================================================================

cat("\n=== Extracting hospital locations ===\n")

all_hosp_info <- list()

for (yr in 2019:2023) {
  zip_file <- file.path(DATA, "hcris", sprintf("hosp10FY%d.zip", yr))
  zip_contents <- unzip(zip_file, list = TRUE)$Name
  alpha_file <- zip_contents[grepl("alpha", zip_contents, ignore.case = TRUE)]
  rpt_file <- zip_contents[grepl("rpt", zip_contents, ignore.case = TRUE)]
  tmp <- tempdir()
  unzip(zip_file, files = c(alpha_file, rpt_file), exdir = tmp, overwrite = TRUE)

  alpha <- fread(file.path(tmp, alpha_file), header = FALSE,
                 col.names = c("rpt_rec_num", "wksht_cd", "line_num", "clmn_num", "alpha_val"))
  rpt <- fread(file.path(tmp, rpt_file), header = FALSE, select = c(1, 3),
               col.names = c("rpt_rec_num", "prvdr_num"))
  rpt[, prvdr_num := sprintf("%06d", as.integer(prvdr_num))]

  # ZIP from S-2 worksheet line 200 col 300
  zips <- alpha[wksht_cd == "S200001" & line_num == 200 & clmn_num == 300,
                .(rpt_rec_num, hosp_zip = alpha_val)]
  zips[, hosp_zip5 := substr(gsub("[^0-9]", "", hosp_zip), 1, 5)]

  hosp <- merge(rpt, zips[, .(rpt_rec_num, hosp_zip5)], by = "rpt_rec_num")
  hosp <- unique(hosp[nchar(hosp_zip5) == 5, .(prvdr_num, hosp_zip5)])
  all_hosp_info[[as.character(yr)]] <- hosp
  file.remove(file.path(tmp, alpha_file), file.path(tmp, rpt_file))
}

hosp_locs <- unique(rbindlist(all_hosp_info))
hosp_locs <- hosp_locs[, .SD[1], by = prvdr_num]  # One zip per hospital
cat(sprintf("Hospital locations: %d with ZIP\n", nrow(hosp_locs)))

## ============================================================================
## 4. Build CCN-NPI crosswalk using ZIP + taxonomy matching
## ============================================================================

cat("\n=== Building CCN-NPI crosswalk ===\n")

# Hospital NPIs from NPPES (taxonomy 282N = general acute care)
hospital_npis <- nppes[entity_type == "2" & grepl("^282N", taxonomy_1),
                        .(npi, nppes_zip5 = zip5)]

# Match by ZIP code
matched <- merge(hosp_locs, hospital_npis,
                 by.x = "hosp_zip5", by.y = "nppes_zip5",
                 allow.cartesian = TRUE)

# Score matches by Medicaid drug billing (primary data source)
matched <- merge(matched,
                 medicaid_drugs[, .(mcaid_total = sum(mcaid_drug_paid)), by = npi],
                 by = "npi", all.x = TRUE)
matched[is.na(mcaid_total), mcaid_total := 0]

# Keep active NPIs and select best per hospital
matched_active <- matched[mcaid_total > 0]
crosswalk <- matched_active[, .SD[which.max(mcaid_total)], by = prvdr_num]

# For hospitals with no Medicaid-active NPI in their zip, keep any NPI
no_match <- hosp_locs[!prvdr_num %in% crosswalk$prvdr_num]
if (nrow(no_match) > 0) {
  remaining <- merge(no_match, hospital_npis,
                     by.x = "hosp_zip5", by.y = "nppes_zip5",
                     allow.cartesian = TRUE)
  if (nrow(remaining) > 0) {
    remaining <- remaining[, .SD[1], by = prvdr_num]
    remaining[, mcaid_total := 0]
    crosswalk <- rbind(crosswalk, remaining[, names(crosswalk), with = FALSE],
                       fill = TRUE)
  }
}

crosswalk <- crosswalk[, .(prvdr_num, npi)]

cat(sprintf("Crosswalk: %d hospitals matched to NPIs\n", nrow(crosswalk)))
cat(sprintf("Unique NPIs: %d\n", uniqueN(crosswalk$npi)))
saveRDS(crosswalk, file.path(DATA, "ccn_npi_crosswalk.rds"))

## ============================================================================
## 4b. Crosswalk Validation Diagnostics
## ============================================================================

cat("\n=== Crosswalk Validation ===\n")

# Match rate by DSH bin
xwalk_validation <- merge(hcris_acute[, .(prvdr_num, dsh_pct, total_beds, state_abbr)],
                          crosswalk, by = "prvdr_num", all.x = TRUE)
xwalk_validation[, matched := !is.na(npi)]
xwalk_validation[, dsh_bin := cut(dsh_pct,
                                   breaks = c(-Inf, 5, 10, 11.75, 15, 20, Inf),
                                   labels = c("<5%", "5-10%", "10-11.75%",
                                              "11.75-15%", "15-20%", ">20%"))]

# One row per hospital (take first year)
xwalk_hosp <- xwalk_validation[, .SD[1], by = prvdr_num]

match_by_bin <- xwalk_hosp[!is.na(dsh_bin), .(
  n_hospitals = .N,
  n_matched = sum(matched),
  match_rate = round(100 * mean(matched), 1)
), by = dsh_bin]
cat("\nMatch rate by DSH bin:\n")
print(match_by_bin)

# Balance: matched vs unmatched
balance_vars <- xwalk_hosp[!is.na(dsh_pct) & !is.na(total_beds), .(
  group = ifelse(matched, "Matched", "Unmatched"),
  dsh_pct, total_beds
)]
balance_summ <- balance_vars[, .(
  mean_dsh = round(mean(dsh_pct), 1),
  sd_dsh = round(sd(dsh_pct), 1),
  mean_beds = round(mean(total_beds, na.rm = TRUE), 0),
  n = .N
), by = group]
cat("\nBalance: Matched vs Unmatched:\n")
print(balance_summ)

# One-to-many / many-to-one
npis_per_hosp <- crosswalk[, .N, by = prvdr_num]
hosps_per_npi <- crosswalk[, .N, by = npi]
cat(sprintf("\nNPIs per hospital: all 1-to-1 (by construction)\n"))
cat(sprintf("Hospitals per NPI: max=%d, mean=%.2f\n",
            max(hosps_per_npi$N), mean(hosps_per_npi$N)))
cat(sprintf("NPIs matched to >1 hospital: %d (%.1f%%)\n",
            sum(hosps_per_npi$N > 1), 100 * mean(hosps_per_npi$N > 1)))

# Save validation data
saveRDS(list(match_by_bin = match_by_bin,
             balance = balance_summ,
             hosps_per_npi = hosps_per_npi),
        file.path(DATA, "crosswalk_validation.rds"))

## ============================================================================
## 5. Build Medicare comparison: physician drug billing by hospital ZIP
## ============================================================================

cat("\n=== Building Medicare drug measures ===\n")

# Medicare PUF is physician-level. Aggregate by zip for hospital-area comparison.
medicare_zip <- medicare_raw[Rndrng_Prvdr_Ent_Cd == "I", .(
  mcare_drug_paid = sum(as.numeric(Avg_Mdcr_Pymt_Amt) * as.numeric(Tot_Srvcs), na.rm = TRUE),
  mcare_drug_srvcs = sum(as.numeric(Tot_Srvcs), na.rm = TRUE),
  mcare_drug_benes = sum(as.numeric(Tot_Benes), na.rm = TRUE),
  mcare_drug_codes = uniqueN(HCPCS_Cd),
  mcare_n_physicians = uniqueN(Rndrng_NPI)
), by = .(zip5 = Rndrng_Prvdr_Zip5)]

cat(sprintf("Medicare drug billing: %d ZIP codes\n", nrow(medicare_zip)))

## ============================================================================
## 6. Merge everything
## ============================================================================

cat("\n=== Merging datasets ===\n")

# Start with HCRIS acute care panel
analysis <- merge(hcris_acute, crosswalk, by = "prvdr_num", all.x = FALSE)
cat(sprintf("After NPI merge: %d hospital-years\n", nrow(analysis)))

# Add hospital ZIP
analysis <- merge(analysis, hosp_locs, by = "prvdr_num", all.x = TRUE)

# Merge Medicaid drug billing
analysis <- merge(analysis,
                  medicaid_drugs[, .(npi, year, mcaid_drug_paid, mcaid_drug_claims,
                                     mcaid_drug_benes, mcaid_drug_codes)],
                  by.x = c("npi", "fiscal_year"), by.y = c("npi", "year"),
                  all.x = TRUE)

# Merge Medicaid non-drug billing (placebo)
analysis <- merge(analysis,
                  medicaid_nondrug[, .(npi, year, mcaid_nondrug_paid, mcaid_nondrug_claims)],
                  by.x = c("npi", "fiscal_year"), by.y = c("npi", "year"),
                  all.x = TRUE)

# Merge HCBS billing (second placebo)
analysis <- merge(analysis,
                  medicaid_hcbs[, .(npi, year, mcaid_hcbs_paid, mcaid_hcbs_claims)],
                  by.x = c("npi", "fiscal_year"), by.y = c("npi", "year"),
                  all.x = TRUE)

# Merge Medicare zip-level drug billing
analysis <- merge(analysis, medicare_zip,
                  by.x = "hosp_zip5", by.y = "zip5", all.x = TRUE)

# Fill missing billing with 0
billing_cols <- c("mcaid_drug_paid", "mcaid_drug_claims", "mcaid_drug_benes",
                  "mcaid_drug_codes", "mcaid_nondrug_paid", "mcaid_nondrug_claims",
                  "mcaid_hcbs_paid", "mcaid_hcbs_claims",
                  "mcare_drug_paid", "mcare_drug_srvcs", "mcare_drug_benes",
                  "mcare_drug_codes", "mcare_n_physicians")
for (col in billing_cols) {
  if (col %in% names(analysis)) analysis[is.na(get(col)), (col) := 0]
}

## ============================================================================
## 7. Construct outcome variables
## ============================================================================

cat("\n=== Constructing outcomes ===\n")

# Log and asinh transformations
analysis[, log_mcaid_drug := log(mcaid_drug_paid + 1)]
analysis[, log_mcare_drug := log(mcare_drug_paid + 1)]
analysis[, log_mcaid_nondrug := log(mcaid_nondrug_paid + 1)]
analysis[, asinh_mcaid_drug := asinh(mcaid_drug_paid)]
analysis[, asinh_mcare_drug := asinh(mcare_drug_paid)]

# Cross-payer ratio
analysis[, total_drug_paid := mcaid_drug_paid + mcare_drug_paid]
analysis[, mcaid_drug_share := fifelse(total_drug_paid > 0,
                                        mcaid_drug_paid / total_drug_paid, NA_real_)]

# Drug intensity
analysis[, mcaid_drug_per_bene := fifelse(mcaid_drug_benes > 0,
                                           mcaid_drug_paid / mcaid_drug_benes, NA_real_)]

# Indicators
analysis[, has_mcaid_drugs := as.integer(mcaid_drug_paid > 0)]
analysis[, has_mcare_drugs := as.integer(mcare_drug_paid > 0)]

# Bed size categories
analysis[, bed_size := fcase(
  total_beds < 100, "Small",
  total_beds < 300, "Medium",
  total_beds >= 300, "Large",
  default = "Unknown"
)]

## ============================================================================
## 8. Create cross-sectional dataset
## ============================================================================

cat("\n=== Creating cross-sectional dataset ===\n")

analysis_xs <- analysis[, .(
  dsh_pct = mean(dsh_pct),
  dsh_centered = mean(dsh_centered),
  treated = max(treated),
  mcaid_drug_paid = mean(mcaid_drug_paid),
  mcaid_drug_claims = mean(mcaid_drug_claims),
  mcaid_drug_benes = mean(mcaid_drug_benes),
  mcaid_nondrug_paid = mean(mcaid_nondrug_paid),
  mcaid_hcbs_paid = mean(mcaid_hcbs_paid),
  mcare_drug_paid = mean(mcare_drug_paid),
  mcare_drug_srvcs = mean(mcare_drug_srvcs),
  mcare_drug_benes = mean(mcare_drug_benes),
  total_beds = mean(total_beds, na.rm = TRUE),
  n_years = .N,
  state_abbr = first(state_abbr),
  hosp_zip5 = first(hosp_zip5)
), by = .(prvdr_num, npi)]

# Recompute derived
analysis_xs[, log_mcaid_drug := log(mcaid_drug_paid + 1)]
analysis_xs[, log_mcare_drug := log(mcare_drug_paid + 1)]
analysis_xs[, asinh_mcaid_drug := asinh(mcaid_drug_paid)]
analysis_xs[, asinh_mcare_drug := asinh(mcare_drug_paid)]
analysis_xs[, total_drug_paid := mcaid_drug_paid + mcare_drug_paid]
analysis_xs[, mcaid_drug_share := fifelse(total_drug_paid > 0,
                                           mcaid_drug_paid / total_drug_paid, NA_real_)]
analysis_xs[, has_mcaid_drugs := as.integer(mcaid_drug_paid > 0)]
analysis_xs[, has_mcare_drugs := as.integer(mcare_drug_paid > 0)]

cat(sprintf("Panel: %d hospital-years, %d hospitals\n",
            nrow(analysis), uniqueN(analysis$prvdr_num)))
cat(sprintf("Cross-section: %d hospitals\n", nrow(analysis_xs)))
cat(sprintf("  ±10pp: %d, ±5pp: %d, ±3pp: %d\n",
            sum(abs(analysis_xs$dsh_centered) <= 10),
            sum(abs(analysis_xs$dsh_centered) <= 5),
            sum(abs(analysis_xs$dsh_centered) <= 3)))
cat(sprintf("  With Medicaid drugs: %d (%.1f%%)\n",
            sum(analysis_xs$has_mcaid_drugs), 100 * mean(analysis_xs$has_mcaid_drugs)))
cat(sprintf("  With Medicare drugs (zip): %d (%.1f%%)\n",
            sum(analysis_xs$has_mcare_drugs), 100 * mean(analysis_xs$has_mcare_drugs)))

## ============================================================================
## 9. Summary by treatment status
## ============================================================================

cat("\n=== Summary by Treatment (±10pp) ===\n")
rdd_sample <- analysis_xs[abs(dsh_centered) <= 10]
summ <- rdd_sample[, .(
  N = .N,
  mean_dsh = mean(dsh_pct),
  mean_beds = mean(total_beds, na.rm = TRUE),
  mean_mcaid_drug = mean(mcaid_drug_paid),
  mean_mcare_drug = mean(mcare_drug_paid),
  pct_mcaid = 100 * mean(mcaid_drug_paid > 0),
  pct_mcare = 100 * mean(mcare_drug_paid > 0)
), by = treated]
print(summ)

## ============================================================================
## 10. Save
## ============================================================================

saveRDS(analysis, file.path(DATA, "analysis_panel.rds"))
saveRDS(analysis_xs, file.path(DATA, "analysis_xs.rds"))
cat("\n=== Data cleaning complete ===\n")
