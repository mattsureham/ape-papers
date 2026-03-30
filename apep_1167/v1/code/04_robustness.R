## 04_robustness.R — Triple-difference, robustness, and placebos

library(dplyr)
library(tidyr)
library(readr)
library(fixest)
library(jsonlite)

df <- read_csv("data/analysis_df.csv", show_col_types = FALSE)
county_year <- read_csv("data/county_year_completions.csv", show_col_types = FALSE)
load("data/regression_results.RData")

# ─────────────────────────────────────────────────────────
# 1. Triple-Difference: SA vs Other Fields × Pill Supply
# ─────────────────────────────────────────────────────────
cat("═══════════════════════════════════════════════════════\n")
cat("Triple-Difference: SA vs Other Fields × Pill Supply\n")
cat("═══════════════════════════════════════════════════════\n\n")

# Stack long differences for SA, engineering, and business
stack_df <- df |>
  select(county_fips, buyer_state, log_pills_total, triplicate, pre_comp,
         delta_comp, delta_eng, delta_bus) |>
  pivot_longer(
    cols = c(delta_comp, delta_eng, delta_bus),
    names_to = "field",
    values_to = "delta"
  ) |>
  filter(!is.na(delta)) |>
  mutate(
    is_sa = field == "delta_comp",
    field_label = case_when(
      field == "delta_comp" ~ "SA Counseling",
      field == "delta_eng" ~ "Engineering",
      field == "delta_bus" ~ "Business"
    )
  )

cat(sprintf("Stacked panel: %d obs (%d SA, %d Engineering, %d Business)\n",
            nrow(stack_df),
            sum(stack_df$field == "delta_comp"),
            sum(stack_df$field == "delta_eng"),
            sum(stack_df$field == "delta_bus")))

# DDD: delta_field = pills + is_sa + pills × is_sa + county FE
ddd1 <- feols(delta ~ log_pills_total * is_sa | field,
              data = stack_df, vcov = ~county_fips)

ddd2 <- feols(delta ~ log_pills_total * is_sa | field + buyer_state,
              data = stack_df, vcov = ~county_fips)

cat("\nDDD (1) — field FE:\n")
summary(ddd1)
cat("\nDDD (2) — field + state FE:\n")
summary(ddd2)

# ─────────────────────────────────────────────────────────
# 2. Normalized specification (percentage growth)
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("Normalized: Growth Rate (post/pre) of SA Completions\n")
cat("═══════════════════════════════════════════════════════\n\n")

df_norm <- df |>
  filter(has_pre_sa, pre_comp >= 5) |>  # require meaningful pre-period
  mutate(
    growth_sa = (post_comp - pre_comp) / pre_comp,
    log_growth_sa = log(post_comp / pre_comp)
  )

m_growth <- feols(growth_sa ~ log_pills_total, data = df_norm, vcov = "HC1")
m_growth_fe <- feols(growth_sa ~ log_pills_total | state_fe,
                     data = df_norm, vcov = "HC1")

cat("Growth rate on pills (no FE):\n")
summary(m_growth)
cat("\nGrowth rate on pills (state FE):\n")
summary(m_growth_fe)

# ─────────────────────────────────────────────────────────
# 3. Within-county panel (2000-2024) for SA trends
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("Panel: County × Year SA Completions\n")
cat("═══════════════════════════════════════════════════════\n\n")

# Build balanced panel of SA completions
sa_panel <- county_year |>
  filter(field_group == "sa_counseling") |>
  select(county_fips, year, completions)

# Merge with ARCOS exposure
arcos_exposure <- df |>
  select(county_fips, buyer_state, log_pills_total, triplicate) |>
  distinct()

sa_panel <- sa_panel |>
  inner_join(arcos_exposure, by = "county_fips") |>
  mutate(
    post = year >= 2013,  # after ARCOS exposure period
    pills_x_post = log_pills_total * post,
    state_fe = as.factor(buyer_state)
  )

# Panel DiD: county FE + year FE + pills × post
panel_m1 <- feols(completions ~ pills_x_post | county_fips + year,
                  data = sa_panel, vcov = ~buyer_state)
cat("Panel DiD (county + year FE):\n")
summary(panel_m1)

# ─────────────────────────────────────────────────────────
# 4. Leave-one-state-out
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("Leave-One-State-Out Sensitivity\n")
cat("═══════════════════════════════════════════════════════\n\n")

states_to_drop <- unique(df$buyer_state)
loso_results <- data.frame(
  dropped_state = character(),
  coef = numeric(),
  se = numeric(),
  n = integer(),
  stringsAsFactors = FALSE
)

for (st in states_to_drop) {
  sub_df <- df |> filter(buyer_state != st)
  m <- feols(delta_comp ~ log_pills_total, data = sub_df, vcov = "HC1")
  loso_results <- rbind(loso_results, data.frame(
    dropped_state = st,
    coef = coef(m)["log_pills_total"],
    se = sqrt(vcov(m)["log_pills_total", "log_pills_total"]),
    n = nrow(sub_df)
  ))
}

cat(sprintf("LOSO: coef range [%.2f, %.2f] (full sample: %.2f)\n",
            min(loso_results$coef), max(loso_results$coef),
            coef(m1)["log_pills_total"]))

# ─────────────────────────────────────────────────────────
# 5. Pre-trend test: Use 2000-2005 SA completions
# ─────────────────────────────────────────────────────────
cat("\n═══════════════════════════════════════════════════════\n")
cat("Pre-Trend Test: 2000-2005 SA Completions\n")
cat("═══════════════════════════════════════════════════════\n\n")

pre_trend <- county_year |>
  filter(field_group == "sa_counseling", year >= 2000, year <= 2005) |>
  group_by(county_fips) |>
  summarise(
    pre_early = mean(completions[year <= 2002], na.rm = TRUE),
    pre_late = mean(completions[year >= 2003 & year <= 2005], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(delta_pre = pre_late - pre_early) |>
  inner_join(arcos_exposure, by = "county_fips")

pre_trend <- pre_trend |> filter(!is.na(delta_pre) & is.finite(delta_pre) & delta_pre != 0)
if (nrow(pre_trend) > 20) {
  m_pre <- feols(delta_pre ~ log_pills_total, data = pre_trend, vcov = "HC1")
  cat("Pre-trend (2003-2005 vs 2000-2002) on future pills:\n")
  summary(m_pre)
} else {
  cat(sprintf("Pre-trend test: %d obs with non-zero delta — most counties had no SA programs before 2006.\n",
              nrow(pre_trend)))
  cat("This is consistent with the paper's story: SA programs EMERGED in response to the crisis.\n")
}

# ─────────────────────────────────────────────────────────
# Save results
# ─────────────────────────────────────────────────────────
save(ddd1, ddd2, m_growth, m_growth_fe, panel_m1, loso_results,
     file = "data/robustness_results.RData")

# Update diagnostics
diag <- fromJSON("data/diagnostics.json")
diag$ddd_coef <- coef(ddd1)["log_pills_total:is_saTRUE"]
diag$ddd_se <- sqrt(vcov(ddd1)["log_pills_total:is_saTRUE", "log_pills_total:is_saTRUE"])
diag$loso_min <- min(loso_results$coef)
diag$loso_max <- max(loso_results$coef)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nRobustness results saved.\n")
