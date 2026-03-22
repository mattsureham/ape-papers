## 04_robustness.R — Robustness checks and triple-difference
source("00_packages.R")
data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel_final.rds"))
panel$placebo_treat <- panel$food_density * panel$post

# ============================================================================
# 1. Controlled specification: gambling density + food density control
# ============================================================================
cat("=== Controlled Specification ===\n")

outcomes <- c("total_rate", "theft_rate", "violence_rate", "robbery_rate",
              "damage_rate", "shoplifting_rate", "drugs_rate")
labels <- c("Total", "Theft", "Violence", "Robbery", "CrimDamage",
            "Shoplifting", "Drugs")

controlled_results <- list()
for (i in seq_along(outcomes)) {
  fml <- as.formula(paste0(outcomes[i],
    " ~ treat_x_post + placebo_treat | force_id + time_id"))
  est <- feols(fml, data = panel, cluster = ~force_id)
  controlled_results[[outcomes[i]]] <- est
  cat(sprintf("%-12s  gambling = %7.3f (p=%.3f)  food = %7.3f (p=%.3f)\n",
              labels[i], coef(est)[1], pvalue(est)[1], coef(est)[2], pvalue(est)[2]))
}
saveRDS(controlled_results, file.path(data_dir, "controlled_results.rds"))

# ============================================================================
# 2. Triple-difference: acquisitive vs non-acquisitive crime
# ============================================================================
cat("\n=== Triple-Difference ===\n")

# Panel A: Theft vs Violence
long_tv <- panel %>%
  select(force, force_id, time_id, yearq, post, betting_density,
         theft_rate, violence_rate) %>%
  pivot_longer(cols = c(theft_rate, violence_rate),
               names_to = "crime_type", values_to = "rate") %>%
  mutate(acquisitive = as.integer(crime_type == "theft_rate"),
         triple = acquisitive * betting_density * post,
         bet_post = betting_density * post)

est_tv <- feols(rate ~ triple + bet_post |
                  force_id^crime_type + time_id^crime_type,
                data = long_tv, cluster = ~force_id)

# Panel B: Shoplifting vs Drug offences (theory-matched placebo)
long_sd <- panel %>%
  select(force, force_id, time_id, yearq, post, betting_density,
         shoplifting_rate, drugs_rate) %>%
  pivot_longer(cols = c(shoplifting_rate, drugs_rate),
               names_to = "crime_type", values_to = "rate") %>%
  mutate(acquisitive = as.integer(crime_type == "shoplifting_rate"),
         triple = acquisitive * betting_density * post,
         bet_post = betting_density * post)

est_sd <- feols(rate ~ triple + bet_post |
                  force_id^crime_type + time_id^crime_type,
                data = long_sd, cluster = ~force_id)

triple_results <- list(theft_vs_violence = est_tv, shoplifting_vs_drugs = est_sd)
saveRDS(triple_results, file.path(data_dir, "triple_results.rds"))

cat("Theft vs Violence:     triple = ", round(coef(est_tv)["triple"], 3),
    " (p=", round(pvalue(est_tv)["triple"], 4), ")\n")
cat("Shoplifting vs Drugs:  triple = ", round(coef(est_sd)["triple"], 3),
    " (p=", round(pvalue(est_sd)["triple"], 4), ")\n")

# ============================================================================
# 3. Pre-COVID window (Apr 2019 - Feb 2020)
# ============================================================================
cat("\n=== Pre-COVID Window (Controlled) ===\n")

panel_precovid <- panel %>% filter(yearq < 2020.25)

precovid_results <- list()
for (i in seq_along(outcomes)) {
  fml <- as.formula(paste0(outcomes[i],
    " ~ treat_x_post + placebo_treat | force_id + time_id"))
  est <- feols(fml, data = panel_precovid, cluster = ~force_id)
  precovid_results[[outcomes[i]]] <- est
  cat(sprintf("Pre-COVID %-10s  gambling = %7.3f (p=%.3f)\n",
              labels[i], coef(est)[1], pvalue(est)[1]))
}
saveRDS(precovid_results, file.path(data_dir, "precovid_results.rds"))

# ============================================================================
# 4. Excluding COVID quarters
# ============================================================================
cat("\n=== Excluding COVID Quarters (Controlled) ===\n")

panel_nocovid <- panel %>% filter(covid == 0)

nocovid_results <- list()
for (i in seq_along(outcomes)) {
  fml <- as.formula(paste0(outcomes[i],
    " ~ treat_x_post + placebo_treat | force_id + time_id"))
  est <- feols(fml, data = panel_nocovid, cluster = ~force_id)
  nocovid_results[[outcomes[i]]] <- est
  cat(sprintf("NoCOVID %-12s  gambling = %7.3f (p=%.3f)\n",
              labels[i], coef(est)[1], pvalue(est)[1]))
}
saveRDS(nocovid_results, file.path(data_dir, "nocovid_results.rds"))

# ============================================================================
# 5. Placebo test: food density with NO gambling control
# ============================================================================
cat("\n=== Placebo: Food Density Only ===\n")

placebo_results <- list()
for (i in seq_along(outcomes)) {
  fml <- as.formula(paste0(outcomes[i], " ~ placebo_treat | force_id + time_id"))
  est <- feols(fml, data = panel, cluster = ~force_id)
  placebo_results[[outcomes[i]]] <- est
  cat(sprintf("Placebo %-12s  food = %7.3f (p=%.3f)\n",
              labels[i], coef(est)[1], pvalue(est)[1]))
}
saveRDS(placebo_results, file.path(data_dir, "placebo_results.rds"))

# ============================================================================
# 6. Pre-trend event study (controlled)
# ============================================================================
cat("\n=== Event Study (Controlled) ===\n")

panel <- panel %>%
  mutate(rel_time_bin = case_when(
    rel_time <= -8 ~ -8L,
    rel_time >= 12 ~ 12L,
    TRUE ~ as.integer(rel_time)
  ))

es_controlled <- list()
for (outcome in c("theft_rate", "violence_rate")) {
  fml <- as.formula(paste0(outcome,
    " ~ i(rel_time_bin, betting_density, ref = -1) + placebo_treat | force_id + time_id"))
  est <- feols(fml, data = panel, cluster = ~force_id)
  es_controlled[[outcome]] <- est
}
saveRDS(es_controlled, file.path(data_dir, "es_controlled.rds"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
