## ============================================================
## 02_clean_data.R — Merge DVF with zone classification, build panel
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"

# ============================================================
# 1. Load data
# ============================================================

dvf <- fread(file.path(DATA_DIR, "dvf_residential_agg.csv"))
zones_raw <- fread(file.path(DATA_DIR, "zonage_abc.csv"))

cat(sprintf("DVF panel: %s commune-years\n", formatC(nrow(dvf), big.mark = ",")))
cat(sprintf("Zones raw: %s rows\n", formatC(nrow(zones_raw), big.mark = ",")))

# ============================================================
# 2. Standardize zone classification
# ============================================================

cat("Zone file columns: ", paste(names(zones_raw), collapse = ", "), "\n")

# Identify zone and commune columns
zone_col <- grep("zone|Zone|ZONE|zonage|Zonage", names(zones_raw), value = TRUE)
commune_col <- grep("code.*commune|CODGEO|codgeo|insee|INSEE|Code", names(zones_raw), value = TRUE)

if (length(zone_col) == 0) {
  # If no explicit zone column, check all columns for zone values
  for (col in names(zones_raw)) {
    vals <- unique(as.character(zones_raw[[col]]))
    if (any(vals %in% c("A", "B1", "B2", "C", "A bis", "Abis"))) {
      zone_col <- col
      break
    }
  }
}

if (length(commune_col) == 0) {
  # Look for any column with 5-digit codes
  for (col in names(zones_raw)) {
    vals <- as.character(zones_raw[[col]])
    if (any(grepl("^[0-9]{5}$", vals))) {
      commune_col <- col
      break
    }
  }
}

zone_col <- zone_col[1]
commune_col <- commune_col[1]
cat(sprintf("Zone column: %s\nCommune column: %s\n", zone_col, commune_col))

zones <- zones_raw[, .(
  code_commune = as.character(get(commune_col)),
  zone = toupper(trimws(as.character(get(zone_col))))
)]

# Standardize zone labels
zones[zone %in% c("A BIS", "ABIS", "A_BIS", "A BIS"), zone := "Abis"]
zones[zone %in% c("A"), zone := "A"]
zones[zone %in% c("B1"), zone := "B1"]
zones[zone %in% c("B2"), zone := "B2"]
zones[zone %in% c("C"), zone := "C"]

# Treatment assignment
zones[, treated := fifelse(zone %in% c("B2", "C"), 1L, 0L)]
zones[, zone_group := fifelse(zone %in% c("B2", "C"), "B2/C",
                       fifelse(zone == "B1", "B1", "A/Abis"))]

cat("\nZone distribution:\n")
print(zones[, .N, by = zone][order(zone)])
cat(sprintf("\nTreated (B2/C): %d communes\n", sum(zones$treated == 1)))
cat(sprintf("Control (B1):   %d communes\n", sum(zones$zone == "B1")))
cat(sprintf("A/Abis:         %d communes\n",
            sum(zones$zone %in% c("A", "Abis"))))

# ============================================================
# 3. Merge DVF with zones
# ============================================================

# Pad commune codes to 5 digits
dvf[, code_commune := sprintf("%05s", as.character(code_commune))]
zones[, code_commune := sprintf("%05s", code_commune)]

# Remove duplicates in zone classification
zones <- unique(zones, by = "code_commune")

# Merge
panel <- merge(dvf, zones, by = "code_commune", all.x = FALSE)
n_unmatched <- nrow(dvf) - nrow(panel)
cat(sprintf("\nMerge: %s matched, %s unmatched (%.1f%%)\n",
            formatC(nrow(panel), big.mark = ","),
            formatC(n_unmatched, big.mark = ","),
            100 * n_unmatched / nrow(dvf)))

# ============================================================
# 4. Construct analysis variables
# ============================================================

# Log price per m2 (using apartment price/m2 as primary metric)
panel[, log_price_m2 := log(price_m2)]

# VEFA share
panel[, vefa_share := fifelse(n_transactions > 0,
                               n_vefa / n_transactions, NA_real_)]

# Treatment timing variables
panel[, post := fifelse(year >= 2018, 1L, 0L)]
panel[, post_full := fifelse(year >= 2020, 1L, 0L)]
panel[, did := treated * post]
panel[, did_full := treated * post_full]

# Event time relative to 2018
panel[, event_time := year - 2018]

# Two-stage treatment indicators
panel[, post_2018 := fifelse(year >= 2018 & year < 2020, 1L, 0L)]
panel[, post_2020 := fifelse(year >= 2020, 1L, 0L)]

cat(sprintf("\nPanel: %s commune-years\n",
            formatC(nrow(panel), big.mark = ",")))
cat(sprintf("Communes: %s\n",
            formatC(uniqueN(panel$code_commune), big.mark = ",")))

# ============================================================
# 5. Build sub-panels
# ============================================================

# Identify border departements (have both B1 and B2/C communes)
dept_zones <- zones[, .(
  has_b1 = any(zone == "B1"),
  has_b2c = any(zone %in% c("B2", "C"))
), by = .(dept = substr(code_commune, 1, 2))]

border_depts <- dept_zones[has_b1 == TRUE & has_b2c == TRUE, dept]
cat(sprintf("\nBorder departements: %d\n", length(border_depts)))

panel[, is_border_dept := substr(code_commune, 1, 2) %in% border_depts]
panel_border <- panel[is_border_dept == TRUE & zone_group %in% c("B1", "B2/C")]

cat(sprintf("Border panel: %s commune-years\n",
            formatC(nrow(panel_border), big.mark = ",")))

# ============================================================
# 6. Save panels
# ============================================================

fwrite(panel, file.path(DATA_DIR, "panel_main.csv"))
fwrite(panel_border, file.path(DATA_DIR, "panel_border.csv"))
fwrite(zones, file.path(DATA_DIR, "zones_clean.csv"))

# ============================================================
# Summary statistics
# ============================================================

cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Main panel:   %s obs, %s communes\n",
            formatC(nrow(panel), big.mark = ","),
            formatC(uniqueN(panel$code_commune), big.mark = ",")))
cat(sprintf("Border panel: %s obs\n",
            formatC(nrow(panel_border), big.mark = ",")))

cat("\nMedian price/m2 by zone group and period:\n")
summ <- panel[zone_group %in% c("B1", "B2/C") & !is.na(price_m2),
  .(median_price = median(price_m2, na.rm = TRUE),
    n_communes = uniqueN(code_commune),
    n_obs = .N),
  by = .(zone_group, period = fifelse(year < 2018, "Pre", "Post"))
]
print(summ[order(zone_group, period)])

cat("\nMean VEFA transactions by zone group and period:\n")
vefa_summ <- panel[zone_group %in% c("B1", "B2/C"),
  .(mean_vefa = mean(n_vefa, na.rm = TRUE),
    total_vefa = sum(n_vefa, na.rm = TRUE)),
  by = .(zone_group, period = fifelse(year < 2018, "Pre", "Post"))
]
print(vefa_summ[order(zone_group, period)])
