# ==============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE
# Paper: Flood, Flight, and Fortune (apep_1287)
# ==============================================================================

source("00_packages.R")

load("../data/main_models.RData")
load("../data/robustness_models.RData")
black <- arrow::read_parquet("../data/analysis_black.parquet")

# --------------------------------------------------------------------------
# Table 1: Summary Statistics
# --------------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

summ_vars <- c("occscore_1920", "sei_1920", "age_1920", "mover_20_30",
               "occscore_1930", "occscore_1940", "sei_1930", "sei_1940")

# Compute summary stats by flood exposure
summ_list <- lapply(c("All", "Flood-Exposed", "Non-Flood"), function(grp) {
  if (grp == "All") d <- black
  else if (grp == "Flood-Exposed") d <- black[black$flood_exposed == 1, ]
  else d <- black[black$flood_exposed == 0, ]

  stats <- sapply(summ_vars, function(v) {
    x <- d[[v]]
    c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))
  })
  data.frame(
    Variable = summ_vars,
    Mean = sprintf("%.2f", stats["mean", ]),
    SD = sprintf("%.2f", stats["sd", ]),
    N = nrow(d)
  )
})

# Build LaTeX table
var_labels <- c(
  "Occupational Score (1920)", "Socioeconomic Index (1920)", "Age (1920)",
  "Migrated 1920--1930", "Occupational Score (1930)", "Occupational Score (1940)",
  "Socioeconomic Index (1930)", "Socioeconomic Index (1940)"
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Black Farm Workers in the Mississippi Delta, 1920}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{All} & \\multicolumn{1}{c}{Flood} & \\multicolumn{1}{c}{No Flood} & \\multicolumn{1}{c}{Diff.} \\\\",
  " & Mean & SD & Mean & Mean & (SE) \\\\",
  "\\midrule"
)

for (i in seq_along(summ_vars)) {
  v <- summ_vars[i]
  all_mean <- mean(black[[v]], na.rm = TRUE)
  all_sd <- sd(black[[v]], na.rm = TRUE)
  flood_mean <- mean(black[[v]][black$flood_exposed == 1], na.rm = TRUE)
  noflood_mean <- mean(black[[v]][black$flood_exposed == 0], na.rm = TRUE)
  # Difference with clustered SE
  m <- feols(as.formula(paste(v, "~ flood_exposed")), data = black,
             cluster = ~county_id)
  diff_coef <- coef(m)["flood_exposed"]
  diff_se <- se(m)["flood_exposed"]

  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.2f & %.2f & %.2f & %.2f & %.3f \\\\",
    var_labels[i], all_mean, all_sd, flood_mean, noflood_mean, diff_coef
  ))
  tab1_lines <- c(tab1_lines, sprintf(
    " & & & & & (%.3f) \\\\", diff_se
  ))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & %s & & %s & %s & \\\\",
          format(nrow(black), big.mark = ","),
          format(sum(black$flood_exposed == 1), big.mark = ","),
          format(sum(black$flood_exposed == 0), big.mark = ",")),
  sprintf("Counties & %d & & %d & %d & \\\\",
          length(unique(black$county_id)),
          length(unique(black$county_id[black$flood_exposed == 1])),
          length(unique(black$county_id[black$flood_exposed == 0]))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize",
  "\\textit{Notes:} Sample is Black farm workers aged 15--60 in 1920, residing in Mississippi, Arkansas, or Louisiana, and linked across the 1920, 1930, and 1940 censuses via the IPUMS Multigenerational Longitudinal Panel (MLP). Flood-exposed counties are those in the Mississippi Alluvial Plain, which experienced severe inundation during the 1927 Great Mississippi Flood. Differences are estimated via OLS with standard errors clustered by 1920 county of residence.",
  "}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")

# --------------------------------------------------------------------------
# Table 2: First Stage + Reduced Form + IV
# --------------------------------------------------------------------------
cat("Generating Table 2: Main Results...\n")

# Use etable from fixest for clean output
etable(fs_full, rf_occ30, rf_occ40, rf_farm30,
       iv_occ30, iv_occ40, iv_farm30,
       headers = c("First Stage", "RF: ΔOcc30", "RF: ΔOcc40", "RF: Left Farm",
                    "IV: ΔOcc30", "IV: ΔOcc40", "IV: Left Farm"),
       se.below = TRUE,
       fitstat = c("n", "r2", "ivf"),
       dict = c(flood_exposed = "Flood Exposed",
                fit_mover_20_30 = "Migration (IV)",
                mover_20_30 = "Migration",
                occscore_1920 = "Occ. Score 1920",
                sei_1920 = "SEI 1920"),
       tex = TRUE,
       file = "../tables/tab2_main_results.tex",
       replace = TRUE,
       title = "The Effect of Flood-Induced Migration on Occupational Trajectories",
       label = "tab:main",
       notes = c(
         "Sample: Black farm workers aged 15--60 in 1920, Mississippi/Arkansas/Louisiana.",
         "Flood Exposed = 1 for counties in the Mississippi Alluvial Plain.",
         "All specifications include age fixed effects and control for pre-flood",
         "occupational score and socioeconomic index. Standard errors clustered by",
         "1920 county of residence. Columns 5--7 instrument migration with flood exposure."
       ))

# --------------------------------------------------------------------------
# Table 3: Robustness — LIML, White falsification, and heterogeneity
# --------------------------------------------------------------------------
cat("Generating Table 3: Robustness...\n")

# Manually build robustness table
tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness and Falsification Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & $\\Delta$OccScore & $\\Delta$OccScore & $\\Delta$SEI & $\\Delta$SEI \\\\",
  " & (1930) & (1940) & (1930) & (1940) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Main IV (2SLS)}} \\\\"
)

# Main IV results
iv_coefs <- c(coef(iv_occ30)["fit_mover_20_30"],
              coef(iv_occ40)["fit_mover_20_30"],
              coef(iv_sei30)["fit_mover_20_30"],
              coef(iv_sei40)["fit_mover_20_30"])
iv_ses <- c(se(iv_occ30)["fit_mover_20_30"],
            se(iv_occ40)["fit_mover_20_30"],
            se(iv_sei30)["fit_mover_20_30"],
            se(iv_sei40)["fit_mover_20_30"])

tab3_lines <- c(tab3_lines,
  sprintf("Migration (IV) & %.3f & %.3f & %.3f & %.3f \\\\",
          iv_coefs[1], iv_coefs[2], iv_coefs[3], iv_coefs[4]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          iv_ses[1], iv_ses[2], iv_ses[3], iv_ses[4]),
  sprintf("First-stage $F$ & %.1f & %.1f & %.1f & %.1f \\\\",
          fitstat(iv_occ30, "ivf")$ivf1$stat,
          fitstat(iv_occ40, "ivf")$ivf1$stat,
          fitstat(iv_sei30, "ivf")$ivf1$stat,
          fitstat(iv_sei40, "ivf")$ivf1$stat),
  sprintf("$N$ & %s & %s & %s & %s \\\\",
          format(nobs(iv_occ30), big.mark = ","),
          format(nobs(iv_occ40), big.mark = ","),
          format(nobs(iv_sei30), big.mark = ","),
          format(nobs(iv_sei40), big.mark = ",")),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Without Age Fixed Effects}} \\\\"
)

# Alternative specification (without age FE) results
liml_c30 <- coef(liml_occ30)["mover_20_30"]
liml_s30 <- liml_occ30$std.error["mover_20_30"]
liml_c40 <- coef(liml_occ40)["mover_20_30"]
liml_s40 <- liml_occ40$std.error["mover_20_30"]

tab3_lines <- c(tab3_lines,
  sprintf("Migration (IV, no age FE) & %.3f & %.3f & --- & --- \\\\",
          liml_c30, liml_c40),
  sprintf(" & (%.3f) & (%.3f) & & \\\\",
          liml_s30, liml_s40),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel C: Falsification --- White Farm Workers}} \\\\"
)

# White falsification
if (!is.null(iv_white_occ30) && !is.null(iv_white_occ40)) {
  tab3_lines <- c(tab3_lines,
    sprintf("Migration (IV) & %.3f & %.3f & --- & --- \\\\",
            coef(iv_white_occ30)["fit_mover_20_30"],
            coef(iv_white_occ40)["fit_mover_20_30"]),
    sprintf(" & (%.3f) & (%.3f) & & \\\\",
            se(iv_white_occ30)["fit_mover_20_30"],
            se(iv_white_occ40)["fit_mover_20_30"])
  )
} else {
  # Report reduced form if first stage is weak
  tab3_lines <- c(tab3_lines,
    sprintf("Flood Exposed (RF) & %.3f & %.3f & --- & --- \\\\",
            coef(rf_white_occ30)["flood_exposed"],
            coef(rf_white_occ40)["flood_exposed"]),
    sprintf(" & (%.3f) & (%.3f) & & \\\\",
            se(rf_white_occ30)["flood_exposed"],
            se(rf_white_occ40)["flood_exposed"])
  )
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel D: Leave-One-County-Out}} \\\\",
  sprintf("Coefficient range & [%.2f, %.2f] & & & \\\\",
          min(loo_df$coef), max(loo_df$coef)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize",
  "\\textit{Notes:} Panel A replicates the main 2SLS specification. Panel B reports IV estimates without age fixed effects to assess sensitivity. Panel C runs the identical specification on white farm workers in the same counties as a falsification test --- if the flood instrument operates through race-specific labor market mechanisms (the sharecropping trap), white workers should show different or null effects. Panel D shows the range of the IV coefficient for $\\Delta$OccScore (1940) when each county is dropped in turn. All Panel A specifications include age fixed effects and pre-flood controls.",
  "}",
  "\\end{table}"
)
writeLines(tab3_lines, "../tables/tab3_robustness.tex")

# --------------------------------------------------------------------------
# Table 4: Heterogeneity by age and pre-flood status
# --------------------------------------------------------------------------
cat("Generating Table 4: Heterogeneity...\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity in the Effect of Flood-Induced Migration}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & $\\Delta$OccScore (1940) & $N$ \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: By Age at Displacement}} \\\\"
)

if (!is.null(age_het_df) && nrow(age_het_df) > 0) {
  for (i in 1:nrow(age_het_df)) {
    tab4_lines <- c(tab4_lines,
      sprintf("Age %s & %.3f & %s \\\\",
              age_het_df$age_bin[i],
              age_het_df$coef[i],
              format(age_het_df$n[i], big.mark = ",")),
      sprintf(" & (%.3f) & \\\\", age_het_df$se[i])
    )
  }
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: By Pre-Flood Occupational Status}} \\\\"
)

if (!is.null(status_het_df) && nrow(status_het_df) > 0) {
  for (i in 1:nrow(status_het_df)) {
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.3f & %s \\\\",
              status_het_df$group[i],
              status_het_df$coef[i],
              format(status_het_df$n[i], big.mark = ",")),
      sprintf(" & (%.3f) & \\\\", status_het_df$se[i])
    )
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize",
  "\\textit{Notes:} Each row reports the IV coefficient on migration (instrumented by flood exposure) from a separate 2SLS regression on the indicated subsample. The dependent variable is the change in occupational earnings score between 1920 and 1940. Panel A splits the sample by age in 1920 to test whether younger workers benefited more from flood-induced displacement. Panel B splits at the median pre-flood occupational score to test whether higher-status workers had more transferable skills. All specifications include age fixed effects and pre-flood controls. Standard errors clustered by 1920 county of residence.",
  "}",
  "\\end{table}"
)
writeLines(tab4_lines, "../tables/tab4_heterogeneity.tex")

# --------------------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# --------------------------------------------------------------------------
cat("Generating Table F1: SDE...\n")

# Pre-treatment (1920) standard deviations for SDE denominator
sd_occ <- sd(black$occscore_1920, na.rm = TRUE)
sd_sei <- sd(black$sei_1920, na.rm = TRUE)

# Compute pre-treatment SD for change variables (use control group SD)
control <- black[black$flood_exposed == 0, ]
sd_delta_occ30 <- sd(control$delta_occ_30, na.rm = TRUE)
sd_delta_occ40 <- sd(control$delta_occ_40, na.rm = TRUE)
sd_delta_sei30 <- sd(control$delta_sei_30, na.rm = TRUE)
sd_delta_sei40 <- sd(control$delta_sei_40, na.rm = TRUE)
sd_farm30 <- sd(control$left_farm_30, na.rm = TRUE)
sd_farm40 <- sd(control$left_farm_40, na.rm = TRUE)

# IV coefficients and SEs
# Max 6 rows total (4 pooled + 2 heterogeneous)
outcomes <- list(
  list(name = "$\\Delta$Occ.~Score (1940)", model = iv_occ40,
       sd_y = sd_delta_occ40),
  list(name = "$\\Delta$SEI (1940)", model = iv_sei40,
       sd_y = sd_delta_sei40),
  list(name = "Left Farm (1930)", model = iv_farm30,
       sd_y = sd_farm30),
  list(name = "Left Farm (1940)", model = iv_farm40,
       sd_y = sd_farm40)
)

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows_pooled <- lapply(outcomes, function(o) {
  beta <- coef(o$model)["fit_mover_20_30"]
  se_beta <- se(o$model)["fit_mover_20_30"]
  sde <- beta / o$sd_y
  se_sde <- se_beta / o$sd_y
  data.frame(
    outcome = o$name,
    beta = beta,
    se = se_beta,
    sd_y = o$sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify_sde(sde)
  )
})
sde_pooled <- do.call(rbind, sde_rows_pooled)

# Panel B: Heterogeneous (by age — young vs. old)
young <- black[black$age_1920 <= 30, ]
old <- black[black$age_1920 > 30, ]

young$delta_occ_40 <- young$occscore_1940 - young$occscore_1920
old$delta_occ_40 <- old$occscore_1940 - old$occscore_1920

iv_young <- tryCatch(
  feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
          mover_20_30 ~ flood_exposed,
        data = young, cluster = ~county_id),
  error = function(e) NULL
)
iv_old <- tryCatch(
  feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
          mover_20_30 ~ flood_exposed,
        data = old, cluster = ~county_id),
  error = function(e) NULL
)

sd_y_young <- sd(young$delta_occ_40[young$flood_exposed == 0], na.rm = TRUE)
sd_y_old <- sd(old$delta_occ_40[old$flood_exposed == 0], na.rm = TRUE)

sde_rows_het <- list()
if (!is.null(iv_young)) {
  b <- coef(iv_young)["fit_mover_20_30"]
  s <- se(iv_young)["fit_mover_20_30"]
  sde_rows_het[[1]] <- data.frame(
    outcome = "$\\Delta$Occ.~Score (1940), Age $\\leq$ 30",
    beta = b, se = s, sd_y = sd_y_young,
    sde = b / sd_y_young, se_sde = s / sd_y_young,
    classification = classify_sde(b / sd_y_young)
  )
}
if (!is.null(iv_old)) {
  b <- coef(iv_old)["fit_mover_20_30"]
  s <- se(iv_old)["fit_mover_20_30"]
  sde_rows_het[[2]] <- data.frame(
    outcome = "$\\Delta$Occ.~Score (1940), Age $>$ 30",
    beta = b, se = s, sd_y = sd_y_old,
    sde = b / sd_y_old, se_sde = s / sd_y_old,
    classification = classify_sde(b / sd_y_old)
  )
}
sde_het <- do.call(rbind, sde_rows_het)

# Build SDE LaTeX table
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did flood-induced displacement during the 1927 Great Mississippi Flood ",
  "improve or worsen the long-run occupational trajectories of Black farm workers in the Mississippi Delta? ",
  "\\textbf{Policy mechanism:} The 1927 flood caused catastrophic levee failures across the Mississippi ",
  "Alluvial Plain, forcing displacement of sharecroppers and farm laborers from cotton counties to ",
  "northern and urban labor markets with higher returns to labor, potentially breaking the sharecropping trap. ",
  "\\textbf{Outcome definition:} Change in IPUMS occupational earnings score (occscore) between 1920 and ",
  "1930 or 1940, measuring movement up the occupational ladder; change in socioeconomic index (SEI); ",
  "binary indicator for exiting farm employment. ",
  "\\textbf{Treatment:} Binary --- individual migrated county of residence between the 1920 and 1930 censuses. ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel (MLP) linking 1920, 1930, and 1940 census ",
  "records at the individual level; county-level flood exposure from Mississippi Alluvial Plain geography ",
  "following Hornbeck and Naidu (2014); sample of Black farm workers aged 15--60 in 1920 in Mississippi, ",
  "Arkansas, and Louisiana. ",
  "\\textbf{Method:} 2SLS/IV with flood exposure (alluvial plain county) as instrument for migration; ",
  "age fixed effects and pre-flood controls; standard errors clustered by 1920 county. ",
  "\\textbf{Sample:} Black male and female farm workers in Delta states, restricted to ages 15--60 and ",
  "successfully linked across three censuses via MLP; linkage rates vary by race and county. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the control-group standard deviation ",
  "of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_pooled)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    sde_pooled$outcome[i], sde_pooled$beta[i], sde_pooled$se[i],
    sde_pooled$sd_y[i], sde_pooled$sde[i], sde_pooled$se_sde[i],
    sde_pooled$classification[i]
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Age Split)}} \\\\"
)

if (!is.null(sde_het) && nrow(sde_het) > 0) {
  for (i in 1:nrow(sde_het)) {
    tabF1_lines <- c(tabF1_lines, sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
      sde_het$outcome[i], sde_het$beta[i], sde_het$se[i],
      sde_het$sd_y[i], sde_het$sde[i], sde_het$se_sde[i],
      sde_het$classification[i]
    ))
  }
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize",
  sde_notes,
  "}",
  "\\end{table}"
)
writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat("Done.\n")
