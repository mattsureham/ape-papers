## 06_tables.R — All tables for the paper
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))
main_res <- fread(file.path(DATA_DIR, "main_results.csv"))
rob_res  <- fread(file.path(DATA_DIR, "robustness_results.csv"))
fs_res   <- fread(file.path(DATA_DIR, "first_stage_results.csv"))
hetero_dom <- fread(file.path(DATA_DIR, "heterogeneity_domain.csv"))

dt[, grant_rate_std := (loo_grant_rate_i - mean(loo_grant_rate_i, na.rm = TRUE)) /
     sd(loo_grant_rate_i, na.rm = TRUE)]
dt[, log_claims := log1p(num_claims)]
dt[, log_bwd_cite := log1p(bwd_citations)]
for (v in c("followon_3yr", "followon_5yr", "followon_10yr", "fwd_citations"))
  dt[, paste0("log_", v) := log1p(get(v))]

# Global dictionary for clean FE labels in all tables
setFixest_dict(c(au_fy = "Art-Unit $\\times$ Filing-Year",
                 "y02_domain-filing_year" = "Domain $\\times$ Filing-Year",
                 "y02_domain^filing_year" = "Domain $\\times$ Filing-Year"))

# ── Table 1: Summary Statistics ─────────────────────────────────────────
cat("=== Table 1: Summary Statistics ===\n")

# Panel A: Full sample
summ_vars_full <- c("granted", "loo_grant_rate_i", "num_claims", "bwd_citations",
                     "followon_3yr", "followon_5yr", "followon_10yr", "fwd_citations")
summ_vars_full <- summ_vars_full[summ_vars_full %in% names(dt)]

summ_full <- rbindlist(lapply(summ_vars_full, function(v) {
  x <- dt[[v]]
  data.table(Variable = v, N = sum(!is.na(x)), Mean = mean(x, na.rm = TRUE),
             SD = sd(x, na.rm = TRUE), P25 = quantile(x, 0.25, na.rm = TRUE),
             Median = median(x, na.rm = TRUE), P75 = quantile(x, 0.75, na.rm = TRUE))
}))

# Panel B: Granted only
summ_granted <- rbindlist(lapply(summ_vars_full[summ_vars_full != "granted"], function(v) {
  x <- dt[granted == 1][[v]]
  data.table(Variable = v, N = sum(!is.na(x)), Mean = mean(x, na.rm = TRUE),
             SD = sd(x, na.rm = TRUE), P25 = quantile(x, 0.25, na.rm = TRUE),
             Median = median(x, na.rm = TRUE), P75 = quantile(x, 0.75, na.rm = TRUE))
}))

# Pretty names
pretty_name <- function(v) {
  fcase(v == "granted", "Application Granted",
        v == "loo_grant_rate_i", "Examiner Grant Rate (LOO)",
        v == "num_claims", "Number of Claims",
        v == "bwd_citations", "Backward Citations",
        v == "followon_3yr", "Follow-on Y02 Patents (3yr)",
        v == "followon_5yr", "Follow-on Y02 Patents (5yr)",
        v == "followon_10yr", "Follow-on Y02 Patents (10yr)",
        v == "fwd_citations", "Forward Citations",
        default = v)
}
summ_full[, Variable := sapply(Variable, pretty_name)]
summ_granted[, Variable := sapply(Variable, pretty_name)]

fwrite(summ_full, file.path(TAB_DIR, "tab1_summary.csv"))

# LaTeX version
sink(file.path(TAB_DIR, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics: Green Patent Applications, 2001--2012}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrr}\n\\hline\\hline\n")
cat("Variable & N & Mean & SD & P25 & Median & P75 \\\\\n\\hline\n")
# Use 3 decimals for rates/proportions, 1 decimal for counts
fmt_row <- function(row) {
  v <- row$Variable
  is_count <- grepl("Claims|Citations|Follow-on", v)
  fmt <- if (is_count) "%.1f" else "%.3f"
  # Use comma formatting for large count medians/percentiles
  sprintf(paste0("%s & %s & ", fmt, " & ", fmt, " & ",
                 if (is_count) "%s" else fmt, " & ",
                 if (is_count) "%s" else fmt, " & ",
                 if (is_count) "%s" else fmt, " \\\\\n"),
          v, format(row$N, big.mark = ","),
          row$Mean, row$SD,
          if (is_count) format(round(row$P25), big.mark = ",") else row$P25,
          if (is_count) format(round(row$Median), big.mark = ",") else row$Median,
          if (is_count) format(round(row$P75), big.mark = ",") else row$P75)
}

cat("\\multicolumn{7}{l}{\\textit{Panel A: Full Sample (Applications)}} \\\\\n")
for (i in 1:nrow(summ_full)) {
  cat(fmt_row(summ_full[i]))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Granted Patents Only}} \\\\\n")
for (i in 1:nrow(summ_granted)) {
  cat(fmt_row(summ_granted[i]))
}
cat("\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n\\footnotesize\n")
cat("\\textit{Notes:} Panel A includes all utility patent applications filed 2001--2012")
cat(" in Y02-technology art units (those where $>$10\\% of resolved applications receive Y02 CPC codes)")
cat(" with resolved disposition (granted or abandoned) and valid examiner assignment.")
cat(" Panel B restricts to granted applications.")
cat(" Examiner Grant Rate (LOO) is the leave-one-out grant rate of the assigned examiner")
cat(" within the art-unit $\\times$ filing-year cell.")
cat(" Follow-on counts measure new Y02 patents in the same CPC subclass")
cat(" filed within the specified window.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 saved.\n")

# ── Table 2: First Stage ────────────────────────────────────────────────
cat("\n=== Table 2: First Stage ===\n")

fs0 <- feols(granted ~ grant_rate_std | au_fy, data = dt, vcov = ~examiner_id)
fs1 <- feols(granted ~ grant_rate_std + log_claims + log_bwd_cite | au_fy, data = dt, vcov = ~examiner_id)
fs2 <- feols(granted ~ grant_rate_std + log_claims + log_bwd_cite | au_fy + y02_domain^filing_year,
             data = dt, vcov = ~examiner_id)

etable(fs0, fs1, fs2,
       tex = TRUE,
       file = file.path(TAB_DIR, "tab2_first_stage.tex"),
       title = "First Stage: Examiner Grant Rate Predicts Application Granted",
       label = "tab:firststage",
       headers = c("(1)", "(2)", "(3)"),
       keep = "%grant_rate_std",
       dict = c(grant_rate_std = "Examiner Grant Rate (1 SD)"),
       notes = paste("Dependent variable: application granted (1 = ISS, 0 = ABN).",
                     "Examiner grant rate is the leave-one-out grant rate of the assigned examiner",
                     "within the art-unit $\\times$ filing-year cell.",
                     "Column (1): art-unit $\\times$ filing-year FE only.",
                     "Column (2): adds $\\log(1 + \\text{claims})$ and $\\log(1 + \\text{backward citations})$.",
                     "Column (3): adds Y02 domain $\\times$ filing-year FE.",
                     "Standard errors clustered at the examiner level."),
       se.below = TRUE,
       fitstat = c("n", "r2", "ivf"))
cat("Table 2 saved.\n")

# ── Table 3: Balance Test ───────────────────────────────────────────────
cat("\n=== Table 3: Balance Test ===\n")

# Balance tests must run on grants-only to avoid mechanical correlation
# (claims and citations are zero for abandoned applications)
dt_granted <- dt[granted == 1]
dt_granted[, grant_rate_std_g := (loo_grant_rate_i - mean(loo_grant_rate_i, na.rm = TRUE)) /
             sd(loo_grant_rate_i, na.rm = TRUE)]

balance_models <- list()
bvars <- c("log_claims", "log_bwd_cite")
bvars <- bvars[sapply(bvars, function(v) v %in% names(dt_granted) & sum(!is.na(dt_granted[[v]])) > 100)]
for (v in bvars) {
  balance_models[[v]] <- feols(
    as.formula(paste(v, "~ grant_rate_std_g | au_fy")),
    data = dt_granted, vcov = ~examiner_id
  )
}
rm(dt_granted)

if (length(balance_models) >= 2) {
  do.call(etable, c(balance_models,
                    list(tex = TRUE,
                         file = file.path(TAB_DIR, "tab3_balance.tex"),
                         title = "Balance Test: Application Characteristics on Examiner Grant Rate (Grants Only)",
                         label = "tab:balance",
                         keep = "%grant_rate_std",
                         dict = c(grant_rate_std_g = "Examiner Grant Rate (1 SD)"),
                         notes = "Grants-only subsample (442,292 granted applications; 5 singleton observations removed by fixed effects). Claims and citations are only observed for granted patents; variables are $\\log(1 + x)$. Standard errors clustered at the examiner level. Under random assignment, coefficients should be zero.",
                         se.below = TRUE,
                         fitstat = c("n", "r2"))))
}
cat("Table 3 saved.\n")

# ── Table 4: Main Results (Follow-on + Citations) ───────────────────────
cat("\n=== Table 4: Main Results ===\n")

# Follow-on patenting: baseline, controlled, IV
m_5yr_0 <- feols(log_followon_5yr ~ grant_rate_std | au_fy, data = dt, vcov = ~examiner_id)
m_5yr_1 <- feols(log_followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy, data = dt, vcov = ~examiner_id)
m_5yr_iv <- feols(log_followon_5yr ~ log_claims + log_bwd_cite | au_fy | granted ~ grant_rate_std,
                  data = dt, vcov = ~examiner_id)

# Forward citations: baseline, controlled, IV
m_cite_0 <- feols(log_fwd_citations ~ grant_rate_std | au_fy, data = dt, vcov = ~examiner_id)
m_cite_1 <- feols(log_fwd_citations ~ grant_rate_std + log_claims + log_bwd_cite | au_fy, data = dt, vcov = ~examiner_id)
m_cite_iv <- feols(log_fwd_citations ~ log_claims + log_bwd_cite | au_fy | granted ~ grant_rate_std,
                   data = dt, vcov = ~examiner_id)

etable(m_5yr_0, m_5yr_1, m_5yr_iv, m_cite_0, m_cite_1, m_cite_iv,
       tex = TRUE,
       file = file.path(TAB_DIR, "tab4_main_results.tex"),
       title = "Effect of Examiner Grant Rate on Follow-on Innovation and Citations",
       label = "tab:main",
       headers = list("Follow-on 5yr" = 3, "Forward Citations" = 3),
       keep = "%grant_rate_std|fit_granted|log_claims|log_bwd_cite",
       dict = c(grant_rate_std = "Examiner Grant Rate (1 SD)",
                fit_granted = "Granted (IV)",
                log_claims = "$\\log(1 + \\text{Claims})$",
                log_bwd_cite = "$\\log(1 + \\text{Bwd. Citations})$"),
       notes = paste("Columns (1)--(2) and (4)--(5): reduced-form effect of examiner grant rate.",
                     "Column (1)/(4): baseline without application controls (preferred).",
                     "Column (2)/(5): adds $\\log(1 + \\text{claims})$ and $\\log(1 + \\text{backward citations})$ as controls.",
                     "Note: claims and citations are coded as zero for abandoned applications",
                     "(unavailable in PatentsView), then log-transformed; these controls therefore partly proxy grant status.",
                     "Columns (3) and (6): exploratory IV estimates (exclusion restriction demanding; not causally interpretable as grant effects).",
                     "The IV first-stage F (Wald statistic from joint IV estimation) differs from the standalone F in Table 2",
                     "due to the inclusion of endogenous regressors in the joint specification.",
                     "All specifications include art-unit $\\times$ filing-year FE.",
                     "Standard errors clustered at the examiner level.",
                     "The high $R^2$ in follow-on columns reflects the shared-outcome structure:",
                     "follow-on patenting is a CPC subclass $\\times$ filing-year aggregate (96 unique values),",
                     "so AU $\\times$ FY fixed effects absorb nearly all outcome variation."),
       se.below = TRUE,
       fitstat = c("n", "r2", "ivf"))
cat("Table 4 saved.\n")

# ── Table 5: Heterogeneity by Technology Domain ─────────────────────────
cat("\n=== Table 5: Heterogeneity ===\n")

# Forward citations are an individual-level outcome, so heterogeneity by domain is estimable.
# Follow-on patenting is a CPC-subclass x filing-year aggregate that is absorbed by FE
# in domain subsamples — use forward citations for domain heterogeneity instead.
dom_models <- list()
for (dom in sort(unique(dt$y02_domain))) {
  sub <- dt[y02_domain == dom]
  if (nrow(sub) >= 500) {
    m <- tryCatch(
      feols(log_fwd_citations ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
            data = sub, vcov = ~examiner_id),
      error = function(e) NULL
    )
    if (!is.null(m) && !is.na(coef(m)["grant_rate_std"]) && !is.nan(coef(m)["grant_rate_std"])) {
      dom_models[[dom]] <- m
    }
  }
}

if (length(dom_models) >= 2) {
  # Use short domain names to fit table width
  short_names <- gsub("Other_Y02", "Other", names(dom_models))
  short_names <- gsub("CarbonCapture", "CCS", short_names)

  do.call(etable, c(dom_models,
                    list(tex = TRUE,
                         file = file.path(TAB_DIR, "tab5_heterogeneity.tex"),
                         title = "Heterogeneity by Y02 Technology Domain: Forward Citations",
                         label = "tab:hetero",
                         headers = short_names,
                         keep = "%grant_rate_std",
                         dict = c(grant_rate_std = "Grant Rate (1 SD)"),
                         notes = paste("Dep. var: $\\log(1 + \\text{forward citations})$.",
                                       "CCS = Carbon Capture \\\\& Storage.",
                                       "All columns include AU $\\times$ FY FE and controls ($\\log(1 + \\text{claims})$, $\\log(1 + \\text{backward citations})$).",
                                       "SEs clustered at examiner level."),
                         se.below = TRUE,
                         fitstat = c("n", "r2"))))

  # Wrap in adjustbox
  lines <- readLines(file.path(TAB_DIR, "tab5_heterogeneity.tex"))
  # Insert adjustbox after \centering
  idx <- grep("\\\\centering", lines)[1]
  if (!is.na(idx)) {
    lines <- c(lines[1:idx], "\\begin{adjustbox}{max width=\\textwidth}",
               lines[(idx+1):length(lines)])
    # Find end of tabular and add closing adjustbox
    idx_end <- max(grep("\\\\end\\{tabular\\}", lines))
    lines <- c(lines[1:idx_end], "\\end{adjustbox}", lines[(idx_end+1):length(lines)])
    writeLines(lines, file.path(TAB_DIR, "tab5_heterogeneity.tex"))
  }
}
cat("Table 5 saved.\n")

# ── Table 6: Robustness ────────────────────────────────────────────────
cat("\n=== Table 6: Robustness ===\n")

rob_res[, stars := fcase(
  abs(coef / se) > 2.576, "***",
  abs(coef / se) > 1.96, "**",
  abs(coef / se) > 1.645, "*",
  default = ""
)]

# Load collapsed subclass results if available
coll_sub_file <- file.path(DATA_DIR, "collapsed_subclass_results.csv")
coll_sub <- if (file.exists(coll_sub_file)) fread(coll_sub_file) else NULL

sink(file.path(TAB_DIR, "tab6_robustness.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Robustness Checks, Falsification, and Aggregation}\n\\label{tab:robust}\n")
cat("\\begin{tabular}{lcccc}\n\\hline\\hline\n")
cat("Specification & Coefficient & Std. Error & N & FE \\\\\n\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Robustness}} \\\\\n")
for (i in which(!grepl("Placebo|Collapsed", rob_res$test))) {
  n_str <- if ("n" %in% names(rob_res)) format(rob_res$n[i], big.mark = ",") else ""
  cat(sprintf("%s & %.4f%s & (%.4f) & %s & AU$\\times$Y \\\\\n",
              gsub("_", " ", rob_res$test[i]),
              rob_res$coef[i], rob_res$stars[i], rob_res$se[i], n_str))
}
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Falsification}} \\\\\n")
for (i in which(grepl("Placebo", rob_res$test))) {
  n_str <- if ("n" %in% names(rob_res)) format(rob_res$n[i], big.mark = ",") else ""
  # Use higher precision for placebo to avoid 0.0000
  cat(sprintf("%s & %.6f%s & (%.6f) & %s & AU$\\times$Y \\\\\n",
              gsub("_", " ", rob_res$test[i]),
              rob_res$coef[i], rob_res$stars[i], rob_res$se[i], n_str))
}
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel C: Collapsed Aggregation}} \\\\\n")
# Subclass × Year collapsed (from 03_main_analysis.R)
if (!is.null(coll_sub)) {
  for (j in 1:nrow(coll_sub)) {
    s <- coll_sub$stars_lbl <- ifelse(abs(coll_sub$coef[j] / coll_sub$se[j]) > 2.576, "***",
                               ifelse(abs(coll_sub$coef[j] / coll_sub$se[j]) > 1.96, "**",
                               ifelse(abs(coll_sub$coef[j] / coll_sub$se[j]) > 1.645, "*", "")))
    fe_lbl <- switch(coll_sub$spec[j],
                     "year_fe_only" = "Year",
                     "subclass_year_fe" = "Sub+Year",
                     "subclass_year_fe_controls" = "Sub+Year+Ctrl")
    cat(sprintf("Collapsed subclass$\\times$year & %.4f%s & (%.4f) & %d & %s \\\\\n",
                coll_sub$coef[j], s, coll_sub$se[j], coll_sub$n[j], fe_lbl))
  }
}
# AU × Year collapsed (from 04_robustness.R)
for (i in which(grepl("Collapsed", rob_res$test))) {
  n_str <- if ("n" %in% names(rob_res)) format(rob_res$n[i], big.mark = ",") else ""
  fe_lbl <- if (grepl("no_controls", rob_res$test[i])) "AU+Y" else "AU+Y+Ctrl"
  cat(sprintf("%s & %.4f%s & (%.4f) & %s & %s \\\\\n",
              gsub("_", " ", rob_res$test[i]),
              rob_res$coef[i], rob_res$stars[i], rob_res$se[i], n_str, fe_lbl))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n\\footnotesize\n")
cat("\\textit{Notes:} Panel A reports the coefficient on examiner grant rate (1 SD)")
cat(" from variants of the main specification with application controls ($\\log(1 + \\text{claims})$, $\\log(1 + \\text{backward citations})$)")
cat(" and art-unit $\\times$ filing-year fixed effects.")
cat(" Panel B: placebo outcome is $\\log(1 + \\text{follow-on in other CPC subclasses})$,")
cat(" baseline specification without controls.")
cat(" The placebo outcome varies at the subclass $\\times$ year level; the small SE reflects limited residual variation after FE.")
cat(" Panel C collapses the data to the level at which the follow-on outcome varies.")
cat(" ``Subclass$\\times$year'' uses 96 CPC subclass-by-filing-year cells, weighted by cell size.")
cat(" ``AU'' uses art-unit-by-filing-year cells with AU + year FE.")
cat(" Dependent variable (except Panel B): $\\log(1 + \\text{follow-on Y02 patents, 5yr})$.")
cat(" Standard errors clustered at the examiner level (Panels A--B)")
cat(" or robust (Panel C).\n")
cat("$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 6 saved.\n")

# ── Table 7: Clustering Comparison ──────────────────────────────────────
cat("\n=== Table 7: Clustering ===\n")
cluster_file <- file.path(DATA_DIR, "clustering_comparison.csv")
if (file.exists(cluster_file)) {
  cl_res <- fread(cluster_file)
  cl_res[, stars := fcase(
    abs(coef / se) > 2.576, "***",
    abs(coef / se) > 1.96, "**",
    abs(coef / se) > 1.645, "*",
    default = ""
  )]

  n_val <- format(nrow(dt), big.mark = ",")
  sink(file.path(TAB_DIR, "tab7_clustering.tex"))
  cat("\\begin{table}[htbp]\n\\centering\n")
  cat("\\caption{Inference Under Alternative Clustering}\n\\label{tab:cluster}\n")
  cat("\\begin{tabular}{lccc}\n\\hline\\hline\n")
  cat("Clustering Level & Coefficient & Std. Error & N \\\\\n\\hline\n")
  for (i in 1:nrow(cl_res)) {
    cat(sprintf("%s & %.4f%s & (%.4f) & %s \\\\\n",
                cl_res$cluster[i], cl_res$coef[i], cl_res$stars[i], cl_res$se[i], n_val))
  }
  cat("\\hline\\hline\n\\end{tabular}\n")
  cat("\\begin{minipage}{0.8\\textwidth}\n\\footnotesize\n")
  cat("\\textit{Notes:} Outcome is log(1 + follow-on Y02 patents, 5yr).")
  cat(" All rows use the baseline specification without application controls,")
  cat(" with art-unit $\\times$ filing-year FE.")
  cat(" CPC Subclass $\\times$ Year clustering addresses the shared-outcome")
  cat(" concern that many applications share the same subclass-level follow-on count.\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()
  cat("Table 7 saved.\n")
}

cat("\nAll tables complete.\n")
