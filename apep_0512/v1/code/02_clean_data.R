# ==============================================================================
# 02_clean_data.R — Clean and merge DVF + REI data
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

source("00_packages.R")

# ==============================================================================
# PART 1: Process commune-level DVF (2014-2020)
# ==============================================================================

cat("=== Processing commune-level DVF (2014-2020) ===\n")

dvf_commune <- fread(file.path(data_dir, "dvf_commune_all.csv"), sep = ";")

# Rename to standard names
setnames(dvf_commune, c("anneemut", "codgeo_2020", "nbmut_ventem", "nbmut_ventea",
                          "vfmed_ventem", "vfmed_ventea", "vfm2_ventea", "nbmut_vente"),
         c("year", "code_insee", "n_house_sales", "n_apt_sales",
           "median_price_house", "median_price_apt", "median_price_m2_apt", "n_total_sales"))

# Convert to numeric
dvf_commune[, year := as.integer(year)]
dvf_commune[, n_house_sales := as.numeric(n_house_sales)]
dvf_commune[, n_apt_sales := as.numeric(n_apt_sales)]
dvf_commune[, median_price_house := as.numeric(median_price_house)]
dvf_commune[, median_price_apt := as.numeric(median_price_apt)]
dvf_commune[, median_price_m2_apt := as.numeric(median_price_m2_apt)]
dvf_commune[, n_total_sales := as.numeric(n_total_sales)]

# Ensure code_insee is character with proper formatting
dvf_commune[, code_insee := as.character(code_insee)]
dvf_commune[nchar(code_insee) == 4, code_insee := paste0("0", code_insee)]

# Department code
dvf_commune[, code_dept := substr(code_insee, 1, 2)]
dvf_commune[substr(code_insee, 1, 2) %in% c("97"), code_dept := substr(code_insee, 1, 3)]

cat("  Commune DVF:", nrow(dvf_commune), "rows\n")
cat("  Years:", paste(sort(unique(dvf_commune$year)), collapse = ", "), "\n")
cat("  Communes:", uniqueN(dvf_commune$code_insee), "\n")

# ==============================================================================
# PART 2: Process transaction-level DVF (2021-2024)
# ==============================================================================

cat("\n=== Processing transaction-level DVF (2021-2024) ===\n")

dvf_txn <- fread(file.path(data_dir, "dvf_transactions_2021_2024.csv"))

# Rename columns
old_names <- c("Date mutation", "Nature mutation", "Valeur fonciere",
               "Code postal", "Code commune", "Code departement",
               "Type local", "Surface reelle bati", "Nombre pieces principales")
new_names <- c("date_mutation", "nature_mutation", "valeur_fonciere",
               "code_postal", "code_commune", "code_dept",
               "type_local", "surface_bati", "n_pieces")
setnames(dvf_txn, old_names, new_names, skip_absent = TRUE)

# Parse price (French format: comma decimal)
if (is.character(dvf_txn$valeur_fonciere)) {
  dvf_txn[, valeur_fonciere := as.numeric(gsub(",", ".", valeur_fonciere))]
}

# Clean types
dvf_txn[, surface_bati := as.numeric(surface_bati)]
dvf_txn[, n_pieces := as.numeric(n_pieces)]
dvf_txn[, code_dept := as.character(code_dept)]
dvf_txn[nchar(code_dept) == 1, code_dept := paste0("0", code_dept)]

# Construct INSEE code = dept + commune
dvf_txn[, code_commune := as.character(code_commune)]
dvf_txn[nchar(code_commune) == 2, code_commune := paste0("0", code_commune)]
dvf_txn[, code_insee := paste0(code_dept, code_commune)]

# Filter to residential sales
dvf_txn <- dvf_txn[grepl("Vente", nature_mutation, ignore.case = TRUE)]
dvf_txn[, property_type := fcase(
  grepl("Maison", type_local), "house",
  grepl("Appartement", type_local), "apartment",
  default = "other"
)]
dvf_txn <- dvf_txn[property_type %in% c("house", "apartment")]

# Remove outliers
dvf_txn <- dvf_txn[valeur_fonciere > 10000 & valeur_fonciere < 5e6]
dvf_txn <- dvf_txn[surface_bati > 9 & surface_bati < 500]
dvf_txn[, price_m2 := valeur_fonciere / surface_bati]
dvf_txn <- dvf_txn[price_m2 > 200 & price_m2 < 15000]

cat("  Transaction DVF after cleaning:", nrow(dvf_txn), "rows\n")
print(dvf_txn[, .N, by = property_type])

# Aggregate to commune-year level to match 2014-2020 data
dvf_txn_agg <- dvf_txn[, .(
  n_house_sales = sum(property_type == "house"),
  n_apt_sales = sum(property_type == "apartment"),
  median_price_house = median(valeur_fonciere[property_type == "house"], na.rm = TRUE),
  median_price_apt = median(valeur_fonciere[property_type == "apartment"], na.rm = TRUE),
  median_price_m2_apt = median(price_m2[property_type == "apartment"], na.rm = TRUE),
  median_price_m2_all = median(price_m2[property_type == "apartment"], na.rm = TRUE),
  n_total_sales = .N
), by = .(year, code_insee)]

dvf_txn_agg[, code_dept := substr(code_insee, 1, 2)]
dvf_txn_agg[substr(code_insee, 1, 2) %in% c("97"), code_dept := substr(code_insee, 1, 3)]
dvf_txn_agg[, log_price_house := ifelse(!is.na(median_price_house) & median_price_house > 0,
                                         log(median_price_house), NA_real_)]

cat("  Aggregated to", nrow(dvf_txn_agg), "commune-years\n")

# ==============================================================================
# PART 3: Combine DVF panels (2014-2024)
# ==============================================================================

cat("\n=== Combining DVF panels ===\n")

# For 2014-2020, use apartment price/m2 where available
# For 2021-2024, we also use apartment-only price/m2 for consistency
# This limits coverage to communes with apartment sales in both periods
dvf_commune[, median_price_m2_all := median_price_m2_apt]

# Also create a house-price outcome for robustness using the full commune sample
# log(median_house_price) can serve as an alternative outcome; commune FE absorb levels
dvf_commune[, log_price_house := ifelse(!is.na(median_price_house) & median_price_house > 0,
                                         log(median_price_house), NA_real_)]

# Combine
common_cols <- c("year", "code_insee", "code_dept", "n_house_sales", "n_apt_sales",
                  "median_price_house", "median_price_apt", "median_price_m2_apt",
                  "median_price_m2_all", "log_price_house", "n_total_sales")

dvf_all <- rbindlist(list(
  dvf_commune[, ..common_cols],
  dvf_txn_agg[, ..common_cols]
), fill = TRUE)

cat("  Combined DVF:", nrow(dvf_all), "commune-years\n")
cat("  Years:", paste(sort(unique(dvf_all$year)), collapse = ", "), "\n")

# ==============================================================================
# PART 4: Clean REI data
# ==============================================================================

cat("\n=== Cleaning REI data ===\n")

rei <- fread(file.path(data_dir, "rei_all_years.csv"))

# Rename columns from REI codes to descriptive names
setnames(rei, c("DEP", "COM", "LIBCOM", "H12", "H13", "E12", "E13", "H11", "E11"),
         c("dept", "commune_code", "commune_name", "taux_th", "produit_th",
           "taux_tfb", "produit_tfb", "base_th", "base_tfb"),
         skip_absent = TRUE)

# Clean types
rei[, taux_th := as.numeric(taux_th)]
rei[, taux_tfb := as.numeric(taux_tfb)]
rei[, produit_th := as.numeric(produit_th)]
rei[, produit_tfb := as.numeric(produit_tfb)]
rei[, base_th := as.numeric(base_th)]
rei[, base_tfb := as.numeric(base_tfb)]

# Construct INSEE code = dept + commune
# Fix XML-encoded digits from some xlsx years (e.g., _x0030_ = '0', _x0031_ = '1', etc.)
decode_xml_digits <- function(x) {
  x <- as.character(x)
  # Replace _xHHHH_ patterns with the corresponding Unicode character
  needs_fix <- grepl("_x[0-9a-fA-F]{4}_", x)
  if (any(needs_fix)) {
    x[needs_fix] <- sapply(x[needs_fix], function(s) {
      while (grepl("_x[0-9a-fA-F]{4}_", s)) {
        m <- regmatches(s, regexpr("_x([0-9a-fA-F]{4})_", s))
        hex <- sub("_x([0-9a-fA-F]{4})_", "\\1", m)
        char <- intToUtf8(strtoi(hex, 16L))
        s <- sub("_x[0-9a-fA-F]{4}_", char, s, fixed = FALSE)
      }
      s
    })
  }
  x
}

rei[, dept := decode_xml_digits(dept)]
rei[nchar(dept) == 1, dept := paste0("0", dept)]
rei[, commune_code := decode_xml_digits(commune_code)]
rei[nchar(commune_code) == 2, commune_code := paste0("0", commune_code)]
rei[nchar(commune_code) == 1, commune_code := paste0("00", commune_code)]
rei[, code_insee := paste0(dept, commune_code)]

# Remove rows with missing or zero rates
rei <- rei[!is.na(taux_th) | !is.na(taux_tfb)]
rei <- rei[taux_th >= 0 | is.na(taux_th)]
rei <- rei[taux_tfb >= 0 | is.na(taux_tfb)]

# Compute TH revenue share (measure of fiscal dependence on TH)
rei[, total_direct_tax := produit_th + produit_tfb]
rei[total_direct_tax > 0, th_share := produit_th / total_direct_tax]
rei[total_direct_tax <= 0 | is.na(total_direct_tax), th_share := NA]

cat("  REI cleaned:", nrow(rei), "rows\n")
cat("  Years:", paste(sort(unique(rei$year)), collapse = ", "), "\n")
cat("  TH rate (2017 median):", median(rei[year == 2017]$taux_th, na.rm = TRUE), "%\n")
cat("  TF rate (2017 median):", median(rei[year == 2017]$taux_tfb, na.rm = TRUE), "%\n")

# ==============================================================================
# PART 5: Construct pre-reform treatment intensity
# ==============================================================================

cat("\n=== Constructing treatment intensity ===\n")

# Use 2014-2017 average TH rate as treatment intensity
rei_pre <- rei[year %in% 2014:2017, .(
  th_rate_pre = mean(taux_th, na.rm = TRUE),
  tfb_rate_pre = mean(taux_tfb, na.rm = TRUE),
  th_share_pre = mean(th_share, na.rm = TRUE),
  th_revenue_pre = mean(produit_th, na.rm = TRUE),
  tfb_revenue_pre = mean(produit_tfb, na.rm = TRUE),
  n_pre_years = .N
), by = code_insee]

# Require at least 2 pre-reform years for reliable treatment measure
rei_pre <- rei_pre[n_pre_years >= 2]

# Create quartile bins
rei_pre[, th_quartile := cut(th_rate_pre,
                              breaks = quantile(th_rate_pre, probs = 0:4/4, na.rm = TRUE),
                              labels = paste0("Q", 1:4), include.lowest = TRUE)]

cat("  Treatment intensity for", nrow(rei_pre), "communes\n")
cat("  Pre-reform TH rate distribution:\n")
print(quantile(rei_pre$th_rate_pre, probs = c(0, .1, .25, .5, .75, .9, 1), na.rm = TRUE))

# ==============================================================================
# PART 6: Merge DVF with treatment intensity
# ==============================================================================

cat("\n=== Merging datasets ===\n")

# Merge DVF commune-year data with pre-reform treatment intensity
dvf_merged <- merge(dvf_all, rei_pre, by = "code_insee", all.x = FALSE)

# Merge with annual REI for TF rate (for Part C)
dvf_merged <- merge(dvf_merged,
                     rei[, .(code_insee, year, taux_th_annual = taux_th,
                             taux_tfb_annual = taux_tfb)],
                     by = c("code_insee", "year"), all.x = TRUE)

# Create post-reform indicator and treatment interaction
dvf_merged[, post := as.integer(year >= 2018)]
dvf_merged[, treat_post := th_rate_pre * post]

# Log price
dvf_merged[!is.na(median_price_m2_all) & median_price_m2_all > 0,
            log_price_m2 := log(median_price_m2_all)]

# Drop missing outcome
dvf_merged <- dvf_merged[!is.na(log_price_m2)]

cat("  Merged dataset:", nrow(dvf_merged), "commune-years\n")
cat("  Communes:", uniqueN(dvf_merged$code_insee), "\n")
cat("  Years:", paste(sort(unique(dvf_merged$year)), collapse = ", "), "\n")

# ==============================================================================
# PART 7: Construct Part B panel (commune-year level for fiscal displacement)
# ==============================================================================

cat("\n=== Constructing commune-year fiscal panel ===\n")

commune_panel <- rei[, .(code_insee, year, taux_th, taux_tfb,
                          produit_th, produit_tfb, th_share)]
commune_panel <- merge(commune_panel, rei_pre, by = "code_insee", all.x = FALSE)
commune_panel[, post := as.integer(year >= 2018)]
commune_panel[, th_depend_post := th_share_pre * post]

# Change in TF rate from pre-reform mean
commune_panel <- merge(commune_panel,
                        rei_pre[, .(code_insee, tfb_base = tfb_rate_pre)],
                        by = "code_insee", all.x = TRUE)
commune_panel[, delta_tfb := taux_tfb - tfb_base]

cat("  Commune panel:", nrow(commune_panel), "commune-years\n")

# ==============================================================================
# SAVE
# ==============================================================================

cat("\n=== Saving cleaned data ===\n")

fwrite(dvf_merged, file.path(data_dir, "dvf_analysis.csv"))
fwrite(commune_panel, file.path(data_dir, "commune_panel.csv"))
fwrite(rei_pre, file.path(data_dir, "treatment_intensity.csv"))

cat("Saved:\n")
cat("  dvf_analysis.csv:", nrow(dvf_merged), "rows\n")
cat("  commune_panel.csv:", nrow(commune_panel), "rows\n")
cat("  treatment_intensity.csv:", nrow(rei_pre), "rows\n")

# ==============================================================================
# FINAL VALIDATION
# ==============================================================================

cat("\n=== Final Validation ===\n")
n_communes <- uniqueN(dvf_merged$code_insee)
n_years <- uniqueN(dvf_merged$year)
stopifnot("Expected 5K+ communes in DVF" = n_communes > 5000)
stopifnot("Expected 8+ years in DVF" = n_years >= 8)
cat("VALIDATION PASSED\n")
cat("  Communes:", n_communes, "\n")
cat("  Years:", n_years, "\n")
cat("  Commune-year obs:", nrow(dvf_merged), "\n")
