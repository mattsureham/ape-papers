## 05_tables.R — Generate all LaTeX tables
## APEP-1116: The Patent Office Lottery

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- fread(file.path(data_dir, "analysis_sample.csv"))
main <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

df_reassigned <- df[reassigned == 1]

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics...\n")

stats <- data.frame(
  Variable = c(
    "Child granted", "Parent granted", "Discordant outcome",
    "Reassigned (diff. examiner)", "Small entity",
    "Examiner grant rate (LOO)", "Filing year"
  ),
  N = format(c(
    nrow(df), nrow(df), nrow(df),
    nrow(df), nrow(df),
    sum(!is.na(df$child_exam_loo_rate)), nrow(df)
  ), big.mark = ","),
  Mean = sprintf("%.3f", c(
    mean(df$child_granted), mean(df$parent_granted), mean(df$discordant),
    mean(df$reassigned), mean(df$small_entity),
    mean(df$child_exam_loo_rate, na.rm = TRUE), mean(df$child_filing_year)
  )),
  SD = sprintf("%.3f", c(
    sd(df$child_granted), sd(df$parent_granted), sd(df$discordant),
    sd(df$reassigned), sd(df$small_entity),
    sd(df$child_exam_loo_rate, na.rm = TRUE), sd(df$child_filing_year)
  ))
)

tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Patent Continuation Twin Pairs}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & N & Mean & SD \\\\",
  "\\hline",
  paste0(stats$Variable, " & ", stats$N, " & ", stats$Mean, " & ", stats$SD, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Same-art-unit continuation and divisional application pairs filed 1998--2015 with resolved outcomes (issued or abandoned). Examiner grant rate is leave-one-out.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Discordance Rates — The Core Fact
# ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Discordance Rates...\n")

# Compute discordance by reassignment × entity size
disc_table <- df[, .(
  N = .N,
  Discordance = sprintf("%.3f", mean(discordant)),
  `Child Grant` = sprintf("%.3f", mean(child_granted))
), by = .(Reassigned = ifelse(reassigned == 1, "Different examiner", "Same examiner"),
          Entity = ifelse(small_entity == 1, "Small", "Large"))]

# Overall row
disc_overall <- df[, .(
  N = .N,
  Discordance = sprintf("%.3f", mean(discordant)),
  `Child Grant` = sprintf("%.3f", mean(child_granted))
), by = .(Reassigned = ifelse(reassigned == 1, "Different examiner", "Same examiner"))]

# Excess discordance
excess <- mean(df$discordant[df$reassigned == 1]) - mean(df$discordant[df$reassigned == 0])
# SE via regression
reg_excess <- feols(discordant ~ reassigned | au_year, data = df, vcov = ~child_art_unit)
excess_se <- coeftable(reg_excess)["reassigned", "Std. Error"]

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Discordance Rates by Examiner Reassignment and Entity Size}",
  "\\label{tab:discordance}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{All Pairs} & \\multicolumn{2}{c}{By Entity Size} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & N & Discordance & Small & Large \\\\",
  "\\hline",
  sprintf("\\textit{Panel A: Levels} & & & & \\\\"),
  sprintf("Different examiner & %s & %s & %s & %s \\\\",
          format(disc_overall$N[disc_overall$Reassigned == "Different examiner"], big.mark = ","),
          disc_overall$Discordance[disc_overall$Reassigned == "Different examiner"],
          disc_table$Discordance[disc_table$Reassigned == "Different examiner" & disc_table$Entity == "Small"],
          disc_table$Discordance[disc_table$Reassigned == "Different examiner" & disc_table$Entity == "Large"]),
  sprintf("Same examiner & %s & %s & %s & %s \\\\",
          format(disc_overall$N[disc_overall$Reassigned == "Same examiner"], big.mark = ","),
          disc_overall$Discordance[disc_overall$Reassigned == "Same examiner"],
          disc_table$Discordance[disc_table$Reassigned == "Same examiner" & disc_table$Entity == "Small"],
          disc_table$Discordance[disc_table$Reassigned == "Same examiner" & disc_table$Entity == "Large"]),
  "\\hline",
  sprintf("\\textit{Panel B: Difference} & & & & \\\\"),
  sprintf("Excess discordance & & %s & & \\\\", sprintf("%.3f", excess)),
  sprintf(" & & (%s) & & \\\\", sprintf("%.3f", excess_se)),
  "\\hline",
  sprintf("Art unit $\\times$ year FE & & Yes & & \\\\"),
  sprintf("Clustered SE (art unit) & & Yes & & \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Discordance means the child and parent applications received different dispositions (one issued, one abandoned). Panel B reports the coefficient on a reassignment indicator from a regression of discordance on reassignment with art-unit $\\times$ filing-year fixed effects. Standard errors clustered at the art-unit level in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_tex, file.path(tables_dir, "tab2_discordance.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: Balance Tests
# ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Balance Tests...\n")

etable(main$bal_small, main$bal_parent_grant,
       file = file.path(tables_dir, "tab3_balance_raw.tex"),
       style.tex = style.tex("aer"),
       title = "Balance Tests: Examiner Leniency and Observable Characteristics",
       label = "tab:balance",
       headers = c("Small Entity", "Parent Granted"),
       notes = "Dependent variable: child examiner leave-one-out grant rate. Sample restricted to reassigned same-art-unit pairs. Art-unit $\\times$ filing-year fixed effects. Standard errors clustered at the examiner level.",
       fitstat = ~ n + r2)

# Manual table for cleaner control
bal1 <- coeftable(main$bal_small)
bal2 <- coeftable(main$bal_parent_grant)

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Balance Tests: Examiner Leniency and Observable Characteristics}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Dep. var.: Examiner leniency (LOO)} \\\\",
  "\\cmidrule(lr){2-3}",
  " & (1) & (2) \\\\",
  "\\hline",
  sprintf("Small entity & %s & \\\\", sprintf("%.4f", bal1["small_entity", "Estimate"])),
  sprintf(" & (%s) & \\\\", sprintf("%.4f", bal1["small_entity", "Std. Error"])),
  sprintf("Parent granted & & %s \\\\", sprintf("%.4f", bal2["parent_granted", "Estimate"])),
  sprintf(" & & (%s) \\\\", sprintf("%.4f", bal2["parent_granted", "Std. Error"])),
  "\\hline",
  "Art unit $\\times$ year FE & Yes & Yes \\\\",
  sprintf("N & %s & %s \\\\",
          format(main$bal_small$nobs, big.mark = ","),
          format(main$bal_parent_grant$nobs, big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f \\\\",
          fitstat(main$bal_small, "r2")$r2,
          fitstat(main$bal_parent_grant, "r2")$r2),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is the child examiner's leave-one-out grant rate. Sample restricted to reassigned same-art-unit continuation pairs. Standard errors clustered at the examiner level in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_balance.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 4: Main Results — Examiner Leniency and Grant Outcomes
# ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Main Results...\n")

rf_coef <- coeftable(main$rf)
iv_coef <- coeftable(main$main_iv)
interact_coef <- coeftable(main$main_interact)

tab4_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Examiner Leniency and Patent Grant Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Dep. var.: Child application granted} \\\\",
  "\\cmidrule(lr){2-4}",
  " & (1) & (2) & (3) \\\\",
  " & Reassigned & Reassigned & Full sample \\\\",
  "\\hline",
  sprintf("Examiner leniency (LOO) & %s & %s & %s \\\\",
          sprintf("%.3f", rf_coef["child_exam_loo_rate", "Estimate"]),
          sprintf("%.3f", iv_coef["child_exam_loo_rate", "Estimate"]),
          sprintf("%.3f", interact_coef["child_exam_loo_rate", "Estimate"])),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
          sprintf("%.3f", rf_coef["child_exam_loo_rate", "Std. Error"]),
          sprintf("%.3f", iv_coef["child_exam_loo_rate", "Std. Error"]),
          sprintf("%.3f", interact_coef["child_exam_loo_rate", "Std. Error"])),
  sprintf("Parent granted & %s & & %s \\\\",
          sprintf("%.3f", rf_coef["parent_granted", "Estimate"]),
          sprintf("%.3f", interact_coef["parent_granted", "Estimate"])),
  sprintf(" & (%s) & & (%s) \\\\",
          sprintf("%.3f", rf_coef["parent_granted", "Std. Error"]),
          sprintf("%.3f", interact_coef["parent_granted", "Std. Error"])),
  sprintf("Reassigned & & & %s \\\\",
          sprintf("%.3f", interact_coef["reassigned", "Estimate"])),
  sprintf(" & & & (%s) \\\\",
          sprintf("%.3f", interact_coef["reassigned", "Std. Error"])),
  "\\hline",
  "Art unit $\\times$ year FE & Yes & Yes & Yes \\\\",
  "Parent outcome control & Yes & No & Yes \\\\",
  sprintf("N & %s & %s & %s \\\\",
          format(main$rf$nobs, big.mark = ","),
          format(main$main_iv$nobs, big.mark = ","),
          format(main$main_interact$nobs, big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\",
          fitstat(main$rf, "r2")$r2,
          fitstat(main$main_iv, "r2")$r2,
          fitstat(main$main_interact, "r2")$r2),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Examiner leniency is the leave-one-out grant rate of the child application's examiner. Column (1) controls for parent outcome; column (2) omits parent control; column (3) includes the full sample with a reassignment indicator and its interaction with leniency. Standard errors clustered at the examiner level in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_main.tex"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 5: Robustness — Technology, Time, Application Type
# ═══════════════════════════════════════════════════════════════════════
cat("Generating Table 5: Robustness...\n")

coef_extract <- function(mod, var = "child_exam_loo_rate") {
  ct <- coeftable(mod)
  list(
    est = sprintf("%.3f", ct[var, "Estimate"]),
    se = sprintf("%.3f", ct[var, "Std. Error"]),
    n = format(mod$nobs, big.mark = ",")
  )
}

ce_con <- coef_extract(robust$r_con)
ce_div <- coef_extract(robust$r_div)
ce_early <- coef_extract(robust$r_early)
ce_late <- coef_extract(robust$r_late)
ce_pgrant <- coef_extract(robust$r_parent_grant)
ce_pabn <- coef_extract(robust$r_parent_abn)
ce_z <- coef_extract(robust$r_z, "leniency_z")

tab5_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Examiner Leniency Effect Across Subsamples}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Coefficient & SE & N \\\\",
  "\\hline",
  "\\textit{Panel A: Application type} & & & \\\\",
  sprintf("Continuations (CON) & %s & (%s) & %s \\\\", ce_con$est, ce_con$se, ce_con$n),
  sprintf("Divisionals (DIV) & %s & (%s) & %s \\\\", ce_div$est, ce_div$se, ce_div$n),
  "\\hline",
  "\\textit{Panel B: Time period} & & & \\\\",
  sprintf("Early (1998--2006) & %s & (%s) & %s \\\\", ce_early$est, ce_early$se, ce_early$n),
  sprintf("Late (2007--2015) & %s & (%s) & %s \\\\", ce_late$est, ce_late$se, ce_late$n),
  "\\hline",
  "\\textit{Panel C: Parent outcome} & & & \\\\",
  sprintf("Parent granted & %s & (%s) & %s \\\\", ce_pgrant$est, ce_pgrant$se, ce_pgrant$n),
  sprintf("Parent abandoned & %s & (%s) & %s \\\\", ce_pabn$est, ce_pabn$se, ce_pabn$n),
  "\\hline",
  "\\textit{Panel D: Alternative leniency} & & & \\\\",
  sprintf("Standardized (within AU$\\times$year) & %s & (%s) & %s \\\\", ce_z$est, ce_z$se, ce_z$n),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each row reports the coefficient on examiner leniency from a regression of child grant outcome on examiner leniency with art-unit $\\times$ filing-year fixed effects. Sample restricted to reassigned same-art-unit pairs unless noted. Standard errors clustered at the examiner level in parentheses. Panel D reports the coefficient on within-AU$\\times$year standardized leniency.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab5_tex, file.path(tables_dir, "tab5_robustness.tex"))

# ═══════════════════════════════════════════════════════════════════════
# SDE TABLE (Appendix — Mandatory)
# ═══════════════════════════════════════════════════════════════════════
cat("Generating SDE table...\n")

# Main outcomes for SDE:
# 1. Child granted (main effect of leniency on grant)
# 2. Discordant outcome (effect of reassignment on discordance)
# 3. Child granted — small entities
# 4. Child granted — large entities

# Pre-treatment SD of outcomes
sd_grant <- sd(df$child_granted)
sd_discord <- sd(df$discordant)
sd_grant_small <- sd(df$child_granted[df$small_entity == 1])
sd_grant_large <- sd(df$child_granted[df$small_entity == 0])

# Leniency is continuous → SDE = β × SD(X) / SD(Y)
sd_leniency <- sd(df_reassigned$child_exam_loo_rate, na.rm = TRUE)

# Main leniency effect on grant
beta_grant <- coef(main$main_iv)["child_exam_loo_rate"]
se_grant <- coeftable(main$main_iv)["child_exam_loo_rate", "Std. Error"]
sde_grant <- beta_grant * sd_leniency / sd_grant
se_sde_grant <- se_grant * sd_leniency / sd_grant

# Reassignment effect on discordance (binary treatment)
beta_discord <- coef(main$main_discord)["reassigned"]
se_discord <- coeftable(main$main_discord)["reassigned", "Std. Error"]
sde_discord <- beta_discord / sd_discord
se_sde_discord <- se_discord / sd_discord

# Small entity leniency effect
beta_small <- coef(main$iv_small)["child_exam_loo_rate"]
se_small <- coeftable(main$iv_small)["child_exam_loo_rate", "Std. Error"]
sd_leniency_small <- sd(df_reassigned$child_exam_loo_rate[df_reassigned$small_entity == 1], na.rm = TRUE)
sde_small <- beta_small * sd_leniency_small / sd_grant_small
se_sde_small <- se_small * sd_leniency_small / sd_grant_small

# Large entity leniency effect
beta_large <- coef(main$iv_large)["child_exam_loo_rate"]
se_large <- coeftable(main$iv_large)["child_exam_loo_rate", "Std. Error"]
sd_leniency_large <- sd(df_reassigned$child_exam_loo_rate[df_reassigned$small_entity == 0], na.rm = TRUE)
sde_large <- beta_large * sd_leniency_large / sd_grant_large
se_sde_large <- se_large * sd_leniency_large / sd_grant_large

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

sde_rows <- data.frame(
  Outcome = c("Child application granted", "Discordant outcome",
              "Child granted (small entity)", "Child granted (large entity)"),
  Beta = c(beta_grant, beta_discord, beta_small, beta_large),
  SE = c(se_grant, se_discord, se_small, se_large),
  SD_Y = c(sd_grant, sd_discord, sd_grant_small, sd_grant_large),
  SDE = c(sde_grant, sde_discord, sde_small, sde_large),
  SE_SDE = c(se_sde_grant, se_sde_discord, se_sde_small, se_sde_large),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does quasi-random reassignment of continuation patent applications to different examiners within the same art unit cause inconsistent grant outcomes, and do small entities bear disproportionate costs? ",
  "\\textbf{Policy mechanism:} When inventors file continuation or divisional applications at the USPTO, workload-balancing reassignment exposes the same invention family to different examiners with heterogeneous grant propensities, creating a regulatory lottery that randomly reallocates patent rights. ",
  "\\textbf{Outcome definition:} Child application granted is a binary indicator equal to one if the continuation application was issued as a patent (disposal type ISS). Discordant outcome equals one if parent and child received different dispositions. ",
  "\\textbf{Treatment:} Continuous examiner leave-one-out grant rate for rows 1, 3, 4; binary reassignment indicator for row 2. ",
  sprintf("\\textbf{Data:} USPTO PAIR via Google BigQuery, 1998--2015 filing years, application-pair level, %s same-art-unit pairs. ",
          format(nrow(df), big.mark = ",")),
  "\\textbf{Method:} OLS with art-unit $\\times$ filing-year fixed effects, standard errors clustered at examiner level (rows 1, 3, 4) or art-unit level (row 2). ",
  "\\textbf{Sample:} Continuation (CON) and divisional (DIV) applications with resolved outcomes (issued or abandoned) where both parent and child are in the same art unit. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, ",
  "$\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Generate table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)
for (i in 1:2) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
            sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
            sde_rows$Classification[i]))
}
sde_lines <- c(sde_lines,
  "\\hline",
  "\\textit{Panel B: Heterogeneous (entity size)} & & & & & & \\\\"
)
for (i in 3:4) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_rows$Outcome[i], sde_rows$Beta[i], sde_rows$SE[i],
            sde_rows$SD_Y[i], sde_rows$SDE[i], sde_rows$SE_SDE[i],
            sde_rows$Classification[i]))
}
sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
