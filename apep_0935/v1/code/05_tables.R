## 05_tables.R — Generate all LaTeX tables
## APEP-0935: First Step Act Safety Valve and Judge Leniency

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "analysis_df.rds"))
df <- df %>% filter(crim_hist >= 1, crim_hist <= 4)
results <- readRDS(file.path(data_dir, "results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Helper: format stars
add_stars <- function(pv) {
  case_when(pv < 0.01 ~ "***", pv < 0.05 ~ "**", pv < 0.10 ~ "*", TRUE ~ "")
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-FSA vs Post-FSA, by eligibility group
summ_groups <- df %>%
  mutate(
    group = case_when(
      newly_eligible == 1 & post_fsa == 0 ~ "Newly Elig., Pre-FSA",
      newly_eligible == 1 & post_fsa == 1 ~ "Newly Elig., Post-FSA",
      already_eligible == 1 & post_fsa == 0 ~ "Already Elig., Pre-FSA",
      already_eligible == 1 & post_fsa == 1 ~ "Already Elig., Post-FSA",
      TRUE ~ "Other CH"
    )
  ) %>%
  filter(group != "Other CH") %>%
  group_by(group) %>%
  summarise(
    N = n(),
    `Sentence (months)` = sprintf("%.1f", mean(sentence_months, na.rm = TRUE)),
    `SD Sentence` = sprintf("%.1f", sd(sentence_months, na.rm = TRUE)),
    `Safety Valve (\\%)` = sprintf("%.1f", 100*mean(safety_valve, na.rm = TRUE)),
    `Black (\\%)` = sprintf("%.1f", 100*mean(black, na.rm = TRUE)),
    `Hispanic (\\%)` = sprintf("%.1f", 100*mean(hispanic, na.rm = TRUE)),
    `Female (\\%)` = sprintf("%.1f", 100*mean(female, na.rm = TRUE)),
    `Age` = sprintf("%.1f", mean(age, na.rm = TRUE)),
    `Offense Level` = sprintf("%.1f", mean(offense_level, na.rm = TRUE)),
    .groups = "drop"
  )

# Write LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Eligibility Group and Period}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{2}{c}{Newly Eligible (CH II--IV)} & \\multicolumn{2}{c}{Already Eligible (CH I)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Pre-FSA & Post-FSA & Pre-FSA & Post-FSA \\\\\n")
cat("\\midrule\n")

# Order: Newly Pre, Newly Post, Already Pre, Already Post
ordered_groups <- c("Newly Elig., Pre-FSA", "Newly Elig., Post-FSA",
                    "Already Elig., Pre-FSA", "Already Elig., Post-FSA")
sg <- summ_groups
for (i in seq_along(ordered_groups)) {
  sg[sg$group == ordered_groups[i], "order"] <- i
}
sg <- sg %>% arrange(order)

vars <- setdiff(names(sg), c("group", "order"))
for (v in vars) {
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              gsub("_", " ", v),
              sg[[v]][1], sg[[v]][2], sg[[v]][3], sg[[v]][4]))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Sample restricted to federal drug trafficking offenses (USSC primary offense chapters 14--18) in districts with at least 20 pre-FSA cases. ``Newly eligible'' defendants have criminal history category II--IV (2--6 points); these defendants became eligible for the statutory safety valve under the First Step Act (December 2018). ``Already eligible'' defendants have criminal history category I (0--1 points) and were eligible for the safety valve before and after the FSA. Pre-FSA: FY2016--FY2018; Post-FSA: FY2019--FY2024.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main DiD Results ===\n")

models_main <- list(results$m1, results$m2, results$m3, results$m4)
model_names <- c("(1)", "(2)", "(3)", "(4)")

sink(file.path(tables_dir, "tab2_main.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of First Step Act on Sentence Length}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\midrule\n")

# Treatment coefficient
for (i in seq_along(models_main)) {
  m <- models_main[[i]]
  b <- coef(m)["treated"]
  s <- se(m)["treated"]
  p <- pvalue(m)["treated"]
  stars <- add_stars(p)
  if (i == 1) {
    cat(sprintf("Newly Elig. $\\times$ Post-FSA & %.2f%s", b, stars))
  } else {
    cat(sprintf(" & %.2f%s", b, stars))
  }
}
cat(" \\\\\n")

# SEs
for (i in seq_along(models_main)) {
  s <- se(models_main[[i]])["treated"]
  if (i == 1) {
    cat(sprintf(" & (%.2f)", s))
  } else {
    cat(sprintf(" & (%.2f)", s))
  }
}
cat(" \\\\\n")

# N
cat("\\midrule\n")
for (i in seq_along(models_main)) {
  n <- nobs(models_main[[i]])
  if (i == 1) {
    cat(sprintf("N & %s", format(n, big.mark = ",")))
  } else {
    cat(sprintf(" & %s", format(n, big.mark = ",")))
  }
}
cat(" \\\\\n")

# FEs
cat("District FE & Yes & Yes & -- & -- \\\\\n")
cat("Year FE & Yes & Yes & -- & -- \\\\\n")
cat("District $\\times$ Year FE & No & No & Yes & Yes \\\\\n")
cat("CH $\\times$ Year FE & No & No & No & Yes \\\\\n")
cat("Controls & No & Yes & Yes & Yes \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Dependent variable is total prison sentence in months. ``Newly Elig.\\ $\\times$ Post-FSA'' is the interaction of an indicator for criminal history category II--IV with an indicator for fiscal years 2019--2024. Controls include indicators for Black and Hispanic race, female, age, U.S.\\ citizenship, and final offense level. Standard errors clustered at the district level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 3: Safety Valve Usage (First Stage)
# ============================================================
cat("=== Table 3: Safety Valve Usage ===\n")

sink(file.path(tables_dir, "tab3_safety_valve.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Effect of First Step Act on Safety Valve Application}\n")
cat("\\label{tab:sv}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) \\\\\n")
cat(" & Safety Valve & Safety Valve \\\\\n")
cat("\\midrule\n")

for (i in 1:2) {
  m <- list(results$sv1, results$sv2)[[i]]
  b <- coef(m)["treated"]
  s <- se(m)["treated"]
  p <- pvalue(m)["treated"]
  stars <- add_stars(p)
  if (i == 1) {
    cat(sprintf("Newly Elig. $\\times$ Post-FSA & %.3f%s & ", b, stars))
  } else {
    cat(sprintf("%.3f%s \\\\\n", b, stars))
  }
}

for (i in 1:2) {
  s <- se(list(results$sv1, results$sv2)[[i]])["treated"]
  if (i == 1) {
    cat(sprintf(" & (%.3f) & ", s))
  } else {
    cat(sprintf("(%.3f) \\\\\n", s))
  }
}

n1 <- nobs(results$sv1)
n2 <- nobs(results$sv2)
cat(sprintf("\\midrule\nN & %s & %s \\\\\n",
            format(n1, big.mark = ","), format(n2, big.mark = ",")))
cat("District $\\times$ Year FE & No & Yes \\\\\n")
cat("Controls & No & Yes \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Dependent variable is an indicator for whether the statutory safety valve (18 U.S.C.\\ \\S3553(f)) was applied. Column (1) includes district and year fixed effects. Column (2) includes district $\\times$ year fixed effects and defendant controls. Standard errors clustered at the district level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 4: Racial Disparity Analysis
# ============================================================
cat("=== Table 4: Racial Disparities ===\n")

sink(file.path(tables_dir, "tab4_race.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{First Step Act Effects on Racial Sentencing Disparities}\n")
cat("\\label{tab:race}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) \\\\\n")
cat(" & Sentence (months) & Safety Valve \\\\\n")
cat("\\midrule\n")

m_race_sent <- results$race_m1
m_race_sv <- results$race_sv

# Treated
cat(sprintf("Newly Elig. $\\times$ Post & %.2f%s & %.3f%s \\\\\n",
            coef(m_race_sent)["treated"], add_stars(pvalue(m_race_sent)["treated"]),
            coef(m_race_sv)["treated"], add_stars(pvalue(m_race_sv)["treated"])))
cat(sprintf(" & (%.2f) & (%.3f) \\\\\n",
            se(m_race_sent)["treated"], se(m_race_sv)["treated"]))

# Treated x Black
cat(sprintf("Newly Elig. $\\times$ Post $\\times$ Black & %.2f%s & %.3f%s \\\\\n",
            coef(m_race_sent)["treated:black"], add_stars(pvalue(m_race_sent)["treated:black"]),
            coef(m_race_sv)["treated:black"], add_stars(pvalue(m_race_sv)["treated:black"])))
cat(sprintf(" & (%.2f) & (%.3f) \\\\\n",
            se(m_race_sent)["treated:black"], se(m_race_sv)["treated:black"]))

n_sent <- nobs(m_race_sent)
n_sv <- nobs(m_race_sv)
cat(sprintf("\\midrule\nN & %s & %s \\\\\n",
            format(n_sent, big.mark = ","), format(n_sv, big.mark = ",")))
cat("District $\\times$ Year FE & Yes & Yes \\\\\n")
cat("Controls & Yes & Yes \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column (1) outcome is sentence length in months. Column (2) outcome is an indicator for safety valve application. ``Newly Elig.\\ $\\times$ Post $\\times$ Black'' tests whether Black defendants among the newly eligible experienced differential sentence changes after the FSA relative to non-Black newly eligible defendants. All specifications include district $\\times$ year fixed effects and defendant controls. Standard errors clustered at the district level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 5: Robustness
# ============================================================
cat("=== Table 5: Robustness ===\n")

sink(file.path(tables_dir, "tab5_robustness.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & Coefficient & SE & N \\\\\n")
cat("\\midrule\n")

# Main result
b_main <- coef(results$m3)["treated"]
s_main <- se(results$m3)["treated"]
p_main <- pvalue(results$m3)["treated"]
cat(sprintf("Main specification & %.2f%s & (%.2f) & %s \\\\\n",
            b_main, add_stars(p_main), s_main,
            format(nobs(results$m3), big.mark = ",")))

# Placebo
b_pl <- coef(rob_results$placebo_m)["post_fsa"]
s_pl <- se(rob_results$placebo_m)["post_fsa"]
p_pl <- pvalue(rob_results$placebo_m)["post_fsa"]
cat(sprintf("Placebo (CH I only) & %.2f%s & (%.2f) & %s \\\\\n",
            b_pl, add_stars(p_pl), s_pl,
            format(nobs(rob_results$placebo_m), big.mark = ",")))

# No COVID
b_nc <- coef(rob_results$m_nocovid)["treated"]
s_nc <- se(rob_results$m_nocovid)["treated"]
p_nc <- pvalue(rob_results$m_nocovid)["treated"]
cat(sprintf("Excluding FY2020--21 & %.2f%s & (%.2f) & %s \\\\\n",
            b_nc, add_stars(p_nc), s_nc,
            format(nobs(rob_results$m_nocovid), big.mark = ",")))

# Log
b_log <- coef(rob_results$m_log)["treated"]
s_log <- se(rob_results$m_log)["treated"]
p_log <- pvalue(rob_results$m_log)["treated"]
cat(sprintf("Log(sentence + 1) & %.3f%s & (%.3f) & %s \\\\\n",
            b_log, add_stars(p_log), s_log,
            format(nobs(rob_results$m_log), big.mark = ",")))

# Pulsifer
if (!is.null(rob_results$m_puls)) {
  b_puls <- coef(rob_results$m_puls)["newly_eligible:pulsifer"]
  s_puls <- se(rob_results$m_puls)["newly_eligible:pulsifer"]
  p_puls <- pvalue(rob_results$m_puls)["newly_eligible:pulsifer"]
  cat(sprintf("Pulsifer reversal (FY2024) & %.2f%s & (%.2f) & %s \\\\\n",
              b_puls, add_stars(p_puls), s_puls,
              format(nobs(rob_results$m_puls), big.mark = ",")))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications include district $\\times$ year fixed effects and defendant controls (race, gender, age, citizenship, offense level) unless otherwise noted. The placebo tests whether already-eligible (CH I) defendants experienced sentence changes post-FSA; these defendants had safety valve access both before and after the reform. Standard errors clustered at the district level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

sd_y <- results$sd_sentence

# Panel A: Pooled - Sentence length
beta_sent <- coef(results$m3)["treated"]
se_sent <- se(results$m3)["treated"]
sde_sent <- beta_sent / sd_y
se_sde_sent <- se_sent / sd_y

# Panel A: Safety valve
sd_sv <- sd(df$safety_valve, na.rm = TRUE)
beta_sv <- coef(results$sv2)["treated"]
se_sv_m <- se(results$sv2)["treated"]
sde_sv <- beta_sv / sd_sv
se_sde_sv <- se_sv_m / sd_sv

# Panel B: Heterogeneous - by race
# Black defendants
black_df <- df %>% filter(black == 1)
m_black <- feols(sentence_months ~ treated + hispanic + female +
                   age + us_citizen + offense_level |
                   district^fiscal_year,
                 data = black_df, cluster = ~district)
sd_y_black <- sd(black_df$sentence_months, na.rm = TRUE)
beta_black <- coef(m_black)["treated"]
se_black <- se(m_black)["treated"]
sde_black <- beta_black / sd_y_black
se_sde_black <- se_black / sd_y_black

# Non-Black defendants
nonblack_df <- df %>% filter(black == 0)
m_nonblack <- feols(sentence_months ~ treated + hispanic + female +
                      age + us_citizen + offense_level |
                      district^fiscal_year,
                    data = nonblack_df, cluster = ~district)
sd_y_nonblack <- sd(nonblack_df$sentence_months, na.rm = TRUE)
beta_nonblack <- coef(m_nonblack)["treated"]
se_nonblack <- se(m_nonblack)["treated"]
sde_nonblack <- beta_nonblack / sd_y_nonblack
se_sde_nonblack <- se_nonblack / sd_y_nonblack

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Write SDE table
sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccl}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")

cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Sentence (months) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_sent, se_sent, sd_y, sde_sent, se_sde_sent, classify(sde_sent)))
cat(sprintf("Safety valve & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_sv, se_sv_m, sd_sv, sde_sv, se_sde_sv, classify(sde_sv)))

cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by race)}} \\\\\n")
cat(sprintf("Sentence, Black & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_black, se_black, sd_y_black, sde_black, se_sde_black, classify(sde_black)))
cat(sprintf("Sentence, non-Black & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_nonblack, se_nonblack, sd_y_nonblack, sde_nonblack, se_sde_nonblack,
            classify(sde_nonblack)))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether the First Step Act's expansion of the statutory safety valve for federal drug offenses reduced sentence length and racial sentencing disparities among defendants with criminal history categories II--IV. ",
  "\\textbf{Policy mechanism:} The First Step Act (December 2018) relaxed the criminal history eligibility threshold for the safety valve (18 U.S.C.\\ \\S3553(f)) from 0--1 criminal history points to up to 4 points, allowing judges to sentence below statutory mandatory minimums for a broader set of drug trafficking defendants. ",
  "\\textbf{Outcome definition:} Total prison sentence in months (TOTPRISN) from USSC Individual Datafiles, and an indicator for whether the statutory safety valve was applied. ",
  "\\textbf{Treatment:} Binary: interaction of newly eligible status (criminal history category II--IV) with post-FSA period (FY2019--FY2024). ",
  "\\textbf{Data:} USSC Individual Datafiles, FY2016--FY2024, individual federal sentencing cases; drug trafficking offenses only. ",
  "\\textbf{Method:} Difference-in-differences comparing newly eligible (CH II--IV) to already eligible (CH I) defendants before and after FSA, with district $\\times$ year fixed effects and district-clustered standard errors. ",
  "\\textbf{Sample:} Federal drug trafficking offenses (USSC primary offense chapters 14--18) in districts with at least 20 pre-FSA eligible cases. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables generated ===\n")
cat(sprintf("Files in %s:\n", tables_dir))
print(list.files(tables_dir))
