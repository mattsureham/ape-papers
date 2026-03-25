## 04_robustness.R — Robustness checks (relative price design)
## apep_0966: EU Menthol Cigarette Ban

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")

# Reconstruct relative tobacco price
panel <- panel |>
  filter(!is.na(overall_index), overall_index > 0) |>
  mutate(
    rel_tobacco = tobacco_index / overall_index,
    ln_rel_tobacco = log(rel_tobacco)
  )

cat("=== Robustness Checks (Relative Price Design) ===\n")

# ------------------------------------------------------------------
# 1. Placebo: menthol share × post on relative NON-tobacco prices
# ------------------------------------------------------------------
# Alcohol/overall, food/overall, clothing/overall should show no effect

panel <- panel |>
  mutate(
    rel_alcohol  = alcohol_index / overall_index,
    rel_food     = food_index / overall_index,
    rel_clothing = clothing_index / overall_index,
    ln_rel_alcohol  = log(rel_alcohol),
    ln_rel_food     = log(rel_food),
    ln_rel_clothing = log(rel_clothing)
  )

p_alcohol <- feols(
  ln_rel_alcohol ~ menthol_x_post + stringency | country + time_id,
  data = panel |> filter(!is.na(ln_rel_alcohol), is.finite(ln_rel_alcohol)),
  cluster = ~country
)

p_food <- feols(
  ln_rel_food ~ menthol_x_post + stringency | country + time_id,
  data = panel |> filter(!is.na(ln_rel_food), is.finite(ln_rel_food)),
  cluster = ~country
)

p_clothing <- feols(
  ln_rel_clothing ~ menthol_x_post + stringency | country + time_id,
  data = panel |> filter(!is.na(ln_rel_clothing), is.finite(ln_rel_clothing)),
  cluster = ~country
)

cat("\n--- Relative Placebo: Alcohol/Overall ---\n")
summary(p_alcohol)
cat("\n--- Relative Placebo: Food/Overall ---\n")
summary(p_food)
cat("\n--- Relative Placebo: Clothing/Overall ---\n")
summary(p_clothing)

# ------------------------------------------------------------------
# 2. Leave-one-out
# ------------------------------------------------------------------
countries <- unique(panel$country)
loo_results <- tibble(
  dropped = character(),
  estimate = numeric(),
  se = numeric()
)

for (cty in countries) {
  m_loo <- feols(
    ln_rel_tobacco ~ menthol_x_post + stringency | country + time_id,
    data = panel |> filter(country != cty),
    cluster = ~country
  )
  loo_results <- bind_rows(loo_results, tibble(
    dropped = cty,
    estimate = coef(m_loo)["menthol_x_post"],
    se = se(m_loo)["menthol_x_post"]
  ))
}

cat("\n--- Leave-One-Out ---\n")
main_models <- readRDS("data/main_models.rds")
cat(sprintf("  Full sample estimate: %.4f\n",
            coef(main_models$m2)["menthol_x_post"]))
cat(sprintf("  LOO range: [%.4f, %.4f]\n",
            min(loo_results$estimate), max(loo_results$estimate)))
cat(sprintf("  Dropping Poland: %.4f\n",
            loo_results |> filter(dropped == "PL") |> pull(estimate)))

# ------------------------------------------------------------------
# 3. Wild cluster bootstrap
# ------------------------------------------------------------------
cat("\n--- Wild Cluster Bootstrap ---\n")

boot_result <- tryCatch({
  fwildclusterboot::boottest(
    main_models$m2,
    param = "menthol_x_post",
    clustid = ~country,
    B = 9999,
    type = "rademacher"
  )
}, error = function(e) {
  cat("WCB error: ", e$message, "\n")
  # Try with webb weights instead
  tryCatch({
    fwildclusterboot::boottest(
      main_models$m2,
      param = "menthol_x_post",
      clustid = ~country,
      B = 9999,
      type = "webb"
    )
  }, error = function(e2) {
    cat("WCB (webb) error: ", e2$message, "\n")
    NULL
  })
})

if (!is.null(boot_result)) {
  cat("  WCB p-value: ", boot_result$p_val, "\n")
  cat("  WCB 95% CI: [", boot_result$conf_int[1], ", ", boot_result$conf_int[2], "]\n")
}

# ------------------------------------------------------------------
# 4. Alternative sample windows
# ------------------------------------------------------------------
# (a) Shorter pre-period: Jan 2019 - Dec 2024
panel_short_pre <- panel |> filter(date >= as.Date("2019-01-01"))
m_short_pre <- feols(
  ln_rel_tobacco ~ menthol_x_post + stringency | country + time_id,
  data = panel_short_pre,
  cluster = ~country
)

# (b) Exclude COVID peak: drop Mar 2020 - Sep 2020
panel_no_covid <- panel |>
  filter(!(date >= as.Date("2020-03-01") & date <= as.Date("2020-09-01")))
m_no_covid <- feols(
  ln_rel_tobacco ~ menthol_x_post + stringency | country + time_id,
  data = panel_no_covid,
  cluster = ~country
)

# (c) Post-COVID only: Jan 2021 - Dec 2024
panel_post_covid <- panel |> filter(date >= as.Date("2021-01-01"))
m_post_covid <- feols(
  ln_rel_tobacco ~ menthol_x_post + stringency | country + time_id,
  data = panel_post_covid,
  cluster = ~country
)

cat("\n--- Alternative Windows ---\n")
cat(sprintf("  Short pre-period: %.4f (%.4f)\n",
            coef(m_short_pre)["menthol_x_post"],
            se(m_short_pre)["menthol_x_post"]))
cat(sprintf("  Excl. COVID peak: %.4f (%.4f)\n",
            coef(m_no_covid)["menthol_x_post"],
            se(m_no_covid)["menthol_x_post"]))
cat(sprintf("  Post-COVID only:  %.4f (%.4f)\n",
            coef(m_post_covid)["menthol_x_post"],
            se(m_post_covid)["menthol_x_post"]))

# ------------------------------------------------------------------
# 5. Save robustness results
# ------------------------------------------------------------------
robustness <- list(
  placebos = list(alcohol = p_alcohol, food = p_food, clothing = p_clothing),
  loo = loo_results,
  boot = boot_result,
  alt_windows = list(short_pre = m_short_pre, no_covid = m_no_covid,
                     post_covid = m_post_covid)
)

saveRDS(robustness, "data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
