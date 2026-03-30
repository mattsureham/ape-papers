## 05_tables.R — Generate LaTeX tables
## Paper: apep_1121 — Swiss cantonal debt brakes and spending composition

source("00_packages.R")

cat("=== Generating LaTeX tables ===\n")

# Load data
analysis_df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
results_table <- read_csv("../data/main_results.csv", show_col_types = FALSE)
twfe_results <- readRDS("../data/twfe_results.rds")
cs_agg_results <- readRDS("../data/cs_agg_results.rds")

analysis_main <- analysis_df %>%
  filter(first_treat_cs == 0 | first_treat_cs >= 1990)

func_names_map <- c("2"="Education", "4"="Health", "5"="Social security",
                     "6"="Transport", "0"="Administration", "1"="Security",
                     "8"="Economy", "3"="Culture")

# ---------------------------------------------------------------
# TABLE 1: Summary Statistics
# ---------------------------------------------------------------

cat("\n=== Table 1: Summary Statistics ===\n")

# Pre-treatment means by treatment status
pre_means <- analysis_main %>%
  filter(func_code != "total", year <= 1993) %>%
  mutate(group = ifelse(treated == 1, "Treated", "Control")) %>%
  group_by(group, func_short) %>%
  summarise(
    mean_share = mean(share, na.rm = TRUE),
    sd_share = sd(share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = group,
    values_from = c(mean_share, sd_share)
  )

# Full sample means
full_means <- analysis_main %>%
  filter(func_code != "total") %>%
  group_by(func_short) %>%
  summarise(
    mean_share = mean(share, na.rm = TRUE),
    sd_share = sd(share, na.rm = TRUE),
    .groups = "drop"
  )

# Order functions by size
func_order <- c("Education", "Social", "Health", "Transport",
                "Economy", "Security", "Finance", "Administration",
                "Environment", "Culture")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Cantonal Expenditure Shares by Function (\\%)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-treatment} & \\multicolumn{2}{c}{Full sample} & \\multicolumn{2}{c}{N} \\\\",
  " & \\multicolumn{2}{c}{(1990--1993)} & \\multicolumn{2}{c}{(1990--2024)} & & \\\\",
  "\\cline{2-3} \\cline{4-5}",
  "Function & Treated & Control & Mean & SD & Cantons & Years \\\\",
  "\\hline"
)

for (fn in func_order) {
  pm <- pre_means %>% filter(func_short == fn)
  fm <- full_means %>% filter(func_short == fn)

  treated_mean <- ifelse(nrow(pm) > 0 && !is.na(pm$mean_share_Treated), sprintf("%.1f", pm$mean_share_Treated), "---")
  control_mean <- ifelse(nrow(pm) > 0 && !is.na(pm$mean_share_Control), sprintf("%.1f", pm$mean_share_Control), "---")
  full_mean <- sprintf("%.1f", fm$mean_share)
  full_sd <- sprintf("%.1f", fm$sd_share)

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s & 24 & 35 \\\\", fn, treated_mean, control_mean, full_mean, full_sd))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Expenditure shares are percentage of total cantonal expenditure.} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize Pre-treatment: years before any canton in the 1994--2014 adoption wave adopted a debt brake.} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize Treated: 20 cantons adopting 1994--2014. Control: 4 never-treated + pre-1990 adopters (6 total).} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize Source: Swiss Federal Finance Administration (EFV), 1990--2024.} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ---------------------------------------------------------------
# TABLE 2: Main Results (CS-DiD and TWFE)
# ---------------------------------------------------------------

cat("\n=== Table 2: Main Results ===\n")

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Cantonal Debt Brakes on Expenditure Composition}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Callaway-Sant'Anna} & \\multicolumn{3}{c}{TWFE} \\\\",
  "\\cline{2-4} \\cline{5-7}",
  "Function & ATT & SE & $p$ & Coef. & SE & $p$ \\\\",
  "\\hline"
)

func_display_order <- c("Education", "Health", "Social", "Transport",
                         "Administration", "Security", "Economy", "Culture")

# Map display names to results_table names
name_map <- c("Social" = "Social")  # They match

for (fn in func_display_order) {
  row <- results_table %>% filter(Function == fn)
  if (nrow(row) == 0) next

  cs_star <- stars(row$CS_pval)
  tw_star <- stars(row$TWFE_pval)

  tab2_lines <- c(tab2_lines,
    sprintf("%s & %.2f%s & (%.2f) & %.3f & %.2f%s & (%.2f) & %.3f \\\\",
            fn,
            row$CS_ATT, cs_star, row$CS_SE, row$CS_pval,
            row$TWFE_coef, tw_star, row$TWFE_se, row$TWFE_pval))
}

tab2_lines <- c(tab2_lines,
  "\\hline",
  "Canton FE & \\multicolumn{3}{c}{---} & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{---} & \\multicolumn{3}{c}{Yes} \\\\",
  "Control group & \\multicolumn{3}{c}{Not-yet-treated} & \\multicolumn{3}{c}{---} \\\\",
  "Cantons & \\multicolumn{3}{c}{24} & \\multicolumn{3}{c}{24} \\\\",
  "Obs. per function & \\multicolumn{3}{c}{840} & \\multicolumn{3}{c}{840} \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Dependent variable is the expenditure share (\\%) of each function in total cantonal} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize spending. CS standard errors are analytical. TWFE standard errors clustered at the canton level.} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize Sample excludes pre-1990 adopters (St.\\ Gallen, Fribourg). $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ---------------------------------------------------------------
# TABLE 3: Robustness (WCB, levels, stringency)
# ---------------------------------------------------------------

cat("\n=== Table 3: Robustness ===\n")

# Re-run key regressions for the table
key_fcs <- c("2", "5", "0", "6")
key_names <- c("Education", "Social security", "Administration", "Transport")

# Triple-diff results
analysis_main_r <- analysis_main %>%
  mutate(
    hard_rule = as.integer(rule_type == "hard"),
    hard_treat_post = hard_rule * treat_post
  )

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Wild Cluster Bootstrap, Levels, and Rule Stringency}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Education & Social & Admin. & Transport \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Wild cluster bootstrap}} \\\\"
)

# WCB results
wcb_results <- readRDS("../data/wcb_results.rds")
wcb_pvals <- sapply(key_fcs, function(fc) {
  if (!is.null(wcb_results[[fc]])) wcb_results[[fc]]$p_val else NA
})

tab3_lines <- c(tab3_lines,
  sprintf("WCB $p$-value & %.3f & %.3f & %.3f & %.3f \\\\",
          wcb_pvals["2"], wcb_pvals["5"], wcb_pvals["0"], wcb_pvals["6"]))

# WCB CIs
wcb_cis <- sapply(key_fcs, function(fc) {
  if (!is.null(wcb_results[[fc]])) {
    sprintf("[%.2f, %.2f]", wcb_results[[fc]]$conf_int[1], wcb_results[[fc]]$conf_int[2])
  } else "---"
})

tab3_lines <- c(tab3_lines,
  sprintf("WCB 95\\%% CI & %s & %s & %s & %s \\\\",
          wcb_cis["2"], wcb_cis["5"], wcb_cis["0"], wcb_cis["6"]),
  " & & & & \\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Log expenditure levels}} \\\\"
)

# Level effects
for (fc in key_fcs) {
  df_func <- analysis_main %>% filter(func_code == fc, expenditure > 0)
  level_fit <- feols(log(expenditure) ~ treat_post | canton_id + year,
                     data = df_func, cluster = ~canton_id)
  assign(paste0("lev_", fc), level_fit)
}

tab3_lines <- c(tab3_lines,
  sprintf("Coefficient & %.3f & %.3f & %.3f & %.3f \\\\",
          coef(lev_2)["treat_post"], coef(lev_5)["treat_post"],
          coef(lev_0)["treat_post"], coef(lev_6)["treat_post"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          sqrt(vcov(lev_2)["treat_post","treat_post"]),
          sqrt(vcov(lev_5)["treat_post","treat_post"]),
          sqrt(vcov(lev_0)["treat_post","treat_post"]),
          sqrt(vcov(lev_6)["treat_post","treat_post"])),
  " & & & & \\\\",
  "\\multicolumn{5}{l}{\\textit{Panel C: Hard vs.\\ soft rules (triple-difference)}} \\\\"
)

# Triple-diff
for (fc in key_fcs) {
  df_func <- analysis_main_r %>% filter(func_code == fc)
  td_fit <- feols(share ~ treat_post + hard_treat_post | canton_id + year,
                  data = df_func, cluster = ~canton_id)
  assign(paste0("td_", fc), td_fit)
}

td_soft <- sprintf("Soft rule & %.2f & %.2f & %.2f & %.2f \\\\",
                   coef(td_2)["treat_post"], coef(td_5)["treat_post"],
                   coef(td_0)["treat_post"], coef(td_6)["treat_post"])
td_soft_se <- sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\",
                      sqrt(vcov(td_2)["treat_post","treat_post"]),
                      sqrt(vcov(td_5)["treat_post","treat_post"]),
                      sqrt(vcov(td_0)["treat_post","treat_post"]),
                      sqrt(vcov(td_6)["treat_post","treat_post"]))

hard_add <- sprintf("Hard $\\times$ Post & %.2f%s & %.2f%s & %.2f%s & %.2f%s \\\\",
                    coef(td_2)["hard_treat_post"], stars(pvalue(td_2)["hard_treat_post"]),
                    coef(td_5)["hard_treat_post"], stars(pvalue(td_5)["hard_treat_post"]),
                    coef(td_0)["hard_treat_post"], stars(pvalue(td_0)["hard_treat_post"]),
                    coef(td_6)["hard_treat_post"], stars(pvalue(td_6)["hard_treat_post"]))
hard_add_se <- sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\",
                       sqrt(vcov(td_2)["hard_treat_post","hard_treat_post"]),
                       sqrt(vcov(td_5)["hard_treat_post","hard_treat_post"]),
                       sqrt(vcov(td_0)["hard_treat_post","hard_treat_post"]),
                       sqrt(vcov(td_6)["hard_treat_post","hard_treat_post"]))

tab3_lines <- c(tab3_lines, td_soft, td_soft_se, hard_add, hard_add_se,
  "\\hline",
  "\\multicolumn{5}{l}{\\footnotesize \\textit{Notes:} Panel A: Mammen wild cluster bootstrap with 9,999 draws.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize Panel B: Dependent variable is log expenditure in CHF thousands. Panel C: Soft rule} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize = advisory balanced-budget targets (AR, AI); Hard = legally binding rules (18 cantons).} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize All specifications include canton and year FE; SEs clustered by canton. $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robust.tex")
cat("Table 3 written.\n")

# ---------------------------------------------------------------
# TABLE 4: Event Study (Pre-trends)
# ---------------------------------------------------------------

cat("\n=== Table 4: Event Study ===\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Expenditure Shares Before and After Debt Brake Adoption}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Education & Transport & Administration & Social \\\\",
  "\\hline"
)

es_fcs <- c("2", "6", "0", "5")
es_names <- c("Education", "Transport", "Administration", "Social")

# Run event studies
es_fits <- list()
for (fc in es_fcs) {
  df_func <- analysis_main %>%
    filter(func_code == fc) %>%
    mutate(
      event_time = ifelse(first_treat_cs > 0, year - first_treat_cs, NA),
      et_bin = case_when(
        is.na(event_time) ~ NA_character_,
        event_time <= -4 ~ "pre4plus",
        event_time == -3 ~ "pre3",
        event_time == -2 ~ "pre2",
        event_time == -1 ~ "pre1",
        event_time == 0 ~ "post0",
        event_time >= 1 & event_time <= 3 ~ "post1to3",
        event_time >= 4 & event_time <= 7 ~ "post4to7",
        event_time >= 8 ~ "post8plus"
      )
    ) %>%
    filter(!is.na(et_bin)) %>%
    mutate(et_bin = relevel(factor(et_bin), ref = "pre1"))

  es_fit <- feols(share ~ et_bin | canton_id + year,
                  data = df_func, cluster = ~canton_id)
  es_fits[[fc]] <- es_fit
}

# Build table rows
et_labels <- c("pre4plus" = "$t \\leq -4$",
               "pre3" = "$t = -3$",
               "pre2" = "$t = -2$",
               "post0" = "$t = 0$",
               "post1to3" = "$t \\in [1,3]$",
               "post4to7" = "$t \\in [4,7]$",
               "post8plus" = "$t \\geq 8$")

for (et in names(et_labels)) {
  coef_name <- paste0("et_bin", et)
  coef_vals <- sapply(es_fcs, function(fc) {
    cf <- coeftable(es_fits[[fc]])
    if (coef_name %in% rownames(cf)) {
      p <- cf[coef_name, "Pr(>|t|)"]
      sprintf("%.2f%s", cf[coef_name, "Estimate"], stars(p))
    } else "---"
  })
  se_vals <- sapply(es_fcs, function(fc) {
    cf <- coeftable(es_fits[[fc]])
    if (coef_name %in% rownames(cf)) {
      sprintf("(%.2f)", cf[coef_name, "Std. Error"])
    } else ""
  })

  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s & %s & %s & %s \\\\", et_labels[et],
            coef_vals[1], coef_vals[2], coef_vals[3], coef_vals[4]),
    sprintf(" & %s & %s & %s & %s \\\\",
            se_vals[1], se_vals[2], se_vals[3], se_vals[4]))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  "Reference & \\multicolumn{4}{c}{$t = -1$} \\\\",
  "Canton \\& Year FE & \\multicolumn{4}{c}{Yes} \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\footnotesize \\textit{Notes:} Event time $t$ relative to debt brake adoption year. Dependent variable is} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize the expenditure share (\\%) of each function. SEs clustered by canton.} \\\\",
  "\\multicolumn{5}{l}{\\footnotesize $^{***}p<0.01$; $^{**}p<0.05$; $^{*}p<0.10$.} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("Table 4 written.\n")

# ---------------------------------------------------------------
# TABLE F1: SDE TABLE (APPENDIX)
# ---------------------------------------------------------------

cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
sde_rows <- list()

main_outcomes <- c("2", "5", "0", "6")
main_names <- c("Education share", "Social security share",
                "Administration share", "Transport share")

for (i in seq_along(main_outcomes)) {
  fc <- main_outcomes[i]
  df_func <- analysis_main %>% filter(func_code == fc)

  # Pre-treatment SD
  pre_sd <- df_func %>%
    filter(first_treat_cs == 0 | year < first_treat_cs) %>%
    pull(share) %>%
    sd(na.rm = TRUE)

  # CS estimate
  cs_att <- cs_agg_results[[fc]]$overall$overall.att
  cs_se <- cs_agg_results[[fc]]$overall$overall.se

  sde <- cs_att / pre_sd
  sde_se <- cs_se / pre_sd

  classification <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  sde_rows[[i]] <- tibble(
    Outcome = main_names[i],
    beta = cs_att,
    se = cs_se,
    sd_y = pre_sd,
    sde = sde,
    sde_se = sde_se,
    classification = classification
  )
}

sde_panel_a <- bind_rows(sde_rows)

# Panel B: Heterogeneous (hard vs soft rules)
sde_hetero_rows <- list()
analysis_main_r <- analysis_main %>%
  mutate(
    hard_rule = as.integer(rule_type == "hard"),
    hard_treat_post = hard_rule * treat_post
  )

for (i in seq_along(main_outcomes)) {
  fc <- main_outcomes[i]
  df_func_hard <- analysis_main_r %>% filter(func_code == fc, rule_type == "hard")
  df_func_soft <- analysis_main_r %>% filter(func_code == fc, rule_type %in% c("soft", "none"))

  pre_sd_hard <- df_func_hard %>%
    filter(first_treat_cs == 0 | year < first_treat_cs) %>%
    pull(share) %>%
    sd(na.rm = TRUE)

  # Use TWFE for hard-rule subgroup
  hard_fit <- feols(share ~ treat_post | canton_id + year,
                    data = df_func_hard, cluster = ~canton_id)

  beta_hard <- coef(hard_fit)["treat_post"]
  se_hard <- sqrt(vcov(hard_fit)["treat_post", "treat_post"])
  sde_hard <- beta_hard / pre_sd_hard
  sde_se_hard <- se_hard / pre_sd_hard

  classification_hard <- case_when(
    sde_hard < -0.15 ~ "Large negative",
    sde_hard < -0.05 ~ "Moderate negative",
    sde_hard < -0.005 ~ "Small negative",
    sde_hard <= 0.005 ~ "Null",
    sde_hard <= 0.05 ~ "Small positive",
    sde_hard <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  sde_hetero_rows[[i]] <- tibble(
    Outcome = paste0(main_names[i], " (hard rules)"),
    beta = beta_hard,
    se = se_hard,
    sd_y = pre_sd_hard,
    sde = sde_hard,
    sde_se = sde_se_hard,
    classification = classification_hard
  )
}

sde_panel_b <- bind_rows(sde_hetero_rows)

# Build LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Do cantonal debt brake adoptions reshape the functional composition of public spending, ",
  "shifting expenditure from investment-intensive categories toward current consumption? ",
  "\\textbf{Policy mechanism:} Cantonal fiscal rules (Schuldenbremsen) impose legally binding balanced-budget requirements or ",
  "expenditure growth limits, creating a structural constraint on annual budget deficits that forces reallocation across spending categories. ",
  "\\textbf{Outcome definition:} Expenditure share (\\%) of each functional category in total cantonal spending, computed from ",
  "Swiss Federal Finance Administration standardized accounts. ",
  "\\textbf{Treatment:} Binary --- canton-year observations after debt brake adoption vs.\\ before/never-treated. ",
  "\\textbf{Data:} Swiss Federal Finance Administration (EFV), cantonal accounts by function, 1990--2024, canton-year level, ",
  "24 cantons (excl.\\ pre-1990 adopters), 840 observations per function. ",
  "\\textbf{Method:} Callaway-Sant'Anna (2021) staggered DiD with not-yet-treated comparison group (Panel A); ",
  "TWFE with canton and year fixed effects for hard-rule subsample (Panel B); SEs clustered at canton level. ",
  "\\textbf{Sample:} Swiss cantons adopting debt brakes 1994--2014 (20 treated) and 4 never-treated cantons; ",
  "pre-1990 adopters excluded from main analysis but included in sensitivity checks. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

format_sde_row <- function(row) {
  sprintf("%s & %.3f & (%.3f) & %.2f & %.3f & (%.3f) & %s \\\\",
          row$Outcome, row$beta, row$se, row$sd_y, row$sde, row$sde_se, row$classification)
}

tabf1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Debt Brakes and Spending Composition}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (Callaway-Sant'Anna)}} \\\\"
)

for (i in 1:nrow(sde_panel_a)) {
  tabf1_lines <- c(tabf1_lines, format_sde_row(sde_panel_a[i,]))
}

tabf1_lines <- c(tabf1_lines,
  " & & & & & & \\\\",
  "\\multicolumn{7}{l}{\\textit{Panel B: Hard rules only (TWFE)}} \\\\"
)

for (i in 1:nrow(sde_panel_b)) {
  tabf1_lines <- c(tabf1_lines, format_sde_row(sde_panel_b[i,]))
}

tabf1_lines <- c(tabf1_lines,
  "\\hline",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\begin{itemize}[leftmargin=*]",
  sde_notes,
  "\\end{itemize}",
  "\\end{minipage} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tabf1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_robust.tex\n")
cat("  tables/tab4_eventstudy.tex\n")
cat("  tables/tabF1_sde.tex\n")
