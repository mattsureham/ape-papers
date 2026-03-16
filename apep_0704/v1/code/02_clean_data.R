## 02_clean_data.R — Construct analysis panel for PSL paper
## apep_0704: Paid Sick Leave and Worker Separation Dynamics

source("00_packages.R")

cat("=== Cleaning QWI data ===\n")

# ── Load raw data ──
qwi <- readRDS("../data/qwi_raw.rds")
psl_dates <- readRDS("../data/psl_dates.rds")
state_fips <- readRDS("../data/state_fips.rds")

# ── Extract state FIPS from county geography codes ──
# QWI geography is 5-digit county FIPS (e.g., "01001"); first 2 = state
qwi <- qwi %>%
  mutate(
    fips_county = str_pad(as.character(fips_state), 5, pad = "0"),
    fips_state = substr(fips_county, 1, 2),
    # Create year-quarter numeric identifier
    yq = year + (quarter - 1) / 4,
    # Create integer time period for CS-DiD
    time_period = (year - 2005) * 4 + quarter
  )

cat(sprintf("County FIPS codes: %d unique\n", n_distinct(qwi$fips_county)))
cat(sprintf("State FIPS codes: %d unique\n", n_distinct(qwi$fips_state)))

# ── Merge state abbreviations ──
qwi <- qwi %>%
  left_join(state_fips, by = "fips_state")

# Drop non-state geographies (territories, etc.)
qwi <- qwi %>% filter(!is.na(state_abbr))

cat(sprintf("States after merge: %d\n", n_distinct(qwi$state_abbr)))

# ── Classify industries ──
qwi <- qwi %>%
  mutate(
    ind_group = case_when(
      industry %in% c("72") ~ "Accommodation/Food",
      industry %in% c("44-45") ~ "Retail",
      industry %in% c("62") ~ "Healthcare",
      industry %in% c("52") ~ "Finance",
      industry %in% c("54") ~ "Professional Services",
      industry %in% c("23") ~ "Construction",
      industry %in% c("31-33") ~ "Manufacturing",
      industry %in% c("42") ~ "Wholesale",
      industry %in% c("48-49") ~ "Transportation",
      industry %in% c("61") ~ "Education",
      industry %in% c("71") ~ "Arts/Recreation",
      industry %in% c("81") ~ "Other Services",
      industry %in% c("51") ~ "Information",
      industry %in% c("53") ~ "Real Estate",
      industry %in% c("55") ~ "Management",
      industry %in% c("56") ~ "Admin/Waste",
      industry %in% c("11") ~ "Agriculture",
      industry %in% c("21") ~ "Mining",
      industry %in% c("22") ~ "Utilities",
      industry %in% c("92") ~ "Public Admin",
      TRUE ~ "Other"
    ),
    high_exposure = industry %in% c("72", "44-45", "62"),
    low_exposure = industry %in% c("52", "54")
  )

# ── Aggregate from county to state level ──
cat("Aggregating county data to state level...\n")
qwi <- qwi %>%
  group_by(fips_state, state_abbr, year, quarter, yq, time_period,
           industry, ind_group, high_exposure, low_exposure, sex, agegrp) %>%
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    EmpEnd = sum(EmpEnd, na.rm = TRUE),
    HirA = sum(HirA, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    # Earnings: weighted mean (handle NA alignment)
    EarnS = if (all(is.na(EarnS) | is.na(Emp))) NA_real_
            else weighted.mean(EarnS[!is.na(EarnS) & !is.na(Emp)],
                               Emp[!is.na(EarnS) & !is.na(Emp)]),
    EarnHirAS = if (all(is.na(EarnHirAS) | is.na(HirA))) NA_real_
                else weighted.mean(EarnHirAS[!is.na(EarnHirAS) & !is.na(HirA)],
                                   HirA[!is.na(EarnHirAS) & !is.na(HirA)]),
    TurnOvrS = sum(TurnOvrS, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("After state aggregation: %s rows\n", format(nrow(qwi), big.mark = ",")))

# ── Merge PSL treatment dates ──
qwi <- qwi %>%
  left_join(psl_dates %>% select(state_abbr, first_treat_yq), by = "state_abbr") %>%
  mutate(
    # Never-treated states get Inf (for CS-DiD)
    first_treat_yq = ifelse(is.na(first_treat_yq), Inf, first_treat_yq),
    # Post-treatment indicator
    post = yq >= first_treat_yq,
    # Treated state indicator
    treated_state = is.finite(first_treat_yq)
  )

cat(sprintf("Treated states: %d\n", n_distinct(qwi$state_abbr[qwi$treated_state])))
cat(sprintf("Control states: %d\n", n_distinct(qwi$state_abbr[!qwi$treated_state])))

# ── Construct key outcome rates (per 100 workers) ──
# Use sex = 0 (all sexes) and agegrp = A00 (all ages) for main spec
qwi_main <- qwi %>%
  filter(sex == "0", agegrp == "A00") %>%
  mutate(
    sep_rate = Sep / Emp * 100,
    hire_rate = HirA / Emp * 100,
    new_hire_rate = HirN / Emp * 100,
    turnover_rate = TurnOvrS / Emp * 100,
    earnings = EarnS
  ) %>%
  filter(!is.na(sep_rate), is.finite(sep_rate), Emp > 0)

cat(sprintf("Main panel (all sex, all age): %s rows\n",
            format(nrow(qwi_main), big.mark = ",")))

# ── Construct age-specific panels for heterogeneity ──
qwi_age <- qwi %>%
  filter(sex == "0", agegrp != "A00") %>%
  mutate(
    age_group = case_when(
      agegrp == "A01" ~ "14-18",
      agegrp == "A02" ~ "19-21",
      agegrp == "A03" ~ "22-24",
      agegrp == "A04" ~ "25-34",
      agegrp == "A05" ~ "35-44",
      agegrp == "A06" ~ "45-54",
      agegrp == "A07" ~ "55-64",
      agegrp == "A08" ~ "65+",
      TRUE ~ "Unknown"
    ),
    young_worker = agegrp %in% c("A01", "A02", "A03"),
    sep_rate = Sep / Emp * 100,
    hire_rate = HirA / Emp * 100
  ) %>%
  filter(!is.na(sep_rate), is.finite(sep_rate), Emp > 0)

cat(sprintf("Age panel: %s rows\n", format(nrow(qwi_age), big.mark = ",")))

# ── Create state × industry panel ID ──
qwi_main <- qwi_main %>%
  mutate(state_ind = paste(state_abbr, industry, sep = "_"))

# ── For CS-DiD: need integer group variable ──
# first_treat_period: integer encoding of first treatment quarter
qwi_main <- qwi_main %>%
  mutate(
    first_treat_period = ifelse(
      is.finite(first_treat_yq),
      (floor(first_treat_yq) - 2005) * 4 + round((first_treat_yq - floor(first_treat_yq)) * 4) + 1,
      0  # never-treated
    )
  )

# ── Summary statistics ──
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Panel: %d state-industries × %d quarters\n",
            n_distinct(qwi_main$state_ind),
            n_distinct(qwi_main$time_period)))
cat(sprintf("Year range: %d–%d\n", min(qwi_main$year), max(qwi_main$year)))

qwi_main %>%
  filter(high_exposure) %>%
  group_by(treated_state) %>%
  summarise(
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    mean_earnings = mean(earnings, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ── Save cleaned panels ──
saveRDS(qwi_main, "../data/qwi_main.rds")
saveRDS(qwi_age, "../data/qwi_age.rds")

cat("\n=== Cleaning complete ===\n")
