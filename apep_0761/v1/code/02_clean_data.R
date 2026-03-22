## 02_clean_data.R — Construct treatment variables and analysis panel
## apep_0761: Post-Dobbs Healthcare Labor Reallocation

source("00_packages.R")

qwi_raw <- readRDS("../data/qwi_raw.rds")

# ── Parse numeric variables ──
qwi <- qwi_raw %>%
  mutate(
    Emp = as.numeric(Emp),
    EmpS = as.numeric(EmpS),
    EarnS = as.numeric(EarnS),
    EmpEnd = as.numeric(EmpEnd),
    state_fips = as.character(state)
  ) %>%
  # Parse time into year and quarter
  mutate(
    year = as.integer(sub("-Q.*", "", time)),
    quarter = as.integer(sub(".*-Q", "", time)),
    # Create numeric quarter for panel
    yq = year + (quarter - 1) / 4
  )

# ── State names and FIPS mapping ──
state_info <- tibble(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,
                                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                                  36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,
                                  53,54,55,56)),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                 "Connecticut","Delaware","DC","Florida","Georgia","Hawaii","Idaho",
                 "Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine",
                 "Maryland","Massachusetts","Michigan","Minnesota","Mississippi",
                 "Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey",
                 "New Mexico","New York","North Carolina","North Dakota","Ohio",
                 "Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina",
                 "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia",
                 "Washington","West Virginia","Wisconsin","Wyoming"),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
                 "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
                 "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
                 "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

# ── Define treatment groups ──
# Ban states: trigger laws or near-immediate bans after Dobbs (June 24, 2022)
# Treatment quarter: 2022Q3 for all (bans effective June-August 2022)
ban_states <- c("AL", "AR", "ID", "KY", "LA", "MS", "MO", "ND", "OK",
                "SD", "TN", "TX", "WY", "WV")
# Georgia, Indiana, South Carolina had later/partial bans — exclude for clean design

# Receiving states: non-ban states bordering ban states, known destination for cross-state travel
receiving_states <- c("IL", "CO", "KS", "NM", "NC", "VA", "MN", "MT", "NE")

# All other states
qwi <- qwi %>%
  left_join(state_info, by = "state_fips") %>%
  mutate(
    ban_state = state_abbr %in% ban_states,
    receiving_state = state_abbr %in% receiving_states,
    group = case_when(
      ban_state ~ "Ban",
      receiving_state ~ "Receiving",
      TRUE ~ "Control"
    ),
    # Treatment timing for CS-DiD: first treated quarter
    # All ban states treated at 2022Q3 (yq = 2022.5)
    first_treat_ban = ifelse(ban_state, 2022.5, 0),
    # Receiving states also "treated" at 2022Q3 (demand shock)
    first_treat_recv = ifelse(receiving_state, 2022.5, 0),
    # Post-Dobbs indicator
    post_dobbs = yq >= 2022.5,
    # Log employment (add 1 to handle zeros)
    log_emp = log(Emp + 1),
    log_emps = log(EmpS + 1),
    log_earns = log(EarnS + 1)
  )

# ── Industry labels ──
qwi <- qwi %>%
  mutate(
    industry_label = case_when(
      industry == "62141" ~ "Family Planning",
      industry == "6211"  ~ "Physician Offices",
      industry == "6214"  ~ "Outpatient Care",
      industry == "6219"  ~ "Other Ambulatory",
      industry == "6213"  ~ "Dental/Optometry (Placebo)",
      TRUE ~ industry
    )
  )

# ── Create panel unit ID: state x industry ──
qwi <- qwi %>%
  mutate(
    unit_id = paste(state_fips, industry, sep = "_"),
    # Numeric time index (quarter number from 2015Q1)
    time_idx = (year - 2015) * 4 + quarter
  )

# ── Remove missing observations ──
cat("Before cleaning:", nrow(qwi), "rows\n")
qwi_clean <- qwi %>%
  filter(!is.na(Emp), Emp >= 0)
cat("After cleaning:", nrow(qwi_clean), "rows\n")

# ── Summary ──
cat("\nPanel structure:\n")
cat("  States:", n_distinct(qwi_clean$state_fips), "\n")
cat("  Industries:", n_distinct(qwi_clean$industry), "\n")
cat("  Time periods:", n_distinct(qwi_clean$yq), "\n")
cat("  Total obs:", nrow(qwi_clean), "\n")
cat("  Ban states:", sum(qwi_clean$ban_state & !duplicated(qwi_clean$state_fips[qwi_clean$ban_state])), "\n")
cat("  Receiving states:", sum(qwi_clean$receiving_state & !duplicated(qwi_clean$state_fips[qwi_clean$receiving_state])), "\n")

# ── Group means pre/post ──
group_summary <- qwi_clean %>%
  filter(industry == "62141") %>%
  group_by(group, post_dobbs) %>%
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
cat("\nFamily Planning (62141) employment by group and period:\n")
print(group_summary)

# ── Save cleaned panel ──
saveRDS(qwi_clean, "../data/panel.rds")
cat("\nSaved panel.rds\n")
