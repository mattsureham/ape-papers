## 02_clean_data.R — Clean FJC data, map districts to states, build panel
## apep_0944: AVR and Federal Jury Acquittal Rates

library(data.table)
library(jsonlite)

# setwd handled by caller

# ── 1. Load parsed FJC data ──────────────────────────────────────────────
fjc <- fread("data/fjc_criminal_parsed.csv",
             colClasses = c(district = "character"))
avr <- fread("data/avr_treatment.csv")

cat("FJC records:", nrow(fjc), "\n")

# ── 2. Circuit-District to State mapping ─────────────────────────────────
# Based on FJC IDB codebook for federal judicial districts
# District codes are alphanumeric — mapped from actual data

dist_map <- data.table(
  circuit = c(
    0,
    rep(1, 5),
    rep(2, 6),
    rep(3, 6),
    rep(4, 9),
    rep(5, 9),
    rep(6, 9),
    rep(7, 7),
    rep(8, 10),
    rep(9, 15),
    rep(10, 8),
    rep(11, 9)
  ),
  district = c(
    # DC
    "90",
    # 1st: ME, MA, NH, PR, RI
    "00", "01", "02", "03", "04",
    # 2nd: CT, NY-N, NY-S, NY-E, NY-W, VT
    "05", "06", "07", "08", "09", "10",
    # 3rd: DE, NJ, PA-E, PA-M, PA-W, VI
    "11", "12", "13", "14", "15", "91",
    # 4th: MD, NC-E, NC-M, NC-W, SC, VA-E, VA-W, WV-N, WV-S
    "16", "17", "18", "19", "20", "22", "23", "24", "25",
    # 5th: LA-E, LA-M, LA-W, MS-N, MS-S, TX-E, TX-N, TX-S, TX-W
    "36", "37", "38", "39", "3L", "40", "3N", "41", "42",
    # 6th: KY-E, KY-W, MI-E, MI-W, OH-N, OH-S, TN-E, TN-M, TN-W
    "43", "44", "45", "46", "47", "48", "49", "50", "51",
    # 7th: IL-C, IL-N, IL-S, IN-N, IN-S, WI-E, WI-W
    "52", "53", "54", "55", "56", "57", "58",
    # 8th: AR-E, AR-W, IA-N, IA-S, MN, MO-E, MO-W, NE, ND, SD
    "60", "61", "62", "63", "64", "65", "66", "67", "68", "69",
    # 9th: AK, AZ, CA-C, CA-E, CA-N, CA-S, GU, HI, ID, MT, NV, MP, OR, WA-E, WA-W
    "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "7-", "81", "93", "94",
    # 10th: CO, KS, NM, OK-E, OK-N, OK-W, UT, WY
    "82", "83", "84", "85", "86", "87", "88", "89",
    # 11th: AL-M, AL-N, AL-S, FL-M, FL-N, FL-S, GA-M, GA-N, GA-S
    "26", "27", "28", "29", "3A", "3C", "3E", "3G", "3J"
  ),
  state_abbr = c(
    "DC",
    "ME", "MA", "NH", "PR", "RI",
    "CT", "NY", "NY", "NY", "NY", "VT",
    "DE", "NJ", "PA", "PA", "PA", "VI",
    "MD", "NC", "NC", "NC", "SC", "VA", "VA", "WV", "WV",
    "LA", "LA", "LA", "MS", "MS", "TX", "TX", "TX", "TX",
    "KY", "KY", "MI", "MI", "OH", "OH", "TN", "TN", "TN",
    "IL", "IL", "IL", "IN", "IN", "WI", "WI",
    "AR", "AR", "IA", "IA", "MN", "MO", "MO", "NE", "ND", "SD",
    "AK", "AZ", "CA", "CA", "CA", "CA", "GU", "HI", "ID", "MT", "NV", "MP", "OR", "WA", "WA",
    "CO", "KS", "NM", "OK", "OK", "OK", "UT", "WY",
    "AL", "AL", "AL", "FL", "FL", "FL", "GA", "GA", "GA"
  ),
  district_name = c(
    "DC",
    "ME", "MA", "NH", "PR", "RI",
    "CT", "NY-N", "NY-S", "NY-E", "NY-W", "VT",
    "DE", "NJ", "PA-E", "PA-M", "PA-W", "VI",
    "MD", "NC-E", "NC-M", "NC-W", "SC", "VA-E", "VA-W", "WV-N", "WV-S",
    "LA-E", "LA-M", "LA-W", "MS-N", "MS-S", "TX-E", "TX-N", "TX-S", "TX-W",
    "KY-E", "KY-W", "MI-E", "MI-W", "OH-N", "OH-S", "TN-E", "TN-M", "TN-W",
    "IL-C", "IL-N", "IL-S", "IN-N", "IN-S", "WI-E", "WI-W",
    "AR-E", "AR-W", "IA-N", "IA-S", "MN", "MO-E", "MO-W", "NE", "ND", "SD",
    "AK", "AZ", "CA-C", "CA-E", "CA-N", "CA-S", "GU", "HI", "ID", "MT", "NV", "MP", "OR", "WA-E", "WA-W",
    "CO", "KS", "NM", "OK-E", "OK-N", "OK-W", "UT", "WY",
    "AL-M", "AL-N", "AL-S", "FL-M", "FL-N", "FL-S", "GA-M", "GA-N", "GA-S"
  )
)

cat("District mapping entries:", nrow(dist_map), "\n")

# ── 3. Merge district mapping ───────────────────────────────────────────
fjc[, circuit := as.integer(circuit)]
fjc[, district := as.character(district)]

fjc_merged <- merge(fjc, dist_map, by = c("circuit", "district"), all.x = TRUE)

# Check unmapped records
unmapped <- fjc_merged[is.na(state_abbr)]
if (nrow(unmapped) > 0) {
  cat("\nUnmapped circuit-district combos:\n")
  print(unmapped[, .N, by = .(circuit, district)][order(-N)][1:min(20, .N)])
  cat("Total unmapped:", nrow(unmapped), "of", nrow(fjc_merged),
      "(", round(100 * nrow(unmapped) / nrow(fjc_merged), 1), "%)\n")
}

# Drop territories (PR, VI, GU, MP) — not relevant for AVR
fjc_us <- fjc_merged[!state_abbr %in% c("PR", "VI", "GU", "MP") & !is.na(state_abbr)]
cat("After dropping territories:", nrow(fjc_us), "records\n")

# ── 4. Identify jury verdicts ────────────────────────────────────────────
# FJC IDB DISP1 codes (confirmed from data):
# 3 = Acquitted (jury trial) — 9,262 records
# 9 = Convicted by jury after trial — 62,136 records
cat("\nVerifying jury verdict codes:\n")
cat("  DISP1=3 (acquittal):", fjc_us[disp1 == 3, .N], "records\n")
cat("  DISP1=9 (jury conviction):", fjc_us[disp1 == 9, .N], "records\n")

fjc_us[, jury_acquittal := as.integer(disp1 == 3)]
fjc_us[, jury_conviction := as.integer(disp1 == 9)]

jury_verdicts <- fjc_us[jury_acquittal == 1 | jury_conviction == 1]
cat("\nJury verdicts identified:", nrow(jury_verdicts), "\n")
cat("  Acquittals:", sum(jury_verdicts$jury_acquittal), "\n")
cat("  Convictions:", sum(jury_verdicts$jury_conviction), "\n")
cat("  Overall acquittal rate:",
    round(100 * mean(jury_verdicts$jury_acquittal), 1), "%\n")

# ── 5. Collapse to district-year panel ───────────────────────────────────
jury_verdicts[, dist_id := paste0(circuit, "_", district)]

panel <- jury_verdicts[, .(
  n_acquittals  = sum(jury_acquittal),
  n_convictions = sum(jury_conviction),
  n_verdicts    = .N
), by = .(dist_id, district_name, state_abbr, fiscalyr)]

panel[, acquittal_rate := n_acquittals / n_verdicts]

cat("\nPanel dimensions:\n")
cat("  Districts:", uniqueN(panel$dist_id), "\n")
cat("  Years:", paste(range(panel$fiscalyr), collapse = "-"), "\n")
cat("  Observations:", nrow(panel), "\n")

# ── 6. Merge with AVR treatment ──────────────────────────────────────────
panel <- merge(panel, avr, by = "state_abbr", all.x = TRUE)
panel[is.na(avr_year), avr_year := 0]
panel[, treated := as.integer(avr_year > 0 & fiscalyr >= avr_year)]
panel[, first_treat := avr_year]

cat("\nTreatment distribution:\n")
cat("  AVR states:", uniqueN(panel[avr_year > 0, state_abbr]), "\n")
cat("  Non-AVR states:", uniqueN(panel[avr_year == 0, state_abbr]), "\n")
cat("  Treated district-years:", sum(panel$treated), "\n")
cat("  Control district-years:", sum(!panel$treated), "\n")

# ── 7. Filter panel for analysis ─────────────────────────────────────────
panel <- panel[fiscalyr >= 2000 & fiscalyr <= 2024]

# Drop districts with very few observations
dist_counts <- panel[, .(mean_verdicts = mean(n_verdicts), n_years = .N), by = dist_id]
keep_dists <- dist_counts[mean_verdicts >= 3 & n_years >= 10, dist_id]
panel <- panel[dist_id %in% keep_dists]

cat("\nAfter filtering:\n")
cat("  Districts:", uniqueN(panel$dist_id), "\n")
cat("  Years:", paste(range(panel$fiscalyr), collapse = "-"), "\n")
cat("  Observations:", nrow(panel), "\n")
cat("  Mean verdicts per district-year:", round(mean(panel$n_verdicts), 1), "\n")

# ── 8. Summary statistics ───────────────────────────────────────────────
cat("\n=== Summary Statistics ===\n")
cat("Acquittal rate — Mean:", round(mean(panel$acquittal_rate), 3),
    " SD:", round(sd(panel$acquittal_rate), 3), "\n")
cat("Verdicts per district-year — Mean:", round(mean(panel$n_verdicts), 1),
    " SD:", round(sd(panel$n_verdicts), 1), "\n")

cat("\nAVR cohort sizes (districts):\n")
print(panel[first_treat > 0, .(n_districts = uniqueN(dist_id)), by = first_treat][order(first_treat)])
cat("Never-treated districts:", uniqueN(panel[first_treat == 0, dist_id]), "\n")

# ── 9. Save analysis panel ──────────────────────────────────────────────
fwrite(panel, "data/analysis_panel.csv")
cat("\nSaved analysis panel:", nrow(panel), "rows\n")

summary_stats <- list(
  n_districts = uniqueN(panel$dist_id),
  n_years = uniqueN(panel$fiscalyr),
  n_obs = nrow(panel),
  n_treated_states = uniqueN(panel[avr_year > 0, state_abbr]),
  n_control_states = uniqueN(panel[avr_year == 0, state_abbr]),
  n_treated_districts = uniqueN(panel[avr_year > 0, dist_id]),
  n_control_districts = uniqueN(panel[avr_year == 0, dist_id]),
  mean_acquittal_rate = mean(panel$acquittal_rate),
  sd_acquittal_rate = sd(panel$acquittal_rate),
  mean_verdicts = mean(panel$n_verdicts),
  total_verdicts = sum(panel$n_verdicts),
  total_acquittals = sum(panel$n_acquittals),
  year_range = paste(range(panel$fiscalyr), collapse = "-")
)
write_json(summary_stats, "data/summary_stats.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== 02_clean_data.R complete ===\n")
