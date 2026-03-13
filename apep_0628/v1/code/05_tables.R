###############################################################################
# 05_tables.R — Generate all LaTeX tables (plain tabular format)
# Paper: The Invisible Tariff (apep_0628)
###############################################################################

source("00_packages.R")

# --------------------------------------------------------------------------
# Load data and models
# --------------------------------------------------------------------------
nigeria_balanced <- readRDS("../data/nigeria_balanced.rds")
panel <- readRDS("../data/panel.rds")
diag <- jsonlite::fromJSON("../data/diagnostics.json")

did_simple <- readRDS("../data/did_simple.rds")
did_asinh <- readRDS("../data/did_asinh.rds")
es_model <- readRDS("../data/es_model.rds")
ddd_model <- readRDS("../data/ddd_model.rds")
ddd_saturated <- readRDS("../data/ddd_saturated.rds")
extensive_did <- readRDS("../data/extensive_did.rds")
intensive_did <- readRDS("../data/intensive_did.rds")

placebo_product <- readRDS("../data/placebo_product.rds")
placebo_country <- readRDS("../data/placebo_country.rds")
placebo_time <- readRDS("../data/placebo_time.rds")
did_weighted <- readRDS("../data/did_weighted.rds")
did_hs4_cluster <- readRDS("../data/did_hs4_cluster.rds")
loo_results <- readRDS("../data/loo_results.rds")

tables_dir <- "../tables"

# Helper: significance stars
stars_fn <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# ==========================================================================
# Table 1: Summary Statistics
# ==========================================================================

cat("Generating Table 1: Summary Statistics\n")

sumstats <- nigeria_balanced[, .(
  mean_imports = mean(import_value, na.rm = TRUE),
  sd_imports = sd(import_value, na.rm = TRUE),
  median_imports = median(import_value, na.rm = TRUE),
  pct_positive = 100 * mean(import_value > 0, na.rm = TRUE),
  n_products = uniqueN(hs6),
  n_obs = .N
), by = .(Period = ifelse(post == 0, "Pre (2012--2014)", "Post (2016--2022)"),
          Group = ifelse(banned == 1, "FX-Banned", "Non-Banned"))]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Nigerian Imports by FX Ban Status}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{llrrrr}",
  "\\toprule",
  "Period & Group & Mean & Median & \\% Positive & Products \\\\",
  " & & (\\$1,000s) & (\\$1,000s) & Imports & \\\\",
  "\\midrule"
)

for (i in 1:nrow(sumstats)) {
  row <- sumstats[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %.1f & %s \\\\",
    row$Period, row$Group,
    format(round(row$mean_imports / 1000), big.mark = ","),
    format(round(row$median_imports / 1000), big.mark = ","),
    row$pct_positive,
    format(row$n_products, big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} HS6-level imports into Nigeria from all partners. FX-Banned: HS2 chapters covered by CBN Circular TED/FEM/FPC/GEN/01/011. Pre: 2012--2014. Post: 2016--2022. 2015 excluded. N = %s product-year observations.}",
          format(nrow(nigeria_balanced), big.mark = ",")),
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_sumstats.tex"))

# ==========================================================================
# Table 2: Main DiD Results
# ==========================================================================

cat("Generating Table 2: Main DiD Results\n")

# Extract coefficients
models <- list(did_simple, did_asinh, extensive_did, intensive_did)
coef_names <- c("banned:post", "banned:post", "banned:post", "banned:post")
col_labels <- c("Log Imports", "asinh(Imports)", "Extensive", "Intensive")

betas <- sapply(seq_along(models), function(i) coef(models[[i]])[coef_names[i]])
ses <- sapply(seq_along(models), function(i) se(models[[i]])[coef_names[i]])
pvals <- sapply(seq_along(models), function(i) pvalue(models[[i]])[coef_names[i]])
ns <- sapply(models, nobs)
r2s <- sapply(models, function(m) fitstat(m, "r2")$r2)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of FX Exclusion on Nigerian Imports}",
  "\\label{tab:main_did}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  sprintf(" & %s \\\\", paste(paste0("(", 1:4, ")"), collapse = " & ")),
  sprintf(" & %s \\\\", paste(col_labels, collapse = " & ")),
  "\\midrule",
  sprintf("Banned $\\times$ Post & %s \\\\",
          paste(sapply(1:4, function(i) sprintf("%.3f%s", betas[i], stars_fn(pvals[i]))), collapse = " & ")),
  sprintf(" & %s \\\\",
          paste(sapply(1:4, function(i) sprintf("(%.3f)", ses[i])), collapse = " & ")),
  " & & & & \\\\",
  sprintf("N & %s \\\\",
          paste(sapply(ns, function(n) format(n, big.mark = ",")), collapse = " & ")),
  sprintf("$R^2$ & %s \\\\",
          paste(sapply(r2s, function(r) sprintf("%.3f", r)), collapse = " & ")),
  "Product FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} SE clustered at HS2 level (%d clusters). Pre: 2012--2014, Post: 2016--2022. Banned: %s HS6 codes in %d HS2 chapters. Controls: %s HS6 codes. Col.~(3): Pr(imports $> 0$). Col.~(4): log imports conditional on positive. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}",
          diag$n_clusters,
          format(diag$n_treated, big.mark = ","),
          length(readRDS("../data/banned_hs2.rds")),
          format(diag$n_control, big.mark = ",")),
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main_did.tex"))

# ==========================================================================
# Table 3: Event Study Coefficients
# ==========================================================================

cat("Generating Table 3: Event Study\n")

es_terms <- grep("event_time", names(coef(es_model)), value = TRUE)
es_times <- as.numeric(gsub(".*::", "", es_terms))
es_est <- coef(es_model)[es_terms]
es_se <- se(es_model)[es_terms]
es_pv <- pvalue(es_model)[es_terms]

es_dt <- data.table(event_time = es_times, estimate = es_est, se = es_se, pval = es_pv)
es_dt <- es_dt[order(event_time)]

# Add reference
es_dt <- rbind(
  es_dt[event_time < 0],
  data.table(event_time = -1, estimate = 0, se = NA_real_, pval = NA_real_),
  es_dt[event_time >= 0]
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: FX Exclusion and Nigerian Imports}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event Time & Estimate & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_dt)) {
  r <- es_dt[i]
  yr <- ifelse(r$event_time < 0,
               paste0("$t", r$event_time, "$"),
               ifelse(r$event_time == 0, "$t$", paste0("$t+", r$event_time, "$")))
  if (r$event_time == -1) {
    tab3_lines <- c(tab3_lines, sprintf("%s & [Ref.] & & \\\\", yr))
  } else {
    ci_lo <- r$estimate - 1.96 * r$se
    ci_hi <- r$estimate + 1.96 * r$se
    tab3_lines <- c(tab3_lines, sprintf(
      "%s & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\",
      yr, r$estimate, stars_fn(r$pval), r$se, ci_lo, ci_hi
    ))
  }
}

# Pre-trend test
pre_coefs <- grep("event_time::-[2-3]", names(coef(es_model)), value = TRUE)
pre_test <- wald(es_model, pre_coefs)

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("N & \\multicolumn{3}{c}{%s} \\\\", format(nobs(es_model), big.mark = ",")),
  sprintf("Pre-trend $F$-test & \\multicolumn{3}{c}{$F = %.2f$, $p = %.3f$} \\\\",
          pre_test$stat, pre_test$p),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} $\\log(\\text{Imports}_{p,t}+1) = \\alpha_p + \\gamma_t + \\sum_k \\beta_k(\\text{Banned}_p \\times \\mathbf{1}\\{t=k\\}) + \\varepsilon_{p,t}$. Reference: $t-1$ (2014). SE clustered at HS2. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_event_study.tex"))

# ==========================================================================
# Table 4: Triple Difference (DDD)
# ==========================================================================

cat("Generating Table 4: DDD\n")

# Model 1: DDD baseline
b1 <- coef(ddd_model)
s1 <- se(ddd_model)
p1 <- pvalue(ddd_model)

# Model 2: DDD saturated
b2 <- coef(ddd_saturated)
s2 <- se(ddd_saturated)
p2 <- pvalue(ddd_saturated)

get_coef <- function(b, s, p, name) {
  if (name %in% names(b)) {
    list(est = b[name], se = s[name], pv = p[name])
  } else {
    list(est = NA, se = NA, pv = NA)
  }
}

ddd_trip1 <- get_coef(b1, s1, p1, "banned:nigeria:post")
ddd_trip2 <- get_coef(b2, s2, p2, "banned:nigeria:post")
ddd_bp <- get_coef(b1, s1, p1, "banned:post")
ddd_bn <- get_coef(b1, s1, p1, "banned:nigeria")

fmt <- function(x, p = NA) if (is.na(x)) "---" else sprintf("%.3f%s", x, stars_fn(p))
fmt_se <- function(x) if (is.na(x)) "" else sprintf("(%.3f)", x)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple Difference: Nigeria vs.\\ West African Controls}",
  "\\label{tab:ddd}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Baseline DDD & Saturated FE \\\\",
  "\\midrule",
  sprintf("Banned $\\times$ Nigeria $\\times$ Post & %s & %s \\\\",
          fmt(ddd_trip1$est, ddd_trip1$pv), fmt(ddd_trip2$est, ddd_trip2$pv)),
  sprintf(" & %s & %s \\\\", fmt_se(ddd_trip1$se), fmt_se(ddd_trip2$se)),
  " & & \\\\",
  sprintf("Banned $\\times$ Post & %s & \\\\", fmt(ddd_bp$est, ddd_bp$pv)),
  sprintf(" & %s & \\\\", fmt_se(ddd_bp$se)),
  sprintf("Banned $\\times$ Nigeria & %s & \\\\", fmt(ddd_bn$est, ddd_bn$pv)),
  sprintf(" & %s & \\\\", fmt_se(ddd_bn$se)),
  " & & \\\\",
  sprintf("N & %s & %s \\\\",
          format(nobs(ddd_model), big.mark = ","),
          format(nobs(ddd_saturated), big.mark = ",")),
  "Product $\\times$ Country FE & Yes & Yes \\\\",
  "Country $\\times$ Year FE & Yes & Yes \\\\",
  "Product $\\times$ Year FE & No & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} Dependent variable: log(imports $+ 1$). Control countries: Ghana, C\\^{o}te d'Ivoire, Senegal. SE clustered at HS2 level. Col.~(2) includes product$\\times$year FE, absorbing global product-specific trade trends. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_ddd.tex"))

# ==========================================================================
# Table 5: Robustness and Placebos
# ==========================================================================

cat("Generating Table 5: Robustness\n")

# Collect results
rob_models <- list(
  list(m = did_simple, cn = "banned:post", label = "Baseline"),
  list(m = did_weighted, cn = "banned:post", label = "Weighted"),
  list(m = did_hs4_cluster, cn = "banned:post", label = "HS4 cluster"),
  list(m = placebo_country, cn = "banned:post", label = "Placebo: countries"),
  list(m = placebo_time, cn = "banned:fake_post", label = "Placebo: timing")
)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robustness}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(rob_models)), collapse = "")),
  "\\toprule",
  sprintf(" & %s \\\\", paste(paste0("(", seq_along(rob_models), ")"), collapse = " & ")),
  sprintf(" & %s \\\\", paste(sapply(rob_models, function(x) x$label), collapse = " & ")),
  "\\midrule"
)

# Coefficient row
coef_row <- sapply(rob_models, function(x) {
  b <- coef(x$m)[x$cn]
  p <- pvalue(x$m)[x$cn]
  sprintf("%.3f%s", b, stars_fn(p))
})
se_row <- sapply(rob_models, function(x) {
  s <- se(x$m)[x$cn]
  sprintf("(%.3f)", s)
})
n_row <- sapply(rob_models, function(x) format(nobs(x$m), big.mark = ","))

tab5_lines <- c(tab5_lines,
  sprintf("Treatment $\\times$ Post & %s \\\\", paste(coef_row, collapse = " & ")),
  sprintf(" & %s \\\\", paste(se_row, collapse = " & ")),
  " & & & & & \\\\",
  sprintf("N & %s \\\\", paste(n_row, collapse = " & ")),
  "\\midrule",
  sprintf("LOO range & \\multicolumn{%d}{c}{[%.3f, %.3f] (dropping each banned HS2 chapter)} \\\\",
          length(rob_models), min(loo_results$coef), max(loo_results$coef)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} Col.~(1): baseline DiD. Col.~(2): weighted by pre-treatment import value. Col.~(3): SE clustered at HS4. Col.~(4): effect of banned products in Ghana/CIV/Senegal (no FX ban). Col.~(5): fake treatment in 2013, pre-period only. LOO: leave-one-out dropping each banned HS2 chapter. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_robustness.tex"))

# ==========================================================================
# SDE Table (Appendix)
# ==========================================================================

cat("Generating SDE Table\n")

nigeria_balanced[, has_imports := as.integer(import_value > 0)]

compute_sde <- function(model, outcome_var, data, outcome_label, coef_name = "banned:post") {
  beta <- coef(model)[coef_name]
  se_beta <- se(model)[coef_name]
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- function(x) {
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x <= 0.005) return("Null")
    if (x <= 0.05) return("Small positive")
    if (x <= 0.15) return("Moderate positive")
    return("Large positive")
  }

  data.table(
    Outcome = outcome_label,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_rows <- rbind(
  compute_sde(did_simple, "log_imports", nigeria_balanced, "Log imports (DiD)"),
  compute_sde(ddd_saturated, "log_imports", panel, "Log imports (DDD)", "banned:nigeria:post"),
  compute_sde(extensive_did, "has_imports", nigeria_balanced, "Pr(imports $> 0$)"),
  compute_sde(intensive_did, "log_imports", nigeria_balanced[import_value > 0], "Log imports $|$ positive")
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i]
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\par\\vspace{0.3em}{\\footnotesize \\textit{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. Research question: Does restricting access to official FX for specific products reduce imports? Data: UN Comtrade HS6-level bilateral imports, 2012--2022. Method: Product-level DiD and DDD with product/year FE, SE clustered at HS2. Sample: %s product-year observations, %d treated HS6 codes. Treatment: CBN FX exclusion (binary). Classification refers to magnitude of the standardized point estimate, not statistical significance. ``Null'' denotes $|\\text{SDE}| < 0.005$, not a failure to reject a null hypothesis.}",
          format(nrow(nigeria_balanced), big.mark = ","), nigeria_balanced[banned == 1, uniqueN(hs6)]),
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
