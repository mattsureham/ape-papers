# 02_clean_data.R — Clean and merge FOPH OKP data with treatment panel
# apep_0961: Swiss tobacco billboard bans and healthcare costs

source("00_packages.R")

# ============================================================================
# 1. Load raw data
# ============================================================================
okp_raw <- readRDS("../data/okp_raw.rds")
treatment <- fread("../data/treatment_dates.csv")

# ============================================================================
# 2. Clean OKP data
# ============================================================================
# Rename columns for convenience
setnames(okp_raw, "Kanton_ISO3166-2", "canton_iso")
setnames(okp_raw, "Bruttoleistungen_pro_Versicherten", "cost_pc")

# Keep canton-level data (drop national "CH-CH" total)
okp <- okp_raw[canton_iso != "CH-CH"]

# Keep total sex only (main spec), keep individual sex for robustness
okp[, year := as.integer(Jahr)]
okp[, cost_group := Kostengruppe]
okp[, sex := Geschlecht]

# Convert cost to numeric (handle "na" strings)
okp[, cost_pc := as.numeric(gsub(",", ".", as.character(cost_pc)))]

# Drop rows with missing cost
okp <- okp[!is.na(cost_pc)]

cat("Cleaned OKP data:", nrow(okp), "rows\n")
cat("Years:", range(okp$year), "\n")
cat("Cantons:", length(unique(okp$canton_iso)), "\n")
cat("Cost groups:", unique(okp$cost_group), "\n")

# Validate: all 26 cantons present
stopifnot(length(unique(okp$canton_iso)) == 26)

# ============================================================================
# 3. Classify cost categories as smoking-related vs placebo
# ============================================================================
# Smoking-related: hospital (inpatient/outpatient), pharmacy, physician treatments
# Placebo (non-smoking-related): physiotherapy, SPITEX, laboratory

okp[, category_type := fcase(
  cost_group %in% c("Spitäler stationär", "Spitäler ambulant",
                     "Apotheken", "Ärzte Behandlungen (ohne Labor)",
                     "Ärzte Medikamente"),
  "smoking_related",
  cost_group %in% c("PhysiotherapeutInnen", "SPITEX-Organisationen",
                     "Laboratorien", "Ärzte Laboranalysen"),
  "placebo",
  cost_group == "Pflegeheime", "nursing_homes",
  cost_group %in% c("Übrige"), "other",
  cost_group == "Total", "total",
  default = "unclassified"
)]

cat("\nCategory classification:\n")
print(okp[, .N, by = .(cost_group, category_type)][order(category_type)])

# ============================================================================
# 4. Merge with treatment dates
# ============================================================================
okp <- merge(okp, treatment, by = "canton_iso", all.x = TRUE)

# Verify all cantons matched
stopifnot(sum(is.na(okp$ban_year)) == 0)

# Create treatment indicators
okp[, treated_ever := as.integer(ban_year > 0)]
okp[, treated_post := as.integer(ban_year > 0 & year >= ban_year)]
okp[, years_since_ban := ifelse(ban_year > 0, year - ban_year, NA_integer_)]

# ============================================================================
# 5. Create analysis panels
# ============================================================================
# Main panel: Total costs by canton-year (sex = Total)
panel_total <- okp[sex == "Total" & cost_group == "Total",
                   .(canton_iso, year, cost_pc, ban_year, treated_ever,
                     treated_post, years_since_ban, canton_name)]
panel_total[, canton_id := as.integer(as.factor(canton_iso))]

cat("\nMain panel (Total costs, Total sex):", nrow(panel_total), "rows\n")
cat("  Cantons:", length(unique(panel_total$canton_iso)), "\n")
cat("  Years:", range(panel_total$year), "\n")

# Category panel: by cost group for placebo tests
panel_cat <- okp[sex == "Total" & cost_group != "Total",
                 .(canton_iso, year, cost_pc, cost_group, category_type,
                   ban_year, treated_ever, treated_post, years_since_ban,
                   canton_name)]
panel_cat[, canton_id := as.integer(as.factor(canton_iso))]

cat("Category panel:", nrow(panel_cat), "rows\n")

# Log transformation for percentage interpretation
panel_total[, ln_cost := log(cost_pc)]
panel_cat[, ln_cost := log(cost_pc)]

# ============================================================================
# 6. Summary statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")
cat("\nTotal per-capita costs (CHF):\n")
print(panel_total[, .(mean = mean(cost_pc), sd = sd(cost_pc),
                       min = min(cost_pc), max = max(cost_pc)),
                  by = treated_ever])

cat("\nPre-treatment means by group:\n")
pre_means <- panel_total[year < 2002, .(
  mean_cost = mean(cost_pc),
  sd_cost = sd(cost_pc),
  n_cantons = uniqueN(canton_iso)
), by = treated_ever]
print(pre_means)

# ============================================================================
# 7. Save analysis panels
# ============================================================================
saveRDS(panel_total, "../data/panel_total.rds")
saveRDS(panel_cat, "../data/panel_cat.rds")
saveRDS(okp, "../data/okp_clean.rds")

cat("\nAnalysis panels saved.\n")
