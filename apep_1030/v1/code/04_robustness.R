## 04_robustness.R — Robustness checks
## apep_1030: EU Deposit Return Schemes and Packaging Waste Recycling

source("00_packages.R")

df       <- readRDS("../data/analysis_panel.rds")
ddd_data <- readRDS("../data/ddd_data.rds")

# ---------------------------------------------------------------
# 1. Leave-one-out: Drop Germany (largest early adopter)
# ---------------------------------------------------------------
cat("=== Leave-one-out: Drop Germany ===\n")

ddd_no_de <- ddd_data %>%
  filter(geo != "DE") %>%
  feols(
    recycle_rate ~ drs_adopted:targeted_num |
      geo^year + material^year + geo^material,
    data = .,
    cluster = ~geo
  )
print(summary(ddd_no_de))
saveRDS(ddd_no_de, "../data/ddd_no_de.rds")

# ---------------------------------------------------------------
# 2. Leave-one-out: Each treated cohort
# ---------------------------------------------------------------
cat("\n=== Leave-one-out: Each treated cohort ===\n")

treated_geos <- ddd_data %>%
  filter(drs_adopted == 1) %>%
  distinct(geo) %>%
  pull(geo)

loo_results <- map_dfr(treated_geos, function(g) {
  fit <- ddd_data %>%
    filter(geo != g) %>%
    feols(
      recycle_rate ~ drs_adopted:targeted_num |
        geo^year + material^year + geo^material,
      data = .,
      cluster = ~geo
    )
  tibble(
    dropped = g,
    coef = coef(fit)["drs_adopted:targeted_num"],
    se = se(fit)["drs_adopted:targeted_num"]
  )
})

cat("  Leave-one-out:\n")
print(loo_results)
saveRDS(loo_results, "../data/loo_results.rds")

# ---------------------------------------------------------------
# 3. Placebo: Glass as partially targeted
# ---------------------------------------------------------------
cat("\n=== Placebo: Glass vs Paper/Wood ===\n")

placebo_data <- df %>%
  filter(material %in% c("Glass", "Paper", "Wood")) %>%
  filter(!is.na(first_treat), !is.na(recycle_rate)) %>%
  mutate(is_glass = as.numeric(material == "Glass"))

placebo_fit <- feols(
  recycle_rate ~ drs_adopted:is_glass |
    geo^year + material^year + geo^material,
  data = placebo_data,
  cluster = ~geo
)
print(summary(placebo_fit))
saveRDS(placebo_fit, "../data/placebo_glass.rds")

# ---------------------------------------------------------------
# 4. Alternative control: Include glass in non-targeted
# ---------------------------------------------------------------
cat("\n=== DDD with glass as control ===\n")

ddd_alt <- df %>%
  filter(material %in% c("Plastic", "Metal", "Glass", "Paper", "Wood")) %>%
  filter(!is.na(first_treat), !is.na(recycle_rate)) %>%
  mutate(targeted_alt = as.numeric(material %in% c("Plastic", "Metal"))) %>%
  feols(
    recycle_rate ~ drs_adopted:targeted_alt |
      geo^year + material^year + geo^material,
    data = .,
    cluster = ~geo
  )
print(summary(ddd_alt))
saveRDS(ddd_alt, "../data/ddd_alt_glass.rds")

# ---------------------------------------------------------------
# 5. Dose-response: Deposit amount
# ---------------------------------------------------------------
cat("\n=== Dose-response: Deposit amount ===\n")

drs_dates <- readRDS("../data/drs_dates.rds")

dose_data <- df %>%
  filter(material == "Total", !is.na(first_treat), !is.na(recycle_rate)) %>%
  select(-any_of("deposit_eur")) %>%
  left_join(drs_dates %>% select(geo, deposit_eur), by = "geo") %>%
  mutate(
    deposit_eur = replace_na(deposit_eur, 0),
    deposit_active = ifelse(drs_adopted == 1, deposit_eur, 0)
  )

dose_fit <- feols(
  recycle_rate ~ deposit_active | geo + year,
  data = dose_data,
  cluster = ~geo
)
print(summary(dose_fit))
saveRDS(dose_fit, "../data/dose_fit.rds")

# ---------------------------------------------------------------
# 6. Pre-trend test from CS
# ---------------------------------------------------------------
cat("\n=== Pre-trend test ===\n")

cs_es <- readRDS("../data/cs_es.rds")
pre_ests <- data.frame(
  etime = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
) %>%
  filter(etime < 0) %>%
  mutate(t_stat = att / se, sig = abs(t_stat) > 1.96)

cat("  Pre-treatment coefficients:\n")
print(pre_ests)
cat(sprintf("  Significant pre-trends: %d of %d\n", sum(pre_ests$sig, na.rm = TRUE), nrow(pre_ests)))

saveRDS(pre_ests, "../data/pre_trends.rds")

# ---------------------------------------------------------------
# 7. Update diagnostics with DDD-based counts
# ---------------------------------------------------------------
cat("\n=== Updating diagnostics ===\n")

# Treated units = country×material pairs with DRS at some point
n_treated_pairs <- ddd_data %>%
  filter(drs_adopted == 1) %>%
  distinct(geo, material) %>%
  nrow()

# Pre-periods: median treated country's pre-period count
n_pre_median <- ddd_data %>%
  filter(first_treat > 0) %>%
  group_by(geo) %>%
  summarise(n_pre = sum(year < first_treat) / n_distinct(material), .groups = "drop") %>%
  pull(n_pre) %>%
  median()

n_obs <- nrow(ddd_data)

jsonlite::write_json(
  list(n_treated = n_treated_pairs, n_pre = as.integer(n_pre_median), n_obs = n_obs),
  "../data/diagnostics.json", auto_unbox = TRUE
)
cat(sprintf("  n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated_pairs, as.integer(n_pre_median), n_obs))

cat("\n=== Robustness checks complete ===\n")
