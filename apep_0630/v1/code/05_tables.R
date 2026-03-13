## 05_tables.R — Generate all tables including SDE appendix
## apep_0630: Surprise Billing Laws and ED Quality

library(data.table)
library(fixest)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "."
setwd(file.path(script_dir, ".."))

panel <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")
diag <- jsonlite::fromJSON("data/diagnostics.json")
rob <- readRDS("data/robustness_results.rds")

# Restore cohort variable needed by sunab summary methods
panel[, cohort := fifelse(G == 0, 10000L, G)]

dir.create("tables", showWarnings = FALSE)

# Helper
fmt_coef <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  s <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  sprintf("%.2f%s", est, s)
}

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("Generating Table 1\n")
ss <- function(dt, label) {
  data.table(
    Group = label,
    N_h = uniqueN(dt$provider_id),
    N = nrow(dt),
    ed_m = mean(dt$ed_time, na.rm = TRUE),
    ed_sd = sd(dt$ed_time, na.rm = TRUE),
    lw_m = mean(dt$lwbs_pct, na.rm = TRUE),
    lw_sd = sd(dt$lwbs_pct, na.rm = TRUE),
    fp = 100 * mean(dt$ownership_type == "For-profit", na.rm = TRUE),
    np = 100 * mean(dt$ownership_type == "Nonprofit", na.rm = TRUE),
    gv = 100 * mean(dt$ownership_type == "Government", na.rm = TRUE)
  )
}
s <- rbind(ss(panel, "Full"), ss(panel[G > 0], "Treated"), ss(panel[G == 0], "Control"))

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Full Sample & Treated & Never-Treated \\\\",
  "\\hline",
  sprintf("Hospitals & %s & %s & %s \\\\",
          format(s$N_h[1], big.mark=","), format(s$N_h[2], big.mark=","), format(s$N_h[3], big.mark=",")),
  sprintf("Hospital-years & %s & %s & %s \\\\",
          format(s$N[1], big.mark=","), format(s$N[2], big.mark=","), format(s$N[3], big.mark=",")),
  "\\\\[-4pt]",
  "\\multicolumn{4}{l}{\\textit{Panel A: ED Quality Measures}} \\\\[2pt]",
  sprintf("ED time to discharge (min.) & %.1f & %.1f & %.1f \\\\", s$ed_m[1], s$ed_m[2], s$ed_m[3]),
  sprintf("\\quad SD & (%.1f) & (%.1f) & (%.1f) \\\\", s$ed_sd[1], s$ed_sd[2], s$ed_sd[3]),
  sprintf("Left without being seen (\\%%) & %.1f & %.1f & %.1f \\\\", s$lw_m[1], s$lw_m[2], s$lw_m[3]),
  sprintf("\\quad SD & (%.1f) & (%.1f) & (%.1f) \\\\", s$lw_sd[1], s$lw_sd[2], s$lw_sd[3]),
  "\\\\[-4pt]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Hospital Characteristics}} \\\\[2pt]",
  sprintf("For-profit (\\%%) & %.1f & %.1f & %.1f \\\\", s$fp[1], s$fp[2], s$fp[3]),
  sprintf("Nonprofit (\\%%) & %.1f & %.1f & %.1f \\\\", s$np[1], s$np[2], s$np[3]),
  sprintf("Government (\\%%) & %.1f & %.1f & %.1f \\\\", s$gv[1], s$gv[2], s$gv[3]),
  "\\hline\\hline",
  "\\end{tabular}",
  sprintf("\\par\\smallskip{\\small\\textit{Notes:} Sample consists of acute care hospitals with emergency departments reporting CMS Hospital Compare measures, %d--%d. ED time = OP-18b (median minutes from arrival to discharge). LWBS = OP-22 (percentage of patients who left without being seen). Treated states enacted comprehensive surprise billing protections between 2015 and 2018.}",
          min(panel$meas_year), max(panel$meas_year)),
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ===================================================================
# Table 2: Main Results
# ===================================================================
cat("Generating Table 2\n")
tw_t <- results$twfe_time
tw_l <- results$twfe_lwbs
sa_t_est <- results$sa_att_est
sa_t_se <- results$sa_att_se
sa_l_est <- results$sa_lwbs_est
sa_l_se <- results$sa_lwbs_se

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Surprise Billing Laws on ED Quality}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{ED Time (minutes)} & \\multicolumn{2}{c}{LWBS (\\%)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & TWFE & SA & TWFE & SA \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("Surprise billing law & $%s$ & $%s$ & $%s$ & $%s$ \\\\",
          fmt_coef(coef(tw_t)["treated"], sqrt(vcov(tw_t)["treated","treated"])),
          fmt_coef(sa_t_est, sa_t_se),
          fmt_coef(coef(tw_l)["treated"], sqrt(vcov(tw_l)["treated","treated"])),
          fmt_coef(sa_l_est, sa_l_se)),
  sprintf(" & (%.2f) & (%.2f) & (%.3f) & (%.3f) \\\\",
          sqrt(vcov(tw_t)["treated","treated"]), sa_t_se,
          sqrt(vcov(tw_l)["treated","treated"]), sa_l_se),
  sprintf(" & $[%.2f, %.2f]$ & $[%.2f, %.2f]$ & $[%.3f, %.3f]$ & $[%.3f, %.3f]$ \\\\",
          coef(tw_t)["treated"] - 1.96*sqrt(vcov(tw_t)["treated","treated"]),
          coef(tw_t)["treated"] + 1.96*sqrt(vcov(tw_t)["treated","treated"]),
          sa_t_est - 1.96*sa_t_se, sa_t_est + 1.96*sa_t_se,
          coef(tw_l)["treated"] - 1.96*sqrt(vcov(tw_l)["treated","treated"]),
          coef(tw_l)["treated"] + 1.96*sqrt(vcov(tw_l)["treated","treated"]),
          sa_l_est - 1.96*sa_l_se, sa_l_est + 1.96*sa_l_se),
  "\\hline",
  "Hospital FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Estimator & TWFE & Sun--Abraham & TWFE & Sun--Abraham \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(tw_t), big.mark=","), format(nobs(tw_t), big.mark=","),
          format(nobs(tw_l), big.mark=","), format(nobs(tw_l), big.mark=",")),
  sprintf("Treated states & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(panel[G>0]$state), uniqueN(panel[G>0]$state)),
  sprintf("Clusters (states) & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(panel$state), uniqueN(panel$state)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\par\\smallskip{\\small\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Standard errors clustered at the state level in parentheses; 95\\% confidence intervals in brackets. TWFE = two-way fixed effects. SA = Sun and Abraham (2021) interaction-weighted estimator with never-treated states as controls. ED Time = median minutes from arrival to discharge (OP-18b). LWBS = percentage who left without being seen (OP-22).}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")

# ===================================================================
# Table 3: Event Study
# ===================================================================
cat("Generating Table 3\n")
sa_es <- results$sa_time
es_tab <- coeftable(summary(sa_es, agg = "period"))
es_dt <- data.table(
  event_time = as.integer(gsub("meas_year::", "", rownames(es_tab))),
  att = es_tab[, "Estimate"],
  se = es_tab[, "Std. Error"],
  p = es_tab[, "Pr(>|t|)"]
)

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: ED Time to Discharge}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Event Time & Estimate & SE & 95\\% CI & Pre/Post \\\\",
  "\\hline"
)

for (i in 1:nrow(es_dt)) {
  r <- es_dt[i]
  stars <- ifelse(r$p < 0.01, "^{***}", ifelse(r$p < 0.05, "^{**}", ifelse(r$p < 0.10, "^{*}", "")))
  pp <- ifelse(r$event_time < 0, "Pre", ifelse(r$event_time == 0, "Impact", "Post"))
  tab3 <- c(tab3,
    sprintf("$k = %+d$ & $%.2f%s$ & (%.2f) & $[%.2f, %.2f]$ & %s \\\\",
            r$event_time, r$att, stars, r$se,
            r$att - 1.96*r$se, r$att + 1.96*r$se, pp))
}

tab3 <- c(tab3,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\par\\smallskip{\\small\\textit{Notes:} Sun and Abraham (2021) interaction-weighted event-study estimates. Dependent variable: median ED time to discharge (minutes). Standard errors clustered at the state level. Reference period: $k = -1$.}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_eventstudy.tex")

# ===================================================================
# Table 4: Ownership Heterogeneity
# ===================================================================
cat("Generating Table 4\n")
own <- rob$ownership

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Hospital Ownership}",
  "\\label{tab:ownership}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & For-Profit & Nonprofit & Government \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\hline"
)

coef_line <- "Surprise billing law"
se_line <- ""
n_line <- "Observations"
nh_line <- "Hospitals"
nt_line <- "Treated hospitals"

for (col_name in c("For-profit", "Nonprofit", "Government")) {
  if (col_name %in% names(own)) {
    r <- own[[col_name]]
    coef_line <- paste0(coef_line, sprintf(" & $%s$", fmt_coef(r$coef, r$se)))
    se_line <- paste0(se_line, sprintf(" & (%.2f)", r$se))
    n_line <- paste0(n_line, sprintf(" & %s", format(r$n, big.mark=",")))
    nh_line <- paste0(nh_line, sprintf(" & %s", format(r$n_hosp, big.mark=",")))
    nt_line <- paste0(nt_line, sprintf(" & %d", r$n_treated))
  } else {
    coef_line <- paste0(coef_line, " & --")
    se_line <- paste0(se_line, " & ")
    n_line <- paste0(n_line, " & --")
    nh_line <- paste0(nh_line, " & --")
    nt_line <- paste0(nt_line, " & --")
  }
}

tab4 <- c(tab4,
  paste0(coef_line, " \\\\"),
  paste0(se_line, " \\\\"),
  "\\hline",
  "Hospital FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "Estimator & Sun--Abraham & Sun--Abraham & Sun--Abraham \\\\",
  paste0(n_line, " \\\\"),
  paste0(nh_line, " \\\\"),
  paste0(nt_line, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\par\\smallskip{\\small\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$. Sun and Abraham (2021) interaction-weighted ATT estimates by hospital ownership type. Standard errors clustered at the state level. For-profit hospitals serve as a proxy for private equity involvement in ED staffing.}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_ownership.tex")

# ===================================================================
# Table F1: Standardized Effect Sizes
# ===================================================================
cat("Generating Table F1\n")

classify_sde <- function(sde) {
  ifelse(sde > 0.15, "Large positive",
  ifelse(sde > 0.05, "Moderate positive",
  ifelse(sde > 0.005, "Small positive",
  ifelse(sde > -0.005, "Null",
  ifelse(sde > -0.05, "Small negative",
  ifelse(sde > -0.15, "Moderate negative", "Large negative"))))))
}

sde_rows <- list()

# ED Time
beta_t <- diag$sa_att_ed_time
se_t <- diag$sa_se_ed_time
sd_t <- diag$sd_ed_time
sde_t <- beta_t / sd_t
sde_rows[[1]] <- c("ED time to discharge (min.)", beta_t, se_t, sd_t, sde_t, se_t/sd_t, classify_sde(sde_t))

# LWBS
if (!is.null(diag$sa_att_lwbs)) {
  beta_l <- diag$sa_att_lwbs
  se_l <- diag$sa_se_lwbs
  sd_l <- diag$sd_lwbs
  sde_l <- beta_l / sd_l
  sde_rows[[2]] <- c("Left without being seen (\\%)", beta_l, se_l, sd_l, sde_l, se_l/sd_l, classify_sde(sde_l))
}

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (r in sde_rows) {
  tabF1 <- c(tabF1,
    sprintf("%s & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\",
            r[1], as.numeric(r[2]), as.numeric(r[3]), as.numeric(r[4]),
            as.numeric(r[5]), as.numeric(r[6]), r[7]))
}

tabF1 <- c(tabF1,
  "\\hline\\hline",
  "\\end{tabular}",
  sprintf("\\par\\smallskip{\\small\\textit{Notes:} This paper studies whether state surprise billing laws affected emergency department quality of care. Data: CMS Hospital Compare OP-18b and OP-22, %d--%d. Estimator: Sun and Abraham (2021) interaction-weighted ATT with never-treated states as controls. Sample: %s acute care hospitals across %d states. SDE = $\\hat{\\beta}$ / SD($Y$). Classification reflects magnitude, not statistical significance.}",
          min(panel$meas_year), max(panel$meas_year),
          format(uniqueN(panel$provider_id), big.mark=","),
          uniqueN(panel$state)),
  "\\end{table}"
)
writeLines(tabF1, "tables/tabF1_sde.tex")

cat("All tables generated.\n")
