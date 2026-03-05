## ============================================================
## 04_robustness.R — Robustness checks and diagnostics
## apep_0522: Flood Re and English Property Values
## ============================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat(sprintf("Analysis panel: %s rows\n", format(nrow(panel), big.mark = ",")))

## -------------------------------------------------------
## 1. Placebo Timing Tests
## -------------------------------------------------------

cat("\n=== ROBUSTNESS 1: Placebo Timing ===\n")

# Placebo at 2012 (well before any Flood Re discussion)
panel[, post_placebo_2012 := as.integer(year >= 2012)]
m_placebo_2012 <- feols(
  ln_price ~ flood_risk_high:post_placebo_2012 +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel[year <= 2015],  # Only pre-Flood-Re period
  cluster = ~la_code
)
cat("Placebo at 2012 (pre-period only):\n")
summary(m_placebo_2012)

# Placebo at 2014 (announcement year)
panel[, post_placebo_2014 := as.integer(year >= 2014)]
m_placebo_2014 <- feols(
  ln_price ~ flood_risk_high:post_placebo_2014 +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel[year <= 2015],
  cluster = ~la_code
)
cat("\nPlacebo at 2014 (announcement, pre-period only):\n")
summary(m_placebo_2014)

## -------------------------------------------------------
## 2. Exclude London
## -------------------------------------------------------

cat("\n=== ROBUSTNESS 2: Exclude London ===\n")

m_no_london <- feols(
  ln_price ~ flood_risk_high:post_floodre +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel[region != "London"],
  cluster = ~la_code
)
cat("Excluding London:\n")
summary(m_no_london)

## -------------------------------------------------------
## 3. Alternative Flood Risk Definitions
## -------------------------------------------------------

cat("\n=== ROBUSTNESS 3: Alternative Risk Definitions ===\n")

# Use "any" flood risk (High + Medium + Low) as treatment
m_any_risk <- feols(
  ln_price ~ flood_risk_any:post_floodre +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel,
  cluster = ~la_code
)
cat("Any flood risk (H+M+L) as treatment:\n")
summary(m_any_risk)

# High risk only
panel[, flood_risk_high_only := as.integer(
  flood_risk_band %in% c("High", "HIGH", "high")
)]
m_high_only <- feols(
  ln_price ~ flood_risk_high_only:post_floodre +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel,
  cluster = ~la_code
)
cat("\nHigh risk only as treatment:\n")
summary(m_high_only)

## -------------------------------------------------------
## 4. Property Type Heterogeneity
## -------------------------------------------------------

cat("\n=== ROBUSTNESS 4: By Property Type ===\n")

prop_types <- c("D", "S", "T", "F")
prop_labels <- c("Detached", "Semi-Detached", "Terraced", "Flat")

hetero_results <- list()
for (j in seq_along(prop_types)) {
  ptype <- prop_types[j]
  sub <- panel[property_type == ptype]
  if (nrow(sub) > 1000) {
    m <- feols(
      ln_price ~ flood_risk_high:post_floodre +
        i(duration) + new_build |
        postcode_sector + year_quarter_str,
      data = sub,
      cluster = ~la_code
    )
    hetero_results[[prop_labels[j]]] <- data.table(
      property_type = prop_labels[j],
      coef = coef(m)["flood_risk_high:post_floodre"],
      se = se(m)["flood_risk_high:post_floodre"],
      n = nrow(sub)
    )
    cat(sprintf("\n%s (N=%s):\n", prop_labels[j],
                format(nrow(sub), big.mark = ",")))
    cat(sprintf("  Coefficient: %.4f (SE: %.4f)\n",
                coef(m)["flood_risk_high:post_floodre"],
                se(m)["flood_risk_high:post_floodre"]))
  }
}

hetero_dt <- rbindlist(hetero_results)
fwrite(hetero_dt, file.path(data_dir, "heterogeneity_property_type.csv"))

## -------------------------------------------------------
## 5. Regional Heterogeneity
## -------------------------------------------------------

cat("\n=== ROBUSTNESS 5: By Region ===\n")

regions <- panel[, unique(region)]
regions <- regions[!is.na(regions)]

region_results <- list()
for (reg in regions) {
  sub <- panel[region == reg]
  if (nrow(sub) > 5000 && sum(sub$flood_risk_high) > 100) {
    m <- feols(
      ln_price ~ flood_risk_high:post_floodre +
        i(property_type) + i(duration) + new_build |
        postcode_sector + year_quarter_str,
      data = sub,
      cluster = ~la_code
    )
    region_results[[reg]] <- data.table(
      region = reg,
      coef = coef(m)["flood_risk_high:post_floodre"],
      se = se(m)["flood_risk_high:post_floodre"],
      n = nrow(sub),
      n_flood = sum(sub$flood_risk_high)
    )
  }
}

region_dt <- rbindlist(region_results)
fwrite(region_dt, file.path(data_dir, "heterogeneity_region.csv"))
cat("\nRegional heterogeneity:\n")
print(region_dt[order(-coef)])

## -------------------------------------------------------
## 6. HonestDiD Sensitivity Analysis
## -------------------------------------------------------

cat("\n=== ROBUSTNESS 6: HonestDiD Sensitivity ===\n")

# Run event study for HonestDiD
m_es_honest <- feols(
  ln_price ~ i(rel_year, flood_risk_high, ref = -1) +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel[year >= 2010],
  cluster = ~la_code
)

# Extract beta and sigma for HonestDiD
tryCatch({
  beta_hat <- coef(m_es_honest)
  sigma_hat <- vcov(m_es_honest)

  # Get the event-study coefficient indices
  es_names <- names(beta_hat)[grepl("rel_year", names(beta_hat))]
  es_idx <- match(es_names, names(beta_hat))

  beta_es <- beta_hat[es_idx]
  sigma_es <- sigma_hat[es_idx, es_idx]

  # Identify pre and post periods
  rel_years <- as.integer(str_extract(es_names, "-?[0-9]+"))
  n_pre <- sum(rel_years < 0)
  n_post <- sum(rel_years > 0)

  if (n_pre >= 2 && n_post >= 1) {
    # Relative magnitudes approach
    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta_es,
      sigma = sigma_es,
      numPrePeriods = n_pre,
      numPostPeriods = n_post,
      Mbarvec = seq(0, 2, by = 0.5)
    )

    # Save results
    honest_df <- as.data.table(honest_rm)
    fwrite(honest_df, file.path(data_dir, "honestdid_results.csv"))
    cat("HonestDiD sensitivity results saved\n")
    print(honest_df)
  } else {
    cat("Insufficient pre/post periods for HonestDiD\n")
  }
}, error = function(e) {
  cat(sprintf("HonestDiD error: %s\n", e$message))
  cat("Proceeding without HonestDiD sensitivity\n")
})

## -------------------------------------------------------
## 7. Save all robustness results
## -------------------------------------------------------

robustness_summary <- data.table(
  check = c("Placebo 2012", "Placebo 2014",
            "Excl London", "Any flood risk", "High risk only"),
  coefficient = c(
    coef(m_placebo_2012)["flood_risk_high:post_placebo_2012"],
    coef(m_placebo_2014)["flood_risk_high:post_placebo_2014"],
    coef(m_no_london)["flood_risk_high:post_floodre"],
    coef(m_any_risk)["flood_risk_any:post_floodre"],
    coef(m_high_only)["flood_risk_high_only:post_floodre"]
  ),
  se = c(
    se(m_placebo_2012)["flood_risk_high:post_placebo_2012"],
    se(m_placebo_2014)["flood_risk_high:post_placebo_2014"],
    se(m_no_london)["flood_risk_high:post_floodre"],
    se(m_any_risk)["flood_risk_any:post_floodre"],
    se(m_high_only)["flood_risk_high_only:post_floodre"]
  )
)
robustness_summary[, pct_effect := 100 * (exp(coefficient) - 1)]
robustness_summary[, sig := ifelse(abs(coefficient / se) > 1.96, "***",
                    ifelse(abs(coefficient / se) > 1.645, "**",
                    ifelse(abs(coefficient / se) > 1.28, "*", "")))]

fwrite(robustness_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\n=== ROBUSTNESS SUMMARY ===\n")
print(robustness_summary)
