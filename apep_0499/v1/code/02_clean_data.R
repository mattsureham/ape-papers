## 02_clean_data.R — Clean and construct analysis variables
## apep_0499: Action Cœur de Ville and Property Markets

source("00_packages.R")

data_dir <- "../data"

# ==============================================================
# 1. Load raw data
# ==============================================================
cat("Loading combined DVF data...\n")
dvf <- readRDS(file.path(data_dir, "dvf_filtered.rds"))
acv_info <- readRDS(file.path(data_dir, "acv_info.rds"))
acv_codes <- unique(acv_info$insee_com)

cat(sprintf("Raw transactions: %d\n", nrow(dvf)))
cat(sprintf("Year range: %d-%d\n", min(dvf$year), max(dvf$year)))

# Harmonize commune codes: ensure consistent 5-digit zero-padded INSEE format
dvf[, commune_full := sprintf("%05s", trimws(as.character(commune_full)))]
acv_codes <- sprintf("%05s", trimws(as.character(acv_codes)))
cat(sprintf("Unique commune codes after harmonization: %d\n", uniqueN(dvf$commune_full)))

# ==============================================================
# 2. Clean transaction data
# ==============================================================

# Filter to sales only (Vente or VEFA)
dvf <- dvf[grepl("Vente|vente", nature_mutation, ignore.case = TRUE)]
cat(sprintf("After filtering to sales: %d\n", nrow(dvf)))

# Remove missing/zero prices
dvf <- dvf[!is.na(valeur_fonciere) & valeur_fonciere > 0]
cat(sprintf("After removing missing/zero prices: %d\n", nrow(dvf)))

# Remove extreme price outliers (1st and 99th percentile)
price_bounds <- quantile(dvf$valeur_fonciere, c(0.01, 0.99), na.rm = TRUE)
dvf <- dvf[valeur_fonciere >= price_bounds[1] & valeur_fonciere <= price_bounds[2]]
cat(sprintf("After removing price outliers: %d\n", nrow(dvf)))

# ==============================================================
# 3. Classify property types
# ==============================================================
dvf[, broad_type := fcase(
  code_type_local == 1, "House",
  code_type_local == 2, "Apartment",
  code_type_local == 3, "Outbuilding",
  code_type_local == 4, "Commercial",
  !is.na(code_nature_culture), "Land",
  default = "Other"
)]
dvf[, residential := broad_type %in% c("House", "Apartment")]

cat("\nProperty type distribution:\n")
print(table(dvf$broad_type))

# ==============================================================
# 4. Compute price per square meter
# ==============================================================
dvf[, area := fifelse(
  residential & !is.na(surface_reelle_bati) & surface_reelle_bati > 0,
  surface_reelle_bati,
  fifelse(!is.na(surface_terrain) & surface_terrain > 0, surface_terrain, NA_real_)
)]
dvf[, price_m2 := fifelse(!is.na(area) & area > 0, valeur_fonciere / area, NA_real_)]
dvf[, log_price := log(valeur_fonciere)]
dvf[, log_price_m2 := fifelse(!is.na(price_m2) & price_m2 > 0, log(price_m2), NA_real_)]

# Filter to residential with valid price_m2
dvf_res <- dvf[residential == TRUE & !is.na(price_m2) & price_m2 > 0]

# Remove extreme price_m2 outliers
pm2_bounds <- quantile(dvf_res$price_m2, c(0.01, 0.99), na.rm = TRUE)
dvf_res <- dvf_res[price_m2 >= pm2_bounds[1] & price_m2 <= pm2_bounds[2]]
dvf_res[, log_price_m2 := log(price_m2)]

cat(sprintf("\nResidential transactions with valid price/m²: %d\n", nrow(dvf_res)))

# ==============================================================
# 5. Merge ACV status
# ==============================================================
dvf_res[, treated := commune_full %in% acv_codes]
dvf_res[, departement := substr(commune_full, 1, 2)]

cat(sprintf("ACV residential transactions: %d\n", sum(dvf_res$treated)))
cat(sprintf("Control residential transactions: %d\n", sum(!dvf_res$treated)))

# ==============================================================
# 6. Create treatment variables
# ==============================================================
dvf_res[, post := year >= 2018]
dvf_res[, treat_post := treated & post]

# ==============================================================
# 7. Aggregate to commune-year panel
# ==============================================================
panel <- dvf_res[, .(
  mean_price = mean(valeur_fonciere, na.rm = TRUE),
  median_price = median(valeur_fonciere, na.rm = TRUE),
  mean_price_m2 = mean(price_m2, na.rm = TRUE),
  median_price_m2 = median(price_m2, na.rm = TRUE),
  log_mean_price_m2 = log(mean(price_m2, na.rm = TRUE)),
  n_transactions = .N,
  mean_area = mean(area, na.rm = TRUE),
  pct_apartment = mean(broad_type == "Apartment", na.rm = TRUE)
), by = .(commune = commune_full, year, treated, departement)]

panel[, post := year >= 2018]
panel[, treat_post := treated & post]
panel[, log_n_trans := log(n_transactions + 1)]

cat(sprintf("\nCommune-year panel: %d observations\n", nrow(panel)))
cat(sprintf("  Unique communes: %d\n", uniqueN(panel$commune)))
cat(sprintf("  ACV communes: %d\n", uniqueN(panel$commune[panel$treated])))
cat(sprintf("  Control communes: %d\n", uniqueN(panel$commune[!panel$treated])))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))

# Year distribution
cat("\nTransactions per year:\n")
print(dvf_res[, .N, by = year][order(year)])

# ==============================================================
# 8. Save cleaned data
# ==============================================================
saveRDS(as_tibble(dvf_res), file.path(data_dir, "dvf_residential_clean.rds"))
saveRDS(as_tibble(panel), file.path(data_dir, "commune_year_panel.rds"))

# Save all transactions for mechanism analysis
dvf[, treated := commune_full %in% acv_codes]
dvf[, departement := substr(commune_full, 1, 2)]
dvf[, post := year >= 2018]
saveRDS(as_tibble(dvf), file.path(data_dir, "dvf_all_clean.rds"))

cat("\n=== CLEANING COMPLETE ===\n")
cat(sprintf("Residential transactions saved: %d\n", nrow(dvf_res)))
cat(sprintf("All transactions saved: %d\n", nrow(dvf)))
cat(sprintf("Commune-year panel saved: %d rows\n", nrow(panel)))
