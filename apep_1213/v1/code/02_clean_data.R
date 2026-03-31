# 02_clean_data.R — Construct analysis panel for Moldova banking crisis
# apep_1213

source("00_packages.R")

load("../data/raw_nbs_data.RData")

cat("=== Constructing analysis panel ===\n")

# ============================================================
# 1. Combine pre and post-crisis enterprise data
# ============================================================

# Pre-crisis: columns are raion_code, year, avg_employees, n_enterprises, turnover_mln
# Post-crisis: same structure
panel <- rbind(df_pre_wide, df_post_wide, fill = TRUE)
setDT(panel)

# Merge raion names
panel <- merge(panel, raion_names, by = "raion_code", all.x = TRUE)

cat(sprintf("Combined panel: %d obs, %d raions, %d years\n",
    nrow(panel), uniqueN(panel$raion_code), uniqueN(panel$year)))

# ============================================================
# 2. Construct treatment: Financial sector dependence (pre-crisis)
# ============================================================
cat("\n--- Constructing treatment variable ---\n")

# From sector-level pre-crisis data, compute financial sector share of enterprises
# Sector "J" = Financial intermediation; "00" = Total
fin_pre <- dt_sector_pre[indicator == "n_enterprises"]
fin_pre_wide <- dcast(fin_pre, raion_code + year ~ sector, value.var = "value")
setnames(fin_pre_wide, c("00", "J"), c("total_enterprises", "fin_enterprises"), skip_absent = TRUE)

# For each raion, average financial share over 2010-2013 (stable pre-crisis period)
fin_share <- fin_pre_wide[year %in% 2010:2013,
  .(fin_share = mean(fin_enterprises / total_enterprises, na.rm = TRUE),
    fin_enterprises_avg = mean(fin_enterprises, na.rm = TRUE),
    total_enterprises_avg = mean(total_enterprises, na.rm = TRUE)),
  by = raion_code]

cat("Financial enterprise share by raion (2010-2013 avg):\n")
fin_share_named <- merge(fin_share, raion_names[, .(raion_code, raion_name)], by = "raion_code")
print(fin_share_named[order(-fin_share)][1:10, .(raion_name, fin_share = round(fin_share, 4),
  fin_enterprises_avg = round(fin_enterprises_avg, 1), total_enterprises_avg = round(total_enterprises_avg, 1))])

# Also compute financial sector employment share
fin_emp_pre <- dt_sector_pre[indicator == "avg_employees"]
fin_emp_wide <- dcast(fin_emp_pre, raion_code + year ~ sector, value.var = "value")
setnames(fin_emp_wide, c("00", "J"), c("total_employees", "fin_employees"), skip_absent = TRUE)

fin_emp_share <- fin_emp_wide[year %in% 2010:2013,
  .(fin_emp_share = mean(fin_employees / total_employees, na.rm = TRUE),
    fin_employees_avg = mean(fin_employees, na.rm = TRUE)),
  by = raion_code]

# ============================================================
# 3. Alternative treatment: Inverse banking competition proxy
# ============================================================
# In small raions with few financial firms, BEM was the dominant institution
# Treatment intensity = 1 / (number of financial enterprises)
# Higher values = more BEM-dependent

inv_competition <- fin_share[, .(raion_code,
  inv_fin_competition = 1 / pmax(fin_enterprises_avg, 1),
  few_banks = as.integer(fin_enterprises_avg <= median(fin_enterprises_avg))
)]

# ============================================================
# 4. Merge treatment into panel
# ============================================================
panel <- merge(panel, fin_share[, .(raion_code, fin_share)], by = "raion_code", all.x = TRUE)
panel <- merge(panel, fin_emp_share[, .(raion_code, fin_emp_share)], by = "raion_code", all.x = TRUE)
panel <- merge(panel, inv_competition, by = "raion_code", all.x = TRUE)

# Merge population (only available 2014+)
panel <- merge(panel, dt_pop, by = c("raion_code", "year"), all.x = TRUE)

# ============================================================
# 5. Construct key variables
# ============================================================

# Post indicator
panel[, post := as.integer(year >= 2015)]

# Treatment × Post interactions
panel[, fin_share_post := fin_share * post]
panel[, fin_emp_share_post := fin_emp_share * post]
panel[, inv_comp_post := inv_fin_competition * post]
panel[, few_banks_post := few_banks * post]

# Log outcomes (handle zeros)
panel[, log_emp := log(pmax(avg_employees, 1))]
panel[, log_enterprises := log(pmax(n_enterprises, 1))]
panel[, log_turnover := log(pmax(turnover_mln, 0.01))]

# Employees per enterprise
panel[, emp_per_firm := avg_employees / pmax(n_enterprises, 1)]

# Year factor
panel[, year_f := factor(year)]

# Event time
panel[, event_time := year - 2014]

# Year interactions for event study
for (yr in unique(panel$year)) {
  panel[, paste0("yr_", yr) := as.integer(year == yr)]
}

# ============================================================
# 6. Standardize treatment for interpretation
# ============================================================
# Z-score the continuous treatments
panel[, fin_share_z := (fin_share - mean(fin_share, na.rm = TRUE)) / sd(fin_share, na.rm = TRUE)]
panel[, fin_share_z_post := fin_share_z * post]

cat("\n--- Panel summary ---\n")
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("Raions: %d\n", uniqueN(panel$raion_code)))
cat(sprintf("Years: %d (%d-%d)\n", uniqueN(panel$year), min(panel$year), max(panel$year)))
cat(sprintf("Pre-crisis years: %d (2005-2014)\n", sum(panel$year <= 2014) / uniqueN(panel$raion_code)))
cat(sprintf("Post-crisis years: %d (2015-2024)\n", sum(panel$year >= 2015) / uniqueN(panel$raion_code)))

# Treatment distribution
cat("\nTreatment variable (fin_share) summary:\n")
print(summary(panel[year == 2014, fin_share]))

cat("\nBinary treatment (few_banks): high-dependence raions\n")
high_dep <- raion_names[raion_code %in% inv_competition[few_banks == 1, raion_code], raion_name]
cat(sprintf("  %d raions: %s\n", length(high_dep), paste(head(high_dep, 10), collapse = ", ")))

# ============================================================
# 7. Save analysis panel
# ============================================================
save(panel, raion_names, fin_share, fin_emp_share, inv_competition,
     file = "../data/analysis_panel.RData")

cat("\nAnalysis panel saved to data/analysis_panel.RData\n")
