# 02_clean_data.R — Clean DVF + assign zones + construct bunching variables
# apep_1173: PTZ zone reclassification bunching

source("00_packages.R")

raw_dir <- "../data/raw"

# ============================================================
# 1. Build commune -> zone mapping (correct for data period 2022-2024)
# ============================================================

# Current zones (post-Sept 2025 reclassification)
zones_current <- fread(file.path(raw_dir, "zonage_abc_sept2025.csv"),
                       sep = ";", encoding = "Latin-1")
setnames(zones_current, c("codgeo", "dep", "libgeo", "zone_sept2025", "reclass_sept2025"))
cat(sprintf("Zone classification: %d communes\n", nrow(zones_current)))
cat(sprintf("  Zones: %s\n", paste(zones_current[, .N, zone_sept2025][order(-N), sprintf("%s=%d", zone_sept2025, N)], collapse = ", ")))

# July 2024 reclassification (865 communes)
reclass_jul24 <- fread(file.path(raw_dir, "reclass_865_juillet2024.csv"),
                       sep = ";", encoding = "Latin-1")
setnames(reclass_jul24, c("codgeo", "libgeo", "dep", "region", "zone_pre_jul24", "zone_post_jul24"))
cat(sprintf("July 2024 reclassification: %d communes\n", nrow(reclass_jul24)))
cat(sprintf("  Transitions: %s\n",
            paste(reclass_jul24[, .N, .(zone_pre_jul24, zone_post_jul24)][order(-N),
                  sprintf("%s->%s: %d", zone_pre_jul24, zone_post_jul24, N)], collapse = ", ")))

# Sept 2025 reclassifications (468 up + 19 down) — need to undo these
reclass_sep25 <- fread(file.path(raw_dir, "reclass_468_sept2025.csv"),
                       sep = ";", encoding = "Latin-1")
setnames(reclass_sep25, c("codgeo", "libgeo", "dep", "region", "zone_pre_sep25", "zone_post_sep25"))

declass_sep25 <- fread(file.path(raw_dir, "declass_19_sept2025.csv"),
                       sep = ";", encoding = "Latin-1")
setnames(declass_sep25, c("codgeo", "libgeo", "dep", "region", "zone_pre_sep25", "zone_post_sep25"))

sep25_changes <- rbind(reclass_sep25[, .(codgeo, zone_pre_sep25, zone_post_sep25)],
                       declass_sep25[, .(codgeo, zone_pre_sep25, zone_post_sep25)])
cat(sprintf("Sept 2025 zone changes to undo: %d communes\n", nrow(sep25_changes)))

# Construct zone for our data period (2022-2024):
# - post_zone: zone in effect Jul-Dec 2024 (after Jul 2024 reclass, before Sept 2025)
# - pre_zone: zone in effect Jan 2022 - Jun 2024 (before Jul 2024 reclass)

commune_zones <- zones_current[, .(codgeo, zone_sept2025)]

# Step 1: Undo Sept 2025 changes to get the Jul 2024-Aug 2025 zone
commune_zones <- merge(commune_zones, sep25_changes[, .(codgeo, zone_pre_sep25)],
                       by = "codgeo", all.x = TRUE)
commune_zones[, zone_post_jul24 := fifelse(!is.na(zone_pre_sep25), zone_pre_sep25, zone_sept2025)]
commune_zones[, zone_pre_sep25 := NULL]

# Step 2: For Jul 2024 reclassified communes, set pre-Jul 2024 zone
commune_zones <- merge(commune_zones, reclass_jul24[, .(codgeo, zone_pre_jul24_orig = zone_pre_jul24)],
                       by = "codgeo", all.x = TRUE)
commune_zones[, zone_pre_jul24 := fifelse(!is.na(zone_pre_jul24_orig), zone_pre_jul24_orig, zone_post_jul24)]
commune_zones[, reclassified_jul24 := !is.na(zone_pre_jul24_orig)]
commune_zones[, zone_pre_jul24_orig := NULL]
commune_zones[, zone_sept2025 := NULL]

# Verify counts
cat(sprintf("\nCommune zone assignments:\n"))
cat(sprintf("  Total communes: %d\n", nrow(commune_zones)))
cat(sprintf("  Reclassified (Jul 2024): %d\n", commune_zones[reclassified_jul24 == TRUE, .N]))
cat(sprintf("  Stable: %d\n", commune_zones[reclassified_jul24 == FALSE, .N]))

# Add transition type
commune_zones <- merge(commune_zones,
                       reclass_jul24[, .(codgeo, transition = paste0(zone_pre_jul24, "_to_", zone_post_jul24))],
                       by = "codgeo", all.x = TRUE)
commune_zones[is.na(transition), transition := "stable"]

cat(sprintf("\nTransition distribution:\n"))
print(commune_zones[, .N, transition][order(-N)])

# ============================================================
# 2. PTZ price caps
# ============================================================

ptz_caps <- fread(file.path(raw_dir, "ptz_caps.csv"))
cat(sprintf("\nPTZ caps loaded: %d zone-size combinations\n", nrow(ptz_caps)))

# Get unique caps per zone (all household sizes)
zone_caps <- ptz_caps[, .(caps = list(unique(cap))), by = zone]

# ============================================================
# 3. Read and filter DVF data
# ============================================================

cat("\n=== Reading DVF files ===\n")

# Columns to keep (minimize memory)
keep_cols <- c("id_mutation", "date_mutation", "nature_mutation", "valeur_fonciere",
               "code_commune", "nom_commune", "code_departement",
               "type_local", "surface_reelle_bati", "nombre_pieces_principales")

dvf_list <- list()
for (yr in 2022:2024) {
  cat(sprintf("Reading DVF %d...\n", yr))
  f <- file.path(raw_dir, sprintf("dvf_%d.csv.gz", yr))
  dt <- fread(cmd = sprintf("gunzip -c '%s'", f),
              select = keep_cols, na.strings = "")
  cat(sprintf("  Raw rows: %s\n", formatC(nrow(dt), format = "d", big.mark = ",")))

  # Filter to property sales only (Vente and VEFA)
  dt <- dt[nature_mutation %in% c("Vente", "Vente en l'\\x{00e9}tat futur d'ach\\x{00e8}vement",
                                   "Vente en l'\xe9tat futur d'ach\xe8vement")]
  # Try broader match for VEFA
  dt_vefa <- fread(cmd = sprintf("gunzip -c '%s'", f),
                   select = keep_cols, na.strings = "")
  dt_vefa <- dt_vefa[grepl("Vente", nature_mutation, fixed = TRUE)]

  # Use the broader filter
  dt <- dt_vefa
  rm(dt_vefa)

  # Keep only transactions with price > 0 and with a local (building)
  dt <- dt[!is.na(valeur_fonciere) & valeur_fonciere > 0]
  dt <- dt[!is.na(type_local) & type_local != ""]

  # Deduplicate: keep one row per mutation (mutations can span multiple lots)
  # Take the mutation-level price and property type
  dt <- dt[, .(valeur_fonciere = valeur_fonciere[1],
               nature_mutation = nature_mutation[1],
               type_local = type_local[1],
               surface = surface_reelle_bati[1],
               n_pieces = nombre_pieces_principales[1]),
           by = .(id_mutation, date_mutation, code_commune, nom_commune, code_departement)]

  dt[, year := yr]
  dvf_list[[as.character(yr)]] <- dt
  cat(sprintf("  After filter + dedup: %s transactions\n", formatC(nrow(dt), format = "d", big.mark = ",")))
}

dvf <- rbindlist(dvf_list)
rm(dvf_list)
gc()

cat(sprintf("\nTotal transactions: %s\n", formatC(nrow(dvf), format = "d", big.mark = ",")))

# ============================================================
# 4. Merge zones and classify transactions
# ============================================================

# Parse date
dvf[, date := as.Date(date_mutation)]
dvf[, month := format(date, "%Y-%m")]
dvf[, post_jul24 := date >= as.Date("2024-07-11")]  # Arrete published July 11

# Merge with commune zones
dvf <- merge(dvf, commune_zones, by.x = "code_commune", by.y = "codgeo", all.x = TRUE)
cat(sprintf("Zone match rate: %.1f%%\n", 100 * dvf[!is.na(zone_post_jul24), .N] / nrow(dvf)))

# Drop unmatched communes
dvf <- dvf[!is.na(zone_post_jul24)]

# Assign the relevant zone based on date
dvf[, zone := fifelse(post_jul24, zone_post_jul24, zone_pre_jul24)]

# Flag new-build (VEFA = Vente en l'etat futur d'achevement)
dvf[, is_vefa := grepl("tat futur", nature_mutation)]
cat(sprintf("VEFA (new-build) transactions: %s (%.1f%%)\n",
            formatC(dvf[is_vefa == TRUE, .N], format = "d", big.mark = ","),
            100 * dvf[is_vefa == TRUE, .N] / nrow(dvf)))

# ============================================================
# 5. Compute distance to PTZ caps
# ============================================================

# For each transaction, compute distance to all PTZ caps in its zone
# Focus on the price range near caps (within +-30K of any cap)
cap_window <- 40000  # look within +-40K of each cap

# Get unique caps per zone
all_caps <- ptz_caps[, .(zone, cap)]
setkey(all_caps, zone, cap)

# For each transaction, find nearest cap in its zone
dvf[, nearest_cap := {
  my_caps <- all_caps[zone == .BY$zone, cap]
  if (length(my_caps) == 0) return(NA_real_)
  dists <- outer(valeur_fonciere, my_caps, FUN = "-")
  my_caps[apply(abs(dists), 1, which.min)]
}, by = zone]

dvf[, dist_to_cap := valeur_fonciere - nearest_cap]

# Flag transactions near a PTZ cap (within window)
dvf[, near_cap := abs(dist_to_cap) <= cap_window]

cat(sprintf("\nTransactions near PTZ caps (within +-%dK): %s (%.1f%%)\n",
            cap_window/1000,
            formatC(dvf[near_cap == TRUE, .N], format = "d", big.mark = ","),
            100 * dvf[near_cap == TRUE, .N] / nrow(dvf)))

# ============================================================
# 6. Create price bins for bunching analysis
# ============================================================

bin_width <- 2500  # euros

# Bin relative to nearest cap
dvf[, price_bin := round(dist_to_cap / bin_width) * bin_width]

# Summary
cat(sprintf("\n=== Clean data summary ===\n"))
cat(sprintf("Years: 2022-2024\n"))
cat(sprintf("Total transactions: %s\n", formatC(nrow(dvf), format = "d", big.mark = ",")))
cat(sprintf("VEFA (new-build): %s\n", formatC(dvf[is_vefa == TRUE, .N], format = "d", big.mark = ",")))
cat(sprintf("Reclassified communes: %s\n", formatC(dvf[reclassified_jul24 == TRUE, .N], format = "d", big.mark = ",")))
cat(sprintf("Pre-Jul 2024: %s | Post-Jul 2024: %s\n",
            formatC(dvf[post_jul24 == FALSE, .N], format = "d", big.mark = ","),
            formatC(dvf[post_jul24 == TRUE, .N], format = "d", big.mark = ",")))

# Save cleaned dataset
fwrite(dvf, "../data/dvf_clean.csv")
cat(sprintf("\nSaved: ../data/dvf_clean.csv (%.1f MB)\n",
            file.size("../data/dvf_clean.csv") / 1e6))

# Save zone assignments for reference
fwrite(commune_zones, "../data/commune_zones.csv")
cat("Saved: ../data/commune_zones.csv\n")
