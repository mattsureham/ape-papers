## =============================================================================
## 05_figures.R — All figures for paper
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
panel_pre_covid <- panel[year <= 2019]

## ---------------------------------------------------------------------------
## Figure 1: Descriptive — National Trends in PH Spending and Drug Deaths
## ---------------------------------------------------------------------------
cat("Creating Figure 1: National trends...\n")

## National averages by year
nat_trends <- panel[, .(
  drug_deaths = mean(drug_death_rate, na.rm = TRUE),
  alcohol_mort = mean(alcohol_mortality, na.rm = TRUE),
  ph_spend = mean(ph_grant_per_head, na.rm = TRUE)
), by = year]

nat_trends <- nat_trends[!is.na(drug_deaths) & !is.na(ph_spend)]

p1a <- ggplot(nat_trends, aes(x = year)) +
  geom_line(aes(y = ph_spend), linewidth = 1, color = "#2166AC") +
  geom_point(aes(y = ph_spend), size = 2, color = "#2166AC") +
  geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2014.8, y = max(nat_trends$ph_spend, na.rm = TRUE) * 0.95,
           label = "Austerity\nbegins", hjust = 0, size = 3, color = "grey40") +
  labs(x = NULL, y = "Real PH Spend per Head (£, 2019/20 prices)",
       title = "A. Public Health Spending") +
  scale_x_continuous(breaks = seq(2006, 2024, 2))

p1b <- ggplot(nat_trends, aes(x = year)) +
  geom_line(aes(y = drug_deaths), linewidth = 1, color = "#B2182B") +
  geom_point(aes(y = drug_deaths), size = 2, color = "#B2182B") +
  geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
  labs(x = NULL, y = "Drug Misuse Deaths per 100k",
       title = "B. Drug Misuse Mortality") +
  scale_x_continuous(breaks = seq(2006, 2024, 2))

fig1 <- p1a / p1b +
  plot_annotation(
    title = "Public Health Spending and Drug Misuse Mortality in England",
    caption = "Source: OHID Fingertips, GOV.UK public health grant allocations. Real values deflated by GDP deflator (2019/20=100)."
  )

ggsave(file.path(FIG_DIR, "fig1_national_trends.pdf"), fig1,
       width = 8, height = 8, device = cairo_pdf)
cat("  Saved: fig1_national_trends.pdf\n")

## ---------------------------------------------------------------------------
## Figure 2: Descriptive — Divergence by Grant Tercile
## ---------------------------------------------------------------------------
cat("Creating Figure 2: Tercile divergence...\n")

if ("grant_tercile" %in% names(panel)) {
  terc_trends <- panel[!is.na(grant_tercile), .(
    drug_deaths = mean(drug_death_rate, na.rm = TRUE),
    alcohol_mort = mean(alcohol_mortality, na.rm = TRUE),
    ph_spend = mean(ph_grant_per_head, na.rm = TRUE)
  ), by = .(year, grant_tercile)]

  p2a <- ggplot(terc_trends[!is.na(ph_spend)],
                aes(x = year, y = ph_spend, color = grant_tercile)) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.5) +
    geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
    scale_color_manual(values = c("Large cut" = "#B2182B",
                                   "Moderate cut" = "#F4A582",
                                   "Protected" = "#2166AC")) +
    labs(x = NULL, y = "Real PH Spend per Head (£)",
         title = "A. Public Health Spending by Grant Tercile",
         color = "Grant Change Tercile") +
    scale_x_continuous(breaks = seq(2006, 2024, 2))

  p2b <- ggplot(terc_trends[!is.na(drug_deaths)],
                aes(x = year, y = drug_deaths, color = grant_tercile)) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.5) +
    geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
    scale_color_manual(values = c("Large cut" = "#B2182B",
                                   "Moderate cut" = "#F4A582",
                                   "Protected" = "#2166AC")) +
    labs(x = NULL, y = "Drug Misuse Deaths per 100k",
         title = "B. Drug Misuse Mortality by Grant Tercile",
         color = "Grant Change Tercile") +
    scale_x_continuous(breaks = seq(2006, 2024, 2))

  fig2 <- p2a / p2b +
    plot_annotation(
      title = "Spending and Mortality Divergence by Grant Cut Severity",
      caption = "Note: Terciles defined by cumulative real per-capita grant change from first observed grant year (2016). Source: OHID Fingertips, GOV.UK."
    ) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")

  ggsave(file.path(FIG_DIR, "fig2_tercile_divergence.pdf"), fig2,
         width = 8, height = 8, device = cairo_pdf)
  cat("  Saved: fig2_tercile_divergence.pdf\n")
}

## ---------------------------------------------------------------------------
## Figure 3: Event Study — Treatment Effect Dynamics
## ---------------------------------------------------------------------------
cat("Creating Figure 3: Event study...\n")

if ("es_drug" %in% names(results)) {
  es <- results$es_drug
  es_coefs <- data.table(
    year = as.integer(gsub("year::|:baseline_grant_std", "", names(coef(es)))),
    coef = coef(es),
    se = se(es)
  )
  es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]

  ## Add reference year (2014 = 0)
  es_coefs <- rbind(
    es_coefs,
    data.table(year = 2014, coef = 0, se = 0, ci_lo = 0, ci_hi = 0)
  )
  es_coefs <- es_coefs[order(year)]

  fig3_drug <- ggplot(es_coefs, aes(x = year, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#B2182B") +
    geom_line(color = "#B2182B", linewidth = 0.8) +
    geom_point(color = "#B2182B", size = 2) +
    labs(x = "Year", y = "Coefficient (Drug Deaths per 100k × Baseline Spend SD)",
         title = "Event Study: Drug Misuse Deaths",
         caption = "Note: Interaction of year dummies with standardized baseline PH spend. Reference year: 2014. 95% CI shown.") +
    scale_x_continuous(breaks = seq(2006, 2019, 1)) +
    annotate("text", x = 2011, y = max(es_coefs$ci_hi) * 0.8,
             label = "Pre-treatment", hjust = 0.5, size = 3, color = "grey40") +
    annotate("text", x = 2017, y = max(es_coefs$ci_hi) * 0.8,
             label = "Post-treatment", hjust = 0.5, size = 3, color = "grey40")

  ggsave(file.path(FIG_DIR, "fig3_event_study_drug.pdf"), fig3_drug,
         width = 8, height = 5, device = cairo_pdf)
  cat("  Saved: fig3_event_study_drug.pdf\n")
}

## Also create event studies for alcohol and treatment rate
for (outcome_name in c("es_alc", "es_treat")) {
  if (outcome_name %in% names(results)) {
    es <- results[[outcome_name]]
    es_coefs <- data.table(
      year = as.integer(gsub("year::|:baseline_grant_std", "", names(coef(es)))),
      coef = coef(es),
      se = se(es)
    )
    es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
    es_coefs <- rbind(
      es_coefs,
      data.table(year = 2014, coef = 0, se = 0, ci_lo = 0, ci_hi = 0)
    )
    es_coefs <- es_coefs[order(year)]

    label <- ifelse(outcome_name == "es_alc", "Alcohol-Specific Mortality",
                    "Drug Treatment Completion Rate")
    color <- ifelse(outcome_name == "es_alc", "#D6604D", "#4393C3")
    fname <- ifelse(outcome_name == "es_alc", "fig3b_event_study_alcohol.pdf",
                    "fig3c_event_study_treatment.pdf")

    p <- ggplot(es_coefs, aes(x = year, y = coef)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
      geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
      geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = color) +
      geom_line(color = color, linewidth = 0.8) +
      geom_point(color = color, size = 2) +
      labs(x = "Year", y = paste0("Coefficient (", label, ")"),
           title = paste("Event Study:", label)) +
      scale_x_continuous(breaks = seq(2006, 2019, 1))

    ggsave(file.path(FIG_DIR, fname), p, width = 8, height = 5, device = cairo_pdf)
    cat(sprintf("  Saved: %s\n", fname))
  }
}

## ---------------------------------------------------------------------------
## Figure 4: Cross-Sectional — Grant Change vs Mortality Change
## ---------------------------------------------------------------------------
cat("Creating Figure 4: Binscatter...\n")

if ("grant_change_pct" %in% names(panel)) {
  ## Calculate LA-level changes: pre-period mean vs post-period mean
  pre_means <- panel[year %in% 2010:2014 & !is.na(drug_death_rate),
                     .(drug_pre = mean(drug_death_rate, na.rm = TRUE)),
                     by = la_code]
  post_means <- panel[year %in% 2017:2019 & !is.na(drug_death_rate),
                      .(drug_post = mean(drug_death_rate, na.rm = TRUE)),
                      by = la_code]
  change_dt <- merge(pre_means, post_means, by = "la_code")
  change_dt[, drug_change := drug_post - drug_pre]

  grant_change <- panel[year == 2019 & !is.na(grant_change_pct),
                        .(la_code, grant_change_pct)]
  change_dt <- merge(change_dt, grant_change, by = "la_code")

  fig4 <- ggplot(change_dt, aes(x = grant_change_pct, y = drug_change)) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
    geom_vline(xintercept = 0, color = "grey60", linetype = "dashed") +
    geom_point(alpha = 0.5, size = 2, color = "#B2182B") +
    geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 0.8) +
    labs(x = "Cumulative Real Grant Change, 2016-2019 (%)",
         y = "Change in Drug Misuse Deaths per 100k\n(2017-19 mean vs 2010-14 mean)",
         title = "Grant Cuts and Drug Mortality: Cross-Sectional Evidence",
         caption = "Each point is an upper-tier local authority. OLS fit shown.") +
    annotate("text", x = min(change_dt$grant_change_pct) * 0.8,
             y = max(change_dt$drug_change) * 0.9,
             label = sprintf("N = %d LAs", nrow(change_dt)),
             hjust = 0, size = 3.5)

  ggsave(file.path(FIG_DIR, "fig4_binscatter.pdf"), fig4,
         width = 7, height = 6, device = cairo_pdf)
  cat("  Saved: fig4_binscatter.pdf\n")
}

## ---------------------------------------------------------------------------
## Figure 5: Mechanism — Treatment Completion and Drug Deaths
## ---------------------------------------------------------------------------
cat("Creating Figure 5: Mechanism path...\n")

if ("drug_treatment_opiate" %in% names(panel)) {
  ## National trends in treatment completion and drug deaths
  mech_trends <- panel[, .(
    treatment_rate = mean(drug_treatment_opiate, na.rm = TRUE),
    drug_deaths = mean(drug_death_rate, na.rm = TRUE)
  ), by = year]
  mech_trends <- mech_trends[!is.na(treatment_rate) & !is.na(drug_deaths)]

  p5a <- ggplot(mech_trends, aes(x = year, y = treatment_rate)) +
    geom_line(linewidth = 1, color = "#4393C3") +
    geom_point(size = 2, color = "#4393C3") +
    geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
    labs(x = NULL, y = "Successful Treatment Completion (%)",
         title = "A. Opiate Treatment Completion Rate") +
    scale_x_continuous(breaks = seq(2006, 2024, 2))

  p5b <- ggplot(mech_trends, aes(x = year, y = drug_deaths)) +
    geom_line(linewidth = 1, color = "#B2182B") +
    geom_point(size = 2, color = "#B2182B") +
    geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
    labs(x = NULL, y = "Drug Misuse Deaths per 100k",
         title = "B. Drug Misuse Mortality Rate") +
    scale_x_continuous(breaks = seq(2006, 2024, 2))

  fig5 <- p5a / p5b +
    plot_annotation(
      title = "Mechanism: Treatment Capacity and Drug Mortality",
      caption = "Source: OHID Fingertips. Treatment completion from NDTMS."
    )

  ggsave(file.path(FIG_DIR, "fig5_mechanism.pdf"), fig5,
         width = 8, height = 7, device = cairo_pdf)
  cat("  Saved: fig5_mechanism.pdf\n")
}

## ---------------------------------------------------------------------------
## Figure 6: Placebo — Cancer Mortality Event Study
## ---------------------------------------------------------------------------
cat("Creating Figure 6: Placebo...\n")

if ("placebo_cancer" %in% names(results) && "baseline_grant_std" %in% names(panel_pre_covid)) {
  ## Re-estimate event study for cancer
  es_cancer <- tryCatch({
    feols(cancer_mortality ~ i(year, baseline_grant_std, ref = 2014) | la_code + year,
          data = panel_pre_covid[!is.na(cancer_mortality) & !is.na(baseline_grant_std)],
          cluster = ~la_code)
  }, error = function(e) NULL)

  if (!is.null(es_cancer)) {
    es_coefs <- data.table(
      year = as.integer(gsub("year::|:baseline_grant_std", "", names(coef(es_cancer)))),
      coef = coef(es_cancer),
      se = se(es_cancer)
    )
    es_coefs[, `:=`(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)]
    es_coefs <- rbind(
      es_coefs,
      data.table(year = 2014, coef = 0, se = 0, ci_lo = 0, ci_hi = 0)
    )
    es_coefs <- es_coefs[order(year)]

    fig6 <- ggplot(es_coefs, aes(x = year, y = coef)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
      geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
      geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "grey50") +
      geom_line(color = "grey40", linewidth = 0.8) +
      geom_point(color = "grey40", size = 2) +
      labs(x = "Year", y = "Coefficient (Cancer Mortality × Baseline Spend SD)",
           title = "Placebo: Cancer Mortality (Long Latency, Should Not Respond)",
           caption = "Note: Cancer mortality should not be affected by short-term PH spending changes. Null effect expected.") +
      scale_x_continuous(breaks = seq(2006, 2019, 1))

    ggsave(file.path(FIG_DIR, "fig6_placebo_cancer.pdf"), fig6,
           width = 8, height = 5, device = cairo_pdf)
    cat("  Saved: fig6_placebo_cancer.pdf\n")
  }
}

cat("\n✓ All figures saved to:", FIG_DIR, "\n")
cat("  Files:", paste(list.files(FIG_DIR, pattern = "\\.pdf$"), collapse = ", "), "\n")
