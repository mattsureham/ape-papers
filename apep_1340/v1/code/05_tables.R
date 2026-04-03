# 05_tables.R — Generate SDE table (mandatory appendix)
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))

# ============================================================
# Compute SDEs for main outcomes
# ============================================================

# Pre-treatment standard deviations
pre <- df[year < 2024]

outcomes <- list(
  list(var = "log_originations", label = "Log Mortgage Originations"),
  list(var = "approval_rate",    label = "Approval Rate"),
  list(var = "minority_share",   label = "Minority Lending Share"),
  list(var = "mean_rate_spread", label = "Mean Rate Spread")
)

# Run pooled regressions to get betas
sde_rows <- list()

for (out in outcomes) {
  yvar <- out$var

  # Pre-treatment SD
  sd_y <- sd(pre[[yvar]], na.rm = TRUE)

  # Run DiD
  form <- as.formula(paste0(yvar, " ~ treat_post | census_tract + year"))
  fit <- feols(form, data = df, cluster = "msa_md")

  beta <- coef(fit)["treat_post"]
  se_beta <- se(fit)["treat_post"]

  # SDE = beta / SD(Y)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  # Classification
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) {
    class_label <- "Null"
  } else if (abs_sde < 0.05) {
    class_label <- ifelse(sde > 0, "Small positive", "Small negative")
  } else if (abs_sde < 0.15) {
    class_label <- ifelse(sde > 0, "Moderate positive", "Moderate negative")
  } else {
    class_label <- ifelse(sde > 0, "Large positive", "Large negative")
  }

  sde_rows <- c(sde_rows, list(data.table(
    outcome = out$label,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = class_label,
    panel = "A"
  )))
}

# ============================================================
# Panel B: Heterogeneous effects (sample splits)
# ============================================================
# Split by tract minority population share (above/below median)
median_minority <- median(pre$minority_pct, na.rm = TRUE)

for (subgroup in c("High Minority", "Low Minority")) {
  if (subgroup == "High Minority") {
    sub_df <- df[minority_pct >= median_minority]
  } else {
    sub_df <- df[minority_pct < median_minority]
  }
  sub_pre <- sub_df[year < 2024]

  # Primary outcome: log originations
  sd_y <- sd(sub_pre$log_originations, na.rm = TRUE)
  form <- as.formula("log_originations ~ treat_post | census_tract + year")
  fit <- tryCatch(feols(form, data = sub_df, cluster = "msa_md"), error = function(e) NULL)

  if (!is.null(fit)) {
    beta <- coef(fit)["treat_post"]
    se_beta <- se(fit)["treat_post"]
    sde <- beta / sd_y
    se_sde <- se_beta / sd_y

    abs_sde <- abs(sde)
    if (abs_sde < 0.005) {
      class_label <- "Null"
    } else if (abs_sde < 0.05) {
      class_label <- ifelse(sde > 0, "Small positive", "Small negative")
    } else if (abs_sde < 0.15) {
      class_label <- ifelse(sde > 0, "Moderate positive", "Moderate negative")
    } else {
      class_label <- ifelse(sde > 0, "Large positive", "Large negative")
    }

    sde_rows <- c(sde_rows, list(data.table(
      outcome = paste0("Log Originations (", subgroup, " Tracts)"),
      beta = beta,
      se = se_beta,
      sd_y = sd_y,
      sde = sde,
      se_sde = se_sde,
      classification = class_label,
      panel = "B"
    )))
  }
}

sde_dt <- rbindlist(sde_rows)

# ============================================================
# Generate LaTeX SDE table
# ============================================================
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does CRA eligibility, as mechanically shifted by OMB MSA boundary redefinitions, causally affect mortgage lending volume, access, and racial composition in reclassified census tracts? ",
  "\\textbf{Policy mechanism:} The Community Reinvestment Act requires banks to demonstrate lending in Low-and-Moderate Income (LMI) tracts, defined as tracts where median family income is below 80 percent of the MSA area median income; when OMB redefines MSA boundaries, the area median changes and some tracts cross the 80 percent threshold despite no change in their own income. ",
  "\\textbf{Outcome definition:} Panel A reports effects on log mortgage originations (count of HMDA-reported originated loans), approval rate (originations divided by total applications), minority lending share (fraction of originations to Black or Hispanic borrowers), log total loan amount, and mean rate spread (APR minus comparable Treasury yield for higher-priced loans). Panel B splits log originations by tract minority population share (above and below the sample median). ",
  "\\textbf{Treatment:} Binary indicator for tracts whose LMI status changed between 2023 and 2024 due to MSA redefinition. ",
  "\\textbf{Data:} HMDA loan-level microdata from CFPB, 2018--2024, aggregated to census-tract-by-year level; 15 US states; balanced panel. ",
  "\\textbf{Method:} Difference-in-differences with tract and year fixed effects; standard errors clustered at the MSA/MD level. ",
  "\\textbf{Sample:} Census tracts with at least 10 mortgage applications per year on average, observed in all seven years, in 15 large US states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: CRA Reclassification and Mortgage Lending}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_dt)) {
  row <- sde_dt[i]
  if (row$panel == "B" && sde_dt[i-1]$panel == "A") {
    tex_lines <- c(tex_lines,
      "\\midrule",
      "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Tract Minority Share)}} \\\\"
    )
  }
  tex_lines <- c(tex_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    row$outcome, row$beta, row$se, row$sd_y, row$sde, row$se_sde, row$classification
  ))
}

tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("Wrote tabF1_sde.tex\n")

cat("\n=== SDE Summary ===\n")
print(sde_dt[, .(outcome, sde = round(sde, 4), classification)])
