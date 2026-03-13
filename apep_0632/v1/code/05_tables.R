## 05_tables.R — Generate all tables for paper
## apep_0632: ZFE Low-Emission Zones and Populist Voting in France

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

## Active metros
active_metros <- unique(panel[metro_active_2022 == TRUE, nearest_metro_siren])
main <- panel[nearest_metro_siren %in% active_metros]

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

## Two panels: inside ZFE vs outside, within 10km
s10 <- main[dist_to_boundary_m <= 10000]
s10_in <- s10[inside_zfe == TRUE]
s10_out <- s10[inside_zfe == FALSE]

make_row <- function(var, label, dt_in, dt_out, mult = 1) {
  sprintf("  %s & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          label,
          mult * mean(dt_in[[var]], na.rm = TRUE),
          mult * sd(dt_in[[var]], na.rm = TRUE),
          mult * mean(dt_out[[var]], na.rm = TRUE),
          mult * sd(dt_out[[var]], na.rm = TRUE),
          mult * mean(c(dt_in[[var]], dt_out[[var]]), na.rm = TRUE),
          mult * sd(c(dt_in[[var]], dt_out[[var]]), na.rm = TRUE))
}

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Communes Within 10 km of ZFE Boundary}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Inside ZFE} & \\multicolumn{2}{c}{Outside ZFE} & \\multicolumn{2}{c}{Full Sample} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Election Outcomes (proportion)}} \\\\[3pt]",
  make_row("rn_share_2012", "FN vote share, 2012", s10_in, s10_out),
  make_row("rn_share_2017", "FN vote share, 2017", s10_in, s10_out),
  make_row("rn_share_2022", "RN vote share, 2022", s10_in, s10_out),
  make_row("farright_share_2022", "Far-right total, 2022", s10_in, s10_out),
  make_row("turnout_2017", "Turnout, 2017", s10_in, s10_out),
  make_row("turnout_2022", "Turnout, 2022", s10_in, s10_out),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Changes (percentage points)}} \\\\[3pt]",
  make_row("delta_rn_1217", "$\\Delta$FN 2012--2017", s10_in, s10_out),
  make_row("delta_rn_1722", "$\\Delta$RN 2017--2022", s10_in, s10_out),
  make_row("delta_farright_1722", "$\\Delta$Far-right 2017--2022", s10_in, s10_out),
  make_row("delta_turnout_1722", "$\\Delta$Turnout 2017--2022", s10_in, s10_out),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel C: Geography}} \\\\[3pt]",
  sprintf("  Distance to boundary (km) & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(s10_in$dist_to_boundary_m) / 1000, sd(s10_in$dist_to_boundary_m) / 1000,
          mean(s10_out$dist_to_boundary_m) / 1000, sd(s10_out$dist_to_boundary_m) / 1000,
          mean(s10$dist_to_boundary_m) / 1000, sd(s10$dist_to_boundary_m) / 1000),
  sprintf("  Population & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\",
          mean(s10_in$population, na.rm = TRUE), sd(s10_in$population, na.rm = TRUE),
          mean(s10_out$population, na.rm = TRUE), sd(s10_out$population, na.rm = TRUE),
          mean(s10$population, na.rm = TRUE), sd(s10$population, na.rm = TRUE)),
  "\\midrule",
  sprintf("  Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(s10_in), nrow(s10_out), nrow(s10)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Sample restricted to communes within 10 km of a ZFE boundary in one of the %d metropolitan areas with active ZFEs before the April 2022 presidential election. FN/RN vote shares refer to Front National (2012) or Rassemblement National (2017, 2022) first-round presidential results. Far-right total adds Zemmour votes in 2022. All vote shares are proportions of expressed votes.", length(active_metros)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

## ============================================================
## Table 2: Main Results — Bandwidth Sensitivity
## ============================================================
cat("\n=== Table 2: Main Results ===\n")

make_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

## Main table: RN share change across bandwidths
rn_rows <- rob[outcome == "delta_rn_1722"]
fr_rows <- rob[outcome == "delta_farright_1722"]
to_rows <- rob[outcome == "delta_turnout_1722"]
placebo_rows <- rob[outcome == "delta_rn_1217"]

bws <- c(3, 5, 7, 10, 15, 20)

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Main Results: Effect of ZFE on Voting Outcomes}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  paste0(" & ", paste(sprintf("(%d)", 1:6), collapse = " & "), " \\\\"),
  paste0("Bandwidth (km) & ", paste(bws, collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: $\\Delta$RN Vote Share, 2017--2022}} \\\\[3pt]"
)

## RN share row
vals <- sapply(bws, function(b) {
  r <- rn_rows[bw_km == b]
  if (nrow(r) == 0) return(c("", "", ""))
  c(sprintf("%.4f%s", r$estimate, make_stars(r$pval)),
    sprintf("(%.4f)", r$se),
    as.character(r$n))
})
tab2 <- c(tab2,
  paste0("  Inside ZFE & ", paste(vals[1, ], collapse = " & "), " \\\\"),
  paste0("   & ", paste(vals[2, ], collapse = " & "), " \\\\[6pt]"),
  "\\multicolumn{7}{l}{\\textit{Panel B: $\\Delta$Far-Right Total, 2017--2022}} \\\\[3pt]"
)

## Far-right row
vals_fr <- sapply(bws, function(b) {
  r <- fr_rows[bw_km == b]
  if (nrow(r) == 0) return(c("", "", ""))
  c(sprintf("%.4f%s", r$estimate, make_stars(r$pval)),
    sprintf("(%.4f)", r$se),
    as.character(r$n))
})
tab2 <- c(tab2,
  paste0("  Inside ZFE & ", paste(vals_fr[1, ], collapse = " & "), " \\\\"),
  paste0("   & ", paste(vals_fr[2, ], collapse = " & "), " \\\\[6pt]"),
  "\\multicolumn{7}{l}{\\textit{Panel C: $\\Delta$Turnout, 2017--2022}} \\\\[3pt]"
)

## Turnout row
vals_to <- sapply(bws, function(b) {
  r <- to_rows[bw_km == b]
  if (nrow(r) == 0) return(c("", "", ""))
  c(sprintf("%.4f%s", r$estimate, make_stars(r$pval)),
    sprintf("(%.4f)", r$se),
    as.character(r$n))
})
tab2 <- c(tab2,
  paste0("  Inside ZFE & ", paste(vals_to[1, ], collapse = " & "), " \\\\"),
  paste0("   & ", paste(vals_to[2, ], collapse = " & "), " \\\\[6pt]"),
  "\\multicolumn{7}{l}{\\textit{Panel D: Placebo -- $\\Delta$FN Vote Share, 2012--2017}} \\\\[3pt]"
)

## Placebo row
vals_pl <- sapply(bws, function(b) {
  r <- placebo_rows[bw_km == b]
  if (nrow(r) == 0) return(c("", "", ""))
  c(sprintf("%.4f%s", r$estimate, make_stars(r$pval)),
    sprintf("(%.4f)", r$se),
    as.character(r$n))
})
tab2 <- c(tab2,
  paste0("  Inside ZFE & ", paste(vals_pl[1, ], collapse = " & "), " \\\\"),
  paste0("   & ", paste(vals_pl[2, ], collapse = " & "), " \\\\"),
  "\\midrule",
  paste0("  Observations & ", paste(sapply(bws, function(b) {
    r <- rn_rows[bw_km == b]; if (nrow(r) > 0) r$n else ""
  }), collapse = " & "), " \\\\"),
  paste0("  Communes inside & ", paste(sapply(bws, function(b) {
    r <- rn_rows[bw_km == b]; if (nrow(r) > 0) r$n_inside else ""
  }), collapse = " & "), " \\\\"),
  "  Metro FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "  Kernel & Tri. & Tri. & Tri. & Tri. & Tri. & Tri. \\\\",
  "  Polynomial & Linear & Linear & Linear & Linear & Linear & Linear \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports the coefficient on the Inside ZFE indicator from a local linear regression of the outcome on Inside ZFE, signed distance to ZFE boundary (km), and their interaction, with metropolitan area fixed effects and triangular kernel weights. Heteroskedasticity-robust standard errors in parentheses. $\\Delta$RN is the change in Rassemblement National (formerly Front National) first-round presidential vote share. Far-right total adds Zemmour votes in 2022. Panel D reports a placebo test using the 2012--2017 change, before any ZFE existed. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

## ============================================================
## Table 3: Specification Sensitivity
## ============================================================
cat("\n=== Table 3: Specification Sensitivity ===\n")

## Run specifications at 10km bandwidth
bw <- 10
sub <- main[dist_to_boundary_m <= bw * 1000]
sub[, w := (1 - dist_to_boundary_m / (bw * 1000))]
sub[, signed_dist_km2 := signed_dist_km^2]

## Donut
sub_donut <- main[dist_to_boundary_m >= 500 & dist_to_boundary_m <= bw * 1000]
sub_donut[, w := (1 - dist_to_boundary_m / (bw * 1000))]

## List of specifications
specs <- list(
  list(name = "Baseline (linear, tri.)", formula = delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren, data = sub, wt = TRUE),
  list(name = "Uniform kernel", formula = delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren, data = sub, wt = FALSE),
  list(name = "Quadratic", formula = delta_rn_1722 ~ inside_zfe * (signed_dist_km + signed_dist_km2) | nearest_metro_siren, data = sub, wt = TRUE),
  list(name = "Donut ($>$500m)", formula = delta_rn_1722 ~ inside_zfe * signed_dist_km | nearest_metro_siren, data = sub_donut, wt = TRUE),
  list(name = "No metro FE", formula = delta_rn_1722 ~ inside_zfe * signed_dist_km, data = sub, wt = TRUE)
)

fits <- list()
for (i in seq_along(specs)) {
  s <- specs[[i]]
  if (s$wt) {
    fits[[i]] <- feols(s$formula, data = s$data, weights = ~w, se = "hetero")
  } else {
    fits[[i]] <- feols(s$formula, data = s$data, se = "hetero")
  }
}

tab3_rows <- sapply(seq_along(fits), function(i) {
  fit <- fits[[i]]
  tau <- coef(fit)["inside_zfeTRUE"]
  se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
  p <- 2 * pnorm(-abs(tau / se))
  sprintf("  %s & %.4f%s & (%.4f) & %d \\\\",
          specs[[i]]$name, tau, make_stars(p), se, nobs(fit))
})

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Specification Sensitivity: $\\Delta$RN Vote Share at 10 km Bandwidth}",
  "\\label{tab:specs}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Inside ZFE & SE & N \\\\",
  "\\midrule",
  tab3_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications estimate the discontinuity in $\\Delta$RN (2017--2022 change in RN first-round presidential vote share) at the ZFE boundary using a 10 km bandwidth. Heteroskedasticity-robust standard errors. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, file.path(tables_dir, "tab3_specs.tex"))
cat("  Written tab3_specs.tex\n")

## ============================================================
## Table 4: Covariate Balance
## ============================================================
cat("\n=== Table 4: Covariate Balance ===\n")

covariates <- list(
  c("rn_share_2012", "FN vote share, 2012"),
  c("rn_share_2017", "FN vote share, 2017"),
  c("turnout_2017", "Turnout, 2017"),
  c("population", "Population (log)")
)

bal_rows <- sapply(covariates, function(cv) {
  var <- cv[1]
  label <- cv[2]
  sub_bal <- main[!is.na(get(var))]
  if (var == "population") {
    sub_bal[, pop_log := log(population + 1)]
    rd <- tryCatch(rdrobust(sub_bal$pop_log, sub_bal$signed_dist_km, c = 0), error = function(e) NULL)
  } else {
    rd <- tryCatch(rdrobust(sub_bal[[var]], sub_bal$signed_dist_km, c = 0), error = function(e) NULL)
  }
  if (!is.null(rd)) {
    sprintf("  %s & %.4f%s & (%.4f) & %.3f & %.1f & %d \\\\",
            label, rd$coef[1], make_stars(rd$pv[1]), rd$se[1], rd$pv[1],
            rd$bws[1], rd$N_h[1] + rd$N_h[2])
  } else {
    sprintf("  %s & --- & --- & --- & --- & --- \\\\", label)
  }
})

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Covariate Balance at ZFE Boundary}",
  "\\label{tab:balance}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Estimate & SE & $p$-value & BW (km) & Eff.~$N$ \\\\",
  "\\midrule",
  bal_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the \\texttt{rdrobust} estimate of the discontinuity in a pre-determined covariate at the ZFE boundary. Data-driven MSE-optimal bandwidth with triangular kernel. Nearest-neighbor standard errors. Population is log-transformed.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, file.path(tables_dir, "tab4_balance.tex"))
cat("  Written tab4_balance.tex\n")

## ============================================================
## Table F1: Standardized Effect Sizes
## ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

## Main specification: 5km bandwidth, triangular kernel, metro FE
bw_main <- 5
sub_sde <- main[dist_to_boundary_m <= bw_main * 1000]
sub_sde[, w := (1 - dist_to_boundary_m / (bw_main * 1000))]

outcomes_sde <- list(
  list(var = "delta_rn_1722", label = "$\\Delta$RN share 2017--2022"),
  list(var = "delta_farright_1722", label = "$\\Delta$Far-right 2017--2022"),
  list(var = "delta_turnout_1722", label = "$\\Delta$Turnout 2017--2022")
)

classify <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- sapply(outcomes_sde, function(o) {
  fit <- feols(as.formula(paste(o$var, "~ inside_zfe * signed_dist_km | nearest_metro_siren")),
               data = sub_sde, weights = ~w, se = "hetero")
  beta <- coef(fit)["inside_zfeTRUE"]
  se <- sqrt(vcov(fit)["inside_zfeTRUE", "inside_zfeTRUE"])
  sd_y <- sd(sub_sde[[o$var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se / sd_y
  sprintf("  %s & %.4f & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\",
          o$label, beta, se, sd_y, sde, se_sde, classify(sde))
})

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sde_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison. SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. SD($Y$) is the unconditional standard deviation of the outcome. \\textbf{Research question:} Does ZFE implementation affect RN voting and turnout in nearby communes? \\textbf{Treatment:} Binary (inside vs.\\ outside ZFE boundary). \\textbf{Data:} French presidential election results (2017, 2022) matched to ZFE boundary distances for %d communes within 5 km of a ZFE boundary. \\textbf{Method:} Local linear diff-in-disc with metro FE, triangular kernel, 5 km bandwidth. \\textbf{Sample:} Communes near %d metropolitan ZFE areas active before April 2022.", nrow(sub_sde), length(active_metros)),
  "",
  "Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$).",
  "",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}"
)
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
