# =============================================================================
# 02_clean_data.R — Merge BRAC treatment with QWI, construct analysis dataset
# =============================================================================
source("00_packages.R")

# Load data
brac <- fread("../data/brac_treatment.csv", colClasses = list(character = "county_fips"))
qwi  <- fread("../data/qwi_raw.csv", colClasses = list(character = "county_fips"))

cat("Loaded", nrow(brac), "treated counties and", nrow(qwi), "QWI rows\n")

# =============================================================================
# Aggregate QWI to county-quarter level (total across all industries)
# =============================================================================
qwi_total <- qwi[industry == "00", .(
  emp = as.numeric(Emp),
  hir = as.numeric(HirA),
  sep = as.numeric(Sep),
  earn = as.numeric(EarnS),
  jbgn = as.numeric(FrmJbGn),
  jbls = as.numeric(FrmJbLs)
), by = .(county_fips, year, quarter, time_q)]

cat("Total (all-industry) rows:", nrow(qwi_total), "\n")

# =============================================================================
# Industry-specific employment for reallocation analysis
# =============================================================================
key_industries <- c("23", "31-33", "44-45", "54", "62", "72")
industry_labels <- c("Construction", "Manufacturing", "Retail",
                     "Professional", "Healthcare", "Accommodation")

qwi_ind <- qwi[industry %in% key_industries, .(
  emp_ind = as.numeric(Emp),
  hir_ind = as.numeric(HirA),
  sep_ind = as.numeric(Sep)
), by = .(county_fips, year, quarter, time_q, industry)]

# Pivot industry employment to wide format
qwi_ind_wide <- dcast(qwi_ind, county_fips + year + quarter + time_q ~ industry,
                       value.var = "emp_ind", fill = NA)
setnames(qwi_ind_wide, key_industries,
         paste0("emp_", c("constr", "manuf", "retail", "prof", "health", "accom")))

# Merge total and industry
panel <- merge(qwi_total, qwi_ind_wide, by = c("county_fips", "year", "quarter", "time_q"),
               all.x = TRUE)

cat("Panel rows after industry merge:", nrow(panel), "\n")

# =============================================================================
# Merge treatment information
# =============================================================================
panel <- merge(panel, brac[, .(county_fips, first_brac_round)],
               by = "county_fips", all.x = TRUE)

# Treatment timing: convert BRAC round year to quarterly treatment time
# BRAC closures typically take 2-6 years to implement, but announcement is the shock
# We use announcement year as treatment timing (when expectations shift)
panel[, treated := !is.na(first_brac_round)]
panel[, brac_cohort := fifelse(treated, first_brac_round, 0L)]

# Create annual treatment cohort for Callaway-Sant'Anna
# CS requires: treatment period = first period of treatment
# Convert BRAC round year to first quarter (Q1 of that year)
panel[, g := fifelse(treated, first_brac_round, 0L)]

cat("\nTreatment groups:\n")
print(panel[, .(n_counties = uniqueN(county_fips)), by = g][order(g)])
cat("Total counties:", uniqueN(panel$county_fips), "\n")

# =============================================================================
# Convert to annual for Callaway-Sant'Anna (quarterly creates too many periods)
# =============================================================================
panel_annual <- panel[, .(
  emp       = mean(emp, na.rm = TRUE),
  hir       = mean(hir, na.rm = TRUE),
  sep       = mean(sep, na.rm = TRUE),
  earn      = mean(earn, na.rm = TRUE),
  jbgn      = mean(jbgn, na.rm = TRUE),
  jbls      = mean(jbls, na.rm = TRUE),
  emp_constr = mean(emp_constr, na.rm = TRUE),
  emp_manuf  = mean(emp_manuf, na.rm = TRUE),
  emp_retail = mean(emp_retail, na.rm = TRUE),
  emp_prof   = mean(emp_prof, na.rm = TRUE),
  emp_health = mean(emp_health, na.rm = TRUE),
  emp_accom  = mean(emp_accom, na.rm = TRUE)
), by = .(county_fips, year, g)]

# Create county numeric ID for did package
panel_annual[, county_id := as.integer(as.factor(county_fips))]

# Log outcomes (standard for employment)
for (v in c("emp", "hir", "sep", "earn", "jbgn", "jbls",
            "emp_constr", "emp_manuf", "emp_retail", "emp_prof",
            "emp_health", "emp_accom")) {
  panel_annual[, paste0("ln_", v) := log(get(v) + 1)]
}

# Industry employment shares (for reallocation decomposition)
panel_annual[, share_constr := emp_constr / emp]
panel_annual[, share_manuf  := emp_manuf / emp]
panel_annual[, share_retail := emp_retail / emp]
panel_annual[, share_prof   := emp_prof / emp]
panel_annual[, share_health := emp_health / emp]
panel_annual[, share_accom  := emp_accom / emp]

cat("\nAnnual panel dimensions:\n")
cat("  Rows:", nrow(panel_annual), "\n")
cat("  Counties:", uniqueN(panel_annual$county_fips), "\n")
cat("  Years:", min(panel_annual$year), "-", max(panel_annual$year), "\n")
cat("  Treated counties:", uniqueN(panel_annual[g > 0]$county_fips), "\n")
cat("  Never-treated counties:", uniqueN(panel_annual[g == 0]$county_fips), "\n")

# Save
fwrite(panel_annual, "../data/panel_annual.csv")
message("Saved annual panel: ", nrow(panel_annual), " rows")

# =============================================================================
# Pre-treatment balance summary
# =============================================================================
pre_data <- panel_annual[year <= 1993 & !is.na(emp)]
if (nrow(pre_data) > 0) {
  balance <- pre_data[, .(
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_health_share = mean(share_health, na.rm = TRUE),
    mean_manuf_share = mean(share_manuf, na.rm = TRUE),
    n = .N
  ), by = .(treated = g > 0)]
  cat("\nPre-treatment balance (1993 and earlier):\n")
  print(balance)
}
