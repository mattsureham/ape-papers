## 02_clean_data.R — Construct analysis panel
## apep_0966: EU Menthol Cigarette Ban

source("code/00_packages.R")

hicp <- readRDS("data/hicp_monthly.rds")
menthol_shares <- readRDS("data/menthol_shares.rds")
oxcgrt <- readRDS("data/oxcgrt_stringency.rds")

# ------------------------------------------------------------------
# 1. Restrict sample window: Jan 2017 — Dec 2024
# ------------------------------------------------------------------
# 40 months pre (Jan 2017 - Apr 2020), 55 months post (Jun 2020 - Dec 2024)
# May 2020 treated as transition month (excluded)

panel_start <- as.Date("2017-01-01")
panel_end   <- as.Date("2024-12-01")
ban_date    <- as.Date("2020-05-01")  # May 2020 = transition

tobacco <- hicp |>
  filter(
    category == "CP022",
    date >= panel_start,
    date <= panel_end,
    date != ban_date  # Exclude transition month
  ) |>
  select(country, date, year, month, tobacco_index = index)

cat(sprintf("Tobacco panel: %d rows\n", nrow(tobacco)))

# ------------------------------------------------------------------
# 2. Merge menthol shares
# ------------------------------------------------------------------
panel <- tobacco |>
  inner_join(menthol_shares |> select(country, menthol_share), by = "country")

lost_countries <- setdiff(unique(tobacco$country), unique(panel$country))
if (length(lost_countries) > 0) {
  cat(sprintf("Countries dropped (no menthol share): %s\n",
              paste(lost_countries, collapse = ", ")))
}

cat(sprintf("Panel after menthol merge: %d rows, %d countries\n",
            nrow(panel), n_distinct(panel$country)))

# ------------------------------------------------------------------
# 3. Merge COVID stringency (zero before 2020)
# ------------------------------------------------------------------
panel <- panel |>
  left_join(oxcgrt, by = c("country", "year", "month")) |>
  mutate(stringency = replace_na(stringency, 0))

# ------------------------------------------------------------------
# 4. Construct variables
# ------------------------------------------------------------------
panel <- panel |>
  mutate(
    post = as.integer(date > ban_date),
    # Relative time (months since ban, May 2020 = 0)
    rel_month = as.integer(round(difftime(date, ban_date, units = "days") / 30.44)),
    # Interaction term (continuous treatment)
    menthol_x_post = menthol_share * post,
    # Log tobacco index
    ln_tobacco = log(tobacco_index),
    # Country numeric ID for FE
    country_id = as.integer(factor(country)),
    # Time numeric ID for FE
    time_id = as.integer(factor(date))
  )

# ------------------------------------------------------------------
# 5. Add placebo outcomes (non-tobacco HICP categories)
# ------------------------------------------------------------------
placebo_cats <- c("CP021", "CP011", "CP031", "CP00")
placebo_names <- c("alcohol_index", "food_index", "clothing_index", "overall_index")

for (i in seq_along(placebo_cats)) {
  placebo_data <- hicp |>
    filter(
      category == placebo_cats[i],
      date >= panel_start,
      date <= panel_end,
      date != ban_date
    ) |>
    select(country, date, !!placebo_names[i] := index)

  panel <- panel |>
    left_join(placebo_data, by = c("country", "date"))
}

# ------------------------------------------------------------------
# 6. Binary high/low menthol indicator (for robustness)
# ------------------------------------------------------------------
median_share <- median(menthol_shares$menthol_share)
panel <- panel |>
  mutate(
    high_menthol = as.integer(menthol_share > median_share),
    high_menthol_x_post = high_menthol * post
  )

cat(sprintf("Final panel: %d rows, %d countries, %d months\n",
            nrow(panel),
            n_distinct(panel$country),
            n_distinct(panel$date)))
cat(sprintf("  Pre-ban obs: %d\n", sum(panel$post == 0)))
cat(sprintf("  Post-ban obs: %d\n", sum(panel$post == 1)))
cat(sprintf("  Median menthol share: %.1f%%\n", median_share * 100))

# ------------------------------------------------------------------
# 7. Summary statistics
# ------------------------------------------------------------------
sumstats <- panel |>
  summarise(
    N = n(),
    n_countries = n_distinct(country),
    n_months = n_distinct(date),
    tobacco_mean = mean(tobacco_index, na.rm = TRUE),
    tobacco_sd = sd(tobacco_index, na.rm = TRUE),
    tobacco_min = min(tobacco_index, na.rm = TRUE),
    tobacco_max = max(tobacco_index, na.rm = TRUE),
    menthol_mean = mean(menthol_share),
    menthol_sd = sd(menthol_share),
    stringency_mean = mean(stringency, na.rm = TRUE),
    stringency_sd = sd(stringency, na.rm = TRUE)
  )

cat("\n=== Summary Statistics ===\n")
print(as.data.frame(sumstats))

# ------------------------------------------------------------------
# 8. Save
# ------------------------------------------------------------------
saveRDS(panel, "data/analysis_panel.rds")
saveRDS(sumstats, "data/summary_stats.rds")

cat("\n=== Clean data complete ===\n")
