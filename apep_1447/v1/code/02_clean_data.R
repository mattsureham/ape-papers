## 02_clean_data.R — Variable construction and sample validation
source("00_packages.R")

panel <- read_csv("../data/panel.csv", show_col_types = FALSE)

cat("=== Cleaning and constructing variables ===\n")

# ---------------------------------------------------------------
# 1. Validate Kaitz index and treatment assignment
# ---------------------------------------------------------------
cat("\nKaitz index summary:\n")
kaitz_summary <- panel %>%
  filter(year == 2015) %>%
  summarise(
    n = n(),
    mean_kaitz = mean(kaitz_actual),
    sd_kaitz = sd(kaitz_actual),
    min_kaitz = min(kaitz_actual),
    max_kaitz = max(kaitz_actual),
    median_kaitz = median(kaitz_actual),
    n_high = sum(high_kaitz),
    n_low = sum(1 - high_kaitz)
  )
print(kaitz_summary)

# ---------------------------------------------------------------
# 2. Construct additional outcome variables
# ---------------------------------------------------------------
panel <- panel %>%
  group_by(prov_id) %>%
  arrange(year) %>%
  mutate(
    # Changes
    d_unemp = unemp_rate - lag(unemp_rate),
    d_lfp = lfp_rate - lag(lfp_rate),
    d_log_mw = log_min_wage - lag(log_min_wage),
    # Real minimum wage (deflated by province GRDP as proxy)
    real_mw = min_wage / grdp_pc,
    # Wage bite: min wage / GRDP per capita (Kaitz-style)
    wage_bite = min_wage / grdp_pc
  ) %>%
  ungroup()

# ---------------------------------------------------------------
# 3. Event-study time dummies
# ---------------------------------------------------------------
# Omit 2015 (last pre-treatment year) as reference
panel <- panel %>%
  mutate(
    rel_year = year - 2016,  # -5 to 3
    # Interaction terms for event study
    kaitz_x_post = kaitz_actual * post
  )

# ---------------------------------------------------------------
# 4. Summary statistics by treatment group
# ---------------------------------------------------------------
cat("\nPre-treatment (2011-2015) means by treatment group:\n")
pre_summary <- panel %>%
  filter(year <= 2015) %>%
  group_by(high_kaitz) %>%
  summarise(
    n_provinces = n_distinct(prov_id),
    mean_unemp = mean(unemp_rate, na.rm = TRUE),
    sd_unemp = sd(unemp_rate, na.rm = TRUE),
    mean_lfp = mean(lfp_rate, na.rm = TRUE),
    sd_lfp = sd(lfp_rate, na.rm = TRUE),
    mean_emp = mean(emp_rate, na.rm = TRUE),
    sd_emp = sd(emp_rate, na.rm = TRUE),
    mean_mw = mean(min_wage, na.rm = TRUE),
    mean_grdp = mean(grdp_pc, na.rm = TRUE),
    .groups = "drop"
  )
print(pre_summary)

# ---------------------------------------------------------------
# 5. Pre-treatment balance test
# ---------------------------------------------------------------
cat("\nPre-treatment balance (2015 only):\n")
balance <- panel %>%
  filter(year == 2015) %>%
  group_by(high_kaitz) %>%
  summarise(
    across(c(unemp_rate, lfp_rate, emp_rate, min_wage, grdp_pc),
           list(mean = mean, sd = sd), .names = "{.col}_{.fn}"),
    .groups = "drop"
  )
print(balance)

write_csv(panel, "../data/panel_clean.csv")

cat(sprintf("\n=== Clean panel: %d rows ===\n", nrow(panel)))
