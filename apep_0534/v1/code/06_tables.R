## 06_tables.R — All tables for the paper
## apep_0534: Green Patent Examiner Leniency IV

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))
main_res <- fread(file.path(DATA_DIR, "main_results.csv"))
rob_res  <- fread(file.path(DATA_DIR, "robustness_results.csv"))
hetero_dom <- fread(file.path(DATA_DIR, "heterogeneity_domain.csv"))

dt[, leniency_std := (loo_leniency - mean(loo_leniency, na.rm = TRUE)) /
     sd(loo_leniency, na.rm = TRUE)]
dt[, log_claims := log1p(num_claims)]
dt[, log_bwd_cite := log1p(bwd_citations)]
for (v in c("followon_3yr", "followon_5yr", "followon_10yr", "fwd_citations"))
  dt[, paste0("log_", v) := log1p(get(v))]

# ── Table 1: Summary Statistics ─────────────────────────────────────────
cat("=== Table 1: Summary Statistics ===\n")

summ_vars <- c("num_claims", "bwd_citations", "loo_leniency",
               "followon_3yr", "followon_5yr", "followon_10yr",
               "fwd_citations")
summ_vars <- summ_vars[summ_vars %in% names(dt)]

summ <- rbindlist(lapply(summ_vars, function(v) {
  x <- dt[[v]]
  data.table(
    Variable = v,
    N = sum(!is.na(x)),
    Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    P25 = quantile(x, 0.25, na.rm = TRUE),
    Median = median(x, na.rm = TRUE),
    P75 = quantile(x, 0.75, na.rm = TRUE)
  )
}))

# Pretty names
summ[, Variable := fcase(
  Variable == "num_claims", "Number of Claims",
  Variable == "bwd_citations", "Backward Citations",
  Variable == "loo_leniency", "Examiner Leniency (LOO)",
  Variable == "followon_3yr", "Follow-on Y02 Patents (3yr)",
  Variable == "followon_5yr", "Follow-on Y02 Patents (5yr)",
  Variable == "followon_10yr", "Follow-on Y02 Patents (10yr)",
  Variable == "fwd_citations", "Forward Citations",
  default = Variable
)]

fwrite(summ, file.path(TAB_DIR, "tab1_summary.csv"))

# LaTeX version
sink(file.path(TAB_DIR, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics: Y02 Green Patent Applications, 2001--2018}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrr}\n\\hline\\hline\n")
cat("Variable & N & Mean & SD & P25 & Median & P75 \\\\\n\\hline\n")
for (i in 1:nrow(summ)) {
  cat(sprintf("%s & %s & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n",
              summ$Variable[i], format(summ$N[i], big.mark = ","),
              summ$Mean[i], summ$SD[i], summ$P25[i], summ$Median[i], summ$P75[i]))
}
cat("\\hline\\hline\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n\\footnotesize\n")
cat("\\textit{Notes:} Sample includes all utility Y02-classified patents granted by the USPTO")
cat(" with filing dates 2001--2018 and valid examiner assignment.")
cat(" Examiner leniency is the leave-one-out mean grant count of the assigned examiner")
cat(" within the art-unit $\\times$ year cell.")
cat(" Follow-on counts measure new Y02 patents in the same CPC subclass")
cat(" filed within the specified window after the focal patent's grant date.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 1 saved.\n")

# ── Table 2: Balance Test ───────────────────────────────────────────────
cat("\n=== Table 2: Balance Test ===\n")

balance_models <- list()
for (v in c("log_claims", "log_bwd_cite")) {
  balance_models[[v]] <- feols(
    as.formula(paste(v, "~ leniency_std | au_fy")),
    data = dt, vcov = ~examiner_id
  )
}

sink(file.path(TAB_DIR, "tab2_balance.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Balance Test: Application Characteristics on Examiner Leniency}\n")
cat("\\label{tab:balance}\n")
cat("\\begin{tabular}{lcc}\n\\hline\\hline\n")
cat(" & (1) & (2) \\\\\n")
cat(" & Log Claims & Log Backward Cites \\\\\n\\hline\n")
cat(sprintf("Examiner Leniency & %.4f & %.4f \\\\\n",
            coef(balance_models[["log_claims"]])["leniency_std"],
            coef(balance_models[["log_bwd_cite"]])["leniency_std"]))
cat(sprintf(" & (%.4f) & (%.4f) \\\\\n",
            sqrt(vcov(balance_models[["log_claims"]])["leniency_std", "leniency_std"]),
            sqrt(vcov(balance_models[["log_bwd_cite"]])["leniency_std", "leniency_std"])))
cat(sprintf("Art Unit $\\times$ Year FE & Yes & Yes \\\\\n"))
cat(sprintf("Observations & %s & %s \\\\\n",
            format(nobs(balance_models[["log_claims"]]), big.mark = ","),
            format(nobs(balance_models[["log_bwd_cite"]]), big.mark = ",")))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.8\\textwidth}\n\\footnotesize\n")
cat("\\textit{Notes:} Each column regresses an application characteristic on")
cat(" standardized examiner leniency with art-unit $\\times$ filing-year fixed effects.")
cat(" Standard errors clustered at the examiner level in parentheses.")
cat(" Under random assignment, coefficients should be zero.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 2 saved.\n")

# ── Table 3: Main Results ───────────────────────────────────────────────
cat("\n=== Table 3: Main Results ===\n")

# Re-estimate for clean table output
m_3yr_0 <- feols(log_followon_3yr ~ leniency_std | au_fy, data = dt, vcov = ~examiner_id)
m_3yr_1 <- feols(log_followon_3yr ~ leniency_std + log_claims + log_bwd_cite | au_fy, data = dt, vcov = ~examiner_id)
m_5yr_0 <- feols(log_followon_5yr ~ leniency_std | au_fy, data = dt, vcov = ~examiner_id)
m_5yr_1 <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy, data = dt, vcov = ~examiner_id)
m_10yr_0 <- feols(log_followon_10yr ~ leniency_std | au_fy, data = dt, vcov = ~examiner_id)
m_10yr_1 <- feols(log_followon_10yr ~ leniency_std + log_claims + log_bwd_cite | au_fy, data = dt, vcov = ~examiner_id)

etable(m_3yr_0, m_3yr_1, m_5yr_0, m_5yr_1, m_10yr_0, m_10yr_1,
       tex = TRUE,
       file = file.path(TAB_DIR, "tab3_main_results.tex"),
       title = "Effect of Examiner Leniency on Follow-on Green Innovation",
       label = "tab:main",
       headers = c("3-Year", "3-Year", "5-Year", "5-Year", "10-Year", "10-Year"),
       keep = "%leniency_std",
       dict = c(leniency_std = "Examiner Leniency (1 SD)"),
       notes = paste("Each column reports the effect of a one standard deviation increase",
                     "in examiner leniency on log follow-on Y02 patent applications in the same CPC subclass.",
                     "Odd columns: no application controls. Even columns: controls for log claims and log backward citations.",
                     "All specifications include art-unit x filing-year fixed effects.",
                     "Standard errors clustered at the examiner level."),
       se.below = TRUE,
       fitstat = c("n", "r2"))
cat("Table 3 saved.\n")

# ── Table 4: Heterogeneity by Technology Domain ─────────────────────────
cat("\n=== Table 4: Heterogeneity ===\n")

dom_models <- list()
for (dom in unique(dt$y02_domain)) {
  sub <- dt[y02_domain == dom]
  if (nrow(sub) >= 200) {
    dom_models[[dom]] <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
                               data = sub, vcov = ~examiner_id)
  }
}

if (length(dom_models) >= 2) {
  do.call(etable, c(dom_models,
                    list(tex = TRUE,
                         file = file.path(TAB_DIR, "tab4_heterogeneity.tex"),
                         title = "Heterogeneity by Y02 Technology Domain",
                         label = "tab:hetero",
                         headers = names(dom_models),
                         keep = "%leniency_std",
                         dict = c(leniency_std = "Examiner Leniency (1 SD)"),
                         se.below = TRUE,
                         fitstat = c("n", "r2"))))
}
cat("Table 4 saved.\n")

# ── Table 5: Robustness ────────────────────────────────────────────────
cat("\n=== Table 5: Robustness ===\n")

rob_res[, stars := fcase(
  abs(coef / se) > 2.576, "***",
  abs(coef / se) > 1.96, "**",
  abs(coef / se) > 1.645, "*",
  default = ""
)]

sink(file.path(TAB_DIR, "tab5_robustness.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Robustness Checks}\n\\label{tab:robust}\n")
cat("\\begin{tabular}{lcc}\n\\hline\\hline\n")
cat("Specification & Coefficient & Std. Error \\\\\n\\hline\n")
for (i in 1:nrow(rob_res)) {
  cat(sprintf("%s & %.4f%s & (%.4f) \\\\\n",
              gsub("_", " ", rob_res$test[i]),
              rob_res$coef[i], rob_res$stars[i], rob_res$se[i]))
}
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{minipage}{0.8\\textwidth}\n\\footnotesize\n")
cat("\\textit{Notes:} Each row reports the coefficient on examiner leniency (or alternative")
cat(" harshness measure) from a variant of the main specification.")
cat(" All specifications include art-unit $\\times$ filing-year fixed effects.\n")
cat("$^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Table 5 saved.\n")

cat("\nAll tables complete.\n")
