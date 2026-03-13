## 02_clean_data.R — Additional cleaning and panel preparation
## apep_0640: E-Verify Mandates and Hispanic Employment
## NOTE: Primary cleaning done in 01_fetch_data.R (Azure aggregation)

source("00_packages.R")

cat("Loading state panel...\n")
df <- readRDS("../data/state_panel.rds")

# ============================================================================
# Create Hispanic employment share panel (pre-treatment baseline)
# ============================================================================
hisp_share <- df %>%
  filter(year <= 2007) %>%
  group_by(state_fips, ethnicity_label) %>%
  summarise(avg_emp = mean(Emp, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = ethnicity_label, values_from = avg_emp) %>%
  mutate(hisp_share = Hispanic / (Hispanic + `Non-Hispanic`)) %>%
  select(state_fips, hisp_share)

saveRDS(hisp_share, "../data/hisp_share.rds")

# ============================================================================
# Create CS-DiD ready Hispanic-only panel
# ============================================================================
hisp_panel <- df %>%
  filter(hispanic == 1) %>%
  # Drop SC (2021) and FL (2023) — too recent / COVID contamination
  # Keep in robustness
  mutate(
    # For CS-DiD: need numeric id and time
    unit_id = state_fips,
    period = time_index
  )

cat(sprintf("Hispanic panel: %d states, %d quarters, %s obs\n",
            n_distinct(hisp_panel$state_fips),
            n_distinct(hisp_panel$time_index),
            format(nrow(hisp_panel), big.mark = ",")))

saveRDS(hisp_panel, "../data/hisp_panel.rds")

# ============================================================================
# Descriptive table data
# ============================================================================
cat("\n=== Hispanic Employment by E-Verify Status ===\n")
df %>%
  filter(hispanic == 1, year %in% c(2007, 2014, 2020)) %>%
  group_by(treated, year) %>%
  summarise(
    total_emp = sum(Emp) / 1e6,
    mean_earn = weighted.mean(EarnS, w = Emp, na.rm = TRUE),
    mean_hire_rate = weighted.mean(hire_rate, w = Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(group = ifelse(treated, "E-Verify states", "Control states")) %>%
  select(group, year, total_emp, mean_earn, mean_hire_rate) %>%
  print(n = 10)

cat("\nData cleaning complete.\n")
