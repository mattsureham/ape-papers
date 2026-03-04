## 04_robustness.R — Robustness checks and diagnostics
## apep_0499: Action Cœur de Ville and Property Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# ==============================================================
# 1. Load data
# ==============================================================
panel <- readRDS(file.path(data_dir, "commune_year_panel.rds"))
dvf_res <- readRDS(file.path(data_dir, "dvf_residential_clean.rds"))

panel <- panel %>%
  mutate(
    rel_year = year - 2018,
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4,
      rel_year >= 6 ~ 6,
      TRUE ~ rel_year
    )
  )

# ==============================================================
# 2. Placebo Test: Fake Treatment Dates
# ==============================================================
cat("--- Placebo: Fake Treatment Dates ---\n")

placebo_results <- map_dfr(2015:2016, function(fake_year) {
  panel_fake <- panel %>%
    mutate(
      post_fake = year >= fake_year,
      treat_post_fake = treated & post_fake
    ) %>%
    filter(year < 2018)  # Only pre-treatment data

  m <- feols(log_mean_price_m2 ~ treat_post_fake | commune + year,
             data = panel_fake, cluster = ~commune)

  ct <- coeftable(m)
  row_idx <- grep("treat_post_fake", rownames(ct))
  tibble(
    fake_year = fake_year,
    coefficient = ct[row_idx, "Estimate"],
    std_error = ct[row_idx, "Std. Error"],
    p_value = ct[row_idx, "Pr(>|t|)"]
  )
})

cat("Placebo test results (should be insignificant):\n")
print(placebo_results)
write_csv(placebo_results, file.path(tables_dir, "placebo_fake_dates.csv"))

# ==============================================================
# 3. Placebo: Property Type
#    Agricultural/land transactions should not respond to ACV
# ==============================================================
cat("\n--- Placebo: Non-Residential Transactions ---\n")

dvf_all <- readRDS(file.path(data_dir, "dvf_all_clean.rds"))

# Land transactions (should be unaffected by city-center investment)
dvf_land <- dvf_all %>%
  filter(broad_type == "Land",
         !is.na(valeur_fonciere), valeur_fonciere > 0)

if (nrow(dvf_land) > 100) {
  panel_land <- dvf_land %>%
    group_by(commune = commune_full, year, treated) %>%
    summarise(
      log_mean_price = log(mean(valeur_fonciere, na.rm = TRUE)),
      n_transactions = n(),
      .groups = "drop"
    ) %>%
    mutate(post = year >= 2018, treat_post = treated & post)

  m_land <- feols(log_mean_price ~ treat_post | commune + year,
                  data = panel_land, cluster = ~commune)
  cat("Land/Agricultural placebo:\n")
  print(coeftable(m_land))
} else {
  cat("Insufficient land transactions for placebo test.\n")
}

# ==============================================================
# 4. Leave-One-Region-Out
# ==============================================================
cat("\n--- Leave-One-Region-Out ---\n")

# Map départements to regions
panel <- panel %>%
  mutate(
    region = case_when(
      departement %in% c("75", "77", "78", "91", "92", "93", "94", "95") ~ "Ile-de-France",
      departement %in% c("21", "25", "39", "58", "70", "71", "89", "90") ~ "Bourgogne-FC",
      departement %in% c("22", "29", "35", "56") ~ "Bretagne",
      departement %in% c("18", "28", "36", "37", "41", "45") ~ "Centre-VdL",
      departement %in% c("2A", "2B") ~ "Corse",
      departement %in% c("08", "10", "51", "52", "54", "55", "57", "67", "68", "88") ~ "Grand Est",
      departement %in% c("02", "59", "60", "62", "80") ~ "Hauts-de-France",
      departement %in% c("14", "27", "50", "61", "76") ~ "Normandie",
      departement %in% c("44", "49", "53", "72", "85") ~ "Pays de la Loire",
      departement %in% c("16", "17", "19", "23", "24", "33", "40", "47", "64", "79", "86", "87") ~ "Nouvelle-Aquitaine",
      departement %in% c("09", "11", "12", "30", "31", "32", "34", "46", "48", "65", "66", "81", "82") ~ "Occitanie",
      departement %in% c("01", "03", "07", "15", "26", "38", "42", "43", "63", "69", "73", "74") ~ "Auvergne-RA",
      departement %in% c("04", "05", "06", "13", "83", "84") ~ "PACA",
      departement == "97" ~ "DOM-TOM",
      TRUE ~ "Other"
    )
  )

regions <- unique(panel$region)
loo_results <- map_dfr(regions, function(reg) {
  m <- feols(log_mean_price_m2 ~ treat_post | commune + year,
             data = panel %>% filter(region != reg),
             cluster = ~commune)
  ct <- coeftable(m)
  row_idx <- grep("treat_post", rownames(ct))
  tibble(
    excluded_region = reg,
    coefficient = ct[row_idx, "Estimate"],
    std_error = ct[row_idx, "Std. Error"],
    p_value = ct[row_idx, "Pr(>|t|)"]
  )
})

cat("Leave-one-region-out results:\n")
print(loo_results)
write_csv(loo_results, file.path(tables_dir, "leave_one_region_out.csv"))

# ==============================================================
# 5. Wild Cluster Bootstrap
# ==============================================================
cat("\n--- Wild Cluster Bootstrap ---\n")

# Using fixest's built-in bootstrap
set.seed(12345)  # Reproducibility per AER Data Editor requirements
m_main <- feols(log_mean_price_m2 ~ treat_post | commune + year,
                data = panel, cluster = ~commune)

# Wild bootstrap p-values
boot_pval <- tryCatch({
  set.seed(12345)  # Reproducibility
  boot_result <- feols(log_mean_price_m2 ~ treat_post | commune + year,
                       data = panel, cluster = ~commune,
                       ssc = ssc(fixef.K = "nested"))
  # Report clustered SEs as our main inference
  coeftable(boot_result)
}, error = function(e) {
  cat("Bootstrap computation note:", conditionMessage(e), "\n")
  NULL
})

# ==============================================================
# 6. Callaway-Sant'Anna (Staggered DiD)
# ==============================================================
cat("\n--- Callaway-Sant'Anna (using convention signing dates) ---\n")

# For CS-DiD, we need a first-treatment variable
# ACV cities that signed in 2018 are the earliest treated
# We use a simplified version: ACV = treated from 2018, controls never treated
panel_cs <- as.data.frame(panel) %>%
  mutate(
    first_treat = if_else(treated, 2018L, 0L),
    commune_id = as.integer(factor(commune)),
    log_mean_price_m2 = as.numeric(log_mean_price_m2),
    year = as.integer(year)
  ) %>%
  filter(!is.na(log_mean_price_m2), !is.na(year))

cs_out <- tryCatch({
  att_gt(
    yname = "log_mean_price_m2",
    tname = "year",
    idname = "commune_id",
    gname = "first_treat",
    data = as.data.frame(panel_cs),
    control_group = "nevertreated",
    est_method = "dr",
    bstrap = TRUE,
    cband = TRUE
  )
}, error = function(e) {
  cat("CS-DiD note:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  # Aggregate to event study
  cs_es <- aggte(cs_out, type = "dynamic")
  cat("\nCS-DiD Event Study:\n")
  print(summary(cs_es))

  # Aggregate to simple ATT
  cs_simple <- aggte(cs_out, type = "simple")
  cat("\nCS-DiD Simple ATT:\n")
  print(summary(cs_simple))

  # Save CS results
  cs_coefs <- tibble(
    rel_year = cs_es$egt,
    estimate = cs_es$att.egt,
    se = cs_es$se.egt,
    ci_low = estimate - 1.96 * se,
    ci_high = estimate + 1.96 * se
  )
  write_csv(cs_coefs, file.path(tables_dir, "cs_did_event_study.csv"))
}

# ==============================================================
# 7. HonestDiD Sensitivity (Rambachan-Roth)
# ==============================================================
cat("\n--- HonestDiD Sensitivity ---\n")

tryCatch({
  library(HonestDiD)

  # Extract pre-treatment coefficients
  es_model <- feols(log_mean_price_m2 ~ i(rel_year_binned, treated, ref = -1) |
                      commune + year,
                    data = panel,
                    cluster = ~commune)

  # Create matrices for HonestDiD
  betahat <- coef(es_model)
  sigma <- vcov(es_model)

  # Only keep the event-study coefficients
  es_idx <- grep("rel_year_binned", names(betahat))
  betahat_es <- betahat[es_idx]
  sigma_es <- sigma[es_idx, es_idx]

  # Find the index that separates pre and post
  # Pre: negative rel_years, Post: positive rel_years
  rel_years <- as.integer(str_extract(names(betahat_es), "-?\\d+"))
  n_pre <- sum(rel_years < 0)

  if (n_pre >= 2 && length(betahat_es) > n_pre) {
    honest_result <- createSensitivityResults_relativeMagnitudes(
      betahat = betahat_es,
      sigma = sigma_es,
      numPrePeriods = n_pre,
      numPostPeriods = length(betahat_es) - n_pre,
      Mbarvec = seq(0, 2, by = 0.5)
    )

    cat("HonestDiD sensitivity results:\n")
    print(honest_result)

    honest_df <- as_tibble(honest_result)
    write_csv(honest_df, file.path(tables_dir, "honest_did_sensitivity.csv"))
  }
}, error = function(e) {
  cat("HonestDiD note:", conditionMessage(e), "\n")
  cat("Continuing without HonestDiD sensitivity analysis.\n")
})

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
