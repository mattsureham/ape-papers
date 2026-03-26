# 02_clean_data.R — Construct analysis panel
source("00_packages.R")

df_raw <- readRDS("../data/qwi_raw.rds")

# ---- Permitless carry adoption dates ----
# Sources: Rand Corporation State Firearm Law Database, Giffords Law Center
# Year law took effect
permitless_carry <- tribble(
  ~state_fips, ~adopt_year,
  "02", 2003,  # AK
  "04", 2010,  # AZ
  "05", 2013,  # AR
  "56", 2011,  # WY
  "20", 2015,  # KS
  "23", 2015,  # ME
  "28", 2016,  # MS
  "54", 2016,  # WV
  "16", 2016,  # ID
  "29", 2017,  # MO
  "33", 2017,  # NH
  "38", 2017,  # ND
  "21", 2019,  # KY
  "46", 2019,  # SD
  "40", 2019,  # OK
  "30", 2021,  # MT
  "19", 2021,  # IA
  "49", 2021,  # UT
  "47", 2021,  # TN
  "48", 2021,  # TX
  "22", 2022,  # LA
  "18", 2022,  # IN
  "39", 2022,  # OH
  "13", 2022,  # GA
  "01", 2023,  # AL
  "12", 2023,  # FL
  "31", 2023,  # NE
  "37", 2023,  # NC
  "45", 2024,  # SC
  "51", 2024   # VA
)

# Never-treated states
never_treated <- c("06", "09", "10", "11", "15", "17", "24", "25",
                   "34", "36", "44")

# ---- Merge treatment timing ----
df <- df_raw %>%
  left_join(permitless_carry, by = "state_fips") %>%
  mutate(
    first_treat_year = ifelse(!is.na(adopt_year), adopt_year, 0),
    treated = as.integer(!is.na(adopt_year) & year >= adopt_year),
    sector = case_when(
      industry == "72" ~ "accommodation",
      industry == "31-33" ~ "manufacturing",
      TRUE ~ "other"
    ),
    race_label = ifelse(race == "A1", "white", "black")
  )

# ---- Filter to our analysis sample ----
# CRITICAL: Use ethnicity = A0 (all ethnicities) to avoid double-counting
# A0 = total, A1 = non-Hispanic, A2 = Hispanic → summing all three triples counts
valid_states <- c(permitless_carry$state_fips, never_treated)
df <- df %>%
  filter(state_fips %in% valid_states, year >= 2005, year <= 2024,
         ethnicity == "A0")

# ---- Aggregate: state × year × race × sector (annual) ----
# Some states have multiple ethnicity rows — collapse across ethnicity
annual <- df %>%
  group_by(state_fips, year, race_label, sector, first_treat_year) %>%
  summarise(
    Emp = mean(Emp, na.rm = TRUE),   # stock: average across quarters
    HirA = sum(HirA, na.rm = TRUE),  # flow: sum across quarters
    Sep = sum(Sep, na.rm = TRUE),    # flow: sum across quarters
    EarnHirAS = if (sum(!is.na(EarnHirAS) & !is.na(HirA)) > 0)
      weighted.mean(EarnHirAS[!is.na(EarnHirAS) & !is.na(HirA)],
                    HirA[!is.na(EarnHirAS) & !is.na(HirA)]) else NA_real_,
    .groups = "drop"
  ) %>%
  mutate(
    log_emp = log(pmax(Emp, 1)),
    log_hires = log(pmax(HirA, 1)),
    state_id = as.numeric(factor(state_fips))
  )

cat(sprintf("States in sample: %d\n", length(unique(annual$state_fips))))
cat(sprintf("Treated states: %d\n",
            length(unique(annual$state_fips[annual$first_treat_year > 0]))))
cat(sprintf("Never-treated states: %d\n",
            length(unique(annual$state_fips[annual$first_treat_year == 0]))))
cat(sprintf("Years: %d-%d\n", min(annual$year), max(annual$year)))
cat(sprintf("Panel rows: %s\n", format(nrow(annual), big.mark = ",")))

# ---- Summary statistics ----
cat("\n=== Summary Statistics ===\n")
summ <- annual %>%
  group_by(race_label, sector) %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hires = mean(HirA, na.rm = TRUE),
    mean_earn = mean(EarnHirAS, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
print(summ, n = 10)

# ---- Save ----
saveRDS(annual, "../data/annual_panel.rds")
cat("\nSaved annual_panel.rds\n")
cat("Done.\n")
