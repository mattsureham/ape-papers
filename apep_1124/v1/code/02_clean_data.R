## ============================================================
## 02_clean_data.R — Construct analysis panel
## apep_1124: Sanctions at Sea
## ============================================================

source("00_packages.R")

cat("=== Loading raw data ===\n")

gfw_annual  <- read_csv("../data/gfw_annual.csv", show_col_types = FALSE)
iuu_cards   <- read_csv("../data/iuu_cards.csv", show_col_types = FALSE)
comtrade_df <- read_csv("../data/comtrade_seafood.csv", show_col_types = FALSE)

# ---------------------------------------------------------------
# 1. Construct Treatment Variable
# ---------------------------------------------------------------

cat("=== Constructing treatment panel ===\n")

# For Callaway-Sant'Anna:
#   gname: first treatment year (0 for never-treated)
#   tname: time period (year)
#   idname: unit identifier (numeric)

carded_countries <- iuu_cards %>%
  select(flag_iso3, yellow_year) %>%
  rename(first_treat = yellow_year)

# ---------------------------------------------------------------
# 2. Annual Panel
# ---------------------------------------------------------------

panel_annual <- gfw_annual %>%
  left_join(carded_countries, by = "flag_iso3") %>%
  mutate(
    first_treat = replace_na(first_treat, 0),
    treated = as.integer(first_treat > 0 & year >= first_treat),
    ln_fishing_hours = log(fishing_hours + 1),
    hours_per_vessel = fishing_hours / pmax(n_vessels, 1),
    ln_hours_per_vessel = log(hours_per_vessel + 1),
    ln_vessels = log(n_vessels + 1)
  )

# Create numeric ID for each flag state
flag_ids <- panel_annual %>%
  distinct(flag_iso3) %>%
  arrange(flag_iso3) %>%
  mutate(flag_id = row_number())

panel_annual <- panel_annual %>%
  left_join(flag_ids, by = "flag_iso3")

n_treated_countries <- n_distinct(panel_annual$flag_iso3[panel_annual$first_treat > 0])
n_control_countries <- n_distinct(panel_annual$flag_iso3[panel_annual$first_treat == 0])

cat(sprintf("Annual panel: %d obs, %d countries (%d treated, %d control)\n",
            nrow(panel_annual),
            n_distinct(panel_annual$flag_iso3),
            n_treated_countries, n_control_countries))

# ---------------------------------------------------------------
# 3. EU Export Dependence (for heterogeneity)
# ---------------------------------------------------------------

if (nrow(comtrade_df) > 0) {
  eu_dep <- comtrade_df %>%
    pivot_wider(names_from = partner, values_from = export_value, values_fill = 0) %>%
    left_join(carded_countries, by = "flag_iso3") %>%
    filter(year < first_treat | first_treat == 0) %>%
    group_by(flag_iso3) %>%
    summarise(
      eu_share = sum(EU, na.rm = TRUE) / sum(World, na.rm = TRUE),
      total_exports = mean(World, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(high_eu_dep = as.integer(eu_share > median(eu_share, na.rm = TRUE)))

  panel_annual <- panel_annual %>%
    left_join(eu_dep, by = "flag_iso3")

  cat(sprintf("EU export dependence: %d countries\n", nrow(eu_dep)))
} else {
  cat("No Comtrade data — skipping EU dependence variable.\n")
  panel_annual$eu_share <- NA_real_
  panel_annual$high_eu_dep <- NA_integer_
}

# ---------------------------------------------------------------
# 4. Descriptive Statistics
# ---------------------------------------------------------------

cat("\n=== Descriptive Statistics ===\n")

# Treatment cohorts
cohorts <- panel_annual %>%
  filter(first_treat > 0) %>%
  distinct(flag_iso3, first_treat) %>%
  count(first_treat, name = "n_countries") %>%
  arrange(first_treat)

cat("Treatment cohorts:\n")
print(as.data.frame(cohorts))

# Summary stats
summary_stats <- panel_annual %>%
  summarise(
    n_obs = n(),
    n_countries = n_distinct(flag_iso3),
    n_treated = n_treated_countries,
    n_control = n_control_countries,
    mean_fishing_hours = mean(fishing_hours),
    sd_fishing_hours = sd(fishing_hours),
    mean_vessels = mean(n_vessels),
    mean_hours_per_vessel = mean(hours_per_vessel),
    years = paste(range(year), collapse = "-")
  )

cat("\nSample overview:\n")
print(as.data.frame(summary_stats))

# Pre-treatment SDs for SDE
pre_sd <- panel_annual %>%
  filter(treated == 0) %>%
  summarise(
    sd_ln_fishing = sd(ln_fishing_hours),
    sd_ln_hpv = sd(ln_hours_per_vessel),
    sd_ln_vessels = sd(ln_vessels),
    sd_fishing = sd(fishing_hours),
    sd_vessels = sd(n_vessels)
  )

cat("\nPre-treatment standard deviations:\n")
print(as.data.frame(pre_sd))

# ---------------------------------------------------------------
# 5. Save Clean Data
# ---------------------------------------------------------------

write_csv(panel_annual, "../data/panel_annual.csv")
write_csv(cohorts, "../data/cohorts.csv")

saveRDS(list(
  summary_stats = summary_stats,
  pre_sd = pre_sd,
  cohorts = cohorts,
  n_treated = n_treated_countries,
  n_control = n_control_countries
), "../data/descriptives.rds")

cat("\n=== Clean data saved ===\n")
