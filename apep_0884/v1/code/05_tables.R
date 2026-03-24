## 05_tables.R — Generate all LaTeX tables (including SDE appendix)
## APEP-0884: The World's Highest Minimum Wage

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
panel <- readRDS("../data/panel_statent.rds")
udemo <- readRDS("../data/panel_udemo.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

ge_code <- panel %>% filter(grepl("Gen", canton_name)) %>% pull(canton_code) %>% unique()
vd_code <- panel %>% filter(grepl("Vaud", canton_name)) %>% pull(canton_code) %>% unique()

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

df <- panel %>%
  filter(canton_code %in% c(ge_code, vd_code),
         !is.na(employment), employment > 0,
         !is.na(establishments), establishments > 0)

# Pre-treatment means by canton and bite group
summ <- df %>%
  filter(year <= 2019) %>%
  group_by(canton_name, bite_group) %>%
  summarise(
    `Sectors` = n_distinct(noga2),
    `Establishments` = sprintf("%.0f", mean(establishments)),
    `Employment` = sprintf("%.0f", mean(employment)),
    `FTE` = sprintf("%.0f", mean(fte, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  filter(bite_group %in% c("high_bite", "low_bite")) %>%
  mutate(bite_group = ifelse(bite_group == "high_bite", "High-Bite", "Low-Bite"))

tab1_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Treatment Means (2011--2019)}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{llrrrr}
\\toprule
Canton & Sector Group & Sectors & Establishments & Employment & FTE \\\\
\\midrule\n"

for (i in seq_len(nrow(summ))) {
  tab1_tex <- paste0(tab1_tex,
    summ$canton_name[i], " & ", summ$bite_group[i], " & ",
    summ$Sectors[i], " & ", summ$Establishments[i], " & ",
    summ$Employment[i], " & ", summ$FTE[i], " \\\\\n")
}

# Add overall totals
overall <- df %>%
  filter(year <= 2019) %>%
  group_by(canton_name) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE) / n_distinct(year),
    establishments = sum(establishments, na.rm = TRUE) / n_distinct(year),
    .groups = "drop"
  )

tab1_tex <- paste0(tab1_tex, "\\midrule\n")
for (i in seq_len(nrow(overall))) {
  tab1_tex <- paste0(tab1_tex,
    overall$canton_name[i], " & All sectors & --- & ",
    sprintf("%.0f", overall$establishments[i]), " & ",
    sprintf("%.0f", overall$employment[i]), " & --- \\\\\n")
}

tab1_tex <- paste0(tab1_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Means computed over annual canton-sector observations, 2011--2019.
High-bite sectors: accommodation (55), food/beverage (56), retail (47), personal services (96),
building services (81), travel agencies (79), and sports/amusement (93).
Low-bite sectors: financial services (64), insurance (65), IT (62), pharmaceuticals (21),
R\\&D (72), legal/accounting (69), telecoms (61), and information services (63).
Source: BFS STATENT.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: Main Results (DiD and DDD)
# ============================================================================

cat("=== Generating Table 2: Main Results ===\n")

# Extract coefficients
extract_row <- function(mod, var_name = NULL) {
  if (is.null(var_name)) var_name <- names(coef(mod))[1]
  b <- coef(mod)[var_name]
  s <- se(mod)[var_name]
  p <- pvalue(mod)[var_name]
  n <- mod$nobs
  r2 <- fitstat(mod, "wr2")[[1]]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, s = s, stars = stars, n = n, r2 = r2)
}

did_e <- extract_row(results$did_emp)
did_s <- extract_row(results$did_est)
ddd_e <- extract_row(results$ddd_emp)
ddd_s <- extract_row(results$ddd_est)
ddd_f <- extract_row(results$ddd_fte)

fmt <- function(x, d = 4) sprintf(paste0("%.", d, "f"), x)

tab2_tex <- "\\begin{table}[htbp]
\\centering
\\caption{The Effect of Geneva's Minimum Wage on Employment and Establishments}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & \\multicolumn{2}{c}{Difference-in-Differences} & \\multicolumn{3}{c}{Triple-Difference} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-6}
 & Log Emp. & Log Est. & Log Emp. & Log Est. & Log FTE \\\\
 & (1) & (2) & (3) & (4) & (5) \\\\
\\midrule
"

# DiD row
tab2_tex <- paste0(tab2_tex,
  "Geneva $\\times$ Post & ", fmt(did_e$b), did_e$stars, " & ",
  fmt(did_s$b), did_s$stars, " & & & \\\\\n",
  " & (", fmt(did_e$s), ") & (", fmt(did_s$s), ") & & & \\\\\n")

# DDD row
tab2_tex <- paste0(tab2_tex,
  "Geneva $\\times$ High-Bite $\\times$ Post & & & ",
  fmt(ddd_e$b), ddd_e$stars, " & ",
  fmt(ddd_s$b), ddd_s$stars, " & ",
  fmt(ddd_f$b), ddd_f$stars, " \\\\\n",
  " & & & (", fmt(ddd_e$s), ") & (", fmt(ddd_s$s), ") & (", fmt(ddd_f$s), ") \\\\\n")

tab2_tex <- paste0(tab2_tex, "\\midrule
Canton $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes \\\\
Canton $\\times$ Sector FE & --- & --- & Yes & Yes & Yes \\\\
Sector $\\times$ Year FE & --- & --- & Yes & Yes & Yes \\\\
Observations & ", did_e$n, " & ", did_s$n, " & ",
  ddd_e$n, " & ", ddd_s$n, " & ", ddd_f$n, " \\\\
Within $R^2$ & ", fmt(did_e$r2, 3), " & ", fmt(did_s$r2, 3), " & ",
  fmt(ddd_e$r2, 3), " & ", fmt(ddd_s$r2, 3), " & ", fmt(ddd_f$r2, 3), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Columns 1--2 report difference-in-differences estimates comparing
Geneva (treated) to Vaud (control), aggregated across all sectors.
Columns 3--5 report triple-difference estimates interacting the Geneva $\\times$ Post
indicator with a high-bite sector indicator. High-bite sectors are those where $\\geq$20\\%
of workers typically earn below CHF~23/hr. Post period: 2021--2023 (first full years after
November 2020 introduction). Standard errors clustered at canton-sector level in parentheses.
$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================

cat("=== Generating Table 3: Event Study ===\n")

es_emp <- results$es_emp
es_est <- results$es_est

# Extract event study coefficients
es_coefs <- data.frame(
  event_time = -9:3,
  emp_b = NA_real_, emp_se = NA_real_,
  est_b = NA_real_, est_se = NA_real_
)

for (i in seq_len(nrow(es_coefs))) {
  et <- es_coefs$event_time[i]
  if (et == -1) next  # Reference period
  var_nm <- paste0("event_time::", et, ":ge_high")
  if (var_nm %in% names(coef(es_emp))) {
    es_coefs$emp_b[i] <- coef(es_emp)[var_nm]
    es_coefs$emp_se[i] <- se(es_emp)[var_nm]
  }
  if (var_nm %in% names(coef(es_est))) {
    es_coefs$est_b[i] <- coef(es_est)[var_nm]
    es_coefs$est_se[i] <- se(es_est)[var_nm]
  }
}

tab3_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Event Study: DDD Coefficients by Year}
\\label{tab:event_study}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & \\multicolumn{2}{c}{Log Employment} & \\multicolumn{2}{c}{Log Establishments} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Event Time & Estimate & SE & Estimate & SE \\\\
\\midrule\n"

for (i in seq_len(nrow(es_coefs))) {
  et <- es_coefs$event_time[i]
  yr <- 2020 + et
  if (et == -1) {
    tab3_tex <- paste0(tab3_tex, "$t", sprintf("%+d", et),
      "$ (", yr, ") & \\multicolumn{4}{c}{Reference period} \\\\\n")
  } else if (!is.na(es_coefs$emp_b[i])) {
    p_emp <- 2 * (1 - pnorm(abs(es_coefs$emp_b[i] / es_coefs$emp_se[i])))
    p_est <- 2 * (1 - pnorm(abs(es_coefs$est_b[i] / es_coefs$est_se[i])))
    star_e <- ifelse(p_emp < 0.01, "***", ifelse(p_emp < 0.05, "**", ifelse(p_emp < 0.1, "*", "")))
    star_s <- ifelse(p_est < 0.01, "***", ifelse(p_est < 0.05, "**", ifelse(p_est < 0.1, "*", "")))
    if (et == 0) {
      tab3_tex <- paste0(tab3_tex, "\\midrule\n")
    }
    tab3_tex <- paste0(tab3_tex,
      "$t", sprintf("%+d", et), "$ (", yr, ") & ",
      fmt(es_coefs$emp_b[i]), star_e, " & (", fmt(es_coefs$emp_se[i]), ") & ",
      fmt(es_coefs$est_b[i]), star_s, " & (", fmt(es_coefs$est_se[i]), ") \\\\\n")
  }
}

tab3_tex <- paste0(tab3_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Coefficients from regressing log outcomes on interactions of
Geneva $\\times$ High-Bite $\\times$ Year indicators, with canton-sector, canton-year,
and sector-year fixed effects. Event time 0 corresponds to 2020 (policy introduction in
November). Reference period: $t-1$ (2019). Standard errors clustered at canton-sector level.
$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab3_tex, "../tables/tab3_event_study.tex")

# ============================================================================
# Table 4: Robustness Checks
# ============================================================================

cat("=== Generating Table 4: Robustness ===\n")

rob_rows <- list(
  list(label = "Baseline DDD", mod = results$ddd_emp),
  list(label = "Placebo: Low-bite as treated", mod = robustness$placebo_sector),
  list(label = "Broader control (add FR, VS)", mod = robustness$broad_control_emp),
  list(label = "Late post only (2022--2023)", mod = robustness$late_post),
  list(label = "Immediate effect (2021 only)", mod = robustness$immediate),
  list(label = "Placebo year (2017)", mod = robustness$placebo_year),
  list(label = "Levels (employment count)", mod = robustness$levels)
)

tab4_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks: DDD Employment Estimates}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
Specification & Estimate & SE & $N$ & Within $R^2$ \\\\
\\midrule\n"

for (r in rob_rows) {
  rr <- extract_row(r$mod)
  tab4_tex <- paste0(tab4_tex,
    r$label, " & ", fmt(rr$b), rr$stars, " & (", fmt(rr$s), ") & ",
    rr$n, " & ", fmt(rr$r2, 3), " \\\\\n")
}

tab4_tex <- paste0(tab4_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All specifications include canton-sector, canton-year, and
sector-year fixed effects (except the baseline DiD and levels models). Standard errors
clustered at canton-sector level. The levels specification reports the coefficient on
Geneva $\\times$ High-Bite $\\times$ Post with employment in levels. Placebo year uses
pre-treatment data only (2011--2019) with a fake treatment date of 2017.
$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ============================================================================
# Table 5: Firm Dynamics (UDEMO)
# ============================================================================

cat("=== Generating Table 5: Firm Dynamics ===\n")

births_r <- extract_row(results$did_births)
closures_r <- extract_row(results$did_closures)
brate_r <- extract_row(results$did_birth_rate)

tab5_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Firm Dynamics: Geneva vs.\\ Vaud Difference-in-Differences}
\\label{tab:udemo}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & Log Births & Log Closures & Birth Rate (\\%) \\\\
 & (1) & (2) & (3) \\\\
\\midrule
Geneva $\\times$ Post & "

tab5_tex <- paste0(tab5_tex,
  fmt(births_r$b), births_r$stars, " & ",
  fmt(closures_r$b), closures_r$stars, " & ",
  fmt(brate_r$b, 3), brate_r$stars, " \\\\\n",
  " & (", fmt(births_r$s), ") & (", fmt(closures_r$s), ") & (",
  fmt(brate_r$s, 3), ") \\\\\n",
  "\\midrule\n",
  "Canton FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "Observations & ", births_r$n, " & ", closures_r$n, " & ", brate_r$n, " \\\\\n",
  "Pre-treatment mean (GE) & ",
  sprintf("%.0f", mean(udemo$births[udemo$geneva == 1 & udemo$year <= 2019])), " & ",
  sprintf("%.0f", mean(udemo$closures[udemo$geneva == 1 & udemo$year <= 2019])), " & ",
  sprintf("%.1f", mean(udemo$birth_rate[udemo$geneva == 1 & udemo$year <= 2019])),
  "\\% \\\\\n")

tab5_tex <- paste0(tab5_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Difference-in-differences comparing Geneva to Vaud at the
canton-year level using BFS UDEMO data (2013--2023). Firm births and closures aggregated
across all sectors and size classes. Birth rate is births divided by active firm stock ($\\times 100$).
Post period: 2021--2023. Robust standard errors in parentheses.
$^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.1$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab5_tex, "../tables/tab5_udemo.tex")

# ============================================================================
# SDE Appendix Table (MANDATORY)
# ============================================================================

cat("=== Generating SDE Table ===\n")

# Compute SDEs
sd_y_emp <- diagnostics$sd_y_emp
sd_y_est <- diagnostics$sd_y_est

# Panel A: Pooled results
beta_emp <- diagnostics$ddd_coef_emp
se_emp <- diagnostics$ddd_se_emp
sde_emp <- beta_emp / sd_y_emp
se_sde_emp <- se_emp / sd_y_emp

beta_est <- diagnostics$ddd_coef_est
se_est <- diagnostics$ddd_se_est
sde_est <- beta_est / sd_y_est
se_sde_est <- se_est / sd_y_est

# FTE
beta_fte <- coef(results$ddd_fte)["geneva_post_high"]
se_fte <- se(results$ddd_fte)["geneva_post_high"]
df_main <- panel %>%
  filter(canton_code %in% c(ge_code, vd_code),
         !is.na(fte), fte > 0) %>%
  mutate(log_fte = log(fte + 1))
sd_y_fte <- sd(df_main$log_fte[df_main$year < 2021])
sde_fte <- beta_fte / sd_y_fte
se_sde_fte <- se_fte / sd_y_fte

# Firm births (DiD)
beta_births <- coef(results$did_births)["geneva_post"]
se_births <- se(results$did_births)["geneva_post"]
udemo_pre <- udemo %>% filter(year <= 2019)
sd_y_births <- sd(log(udemo_pre$births))
sde_births <- beta_births / sd_y_births
se_sde_births <- se_births / sd_y_births

classify_sde <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneity (late post vs immediate)
beta_late <- coef(robustness$late_post)[1]
se_late <- se(robustness$late_post)[1]
sde_late <- beta_late / sd_y_emp
se_sde_late <- se_late / sd_y_emp

beta_imm <- coef(robustness$immediate)[1]
se_imm <- se(robustness$immediate)[1]
sde_imm <- beta_imm / sd_y_emp
se_sde_imm <- se_imm / sd_y_emp

# --- Build SDE LaTeX table ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the world's highest minimum wage (CHF~23/hr, Geneva, November 2020) affect employment, firm entry, and establishment counts in sectors with high shares of low-wage workers? ",
  "\\textbf{Policy mechanism:} Geneva's cantonal minimum wage, approved by 58\\% of voters in September 2020, mandates a CHF~23/hr floor for all private-sector employees, with no prior cantonal minimum wage in place; neighboring Vaud has no minimum wage. ",
  "\\textbf{Outcome definition:} Log employment (headcount of all employed persons in a canton-sector-year cell from STATENT), log establishments (count of business locations), log FTE (full-time equivalents), and log firm births (annual count of newly registered enterprises from UDEMO). ",
  "\\textbf{Treatment:} Binary: Geneva (treated, November 2020) vs.\\ Vaud (control, no minimum wage). Triple-difference interacts Geneva indicator with high-bite sector indicator (NOGA divisions where $\\geq$20\\% of workers earn below CHF~23/hr). ",
  "\\textbf{Data:} BFS STATENT (2011--2023) and UDEMO (2013--2023); canton $\\times$ NOGA 2-digit $\\times$ year panel; 1,957 observations for STATENT, 22 for UDEMO. ",
  "\\textbf{Method:} Triple-difference with canton-sector, canton-year, and sector-year fixed effects; standard errors clustered at canton-sector level. UDEMO uses simple DiD with canton and year FE. ",
  "\\textbf{Sample:} Geneva and Vaud cantons, 83 NOGA 2-digit sectors (7 high-bite, 8 low-bite, 68 medium); firms in all size classes. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Employment (DDD) & ", fmt(beta_emp), " & ", fmt(se_emp), " & ", fmt(sd_y_emp, 2),
  " & ", fmt(sde_emp, 3), " & ", fmt(se_sde_emp, 3), " & ", classify_sde(sde_emp), " \\\\
Establishments (DDD) & ", fmt(beta_est), " & ", fmt(se_est), " & ", fmt(sd_y_est, 2),
  " & ", fmt(sde_est, 3), " & ", fmt(se_sde_est, 3), " & ", classify_sde(sde_est), " \\\\
FTE (DDD) & ", fmt(beta_fte), " & ", fmt(se_fte), " & ", fmt(sd_y_fte, 2),
  " & ", fmt(sde_fte, 3), " & ", fmt(se_sde_fte, 3), " & ", classify_sde(sde_fte), " \\\\
Firm Births (DiD) & ", fmt(beta_births), " & ", fmt(se_births), " & ", fmt(sd_y_births, 2),
  " & ", fmt(sde_births, 3), " & ", fmt(se_sde_births, 3), " & ", classify_sde(sde_births), " \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Timing)}} \\\\
Employment --- Late (2022--2023) & ", fmt(beta_late), " & ", fmt(se_late), " & ", fmt(sd_y_emp, 2),
  " & ", fmt(sde_late, 3), " & ", fmt(se_sde_late, 3), " & ", classify_sde(sde_late), " \\\\
Employment --- Immediate (2021) & ", fmt(beta_imm), " & ", fmt(se_imm), " & ", fmt(sd_y_emp, 2),
  " & ", fmt(sde_imm, 3), " & ", fmt(se_sde_imm, 3), " & ", classify_sde(sde_imm), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated in tables/\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_event_study.tex\n")
cat("  tab4_robustness.tex\n")
cat("  tab5_udemo.tex\n")
cat("  tabF1_sde.tex\n")
