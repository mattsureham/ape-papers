## 05_tables.R — Generate all LaTeX tables
## V1 format: ≤5 main tables + SDE appendix table

source("00_packages.R")

DATA_DIR   <- "../data"
TABLE_DIR  <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
agency_intensity <- readRDS(file.path(DATA_DIR, "agency_intensity.rds"))
nprm_panel <- readRDS(file.path(DATA_DIR, "nprm_panel.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
robust <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================
panel_pos <- panel |> filter(n_nprm > 0)

# Pre-period (2010-2016)
pre <- panel |> filter(year < 2017)
pre_pos <- pre |> filter(n_nprm > 0)

# EO 13771 period (2017-2020)
eo <- panel |> filter(year >= 2017 & year <= 2020)
eo_pos <- eo |> filter(n_nprm > 0)

# Post-rescission (2021-2024)
post <- panel |> filter(year >= 2021)
post_pos <- post |> filter(n_nprm > 0)

make_summary_row <- function(vec, label) {
  sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
          label,
          mean(vec, na.rm = TRUE),
          sd(vec, na.rm = TRUE),
          quantile(vec, 0.25, na.rm = TRUE),
          quantile(vec, 0.75, na.rm = TRUE))
}

tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Agency-Semester Panel}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & P25 & P75 \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Full Sample (2010--2024)}} \\\\",
  make_summary_row(panel$n_nprm, "NPRMs per agency-semester"),
  make_summary_row(panel_pos$completion_rate, "Completion rate"),
  make_summary_row(panel_pos$mean_duration[!is.na(panel_pos$mean_duration)], "Duration (days)"),
  make_summary_row(agency_intensity$sig_share, "Significance share (pre-2017)"),
  sprintf("Agencies & \\multicolumn{4}{c}{%d} \\\\", n_distinct(panel$primary_agency)),
  sprintf("Agency-semesters & \\multicolumn{4}{c}{%s} \\\\", format(nrow(panel), big.mark = ",")),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: By Period}} \\\\",
  sprintf("NPRMs/agency-semester (Pre: 2010--2016) & %.2f & %.2f & & \\\\",
          mean(pre$n_nprm), sd(pre$n_nprm)),
  sprintf("NPRMs/agency-semester (EO 13771: 2017--2020) & %.2f & %.2f & & \\\\",
          mean(eo$n_nprm), sd(eo$n_nprm)),
  sprintf("NPRMs/agency-semester (Post-Rescission: 2021--2024) & %.2f & %.2f & & \\\\",
          mean(post$n_nprm), sd(post$n_nprm)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Unit of observation is agency-semester. Completion rate is the share of proposed rules (NPRMs) with a matching final rule published within the sample period. Duration is measured in days from NPRM publication to final rule publication. Significance share is the agency's pre-2017 share of EO 12866 ``significant'' proposed rules, computed over 2008--2016. Source: Federal Register API.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("Table 1 (Summary Statistics) written.\n")

# ===========================================================================
# TABLE 2: Main Results — Continuous DiD
# ===========================================================================
tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of EO 13771 on Federal Rulemaking}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & log(NPRMs+1) & Completion Rate & log(Duration) & Sig. Share \\\\",
  "\\midrule"
)

# Extract coefficients
models <- list(results$m1_count, results$m2_complete, results$m3_duration, results$m4_composition)
var_names <- c("treat_eo", "treat_rescind")
var_labels <- c("Post EO 13771 $\\times$ Sig. Share", "Post Rescission $\\times$ Sig. Share")

for (v in seq_along(var_names)) {
  coef_row <- var_labels[v]
  se_row <- ""
  for (m in models) {
    cf <- tryCatch(coef(m)[var_names[v]], error = function(e) NA)
    s  <- tryCatch(se(m)[var_names[v]], error = function(e) NA)
    pv <- tryCatch(fixest::pvalue(m)[var_names[v]], error = function(e) NA)
    stars <- ifelse(is.na(pv), "",
                    ifelse(pv < 0.01, "***",
                           ifelse(pv < 0.05, "**",
                                  ifelse(pv < 0.10, "*", ""))))
    coef_row <- paste0(coef_row, sprintf(" & %.3f%s", cf, stars))
    se_row <- paste0(se_row, sprintf(" & (%.3f)", s))
  }
  tab2_tex <- c(tab2_tex,
                paste0(coef_row, " \\\\"),
                paste0(se_row, " \\\\"))
}

# Add fixed effects and N
tab2_tex <- c(tab2_tex,
              "\\midrule",
              "Agency FE & Yes & Yes & Yes & Yes \\\\",
              "Semester FE & Yes & Yes & Yes & Yes \\\\")

# N for each model
n_row <- "N"
for (m in models) {
  n_row <- paste0(n_row, sprintf(" & %s", format(m$nobs, big.mark = ",")))
}
tab2_tex <- c(tab2_tex, paste0(n_row, " \\\\"))

# Cluster count
cl_row <- "Clusters (agencies)"
for (m in models) {
  nc <- length(unique(m$fixef_vars))
  # Get actual cluster count from model
  nc <- tryCatch(m$nparams, error = function(e) NA)
  cl_row <- paste0(cl_row, sprintf(" & %d", n_distinct(panel$primary_agency)))
}
tab2_tex <- c(tab2_tex, paste0(cl_row, " \\\\"))

tab2_tex <- c(tab2_tex,
              "\\bottomrule",
              "\\end{tabular}",
              "\\end{adjustbox}",
              "\\begin{tablenotes}[flushleft]\\small",
              "\\item \\textit{Notes:} Each column estimates a continuous difference-in-differences specification where the treatment is the interaction of a post-EO 13771 indicator (2017H1 onward) with the agency's pre-2017 share of EO 12866 significant proposed rules. Column (1): log(NPRMs + 1) captures the extensive margin of rulemaking activity. Column (2): completion rate (share of NPRMs with a matching final rule). Column (3): log of mean NPRM-to-final-rule duration in days. Column (4): share of NPRMs flagged as significant. Standard errors clustered at the agency level in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
              "\\end{tablenotes}",
              "\\end{threeparttable}",
              "\\end{table}")

writeLines(tab2_tex, file.path(TABLE_DIR, "tab2_main.tex"))
cat("Table 2 (Main Results) written.\n")

# ===========================================================================
# TABLE 3: Event Study Coefficients
# ===========================================================================
# Extract event study coefficients for NPRM count
es_cf <- as.data.frame(summary(results$es_count)$coeftable)
# Row names look like "et_factor::-7:sig_share" — extract the number between "::" and ":"
es_cf$event_time <- as.numeric(str_extract(rownames(es_cf), "(?<=::)-?\\d+"))
es_cf <- es_cf |> filter(!is.na(event_time)) |> arrange(event_time)

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study Estimates: log(NPRMs+1)}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Semester Relative to EO 13771 & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_cf))) {
  t <- es_cf$event_time[i]
  cf <- es_cf$Estimate[i]
  s <- es_cf$`Std. Error`[i]
  pv <- es_cf$`Pr(>|t|)`[i]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  label <- ifelse(t < 0, sprintf("$t%d$", t), sprintf("$t+%d$", t))
  if (t == -1) next  # reference period
  tab3_tex <- c(tab3_tex,
                sprintf("%s & %.3f%s & (%.3f) \\\\", label, cf, stars, s))
}

tab3_tex <- c(tab3_tex,
              "\\midrule",
              "Reference period & \\multicolumn{2}{c}{$t-1$ (2016H2)} \\\\",
              sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
                      format(results$es_count$nobs, big.mark = ",")),
              "\\bottomrule",
              "\\end{tabular}",
              "\\begin{tablenotes}[flushleft]\\small",
              "\\item \\textit{Notes:} Event study specification interacting semester indicators with the agency's pre-2017 significance share. The reference period is the semester immediately before EO 13771 (2016H2). Agency and semester fixed effects included. Standard errors clustered at the agency level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
              "\\end{tablenotes}",
              "\\end{threeparttable}",
              "\\end{table}")

writeLines(tab3_tex, file.path(TABLE_DIR, "tab3_eventstudy.tex"))
cat("Table 3 (Event Study) written.\n")

# ===========================================================================
# TABLE 4: Robustness Checks
# ===========================================================================
tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: log(NPRMs+1)}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & $\\hat{\\beta}_{EO}$ & SE & N \\\\",
  "\\midrule"
)

robustness_specs <- list(
  list(label = "Baseline", model = results$m1_count),
  list(label = "Binary treatment (median split)", model = robust$binary_count),
  list(label = "Weighted by pre-period volume", model = robust$weighted_count),
  list(label = "Excluding COVID (2020--2021)", model = robust$nocovid_count),
  list(label = "Placebo (2014H1)", model = robust$placebo_count)
)

for (spec in robustness_specs) {
  m <- spec$model
  var <- ifelse(spec$label == "Binary treatment (median split)", "treat_binary_eo",
                ifelse(spec$label == "Placebo (2014H1)", "treat_placebo", "treat_eo"))
  cf <- coef(m)[var]
  s <- se(m)[var]
  pv <- fixest::pvalue(m)[var]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.10, "*", "")))
  tab4_tex <- c(tab4_tex,
                sprintf("%s & %.3f%s & (%.3f) & %s \\\\",
                        spec$label, cf, stars, s, format(m$nobs, big.mark = ",")))
}

tab4_tex <- c(tab4_tex,
              "\\midrule",
              "\\multicolumn{4}{l}{\\textit{Leave-one-out (dropping largest agencies):}} \\\\")

loo <- robust$loo_results
for (i in seq_len(nrow(loo))) {
  stars <- ifelse(abs(loo$beta_eo[i] / loo$se_eo[i]) > 2.576, "***",
                  ifelse(abs(loo$beta_eo[i] / loo$se_eo[i]) > 1.960, "**",
                         ifelse(abs(loo$beta_eo[i] / loo$se_eo[i]) > 1.645, "*", "")))
  tab4_tex <- c(tab4_tex,
                sprintf("\\quad Drop %s & %.3f%s & (%.3f) & \\\\",
                        gsub("-", " ", loo$dropped[i]), loo$beta_eo[i], stars, loo$se_eo[i]))
}

tab4_tex <- c(tab4_tex,
              "\\bottomrule",
              "\\end{tabular}",
              "\\begin{tablenotes}[flushleft]\\small",
              "\\item \\textit{Notes:} All specifications include agency and semester fixed effects with standard errors clustered at the agency level. The baseline uses continuous treatment (significance share). Binary treatment splits agencies at the median pre-2017 significance share. Weighted regression uses pre-period NPRM volume as analytic weights. The placebo test applies a fake treatment at 2014H1 using only 2010--2016 data. Leave-one-out drops each of the five largest agencies by pre-period NPRM count. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.",
              "\\end{tablenotes}",
              "\\end{threeparttable}",
              "\\end{table}")

writeLines(tab4_tex, file.path(TABLE_DIR, "tab4_robustness.tex"))
cat("Table 4 (Robustness) written.\n")

# ===========================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix — MANDATORY)
# ===========================================================================
# Compute SDE for main outcomes

# Get pre-treatment SDs
pre_panel <- panel |> filter(year < 2017)
pre_panel_pos <- pre_panel |> filter(n_nprm > 0)

sd_log_nprm <- sd(pre_panel$log_nprm, na.rm = TRUE)
sd_completion <- sd(pre_panel_pos$completion_rate, na.rm = TRUE)
sd_log_duration <- sd(log(pre_panel_pos$mean_duration[pre_panel_pos$mean_duration > 0 & !is.na(pre_panel_pos$mean_duration)]), na.rm = TRUE)
sd_sig_rate <- sd(pre_panel_pos$n_significant / pre_panel_pos$n_nprm, na.rm = TRUE)

sd_treat <- sd(agency_intensity$sig_share, na.rm = TRUE)

# For continuous treatment: SDE = β × SD(X) / SD(Y)
compute_sde <- function(model, var_name, sd_y) {
  beta <- coef(model)[var_name]
  se_beta <- se(model)[var_name]
  sde <- beta * sd_treat / sd_y
  se_sde <- se_beta * sd_treat / sd_y
  list(beta = beta, se_beta = se_beta, sd_y = sd_y, sde = sde, se_sde = se_sde)
}

sde_nprm <- compute_sde(results$m1_count, "treat_eo", sd_log_nprm)
sde_complete <- compute_sde(results$m2_complete, "treat_eo", sd_completion)
sde_duration <- compute_sde(results$m3_duration, "treat_eo", sd_log_duration)
sde_composition <- compute_sde(results$m4_composition, "treat_eo", sd_sig_rate)

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Heterogeneity: split by independent vs cabinet agencies
# Independent agencies are typically less politically responsive
# (This is the most relevant heterogeneity for regulatory budget effects)
independent_agencies <- c(
  "consumer-product-safety-commission", "federal-communications-commission",
  "federal-trade-commission", "nuclear-regulatory-commission",
  "securities-and-exchange-commission", "environmental-protection-agency",
  "commodity-futures-trading-commission", "federal-energy-regulatory-commission",
  "national-labor-relations-board", "consumer-financial-protection-bureau"
)

panel_cab <- panel |> mutate(is_independent = primary_agency %in% independent_agencies)

het_cabinet <- feols(
  log_nprm ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_cab |> filter(!is_independent),
  cluster = ~primary_agency
)

het_indep <- feols(
  log_nprm ~ treat_eo + treat_rescind | primary_agency + year_sem,
  data = panel_cab |> filter(is_independent),
  cluster = ~primary_agency
)

sde_cabinet <- compute_sde(het_cabinet, "treat_eo", sd(pre_panel$log_nprm[!pre_panel$primary_agency %in% independent_agencies], na.rm = TRUE))
sde_indep <- compute_sde(het_indep, "treat_eo", sd(pre_panel$log_nprm[pre_panel$primary_agency %in% independent_agencies], na.rm = TRUE))

# Build SDE table
sde_rows <- list(
  list(outcome = "NPRM count (log)", s = sde_nprm),
  list(outcome = "Completion rate", s = sde_complete),
  list(outcome = "Duration (log days)", s = sde_duration),
  list(outcome = "Significance share", s = sde_composition)
)

sde_het_rows <- list(
  list(outcome = "NPRM count --- Cabinet agencies", s = sde_cabinet),
  list(outcome = "NPRM count --- Independent agencies", s = sde_indep)
)

tabF1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (r in sde_rows) {
  cls <- classify_sde(r$s$sde)
  tabF1_tex <- c(tabF1_tex,
                 sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
                         r$outcome, r$s$beta, r$s$se_beta, r$s$sd_y,
                         r$s$sde, r$s$se_sde, cls))
}

tabF1_tex <- c(tabF1_tex,
               "\\midrule",
               "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by agency type)}} \\\\")

for (r in sde_het_rows) {
  cls <- classify_sde(r$s$sde)
  tabF1_tex <- c(tabF1_tex,
                 sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
                         r$outcome, r$s$beta, r$s$se_beta, r$s$sd_y,
                         r$s$sde, r$s$se_sde, cls))
}

# Build notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the two-for-one regulatory budget (EO 13771) reduce rulemaking activity at agencies with high pre-existing shares of significant rules? ",
  "\\textbf{Policy mechanism:} EO 13771 required agencies to repeal two existing rules for each new rule and imposed a net-zero annual regulatory cost cap, creating a binding constraint on agencies with economically significant rule portfolios. ",
  "\\textbf{Outcome definition:} log(NPRMs + 1), where NPRMs are Notice of Proposed Rulemaking documents published in the Federal Register per agency-semester. ",
  "\\textbf{Treatment:} Continuous --- agency's pre-2017 share of EO 12866 significant proposed rules. ",
  "\\textbf{Data:} Federal Register API, 2010--2024, agency-semester panel. ",
  "\\textbf{Method:} Continuous difference-in-differences with agency and semester fixed effects; standard errors clustered at agency level. ",
  "\\textbf{Sample:} Federal agencies with at least 10 proposed rules in 2008--2016; excludes agencies with trivial rulemaking portfolios. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-agency standard deviation of the significance share and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(tabF1_tex,
               "\\bottomrule",
               "\\end{tabular}",
               "\\begin{tablenotes}[flushleft]\\small",
               sde_notes,
               "\\end{tablenotes}",
               "\\end{threeparttable}",
               "\\end{table}")

writeLines(tabF1_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
