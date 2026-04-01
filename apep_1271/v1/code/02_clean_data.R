# 02_clean_data.R — Construct analysis panel
# Paper: Mandated to Stay (apep_1271)

source("00_packages.R")

# ---- Load data ----
qwi <- fread("../data/qwi_main.csv")
qwi_age <- fread("../data/qwi_age.csv")
treated_states <- fread("../data/treated_states.csv")

# ---- Create time variables ----
qwi[, quarter_num := year * 4L + quarter - 1L]
qwi_age[, quarter_num := year * 4L + quarter - 1L]

# Calendar quarter label for display
qwi[, yq := paste0(year, "Q", quarter)]

# ---- Compute recall hires ----
# HirR = HirA - HirN (all hires minus new hires = recalls)
qwi[, HirR := HirA - HirN]

# ---- Merge treatment info ----
qwi <- merge(qwi, treated_states[, .(state_fips, treatment_quarter, state_abbr)],
             by = "state_fips", all.x = TRUE)

# Never-treated states get treatment_quarter = 0 (for did package)
qwi[is.na(treatment_quarter), treatment_quarter := 0L]

# ---- Construct rate variables ----
# Rates per worker (denominator: Emp)
qwi[Emp > 0, `:=`(
  sep_rate    = Sep / Emp,
  hirn_rate   = HirN / Emp,
  hirr_rate   = HirR / Emp,
  hira_rate   = HirA / Emp,
  stability   = EmpS / Emp,
  turnover    = TurnOvrS
)]

# ---- Food service panel (NAICS 722) ----
food <- qwi[industry == "722"]

# Filter: counties with minimum employment in all quarters
county_min_emp <- food[, .(min_emp = min(Emp, na.rm = TRUE),
                           n_quarters = .N), by = county_fips]

# Require Emp >= 50 and at least 60 quarters present (2005-2022 = 72 quarters)
valid_counties <- county_min_emp[min_emp >= 50 & n_quarters >= 60, county_fips]

food <- food[county_fips %in% valid_counties]
cat(sprintf("Food service panel: %s county-quarters, %d unique counties\n",
            format(nrow(food), big.mark = ","), uniqueN(food$county_fips)))

# ---- Retail panel (NAICS 44-45) for placebo ----
retail <- qwi[industry == "44-45"]
retail <- retail[county_fips %in% valid_counties]  # Same counties as food
cat(sprintf("Retail panel: %s county-quarters, %d unique counties\n",
            format(nrow(retail), big.mark = ","), uniqueN(retail$county_fips)))

# ---- Age-specific panel (food service only) ----
qwi_age[, quarter_num := year * 4L + quarter - 1L]
qwi_age[, HirR := HirA - HirN]
qwi_age <- merge(qwi_age, treated_states[, .(state_fips, treatment_quarter)],
                 by = "state_fips", all.x = TRUE)
qwi_age[is.na(treatment_quarter), treatment_quarter := 0L]
qwi_age[Emp > 0, `:=`(
  sep_rate  = Sep / Emp,
  hirn_rate = HirN / Emp,
  hirr_rate = HirR / Emp,
  stability = EmpS / Emp
)]

# Create young (19-24) vs prime-age (25-54) groups
qwi_age[, age_group := fifelse(agegrp %in% c("A03", "A04"), "young_19_24",
                        fifelse(agegrp %in% c("A05", "A06", "A07"), "prime_25_54", "older_55_64"))]

# Aggregate to age_group level within county-quarter
age_panel <- qwi_age[, .(
  Emp = sum(Emp, na.rm = TRUE),
  Sep = sum(Sep, na.rm = TRUE),
  HirN = sum(HirN, na.rm = TRUE),
  HirR = sum(HirR, na.rm = TRUE),
  EmpS = sum(EmpS, na.rm = TRUE)
), by = .(county_fips, state_fips, year, quarter, quarter_num, treatment_quarter, age_group)]

age_panel[Emp > 0, `:=`(
  sep_rate  = Sep / Emp,
  hirn_rate = HirN / Emp,
  hirr_rate = HirR / Emp,
  stability = EmpS / Emp
)]

# Filter to counties in food panel
age_panel <- age_panel[county_fips %in% valid_counties]

cat(sprintf("Age panel: %s county-quarter-age observations\n",
            format(nrow(age_panel), big.mark = ",")))

# ---- Summary statistics ----
cat("\n=== SUMMARY STATISTICS (Food Service, Pre-Treatment) ===\n")
pre <- food[treatment_quarter == 0 | quarter_num < treatment_quarter]
cat(sprintf("Counties: %d (treated: %d, control: %d)\n",
            uniqueN(food$county_fips),
            uniqueN(food[treatment_quarter > 0, county_fips]),
            uniqueN(food[treatment_quarter == 0, county_fips])))
cat(sprintf("Mean sep_rate: %.4f (SD: %.4f)\n", mean(pre$sep_rate, na.rm = TRUE), sd(pre$sep_rate, na.rm = TRUE)))
cat(sprintf("Mean hirn_rate: %.4f (SD: %.4f)\n", mean(pre$hirn_rate, na.rm = TRUE), sd(pre$hirn_rate, na.rm = TRUE)))
cat(sprintf("Mean hirr_rate: %.4f (SD: %.4f)\n", mean(pre$hirr_rate, na.rm = TRUE), sd(pre$hirr_rate, na.rm = TRUE)))
cat(sprintf("Mean stability: %.4f (SD: %.4f)\n", mean(pre$stability, na.rm = TRUE), sd(pre$stability, na.rm = TRUE)))
cat(sprintf("Mean Emp: %.0f (SD: %.0f)\n", mean(pre$Emp, na.rm = TRUE), sd(pre$Emp, na.rm = TRUE)))

# ---- Save panels ----
fwrite(food, "../data/panel_food.csv")
fwrite(retail, "../data/panel_retail.csv")
fwrite(age_panel, "../data/panel_age.csv")

cat("\nPanels saved. 02_clean_data.R completed successfully.\n")
