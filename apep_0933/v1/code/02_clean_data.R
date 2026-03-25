## 02_clean_data.R — Clean and merge planning + brownfield data
## APEP paper apep_0933: BNG and Housing Development in England

source("00_packages.R")

data_dir <- "../data"

# ====================================================================
# 1. Read PS2 (planning decisions) — skip 2 header rows, readr handles semicolons
# ====================================================================
cat("=== Reading PS2 ===\n")
ps2 <- readr::read_csv(
  file.path(data_dir, "ps2_raw.csv"),
  skip = 2,
  show_col_types = FALSE,
  guess_max = 5000,
  na = c("..", "", "NA", "z", "x")
)
ps2 <- as.data.table(ps2)
cat("PS2 dimensions:", nrow(ps2), "x", ncol(ps2), "\n")

# Select key columns
ps2_sel <- ps2[, .(
  region = Region,
  la_name = LPANM,
  la_code = LPACD,
  quarter = Quarter,
  total_decisions   = `Total decisions; grand total (all)`,
  total_granted     = `Total granted; grand total (all)`,
  total_refused     = `Total refused; grand total (all)`,
  major_dwell_dec   = `Total decisions; major dwellings (all)`,
  major_dwell_grant = `Total granted; major dwellings (all)`,
  major_dwell_ref   = `Total refused; major dwellings (all)`,
  minor_decisions   = `Total decisions; minor total (all)`,
  minor_granted     = `Total granted; minor total (all)`,
  minor_refused     = `Total refused; minor total (all)`
)]

# Parse quarter
ps2_sel[, year := as.integer(sub(" Q.*", "", quarter))]
ps2_sel[, qtr := as.integer(sub(".*Q", "", quarter))]
ps2_sel[, year_quarter := year + (qtr - 1) / 4]

# Filter to English LAs (E-codes) and recent period
ps2_sel <- ps2_sel[grepl("^E0[6-9]", la_code) & year >= 2015]

# Compute approval rates
ps2_sel[, approval_rate := fifelse(total_decisions > 0, total_granted / total_decisions, NA_real_)]
ps2_sel[, major_approval_rate := fifelse(major_dwell_dec > 0, major_dwell_grant / major_dwell_dec, NA_real_)]

cat("PS2 after cleaning:", nrow(ps2_sel), "rows,", length(unique(ps2_sel$la_code)), "LAs\n")
cat("Quarter range:", min(ps2_sel$quarter), "to", max(ps2_sel$quarter), "\n")

# ====================================================================
# 2. Read PS1 (applications received) — has extra header rows
# ====================================================================
cat("\n=== Reading PS1 ===\n")
ps1 <- readr::read_csv(
  file.path(data_dir, "ps1_raw.csv"),
  skip = 3,
  show_col_types = FALSE,
  guess_max = 5000,
  na = c("..", "", "NA", "z", "x")
)
ps1 <- as.data.table(ps1)
cat("PS1 dimensions:", nrow(ps1), "x", ncol(ps1), "\n")
cat("PS1 col names (first 10):", paste(names(ps1)[1:10], collapse = " | "), "\n")

ps1_sel <- ps1[, .(
  la_code = LPACD,
  quarter = Quarter,
  apps_received = `Applications received`,
  apps_decided  = `Applications decided`
)]

ps1_sel[, year := as.integer(sub(" Q.*", "", quarter))]
ps1_sel <- ps1_sel[grepl("^E0[6-9]", la_code) & year >= 2015]
cat("PS1 after cleaning:", nrow(ps1_sel), "rows\n")

# ====================================================================
# 3. Brownfield Land Register — count sites per LA
# ====================================================================
cat("\n=== Processing Brownfield Land Register ===\n")
blr <- data.table::fread(file.path(data_dir, "brownfield_land.csv"), na.strings = c("", "NA"))
cat("BLR rows:", nrow(blr), "\n")

# Get organisation-entity → GSS LA code mapping
cat("Fetching LA entity → GSS code mapping...\n")
org_url <- "https://files.planning.data.gov.uk/dataset/local-authority.csv"
resp <- httr2::request(org_url) |>
  httr2::req_timeout(60) |>
  httr2::req_error(is_error = function(r) FALSE) |>
  httr2::req_perform()

la_lookup <- NULL
if (httr2::resp_status(resp) == 200) {
  writeBin(httr2::resp_body_raw(resp), file.path(data_dir, "la_entities.csv"))
  la_ent <- data.table::fread(file.path(data_dir, "la_entities.csv"))
  cat("LA entity table:", nrow(la_ent), "x", ncol(la_ent), "\n")
  cat("Columns:", paste(names(la_ent), collapse = ", "), "\n")

  # GSS codes are in statistical-geography column
  if ("statistical-geography" %in% names(la_ent)) {
    la_lookup <- la_ent[, .(org_entity = as.integer(entity),
                            la_code = `statistical-geography`)]
    la_lookup <- la_lookup[grepl("^E0", la_code)]
    cat("LA lookup rows:", nrow(la_lookup), "\n")
  }
}

# Aggregate brownfield by org entity
blr[, hectares_num := as.numeric(hectares)]
blr[, max_dwellings := as.numeric(`maximum-net-dwellings`)]

bf_agg <- blr[, .(
  bf_sites = .N,
  bf_hectares = sum(hectares_num, na.rm = TRUE),
  bf_dwellings = sum(max_dwellings, na.rm = TRUE)
), by = .(`organisation-entity`)]
setnames(bf_agg, "organisation-entity", "org_entity")
bf_agg[, org_entity := as.integer(org_entity)]

cat("Brownfield aggregated:", nrow(bf_agg), "LA entities\n")

# Merge with LA lookup
if (!is.null(la_lookup) && nrow(la_lookup) > 0) {
  bf_la <- merge(bf_agg, la_lookup, by = "org_entity", all.x = TRUE)
  cat("Matched to GSS codes:", sum(!is.na(bf_la$la_code)), "/", nrow(bf_la), "\n")

  # Collapse by LA code (in case multiple entities map to same LA)
  bf_la <- bf_la[!is.na(la_code), .(
    bf_sites = sum(bf_sites),
    bf_hectares = sum(bf_hectares),
    bf_dwellings = sum(bf_dwellings)
  ), by = la_code]
  cat("Unique LAs with brownfield data:", nrow(bf_la), "\n")
} else {
  cat("WARNING: No LA entity mapping available. Trying direct match.\n")
  # As fallback, use the most common entity per E-code in the data
  bf_la <- bf_agg[, .(la_code = NA_character_, bf_sites, bf_hectares, bf_dwellings)]
}

# ====================================================================
# 4. Merge into analysis panel
# ====================================================================
cat("\n=== Merging into analysis panel ===\n")

# Merge PS1 into PS2
panel <- merge(ps2_sel, ps1_sel[, .(la_code, quarter, apps_received, apps_decided)],
               by = c("la_code", "quarter"), all.x = TRUE)

# Merge brownfield
panel <- merge(panel, bf_la, by = "la_code", all.x = TRUE)

# Fill missing brownfield as 0
for (col in c("bf_sites", "bf_hectares", "bf_dwellings")) {
  if (col %in% names(panel)) panel[is.na(get(col)), (col) := 0]
}

# ====================================================================
# 5. Construct treatment variables
# ====================================================================
cat("=== Constructing treatment variables ===\n")

# Post-BNG: 2024 Q1 = first quarter with mandatory BNG for major developments
panel[, post_bng := as.integer(year_quarter >= 2024.0)]

# Treatment intensity: fewer brownfield sites = more exposed to BNG costs
# Use percentile rank (inverted): high intensity = few brownfield = high BNG bite
bf_summary <- unique(panel[, .(la_code, bf_sites, bf_hectares)])
bf_summary[, bf_sites_pctile := rank(bf_sites) / .N]
bf_summary[, bng_intensity := 1 - bf_sites_pctile]

# Binary: above/below median brownfield
bf_summary[, high_exposure := as.integer(bf_sites <= median(bf_sites))]

# Also hectares-based intensity
bf_summary[, bf_hect_pctile := rank(bf_hectares) / .N]
bf_summary[, bng_intensity_hect := 1 - bf_hect_pctile]

panel <- merge(panel, bf_summary[, .(la_code, bng_intensity, high_exposure, bng_intensity_hect)],
               by = "la_code", all.x = TRUE)

# Event time (quarters relative to 2024 Q1)
panel[, event_time := (year - 2024) * 4 + (qtr - 1)]

# DiD interaction
panel[, did_term := post_bng * bng_intensity]

# Log outcomes (add 1 for zeros)
panel[, log_total_granted := log(total_granted + 1)]
panel[, log_apps_received := log(apps_received + 1)]
panel[, log_major_grant := log(major_dwell_grant + 1)]

# ====================================================================
# 6. Summary and save
# ====================================================================
cat("\n=== Panel Summary ===\n")
cat("Rows:", nrow(panel), "\n")
cat("LAs:", length(unique(panel$la_code)), "\n")
cat("Quarters:", length(unique(panel$quarter)), "\n")
cat("Range:", min(panel$quarter), "to", max(panel$quarter), "\n")
cat("Pre-BNG obs:", sum(panel$post_bng == 0, na.rm = TRUE), "\n")
cat("Post-BNG obs:", sum(panel$post_bng == 1, na.rm = TRUE), "\n")

cat("\nBrownfield distribution:\n")
print(summary(bf_summary$bf_sites))

cat("\nBNG intensity distribution:\n")
print(summary(panel$bng_intensity))

cat("\nOutcome means (pre-BNG):\n")
pre <- panel[post_bng == 0]
cat("  Total granted:", round(mean(pre$total_granted, na.rm = TRUE), 1), "\n")
cat("  Major dwelling granted:", round(mean(pre$major_dwell_grant, na.rm = TRUE), 1), "\n")
cat("  Apps received:", round(mean(pre$apps_received, na.rm = TRUE), 1), "\n")
cat("  Approval rate:", round(mean(pre$approval_rate, na.rm = TRUE), 3), "\n")

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nPanel saved.\n")
