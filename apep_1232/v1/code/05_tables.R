## 05_tables.R — Generate all LaTeX tables
## APEP-1232: Medicaid Doula Reimbursement and Birth Outcomes

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ─── Helper: format numbers ─────────────────────────────────────────────────
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt_pct <- function(x, d = 1) formatC(x * 100, format = "f", digits = d)
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics\n")

med_panel <- panel %>% filter(payer == "medicaid", first_treat == 0 | first_treat >= 2018)
priv_panel <- panel %>% filter(payer == "private", first_treat == 0 | first_treat >= 2018)

make_sumstats <- function(d, label) {
  w <- d$births
  data.frame(
    total_births = sum(w),
    csrate = weighted.mean(d$csection_rate, w),
    csrate_sd = sqrt(weighted.mean((d$csection_rate - weighted.mean(d$csection_rate, w))^2, w)),
    preterm = weighted.mean(d$preterm_rate, w),
    preterm_sd = sqrt(weighted.mean((d$preterm_rate - weighted.mean(d$preterm_rate, w))^2, w)),
    lbw = weighted.mean(d$lbw_rate, w),
    lbw_sd = sqrt(weighted.mean((d$lbw_rate - weighted.mean(d$lbw_rate, w))^2, w)),
    group = label
  )
}

ss_med_treat <- med_panel %>% filter(first_treat > 0) %>% make_sumstats("Treated (Medicaid)")
ss_med_ctrl <- med_panel %>% filter(first_treat == 0) %>% make_sumstats("Control (Medicaid)")
ss_priv_treat <- priv_panel %>% filter(first_treat > 0) %>% make_sumstats("Treated (Private)")
ss_priv_ctrl <- priv_panel %>% filter(first_treat == 0) %>% make_sumstats("Control (Private)")

ss <- bind_rows(ss_med_treat, ss_med_ctrl, ss_priv_treat, ss_priv_ctrl)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Treated & Control & Treated & Control \\\\\n",
  " & (Medicaid) & (Medicaid) & (Private) & (Private) \\\\\n",
  "\\hline\n"
)

for (v in c("csrate", "preterm", "lbw")) {
  vname <- switch(v,
    csrate = "C-section rate",
    preterm = "Preterm birth rate",
    lbw = "Low birth weight rate"
  )
  vals <- sapply(list(ss_med_treat, ss_med_ctrl, ss_priv_treat, ss_priv_ctrl),
                 function(x) fmt_pct(x[[v]]))
  sds <- sapply(list(ss_med_treat, ss_med_ctrl, ss_priv_treat, ss_priv_ctrl),
                function(x) paste0("[", fmt_pct(x[[paste0(v, "_sd")]]), "]"))
  tab1 <- paste0(tab1, vname, " & ", paste(vals, collapse = " & "), " \\\\\n")
  tab1 <- paste0(tab1, " & ", paste(sds, collapse = " & "), " \\\\\n")
}

births_row <- sapply(list(ss_med_treat, ss_med_ctrl, ss_priv_treat, ss_priv_ctrl),
                     function(x) formatC(x$total_births, format = "d", big.mark = ","))
tab1 <- paste0(tab1,
  "\\hline\n",
  "Total births & ", paste(births_row, collapse = " & "), " \\\\\n",
  "States & ", n_distinct(med_panel$state[med_panel$first_treat > 0]),
  " & ", n_distinct(med_panel$state[med_panel$first_treat == 0]),
  " & ", n_distinct(priv_panel$state[priv_panel$first_treat > 0]),
  " & ", n_distinct(priv_panel$state[priv_panel$first_treat == 0]), " \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Means and standard deviations (in brackets) weighted by cell birth count. ",
  "Treated states adopted Medicaid doula reimbursement between 2022 and 2023. ",
  "Control states had not adopted by end of 2023. ",
  "Data: NCHS Natality Microdata, 2018--2023.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab1, file.path(tables_dir, "tab1_sumstats.tex"))

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results — Callaway-Sant'Anna ATT
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main Results\n")

make_att_row <- function(agg, label) {
  att <- agg$overall.att
  se <- agg$overall.se
  p <- 2 * pnorm(-abs(att / se))
  ci_lo <- att - 1.96 * se
  ci_hi <- att + 1.96 * se
  paste0(
    label, " & ", fmt(att, 4), stars(p), " & (", fmt(se, 4), ") & [",
    fmt(ci_lo, 4), ", ", fmt(ci_hi, 4), "] \\\\\n"
  )
}

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Medicaid Doula Reimbursement on Birth Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & ATT & SE & 95\\% CI \\\\\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Callaway-Sant'Anna (Medicaid births)}} \\\\\n",
  make_att_row(results$agg_csection, "C-section rate"),
  make_att_row(results$agg_preterm, "Preterm birth rate"),
  make_att_row(results$agg_lbw, "Low birth weight rate"),
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Triple-difference (Medicaid vs.\\ Private)}} \\\\\n"
)

# DDD results from fixest
for (mod_name in c("ddd_csection", "ddd_preterm", "ddd_lbw")) {
  mod <- results[[mod_name]]
  ct <- coeftable(mod)
  coef_name <- rownames(ct)[1]
  est <- ct[coef_name, "Estimate"]
  se_val <- ct[coef_name, "Std. Error"]
  p_val <- ct[coef_name, "Pr(>|t|)"]
  ci_lo <- est - 1.96 * se_val
  ci_hi <- est + 1.96 * se_val
  label <- switch(mod_name,
    ddd_csection = "C-section rate",
    ddd_preterm = "Preterm birth rate",
    ddd_lbw = "Low birth weight rate"
  )
  tab2 <- paste0(tab2,
    label, " & ", fmt(est, 4), stars(p_val), " & (", fmt(se_val, 4), ") & [",
    fmt(ci_lo, 4), ", ", fmt(ci_hi, 4), "] \\\\\n"
  )
}

tab2 <- paste0(tab2,
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo (Private insurance births only)}} \\\\\n",
  make_att_row(robust$placebo, "C-section rate"),
  "\\hline\\hline\n",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Panel A reports Callaway-Sant'Anna (2021) ATT estimates using never-treated ",
  "states as controls. Panel B reports triple-difference estimates (treated state ",
  "$\\times$ Medicaid $\\times$ post) with state-year, state-payer, and year-payer ",
  "fixed effects, weighted by births and clustered at the state level. ",
  "Panel C reports the placebo test: Callaway-Sant'Anna ATT for private-insurance ",
  "births in treated states. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 3: Event Study Coefficients
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Event Study\n")

es <- results$agg_es
es_df <- data.frame(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt
) %>%
  mutate(
    p = 2 * pnorm(-abs(att / se)),
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se
  )

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: C-Section Rate by Years Relative to Adoption}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Event time & ATT & SE & 95\\% CI & Pre/Post \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(es_df))) {
  r <- es_df[i, ]
  period_label <- ifelse(r$event_time < 0, "Pre", "Post")
  tab3 <- paste0(tab3,
    "$t", ifelse(r$event_time >= 0, "+", ""), r$event_time, "$ & ",
    fmt(r$att, 4), stars(r$p), " & (", fmt(r$se, 4), ") & [",
    fmt(r$ci_lo, 4), ", ", fmt(r$ci_hi, 4), "] & ", period_label, " \\\\\n"
  )
}

tab3 <- paste0(tab3,
  "\\hline\\hline\n",
  "\\multicolumn{5}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "Callaway-Sant'Anna (2021) group-time ATTs aggregated by event time. ",
  "Reference period: $t-1$ (universal base). Pre-treatment coefficients test ",
  "the parallel trends assumption. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab3, file.path(tables_dir, "tab3_eventstudy.tex"))

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 4: Robustness
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Robustness\n")

# Sun-Abraham (pre-extracted coefficients)
sa_est <- robust$sa_coefs$est
sa_se <- robust$sa_coefs$se
sa_p <- robust$sa_coefs$p

# Stacked DiD (pre-extracted coefficients)
stacked_est <- robust$stacked_coefs$est
stacked_se <- robust$stacked_coefs$se
stacked_p <- robust$stacked_coefs$p

# Main CS estimate
cs_est <- results$agg_csection$overall.att
cs_se <- results$agg_csection$overall.se
cs_p <- 2 * pnorm(-abs(cs_est / cs_se))

# Jackknife
jack_min <- min(robust$jackknife$att, na.rm = TRUE)
jack_max <- max(robust$jackknife$att, na.rm = TRUE)

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Estimators and Sensitivity}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Estimate & SE \\\\\n",
  "\\hline\n",
  "Callaway-Sant'Anna (baseline) & ", fmt(cs_est, 4), stars(cs_p), " & (", fmt(cs_se, 4), ") \\\\\n",
  "Sun-Abraham & ", fmt(sa_est, 4), ifelse(!is.na(sa_p), stars(sa_p), ""), " & ",
    ifelse(!is.na(sa_se), paste0("(", fmt(sa_se, 4), ")"), "---"), " \\\\\n",
  "Stacked DiD & ", fmt(stacked_est, 4), stars(stacked_p), " & (", fmt(stacked_se, 4), ") \\\\\n",
  "\\hline\n",
  "Jackknife range & \\multicolumn{2}{c}{[", fmt(jack_min, 4), ", ", fmt(jack_max, 4), "]} \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "All specifications estimate the effect of Medicaid doula reimbursement on the ",
  "C-section rate among Medicaid births. Callaway-Sant'Anna uses never-treated ",
  "controls. Sun-Abraham uses fixest::sunab(). Stacked DiD creates cohort-specific ",
  "datasets. Jackknife range shows ATT bounds when each treated state is dropped. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab4, file.path(tables_dir, "tab4_robust.tex"))

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE 5: Racial Disparity
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table 5: Racial Disparity\n")

# Race-specific C-section rates by group
race_ss <- panel %>%
  filter(payer == "medicaid", first_treat == 0 | first_treat >= 2018,
         births_black >= 50, births_white >= 50) %>%
  group_by(treat_group = ifelse(first_treat > 0, "Treated", "Control")) %>%
  summarise(
    csrate_black = weighted.mean(csrate_black, births_black, na.rm = TRUE),
    csrate_white = weighted.mean(csrate_white, births_white, na.rm = TRUE),
    gap = weighted.mean(csrate_bw_gap, pmin(births_black, births_white), na.rm = TRUE),
    .groups = "drop"
  )

bwgap_att <- results$agg_bwgap$overall.att
bwgap_se <- results$agg_bwgap$overall.se
bwgap_p <- 2 * pnorm(-abs(bwgap_att / bwgap_se))

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Racial Disparities in C-Section Rates}\n",
  "\\label{tab:race}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Treated & Control \\\\\n",
  "\\hline\n",
  "Black C-section rate & ", fmt_pct(race_ss$csrate_black[race_ss$treat_group == "Treated"]),
  "\\% & ", fmt_pct(race_ss$csrate_black[race_ss$treat_group == "Control"]), "\\% \\\\\n",
  "White C-section rate & ", fmt_pct(race_ss$csrate_white[race_ss$treat_group == "Treated"]),
  "\\% & ", fmt_pct(race_ss$csrate_white[race_ss$treat_group == "Control"]), "\\% \\\\\n",
  "Black-White gap & ", fmt_pct(race_ss$gap[race_ss$treat_group == "Treated"]),
  " pp & ", fmt_pct(race_ss$gap[race_ss$treat_group == "Control"]), " pp \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Callaway-Sant'Anna ATT on B-W gap}} \\\\\n",
  "Estimate & \\multicolumn{2}{c}{", fmt(bwgap_att, 4), stars(bwgap_p), "} \\\\\n",
  "SE & \\multicolumn{2}{c}{(", fmt(bwgap_se, 4), ")} \\\\\n",
  "\\hline\\hline\n",
  "\\multicolumn{3}{p{0.75\\textwidth}}{\\footnotesize \\textit{Notes:} ",
  "C-section rates by maternal race among Medicaid births. ",
  "Black-White gap is the difference in C-section rates. ",
  "ATT estimated via Callaway-Sant'Anna (2021) with never-treated controls. ",
  "States with fewer than 50 births per race-year excluded. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tab5, file.path(tables_dir, "tab5_race.tex"))

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ═══════════════════════════════════════════════════════════════════════════════
cat("Generating Table F1: Standardized Effect Sizes\n")

# Get pre-treatment SDs for each outcome
pre_med <- panel %>%
  filter(payer == "medicaid", first_treat == 0 | first_treat >= 2018,
         year < 2022)

sd_csection <- sqrt(weighted.mean(
  (pre_med$csection_rate - weighted.mean(pre_med$csection_rate, pre_med$births))^2,
  pre_med$births
))
sd_preterm <- sqrt(weighted.mean(
  (pre_med$preterm_rate - weighted.mean(pre_med$preterm_rate, pre_med$births))^2,
  pre_med$births
))
sd_lbw <- sqrt(weighted.mean(
  (pre_med$lbw_rate - weighted.mean(pre_med$lbw_rate, pre_med$births))^2,
  pre_med$births
))

# B-W gap SD
pre_race <- pre_med %>% filter(!is.na(csrate_bw_gap), births_black >= 50, births_white >= 50)
sd_bwgap <- sd(pre_race$csrate_bw_gap, na.rm = TRUE)

# Compute SDEs
sde_rows <- data.frame(
  outcome = c("C-section rate", "Preterm birth rate",
              "Low birth weight rate", "Black-White C-section gap"),
  beta = c(results$agg_csection$overall.att,
           results$agg_preterm$overall.att,
           results$agg_lbw$overall.att,
           results$agg_bwgap$overall.att),
  se = c(results$agg_csection$overall.se,
         results$agg_preterm$overall.se,
         results$agg_lbw$overall.se,
         results$agg_bwgap$overall.se),
  sd_y = c(sd_csection, sd_preterm, sd_lbw, sd_bwgap)
)

sde_rows <- sde_rows %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

# Heterogeneity rows (Panel B): split by high vs low baseline C-section states
med_pre_state <- pre_med %>%
  group_by(state, state_id) %>%
  summarise(baseline_csrate = weighted.mean(csection_rate, births), .groups = "drop")
median_csrate <- median(med_pre_state$baseline_csrate)

med_w_baseline <- panel %>%
  filter(payer == "medicaid", first_treat == 0 | first_treat >= 2018) %>%
  left_join(med_pre_state %>% select(state, baseline_csrate), by = "state")

# High-baseline states
high_base <- med_w_baseline %>% filter(baseline_csrate >= median_csrate)
high_base <- high_base %>% mutate(state_id_h = as.integer(factor(state)))

cs_high <- tryCatch({
  att_gt(yname = "csection_rate", tname = "year", idname = "state_id_h",
         gname = "first_treat", data = high_base,
         control_group = "nevertreated", base_period = "universal")
}, error = function(e) NULL)

if (!is.null(cs_high)) {
  agg_high <- aggte(cs_high, type = "simple")
  sde_high <- agg_high$overall.att / sd_csection
  se_sde_high <- agg_high$overall.se / sd_csection
} else {
  sde_high <- NA; se_sde_high <- NA
}

# Low-baseline states
low_base <- med_w_baseline %>% filter(baseline_csrate < median_csrate)
low_base <- low_base %>% mutate(state_id_l = as.integer(factor(state)))

cs_low <- tryCatch({
  att_gt(yname = "csection_rate", tname = "year", idname = "state_id_l",
         gname = "first_treat", data = low_base,
         control_group = "nevertreated", base_period = "universal")
}, error = function(e) NULL)

if (!is.null(cs_low)) {
  agg_low <- aggte(cs_low, type = "simple")
  sde_low <- agg_low$overall.att / sd_csection
  se_sde_low <- agg_low$overall.se / sd_csection
} else {
  sde_low <- NA; se_sde_low <- NA
}

classify_sde <- function(s) {
  if (is.na(s)) return("---")
  case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <= 0.005 ~ "Null",
    s <= 0.05 ~ "Small positive",
    s <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does state-level Medicaid doula reimbursement ",
  "reduce cesarean delivery rates and improve birth outcomes among Medicaid-financed births? ",
  "\\textbf{Policy mechanism:} State Plan Amendments adding doula services as a ",
  "covered Medicaid benefit, enabling Medicaid-enrolled pregnant individuals to receive ",
  "continuous labor support from a trained doula without out-of-pocket cost, with ",
  "reimbursement ranging from \\$450 to \\$3,263 per birth episode. ",
  "\\textbf{Outcome definition:} State-year C-section rate calculated as the share of ",
  "Medicaid-financed births delivered via cesarean (DMETH\\_REC = 2) from NCHS natality records. ",
  "\\textbf{Treatment:} Binary; equals one in the year a state's Medicaid doula reimbursement ",
  "becomes effective and all subsequent years. ",
  "\\textbf{Data:} NCHS Natality Microdata 2018--2023, restricted to Medicaid and ",
  "private-insurance births with known delivery method; approximately ",
  formatC(sum(panel$births[panel$payer == "medicaid"]), format = "d", big.mark = ","),
  " Medicaid births across ", n_distinct(panel$state), " states and 6 years. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated ",
  "controls and universal base period; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Singleton births with known delivery method and payer (Medicaid or private); ",
  "states with fewer than 50 race-specific births excluded from racial disparity analysis. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2018--2021) ",
  "weighted standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  tabF1 <- paste0(tabF1,
    r$outcome, " & ", fmt(r$beta, 4), " & ", fmt(r$se, 4), " & ",
    fmt(r$sd_y, 4), " & ", fmt(r$sde, 3), " & ", fmt(r$se_sde, 3),
    " & ", r$classification, " \\\\\n"
  )
}

tabF1 <- paste0(tabF1,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (C-section rate by baseline level)}} \\\\\n",
  "High-baseline states & --- & --- & ", fmt(sd_csection, 4), " & ",
  ifelse(!is.na(sde_high), fmt(sde_high, 3), "---"), " & ",
  ifelse(!is.na(se_sde_high), fmt(se_sde_high, 3), "---"), " & ",
  classify_sde(sde_high), " \\\\\n",
  "Low-baseline states & --- & --- & ", fmt(sd_csection, 4), " & ",
  ifelse(!is.na(sde_low), fmt(sde_low, 3), "---"), " & ",
  ifelse(!is.na(se_sde_low), fmt(se_sde_low, 3), "---"), " & ",
  classify_sde(sde_low), " \\\\\n",
  "\\hline\\hline\n",
  "\\begin{minipage}{0.95\\textwidth}\n",
  "\\vspace{0.3em}\n",
  "\\begin{itemize}[leftmargin=*,nosep]\n",
  sde_notes, "\n",
  "\\end{itemize}\n",
  "\\end{minipage}\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in:", tables_dir, "\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
