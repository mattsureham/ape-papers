## 02_clean_data.R — Construct analysis panel with AVGM treatment
## apep_1156: Mexico AVGM and Domestic Violence Reporting

source("00_packages.R")

# -------------------------------------------------------------------
# 1. Load monthly crime panel
# -------------------------------------------------------------------
panel <- fread("../data/crime_panel_monthly.csv")
cat(sprintf("Loaded panel: %d rows\n", nrow(panel)))

# -------------------------------------------------------------------
# 2. AVGM treatment dates (verified from CONAVIM/Data Cívica)
# -------------------------------------------------------------------
# First AVGM declaration date per state. Sources:
#   - CONAVIM official gazette declarations
#   - Data Cívica (avgmciudadana.datacivica.org)
#   - Academic reviews (Frías 2023; Incháustegui & López 2021)
#
# INEGI state codes: 1=Ags, 2=BC, 3=BCS, 4=Camp, 5=Coah, 6=Col,
# 7=Chis, 8=Chih, 9=CDMX, 10=Dgo, 11=Gto, 12=Gro, 13=Hgo,
# 14=Jal, 15=EdoMex, 16=Mich, 17=Mor, 18=Nay, 19=NL, 20=Oax,
# 21=Pue, 22=Qro, 23=QRoo, 24=SLP, 25=Sin, 26=Son, 27=Tab,
# 28=Tamps, 29=Tlax, 30=Ver, 31=Yuc, 32=Zac

avgm_dates <- data.table(
  state_code = c(15, 17, 11, 2,        # 2015
                 16,                     # Jun 2016
                 7, 19, 30,             # Nov 2016
                 25,                     # Mar 2017
                 24, 12, 6,             # Jun 2017
                 18, 22, 21, 31, 5,     # Aug 2017
                 9, 23,                 # Aug 2017 (CDMX, QRoo)
                 32, 20,               # Aug 2018 (Zac, Oax)
                 10, 4, 14,            # Nov 2018 (Dgo, Camp, Jal)
                 8),                    # Aug 2021 (Chih)
  avgm_ym = c(
    201507, 201508, 201511, 201511,     # EdoMex Jul, Morelos Aug, Gto Nov, BC Nov
    201606,                              # Michoacan Jun
    201611, 201611, 201611,             # Chiapas, NL, Veracruz Nov
    201703,                              # Sinaloa Mar
    201706, 201706, 201706,             # SLP, Guerrero, Colima Jun
    201708, 201708, 201708, 201708, 201708, # Nay, Qro, Pue, Yuc, Coah Aug
    201708, 201708,                     # CDMX, QRoo Aug
    201808, 201808,                     # Zacatecas, Oaxaca Aug
    201811, 201811, 201811,             # Durango, Campeche, Jalisco Nov
    202108                               # Chihuahua Aug
  )
)

stopifnot("Duplicate state codes in AVGM list" =
            !any(duplicated(avgm_dates$state_code)))

# Verify treated vs never-treated
all_states <- sort(unique(panel$state_code))
treated_states <- sort(avgm_dates$state_code)
never_treated <- setdiff(all_states, treated_states)
cat(sprintf("Total states in data: %d\n", length(all_states)))
cat(sprintf("Treated states: %d\n", length(treated_states)))
cat(sprintf("Never-treated states: %d — codes: %s\n",
            length(never_treated), paste(never_treated, collapse=", ")))

# -------------------------------------------------------------------
# 3. Merge treatment info into panel
# -------------------------------------------------------------------
panel <- merge(panel, avgm_dates, by = "state_code", all.x = TRUE)
panel[is.na(avgm_ym), avgm_ym := 0]  # never-treated = 0

# Treatment indicator
panel[, treated_post := as.integer(avgm_ym > 0 & ym >= avgm_ym)]

cat(sprintf("Obs treated_post=1: %d (%.1f%%)\n",
            sum(panel$treated_post),
            100 * mean(panel$treated_post)))

# -------------------------------------------------------------------
# 4. Create numeric time index for CS-DiD
# -------------------------------------------------------------------
all_ym <- sort(unique(panel$ym))
ym_to_t <- setNames(seq_along(all_ym), all_ym)
panel[, t := ym_to_t[as.character(ym)]]

# Treatment cohort (first treatment period) for CS-DiD
panel[avgm_ym > 0, g := ym_to_t[as.character(avgm_ym)]]
panel[avgm_ym == 0, g := 0]

cat(sprintf("Time periods: %d (t=1 to t=%d)\n",
            length(all_ym), max(panel$t)))
cohort_tab <- unique(panel[g > 0, .(state_code, g, avgm_ym)])
cat(sprintf("Treatment cohorts:\n"))
print(cohort_tab[order(g), .(avgm_ym = avgm_ym[1], n_states = .N), by = g])

# -------------------------------------------------------------------
# 5. Municipality ID
# -------------------------------------------------------------------
panel[, mun_id := mun_code]
cat(sprintf("Unique municipalities: %d\n", uniqueN(panel$mun_id)))

# -------------------------------------------------------------------
# 6. Outcome transformations
# -------------------------------------------------------------------
panel[, y_asinh := asinh(count)]
panel[, y_raw := count]

# -------------------------------------------------------------------
# 7. Separate panels by crime category
# -------------------------------------------------------------------
dv_panel <- panel[crime_cat == "dv"]
fem_panel <- panel[crime_cat == "feminicide"]
prop_panel <- panel[crime_cat == "property_business"]
abuse_panel <- panel[crime_cat == "sexual_abuse"]

cat(sprintf("\n--- Panel sizes ---\n"))
for (nm in c("dv", "feminicide", "property_business", "sexual_abuse")) {
  d <- panel[crime_cat == nm]
  cat(sprintf("%-20s %7d rows, %d munis, %d months\n",
              nm, nrow(d), uniqueN(d$mun_id), uniqueN(d$t)))
}

# Pre-treatment stats for SDE
dv_pre <- dv_panel[treated_post == 0 & (avgm_ym == 0 | ym < avgm_ym)]
cat(sprintf("\nPre-treatment DV (raw count):\n"))
cat(sprintf("  Mean:   %.3f\n", mean(dv_pre$y_raw)))
cat(sprintf("  SD:     %.3f\n", sd(dv_pre$y_raw)))
cat(sprintf("  Median: %.1f\n", median(dv_pre$y_raw)))
cat(sprintf("  Zeros:  %.1f%%\n", 100 * mean(dv_pre$y_raw == 0)))
cat(sprintf("\nPre-treatment DV (asinh):\n"))
cat(sprintf("  Mean:   %.3f\n", mean(dv_pre$y_asinh)))
cat(sprintf("  SD:     %.3f\n", sd(dv_pre$y_asinh)))

# -------------------------------------------------------------------
# 8. Save
# -------------------------------------------------------------------
fwrite(dv_panel, "../data/dv_panel.csv")
fwrite(fem_panel, "../data/fem_panel.csv")
fwrite(prop_panel, "../data/prop_panel.csv")
fwrite(abuse_panel, "../data/abuse_panel.csv")
fwrite(data.table(ym = all_ym, t = seq_along(all_ym)),
       "../data/ym_mapping.csv")

cat("\nSaved analysis panels.\n")
