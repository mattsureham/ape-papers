## 01_fetch_data.R — Download DVF + TLV zoning data
## TLV Vacancy Tax Expansion — apep_0523

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. TLV Commune Zoning
# ===========================================================================
cat("=== Fetching TLV commune zoning ===\n")
tlv_url <- "https://static.data.gouv.fr/resources/liste-des-communes-selon-le-zonage-tlv-1/20251230-094759/zonage-tlv-decret-22-dec-2025.csv"
tlv_file <- file.path(data_dir, "zonage_tlv.csv")

tryCatch({
  download.file(tlv_url, tlv_file, mode = "wb", quiet = TRUE)
}, error = function(e) stop("TLV zoning data unavailable: ", e$message,
                            "\nPivot research question or fix the source."))

tlv <- fread(tlv_file, encoding = "UTF-8")
setnames(tlv, c("codgeo", "dep", "libgeo", "code_epci", "lib_epci",
                "tlv_2013", "tlv_2023", "tlv_2025"))

cat("TLV zoning loaded:", nrow(tlv), "communes\n")
cat("  TLV 2013 distribution:\n")
print(table(tlv$tlv_2013))
cat("  TLV 2023 distribution:\n")
print(table(tlv$tlv_2023))

# Create treatment groups
tlv[, group := fcase(
  tlv_2013 == "TLV" & tlv_2023 %in% c("1. Zone tendue", "2. Zone touristique et tendue"), "always_treated",
  tlv_2013 == "Non TLV" & tlv_2023 %in% c("1. Zone tendue", "2. Zone touristique et tendue"), "newly_treated_2023",
  tlv_2013 == "TLV" & tlv_2023 == "3. Non tendue", "lost_treatment",
  default = "never_treated"
)]
cat("\nTreatment groups:\n")
print(table(tlv$group))

# Zone type for heterogeneity
tlv[, zone_type := fcase(
  tlv_2023 == "1. Zone tendue", "tendue",
  tlv_2023 == "2. Zone touristique et tendue", "touristique",
  default = "non_tendue"
)]

fwrite(tlv, file.path(data_dir, "tlv_zoning_clean.csv"))
cat("TLV zoning saved.\n\n")

# ===========================================================================
# 2. DVF Property Transactions (2020-2025)
# ===========================================================================
cat("=== Fetching DVF property transactions ===\n")

dvf_base_url <- "https://files.data.gouv.fr/geo-dvf/latest/csv"
years <- 2020:2025

# Get list of all departments
dep_list <- c(sprintf("%02d", 1:19), "2A", "2B", sprintf("%02d", 21:95))

all_dvf <- list()

for (yr in years) {
  cat(sprintf("  Year %d: ", yr))
  yr_data <- list()

  for (dep in dep_list) {
    url <- sprintf("%s/%d/departements/%s.csv.gz", dvf_base_url, yr, dep)
    tmp <- tempfile(fileext = ".csv.gz")

    result <- tryCatch({
      download.file(url, tmp, mode = "wb", quiet = TRUE)
      dt <- fread(cmd = paste("gunzip -c", tmp), select = c(
        "id_mutation", "date_mutation", "nature_mutation", "valeur_fonciere",
        "code_postal", "code_commune", "nom_commune", "code_departement",
        "code_type_local", "type_local", "surface_reelle_bati",
        "nombre_pieces_principales", "surface_terrain",
        "longitude", "latitude"
      ))
      dt
    }, error = function(e) NULL)

    if (!is.null(result) && nrow(result) > 0) {
      yr_data[[dep]] <- result
    }
    unlink(tmp)
  }

  if (length(yr_data) > 0) {
    yr_combined <- rbindlist(yr_data, fill = TRUE)
    yr_combined[, year := yr]
    all_dvf[[as.character(yr)]] <- yr_combined
    cat(sprintf("%s rows across %d departments\n",
                format(nrow(yr_combined), big.mark = ","), length(yr_data)))
  } else {
    cat("NO DATA\n")
  }
}

dvf <- rbindlist(all_dvf, fill = TRUE)
cat(sprintf("\nTotal DVF rows: %s\n", format(nrow(dvf), big.mark = ",")))

# ===========================================================================
# 3. Clean DVF
# ===========================================================================
cat("\n=== Cleaning DVF data ===\n")

# Keep only sales (Vente)
dvf <- dvf[nature_mutation == "Vente"]
cat(sprintf("  After keeping sales only: %s rows\n", format(nrow(dvf), big.mark = ",")))

# Parse date
dvf[, date := as.Date(date_mutation)]
dvf[, quarter := paste0(year(date), "Q", quarter(date))]
dvf[, year_q := year(date) + (quarter(date) - 1) / 4]

# Remove extreme prices (< 1000 or > 10M)
dvf <- dvf[valeur_fonciere >= 1000 & valeur_fonciere <= 10000000]
cat(sprintf("  After price filter: %s rows\n", format(nrow(dvf), big.mark = ",")))

# Compute price per m2 where possible
dvf[, prix_m2 := fifelse(surface_reelle_bati > 0, valeur_fonciere / surface_reelle_bati, NA_real_)]

# Keep residential properties (apartments + houses)
dvf <- dvf[code_type_local %in% c(1, 2)]
cat(sprintf("  After keeping residential: %s rows\n", format(nrow(dvf), big.mark = ",")))

# Standardize commune code (5-digit)
dvf[, codgeo := str_pad(as.character(code_commune), 5, pad = "0")]

# ===========================================================================
# 4. Merge DVF with TLV zoning
# ===========================================================================
cat("\n=== Merging DVF with TLV zoning ===\n")
dvf_merged <- merge(dvf, tlv[, .(codgeo, group, zone_type, dep, lib_epci, code_epci)],
                    by = "codgeo", all.x = FALSE)
cat(sprintf("  Merged rows: %s (%.1f%% of DVF matched)\n",
            format(nrow(dvf_merged), big.mark = ","),
            100 * nrow(dvf_merged) / nrow(dvf)))

# Save
arrow::write_parquet(dvf_merged, file.path(data_dir, "dvf_tlv_merged.parquet"))
cat("Saved dvf_tlv_merged.parquet\n")

# ===========================================================================
# 5. Build commune-quarter panel
# ===========================================================================
cat("\n=== Building commune-quarter panel ===\n")

# Aggregate to commune-quarter level
panel <- dvf_merged[, .(
  n_transactions = .N,
  total_value = sum(valeur_fonciere, na.rm = TRUE),
  median_price = median(valeur_fonciere, na.rm = TRUE),
  median_prix_m2 = median(prix_m2, na.rm = TRUE),
  mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
  pct_apartment = mean(code_type_local == 2, na.rm = TRUE),
  mean_rooms = mean(nombre_pieces_principales, na.rm = TRUE)
), by = .(codgeo, quarter, year_q, group, zone_type, code_epci)]

# Create treatment indicator
panel[, treat_post := as.integer(group == "newly_treated_2023" & year_q >= 2024)]
panel[, treated := as.integer(group == "newly_treated_2023")]
panel[, post := as.integer(year_q >= 2024)]

# Create numeric quarter for event study
panel[, time_q := as.integer(factor(quarter, levels = sort(unique(quarter))))]

fwrite(panel, file.path(data_dir, "commune_quarter_panel.csv"))
cat(sprintf("Panel: %s commune-quarter observations\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Unique communes: %s\n", format(uniqueN(panel$codgeo), big.mark = ",")))
cat(sprintf("  Quarters: %s\n", paste(sort(unique(panel$quarter)), collapse = ", ")))

# ===========================================================================
# 6. DATA VALIDATION
# ===========================================================================
cat("\n=== DATA VALIDATION ===\n")
stopifnot("Expected 3+ treatment groups" = length(unique(panel$group)) >= 3)
stopifnot("Expected newly_treated communes" = sum(panel$group == "newly_treated_2023") > 0)
stopifnot("Expected never_treated communes" = sum(panel$group == "never_treated") > 0)
stopifnot("Expected 15+ quarters" = uniqueN(panel$quarter) >= 10)
stopifnot("Expected 1000+ communes" = uniqueN(panel$codgeo) >= 1000)

cat(sprintf("Data validation passed:\n"))
cat(sprintf("  %s rows, %s communes, %s quarters\n",
            format(nrow(panel), big.mark = ","),
            format(uniqueN(panel$codgeo), big.mark = ","),
            uniqueN(panel$quarter)))
cat(sprintf("  Treatment groups: %s\n",
            paste(names(table(panel$group)), table(panel$group), sep = "=", collapse = ", ")))
cat("\nDone.\n")
