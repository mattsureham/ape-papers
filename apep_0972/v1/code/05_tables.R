# 05_tables.R — Generate all LaTeX tables
# apep_0972: Craft brewery self-distribution deregulation

source("00_packages.R")

state_panel <- readRDS("../data/state_panel.rds")
models <- readRDS("../data/main_models.rds")
rob <- readRDS("../data/robustness_models.rds")
diag <- fromJSON("../data/diagnostics.json")

sp312 <- state_panel %>% filter(industry == "312")
sp311 <- state_panel %>% filter(industry == "311")

# ══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment means (before earliest treatment = 2011Q3)
pre_312 <- sp312 %>% filter(yq < 20113)
pre_311 <- sp311 %>% filter(yq < 20113)

# Split by treated vs control
pre_312_t <- pre_312 %>% filter(treat_yq > 0)
pre_312_c <- pre_312 %>% filter(treat_yq == 0)

sum_stats <- function(d, var) {
  x <- d[[var]]
  c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE),
    p25 = quantile(x, 0.25, na.rm = TRUE),
    p75 = quantile(x, 0.75, na.rm = TRUE))
}

# Generate summary stats
vars_labels <- c(
  "Emp" = "Employment (NAICS 312)",
  "log_emp" = "Log employment",
  "HirN" = "New hires",
  "hire_rate" = "Hiring rate",
  "Sep" = "Separations",
  "sep_rate" = "Separation rate",
  "net_job_creation" = "Net job creation rate",
  "n_counties" = "Counties with NAICS 312"
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Beverage Manufacturing (NAICS 312), Pre-Treatment}",
  "\\label{tab:sumstats}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Treated States} & \\multicolumn{3}{c}{Control States} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & N & Mean & SD & N \\\\",
  "\\midrule"
)

for (v in names(vars_labels)) {
  st <- sum_stats(pre_312_t, v)
  sc <- sum_stats(pre_312_c, v)
  nt <- sum(!is.na(pre_312_t[[v]]))
  nc <- sum(!is.na(pre_312_c[[v]]))

  if (v %in% c("Emp", "HirN", "Sep")) {
    fmt <- "%.0f"
  } else if (v == "n_counties") {
    fmt <- "%.1f"
  } else {
    fmt <- "%.3f"
  }

  line <- sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                  vars_labels[v],
                  sprintf(fmt, st["mean"]),
                  sprintf(fmt, st["sd"]),
                  format(nt, big.mark = ","),
                  sprintf(fmt, sc["mean"]),
                  sprintf(fmt, sc["sd"]),
                  format(nc, big.mark = ","))
  tab1_lines <- c(tab1_lines, line)
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("States & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          n_distinct(pre_312_t$statefips), n_distinct(pre_312_c$statefips)),
  sprintf("Quarters & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          n_distinct(pre_312_t$time_id), n_distinct(pre_312_c$time_id)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Pre-treatment summary statistics for beverage manufacturing",
  "(NAICS 312) at the state-quarter level. Treated states are those that adopted",
  "self-distribution laws during 2011--2019. Control states had no documented adoption",
  "during the sample period. All statistics are calculated before the earliest",
  "treatment (2011Q3).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

# ══════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main Results\n")

# CS-DiD aggregate estimate
cs_out <- readRDS("../data/cs_did_out.rds")
cs_agg <- aggte(cs_out, type = "simple")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Self-Distribution Laws on Beverage Manufacturing Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Emp & Hiring Rate & Emp (Level) & Net Job Creation \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: TWFE}} \\\\[4pt]"
)

# Panel A: TWFE
coefs_twfe <- c(
  coef(models$m1_emp)["treated"],
  coef(models$m1_hire)["treated"],
  coef(rob$m_level)["treated"],
  coef(models$m1_net)["treated"]
)
ses_twfe <- c(
  se(models$m1_emp)["treated"],
  se(models$m1_hire)["treated"],
  se(rob$m_level)["treated"],
  se(models$m1_net)["treated"]
)
pvals_twfe <- c(
  pvalue(models$m1_emp)["treated"],
  pvalue(models$m1_hire)["treated"],
  pvalue(rob$m_level)["treated"],
  pvalue(models$m1_net)["treated"]
)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

fmts <- c("%.3f", "%.4f", "%.0f", "%.4f")
coef_line <- "Self-distribution"
se_line <- ""
for (i in 1:4) {
  coef_line <- paste0(coef_line, " & ", sprintf(fmts[i], coefs_twfe[i]), stars(pvals_twfe[i]))
  se_line <- paste0(se_line, " & (", sprintf(fmts[i], ses_twfe[i]), ")")
}
tab2_lines <- c(tab2_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\[8pt]")
)

# Panel B: CS-DiD (only for log employment)
tab2_lines <- c(tab2_lines,
  "\\multicolumn{5}{l}{\\textit{Panel B: Callaway-Sant'Anna}} \\\\[4pt]",
  sprintf("Self-distribution & %.3f & & & \\\\", cs_agg$overall.att),
  sprintf(" & (%.3f) & & & \\\\[8pt]", cs_agg$overall.se)
)

# Panel C: Triple Difference (312 vs 311)
ddd_coef <- coef(models$m3_ddd)["treated:is_312"]
ddd_se <- se(models$m3_ddd)["treated:is_312"]
ddd_p <- pvalue(models$m3_ddd)["treated:is_312"]

tab2_lines <- c(tab2_lines,
  "\\multicolumn{5}{l}{\\textit{Panel C: Triple Difference (NAICS 312 vs.\\ 311)}} \\\\[4pt]",
  sprintf("Self-dist.\\ $\\times$ Beverage & %.3f%s & & & \\\\",
          ddd_coef, stars(ddd_p)),
  sprintf(" & (%.3f) & & & \\\\[4pt]", ddd_se)
)

# Footer
tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(models$m1_emp), big.mark = ","),
          format(nobs(models$m1_hire), big.mark = ","),
          format(nobs(rob$m_level), big.mark = ","),
          format(nobs(models$m1_net), big.mark = ",")),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Treated states & %d & %d & %d & %d \\\\", diag$n_treated,
          diag$n_treated, diag$n_treated, diag$n_treated),
  sprintf("Control states & %d & %d & %d & %d \\\\", diag$n_control_states,
          diag$n_control_states, diag$n_control_states, diag$n_control_states),
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on a binary indicator for",
  "self-distribution law in effect. Panel A: two-way fixed effects (state + quarter).",
  "Panel B: Callaway-Sant'Anna estimator with not-yet-treated controls.",
  "Panel C: triple-difference comparing NAICS 312 (Beverage Manufacturing) to NAICS 311",
  "(Food Manufacturing) within the same states. Standard errors clustered at the state level",
  "in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ══════════════════════════════════════════════════════════════════════
# TABLE 3: Robustness
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Robustness\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Coefficient & SE & N \\\\",
  "\\midrule",
  sprintf("\\textit{Main estimate (TWFE, log emp)} & %.3f & (%.3f) & %s \\\\",
          coef(models$m1_emp)["treated"], se(models$m1_emp)["treated"],
          format(nobs(models$m1_emp), big.mark = ",")),
  sprintf("\\textit{Callaway-Sant'Anna} & %.3f & (%.3f) & %s \\\\[4pt]",
          cs_agg$overall.att, cs_agg$overall.se,
          format(nobs(models$m1_emp), big.mark = ",")),
  "\\multicolumn{4}{l}{\\textit{Placebo and falsification}} \\\\",
  sprintf("\\quad NAICS 311 (Food Mfg) placebo & %.3f & (%.3f) & %s \\\\",
          coef(rob$placebo_311)["treated"], se(rob$placebo_311)["treated"],
          format(nobs(rob$placebo_311), big.mark = ",")),
  sprintf("\\quad 4-quarter-early falsification & %.3f & (%.3f) & %s \\\\[4pt]",
          coef(rob$falsif_4q)["treated_early"], se(rob$falsif_4q)["treated_early"],
          format(nobs(rob$falsif_4q), big.mark = ",")),
  "\\multicolumn{4}{l}{\\textit{Alternative specifications}} \\\\",
  sprintf("\\quad Employment levels & %.0f & (%.0f) & %s \\\\",
          coef(rob$m_level)["treated"], se(rob$m_level)["treated"],
          format(nobs(rob$m_level), big.mark = ",")),
  sprintf("\\quad Restricted sample (2005--2019) & %.3f & (%.3f) & %s \\\\[4pt]",
          coef(rob$m_restricted)["treated"], se(rob$m_restricted)["treated"],
          format(nobs(rob$m_restricted), big.mark = ",")),
  sprintf("\\multicolumn{4}{l}{\\textit{Leave-one-state-out range: [%.3f, %.3f]}} \\\\",
          min(rob$loo_coefs), max(rob$loo_coefs)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} All specifications include state and quarter fixed effects with",
  "standard errors clustered at the state level. The placebo test applies the treatment",
  "indicator to NAICS 311 (Food Manufacturing). The falsification test assigns treatment",
  "four quarters before actual adoption. The leave-one-state-out range reports the minimum",
  "and maximum TWFE coefficient when each treated state is sequentially dropped.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robust.tex")

# ══════════════════════════════════════════════════════════════════════
# TABLE 4: Heterogeneity by Education
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Education Heterogeneity\n")

state_edu <- readRDS("../data/state_edu.rds")

edu_results <- list()
for (ed in c("E1", "E2", "E3", "E4")) {
  ed_data <- state_edu %>% filter(education == ed)
  m <- feols(log_emp ~ treated | statefips + time_id,
             data = ed_data, cluster = ~statefips)
  edu_results[[ed]] <- list(
    coef = coef(m)["treated"],
    se = se(m)["treated"],
    pval = pvalue(m)["treated"],
    n = nobs(m)
  )
}

edu_labels <- c(E1 = "Less than HS", E2 = "HS / GED",
                E3 = "Some College", E4 = "Bachelor's+")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Worker Education Level (NAICS 312)}",
  "\\label{tab:educ}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  paste0(" & ", paste(edu_labels, collapse = " & "), " \\\\"),
  paste0(" & (1) & (2) & (3) & (4) \\\\"),
  "\\midrule"
)

coef_line <- "Self-distribution"
se_line <- ""
for (ed in c("E1", "E2", "E3", "E4")) {
  r <- edu_results[[ed]]
  coef_line <- paste0(coef_line, sprintf(" & %.3f%s", r$coef, stars(r$pval)))
  se_line <- paste0(se_line, sprintf(" & (%.3f)", r$se))
}
tab4_lines <- c(tab4_lines,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\midrule",
  paste0("Observations & ", paste(sapply(edu_results, function(r)
    format(r$n, big.mark = ",")), collapse = " & "), " \\\\"),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each column reports the TWFE coefficient on the self-distribution",
  "indicator for a different education subgroup within NAICS 312 (Beverage Manufacturing).",
  "QWI education categories: E1 = less than high school, E2 = high school/GED,",
  "E3 = some college/associate's, E4 = bachelor's degree or higher. Standard errors",
  "clustered at the state level in parentheses.",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_educ.tex")

# ══════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table F1: Standardized Effect Sizes\n")

# Pre-treatment SD(Y) for each outcome
pre_312 <- sp312 %>% filter(yq < 20113)
sd_log_emp <- sd(pre_312$log_emp, na.rm = TRUE)
sd_hire <- sd(pre_312$hire_rate, na.rm = TRUE)
sd_net <- sd(pre_312$net_job_creation, na.rm = TRUE)

# County entry outcome
ce <- readRDS("../data/county_entry.rds")
ce_pre <- ce %>% filter(yq < 20113)
sd_counties <- sd(ce_pre$n_counties_312, na.rm = TRUE)

# SDE = beta / SD(Y) for binary treatment
sde_rows <- data.frame(
  outcome = c("Log employment (NAICS 312)",
              "Hiring rate",
              "Net job creation rate",
              "Counties with NAICS 312 emp."),
  beta = c(coef(models$m1_emp)["treated"],
           coef(models$m1_hire)["treated"],
           coef(models$m1_net)["treated"],
           coef(models$m4_entry)["treated"]),
  se = c(se(models$m1_emp)["treated"],
         se(models$m1_hire)["treated"],
         se(models$m1_net)["treated"],
         se(models$m4_entry)["treated"]),
  sd_y = c(sd_log_emp, sd_hire, sd_net, sd_counties)
)

sde_rows <- sde_rows %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    class = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state self-distribution laws, which exempt small breweries ",
  "from mandatory wholesale distribution under the three-tier system, affect beverage manufacturing ",
  "employment, hiring, and geographic expansion? ",
  "\\textbf{Policy mechanism:} Self-distribution laws allow small breweries to bypass the ",
  "mandatory distributor tier and sell directly to retailers, reducing market entry barriers ",
  "and distribution costs for craft producers. ",
  "\\textbf{Outcome definition:} Log quarterly employment in NAICS 312 (Beverage and Tobacco ",
  "Product Manufacturing) from the Quarterly Workforce Indicators; hiring rate (new hires / ",
  "employment); net job creation rate ((firm job gains $-$ losses) / employment); count of ",
  "counties with any NAICS 312 employment. ",
  "\\textbf{Treatment:} Binary indicator for state adoption of brewery self-distribution law. ",
  "\\textbf{Data:} Census LEHD Quarterly Workforce Indicators, 2001--2024, state-quarter-industry level, ",
  "52 states/territories, 4,891 state-quarter observations for NAICS 312. ",
  "\\textbf{Method:} Two-way fixed effects (state + quarter) with staggered treatment; ",
  "Callaway-Sant'Anna and Sun-Abraham as robustness; triple-difference against NAICS 311; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} All US states with QWI coverage; 20 treated states adopting self-distribution ",
  "during 2011--2019, 32 control states with no documented adoption. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

# Panel B: Heterogeneity by sample split (small vs large states)
pre_med <- median(pre_312$Emp, na.rm = TRUE)
sp312_small <- sp312 %>% filter(statefips %in%
  (pre_312 %>% group_by(statefips) %>%
   summarise(m = mean(Emp, na.rm = TRUE)) %>%
   filter(m <= pre_med) %>% pull(statefips)))
sp312_large <- sp312 %>% filter(statefips %in%
  (pre_312 %>% group_by(statefips) %>%
   summarise(m = mean(Emp, na.rm = TRUE)) %>%
   filter(m > pre_med) %>% pull(statefips)))

m_small <- feols(log_emp ~ treated | statefips + time_id,
                 data = sp312_small, cluster = ~statefips)
m_large <- feols(log_emp ~ treated | statefips + time_id,
                 data = sp312_large, cluster = ~statefips)

sde_het <- data.frame(
  outcome = c("Log emp. (small states)", "Log emp. (large states)"),
  beta = c(coef(m_small)["treated"], coef(m_large)["treated"]),
  se = c(se(m_small)["treated"], se(m_large)["treated"]),
  sd_y = c(sd(sp312_small$log_emp[sp312_small$yq < 20113], na.rm = TRUE),
           sd(sp312_large$log_emp[sp312_large$yq < 20113], na.rm = TRUE))
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    class = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Combine panels
tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[4pt]"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

tabF1_lines <- c(tabF1_lines,
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-treatment state size)}} \\\\[4pt]"
)

for (i in 1:nrow(sde_het)) {
  r <- sde_het[i, ]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_robust.tex\n")
cat("  tab4_educ.tex\n")
cat("  tabF1_sde.tex\n")
