# 05_tables.R — Generate all LaTeX tables
# apep_1021: Latvia AML Shell-Company Ban

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
load("../data/main_models.RData")
load("../data/robustness_models.RData")
reg <- readRDS("../data/register_parsed.rds")

# Classify for summary stats
reg[, firm_category := fcase(
  grepl("Sabiedrība ar ierobežotu", type_text), "SIA",
  grepl("Akciju sabiedrība", type_text), "AS",
  grepl("Ārvalsts komersanta", type_text), "foreign_rep",
  grepl("Individuālais komersants", type_text), "IK",
  grepl("Zemnieku", type_text), "farm",
  default = "other"
)]
reg[, shell_likely := firm_category %in% c("SIA", "AS", "foreign_rep")]
reg[, riga := (atvk == 10000)]
reg[is.na(riga), riga := FALSE]

# ============================================================
# Table 1: Summary Statistics
# ============================================================

pre <- panel[ym < as.Date("2018-02-01")]
post_d <- panel[ym >= as.Date("2018-02-01")]

# Pre-treatment means
pre_stats <- pre[, .(
  active = formatC(round(mean(active_firms)), format = "d", big.mark = ","),
  diss_rate = sprintf("%.2f", mean(dissolution_rate, na.rm = TRUE)),
  reg_rate = sprintf("%.2f", mean(registration_rate, na.rm = TRUE)),
  diss_ct = sprintf("%.0f", mean(dissolved)),
  new_ct = sprintf("%.0f", mean(new_firms))
), by = group]

# Post-treatment means
post_stats <- post_d[, .(
  active_post = formatC(round(mean(active_firms)), format = "d", big.mark = ","),
  diss_rate_post = sprintf("%.2f", mean(dissolution_rate, na.rm = TRUE)),
  reg_rate_post = sprintf("%.2f", mean(registration_rate, na.rm = TRUE))
), by = group]

tab1 <- merge(pre_stats, post_stats, by = "group")

# Order: SIA/Riga first
tab1[, order := fcase(
  group == "SIA/Riga", 1,
  group == "SIA/non-Riga", 2,
  group == "non-SIA/Riga", 3,
  group == "non-SIA/non-Riga", 4
)]
setorder(tab1, order)

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Treatment Group}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Pre-Treatment (2015--2018:1)} & \\multicolumn{3}{c}{Post-Treatment (2018:2--2021)} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  "Group & Active & Diss. Rate & Reg. Rate & Active & Diss. Rate & Reg. Rate \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1)) {
  row <- tab1[i]
  tab1_tex <- paste0(tab1_tex,
    row$group, " & ", row$active, " & ", row$diss_rate, " & ", row$reg_rate,
    " & ", row$active_post, " & ", row$diss_rate_post, " & ", row$reg_rate_post,
    " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dissolution and registration rates are per 1,000 active firms per month. ",
  "``Active'' is the mean monthly stock of firms. ``Shell-likely'' includes SIA (LLC), AS (joint stock), ",
  "and foreign representative offices. Treatment is the intersection of shell-likely firm type and Riga ",
  "location (ATVK code 10000). Pre-treatment: January 2015 to January 2018. Post-treatment: ",
  "February 2018 to December 2021. Source: Latvia Enterprise Register Open Data ",
  "(\\texttt{dati.ur.gov.lv}).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Main DiD Results
# ============================================================

# Rebuild models for clean presentation
panel[, group_id := paste0(as.numeric(shell_likely), "_", as.numeric(riga))]

m1 <- feols(dissolution_rate ~ treated:post | group_id + ym,
            data = panel, vcov = "hetero")
m2 <- feols(registration_rate ~ treated:post | group_id + ym,
            data = panel, vcov = "hetero")
m3 <- feols(log(active_firms) ~ treated:post | group_id + ym,
            data = panel, vcov = "hetero")

# Extract coefficients (use index since collinearity mangles names)
extract_coef <- function(model, idx = 1) {
  cf <- coeftable(model)
  list(
    est = cf[idx, 1],
    se = cf[idx, 2],
    p = cf[idx, 4]
  )
}

c1 <- extract_coef(m1, 1)
c2 <- extract_coef(m2, 1)
c3 <- extract_coef(m3, 1)

cat(sprintf("DiD coefficients: diss=%.2f, reg=%.2f, log_active=%.3f\n", c1$est, c2$est, c3$est))

stars <- function(p) {
  if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of AML Enforcement on Firm Demographics}\n",
  "\\label{tab:main_did}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Dissolution Rate & Registration Rate & Log Active Firms \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  sprintf("Treated $\\times$ Post & %.2f%s & %.2f%s & %.3f%s \\\\\n",
          c1$est, stars(c1$p), c2$est, stars(c2$p), c3$est, stars(c3$p)),
  sprintf(" & (%.2f) & (%.2f) & (%.3f) \\\\\n", c1$se, c2$se, c3$se),
  "[6pt]\n",
  "Group FE & Yes & Yes & Yes \\\\\n",
  "Month FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d \\\\\n", nobs(m1), nobs(m2), nobs(m3)),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f \\\\\n",
          r2(m1, "wr2"), r2(m2, "wr2"), r2(m3, "wr2")),
  sprintf("Pre-treatment mean (treated) & %.2f & %.2f & %.2f \\\\\n",
          mean(panel[treated == TRUE & !post, dissolution_rate], na.rm = TRUE),
          mean(panel[treated == TRUE & !post, registration_rate], na.rm = TRUE),
          mean(panel[treated == TRUE & !post, log(active_firms)], na.rm = TRUE)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports an OLS estimate of $\\beta$ from ",
  "$Y_{gt} = \\alpha_g + \\gamma_t + \\beta \\cdot \\text{Treated}_g \\times \\text{Post}_t + \\varepsilon_{gt}$, ",
  "where $g$ indexes four firm-type$\\times$geography groups (shell-likely$\\times$Riga) and $t$ indexes months. ",
  "Rates are per 1,000 active firms. Heteroskedasticity-robust standard errors in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main_did.tex")

# ============================================================
# Table 3: Mechanism Tests (Firm Type Heterogeneity)
# ============================================================

det_panel <- readRDS("../data/detail_panel.rds")
main_cats <- c("SIA", "AS", "foreign_rep", "IK", "farm", "sole_prop")

cat_results <- list()
for (cat_name in main_cats) {
  cat_data <- det_panel[firm_category == cat_name & active_firms > 0]
  cat_data[, post := ym >= as.Date("2018-02-01")]
  cat_data[, group_id := paste0(cat_name, "_", as.numeric(riga))]

  if (nrow(cat_data) >= 20) {
    m_cat <- feols(dissolution_rate ~ riga * post | group_id + ym,
                   data = cat_data, vcov = "hetero")
    rid <- grep("riga.*post", names(coef(m_cat)))
    if (length(rid) > 0) {
      cat_results[[cat_name]] <- list(
        est = coef(m_cat)[rid],
        se = se(m_cat)[rid],
        p = pvalue(m_cat)[rid],
        n = nobs(m_cat),
        pre_mean = mean(cat_data[riga == TRUE & !post, dissolution_rate], na.rm = TRUE)
      )
    }
  }
}

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Mechanism Test: Dissolution Effects by Firm Type (Riga vs.~Non-Riga)}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Firm Type & $\\hat{\\beta}$ & SE & Pre-Mean & $N$ \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Shell-Likely Types (Treated)}} \\\\\n"
)

treated_types <- c("SIA", "AS", "foreign_rep")
control_types <- c("IK", "farm", "sole_prop")
type_labels <- c(SIA = "SIA (LLC)", AS = "AS (Joint Stock)",
                 foreign_rep = "Foreign Representative",
                 IK = "Individual Merchant", farm = "Farm Enterprise",
                 sole_prop = "Sole Proprietorship")

for (tn in treated_types) {
  r <- cat_results[[tn]]
  if (!is.null(r)) {
    tab3_tex <- paste0(tab3_tex,
      sprintf("\\quad %s & %.2f%s & (%.2f) & %.2f & %d \\\\\n",
              type_labels[tn], r$est, stars(r$p), r$se,
              ifelse(is.nan(r$pre_mean), 0, r$pre_mean), r$n))
  }
}

tab3_tex <- paste0(tab3_tex,
  "[6pt]\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Non-Shell Types (Placebos)}} \\\\\n"
)

for (tn in control_types) {
  r <- cat_results[[tn]]
  if (!is.null(r)) {
    tab3_tex <- paste0(tab3_tex,
      sprintf("\\quad %s & %.2f%s & (%.2f) & %.2f & %d \\\\\n",
              type_labels[tn], r$est, stars(r$p), r$se,
              ifelse(is.nan(r$pre_mean), 0, r$pre_mean), r$n))
  }
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on Riga$\\times$Post from a separate ",
  "regression of dissolution rate (per 1,000 active firms) on the interaction, with group and month ",
  "fixed effects. Heteroskedasticity-robust SEs. Panel~A reports shell-likely firm types (the main ",
  "treatment channel). Panel~B reports non-shell types as mechanism-matched placebos: individual ",
  "merchants and farms should not be affected by the shell-company banking prohibition. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_mechanism.tex")

# ============================================================
# Table 4: Firm Age Heterogeneity
# ============================================================

# Rebuild era panel
reg[, reg_era := fcase(
  registered >= as.Date("2010-01-01"), "Post-2010",
  registered >= as.Date("2000-01-01") & registered < as.Date("2010-01-01"), "2000--2009",
  default = "Pre-2000"
)]

shells <- reg[shell_likely == TRUE & registered <= as.Date("2021-12-31")]
shells[, term_month := floor_date(terminated, "month")]
start_date <- as.Date("2015-01-01")
end_date <- as.Date("2021-12-31")
months <- seq(start_date, end_date, by = "month")

diss_era <- shells[!is.na(term_month) & term_month >= start_date & term_month <= end_date,
                   .(dissolved = .N), by = .(ym = term_month, reg_era, riga)]
active_era <- rbindlist(lapply(months, function(m) {
  m_end <- ceiling_date(m, "month") - days(1)
  act <- shells[registered <= m_end & (is.na(terminated) | terminated > m_end)]
  act[, .(active_firms = .N), by = .(reg_era, riga)][, ym := m]
}))
era_grid <- CJ(ym = months, reg_era = unique(shells$reg_era), riga = c(TRUE, FALSE))
era_panel <- merge(era_grid, diss_era, by = c("ym", "reg_era", "riga"), all.x = TRUE)
era_panel <- merge(era_panel, active_era, by = c("ym", "reg_era", "riga"), all.x = TRUE)
era_panel[is.na(dissolved), dissolved := 0]
era_panel[active_firms > 0, dissolution_rate := (dissolved / active_firms) * 1000]
era_panel[, post := ym >= as.Date("2018-02-01")]
era_panel[, group_id := paste0(reg_era, "_", as.numeric(riga))]

era_results <- list()
for (era in c("Post-2010", "2000--2009", "Pre-2000")) {
  ed <- era_panel[reg_era == era & active_firms > 0]
  m_era <- feols(dissolution_rate ~ riga * post | group_id + ym, data = ed, vcov = "hetero")
  rid <- grep("riga.*post", names(coef(m_era)))
  era_results[[era]] <- list(
    est = coef(m_era)[rid], se = se(m_era)[rid], p = pvalue(m_era)[rid],
    n = nobs(m_era),
    pre_mean_riga = mean(ed[riga == TRUE & !post, dissolution_rate], na.rm = TRUE),
    active_pre = round(mean(ed[riga == TRUE & !post, active_firms]))
  )
}

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Firm Age Heterogeneity: Shell-Likely Firms by Registration Era}\n",
  "\\label{tab:age_het}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Registration Era & $\\hat{\\beta}$ & SE & Pre-Mean (Riga) & Active (Riga) & $N$ \\\\\n",
  "\\hline\n"
)

for (era in c("2000--2009", "Post-2010", "Pre-2000")) {
  r <- era_results[[era]]
  tab4_tex <- paste0(tab4_tex,
    sprintf("%s & %.2f%s & (%.2f) & %.2f & %s & %d \\\\\n",
            era, r$est, stars(r$p), r$se, r$pre_mean_riga,
            formatC(r$active_pre, format = "d", big.mark = ","), r$n))
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the Riga$\\times$Post coefficient from a DiD regression ",
  "of dissolution rate (per 1,000) on the interaction, restricting to shell-likely firms (SIA, AS, ",
  "foreign representative) registered in the indicated era. The 2000--2009 cohort captures the peak ",
  "of Latvia's non-resident banking boom. Heteroskedasticity-robust SEs. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_age_het.tex")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================

# Compute SDEs
panel[, log_active := log(active_firms)]
pre_treated <- panel[treated == TRUE & !post]
cat(sprintf("Pre-treated obs for SDE: %d\n", nrow(pre_treated)))
sd_diss <- sd(pre_treated$dissolution_rate, na.rm = TRUE)
sd_reg <- sd(pre_treated$registration_rate, na.rm = TRUE)
sd_log_active <- sd(pre_treated$log_active, na.rm = TRUE)
cat(sprintf("SDs: diss=%.2f, reg=%.2f, log_active=%.4f\n", sd_diss, sd_reg, sd_log_active))

# Dissolution rate
sde_diss <- c1$est / sd_diss
se_sde_diss <- c1$se / sd_diss

# Registration rate
sde_reg <- c2$est / sd_reg
se_sde_reg <- c2$se / sd_reg

# Log active firms
sde_active <- c3$est / sd_log_active
se_sde_active <- c3$se / sd_log_active

classify_sde <- function(x) {
  if (is.na(x) || is.nan(x)) return("N/A")
  if (x < -0.15) "Large negative"
  else if (x < -0.05) "Moderate negative"
  else if (x < -0.005) "Small negative"
  else if (x <= 0.005) "Null"
  else if (x <= 0.05) "Small positive"
  else if (x <= 0.15) "Moderate positive"
  else "Large positive"
}

# --- SDE for heterogeneity (Panel B) ---
# SIA in Riga vs non-Riga (the core mechanism)
sia_data <- det_panel[firm_category == "SIA" & active_firms > 0]
sia_data[, post := ym >= as.Date("2018-02-01")]
sia_data[, group_id := paste0("SIA_", as.numeric(riga))]
m_sia <- feols(dissolution_rate ~ riga * post | group_id + ym, data = sia_data, vcov = "hetero")
sia_rid <- grep("riga.*post", names(coef(m_sia)))
sd_sia_pre <- sd(sia_data[riga == TRUE & !post, dissolution_rate], na.rm = TRUE)
sde_sia <- coef(m_sia)[sia_rid] / sd_sia_pre
se_sde_sia <- se(m_sia)[sia_rid] / sd_sia_pre

# 2000s cohort (peak shell era)
era_2000s <- era_panel[reg_era == "2000--2009" & active_firms > 0]
m_2000s <- feols(dissolution_rate ~ riga * post | group_id + ym, data = era_2000s, vcov = "hetero")
rid_2000s <- grep("riga.*post", names(coef(m_2000s)))
sd_2000s_pre <- sd(era_2000s[riga == TRUE & !post, dissolution_rate], na.rm = TRUE)
sde_2000s <- coef(m_2000s)[rid_2000s] / sd_2000s_pre
se_sde_2000s <- se(m_2000s)[rid_2000s] / sd_2000s_pre

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Latvia. ",
  "\\textbf{Research question:} Does anti-money-laundering enforcement that bans shell-company bank accounts ",
  "increase firm dissolution and reduce new firm formation in the affected financial center? ",
  "\\textbf{Policy mechanism:} Following FinCEN's February 2018 designation of ABLV Bank as a primary money-laundering ",
  "concern, Latvia's April 2018 amendment to the Law on the Prevention of Money Laundering prohibited credit ",
  "institutions from maintaining accounts for shell companies, forcing mass closure of non-resident banking relationships. ",
  "\\textbf{Outcome definition:} Monthly firm dissolution rate per 1,000 active firms (Panel A rows 1--2), monthly ",
  "new-firm registration rate per 1,000 active firms (Panel A row 3), and log stock of active firms (Panel A row 4). ",
  "Panel B splits by SIA (LLC) firms only and by firms registered during the 2000--2009 non-resident banking boom. ",
  "\\textbf{Treatment:} Binary; shell-likely firm types (SIA, AS, foreign representative offices) located in ",
  "Riga (ATVK 10000) versus non-shell types and non-Riga locations. ",
  "\\textbf{Data:} Latvia Enterprise Register Open Data (\\texttt{dati.ur.gov.lv}), 482,492 firm records, ",
  "January 2015 to December 2021, firm-type $\\times$ geography $\\times$ month panel (336 observations in main specification). ",
  "\\textbf{Method:} Two-way fixed effects DiD with group and month fixed effects; heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} All registered commercial entities in Latvia; analysis restricted to 2015--2021 study window. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for the treated group. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Dissolution rate & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          c1$est, c1$se, sd_diss, sde_diss, se_sde_diss, classify_sde(sde_diss)),
  sprintf("Registration rate & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          c2$est, c2$se, sd_reg, sde_reg, se_sde_reg, classify_sde(sde_reg)),
  sprintf("Log active firms & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          c3$est, c3$se, sd_log_active, sde_active, se_sde_active, classify_sde(sde_active)),
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Dissolution (SIA only) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          coef(m_sia)[sia_rid], se(m_sia)[sia_rid], sd_sia_pre,
          sde_sia, se_sde_sia, classify_sde(sde_sia)),
  sprintf("Dissolution (2000s cohort) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          coef(m_2000s)[rid_2000s], se(m_2000s)[rid_2000s], sd_2000s_pre,
          sde_2000s, se_sde_2000s, classify_sde(sde_2000s)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("All tables generated successfully.\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main_did.tex\n")
cat("  tables/tab3_mechanism.tex\n")
cat("  tables/tab4_age_het.tex\n")
cat("  tables/tabF1_sde.tex\n")
