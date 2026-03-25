## 03_main_analysis.R — Main dose-response DiD estimation
## apep_0966: EU Menthol Cigarette Ban
## Revised: uses RELATIVE tobacco price (tobacco/overall HICP) to control
## for differential country-level inflation shocks

source("code/00_packages.R")
library(fixest)
library(dplyr)

panel <- readRDS("data/analysis_panel.rds")

cat("=== Main Analysis (Revised: Relative Price Design) ===\n")
cat(sprintf("Panel: %d rows, %d countries, %d months\n",
            nrow(panel), n_distinct(panel$country), n_distinct(panel$date)))

# ------------------------------------------------------------------
# 0. Construct relative tobacco price
# ------------------------------------------------------------------
# Key insight: high-menthol countries (CE Europe) had higher overall
# inflation post-2020 (energy crisis). Using tobacco/overall HICP
# differences out common price-level shocks within each country-month.

panel <- panel |>
  filter(!is.na(overall_index), overall_index > 0) |>
  mutate(
    rel_tobacco = tobacco_index / overall_index,
    ln_rel_tobacco = log(rel_tobacco)
  )

cat(sprintf("After filtering missing overall index: %d rows\n", nrow(panel)))

# ------------------------------------------------------------------
# 1. Main specification: Relative tobacco price
# ------------------------------------------------------------------
# (1) Relative price, no controls
m1 <- feols(
  ln_rel_tobacco ~ menthol_x_post | country + time_id,
  data = panel,
  cluster = ~country
)

# (2) Relative price + COVID stringency
m2 <- feols(
  ln_rel_tobacco ~ menthol_x_post + stringency | country + time_id,
  data = panel,
  cluster = ~country
)

# (3) Level specification for comparison: ln tobacco with overall HICP control
m3 <- feols(
  ln_tobacco ~ menthol_x_post + stringency + log(overall_index) | country + time_id,
  data = panel,
  cluster = ~country
)

# (4) Binary high/low menthol on relative price
m4 <- feols(
  ln_rel_tobacco ~ high_menthol_x_post | country + time_id,
  data = panel,
  cluster = ~country
)

# (5) Binary + stringency on relative price
m5 <- feols(
  ln_rel_tobacco ~ high_menthol_x_post + stringency | country + time_id,
  data = panel,
  cluster = ~country
)

cat("\n--- Model 1: Relative price, baseline ---\n")
summary(m1)
cat("\n--- Model 2: Relative price + stringency ---\n")
summary(m2)
cat("\n--- Model 3: Level + overall HICP control ---\n")
summary(m3)
cat("\n--- Model 4: Binary, relative price ---\n")
summary(m4)
cat("\n--- Model 5: Binary + stringency, relative price ---\n")
summary(m5)

# ------------------------------------------------------------------
# 2. Triple-difference: product category × country × time
# ------------------------------------------------------------------
# Stack tobacco and non-tobacco categories; estimate whether the
# menthol share interaction is specific to tobacco

hicp <- readRDS("data/hicp_monthly.rds")
menthol_shares <- readRDS("data/menthol_shares.rds")
oxcgrt <- readRDS("data/oxcgrt_stringency.rds")

panel_start <- as.Date("2017-01-01")
panel_end   <- as.Date("2024-12-01")
ban_date    <- as.Date("2020-05-01")

# Build stacked panel: tobacco + alcohol + food + clothing
stacked <- hicp |>
  filter(
    category %in% c("CP022", "CP021", "CP011", "CP031"),
    date >= panel_start, date <= panel_end, date != ban_date,
    !is.na(index)
  ) |>
  inner_join(menthol_shares |> select(country, menthol_share), by = "country") |>
  left_join(oxcgrt, by = c("country", "year", "month")) |>
  mutate(
    stringency = replace_na(stringency, 0),
    post = as.integer(date > ban_date),
    is_tobacco = as.integer(category == "CP022"),
    menthol_x_post = menthol_share * post,
    # Triple interaction: tobacco × menthol × post
    ddd = is_tobacco * menthol_share * post,
    ln_index = log(index),
    country_cat = paste0(country, "_", category),
    time_id = as.integer(factor(date))
  )

cat(sprintf("\nStacked panel: %d rows, %d country-category pairs\n",
            nrow(stacked), n_distinct(stacked$country_cat)))

# Triple-diff
m_ddd <- feols(
  ln_index ~ ddd + menthol_x_post + is_tobacco:post + stringency |
    country_cat + time_id,
  data = stacked,
  cluster = ~country
)

cat("\n--- Triple-Difference (Tobacco-specific menthol × post) ---\n")
summary(m_ddd)

# ------------------------------------------------------------------
# 3. Event study on relative tobacco price
# ------------------------------------------------------------------
panel <- panel |>
  mutate(
    rel_month_binned = case_when(
      rel_month <= -12 ~ -12L,
      rel_month >= 24  ~ 24L,
      TRUE             ~ as.integer(rel_month)
    )
  )

es_model <- feols(
  ln_rel_tobacco ~ i(rel_month_binned, menthol_share, ref = -1) + stringency |
    country + time_id,
  data = panel,
  cluster = ~country
)

cat("\n--- Event Study (Relative Price) ---\n")
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.frame(coeftable(es_model)) |>
  tibble::rownames_to_column("term") |>
  filter(grepl("rel_month_binned", term)) |>
  mutate(
    rel_month = as.integer(gsub(".*::([-0-9]+):.*", "\\1", term)),
    estimate = Estimate,
    se = `Std. Error`,
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  ) |>
  select(rel_month, estimate, se, ci_lo, ci_hi)

# Add reference period
es_coefs <- bind_rows(
  es_coefs,
  tibble(rel_month = -1L, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
) |>
  arrange(rel_month)

saveRDS(es_coefs, "data/event_study_coefs.rds")

# ------------------------------------------------------------------
# 4. Save model objects and diagnostics
# ------------------------------------------------------------------
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
             m_ddd = m_ddd, es = es_model),
        "data/main_models.rds")

# Diagnostics for validation
# Continuous treatment: ALL 28 countries are treated with varying intensity
# (menthol share > 0 for all). Use total countries as n_treated.
n_treated <- n_distinct(panel$country)

n_pre <- panel |>
  filter(post == 0) |>
  distinct(date) |>
  nrow()

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel)
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n=== Diagnostics ===\n"))
cat(sprintf("  n_treated (all countries, continuous treatment): %d\n", n_treated))
cat(sprintf("  n_pre (pre-ban months): %d\n", n_pre))
cat(sprintf("  n_obs (main panel): %d\n", nrow(panel)))
cat(sprintf("  n_obs (stacked DDD): %d\n", nrow(stacked)))

cat("\n=== Main analysis complete ===\n")
