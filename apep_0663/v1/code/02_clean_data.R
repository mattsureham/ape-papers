# =============================================================================
# 02_clean_data.R — Clean data and construct treatment variables for apep_0663
# =============================================================================

source("00_packages.R")

# ---- Load raw data -----------------------------------------------------------
qwi <- readRDS("../data/qwi_se_state.rds")

# ---- Medicaid expansion dates ------------------------------------------------
# Source: KFF, MACPAC. Treatment = quarter of expansion effective date.
# Using first legal sale / effective date mapped to quarter.
expansion <- tribble(
  ~statefip, ~expand_year, ~expand_qtr,
  # 2014 Q1 (Jan 1, 2014): 24 states + DC
  2,  2014, 1,  # AK — actually 2015 Q3, corrected below
  4,  2014, 1,  # AZ
  5,  2014, 1,  # AR
  6,  2014, 1,  # CA
  8,  2014, 1,  # CO
  9,  2014, 1,  # CT
  10, 2014, 1,  # DE
  11, 2014, 1,  # DC
  15, 2014, 1,  # HI
  17, 2014, 1,  # IL
  19, 2014, 1,  # IA
  21, 2014, 1,  # KY
  24, 2014, 1,  # MD
  25, 2014, 1,  # MA
  26, 2014, 1,  # MI
  27, 2014, 1,  # MN
  29, 2014, 1,  # MO — actually 2021 Q4, corrected below
  32, 2014, 1,  # NV
  34, 2014, 1,  # NJ
  35, 2014, 1,  # NM
  36, 2014, 1,  # NY
  38, 2014, 1,  # ND
  39, 2014, 1,  # OH
  41, 2014, 1,  # OR
  44, 2014, 1,  # RI
  50, 2014, 1,  # VT
  53, 2014, 1,  # WA
  54, 2014, 1,  # WV
  # 2014 Q2 (Apr 2014)
  33, 2014, 2,  # NH
  # 2015 Q1
  18, 2015, 1,  # IN
  42, 2015, 1,  # PA
  # 2015 Q3 (Sep 2015)
  2,  2015, 3,  # AK (corrected)
  # 2016
  22, 2016, 3,  # LA (Jul 2016)
  30, 2016, 1,  # MT (Jan 2016)
  # 2019
  23, 2019, 1,  # ME (Jan 2019)
  51, 2019, 1   # VA (Jan 2019)
)

# Remove the incorrect AK and MO entries from 2014
expansion <- expansion %>%
  filter(!(statefip == 2 & expand_year == 2014)) %>%  # Keep AK 2015 Q3
  filter(!(statefip == 29))  # MO expanded in 2021 — outside sample

# Never-treated states (within our 2010-2019 window):
# TX (48), FL (12), GA (13), WI (55), KS (20), TN (47), MS (28), AL (1),
# SC (45), WY (56), NE (31—expanded 2020), MO (29—expanded 2021),
# OK (40—expanded 2021), SD (46—expanded 2022), NC (37—expanded 2023),
# ID (16—expanded 2020)
never_treated <- c(1, 12, 13, 16, 20, 28, 29, 31, 37, 40, 45, 46, 47, 48, 55, 56)

# Create time period variable (quarters since 2010Q1 = period 1)
qwi <- qwi %>%
  mutate(period = (year - 2010) * 4 + quarter)

# ---- Classify industries by ESI rate ----------------------------------------
# High-ESI: industries where >60% of workers have employer-sponsored insurance
# Based on CPS ASEC / MEPS data on ESI coverage by industry
high_esi <- c("31-33",  # Manufacturing
              "51",     # Information
              "52",     # Finance and Insurance
              "54",     # Professional, Scientific, Technical
              "55",     # Management of Companies
              "22")     # Utilities

low_esi <- c("72",      # Accommodation and Food Services
             "44-45",   # Retail Trade
             "11",      # Agriculture
             "56",      # Admin/Support/Waste Management
             "81",      # Other Services
             "71")      # Arts, Entertainment, Recreation

# ---- Classify education -----------------------------------------------------
# Low education: E1 (< high school), E2 (high school), E3 (some college)
# High education: E4 (bachelor's), E5 (advanced degree)
qwi <- qwi %>%
  mutate(
    low_edu = education %in% c("E1", "E2", "E3"),
    edu_group = ifelse(low_edu, "no_bachelors", "bachelors_plus")
  )

# ---- Merge treatment status --------------------------------------------------
qwi <- qwi %>%
  left_join(expansion, by = "statefip") %>%
  mutate(
    # Treatment period for CS-DiD (first treated period)
    expand_period = ifelse(!is.na(expand_year),
                           (expand_year - 2010) * 4 + expand_qtr,
                           0),  # 0 = never treated
    # Binary post indicator
    post = ifelse(expand_period > 0 & period >= expand_period, 1, 0),
    # Expansion state indicator
    expansion_state = ifelse(!is.na(expand_year), 1, 0),
    # High-ESI indicator
    high_esi = ifelse(industry %in% high_esi, 1,
                      ifelse(industry %in% low_esi, 0, NA)),
    # State abbreviation for labels
    state_name = statefip
  )

# ---- Restrict to classified industries ---------------------------------------
qwi_classified <- qwi %>%
  filter(!is.na(high_esi))

cat(sprintf("Classified sample: %s rows (%s high-ESI, %s low-ESI)\n",
            format(nrow(qwi_classified), big.mark = ","),
            format(sum(qwi_classified$high_esi == 1), big.mark = ","),
            format(sum(qwi_classified$high_esi == 0), big.mark = ",")))

# ---- Construct outcome variables ---------------------------------------------
# Rates per worker for comparability
qwi_classified <- qwi_classified %>%
  mutate(
    hire_rate = HirN / Emp * 100,        # New hires (from other employers) per 100 workers
    sep_rate = Sep / Emp * 100,           # Separations per 100 workers
    hira_rate = HirA / Emp * 100,        # All hires per 100 workers
    net_job_creation = (FrmJbGn - FrmJbLs) / Emp * 100,  # Net job creation rate
    log_earnings = log(EarnS_wtd)         # Log average earnings
  ) %>%
  filter(is.finite(hire_rate), is.finite(sep_rate))

# ---- Aggregate to state × quarter × industry_type × education level ---------
# For the DDD: collapse across specific industries within high/low ESI
panel <- qwi_classified %>%
  group_by(statefip, year, quarter, period, high_esi, edu_group,
           expansion_state, expand_period, post) %>%
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    HirA = sum(HirA, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    EarnS_wtd = weighted.mean(EarnS_wtd, EmpS, na.rm = TRUE),
    EmpS = sum(EmpS, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    hire_rate = HirN / Emp * 100,
    sep_rate = Sep / Emp * 100,
    hira_rate = HirA / Emp * 100,
    net_job_creation = (FrmJbGn - FrmJbLs) / Emp * 100,
    log_earnings = log(EarnS_wtd)
  ) %>%
  filter(is.finite(hire_rate), is.finite(sep_rate))

# Create panel ID for fixest
panel <- panel %>%
  mutate(
    panel_id = paste(statefip, high_esi, edu_group, sep = "_"),
    state_ind = paste(statefip, high_esi, sep = "_"),
    ind_time = paste(high_esi, period, sep = "_"),
    state_time = paste(statefip, period, sep = "_")
  )

cat(sprintf("Final panel: %s rows\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("States: %d | Periods: %d | Industry types: %d | Education groups: %d\n",
            n_distinct(panel$statefip),
            n_distinct(panel$period),
            n_distinct(panel$high_esi),
            n_distinct(panel$edu_group)))

# ---- Save cleaned data -------------------------------------------------------
saveRDS(panel, "../data/panel_clean.rds")
saveRDS(qwi_classified, "../data/qwi_classified.rds")
cat("Saved cleaned panel data.\n")
