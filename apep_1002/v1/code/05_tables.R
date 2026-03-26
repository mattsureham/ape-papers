# 05_tables.R — Generate all LaTeX tables
# apep_1002: Czech EET Abolition and Formalization Hysteresis
# V1 format: tables only, zero figures

source("00_packages.R")

cat("=== Loading all results ===\n")
panel <- readRDS("../data/analysis_panel.rds")
models <- readRDS("../data/main_models.rds")
robustness <- readRDS("../data/robustness_results.rds")
sumstats_data <- readRDS("../data/summary_stats.rds")
es_coefs <- readRDS("../data/event_study_coefs.rds")

# =====================================================================
# TABLE 1: Summary Statistics
# =====================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Compute detailed summary stats
pre_panel <- panel %>% filter(post == 0)
post_panel <- panel %>% filter(post == 1)

cz_pre <- pre_panel %>% filter(czech == 1)
ctrl_pre <- pre_panel %>% filter(czech == 0)
cz_post <- post_panel %>% filter(czech == 1)
ctrl_post <- post_panel %>% filter(czech == 0)

tab1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Quarterly Business Registration Index}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{l S[table-format=3.1] S[table-format=3.1] S[table-format=3.1] S[table-format=3.1]}
\\toprule
 & \\multicolumn{2}{c}{Pre-Abolition (2015--2022)} & \\multicolumn{2}{c}{Post-Abolition (2023--2025)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
 & {Czech Rep.} & {Controls} & {Czech Rep.} & {Controls} \\\\
\\midrule
Mean & %0.1f & %0.1f & %0.1f & %0.1f \\\\
Std. Dev. & %0.1f & %0.1f & %0.1f & %0.1f \\\\
Min & %0.1f & %0.1f & %0.1f & %0.1f \\\\
Max & %0.1f & %0.1f & %0.1f & %0.1f \\\\
\\midrule
Observations & {%d} & {%d} & {%d} & {%d} \\\\
Sectors & {%d} & {%d} & {%d} & {%d} \\\\
Quarters & {%d} & {%d} & {%d} & {%d} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} The registration index is from Eurostat STS\\_RB\\_Q, indexed to 2015 = 100. Czech Republic is the treated unit (EET abolished January 1, 2023). Controls are Hungary, Croatia, Italy, Poland, and Sweden, all of which maintained fiscal enforcement systems. Pre-abolition covers Q1 2015--Q4 2022; post-abolition covers Q1 2023--Q4 2025.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
mean(cz_pre$reg_index, na.rm=T), mean(ctrl_pre$reg_index, na.rm=T),
mean(cz_post$reg_index, na.rm=T), mean(ctrl_post$reg_index, na.rm=T),
sd(cz_pre$reg_index, na.rm=T), sd(ctrl_pre$reg_index, na.rm=T),
sd(cz_post$reg_index, na.rm=T), sd(ctrl_post$reg_index, na.rm=T),
min(cz_pre$reg_index, na.rm=T), min(ctrl_pre$reg_index, na.rm=T),
min(cz_post$reg_index, na.rm=T), min(ctrl_post$reg_index, na.rm=T),
max(cz_pre$reg_index, na.rm=T), max(ctrl_pre$reg_index, na.rm=T),
max(cz_post$reg_index, na.rm=T), max(ctrl_post$reg_index, na.rm=T),
nrow(cz_pre), nrow(ctrl_pre), nrow(cz_post), nrow(ctrl_post),
n_distinct(cz_pre$nace_r2), n_distinct(ctrl_pre$nace_r2),
n_distinct(cz_post$nace_r2), n_distinct(ctrl_post$nace_r2),
n_distinct(cz_pre$TIME_PERIOD), n_distinct(ctrl_pre$TIME_PERIOD),
n_distinct(cz_post$TIME_PERIOD), n_distinct(ctrl_post$TIME_PERIOD)
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Written tab1_summary.tex\n")

# =====================================================================
# TABLE 2: Main DiD Results
# =====================================================================
cat("\n=== Table 2: Main DiD Results ===\n")

m1 <- models$m1; m2 <- models$m2; m3 <- models$m3; m4 <- models$m4

# Helper to format coefficient with stars
fmt_coef <- function(est, pval) {
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.10, "^{*}", "")))
  sprintf("%.3f%s", est, stars)
}

tab2 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Effect of EET Abolition on Business Registrations}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
\\midrule
Czech $\\times$ Post & $%s$ & $%s$ & $%s$ & $%s$ \\\\
 & (%0.3f) & (%0.3f) & (%0.3f) & (%0.3f) \\\\
\\midrule
Country $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes & Yes \\\\
Country trends & No & Yes & No & No \\\\
Sector trends & No & No & Yes & No \\\\
Country $\\times$ Sector trends & No & No & No & Yes \\\\
Observations & %s & %s & %s & %s \\\\
R$^2$ & %0.3f & %0.3f & %0.3f & %0.3f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is the Eurostat quarterly business registration index (2015 = 100). Czech $\\times$ Post equals one for Czech Republic observations from Q1 2023 onward. Controls are Hungary, Croatia, Italy, Poland, and Sweden. Standard errors clustered at the country level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
fmt_coef(coef(m1)["treat"], pvalue(m1)["treat"]),
fmt_coef(coef(m2)["treat"], pvalue(m2)["treat"]),
fmt_coef(coef(m3)["treat"], pvalue(m3)["treat"]),
fmt_coef(coef(m4)["treat"], pvalue(m4)["treat"]),
se(m1)["treat"], se(m2)["treat"], se(m3)["treat"], se(m4)["treat"],
format(nobs(m1), big.mark=","), format(nobs(m2), big.mark=","),
format(nobs(m3), big.mark=","), format(nobs(m4), big.mark=","),
r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m4, "r2")
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Written tab2_main.tex\n")

# =====================================================================
# TABLE 3: Event Study Coefficients
# =====================================================================
cat("\n=== Table 3: Event Study ===\n")

es_rows <- es_coefs %>%
  mutate(
    label = ifelse(rel_q < 0, paste0("$t", rel_q, "$"), paste0("$t+", rel_q, "$")),
    label = ifelse(rel_q == -1, "$t-1$ (ref.)", label),
    stars = case_when(
      abs(estimate / se) > 2.576 & se > 0 ~ "^{***}",
      abs(estimate / se) > 1.96 & se > 0 ~ "^{**}",
      abs(estimate / se) > 1.645 & se > 0 ~ "^{*}",
      TRUE ~ ""
    ),
    coef_str = ifelse(rel_q == -1, "---",
                      sprintf("$%0.2f%s$", estimate, stars)),
    se_str = ifelse(rel_q == -1, "",
                    sprintf("(%0.2f)", se))
  )

es_body <- paste(
  sapply(seq_len(nrow(es_rows)), function(i) {
    sprintf("%s & %s \\\\", es_rows$label[i],
            ifelse(es_rows$se_str[i] == "",
                   es_rows$coef_str[i],
                   paste0(es_rows$coef_str[i], " \\\\\n & ", es_rows$se_str[i])))
  }),
  collapse = "\n"
)

tab3 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Event Study: Czech $\\times$ Quarter Interactions}
\\label{tab:eventstudy}
\\begin{threeparttable}
\\begin{tabular}{lc}
\\toprule
Quarter (relative to abolition) & Coefficient \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Coefficients from regressing the business registration index on interactions between a Czech Republic indicator and quarter dummies, relative to Q4 2022 ($t-1$). Includes country $\\times$ sector and quarter fixed effects. Standard errors clustered at the country level. Endpoints ($t \\leq -8$ and $t \\geq 8$) are binned. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
", es_body)

writeLines(tab3, "../tables/tab3_eventstudy.tex")
cat("Written tab3_eventstudy.tex\n")

# =====================================================================
# TABLE 4: Heterogeneity — Cash-Intensive vs. Non-Cash
# =====================================================================
cat("\n=== Table 4: Heterogeneity ===\n")

m_cash <- models$m_cash
m_noncash <- models$m_noncash
m_phase1 <- models$m_phase1
m_phase2 <- models$m_phase2
m_phase34 <- models$m_phase34

tab4 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Heterogeneity: Cash-Intensive Sectors and EET Exposure Duration}
\\label{tab:hetero}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & \\multicolumn{2}{c}{By Cash Intensity} & \\multicolumn{3}{c}{By EET Phase} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-6}
 & (1) & (2) & (3) & (4) & (5) \\\\
 & {Cash-Int.} & {Non-Cash} & {Phase 1} & {Phase 2} & {Phase 3--4} \\\\
\\midrule
Czech $\\times$ Post & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\
 & (%0.3f) & (%0.3f) & (%0.3f) & (%0.3f) & (%0.3f) \\\\
\\midrule
Country $\\times$ Sector FE & Yes & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Cash-intensive sectors are accommodation and wholesale/retail (NACE I, G). Phase 1 sectors entered EET in December 2016, Phase 2 in March 2017, Phase 3--4 from March--June 2018. All columns include country $\\times$ sector and quarter fixed effects. Standard errors clustered at the country level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
fmt_coef(coef(m_cash)["treat"], pvalue(m_cash)["treat"]),
fmt_coef(coef(m_noncash)["treat"], pvalue(m_noncash)["treat"]),
fmt_coef(coef(m_phase1)["treat"], pvalue(m_phase1)["treat"]),
fmt_coef(coef(m_phase2)["treat"], pvalue(m_phase2)["treat"]),
fmt_coef(coef(m_phase34)["treat"], pvalue(m_phase34)["treat"]),
se(m_cash)["treat"], se(m_noncash)["treat"],
se(m_phase1)["treat"], se(m_phase2)["treat"], se(m_phase34)["treat"],
format(nobs(m_cash), big.mark=","), format(nobs(m_noncash), big.mark=","),
format(nobs(m_phase1), big.mark=","), format(nobs(m_phase2), big.mark=","),
format(nobs(m_phase34), big.mark=",")
)

writeLines(tab4, "../tables/tab4_heterogeneity.tex")
cat("Written tab4_heterogeneity.tex\n")

# =====================================================================
# TABLE 5: Robustness
# =====================================================================
cat("\n=== Table 5: Robustness ===\n")

m_placebo <- robustness$placebo_2020
m_placebo2 <- robustness$placebo_2019
m_nocovid <- robustness$no_covid
m_alt <- robustness$alt_cluster
wcb <- robustness$wcb

# WCB p-value
wcb_p <- if (is.list(wcb)) wcb$p_val else NA

tab5 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & {Placebo 2020} & {Placebo 2019} & {Excl.\\ COVID} & {CS Cluster} \\\\
\\midrule
Treatment $\\times$ Post & $%s$ & $%s$ & $%s$ & $%s$ \\\\
 & (%0.3f) & (%0.3f) & (%0.3f) & (%0.3f) \\\\
\\midrule
Country $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\
Quarter FE & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Wild cluster bootstrap $p$-value (main spec.):} %s} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column 1 assigns a fake treatment date of Q1 2020 using only pre-abolition data. Column 2 assigns Q1 2019 using data through Q4 2019. Column 3 drops Q1 2020--Q4 2021 (COVID period). Column 4 clusters standard errors at the country $\\times$ sector level instead of the country level. The wild cluster bootstrap $p$-value (Webb weights, 9{,}999 replications) applies to the baseline specification in Table~\\ref{tab:main}, column 1. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
fmt_coef(coef(m_placebo)["treat_placebo"], pvalue(m_placebo)["treat_placebo"]),
fmt_coef(coef(m_placebo2)["treat_placebo2"], pvalue(m_placebo2)["treat_placebo2"]),
fmt_coef(coef(m_nocovid)["treat"], pvalue(m_nocovid)["treat"]),
fmt_coef(coef(m_alt)["treat"], pvalue(m_alt)["treat"]),
se(m_placebo)["treat_placebo"], se(m_placebo2)["treat_placebo2"],
se(m_nocovid)["treat"], se(m_alt)["treat"],
format(nobs(m_placebo), big.mark=","), format(nobs(m_placebo2), big.mark=","),
format(nobs(m_nocovid), big.mark=","), format(nobs(m_alt), big.mark=","),
ifelse(is.na(wcb_p), "N/A", sprintf("%.3f", wcb_p))
)

writeLines(tab5, "../tables/tab5_robustness.tex")
cat("Written tab5_robustness.tex\n")

# =====================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# =====================================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

pre_sd <- sumstats_data$pre_sd

# Panel A: Pooled
beta_pooled <- coef(m1)["treat"]
se_pooled <- se(m1)["treat"]
sde_pooled <- beta_pooled / pre_sd
se_sde_pooled <- se_pooled / pre_sd

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# Panel B: Heterogeneous (cash-intensive vs non-cash)
beta_cash <- coef(m_cash)["treat"]
se_cash <- se(m_cash)["treat"]
pre_sd_cash <- sd(panel$reg_index[panel$post == 0 & panel$cash_intensive == TRUE], na.rm = TRUE)
sde_cash <- beta_cash / pre_sd_cash
se_sde_cash <- se_cash / pre_sd_cash

beta_noncash <- coef(m_noncash)["treat"]
se_noncash <- se(m_noncash)["treat"]
pre_sd_noncash <- sd(panel$reg_index[panel$post == 0 & panel$cash_intensive == FALSE], na.rm = TRUE)
sde_noncash <- beta_noncash / pre_sd_noncash
se_sde_noncash <- se_noncash / pre_sd_noncash

# Build SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Czech Republic (treated) vs.\\ Hungary, Croatia, Italy, Poland, Sweden (controls). ",
  "\\textbf{Research question:} Does the abolition of mandatory electronic sales registration (EET) reverse ",
  "formalization gains in business registrations? ",
  "\\textbf{Policy mechanism:} The Czech government permanently abolished its EET system on January 1, 2023, ",
  "removing the requirement for real-time electronic reporting of cash transactions that had been in force since ",
  "December 2016, thereby eliminating the primary enforcement lever against shadow-economy activity in cash-intensive sectors. ",
  "\\textbf{Outcome definition:} Eurostat quarterly business registration index (STS\\_RB\\_Q), measuring the number of ",
  "newly registered businesses per quarter, indexed to 2015 = 100. ",
  "\\textbf{Treatment:} Binary (0/1); equals one for Czech Republic observations from Q1 2023 onward. ",
  "\\textbf{Data:} Eurostat STS\\_RB\\_Q, Q1 2015--Q4 2025, country $\\times$ NACE sector $\\times$ quarter panel, ",
  sprintf("N = %s. ", format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} Two-way fixed effects DiD with country $\\times$ sector and quarter fixed effects; ",
  "standard errors clustered at the country level with wild cluster bootstrap for small-cluster inference. ",
  "\\textbf{Sample:} Six European countries with comparable fiscal enforcement systems; sectors restricted to ",
  "those covered by EET phases (NACE C, F, G, H, I, M, N). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Business registrations & %0.3f & %0.3f & %0.2f & %0.3f & %0.3f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
Cash-intensive sectors & %0.3f & %0.3f & %0.2f & %0.3f & %0.3f & %s \\\\
Non-cash sectors & %0.3f & %0.3f & %0.2f & %0.3f & %0.3f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
beta_pooled, se_pooled, pre_sd, sde_pooled, se_sde_pooled, classify(sde_pooled),
beta_cash, se_cash, pre_sd_cash, sde_cash, se_sde_cash, classify(sde_cash),
beta_noncash, se_noncash, pre_sd_noncash, sde_noncash, se_sde_noncash, classify(sde_noncash),
sde_notes
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Written tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
