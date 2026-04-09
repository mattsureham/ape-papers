## ============================================================================
## 06_tables.R — Generate LaTeX Tables for apep_0626 V2
## "Closing the Golden Door" — The Restrictionist Mirage
## ============================================================================

source("code/00_packages.R")

data_dir <- "data"
tables_dir <- "tables"
dir.create(tables_dir, showWarnings = FALSE)

## Force modelsummary to produce plain LaTeX strings
options(modelsummary_format_numeric_latex = "plain")

## --------------------------------------------------------------------------
## Load all models and data
## --------------------------------------------------------------------------

dt <- readRDS(file.path(data_dir, "clean_1920_1930.rds"))
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
alt_models <- readRDS(file.path(data_dir, "alt_models.rds"))
het_models <- readRDS(file.path(data_dir, "het_models.rds"))
loo_results <- readRDS(file.path(data_dir, "loo_results.rds"))
diagnostics <- fromJSON(file.path(data_dir, "diagnostics.json"))

## --------------------------------------------------------------------------
## Table 1: Summary Statistics by Exposure Quartile
## --------------------------------------------------------------------------

cat("=== Table 1: Summary Statistics ===\n")

summ <- dt[, .(
  N = format(.N, big.mark = ","),
  `Mean Quota Exposure` = sprintf("%.3f", mean(quota_exposure)),
  `OCCSCORE (1920)` = sprintf("%.1f", mean(occscore_1920)),
  `OCCSCORE (1930)` = sprintf("%.1f", mean(occscore_1930)),
  `$\\Delta$ OCCSCORE` = sprintf("%.2f", mean(delta_occscore)),
  `Share Upgraded` = sprintf("%.3f", mean(upgraded)),
  `Share Farm (1920)` = sprintf("%.3f", mean(farm_1920 == 2)),
  `Farm Exit Rate` = sprintf("%.3f", mean(farm_exit)),
  `Share Moved` = sprintf("%.3f", mean(moved, na.rm = TRUE)),
  `Share Literate` = sprintf("%.3f", mean(literate)),
  `Mean Age (1920)` = sprintf("%.1f", mean(age_1920))
), by = exp_quartile][order(exp_quartile)]

## Add overall row
overall <- dt[, .(
  exp_quartile = "Overall",
  N = format(.N, big.mark = ","),
  `Mean Quota Exposure` = sprintf("%.3f", mean(quota_exposure)),
  `OCCSCORE (1920)` = sprintf("%.1f", mean(occscore_1920)),
  `OCCSCORE (1930)` = sprintf("%.1f", mean(occscore_1930)),
  `$\\Delta$ OCCSCORE` = sprintf("%.2f", mean(delta_occscore)),
  `Share Upgraded` = sprintf("%.3f", mean(upgraded)),
  `Share Farm (1920)` = sprintf("%.3f", mean(farm_1920 == 2)),
  `Farm Exit Rate` = sprintf("%.3f", mean(farm_exit)),
  `Share Moved` = sprintf("%.3f", mean(moved, na.rm = TRUE)),
  `Share Literate` = sprintf("%.3f", mean(literate)),
  `Mean Age (1920)` = sprintf("%.1f", mean(age_1920))
)]

summ <- rbind(summ, overall)

## Transpose for LaTeX
summ_t <- t(summ[, -1])
colnames(summ_t) <- summ$exp_quartile

tab1_tex <- kbl(summ_t, format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Summary Statistics by Quota Exposure Quartile",
    label = "summary") |>
  kable_styling(latex_options = c("hold_position")) |>
  add_header_above(c(" " = 1, "Exposure Quartile" = 4, " " = 1)) |>
  footnote(general = c(
    "Sample: Native-born men aged 18--55 in 1920 with valid occupations in both census years,",
    "linked across the 1920 and 1930 censuses via IPUMS MLP v2. Quota exposure is the county-level",
    "share of 1920 population born in restricted-origin countries (Italy, Russia, Poland, Austria,",
    "Hungary, Czechoslovakia). OCCSCORE is the IPUMS occupational income score."),
    threeparttable = TRUE, escape = FALSE)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Wrote tab1_summary.tex\n")

## --------------------------------------------------------------------------
## Table 2: Main Results — Effect of Quota Exposure on Occupational Mobility
## --------------------------------------------------------------------------

cat("=== Table 2: Main Results ===\n")

cm <- c(
  "quota_exposure" = "Quota Exposure",
  "quota_exposure_broad" = "Quota Exposure (Broad)",
  "age_1920" = "Age",
  "I(age_1920^2)" = "Age$^2$",
  "literate" = "Literate",
  "urban" = "Urban",
  "log_pop" = "Log(Population)"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared", "clean" = "R$^2$", "fmt" = 3)
)

## Use etable from fixest for reliable LaTeX output
etable(main_models$m1, main_models$m2, main_models$m3, main_models$m4, main_models$m5,
  headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
  dict = c(
    quota_exposure = "Quota Exposure",
    quota_exposure_broad = "Quota Exposure (Broad)",
    age_1920 = "Age",
    "I(age_1920^2)" = "Age$^2$",
    literate = "Literate",
    urban = "Urban",
    log_pop = "Log(Population)"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  title = "Effect of Quota Exposure on Occupational Mobility, 1920--1930",
  label = "tab:main",
  notes = c(
    "Dependent variable is change in OCCSCORE between 1920 and 1930.",
    "Quota exposure is the county-level share of 1920 population born in countries subject to",
    "severe quota restrictions under the 1924 Johnson-Reed Act. Column (5) uses a broader",
    "definition including Greece, Romania, Yugoslavia, and Baltic states. Standard errors",
    "clustered at the county level in parentheses."
  ),
  tex = TRUE,
  file = file.path(tables_dir, "tab2_main.tex"),
  replace = TRUE
)
cat("  Wrote tab2_main.tex\n")

## --------------------------------------------------------------------------
## Table 3: Heterogeneity — By Race, Skill, and Location
## --------------------------------------------------------------------------

cat("=== Table 3: Heterogeneity ===\n")

etable(het_models$m_white, het_models$m_black,
       het_models$m_urban, het_models$m_rural,
  headers = c("White", "Black", "Urban", "Rural"),
  dict = c(
    quota_exposure = "Quota Exposure",
    age_1920 = "Age",
    "I(age_1920^2)" = "Age$^2$",
    literate = "Literate",
    urban = "Urban",
    log_pop = "Log(Population)"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  title = "Heterogeneous Effects by Race and Location",
  label = "tab:heterogeneity",
  notes = c(
    "Dependent variable is change in OCCSCORE (1920--1930).",
    "All columns include state and 1920 occupation fixed effects, and individual controls.",
    "Standard errors clustered at the county level."
  ),
  tex = TRUE,
  file = file.path(tables_dir, "tab3_heterogeneity.tex"),
  replace = TRUE
)
cat("  Wrote tab3_heterogeneity.tex\n")

## --------------------------------------------------------------------------
## Table 4: Placebo Test — 1910-1920 (Pre-Quota Period)
## --------------------------------------------------------------------------

cat("=== Table 4: Placebo ===\n")

if (file.exists(file.path(data_dir, "placebo_models.rds"))) {
  placebo_models <- readRDS(file.path(data_dir, "placebo_models.rds"))

  etable(placebo_models$m_placebo_1, placebo_models$m_placebo_2,
         placebo_models$m_placebo_full, placebo_models$m_placebo_upgrade,
    headers = c("$\\Delta$OccScore (1920 Exp.)", "$\\Delta$OccScore (1910 Exp.)",
                "$\\Delta$OccScore (Full)", "Upgraded (1920 Exp.)"),
    dict = c(
      quota_exposure = "Quota Exposure (1920)",
      quota_exposure_1910 = "Quota Exposure (1910)",
      age_1910 = "Age",
      "I(age_1910^2)" = "Age$^2$",
      literate = "Literate",
      urban = "Urban"
    ),
    se.below = TRUE,
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
    title = "Placebo Test: 1910--1920 (Pre-Quota Period)",
    label = "tab:placebo",
    notes = c(
      "Dependent variable is the change in OCCSCORE between 1910 and 1920",
      "(the decade before the 1924 quota). If quota exposure proxies for pre-existing",
      "occupational upgrading trends, we would expect significant coefficients here.",
      "Null results support the parallel-trends assumption. All columns include state FE",
      "and individual controls. Standard errors clustered at county level."
    ),
    tex = TRUE,
    file = file.path(tables_dir, "tab4_placebo.tex"),
    replace = TRUE
  )
  cat("  Wrote tab4_placebo.tex\n")
} else {
  cat("  SKIPPED: No placebo models\n")
}

## --------------------------------------------------------------------------
## Table 5: Robustness — Leave-One-Out, Clustering, Non-Movers
## --------------------------------------------------------------------------

cat("=== Table 5: Robustness ===\n")

## Panel A: Leave-one-origin-out
loo_tex <- kbl(
  loo_results[, .(
    `Dropped Origin` = tools::toTitleCase(dropped_origin),
    `Coefficient` = sprintf("%.4f", coef),
    `Std. Error` = sprintf("%.4f", se),
    `t-stat` = sprintf("%.2f", coef / se)
  )],
  format = "latex", booktabs = TRUE, escape = FALSE,
  caption = "Robustness Checks",
  label = "tab:robustness"
) |>
  kable_styling(latex_options = c("hold_position")) |>
  pack_rows("Panel A: Leave-One-Origin-Out", 1, nrow(loo_results))

## Add Panel B info
m_state_cl <- readRDS(file.path(data_dir, "model_state_cluster.rds"))
m_nonmover <- readRDS(file.path(data_dir, "model_nonmover.rds"))

panel_b <- data.table(
  `Specification` = c("Baseline (county cluster)", "State cluster", "Non-movers only"),
  `Coefficient` = c(
    sprintf("%.4f", diagnostics$main_coef),
    sprintf("%.4f", coef(m_state_cl)["quota_exposure"]),
    sprintf("%.4f", coef(m_nonmover)["quota_exposure"])
  ),
  `Std. Error` = c(
    sprintf("%.4f", diagnostics$main_se),
    sprintf("%.4f", se(m_state_cl)["quota_exposure"]),
    sprintf("%.4f", se(m_nonmover)["quota_exposure"])
  ),
  N = c(
    format(diagnostics$n_obs, big.mark = ","),
    format(nobs(m_state_cl), big.mark = ","),
    format(nobs(m_nonmover), big.mark = ",")
  )
)

panel_b_tex <- kbl(panel_b, format = "latex", booktabs = TRUE, escape = FALSE) |>
  kable_styling(latex_options = c("hold_position")) |>
  pack_rows("Panel B: Alternative Specifications", 1, 3)

## Combine into one table
tab5_full <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{threeparttable}",
  loo_tex,
  "",
  "\\vspace{0.5em}",
  panel_b_tex,
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Panel A drops each origin country in turn from the quota exposure",
  "measure and re-estimates the main specification. Panel B varies the clustering level and",
  "sample. All specifications include state and 1920 occupation fixed effects and individual",
  "controls. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_full, file.path(tables_dir, "tab5_robustness.tex"))
cat("  Wrote tab5_robustness.tex\n")

## --------------------------------------------------------------------------
## SDE Appendix Table (Mandatory)
## --------------------------------------------------------------------------

cat("=== SDE Table ===\n")

## Collect main outcomes and their SDE
outcomes <- list(
  list(name = "$\\Delta$ OCCSCORE", model = main_models$m4,
       var = "quota_exposure", y_var = "delta_occscore",
       treatment = "continuous"),
  list(name = "Upgraded Occupation", model = alt_models$m_upgrade,
       var = "quota_exposure", y_var = "upgraded",
       treatment = "continuous"),
  list(name = "Farm Exit", model = alt_models$m_farm_exit,
       var = "quota_exposure", y_var = "farm_exit",
       treatment = "continuous"),
  list(name = "Geographic Mobility", model = alt_models$m_moved,
       var = "quota_exposure", y_var = "moved",
       treatment = "continuous"),
  list(name = "$\\Delta$ SEI", model = alt_models$m_sei,
       var = "quota_exposure", y_var = "delta_sei",
       treatment = "continuous")
)

sd_x <- sd(dt$quota_exposure)
sde_rows <- list()

for (o in outcomes) {
  b <- coef(o$model)[o$var]
  se_b <- se(o$model)[o$var]

  if (o$y_var == "farm_exit") {
    sd_y <- sd(dt[farm_1920 == 2][[o$y_var]], na.rm = TRUE)
  } else {
    sd_y <- sd(dt[[o$y_var]], na.rm = TRUE)
  }

  ## Continuous treatment: SDE = beta * SD(X) / SD(Y)
  sde <- b * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y

  ## Classification
  bucket <- fcase(
    sde < -0.15, "Large negative",
    sde < -0.05, "Moderate negative",
    sde < -0.005, "Small negative",
    sde < 0.005, "Null",
    sde < 0.05, "Small positive",
    sde < 0.15, "Moderate positive",
    default = "Large positive"
  )

  sde_rows <- c(sde_rows, list(data.table(
    Outcome = o$name,
    `$\\hat{\\beta}$` = sprintf("%.4f", b),
    SE = sprintf("%.4f", se_b),
    `SD(Y)` = sprintf("%.3f", sd_y),
    SDE = sprintf("%.4f", sde),
    `SE(SDE)` = sprintf("%.4f", se_sde),
    Classification = bucket
  )))
}

sde_dt <- rbindlist(sde_rows)

sde_tex <- kbl(sde_dt, format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Standardized Effect Sizes",
    label = "tab:sde") |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = c(
    "Standardized effect sizes computed as SDE = $\\hat{\\beta} \\times$ SD(X) / SD(Y) for",
    "continuous treatment. Treatment is the county-level share of restricted-origin foreign-born",
    "in 1920 (SD = ", sprintf("%.3f", sd_x), "). Classification refers to the magnitude of the",
    "standardized effect, not statistical significance. Data: IPUMS MLP v2 linked 1920--1930",
    sprintf("panel, N = %s native-born men.", format(nrow(dt), big.mark = ",")),
    "Method: individual-level continuous-treatment DiD with county-level quota exposure."),
    threeparttable = TRUE, escape = FALSE)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Wrote tabF1_sde.tex\n")

## --------------------------------------------------------------------------
## V2 Table 6: First-Stage Evidence
## --------------------------------------------------------------------------

cat("=== V2 Table 6: First Stage ===\n")

if (file.exists(file.path(data_dir, "first_stage_models.rds"))) {
  fs <- readRDS(file.path(data_dir, "first_stage_models.rds"))

  etable(fs$m_fs1, fs$m_fs2,
    headers = c("$\\Delta$ Restricted Share", "$\\Delta$ Total FB Share"),
    dict = c(quota_exposure = "Quota Exposure (1920)"),
    se.below = TRUE,
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
    title = "First Stage: Did Restriction Reduce Immigrant Presence?",
    label = "tab:firststage",
    notes = c(
      "County-level regressions weighted by number of linked individuals.",
      "Dependent variable is the change in county share of foreign-born from",
      "restricted-origin countries (Col 1) or all foreign-born (Col 2)",
      "between the 1920 and 1930 censuses. Includes state fixed effects."
    ),
    tex = TRUE,
    file = file.path(tables_dir, "tab6_first_stage.tex"),
    replace = TRUE
  )
  cat("  Wrote tab6_first_stage.tex\n")
} else {
  cat("  SKIPPED: No first-stage models\n")
}

## --------------------------------------------------------------------------
## V2 Table 7: Alternative Outcomes (expanded with homeownership)
## --------------------------------------------------------------------------

cat("=== V2 Table 7: Alternative Outcomes ===\n")

etable(alt_models$m_upgrade, alt_models$m_farm_exit,
       alt_models$m_moved, alt_models$m_sei, alt_models$m_owner,
  headers = c("Upgraded", "Farm Exit", "Moved", "$\\Delta$ SEI", "Became Owner"),
  dict = c(quota_exposure = "Quota Exposure"),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
  title = "Alternative Outcomes: Occupational Mobility, Migration, and Homeownership",
  label = "tab:altoutcomes",
  notes = c(
    "Each column estimates a separate regression of the indicated outcome on quota exposure.",
    "All specifications include state and 1920 occupation FE, individual controls, and",
    "county-clustered standard errors. Farm Exit restricted to 1920 farm workers.",
    "Became Owner indicates transition from renter to owner between 1920 and 1930."
  ),
  tex = TRUE,
  file = file.path(tables_dir, "tab7_alt_outcomes.tex"),
  replace = TRUE
)
cat("  Wrote tab7_alt_outcomes.tex\n")

## --------------------------------------------------------------------------
## V2 Table 8: Homeownership Mechanism Decomposition
## --------------------------------------------------------------------------

cat("=== V2 Table 8: Homeownership Mechanism ===\n")

if (file.exists(file.path(data_dir, "owner_mechanism_models.rds"))) {
  owner_mech <- readRDS(file.path(data_dir, "owner_mechanism_models.rds"))

  etable(owner_mech$m_owner_renters, owner_mech$m_lost_home, owner_mech$m_net_owner,
         owner_mech$m_owner_young, owner_mech$m_owner_old,
         owner_mech$m_owner_urban, owner_mech$m_owner_rural,
    headers = c("Became Owner\n(Renters)", "Lost Home\n(Owners)", "Net Ownership",
                "Young\n(18-35)", "Old\n(36-55)", "Urban", "Rural"),
    dict = c(quota_exposure = "Quota Exposure"),
    se.below = TRUE,
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
    title = "Homeownership Mechanism Decomposition",
    label = "tab:ownermech",
    notes = c(
      "Cols 1-3 decompose net homeownership transitions. Col 1: among 1920 renters,",
      "probability of becoming owner by 1930. Col 2: among 1920 owners, probability",
      "of losing ownership by 1930. Col 3: net transition (became minus lost).",
      "Cols 4-7 estimate homeownership transitions by age and location.",
      "All specifications include state and occupation FE, individual controls,",
      "and county-clustered standard errors."
    ),
    tex = TRUE,
    file = file.path(tables_dir, "tab8_owner_mechanism.tex"),
    replace = TRUE
  )
  cat("  Wrote tab8_owner_mechanism.tex\n")
}

## --------------------------------------------------------------------------
## V2 SDE Table: Updated with all outcomes including homeownership
## --------------------------------------------------------------------------

cat("=== V2 SDE Table (updated) ===\n")

## Reload to include homeownership-specific outcomes
outcomes_v2 <- list(
  list(name = "$\\Delta$ OCCSCORE", model = main_models$m4,
       var = "quota_exposure", y_var = "delta_occscore"),
  list(name = "Upgraded Occupation", model = alt_models$m_upgrade,
       var = "quota_exposure", y_var = "upgraded"),
  list(name = "Became Homeowner", model = alt_models$m_owner,
       var = "quota_exposure", y_var = "became_owner"),
  list(name = "Farm Exit", model = alt_models$m_farm_exit,
       var = "quota_exposure", y_var = "farm_exit"),
  list(name = "Geographic Mobility", model = alt_models$m_moved,
       var = "quota_exposure", y_var = "moved"),
  list(name = "$\\Delta$ SEI", model = alt_models$m_sei,
       var = "quota_exposure", y_var = "delta_sei")
)

sd_x <- sd(dt$quota_exposure)
sde_rows <- list()

for (o in outcomes_v2) {
  b <- coef(o$model)[o$var]
  se_b <- se(o$model)[o$var]
  if (o$y_var == "farm_exit") {
    sd_y <- sd(dt[farm_1920 == 2][[o$y_var]], na.rm = TRUE)
  } else {
    sd_y <- sd(dt[[o$y_var]], na.rm = TRUE)
  }
  sde <- b * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  bucket <- fcase(
    sde < -0.15, "Large negative",
    sde < -0.05, "Moderate negative",
    sde < -0.005, "Small negative",
    sde < 0.005, "Null",
    sde < 0.05, "Small positive",
    sde < 0.15, "Moderate positive",
    default = "Large positive"
  )
  sde_rows <- c(sde_rows, list(data.table(
    Outcome = o$name,
    `$\\hat{\\beta}$` = sprintf("%.4f", b),
    SE = sprintf("%.4f", se_b),
    `SD(Y)` = sprintf("%.3f", sd_y),
    SDE = sprintf("%.4f", sde),
    `SE(SDE)` = sprintf("%.4f", se_sde),
    Classification = bucket
  )))
}

sde_dt <- rbindlist(sde_rows)

sde_tex <- kbl(sde_dt, format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Standardized Effect Sizes",
    label = "tab:sde") |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = c(
    "Standardized effect sizes computed as SDE = $\\hat{\\beta} \\times$ SD(X) / SD(Y) for",
    "continuous treatment. Treatment is the county-level share of restricted-origin foreign-born",
    "in 1920 (SD = ", sprintf("%.3f", sd_x), "). Classification refers to the magnitude of the",
    "standardized effect. Data: IPUMS MLP v2 linked 1920--1930",
    sprintf("panel, N = %s native-born men.", format(nrow(dt), big.mark = ",")),
    "Method: individual-level continuous-treatment DiD with county-level quota exposure."),
    threeparttable = TRUE, escape = FALSE)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
for (f in list.files(tables_dir)) {
  cat(sprintf("  %s\n", f))
}
