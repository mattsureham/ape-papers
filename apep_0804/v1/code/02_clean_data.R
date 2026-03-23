# 02_clean_data.R — Construct mother-level analysis dataset
# APEP Paper apep_0804: The Caregiving Tax

source("00_packages.R")

cat("=== Constructing analysis dataset ===\n")

dt <- fread("../data/acs_pums_raw.csv")
cat(sprintf("Loaded %s raw records\n", format(nrow(dt), big.mark = ",")))

# --- State autism insurance mandate adoption dates ---
# Source: Chatterji et al. (2015, JPAM); Autism Speaks legislative database;
# NCSL State Insurance Mandates for Autism Spectrum Disorder
# Only includes mandates requiring private insurers to cover ABA/behavioral therapy

mandate_dates <- data.table(
  ST = c(
    # 2001
    18L,  # IN
    # 2007
    45L, 48L,  # SC, TX
    # 2008
    4L, 12L, 17L, 22L, 42L,  # AZ, FL, IL, LA, PA
    # 2009
    8L, 9L, 30L, 34L, 35L, 32L, 55L,  # CO, CT, MT, NJ, NM, NV, WI
    # 2010
    20L, 21L, 25L, 23L, 29L, 33L, 51L, 50L,  # KS, KY, MA, ME, MO, NH, VA, VT
    # 2011
    5L, 19L, 36L, 54L,  # AR, IA, NY, WV
    # 2012
    6L, 10L, 24L, 26L, 44L,  # CA, DE, MD, MI, RI
    # 2013
    27L, 39L, 40L, 41L,  # MN, OH, OK, OR
    # 2014
    31L, 46L, 47L, 49L, 53L,  # NE, SD, TN, UT, WA
    # 2015
    13L, 15L, 28L, 37L, 38L  # GA, HI, MS, NC, ND
  ),
  mandate_year = c(
    2001L,
    2007L, 2007L,
    2008L, 2008L, 2008L, 2008L, 2008L,
    2009L, 2009L, 2009L, 2009L, 2009L, 2009L, 2009L,
    2010L, 2010L, 2010L, 2010L, 2010L, 2010L, 2010L, 2010L,
    2011L, 2011L, 2011L, 2011L,
    2012L, 2012L, 2012L, 2012L, 2012L,
    2013L, 2013L, 2013L, 2013L,
    2014L, 2014L, 2014L, 2014L, 2014L,
    2015L, 2015L, 2015L, 2015L, 2015L
  )
)

cat(sprintf("Mandate adoption: %d states, years %d-%d\n",
            nrow(mandate_dates), min(mandate_dates$mandate_year),
            max(mandate_dates$mandate_year)))

# Never-treated states (no mandate by end of 2019)
# AL (1), AK (2), ID (16), WY (56)
never_treated <- c(1L, 2L, 16L, 56L)

# --- Identify children aged 5-17 with cognitive difficulty ---
children <- dt[AGEP >= 5 & AGEP <= 17]
cat(sprintf("Children aged 5-17: %s\n", format(nrow(children), big.mark = ",")))

# DREM coding: 1 = Yes (cognitive difficulty), 2 = No
children[, has_cog_diff := as.integer(DREM == 1)]
cat(sprintf("Children with DREM=1: %s (%.1f%%)\n",
            format(sum(children$has_cog_diff == 1, na.rm = TRUE), big.mark = ","),
            100 * mean(children$has_cog_diff == 1, na.rm = TRUE)))

# --- Create household-level child disability indicator ---
# For each household-year: does it have at least one child with DREM=1?
hh_child <- children[, .(
  has_drem_child = as.integer(any(has_cog_diff == 1, na.rm = TRUE)),
  has_dphy_child = as.integer(any(DPHY == 1, na.rm = TRUE)),  # physical disability (placebo)
  n_children = .N,
  min_child_age = min(AGEP),
  max_child_age = max(AGEP)
), by = .(SERIALNO, year)]

cat(sprintf("Households with children: %s\n", format(nrow(hh_child), big.mark = ",")))
cat(sprintf("  With DREM=1 child: %s (%.1f%%)\n",
            format(sum(hh_child$has_drem_child == 1), big.mark = ","),
            100 * mean(hh_child$has_drem_child == 1)))

# --- Identify mothers (adult women in parenting role) ---
# RELP codes (2008-2018):
#   0 = Reference person
#   1 = Husband/wife
#   13 = Unmarried partner
# We define "mother" as: female, age 25-54, reference person or spouse,
# in a household with children aged 5-17

mothers <- dt[SEX == 2 & AGEP >= 25 & AGEP <= 54 & RELP %in% c(0, 1, 13)]
cat(sprintf("Candidate mothers (female, 25-54, ref/spouse): %s\n",
            format(nrow(mothers), big.mark = ",")))

# Merge with household child info
mothers <- merge(mothers, hh_child, by = c("SERIALNO", "year"), all.x = FALSE)
cat(sprintf("Mothers in households with children 5-17: %s\n",
            format(nrow(mothers), big.mark = ",")))

# --- Construct outcome variables ---
# ESR: Employment status recode
#   1 = Employed, at work
#   2 = Employed, with a job but not at work
#   3 = Unemployed
#   4 = Armed Forces, at work
#   5 = Armed Forces, with a job but not at work
#   6 = Not in labor force
mothers[, employed := as.integer(ESR %in% c(1, 2, 4, 5))]
mothers[, in_labor_force := as.integer(ESR %in% c(1, 2, 3, 4, 5))]

# Hours and wages (set 0 for non-workers)
mothers[, hours := fifelse(is.na(WKHP), 0, as.numeric(WKHP))]
mothers[, wages := fifelse(is.na(WAGP), 0, as.numeric(WAGP))]
mothers[, log_wages := fifelse(wages > 0, log(wages), NA_real_)]

# --- Merge mandate dates and construct treatment ---
mothers <- merge(mothers, mandate_dates, by = "ST", all.x = TRUE)

# Never-treated states get mandate_year = Inf (for CS estimator)
mothers[is.na(mandate_year), mandate_year := 0L]
mothers[, ever_treated := as.integer(mandate_year > 0)]
mothers[mandate_year == 0, mandate_year_cs := 0L]  # CS convention: 0 = never-treated
mothers[mandate_year > 0, mandate_year_cs := mandate_year]

# Post-treatment indicator
mothers[, post := as.integer(ever_treated == 1 & year >= mandate_year)]

# Relative time to treatment
mothers[ever_treated == 1, rel_time := year - mandate_year]
mothers[ever_treated == 0, rel_time := NA_integer_]

# --- Covariates ---
# Education: college degree or higher
mothers[, college := as.integer(SCHL >= 21)]  # 21 = Bachelor's degree

# Race
mothers[, white := as.integer(RAC1P == 1)]
mothers[, black := as.integer(RAC1P == 2)]

# Marital status
mothers[, married := as.integer(MAR == 1)]

# State name for display
state_fips <- data.table(
  ST = c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56),
  state_name = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                 "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                 "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                 "UT","VT","VA","WA","WV","WI","WY")
)
mothers <- merge(mothers, state_fips, by = "ST", all.x = TRUE)

# --- Final sample restrictions ---
# Drop states that adopted before ACS data begins (2008) with no pre-period
# IN (2001), SC (2007), TX (2007) — always-treated, no pre-period variation
# Keep them but flag for robustness
mothers[, always_treated := as.integer(mandate_year > 0 & mandate_year < 2008)]

cat("\n=== Analysis dataset summary ===\n")
cat(sprintf("Total mothers: %s\n", format(nrow(mothers), big.mark = ",")))
cat(sprintf("  DREM=1 child: %s\n", format(sum(mothers$has_drem_child == 1), big.mark = ",")))
cat(sprintf("  DREM=0 child: %s\n", format(sum(mothers$has_drem_child == 0), big.mark = ",")))
cat(sprintf("States: %d\n", uniqueN(mothers$ST)))
cat(sprintf("Years: %d-%d\n", min(mothers$year), max(mothers$year)))
cat(sprintf("Mandate states: %d\n", uniqueN(mothers[ever_treated == 1]$ST)))
cat(sprintf("Never-treated states: %d\n", uniqueN(mothers[ever_treated == 0]$ST)))
cat(sprintf("Employment rate (all): %.1f%%\n", 100 * mean(mothers$employed)))
cat(sprintf("Employment rate (DREM=1 child): %.1f%%\n",
            100 * mean(mothers[has_drem_child == 1]$employed)))
cat(sprintf("Employment rate (DREM=0 child): %.1f%%\n",
            100 * mean(mothers[has_drem_child == 0]$employed)))

# Save analysis dataset
fwrite(mothers, "../data/analysis_data.csv")
cat("\nSaved to data/analysis_data.csv\n")
cat("=== Cleaning complete ===\n")
