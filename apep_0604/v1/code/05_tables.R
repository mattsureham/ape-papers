# 05_tables.R — Generate all LaTeX tables
# APEP-0604: Colombia FARC Peace and Education

source("code/00_packages.R")

load("data/models.RData")
load("data/robustness_models.RData")

dir.create("tables", showWarnings = FALSE)

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("=== Generating Table 1: Summary Statistics ===\n")

panel_pre <- panel %>% filter(year <= 2014)

# Overall summary
stats_all <- panel %>%
  summarise(
    across(c(net_secondary, net_primary, dropout_total, dropout_secondary,
             approval_total, net_media, farc_events_pre, farc_events_yr),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

# By FARC exposure (pre-period)
stats_by_farc <- panel_pre %>%
  mutate(group = ifelse(high_farc == 1, "High FARC (>=3 events)", "Low/No FARC")) %>%
  group_by(group) %>%
  summarise(
    n_munis = n_distinct(mun_code),
    sec_enroll = mean(net_secondary, na.rm = TRUE),
    pri_enroll = mean(net_primary, na.rm = TRUE),
    dropout = mean(dropout_total, na.rm = TRUE),
    dropout_sec = mean(dropout_secondary, na.rm = TRUE),
    approval = mean(approval_total, na.rm = TRUE),
    class_size = mean(class_size, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-period means by FARC exposure:\n")
print(stats_by_farc)

# Write LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Ceasefire Municipal Education Indicators (2011--2014)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Low/No FARC} & \\multicolumn{2}{c}{High FARC ($\\geq$3 events)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n"
)

# Compute stats for both groups
for_tab <- panel_pre %>%
  mutate(group = ifelse(high_farc == 1, "high", "low"))

vars_info <- list(
  list(var = "net_secondary", label = "Net secondary enrollment (\\%)"),
  list(var = "net_primary", label = "Net primary enrollment (\\%)"),
  list(var = "dropout_total", label = "Overall dropout rate (\\%)"),
  list(var = "dropout_secondary", label = "Secondary dropout rate (\\%)"),
  list(var = "approval_total", label = "Approval rate (\\%)"),
  list(var = "class_size", label = "Average class size"),
  list(var = "internet_pct", label = "Schools with internet (\\%)")
)

for (vi in vars_info) {
  low_stats <- for_tab %>% filter(group == "low") %>%
    summarise(m = mean(.data[[vi$var]], na.rm = TRUE),
              s = sd(.data[[vi$var]], na.rm = TRUE))
  high_stats <- for_tab %>% filter(group == "high") %>%
    summarise(m = mean(.data[[vi$var]], na.rm = TRUE),
              s = sd(.data[[vi$var]], na.rm = TRUE))
  tab1_tex <- paste0(tab1_tex,
    sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\\n",
            vi$label, low_stats$m, low_stats$s, high_stats$m, high_stats$s))
}

n_low <- n_distinct(for_tab$mun_code[for_tab$group == "low"])
n_high <- n_distinct(for_tab$mun_code[for_tab$group == "high"])

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  sprintf("Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n", n_low, n_high),
  sprintf("Municipality-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nrow(for_tab %>% filter(group == "low")), big.mark = ","),
          format(nrow(for_tab %>% filter(group == "high")), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Pre-ceasefire period (2011--2014). ``High FARC'' municipalities are those with three or more FARC-attributed violent events (UCDP GED) during 2010--2014. Education data from Colombia's Ministry of Education via datos.gov.co. Net enrollment rates can exceed 100\\% due to measurement methodology.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

# ---------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------
cat("\n=== Generating Table 2: Main Results ===\n")

# Main results table with multiple outcomes
models_main <- list(
  "Secondary" = m1_secondary,
  "Primary" = m1_primary,
  "Dropout" = m1_dropout,
  "Sec. Dropout" = m1_dropout_sec,
  "Approval" = m1_approval
)

# Extract key statistics
tab2_rows <- lapply(models_main, function(m) {
  cf <- coef(m)
  se <- se(m)
  pv <- pvalue(m)
  n <- m$nobs
  list(beta = cf[1], se = se[1], pval = pv[1], n = n)
})

# Format stars
star_fn <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of FARC Ceasefire on Municipal Education Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Net & Net & Overall & Secondary & Approval \\\\\n",
  " & Secondary & Primary & Dropout & Dropout & Rate \\\\\n",
  "\\midrule\n",
  "\\\\[-1em]\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Continuous treatment (FARC events $\\times$ Post)}} \\\\\n",
  "\\\\[0.3em]\n"
)

betas <- sapply(tab2_rows, function(x) x$beta)
ses <- sapply(tab2_rows, function(x) x$se)
pvals <- sapply(tab2_rows, function(x) x$pval)
ns <- sapply(tab2_rows, function(x) x$n)

tab2_tex <- paste0(tab2_tex,
  sprintf("FARC intensity $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          betas[1], star_fn(pvals[1]), betas[2], star_fn(pvals[2]),
          betas[3], star_fn(pvals[3]), betas[4], star_fn(pvals[4]),
          betas[5], star_fn(pvals[5])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          ses[1], ses[2], ses[3], ses[4], ses[5]),
  sprintf("N & %s & %s & %s & %s & %s \\\\\n",
          format(ns[1], big.mark = ","), format(ns[2], big.mark = ","),
          format(ns[3], big.mark = ","), format(ns[4], big.mark = ","),
          format(ns[5], big.mark = ",")),
  "\\\\[0.5em]\n"
)

# Panel B: Binary high-intensity treatment
tab2_tex <- paste0(tab2_tex,
  "\\multicolumn{6}{l}{\\textit{Panel B: Binary treatment (High FARC $\\geq$3 events $\\times$ Post)}} \\\\\n",
  "\\\\[0.3em]\n"
)

# Run high-intensity for all outcomes
m_high_primary <- feols(net_primary ~ high_farc:post_ceasefire | mun_code + year, data = panel, cluster = ~dept_code)
m_high_dropout <- feols(dropout_total ~ high_farc:post_ceasefire | mun_code + year, data = panel, cluster = ~dept_code)
m_high_dropout_sec <- feols(dropout_secondary ~ high_farc:post_ceasefire | mun_code + year, data = panel, cluster = ~dept_code)
m_high_approval <- feols(approval_total ~ high_farc:post_ceasefire | mun_code + year, data = panel, cluster = ~dept_code)

high_models <- list(r1_high, m_high_primary, m_high_dropout, m_high_dropout_sec, m_high_approval)
high_betas <- sapply(high_models, function(m) coef(m)[1])
high_ses <- sapply(high_models, function(m) se(m)[1])
high_pvals <- sapply(high_models, function(m) pvalue(m)[1])
high_ns <- sapply(high_models, function(m) m$nobs)

tab2_tex <- paste0(tab2_tex,
  sprintf("High FARC $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          high_betas[1], star_fn(high_pvals[1]), high_betas[2], star_fn(high_pvals[2]),
          high_betas[3], star_fn(high_pvals[3]), high_betas[4], star_fn(high_pvals[4]),
          high_betas[5], star_fn(high_pvals[5])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          high_ses[1], high_ses[2], high_ses[3], high_ses[4], high_ses[5]),
  sprintf("N & %s & %s & %s & %s & %s \\\\\n",
          format(high_ns[1], big.mark = ","), format(high_ns[2], big.mark = ","),
          format(high_ns[3], big.mark = ","), format(high_ns[4], big.mark = ","),
          format(high_ns[5], big.mark = ",")),
  "\\midrule\n",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & Dept. & Dept. & Dept. & Dept. & Dept. \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports a separate regression. Panel A uses continuous treatment intensity (count of FARC-attributed events 2010--2014 from UCDP GED). Panel B uses a binary indicator for municipalities with $\\geq$3 events. Post = 2015--2024 (post-ceasefire). All specifications include municipality and year fixed effects with standard errors clustered at the department level (34 departments). * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "tables/tab2_main.tex")
cat("  Written tables/tab2_main.tex\n")

# ---------------------------------------------------------------
# Table 3: Two-Shock Decomposition
# ---------------------------------------------------------------
cat("\n=== Generating Table 3: Two-Shock Decomposition ===\n")

# Run two-shock for all key outcomes
m2_primary <- feols(
  net_primary ~ farc_events_pre:post1_ceasefire_only +
    farc_events_pre:post2_pdet | mun_code + year,
  data = panel, cluster = ~dept_code
)

m2_approval <- feols(
  approval_total ~ farc_events_pre:post1_ceasefire_only +
    farc_events_pre:post2_pdet | mun_code + year,
  data = panel, cluster = ~dept_code
)

# Also run high-intensity two-shock
m2h_secondary <- feols(
  net_secondary ~ high_farc:post1_ceasefire_only +
    high_farc:post2_pdet | mun_code + year,
  data = panel, cluster = ~dept_code
)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Two-Shock Decomposition: Ceasefire vs.\\ PDET Investment}\n",
  "\\label{tab:twoshock}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Net Sec. & Net Sec. & Net Pri. & Approval \\\\\n",
  " & (continuous) & (binary) & (continuous) & (continuous) \\\\\n",
  "\\midrule\n"
)

# Continuous secondary
cf2s <- coef(m2_secondary); se2s <- se(m2_secondary); pv2s <- pvalue(m2_secondary)
cf2h <- coef(m2h_secondary); se2h <- se(m2h_secondary); pv2h <- pvalue(m2h_secondary)
cf2p <- coef(m2_primary); se2p <- se(m2_primary); pv2p <- pvalue(m2_primary)
cf2a <- coef(m2_approval); se2a <- se(m2_approval); pv2a <- pvalue(m2_approval)

tab3_tex <- paste0(tab3_tex,
  sprintf("Treatment $\\times$ Ceasefire only & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          cf2s[1], star_fn(pv2s[1]), cf2h[1], star_fn(pv2h[1]),
          cf2p[1], star_fn(pv2p[1]), cf2a[1], star_fn(pv2a[1])),
  sprintf("\\quad (2015--2017) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se2s[1], se2h[1], se2p[1], se2a[1]),
  sprintf("Treatment $\\times$ Ceasefire + PDET & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          cf2s[2], star_fn(pv2s[2]), cf2h[2], star_fn(pv2h[2]),
          cf2p[2], star_fn(pv2p[2]), cf2a[2], star_fn(pv2a[2])),
  sprintf("\\quad (2018--2024) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se2s[2], se2h[2], se2p[2], se2a[2]),
  sprintf("N & %s & %s & %s & %s \\\\\n",
          format(m2_secondary$nobs, big.mark = ","), format(m2h_secondary$nobs, big.mark = ","),
          format(m2_primary$nobs, big.mark = ","), format(m2_approval$nobs, big.mark = ",")),
  "\\midrule\n",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Clustering & Dept. & Dept. & Dept. & Dept. \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports a separate regression decomposing the post-ceasefire period into two phases: the ceasefire-only period (2015--2017, before PDET investment began) and the ceasefire-plus-PDET period (2018--2024). ``Treatment'' is continuous FARC intensity (columns 1, 3, 4) or binary high-FARC indicator (column 2). Standard errors clustered at the department level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "tables/tab3_twoshock.tex")
cat("  Written tables/tab3_twoshock.tex\n")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("\n=== Generating Table 4: Robustness ===\n")

rob_models <- list(
  "Baseline" = m1_secondary,
  "Log intensity" = r1_log,
  "Deaths-based" = r1_deaths,
  "High FARC ($\\geq$3)" = r1_high,
  "Excl. capitals" = r2_no_capitals,
  "Mun. cluster" = r3_mun_cluster,
  "Excl. 2020" = r4_no_covid,
  "PDET only" = r8_pdet_only
)

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness: Effect on Net Secondary Enrollment}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\\\\n"
)

# Header row with specification names
tab4_tex <- paste0(tab4_tex,
  " & Baseline & Log & Deaths & High & Excl. & Mun. & Excl. & PDET \\\\\n",
  " & & intensity & based & FARC & capitals & cluster & 2020 & only \\\\\n",
  "\\midrule\n"
)

rob_betas <- sapply(rob_models, function(m) coef(m)[1])
rob_ses <- sapply(rob_models, function(m) se(m)[1])
rob_pvals <- sapply(rob_models, function(m) pvalue(m)[1])
rob_ns <- sapply(rob_models, function(m) m$nobs)

tab4_tex <- paste0(tab4_tex,
  paste0("Treatment $\\times$ Post & ",
         paste(sprintf("%.3f%s", rob_betas, sapply(rob_pvals, star_fn)), collapse = " & "),
         " \\\\\n"),
  paste0(" & ",
         paste(sprintf("(%.3f)", rob_ses), collapse = " & "),
         " \\\\\n"),
  paste0("N & ",
         paste(format(rob_ns, big.mark = ","), collapse = " & "),
         " \\\\\n"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is net secondary enrollment rate. Column (1) is the baseline continuous-treatment specification. Column (2) uses log(1 + FARC events). Column (3) uses FARC deaths as treatment intensity. Column (4) uses a binary indicator for $\\geq$3 events. Column (5) excludes department capitals. Column (6) clusters at the municipality level instead of department. Column (7) drops 2020 (COVID disruption). Column (8) restricts to PDET municipalities. All specifications include municipality and year fixed effects. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "tables/tab4_robustness.tex")
cat("  Written tables/tab4_robustness.tex\n")

# ---------------------------------------------------------------
# Table 5: Violence Reduction (First Stage)
# ---------------------------------------------------------------
cat("\n=== Generating Table 5: Violence First Stage ===\n")

tab5_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Violence Reduction After Ceasefire (First Stage)}\n",
  "\\label{tab:violence}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & FARC events & FARC events \\\\\n",
  " & (pooled post) & (by period) \\\\\n",
  "\\midrule\n"
)

cv <- coef(r9_violence); sv <- se(r9_violence); pv_v <- pvalue(r9_violence)
cv2 <- coef(r9_violence_2); sv2 <- se(r9_violence_2); pv_v2 <- pvalue(r9_violence_2)

tab5_tex <- paste0(tab5_tex,
  sprintf("FARC intensity $\\times$ Post & %.4f%s & \\\\\n", cv[1], star_fn(pv_v[1])),
  sprintf(" & (%.4f) & \\\\\n", sv[1]),
  sprintf("FARC intensity $\\times$ Ceasefire only & & %.4f%s \\\\\n", cv2[1], star_fn(pv_v2[1])),
  sprintf("\\quad (2015--2017) & & (%.4f) \\\\\n", sv2[1]),
  sprintf("FARC intensity $\\times$ PDET & & %.4f%s \\\\\n", cv2[2], star_fn(pv_v2[2])),
  sprintf("\\quad (2018--2024) & & (%.4f) \\\\\n", sv2[2]),
  sprintf("N & %s & %s \\\\\n",
          format(r9_violence$nobs, big.mark = ","), format(r9_violence_2$nobs, big.mark = ",")),
  "\\midrule\n",
  "Municipality FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Clustering & Dept. & Dept. \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is the annual count of FARC-attributed events (UCDP GED) in municipality $m$ and year $t$. Treatment intensity is the count of FARC events during 2010--2014. Column (1) pools the entire post-ceasefire period. Column (2) separates the ceasefire-only period (2015--2017) from the PDET period (2018--2024). The sharp decline in column (2) confirms that the ceasefire was differentially binding in high-intensity municipalities. Standard errors clustered at the department level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, "tables/tab5_violence.tex")
cat("  Written tables/tab5_violence.tex\n")

# ---------------------------------------------------------------
# SDE Table (Mandatory Appendix)
# ---------------------------------------------------------------
cat("\n=== Generating SDE Table ===\n")

# Use main results (both continuous and high-intensity binary)
sde_data <- tibble(
  outcome = c("Net secondary enrollment", "Net secondary enrollment",
              "Overall dropout rate", "Approval rate"),
  spec = c("Continuous", "Binary ($\\geq$3)", "Continuous", "Continuous"),
  beta = c(coef(m1_secondary)[1], coef(r1_high)[1],
           coef(m1_dropout)[1], coef(m1_approval)[1]),
  se_beta = c(se(m1_secondary)[1], se(r1_high)[1],
              se(m1_dropout)[1], se(m1_approval)[1]),
  sd_y = c(sd(panel$net_secondary, na.rm = TRUE),
           sd(panel$net_secondary, na.rm = TRUE),
           sd(panel$dropout_total, na.rm = TRUE),
           sd(panel$approval_total, na.rm = TRUE)),
  sd_x = c(sd(panel$farc_events_pre), NA,
           sd(panel$farc_events_pre),
           sd(panel$farc_events_pre))
) %>%
  mutate(
    sde = ifelse(is.na(sd_x), beta / sd_y, beta * sd_x / sd_y),
    se_sde = ifelse(is.na(sd_x), se_beta / sd_y, se_beta * sd_x / sd_y),
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde < 0.005 ~ "Null",
      sde < 0.05 ~ "Small positive",
      sde < 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

sde_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(sde_data))) {
  row <- sde_data[i, ]
  sd_x_str <- ifelse(is.na(row$sd_x), "---", sprintf("%.2f", row$sd_x))
  sde_tex <- paste0(sde_tex,
    sprintf("%s & %s & %.3f & %s & %.2f & %.4f & %.4f & %s \\\\\n",
            row$outcome, row$spec, row$beta, sd_x_str, row$sd_y,
            row$sde, row$se_sde, row$classification))
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For the binary treatment (row 2), SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) column is marked ``---''. ",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
  "SD($Y$) and SD($X$) are unconditional standard deviations from the full sample.\n\n",
  "\\textbf{Research question:} Does the cessation of armed conflict improve educational outcomes in Colombia's formerly violent municipalities?\n",
  "\\textbf{Treatment:} Continuous (FARC event count 2010--2014) or binary ($\\geq$3 events).\n",
  sprintf("\\textbf{Data:} Colombia Ministry of Education municipal panel, 2011--2024, %s municipality-years.\n",
          format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} Two-way fixed effects DiD with department-clustered standard errors.\n",
  sprintf("\\textbf{Sample:} %d municipalities, %d with pre-ceasefire FARC events, %d departments.\n\n",
          n_distinct(panel$mun_code), sum(panel$any_farc[panel$year == 2011]),
          n_distinct(panel$dept_code)),
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ",
  "``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
