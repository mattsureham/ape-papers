# 05_tables.R — Generate all tables
# apep_0734: Wales 20mph Speed Limit and Road Casualties

source("00_packages.R")

cat("=== Loading models ===\n")
load("../data/models.RData")
load("../data/robustness_models.RData")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

# Pre-treatment period
pre <- panel[post == 0]

# Welsh pre-treatment
w_pre <- pre[wales == 1, .(
  casualties_mean = mean(casualties),
  casualties_sd = sd(casualties),
  fatal_mean = mean(fatal),
  fatal_sd = sd(fatal),
  serious_mean = mean(serious),
  collisions_mean = mean(collisions),
  n_la_quarters = .N
)]

# English pre-treatment
e_pre <- pre[wales == 0, .(
  casualties_mean = mean(casualties),
  casualties_sd = sd(casualties),
  fatal_mean = mean(fatal),
  fatal_sd = sd(fatal),
  serious_mean = mean(serious),
  collisions_mean = mean(collisions),
  n_la_quarters = .N
)]

# Post-treatment
w_post <- panel[wales == 1 & post == 1, .(casualties_mean = mean(casualties), casualties_sd = sd(casualties))]
e_post <- panel[wales == 0 & post == 1, .(casualties_mean = mean(casualties), casualties_sd = sd(casualties))]

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Casualties on Restricted Roads by Country and Period}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{l",
  paste(rep("S[table-format=3.1]", 4), collapse = ""),
  "}\n",
  "\\toprule\n",
  "& \\multicolumn{2}{c}{Wales (Treated)} & \\multicolumn{2}{c}{England (Control)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "& {Mean} & {Std.\\ Dev.} & {Mean} & {Std.\\ Dev.} \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-Treatment (2019--2023Q3)}} \\\\\n",
  sprintf("Casualties (restricted roads) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          w_pre$casualties_mean, w_pre$casualties_sd, e_pre$casualties_mean, e_pre$casualties_sd),
  sprintf("Fatal casualties & %.2f & %.2f & %.2f & %.2f \\\\\n",
          w_pre$fatal_mean, w_pre$fatal_sd, e_pre$fatal_mean, e_pre$fatal_sd),
  sprintf("Serious casualties & %.1f & %.1f & %.1f & %.1f \\\\\n",
          w_pre$serious_mean, w_pre$serious_sd, e_pre$serious_mean, e_pre$serious_sd),
  sprintf("Collisions & %.1f & %.1f & %.1f & %.1f \\\\\n",
          w_pre$collisions_mean, w_pre$collisions_sd, e_pre$collisions_mean, e_pre$collisions_sd),
  sprintf("LA-quarters & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          w_pre$n_la_quarters, e_pre$n_la_quarters),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Post-Treatment (2023Q4--2024)}} \\\\\n",
  sprintf("Casualties (restricted roads) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          w_post$casualties_mean, w_post$casualties_sd, e_post$casualties_mean, e_post$casualties_sd),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} Panel A shows means and standard deviations of LA-quarter-level outcomes during the pre-treatment period (2019Q1--2023Q3). Panel B shows post-treatment means (2023Q4--2024Q4). Restricted roads are those with 20 or 30 mph speed limits. Wales has %d LAs; England has %d LAs. Source: DfT STATS19.\n",
          uniqueN(panel[wales == 1]$la_code), uniqueN(panel[wales == 0]$la_code)),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written\n")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

# Collect coefficients
get_row <- function(mod, label) {
  b <- coef(mod)["treat"]
  s <- se(mod)["treat"]
  p <- pvalue(mod)["treat"]
  n <- mod$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  list(label = label, beta = b, se = s, pval = p, stars = stars, n = n)
}

r1 <- get_row(m1, "Log casualties (restricted)")
r2 <- get_row(m1_level, "Casualties (level)")
r_fs <- get_row(m_fs, "Log fatal + serious")
r_sl <- get_row(m_sl, "Log slight")

# Wild cluster bootstrap info
wcb_str <- ""
if (!is.null(boot_m1)) {
  wcb_str <- sprintf("%.3f", boot_m1$p_val)
} else {
  wcb_str <- "---"
}

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Wales 20mph Default on Road Casualties}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "& (1) & (2) & (3) & (4) \\\\\n",
  "& Log casualties & Casualties & Log fatal/ & Log slight \\\\\n",
  "& (restricted) & (level) & serious & \\\\\n",
  "\\midrule\n",
  sprintf("Wales $\\times$ Post & %s%.3f & %s%.1f & %s%.3f & %s%.3f \\\\\n",
          ifelse(r1$beta < 0, "$-$", ""), abs(r1$beta),
          ifelse(r2$beta < 0, "$-$", ""), abs(r2$beta),
          ifelse(r_fs$beta < 0, "$-$", ""), abs(r_fs$beta),
          ifelse(r_sl$beta < 0, "$-$", ""), abs(r_sl$beta)),
  sprintf("& (%.3f)%s & (%.1f)%s & (%.3f)%s & (%.3f)%s \\\\\n",
          r1$se, r1$stars, r2$se, r2$stars, r_fs$se, r_fs$stars, r_sl$se, r_sl$stars),
  sprintf("WCB $p$-value & %s & & & \\\\\n", wcb_str),
  "\\midrule\n",
  "LA FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
          format(r_fs$n, big.mark = ","), format(r_sl$n, big.mark = ","),
          format(uniqueN(panel$la_code), big.mark = ",")),
  sprintf("LAs & %d & %d & %d & %d \\\\\n",
          uniqueN(panel$la_code), uniqueN(panel$la_code),
          uniqueN(panel$la_code), uniqueN(panel$la_code)),
  sprintf("Welsh LAs & %d & %d & %d & %d \\\\\n",
          uniqueN(panel[wales == 1]$la_code), uniqueN(panel[wales == 1]$la_code),
          uniqueN(panel[wales == 1]$la_code), uniqueN(panel[wales == 1]$la_code)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the coefficient on Wales $\\times$ Post from a two-way fixed effects regression with LA and quarter fixed effects. Standard errors clustered at the LA level in parentheses. WCB = wild cluster bootstrap $p$-value (Webb weights, 9,999 replications). Restricted roads are those with 20 or 30 mph speed limits. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written\n")

# ============================================================
# TABLE 3: By Road Type (Mechanism)
# ============================================================
cat("\n=== Table 3: By Road Type ===\n")

r_20 <- get_row(m_20, "20mph")
r_30 <- get_row(m_30, "30mph")
r_hi <- get_row(m_high, "40+ mph")

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect by Speed Limit Category: Reclassification vs.\\ Placebo}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "& (1) & (2) & (3) \\\\\n",
  "& Log casualties & Log casualties & Log casualties \\\\\n",
  "& (20 mph) & (30 mph) & (40+ mph) \\\\\n",
  "\\midrule\n",
  sprintf("Wales $\\times$ Post & %s%.3f & %s%.3f & %s%.3f \\\\\n",
          ifelse(r_20$beta < 0, "$-$", ""), abs(r_20$beta),
          ifelse(r_30$beta < 0, "$-$", ""), abs(r_30$beta),
          ifelse(r_hi$beta < 0, "$-$", ""), abs(r_hi$beta)),
  sprintf("& (%.3f)%s & (%.3f)%s & (%.3f)%s \\\\\n",
          r_20$se, r_20$stars, r_30$se, r_30$stars, r_hi$se, r_hi$stars),
  "\\midrule\n",
  "LA FE & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(r_20$n, big.mark = ","), format(r_30$n, big.mark = ","),
          format(r_hi$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the DiD coefficient for casualties on roads with different posted speed limits. Column (1): roads posted at 20 mph. Column (2): roads posted at 30 mph (the roads reclassified to 20 mph in Wales). Column (3): roads posted at 40 mph or above (placebo --- unaffected by the policy). Standard errors clustered at the LA level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_mechanism.tex")
cat("Table 3 written\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

r_nc <- get_row(m_nocovid, "Excl. COVID")
r_sh <- get_row(m_short, "Short window")
r_col <- get_row(m_collisions, "Collisions")

# Poisson
if (!is.null(m_poisson)) {
  r_poi <- get_row(m_poisson, "Poisson")
} else {
  r_poi <- list(beta = NA, se = NA, stars = "", n = NA)
}

# Border
if (!is.null(m_border)) {
  r_bor <- get_row(m_border, "Border LAs")
} else {
  r_bor <- list(beta = NA, se = NA, stars = "", n = NA)
}

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  "& (1) & (2) & (3) & (4) & (5) \\\\\n",
  "& Baseline & Excl.\\ COVID & Short & Poisson & Collisions \\\\\n",
  "& & (2020--21) & window & & \\\\\n",
  "\\midrule\n",
  sprintf("Wales $\\times$ Post & %s%.3f & %s%.3f & %s%.3f & %s & %s%.3f \\\\\n",
          ifelse(r1$beta < 0, "$-$", ""), abs(r1$beta),
          ifelse(r_nc$beta < 0, "$-$", ""), abs(r_nc$beta),
          ifelse(r_sh$beta < 0, "$-$", ""), abs(r_sh$beta),
          ifelse(!is.na(r_poi$beta), sprintf("%s%.3f", ifelse(r_poi$beta < 0, "$-$", ""), abs(r_poi$beta)), "---"),
          ifelse(r_col$beta < 0, "$-$", ""), abs(r_col$beta)),
  sprintf("& (%.3f)%s & (%.3f)%s & (%.3f)%s & %s & (%.3f)%s \\\\\n",
          r1$se, r1$stars, r_nc$se, r_nc$stars, r_sh$se, r_sh$stars,
          ifelse(!is.na(r_poi$se), sprintf("(%.3f)%s", r_poi$se, r_poi$stars), "---"),
          r_col$se, r_col$stars),
  "\\midrule\n",
  "LA FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(r1$n, big.mark = ","),
          format(r_nc$n, big.mark = ","),
          format(r_sh$n, big.mark = ","),
          ifelse(!is.na(r_poi$n), format(r_poi$n, big.mark = ","), "---"),
          format(r_col$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) replicates the baseline log casualties specification. Column (2) excludes the COVID-affected period (2020Q1--2021Q4). Column (3) uses a shorter pre-treatment window (2022Q1--2023Q3). Column (4) estimates a Poisson regression on casualty counts. Column (5) uses log collisions instead of log casualties as the outcome. All specifications include LA and quarter fixed effects with LA-clustered standard errors. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")
cat("Table 4 written\n")

# ============================================================
# TABLE F1: SDE Table (MANDATORY)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# SD(Y) from pre-treatment period
pre <- panel[post == 0]
sd_casualties <- sd(pre$log_casualties, na.rm = TRUE)
sd_fatal_serious <- sd(pre$log_fatal_serious, na.rm = TRUE)
sd_slight <- sd(pre$log_slight, na.rm = TRUE)
sd_cas_high <- sd(pre$log_cas_high, na.rm = TRUE)

# Main specification
beta_main <- coef(m1)["treat"]
se_main <- se(m1)["treat"]
sde_main <- beta_main / sd_casualties
se_sde_main <- se_main / sd_casualties

# Fatal+serious
beta_fs <- coef(m_fs)["treat"]
se_fs_val <- se(m_fs)["treat"]
sde_fs <- beta_fs / sd_fatal_serious
se_sde_fs <- se_fs_val / sd_fatal_serious

# Slight
beta_sl <- coef(m_sl)["treat"]
se_sl_val <- se(m_sl)["treat"]
sde_sl <- beta_sl / sd_slight
se_sde_sl <- se_sl_val / sd_slight

# Placebo (high-speed)
beta_hi <- coef(m_high)["treat"]
se_hi_val <- se(m_high)["treat"]
sde_hi <- beta_hi / sd_cas_high
se_sde_hi <- se_hi_val / sd_cas_high

# Classification function
classify_sde <- function(s) {
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

sde_rows <- data.frame(
  Outcome = c("Total casualties (restricted)", "Fatal \\& serious", "Slight injuries", "Placebo: 40+ mph roads"),
  Spec = rep("TWFE DiD", 4),
  Beta = c(beta_main, beta_fs, beta_sl, beta_hi),
  SE = c(se_main, se_fs_val, se_sl_val, se_hi_val),
  SDY = c(sd_casualties, sd_fatal_serious, sd_slight, sd_cas_high),
  SDE = c(sde_main, sde_fs, sde_sl, sde_hi),
  SE_SDE = c(se_sde_main, se_sde_fs, se_sde_sl, se_sde_hi),
  Classification = classify_sde(c(sde_main, sde_fs, sde_sl, sde_hi))
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (Wales vs.\\ England). ",
  "\\textbf{Research question:} Does lowering the default urban speed limit from 30 to 20 mph reduce road casualties? ",
  "\\textbf{Policy mechanism:} Wales's September 2023 Restricted Roads Order reclassified all roads with street lighting ",
  "from a 30 mph to a 20 mph default, affecting thousands of road segments across all 22 local authorities; ",
  "England retained its 30 mph default, providing a counterfactual. ",
  "\\textbf{Outcome definition:} Log of quarterly casualty counts on restricted-speed roads (20 and 30 mph combined) ",
  "from police-reported STATS19 collision records, disaggregated by severity. ",
  "\\textbf{Treatment:} Binary --- Welsh local authorities after September 2023 vs.\\ English local authorities. ",
  "\\textbf{Data:} DfT STATS19 collision and casualty records, 2019--2024, aggregated to LA-quarter panel; ",
  sprintf("%s observations across %d local authorities. ",
          format(nrow(panel), big.mark = ","), uniqueN(panel$la_code)),
  "\\textbf{Method:} Two-way fixed effects DiD with LA and quarter fixed effects, standard errors clustered at LA level, ",
  "wild cluster bootstrap for inference with 22 treated Welsh clusters. ",
  "\\textbf{Sample:} All local authority districts in England and Wales; Scotland excluded due to concurrent 20 mph pilots. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sde_rows)) {
  sde_tab <- paste0(sde_tab, sprintf(
    "%s & %s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    sde_rows$Outcome[i], sde_rows$Spec[i],
    sde_rows$Beta[i], sde_rows$SE[i], sde_rows$SDY[i],
    sde_rows$SDE[i], sde_rows$SE_SDE[i], sde_rows$Classification[i]
  ))
}

sde_tab <- paste0(sde_tab,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(sde_tab, "../tables/tabF1_sde.tex")
cat("SDE table written\n")

cat("\n=== All tables generated ===\n")
