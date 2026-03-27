# =============================================================================
# 02_clean_data.R — Construct analysis-ready dataset
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/qwi_panel.rds")
everify_states <- readRDS("../data/everify_states.rds")

cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Counties:", n_distinct(panel$county_fips), "\n")

# --- Drop cells with Emp = 0 (undefined rates) ---
panel <- panel |> filter(Emp > 0)
cat("After dropping Emp=0:", nrow(panel), "rows\n")

# --- Winsorize flow rates at 1st/99th percentile ---
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- quantile(x, probs, na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}

panel <- panel |>
  mutate(
    hire_rate_w = winsorize(hire_rate),
    sep_rate_w = winsorize(sep_rate),
    recall_rate_w = winsorize(recall_rate),
    stability_rate_w = winsorize(stability_rate)
  )

# --- Create relative time variable (quarters to mandate) ---
panel <- panel |>
  mutate(
    rel_quarter = if_else(
      !is.na(mandate_date),
      as.integer(round(as.numeric(difftime(quarter_date, mandate_date, units = "days")) / 91.25)),
      NA_integer_
    )
  )

# --- Create DDD interaction terms ---
panel <- panel |>
  mutate(
    # Key interaction: Hispanic × Construction × Post-mandate
    hisp_x_constr = as.integer(is_hispanic & is_construction),
    hisp_x_constr_x_post = as.integer(is_hispanic & is_construction & post_mandate),
    # Two-way interactions
    hisp_x_post = as.integer(is_hispanic & post_mandate),
    constr_x_post = as.integer(is_construction & post_mandate),
    hisp_x_constr_int = as.integer(is_hispanic) * as.integer(is_construction),
    # Cell ID for clustering and FEs
    county_quarter = paste0(county_fips, "_", year, "Q", quarter),
    state_id = state_fips,
    # Numeric quarter for FE
    yq = year + (quarter - 1) / 4
  )

# --- Summary statistics table ---
cat("\n--- Means by group (pre-treatment: 2004-2007) ---\n")
pre_summary <- panel |>
  filter(year <= 2007) |>
  group_by(is_hispanic, is_construction) |>
  summarise(
    n_obs = n(),
    n_counties = n_distinct(county_fips),
    mean_emp = round(mean(Emp)),
    mean_hire_rate = round(mean(hire_rate_w, na.rm = TRUE), 3),
    mean_sep_rate = round(mean(sep_rate_w, na.rm = TRUE), 3),
    mean_stability = round(mean(stability_rate_w, na.rm = TRUE), 3),
    mean_earn_newhire = round(mean(earn_new_hire, na.rm = TRUE)),
    .groups = "drop"
  )
print(pre_summary)

# --- Check pre-treatment parallel trends (visual) ---
cat("\n--- Pre-trend check: hire rate by group (treated vs control) ---\n")
trend_data <- panel |>
  filter(is_construction & year <= 2007) |>
  group_by(treated_state, is_hispanic, year, quarter) |>
  summarise(
    mean_hire_rate = mean(hire_rate_w, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate_w, na.rm = TRUE),
    .groups = "drop"
  )

# Show Hispanic construction trends
hisp_trends <- trend_data |>
  filter(is_hispanic) |>
  group_by(treated_state) |>
  summarise(
    mean_hr = round(mean(mean_hire_rate), 3),
    sd_hr = round(sd(mean_hire_rate), 3),
    .groups = "drop"
  )
cat("Hispanic construction hire rate (pre-2008):\n")
print(hisp_trends)

# --- Save cleaned panel ---
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nCleaned panel saved:", nrow(panel), "rows\n")
cat("Done.\n")
