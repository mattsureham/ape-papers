## 02_clean_data.R — Construct analysis dataset
## APEP-1185: Kratom Bans and Opioid Overdose Mortality

source("00_packages.R")

df_raw <- readRDS("../data/cdc_vsrr_raw.rds")

cat("Raw data:", nrow(df_raw), "rows,", n_distinct(df_raw$state_name), "states\n")

# ============================================================================
# Define treatment: kratom ban dates
# ============================================================================

ban_info <- tibble(
  state_name = c("Wisconsin", "Indiana", "Arkansas", "Alabama", "Rhode Island"),
  ban_year   = c(2014L, 2014L, 2015L, 2016L, 2017L),
  ban_month  = c(4L, 7L, 10L, 5L, 6L)
)

ban_info <- ban_info %>%
  mutate(ban_ym = ban_year * 12L + ban_month)

# ============================================================================
# Map indicators to analysis categories
# ============================================================================

indicator_map <- c(
  "Number of Drug Overdose Deaths"                = "all_drug_od",
  "Opioids (T40.0-T40.4,T40.6)"                 = "opioids_all",
  "Natural & semi-synthetic opioids (T40.2)"     = "opioids_natural",
  "Synthetic opioids, excl. methadone (T40.4)"   = "opioids_synthetic",
  "Heroin (T40.1)"                                = "heroin",
  "Methadone (T40.3)"                             = "methadone",
  "Cocaine (T40.5)"                               = "cocaine",
  "Psychostimulants with abuse potential (T43.6)" = "psychostimulants"
)

matched <- intersect(names(indicator_map), unique(df_raw$indicator))
cat("\nMatched", length(matched), "of", length(indicator_map), "indicators\n")

# ============================================================================
# Reshape: one row per state-year-month, columns for each drug type
# ============================================================================

df_wide <- df_raw %>%
  filter(indicator %in% names(indicator_map)) %>%
  mutate(drug_type = indicator_map[indicator]) %>%
  select(state_name, year, month, drug_type, data_value) %>%
  pivot_wider(
    names_from = drug_type,
    values_from = data_value,
    values_fn = first
  )

cat("Wide dataset:", nrow(df_wide), "state-months\n")

# ============================================================================
# Add treatment indicators
# ============================================================================

df_wide <- df_wide %>%
  mutate(ym = year * 12L + month) %>%
  left_join(ban_info, by = "state_name") %>%
  mutate(
    treated_state = as.integer(!is.na(ban_year)),
    post_ban = as.integer(!is.na(ban_ym) & ym >= ban_ym),
    # C-S: first_treat = ban_ym for treated, 0 for never-treated
    first_treat = if_else(treated_state == 1L, ban_ym, 0L),
    state_id = as.integer(factor(state_name))
  )

cat("\nTreatment summary:\n")
df_wide %>%
  filter(treated_state == 1) %>%
  distinct(state_name, ban_year, ban_month) %>%
  arrange(ban_year, ban_month) %>%
  print()

cat("\nControl states:", n_distinct(df_wide$state_name[df_wide$treated_state == 0]), "\n")

# ============================================================================
# Check completeness
# ============================================================================

completeness <- df_wide %>%
  group_by(state_name, treated_state) %>%
  summarize(
    n_months = n(),
    first_year = min(year),
    last_year = max(year),
    pct_opioid_nonmissing = mean(!is.na(opioids_all)) * 100,
    .groups = "drop"
  ) %>%
  arrange(pct_opioid_nonmissing)

cat("\nStates with lowest opioid coverage:\n")
print(head(completeness, 10))

# Keep states with at least 50% opioid coverage AND at least 24 months
thin_states <- completeness %>%
  filter(pct_opioid_nonmissing < 50 | n_months < 24) %>%
  pull(state_name)

# Never drop treated states
thin_states <- setdiff(thin_states, ban_info$state_name)

if (length(thin_states) > 0) {
  cat("\nDropping", length(thin_states), "control states with sparse data:",
      paste(thin_states, collapse = ", "), "\n")
  df_wide <- df_wide %>% filter(!state_name %in% thin_states)
}

# Report final panel balance
cat("\nFinal panel:\n")
cat("  States:", n_distinct(df_wide$state_name), "\n")
cat("  Treated:", n_distinct(df_wide$state_name[df_wide$treated_state == 1]), "\n")
cat("  Control:", n_distinct(df_wide$state_name[df_wide$treated_state == 0]), "\n")
cat("  State-months:", nrow(df_wide), "\n")
cat("  Year range:", min(df_wide$year), "-", max(df_wide$year), "\n")

# ============================================================================
# Restrict sample period for clean pre/post design
# CDC VSRR starts 2015 but WI/IN bans were 2014
# We use 2015-2024: WI/IN are already post-treatment in Jan 2015
# AR bans Oct 2015, AL May 2016, RI June 2017
# This gives us clean pre-periods for AR, AL, RI
# WI and IN serve as "always treated" in the 2015+ window
# ============================================================================

# For Callaway-Sant'Anna, WI and IN (banned 2014) are "already treated"
# in our sample window (2015+). We need to handle this:
# Option 1: Treat them as always-treated (exclude from ATT estimation)
# Option 2: Use their ban_ym but note limited pre-period
# We'll use Option 1: focus on AR, AL, RI as the three treatment cohorts
# with clean pre-periods, keeping WI/IN as a supplementary check

df_wide <- df_wide %>%
  mutate(
    # For C-S estimation: only AR, AL, RI have clean pre-periods in VSRR data
    cs_group = case_when(
      state_name == "Arkansas"     ~ 2015L * 12L + 10L,  # Oct 2015
      state_name == "Alabama"      ~ 2016L * 12L + 5L,   # May 2016
      state_name == "Rhode Island" ~ 2017L * 12L + 6L,   # June 2017
      state_name %in% c("Wisconsin", "Indiana") ~ NA_integer_,  # always-treated
      TRUE ~ 0L  # never-treated
    )
  )

cat("\nC-S treatment groups (clean pre-period):\n")
df_wide %>%
  filter(!is.na(cs_group), cs_group > 0) %>%
  distinct(state_name, cs_group) %>%
  print()

cat("\nAlready-treated states (WI, IN) excluded from C-S but kept for TWFE:\n")
df_wide %>%
  filter(is.na(cs_group)) %>%
  distinct(state_name) %>%
  print()

# ============================================================================
# Save
# ============================================================================

saveRDS(df_wide, "../data/analysis_panel.rds")
cat("\nSaved analysis panel:", nrow(df_wide), "rows\n")
