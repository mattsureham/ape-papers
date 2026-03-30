## 02_clean_data.R — Clean and construct analysis dataset
## Paper: apep_1121 — Swiss cantonal debt brakes and spending composition

source("00_packages.R")

cat("=== Cleaning and constructing analysis dataset ===\n")

# ---------------------------------------------------------------
# 1. LOAD RAW DATA
# ---------------------------------------------------------------

expenditure_panel <- read_csv("../data/cantonal_expenditure_panel.csv", show_col_types = FALSE)
debt_brake_timing <- read_csv("../data/debt_brake_timing.csv", show_col_types = FALSE)

cat("Raw panel:", nrow(expenditure_panel), "rows\n")
cat("Cantons:", n_distinct(expenditure_panel$canton), "\n")
cat("Years:", min(expenditure_panel$year), "-", max(expenditure_panel$year), "\n")

# ---------------------------------------------------------------
# 2. COMPUTE EXPENDITURE SHARES
# ---------------------------------------------------------------

cat("\n=== Computing expenditure shares ===\n")

# Get total expenditure for each canton-year
totals <- expenditure_panel %>%
  filter(func_code == "total") %>%
  select(canton, year, total_expenditure = expenditure)

# Compute functional shares
func_shares <- expenditure_panel %>%
  filter(func_code != "total") %>%
  left_join(totals, by = c("canton", "year")) %>%
  mutate(
    share = expenditure / total_expenditure * 100  # Percentage
  )

cat("Functional shares computed.\n")
cat("Missing total_expenditure:", sum(is.na(func_shares$total_expenditure)), "\n")
cat("Missing share values:", sum(is.na(func_shares$share)), "\n")

# ---------------------------------------------------------------
# 3. CREATE SHORT FUNCTION LABELS
# ---------------------------------------------------------------

func_labels <- tribble(
  ~func_code, ~func_short,
  "0", "Administration",
  "1", "Security",
  "2", "Education",
  "3", "Culture",
  "4", "Health",
  "5", "Social",
  "6", "Transport",
  "7", "Environment",
  "8", "Economy",
  "9", "Finance"
)

func_shares <- func_shares %>%
  left_join(func_labels, by = "func_code")

# ---------------------------------------------------------------
# 4. MERGE WITH DEBT BRAKE TIMING
# ---------------------------------------------------------------

cat("\n=== Merging with debt brake timing ===\n")

analysis_df <- func_shares %>%
  left_join(debt_brake_timing %>% select(canton = canton_abbr, adoption_year, rule_type),
            by = "canton") %>%
  mutate(
    # Treatment indicator
    treated = as.integer(is.finite(adoption_year)),
    post = as.integer(year >= adoption_year),
    treat_post = treated * post,

    # For Callaway-Sant'Anna: first_treat = adoption year (0 for never-treated)
    first_treat = ifelse(is.finite(adoption_year), adoption_year, 0),

    # Adoption cohort
    cohort = case_when(
      !is.finite(adoption_year) ~ "Never treated",
      adoption_year < 1990 ~ "Pre-1990",
      adoption_year <= 2000 ~ "1994-2000",
      adoption_year <= 2005 ~ "2001-2005",
      adoption_year <= 2010 ~ "2006-2010",
      TRUE ~ "2011+"
    ),

    # Canton numeric ID for panel
    canton_id = as.integer(factor(canton))
  )

cat("Analysis dataset constructed.\n")
cat("Total obs:", nrow(analysis_df), "\n")

# ---------------------------------------------------------------
# 5. HANDLE PRE-1990 ADOPTERS
# ---------------------------------------------------------------

# St. Gallen (1929) and Fribourg (1960) adopted before our panel starts (1990).
# These cantons are ALWAYS treated in our sample window.
# For CS estimator, we can either:
# (a) Drop them (lose 2 cantons)
# (b) Treat them as never-treated controls (they've had rules for decades)
# (c) Treat them as an "always treated" group
#
# We follow approach (b): reclassify pre-1990 adopters as always-treated.
# Since their rules were adopted >30 years before our window,
# any treatment effect has long stabilized. They serve as a different
# counterfactual from the never-treated group.
# Sensitivity: we also report results dropping them entirely.

analysis_df <- analysis_df %>%
  mutate(
    first_treat_cs = case_when(
      adoption_year < 1990 ~ 0,  # Treated as never-treated for CS
      is.finite(adoption_year) ~ adoption_year,
      TRUE ~ 0  # Never-treated
    )
  )

cat("\nAdoption cohort distribution:\n")
analysis_df %>%
  filter(func_code == "2", year == 2010) %>%  # One function, one year
  count(cohort) %>%
  print()

# ---------------------------------------------------------------
# 6. SUMMARY STATISTICS
# ---------------------------------------------------------------

cat("\n=== Summary statistics by function ===\n")

analysis_df %>%
  group_by(func_short) %>%
  summarise(
    mean_share = mean(share, na.rm = TRUE),
    sd_share = sd(share, na.rm = TRUE),
    min_share = min(share, na.rm = TRUE),
    max_share = max(share, na.rm = TRUE),
    n_obs = sum(!is.na(share)),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_share)) %>%
  print(n = 15)

cat("\n=== Treated vs never-treated comparison ===\n")

analysis_df %>%
  filter(func_code != "total", year <= 1993) %>%  # Pre-treatment for most
  mutate(group = ifelse(treated == 1, "Later treated", "Never treated")) %>%
  group_by(group, func_short) %>%
  summarise(mean_share = mean(share, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = group, values_from = mean_share) %>%
  print(n = 15)

# ---------------------------------------------------------------
# 7. SAVE ANALYSIS DATASET
# ---------------------------------------------------------------

write_csv(analysis_df, "../data/analysis_panel.csv")
cat("\nSaved analysis_panel.csv:", nrow(analysis_df), "rows\n")

cat("\n=== Data cleaning complete ===\n")
