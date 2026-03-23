# ==============================================================================
# 02_clean_data.R — Construct treatment variables and analysis sample
# ==============================================================================

source("00_packages.R")

qwi <- fread("../data/qwi_raw.csv")

# Ensure fips_county is zero-padded and create state FIPS
qwi[, fips_county := sprintf("%05d", as.integer(fips_county))]
qwi[, fips_state := substr(fips_county, 1, 2)]
qwi[, yearqtr := year + (quarter - 1) / 4]

# --- Step 1: Construct county-level tech share (treatment intensity) ---
# Tech share = (NAICS 51 + NAICS 54) / total employment in 2002Q1

tech_emp_2002 <- qwi[year == 2002 & quarter == 1 & industry %in% c("51", "54"),
                     .(tech_emp = sum(Emp, na.rm = TRUE)), by = fips_county]

total_emp_2002 <- qwi[year == 2002 & quarter == 1 & industry == "00",
                      .(total_emp = sum(Emp, na.rm = TRUE)), by = fips_county]

tech_share <- merge(tech_emp_2002, total_emp_2002, by = "fips_county", all = FALSE)
tech_share[, tech_share := tech_emp / total_emp]

# Drop counties with very small total employment (< 1000)
tech_share <- tech_share[total_emp >= 1000]

cat(sprintf("Counties with tech share computed: %d\n", nrow(tech_share)))
cat(sprintf("Tech share: mean=%.3f, median=%.3f, p25=%.3f, p75=%.3f\n",
            mean(tech_share$tech_share), median(tech_share$tech_share),
            quantile(tech_share$tech_share, 0.25),
            quantile(tech_share$tech_share, 0.75)))

stopifnot("Must have 500+ counties" = nrow(tech_share) >= 500)

# --- Step 2: Create analysis panel ---
# Focus on NAICS 54 (Professional/Technical) as treated industry
# Plus control industries: 42 (Wholesale), 44-45 (Retail), 56 (Admin), 62 (Health), 72 (Accommodation)
# Placebo: 92 (Government), 21 (Mining)

analysis_industries <- c("54", "42", "44-45", "56", "62", "72", "92", "21")

panel <- qwi[industry %in% analysis_industries]

# Merge tech share
panel <- merge(panel, tech_share[, .(fips_county, tech_share, total_emp)],
               by = "fips_county", all = FALSE)

# --- Step 3: Create DDD variables ---
# Young = 1 for age 25-34 (A04), 0 for age 45-54 (A06), exclude 35-44 for clean comparison
panel_ddd <- panel[agegrp %in% c("A04", "A06")]
panel_ddd[, young := as.integer(agegrp == "A04")]

# Tech industry indicator
panel_ddd[, tech_ind := as.integer(industry == "54")]

# Event time relative to 2003Q4 (FY2004 cap reduction)
panel_ddd[, event_time := (year - 2003) * 4 + (quarter - 4)]

# Log outcomes (adding 1 to handle zeros in small cells)
panel_ddd[, log_emp := log(Emp + 1)]
panel_ddd[, log_hires := log(HirA + 1)]
panel_ddd[, log_sep := log(Sep + 1)]
panel_ddd[, log_earn := log(EarnS + 1)]

# Fixed effect identifiers
panel_ddd[, county_ind_age := paste(fips_county, industry, agegrp, sep = "_")]
panel_ddd[, state_quarter := paste(fips_state, yearqtr, sep = "_")]
panel_ddd[, ind_quarter := paste(industry, yearqtr, sep = "_")]
panel_ddd[, age_quarter := paste(agegrp, yearqtr, sep = "_")]

# Treatment quartile indicators
panel_ddd[, tech_quartile := cut(tech_share,
                                  breaks = quantile(tech_share, c(0, 0.25, 0.5, 0.75, 1)),
                                  labels = c("Q1", "Q2", "Q3", "Q4"),
                                  include.lowest = TRUE)]
panel_ddd[, high_tech := as.integer(tech_quartile == "Q4")]

# Post-treatment indicator (cap cut effective 2003Q4)
panel_ddd[, post := as.integer(yearqtr >= 2003.75)]

# --- Step 4: Summary statistics ---
cat("\n=== Analysis Sample ===\n")
cat(sprintf("Observations: %s\n", format(nrow(panel_ddd), big.mark = ",")))
cat(sprintf("Counties: %d\n", uniqueN(panel_ddd$fips_county)))
cat(sprintf("Quarters: %d (%.1f to %.1f)\n", uniqueN(panel_ddd$yearqtr),
            min(panel_ddd$yearqtr), max(panel_ddd$yearqtr)))
cat(sprintf("Industries: %s\n", paste(sort(unique(panel_ddd$industry)), collapse = ", ")))

# Mean employment by tech intensity and age
summ <- panel_ddd[industry == "54",
                  .(mean_emp = mean(Emp, na.rm = TRUE),
                    mean_earn = mean(EarnS, na.rm = TRUE),
                    n_obs = .N),
                  by = .(high_tech, young)]
print(summ)

# --- Step 5: Save ---
fwrite(panel_ddd, "../data/analysis_panel.csv")
fwrite(tech_share, "../data/tech_share.csv")

cat("\nSaved analysis_panel.csv and tech_share.csv\n")
