# 03_main_analysis.R — TWFE DiD + Permutation Inference for ASAN impact
# Paper: apep_1413
# Design: Single treated unit (Azerbaijan) with 11 donor countries
# Method: TWFE DiD for point estimates, permutation inference for p-values

source("00_packages.R")

data_dir <- "../data"

panel <- read.csv(file.path(data_dir, "analysis_panel.csv"), stringsAsFactors = FALSE)
es_panel <- read.csv(file.path(data_dir, "es_bribery_panel.csv"), stringsAsFactors = FALSE)

# ============================================================
# 1. Balance the panel
# ============================================================

cat("=== Balancing panel ===\n")

# Find common years where all countries have registration data
reg_years <- panel %>%
  filter(!is.na(new_registrations)) %>%
  group_by(year) %>%
  summarize(n_countries = n_distinct(iso3), .groups = "drop")

cat("Year coverage:\n")
print(reg_years)

# Azerbaijan has data from 2008; use 2008-2020 as common window
good_years <- 2008:2020
cat(sprintf("Using years: %s\n", paste(good_years, collapse = ", ")))

# Balance: keep only country-years where registration data exists
balanced <- panel %>%
  filter(year %in% good_years, !is.na(new_registrations))

# Restrict to countries with full coverage in this window
country_coverage <- balanced %>%
  group_by(iso3) %>%
  summarize(n_years = n(), .groups = "drop") %>%
  filter(n_years == length(good_years))

cat("Countries with full 2008-2020 coverage:\n")
print(country_coverage)

balanced <- balanced %>%
  filter(iso3 %in% country_coverage$iso3)

cat(sprintf("Balanced panel: %d obs, %d countries, %d years\n",
            nrow(balanced), n_distinct(balanced$iso3), n_distinct(balanced$year)))

# ============================================================
# 2. TWFE DiD — Business Registrations
# ============================================================

cat("\n=== TWFE DiD: Business Registrations ===\n")

# Reconstruct treatment variable on balanced panel
balanced$aze <- as.integer(balanced$iso3 == "AZE")
balanced$post2013 <- as.integer(balanced$year >= 2013)
balanced$aze_post <- balanced$aze * balanced$post2013

# Level specification
did_reg_level <- fixest::feols(
  new_registrations ~ aze_post | iso3 + year,
  data = balanced,
  cluster = ~iso3
)
cat("Registrations (level):\n")
print(summary(did_reg_level))

# Log specification
did_reg_log <- fixest::feols(
  log_reg ~ aze_post | iso3 + year,
  data = balanced,
  cluster = ~iso3
)
cat("\nRegistrations (log):\n")
print(summary(did_reg_log))

# Percentage interpretation
log_coef <- coef(did_reg_log)["aze_post"]
pct_effect <- (exp(log_coef) - 1) * 100
cat(sprintf("Implied percentage effect: %.1f%%\n", pct_effect))

# ============================================================
# 3. Permutation Inference (Placebo-in-Space)
# ============================================================

cat("\n=== Permutation Inference: Registrations ===\n")

# Assign "treatment" to each donor country in turn
donors <- setdiff(unique(balanced$iso3), "AZE")
true_att <- coef(did_reg_log)["aze_post"]

placebo_atts <- numeric(length(donors))
names(placebo_atts) <- donors

for (i in seq_along(donors)) {
  d <- donors[i]
  pdata <- balanced %>%
    mutate(
      placebo_treated = ifelse(iso3 == d, 1, 0),
      placebo_post = ifelse(year >= 2013, 1, 0),
      placebo_tp = placebo_treated * placebo_post
    ) %>%
    filter(iso3 != "AZE")  # Remove actual treated unit

  pfit <- fixest::feols(
    log_reg ~ placebo_tp | iso3 + year,
    data = pdata,
    cluster = ~iso3
  )
  placebo_atts[i] <- coef(pfit)["placebo_tp"]
  cat(sprintf("  Placebo %s: ATT = %.4f\n", d, placebo_atts[i]))
}

# Rank Azerbaijan's ATT against placebo distribution
rank_pos <- sum(abs(placebo_atts) >= abs(true_att)) + 1
total <- length(placebo_atts) + 1
perm_pvalue <- rank_pos / total

cat(sprintf("\nTrue ATT (log): %.4f\n", true_att))
cat(sprintf("Rank: %d/%d, Permutation p-value: %.3f\n", rank_pos, total, perm_pvalue))

# ============================================================
# 4. Cross-Country DiD — Bribery Incidence
# ============================================================

cat("\n=== Cross-Country DiD: Bribery Incidence ===\n")

if (nrow(es_panel) > 0 && sum(!is.na(es_panel$bribery_pct)) > 5) {
  did_brib <- lm(bribery_pct ~ treated * post, data = es_panel)
  cat("Bribery DiD:\n")
  print(summary(did_brib))

  # Extract key coefficient
  brib_coef <- coef(did_brib)["treated:post"]
  brib_se <- sqrt(diag(vcov(did_brib)))["treated:post"]
  cat(sprintf("\nDiD coefficient: %.1f (SE: %.1f)\n", brib_coef, brib_se))

  # Permutation inference for bribery
  brib_donors <- setdiff(unique(es_panel$iso3[!is.na(es_panel$bribery_pct)]), "AZE")
  brib_placebos <- numeric()

  for (d in brib_donors) {
    pdata_b <- es_panel %>%
      filter(!is.na(bribery_pct), iso3 != "AZE") %>%
      mutate(
        placebo_treated = ifelse(iso3 == d, 1, 0),
        placebo_tp = placebo_treated * post
      )
    if (nrow(pdata_b) > 4) {
      tryCatch({
        pfit_b <- lm(bribery_pct ~ placebo_treated * post, data = pdata_b)
        brib_placebos <- c(brib_placebos, coef(pfit_b)["placebo_treated:post"])
      }, error = function(e) {})
    }
  }

  if (length(brib_placebos) > 0) {
    brib_rank <- sum(abs(brib_placebos) >= abs(brib_coef)) + 1
    brib_total <- length(brib_placebos) + 1
    brib_perm_p <- brib_rank / brib_total
    cat(sprintf("Bribery permutation p-value: %.3f (%d/%d)\n",
                brib_perm_p, brib_rank, brib_total))
  }

  saveRDS(did_brib, file.path(data_dir, "did_bribery.rds"))
}

# ============================================================
# 5. Cross-Country DiD — Governance Indicators
# ============================================================

cat("\n=== Cross-Country DiD: Governance Indicators ===\n")

# Control of corruption (WGI)
did_corr <- fixest::feols(
  corruption_control ~ aze_post | iso3 + year,
  data = balanced,
  cluster = ~iso3
)
cat("Corruption Control DiD:\n")
print(summary(did_corr))

# Government effectiveness
did_goveff <- fixest::feols(
  govt_effectiveness ~ aze_post | iso3 + year,
  data = balanced,
  cluster = ~iso3
)
cat("\nGovernment Effectiveness DiD:\n")
print(summary(did_goveff))

saveRDS(did_corr, file.path(data_dir, "did_governance.rds"))
saveRDS(did_goveff, file.path(data_dir, "did_goveff.rds"))

# ============================================================
# 6. Event Study — Registrations
# ============================================================

cat("\n=== Event Study: Registrations ===\n")

# Create event-time dummies
balanced$event_time <- balanced$year - 2013

# Interact with treatment
balanced$aze <- ifelse(balanced$iso3 == "AZE", 1, 0)

# Event study with fixest
es_fit <- fixest::feols(
  log_reg ~ i(event_time, aze, ref = -1) | iso3 + year,
  data = balanced,
  cluster = ~iso3
)
cat("Event study coefficients:\n")
print(summary(es_fit))

# Save event study for tables
es_coefs <- as.data.frame(coef(es_fit))
es_coefs$term <- rownames(es_coefs)
es_se <- sqrt(diag(vcov(es_fit)))

event_study_df <- data.frame(
  event_time = as.numeric(gsub("event_time::([-0-9]+):aze", "\\1", names(coef(es_fit)))),
  coef = as.numeric(coef(es_fit)),
  se = as.numeric(es_se)
)
event_study_df <- event_study_df[order(event_study_df$event_time), ]
cat("\nEvent study table:\n")
print(event_study_df)

saveRDS(event_study_df, file.path(data_dir, "event_study.rds"))

# ============================================================
# 7. Save diagnostics
# ============================================================

diagnostics <- list(
  n_treated = 1,
  n_pre = sum(unique(balanced$year) < 2013),
  n_obs = nrow(balanced),
  n_donors = n_distinct(balanced$iso3) - 1,
  treatment_year = 2013
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

# Save main results
main_results <- list(
  did_reg_level = did_reg_level,
  did_reg_log = did_reg_log,
  pct_effect = pct_effect,
  perm_pvalue = perm_pvalue,
  true_att = true_att,
  placebo_atts = placebo_atts,
  did_corr = did_corr,
  did_goveff = did_goveff,
  event_study = event_study_df
)

saveRDS(main_results, file.path(data_dir, "main_results.rds"))

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Key results:\n"))
cat(sprintf("  Registrations (log DiD): %.4f (perm p = %.3f)\n", true_att, perm_pvalue))
cat(sprintf("  Implied %% effect: %.1f%%\n", pct_effect))
cat(sprintf("  Govt effectiveness: %.3f (p = %.4f)\n",
            coef(did_goveff)["aze_post"],
            summary(did_goveff)$coeftable["aze_post", "Pr(>|t|)"]))
