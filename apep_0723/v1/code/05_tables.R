## 05_tables.R — Generate all LaTeX tables for apep_0723
## apep_0723: EU Youth Employment Initiative RDD

source("00_packages.R")

df          <- readRDS("../data/analysis_clean.rds")
models      <- readRDS("../data/models.rds")
robustness  <- readRDS("../data/robustness.rds")
diagnostics <- jsonlite::read_json("../data/diagnostics.json")

rdd_neet <- models$rdd_neet
rdd_emp  <- models$rdd_emp
rdd_esl  <- models$rdd_esl
ols_lin  <- models$ols_lin
ols_quad <- models$ols_quad
ols_bw   <- models$ols_bw
ols_emp  <- models$ols_emp
es_df    <- models$es_df
bw_main  <- models$bw_main

# ============================================================
# HELPER FUNCTIONS
# ============================================================

stars <- function(p) {
  case_when(p < 0.01 ~ "$^{***}$", p < 0.05 ~ "$^{**}$", p < 0.10 ~ "$^{*}$", TRUE ~ "")
}

fmt_coef <- function(b, p) sprintf("%.3f%s", b, stars(p))
fmt_se   <- function(se) sprintf("(%.3f)", se)
fmt_bw   <- function(bw) if (is.na(bw)) "--" else sprintf("%.2f", bw)

rdd_coef <- function(obj) as.numeric(obj$coef["Conventional"])
rdd_se   <- function(obj) as.numeric(obj$se["Conventional"])
rdd_pval <- function(obj) as.numeric(obj$pv["Conventional"])
rdd_bw   <- function(obj) as.numeric(obj$bws["h", "left"])
rdd_n    <- function(obj) as.numeric(obj$N_h["left"]) + as.numeric(obj$N_h["right"])

ols_coef <- function(mod, term) {
  ct <- coeftable(mod)
  if (!(term %in% rownames(ct))) return(c(b=NA, se=NA, p=NA))
  c(b=ct[term,"Estimate"], se=ct[term,"Std. Error"], p=ct[term,"Pr(>|t|)"])
}

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================

cat("Generating Table 1: Summary statistics...\n")

df_above <- df %>% filter(treated == 1)
df_below <- df %>% filter(treated == 0)

smry <- function(x) c(mean=mean(x, na.rm=TRUE), sd=sd(x, na.rm=TRUE), n=sum(!is.na(x)))

make_row <- function(var_above, var_below, label) {
  a <- smry(var_above)
  b <- smry(var_below)
  # t-test for difference
  tt <- tryCatch(t.test(var_above, var_below), error=function(e) list(p.value=NA))
  diff_p <- tt$p.value
  diff_stars <- if (!is.na(diff_p)) stars(diff_p) else ""

  sprintf("%-42s & %.2f & (%.2f) & %.2f & (%.2f) & %.2f%s \\\\\n",
          label,
          a["mean"], a["sd"],
          b["mean"], b["sd"],
          a["mean"] - b["mean"], diff_stars)
}

tab1_body <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by YEI Eligibility Status}\n",
  "\\label{tab:summary}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Above 25\\%} & \\multicolumn{2}{c}{Below 25\\%} & \\multicolumn{2}{c}{Difference} \\\\\n",
  " & Mean & (SD) & Mean & (SD) & Est. & \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Running variable and treatment}} \\\\\n",
  make_row(df_above$unemp_2012, df_below$unemp_2012, "Youth unemployment rate, 2012 (\\%)"),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Pre-YEI outcomes (2010--2012 average)}} \\\\\n",
  make_row(df_above$neet_pre, df_below$neet_pre, "NEET rate, ages 18--24 (\\%)"),
  make_row(df_above$emp_pre, df_below$emp_pre, "Youth employment rate, ages 15--24 (\\%)"),
  make_row(df_above$esl_pre, df_below$esl_pre, "Early school leaving rate (\\%)"),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Post-YEI outcomes (2016--2019 average)}} \\\\\n",
  make_row(df_above$neet_post, df_below$neet_post, "NEET rate, ages 18--24 (\\%)"),
  make_row(df_above$emp_post, df_below$emp_post, "Youth employment rate, ages 15--24 (\\%)"),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Outcome changes (post $-$ pre)}} \\\\\n",
  make_row(df_above$d_neet, df_below$d_neet, "$\\Delta$ NEET rate (pp)"),
  make_row(df_above$d_emp, df_below$d_emp, "$\\Delta$ Youth employment rate (pp)"),
  make_row(df_above$d_esl, df_below$d_esl, "$\\Delta$ Early school leaving (pp)"),
  "\\midrule\n",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          nrow(df_above), nrow(df_below), nrow(df)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\raggedright\\footnotesize\n",
  "Notes: NUTS2 regions from EU-27 member states. Above/below threshold defined by whether the 2012 youth unemployment rate (ages 15--24) was at or above 25\\%, the YEI eligibility cutoff. Pre-YEI period: 2010--2012; post-YEI period: 2016--2019. Difference column reports above minus below; stars denote significance of a two-sample $t$-test ($^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$).\n",
  "\\end{table}\n"
)

writeLines(tab1_body, "../tables/tab1_summary.tex")
cat("Table 1 saved.\n")

# ============================================================
# TABLE 2: MAIN RDD RESULTS (THREE OUTCOMES)
# ============================================================

cat("Generating Table 2: Main RDD results...\n")

# Extract RDD estimates for three outcomes
b_neet <- rdd_coef(rdd_neet);  se_neet <- rdd_se(rdd_neet);  p_neet <- rdd_pval(rdd_neet)
b_emp  <- rdd_coef(rdd_emp);   se_emp  <- rdd_se(rdd_emp);   p_emp  <- rdd_pval(rdd_emp)

if (!is.null(rdd_esl)) {
  b_esl <- rdd_coef(rdd_esl); se_esl <- rdd_se(rdd_esl); p_esl <- rdd_pval(rdd_esl)
  n_esl <- rdd_n(rdd_esl);    bw_esl <- rdd_bw(rdd_esl)
} else {
  b_esl <- NA; se_esl <- NA; p_esl <- NA; n_esl <- NA; bw_esl <- NA
}

n_neet <- rdd_n(rdd_neet); bw_neet <- rdd_bw(rdd_neet)
n_emp  <- rdd_n(rdd_emp);  bw_emp  <- rdd_bw(rdd_emp)

tab2 <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{RDD Estimates: Effect of YEI Eligibility on Youth Labor Market Outcomes}\n",
  "\\label{tab:rdd_main}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & $\\Delta$ NEET & $\\Delta$ Youth Emp.~Rate & $\\Delta$ Early School Leaving \\\\\n",
  "\\midrule\n",
  "YEI eligible ($\\geq 25\\%$) & ",
  sprintf("%s & %s & %s \\\\\n",
    fmt_coef(b_neet, p_neet),
    fmt_coef(b_emp, p_emp),
    if (!is.na(b_esl)) fmt_coef(b_esl, p_esl) else "--"
  ),
  " & ", fmt_se(se_neet), " & ", fmt_se(se_emp), " & ",
  if (!is.na(se_esl)) fmt_se(se_esl) else "--", " \\\\\n",
  "\\midrule\n",
  "Outcome period & \\multicolumn{3}{c}{Change: avg(2016--2019) $-$ avg(2010--2012)} \\\\\n",
  "Kernel & \\multicolumn{3}{c}{Triangular} \\\\\n",
  "Bandwidth selector & \\multicolumn{3}{c}{MSE-optimal (rdrobust)} \\\\\n",
  sprintf("Bandwidth (pp) & %.2f & %.2f & %s \\\\\n",
          bw_neet, bw_emp, fmt_bw(bw_esl)),
  sprintf("Observations & %d & %d & %s \\\\\n",
          n_neet, n_emp,
          if (!is.na(n_esl)) as.character(n_esl) else "--"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\raggedright\\footnotesize\n",
  "Notes: Each column reports a local polynomial RDD estimate using \\texttt{rdrobust} (Calonico, Cattaneo, and Titiunik, 2014). The running variable is the 2012 youth unemployment rate (ages 15--24) centered at the 25\\% YEI eligibility threshold. Outcomes are changes from the pre-YEI average (2010--2012) to the post-YEI average (2016--2019). Standard errors clustered at the country level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_rdd_main.tex")
cat("Table 2 saved.\n")

# ============================================================
# TABLE 3: OLS POLYNOMIAL COMPARISON
# ============================================================

cat("Generating Table 3: OLS polynomial specifications...\n")

c_lin  <- ols_coef(ols_lin,  "treated")
c_quad <- ols_coef(ols_quad, "treated")
c_bw   <- ols_coef(ols_bw,   "treated")
c_emp  <- ols_coef(ols_emp,  "treated")

n_lin  <- nobs(ols_lin)
n_quad <- nobs(ols_quad)
n_bw   <- nobs(ols_bw)
n_emp_ols <- nobs(ols_emp)

tab3 <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{OLS Polynomial Specifications}\n",
  "\\label{tab:ols}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & $\\Delta$ NEET & $\\Delta$ NEET & $\\Delta$ NEET & $\\Delta$ Emp.~Rate \\\\\n",
  " & Linear & Quadratic & Linear, BW & Linear \\\\\n",
  "\\midrule\n",
  "YEI eligible ($\\geq 25\\%$) & ",
  sprintf("%s & %s & %s & %s \\\\\n",
    fmt_coef(c_lin["b"], c_lin["p"]),
    fmt_coef(c_quad["b"], c_quad["p"]),
    fmt_coef(c_bw["b"], c_bw["p"]),
    fmt_coef(c_emp["b"], c_emp["p"])
  ),
  " & ", fmt_se(c_lin["se"]), " & ", fmt_se(c_quad["se"]),
  " & ", fmt_se(c_bw["se"]), " & ", fmt_se(c_emp["se"]), " \\\\\n",
  "\\midrule\n",
  "Polynomial in RV & Linear & Quadratic & Linear & Linear \\\\\n",
  "Interactions (RV$\\times$Treat) & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Bandwidth & Full & Full & %.1f pp & Full \\\\\n", bw_main),
  sprintf("Observations & %d & %d & %d & %d \\\\\n",
          n_lin, n_quad, n_bw, n_emp_ols),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\raggedright\\footnotesize\n",
  "Notes: OLS estimates of the RDD treatment effect using a polynomial control function in the running variable (2012 youth unemployment rate centered at 25\\%). All specifications include an interaction between the polynomial and the treatment dummy. Column (3) restricts to observations within the MSE-optimal bandwidth from the main RDD. Standard errors clustered at the country level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_ols.tex")
cat("Table 3 saved.\n")

# ============================================================
# TABLE 4: ROBUSTNESS — BANDWIDTH, PLACEBO, McCRARY, DONUT
# ============================================================

cat("Generating Table 4: Robustness checks...\n")

bw_df  <- robustness$bw_results
plac   <- robustness$placebo
donut  <- robustness$donut
unif   <- robustness$uniform
mcc_t  <- robustness$mccrary_tstat
mcc_p  <- robustness$mccrary_pval

# Panel A: Bandwidth sensitivity
make_bw_row <- function(row) {
  if (is.null(row) || is.na(row$coef)) {
    sprintf("%s & -- & -- & -- \\\\\n", row$spec)
  } else {
    sprintf("%s & %s & %s & %d \\\\\n",
            row$spec,
            fmt_coef(row$coef, row$pval),
            fmt_se(row$se),
            as.integer(row$n))
  }
}

bw_rows <- ""
for (i in 1:nrow(bw_df)) {
  bw_rows <- paste0(bw_rows, make_bw_row(bw_df[i,]))
}

# Main estimate for reference
main_coef <- b_neet; main_se <- se_neet; main_pval <- p_neet
main_n    <- n_neet

mcc_str <- if (!is.na(mcc_t) && !is.na(mcc_p)) {
  sprintf("$T = %.3f$ ($p = %.3f$)", mcc_t, mcc_p)
} else {
  "Not computed"
}

tab4 <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Main RDD Estimate (Outcome: $\\Delta$ NEET Rate)}\n",
  "\\label{tab:robustness}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Main estimate and bandwidth sensitivity}} \\\\\n",
  sprintf("Main (triangular, MSE-optimal BW = %.1f pp) & %s & %s & %d \\\\\n",
          bw_main, fmt_coef(main_coef, main_pval), fmt_se(main_se), main_n),
  bw_rows,
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative specifications}} \\\\\n",
  sprintf("Uniform kernel & %s & %s & %d \\\\\n",
          if (!is.na(unif$coef)) fmt_coef(unif$coef, unif$pval) else "--",
          if (!is.na(unif$se))   fmt_se(unif$se) else "--",
          if (!is.na(unif$n))    as.integer(unif$n) else 0),
  sprintf("Donut RDD ($|$rv$| > 1$ pp) & %s & %s & %d \\\\\n",
          if (!is.na(donut$coef)) fmt_coef(donut$coef, donut$pval) else "--",
          if (!is.na(donut$se))   fmt_se(donut$se) else "--",
          if (!is.na(donut$n))    as.integer(donut$n) else 0),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo cutoffs (should show no discontinuity)}} \\\\\n",
  sprintf("Placebo cutoff at 20\\%% (below-threshold sample) & %s & %s & %s \\\\\n",
          if (!is.na(plac$coef[1])) fmt_coef(plac$coef[1], plac$pval[1]) else "--",
          if (!is.na(plac$se[1]))   fmt_se(plac$se[1]) else "--",
          if (!is.na(plac$n[1]))    as.character(as.integer(plac$n[1])) else "--"),
  sprintf("Placebo cutoff at 30\\%% (above-threshold sample) & %s & %s & %s \\\\\n",
          if (!is.na(plac$coef[2])) fmt_coef(plac$coef[2], plac$pval[2]) else "--",
          if (!is.na(plac$se[2]))   fmt_se(plac$se[2]) else "--",
          if (!is.na(plac$n[2]))    as.character(as.integer(plac$n[2])) else "--"),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel D: McCrary density test for manipulation at threshold}} \\\\\n",
  sprintf("\\multicolumn{4}{l}{\\quad %s} \\\\\n", mcc_str),
  "\\multicolumn{4}{l}{\\quad (Null hypothesis: no density discontinuity; large $p$ supports identification)} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\raggedright\\footnotesize\n",
  "Notes: All estimates for the $\\Delta$ NEET rate outcome. Running variable is the 2012 youth unemployment rate centered at 25\\%. Panel A varies the estimation bandwidth; the main MSE-optimal bandwidth is computed by \\texttt{rdrobust}. Panel B uses a uniform kernel and a donut design excluding regions within 1 pp of the threshold. Panel C tests for spurious discontinuities at alternative cutoffs. Panel D reports the Cattaneo-Jansson-Ma (2020) density test; failure to reject supports the absence of manipulation. Standard errors clustered at the country level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robustness.tex")
cat("Table 4 saved.\n")

# ============================================================
# TABLE 5: HETEROGENEITY — SOUTHERN vs NON-SOUTHERN EUROPE
# ============================================================

cat("Generating Table 5: Heterogeneity by Southern Europe...\n")

df_south     <- df %>% filter(southern == 1)
df_nonsouth  <- df %>% filter(southern == 0)

cat(sprintf("Southern Europe: %d regions\n", nrow(df_south)))
cat(sprintf("Non-Southern Europe: %d regions\n", nrow(df_nonsouth)))

# RDD separately for each subsample
rdd_south <- tryCatch({
  rdrobust::rdrobust(
    y = df_south$d_neet, x = df_south$rv, c = 0,
    kernel = "triangular", bwselect = "mserd",
    cluster = df_south$country
  )
}, error = function(e) {
  cat(sprintf("WARNING: RDD for Southern Europe failed: %s\n", e$message))
  NULL
})

rdd_nonsouth <- tryCatch({
  rdrobust::rdrobust(
    y = df_nonsouth$d_neet, x = df_nonsouth$rv, c = 0,
    kernel = "triangular", bwselect = "mserd",
    cluster = df_nonsouth$country
  )
}, error = function(e) {
  cat(sprintf("WARNING: RDD for Non-Southern Europe failed: %s\n", e$message))
  NULL
})

# OLS for hetero: interaction with southern dummy (full sample)
ols_hetero <- tryCatch({
  feols(
    d_neet ~ treated * southern + rv + I(rv * treated),
    data = df,
    cluster = ~country
  )
}, error = function(e) NULL)

fmt_rdd <- function(obj, label) {
  if (is.null(obj)) return(list(spec=label, b="--", se="--", bw="--", n="--"))
  list(
    spec = label,
    b    = fmt_coef(rdd_coef(obj), rdd_pval(obj)),
    se   = fmt_se(rdd_se(obj)),
    bw   = sprintf("%.2f", rdd_bw(obj)),
    n    = as.character(rdd_n(obj))
  )
}

row_s  <- fmt_rdd(rdd_south,    "Southern Europe (IT, ES, EL, PT)")
row_ns <- fmt_rdd(rdd_nonsouth, "Non-Southern Europe (other EU-27)")

# Interaction coefficient
het_row <- if (!is.null(ols_hetero)) {
  ct <- coeftable(ols_hetero)
  if ("treated:southern" %in% rownames(ct)) {
    c(b=ct["treated:southern","Estimate"],
      se=ct["treated:southern","Std. Error"],
      p=ct["treated:southern","Pr(>|t|)"])
  } else {
    c(b=NA, se=NA, p=NA)
  }
} else {
  c(b=NA, se=NA, p=NA)
}

tab5 <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Heterogeneous Effects: Southern vs.~Non-Southern Europe}\n",
  "\\label{tab:hetero}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Estimate & SE & BW (pp) & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Separate RDD by subsample (outcome: $\\Delta$ NEET rate)}} \\\\\n",
  sprintf("%s & %s & %s & %s & %s \\\\\n",
          row_s$spec, row_s$b, row_s$se, row_s$bw, row_s$n),
  sprintf("%s & %s & %s & %s & %s \\\\\n",
          row_ns$spec, row_ns$b, row_ns$se, row_ns$bw, row_ns$n),
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: OLS interaction test (full sample)}} \\\\\n",
  sprintf("YEI eligible $\\times$ Southern & %s & %s & Full & %d \\\\\n",
          if (!is.na(het_row["b"])) fmt_coef(het_row["b"], het_row["p"]) else "--",
          if (!is.na(het_row["se"])) fmt_se(het_row["se"]) else "--",
          nrow(df)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\raggedright\\footnotesize\n",
  "Notes: Southern Europe defined as Italy (IT), Spain (ES), Greece (EL), and Portugal (PT) --- the four countries with the highest youth unemployment rates in 2012 and that received the largest YEI allocations. Panel A estimates separate local polynomial RDDs for each subsample. Panel B estimates an OLS specification with a treatment$\\times$southern interaction and a linear polynomial in the running variable. Standard errors clustered at the country level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{table}\n"
)

writeLines(tab5, "../tables/tab5_heterogeneity.tex")
cat("Table 5 saved.\n")

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE) APPENDIX
# ============================================================

cat("Generating Table F1: Standardized effect sizes...\n")

# Pre-treatment SD of outcome for each variable
sd_neet <- df %>%
  filter(!is.na(neet_pre)) %>%
  summarise(s = sd(neet_pre, na.rm=TRUE)) %>%
  pull(s)

sd_emp <- df %>%
  filter(!is.na(emp_pre)) %>%
  summarise(s = sd(emp_pre, na.rm=TRUE)) %>%
  pull(s)

sd_esl <- df %>%
  filter(!is.na(esl_pre)) %>%
  summarise(s = sd(esl_pre, na.rm=TRUE)) %>%
  pull(s)

# Compute SDEs
sde_neet <- b_neet / sd_neet
se_sde_neet <- se_neet / sd_neet

sde_emp  <- b_emp  / sd_emp
se_sde_emp  <- se_emp  / sd_emp

sde_esl  <- if (!is.na(b_esl)) b_esl / sd_esl else NA
se_sde_esl  <- if (!is.na(se_esl)) se_esl / sd_esl else NA

classify_sde <- function(sde) {
  if (is.na(sde)) return("--")
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_notes_text <- paste0(
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Does the Youth Employment Initiative (YEI) --- allocated to NUTS2 regions with 2012 youth unemployment at or above 25\\% --- reduce the NEET rate and raise youth employment? ",
  "\\textbf{Policy mechanism:} The YEI provided €6.4 billion (2014--2020) to co-finance apprenticeships, traineeships, job placements, and education re-entry for young people not in employment, education, or training (NEET). Regions above the 25\\% threshold received funding automatically; regions below did not, creating a sharp discontinuity. ",
  "\\textbf{Outcome definition:} NEET rate = share of 18--24 year olds neither employed nor in education/training (Eurostat \\texttt{edat\\_lfse\\_22}); youth employment rate = share of 15--24 year olds employed (\\texttt{lfst\\_r\\_lfe2emprt}); early school leaving = share of 18--24 year olds with at most lower secondary education not in training (\\texttt{edat\\_lfse\\_16}). Outcomes measured as changes from pre-YEI baseline (2010--2012 average) to post-YEI period (2016--2019 average). ",
  "\\textbf{Treatment:} Binary --- NUTS2 region with 2012 youth unemployment $\\geq 25\\%$ (YEI-eligible) vs.~$< 25\\%$ (ineligible). Running variable centered at zero. ",
  "\\textbf{Data:} Eurostat regional statistics, NUTS2 level, EU-27 member states. Pre-treatment period: 2010--2012. ",
  "\\textbf{Method:} Local polynomial RDD (\\texttt{rdrobust}), triangular kernel, MSE-optimal bandwidth, standard errors clustered at country level. ",
  "\\textbf{Sample:} All EU-27 NUTS2 regions with non-missing 2012 youth unemployment and post-2016 NEET data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y_{\\text{pre}})$ where SD$(Y_{\\text{pre}})$ is the cross-regional standard deviation of the pre-YEI baseline outcome level. Classification refers to magnitude only, not statistical significance: ",
  "Large ($|\\text{SDE}| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[h!]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Size (SDE) Appendix}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD$(Y_{\\text{pre}})$ & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sprintf("$\\Delta$ NEET rate & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          b_neet, se_neet, sd_neet, sde_neet, se_sde_neet, classify_sde(sde_neet)),
  sprintf("$\\Delta$ Youth employment rate & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          b_emp, se_emp, sd_emp, sde_emp, se_sde_emp, classify_sde(sde_emp)),
  sprintf("$\\Delta$ Early school leaving & %s & %s & %.3f & %s & %s & %s \\\\\n",
          if (!is.na(b_esl)) sprintf("%.3f", b_esl) else "--",
          if (!is.na(se_esl)) sprintf("%.3f", se_esl) else "--",
          sd_esl,
          if (!is.na(sde_esl)) sprintf("%.3f", sde_esl) else "--",
          if (!is.na(se_sde_esl)) sprintf("%.3f", se_sde_esl) else "--",
          classify_sde(sde_esl)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\parbox{\\textwidth}{\\raggedright\\footnotesize\n",
  sde_notes_text,
  "}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 saved.\n")

# ============================================================
# PRINT SUMMARY
# ============================================================

cat("\n=== TABLE GENERATION COMPLETE ===\n")
cat("tab1_summary.tex     — Summary statistics by eligibility status\n")
cat("tab2_rdd_main.tex    — Main RDD results (3 outcomes)\n")
cat("tab3_ols.tex         — OLS polynomial comparison\n")
cat("tab4_robustness.tex  — Bandwidth sensitivity + placebo + McCrary + donut\n")
cat("tab5_heterogeneity.tex — Southern vs non-Southern Europe\n")
cat("tabF1_sde.tex        — Standardized effect size appendix\n")

cat(sprintf("\nKey result: RDD estimate for NEET rate = %.3f%s (SE = %.3f)\n",
            b_neet, stars(p_neet), se_neet))
cat(sprintf("Interpretation: YEI-eligible regions experienced a %.2f pp %s in the NEET rate\n",
            abs(b_neet), if (b_neet < 0) "decrease" else "increase"))
