## ============================================================================
## 02_clean_data.R — Construct analysis variables
## ============================================================================

paper_dir <- here::here()
if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
setwd(here::here())
source("code/00_packages.R")

panel <- readRDS("data/state_crime_panel.rds")
cat("Loaded panel:", nrow(panel), "obs,", n_distinct(panel$state), "states\n")

## ---------------------------------------------------------------------------
## 0. Deduplicate: Disaster Center pages have two tables (counts + rates)
## ---------------------------------------------------------------------------
panel <- panel %>%
  group_by(state, year) %>%
  slice(1) %>%
  ungroup()
cat("After dedup:", nrow(panel), "obs,", n_distinct(panel$state), "states\n")

## ---------------------------------------------------------------------------
## 1. Winsorize extreme values
## ---------------------------------------------------------------------------

# Some state-years may have extreme rates due to population changes
# Winsorize at 1st and 99th percentiles
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  x[x < q[1]] <- q[1]
  x[x > q[2]] <- q[2]
  return(x)
}

rate_cols <- c("violent_rate", "murder_rate", "robbery_rate", "assault_rate",
               "property_rate", "burglary_rate", "larceny_rate", "motor_rate")

for (col in rate_cols) {
  panel[[col]] <- winsorize(panel[[col]])
  panel[[paste0("log_", col)]] <- log(pmax(panel[[col]], 0.01))
}

## ---------------------------------------------------------------------------
## 2. Construct relative time variable
## ---------------------------------------------------------------------------

panel <- panel %>%
  mutate(
    # Years since NIBRS adoption (negative = pre, positive = post)
    rel_time = ifelse(nibrs_year <= 2020, year - nibrs_year, NA_integer_),
    # Bin endpoints for event study
    rel_time_binned = case_when(
      is.na(rel_time) ~ NA_integer_,
      rel_time <= -6 ~ -6L,
      rel_time >= 6 ~ 6L,
      TRUE ~ as.integer(rel_time)
    )
  )

## ---------------------------------------------------------------------------
## 3. Summary statistics
## ---------------------------------------------------------------------------

cat("\n=== SUMMARY STATISTICS ===\n")

# Pre-treatment means
pre_means <- panel %>%
  filter(treated == 0 | (first_treat > 0 & year < nibrs_year)) %>%
  summarise(
    across(all_of(rate_cols), ~mean(.x, na.rm = TRUE), .names = "mean_{.col}"),
    across(all_of(rate_cols), ~sd(.x, na.rm = TRUE), .names = "sd_{.col}"),
    n_obs = n()
  )

cat("\nPre-treatment means (per 100K):\n")
cat("  Violent crime:", round(pre_means$mean_violent_rate, 1),
    "(SD:", round(pre_means$sd_violent_rate, 1), ")\n")
cat("  Murder:", round(pre_means$mean_murder_rate, 2),
    "(SD:", round(pre_means$sd_murder_rate, 2), ")\n")
cat("  Property crime:", round(pre_means$mean_property_rate, 1),
    "(SD:", round(pre_means$sd_property_rate, 1), ")\n")
cat("  Robbery:", round(pre_means$mean_robbery_rate, 1),
    "(SD:", round(pre_means$sd_robbery_rate, 1), ")\n")
cat("  Burglary:", round(pre_means$mean_burglary_rate, 1),
    "(SD:", round(pre_means$sd_burglary_rate, 1), ")\n")

# Treatment/control balance
cat("\n=== TREATMENT-CONTROL BALANCE ===\n")
balance <- panel %>%
  filter(year == 2005) %>%
  group_by(group = ifelse(first_treat > 0, "Treated (eventually)", "Never-treated")) %>%
  summarise(
    n_states = n(),
    mean_violent = mean(violent_rate, na.rm = TRUE),
    mean_murder = mean(murder_rate, na.rm = TRUE),
    mean_property = mean(property_rate, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    .groups = "drop"
  )
print(balance)

## ---------------------------------------------------------------------------
## 4. Save cleaned panel
## ---------------------------------------------------------------------------

saveRDS(panel, "data/analysis_panel.rds")
cat("\nSaved analysis panel:", nrow(panel), "observations\n")
