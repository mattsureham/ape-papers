# 02_clean_data.R — Clean and construct analysis panel
# apep_0896: Does the Right to Repair Create Repairers?

source("00_packages.R")

# ── Load raw QCEW data ──
qcew_raw <- read_csv("../data/qcew_raw.csv", show_col_types = FALSE)
cat(sprintf("Raw data: %d rows\n", nrow(qcew_raw)))

# ── Filter to state-level, private sector, 4-digit NAICS ──
# agglvl_code 56 = State, by ownership, 4-digit NAICS
# own_code 5 = Private
qcew_state <- qcew_raw %>%
  filter(
    agglvl_code == 56,
    own_code == 5
  )

cat(sprintf("State-level private rows: %d\n", nrow(qcew_state)))
cat(sprintf("Unique area_fips: %d\n", n_distinct(qcew_state$area_fips)))

# ── Create state FIPS and time variables ──
# area_fips format: "SSFFF" where SS = state, FFF = county (000 = state total)
qcew_state <- qcew_state %>%
  mutate(
    state_fips = substr(area_fips, 1, 2),
    # Create numeric quarter index: 2019Q1 = 1, 2019Q2 = 2, ...
    time_q = (year - 2019) * 4 + qtr
  )

# ── State name mapping ──
state_map <- tibble(
  state_fips = c(
    "01","02","04","05","06","08","09","10","11","12",
    "13","15","16","17","18","19","20","21","22","23",
    "24","25","26","27","28","29","30","31","32","33",
    "34","35","36","37","38","39","40","41","42","44",
    "45","46","47","48","49","50","51","53","54","55","56"
  ),
  state_name = c(
    "Alabama","Alaska","Arizona","Arkansas","California","Colorado",
    "Connecticut","Delaware","District of Columbia","Florida",
    "Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas",
    "Kentucky","Louisiana","Maine","Maryland","Massachusetts",
    "Michigan","Minnesota","Mississippi","Missouri","Montana",
    "Nebraska","Nevada","New Hampshire","New Jersey","New Mexico",
    "New York","North Carolina","North Dakota","Ohio","Oklahoma",
    "Oregon","Pennsylvania","Rhode Island","South Carolina",
    "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia",
    "Washington","West Virginia","Wisconsin","Wyoming"
  ),
  state_abbr = c(
    "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
    "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
    "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
    "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
    "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
  )
)

qcew_state <- qcew_state %>%
  left_join(state_map, by = "state_fips")

# ── Define RTR treatment ──
# NY: effective July 1, 2023 → treated from 2023Q3 (time_q = 19)
# CA: effective July 1, 2024 → treated from 2024Q3 (time_q = 23)
# MN: effective July 1, 2024 → treated from 2024Q3 (time_q = 23)
# OR: effective Jan 1, 2025 → treated from 2025Q1 (time_q = 25)
# CO: effective Jan 1, 2025 → treated from 2025Q1 (time_q = 25)

rtr_treatment <- tibble(
  state_abbr = c("NY", "CA", "MN", "OR", "CO"),
  first_treat_q = c(19, 23, 23, 25, 25),  # time_q of first treatment
  rtr_year_q = c("2023Q3", "2024Q3", "2024Q3", "2025Q1", "2025Q1")
)

qcew_state <- qcew_state %>%
  left_join(rtr_treatment, by = "state_abbr") %>%
  mutate(
    first_treat_q = ifelse(is.na(first_treat_q), 0, first_treat_q),  # 0 = never treated
    treated = ifelse(first_treat_q > 0 & time_q >= first_treat_q, 1, 0),
    rtr_state = ifelse(first_treat_q > 0, 1, 0)
  )

# ── Create analysis variables ──
panel <- qcew_state %>%
  select(
    state_fips, state_name, state_abbr, naics_code,
    year, qtr, time_q,
    estabs = qtrly_estabs,
    emp_m1 = month1_emplvl,
    emp_m2 = month2_emplvl,
    emp_m3 = month3_emplvl,
    total_wages = total_qtrly_wages,
    avg_wkly_wage,
    first_treat_q, treated, rtr_state,
    rtr_year_q
  ) %>%
  mutate(
    # Average monthly employment across 3 months in quarter
    emp = (emp_m1 + emp_m2 + emp_m3) / 3,
    # Log transforms (add 1 for zeros)
    log_estabs = log(estabs + 1),
    log_emp = log(emp + 1),
    log_avg_wage = log(avg_wkly_wage + 1),
    # Year-quarter label
    yq = paste0(year, "Q", qtr)
  )

# ── Verify panel balance ──
cat("\n=== Panel Summary ===\n")
cat(sprintf("States: %d\n", n_distinct(panel$state_fips)))
cat(sprintf("Quarters: %d\n", n_distinct(panel$time_q)))
cat(sprintf("NAICS codes: %s\n", paste(unique(panel$naics_code), collapse = ", ")))

panel_8112 <- panel %>% filter(naics_code == "8112")
panel_8111 <- panel %>% filter(naics_code == "8111")

cat(sprintf("\nNAICS 8112 (Electronic Repair):\n"))
cat(sprintf("  Obs: %d\n", nrow(panel_8112)))
cat(sprintf("  States: %d\n", n_distinct(panel_8112$state_fips)))
cat(sprintf("  Quarters: %d\n", n_distinct(panel_8112$time_q)))
cat(sprintf("  Treated states: %s\n",
  paste(panel_8112 %>% filter(rtr_state == 1) %>% distinct(state_abbr) %>% pull(), collapse = ", ")))
cat(sprintf("  Never-treated states: %d\n",
  n_distinct(panel_8112 %>% filter(rtr_state == 0) %>% pull(state_fips))))

cat(sprintf("\nNAICS 8111 (Automotive Repair, placebo):\n"))
cat(sprintf("  Obs: %d\n", nrow(panel_8111)))
cat(sprintf("  States: %d\n", n_distinct(panel_8111$state_fips)))

# ── Treatment cohort sizes ──
cat("\n=== Treatment Cohorts ===\n")
panel_8112 %>%
  filter(rtr_state == 1) %>%
  distinct(state_abbr, first_treat_q, rtr_year_q) %>%
  arrange(first_treat_q) %>%
  print()

# ── Summary statistics for pre-treatment period ──
cat("\n=== Pre-Treatment Summary (NAICS 8112, 2019Q1-2023Q2) ===\n")
pre_summ <- panel_8112 %>%
  filter(time_q < 19) %>%  # Before NY treatment
  group_by(rtr_state) %>%
  summarise(
    mean_estabs = mean(estabs, na.rm = TRUE),
    sd_estabs = sd(estabs, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    mean_wage = mean(avg_wkly_wage, na.rm = TRUE),
    sd_wage = sd(avg_wkly_wage, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )
print(pre_summ)

# ── Check for disclosure issues (suppressed cells) ──
cat("\n=== Disclosure Status (NAICS 8112) ===\n")
panel_8112 %>%
  count(disclosure_code = ifelse(estabs == 0, "suppressed", "disclosed")) %>%
  print()

# ── Save analysis panel ──
write_csv(panel, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved to data/analysis_panel.csv\n")

# ── Assertions ──
stopifnot("Panel must have data" = nrow(panel) > 0)
stopifnot("Must have both NAICS codes" = all(c("8112", "8111") %in% panel$naics_code))
stopifnot("Must have treated states" = sum(panel$rtr_state) > 0)
n_treated_states <- n_distinct(panel_8112$state_fips[panel_8112$rtr_state == 1])
stopifnot("Must have at least 5 treated states" = n_treated_states >= 5)
