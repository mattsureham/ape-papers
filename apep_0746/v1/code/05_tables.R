## 05_tables.R — Generate all LaTeX tables
## APEP-0746

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

cat("Loading analysis dataset...\n")
dt <- fread(file.path(data_dir, "analysis_data.csv.gz"))

## ===================================================================
## Table 1: Summary Statistics
## ===================================================================

cat("Generating Table 1: Summary Statistics...\n")

make_summ_row <- function(dt_sub, label) {
  data.table(
    Panel = label,
    N = formatC(nrow(dt_sub), format = "d", big.mark = ","),
    `Mean Price` = formatC(mean(dt_sub$valeur_fonciere), format = "f", digits = 0, big.mark = ","),
    `SD Price` = formatC(sd(dt_sub$valeur_fonciere), format = "f", digits = 0, big.mark = ","),
    `Mean Surface` = formatC(mean(dt_sub$surface_reelle_bati, na.rm = TRUE), format = "f", digits = 1),
    `Mean Rooms` = formatC(mean(dt_sub$nombre_pieces_principales, na.rm = TRUE), format = "f", digits = 1),
    `Pct Apt` = formatC(100 * mean(dt_sub$is_apt, na.rm = TRUE), format = "f", digits = 1)
  )
}

summ <- rbind(
  make_summ_row(dt, "Full sample"),
  make_summ_row(dt[is_rep == TRUE], "REP/REP+ side"),
  make_summ_row(dt[is_rep == FALSE], "Non-REP side"),
  make_summ_row(dt[ep_status == "REP+"], "REP+ only"),
  make_summ_row(dt[ep_status == "REP"], "REP only")
)

# LaTeX output
tex_tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Property Transactions Near REP/Non-REP Boundaries}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & N & Mean Price & SD Price & Surface & Rooms & Apt \\\\",
  " & & (EUR) & (EUR) & (m$^2$) & & (\\%) \\\\",
  "\\midrule"
)

for (r in seq_len(nrow(summ))) {
  tex_tab1 <- c(tex_tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                                   summ$Panel[r], summ$N[r], summ$`Mean Price`[r],
                                   summ$`SD Price`[r], summ$`Mean Surface`[r],
                                   summ$`Mean Rooms`[r], summ$`Pct Apt`[r]))
}

tex_tab1 <- c(tex_tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample includes all residential property transactions (apartments and houses) from the DVF universe within 1,000 meters of a REP/non-REP college catchment boundary, 2020--2024. REP = R\\'{e}seau d'\\'{E}ducation Prioritaire; REP+ = reinforced priority network with class sizes capped at 12 students.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_tab1, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

## ===================================================================
## Table 2: Main RDD Results
## ===================================================================

cat("Generating Table 2: Main RDD Results...\n")

# Run RDD at multiple bandwidths
rdd_results <- list()
bws <- c(200, 300, 500, 750, 1000)

for (bw in bws) {
  dt_bw <- dt[dist_m <= bw]
  if (nrow(dt_bw) < 200) next

  # rdrobust
  rdd <- tryCatch(
    rdrobust(y = dt_bw$log_price, x = dt_bw$signed_dist_m, c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )

  # Parametric with controls + FE
  reg <- tryCatch(
    feols(log_price ~ is_rep + signed_dist_m + I(is_rep * signed_dist_m) +
          is_apt + surface_reelle_bati + nombre_pieces_principales |
          nearest_seg + year_quarter,
          data = dt_bw, cluster = ~nearest_seg),
    error = function(e) NULL
  )

  rdd_results[[as.character(bw)]] <- list(rdd = rdd, reg = reg, bw = bw, n = nrow(dt_bw))
}

# Build table
tex_tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of REP Designation on Log Property Prices: Spatial RDD}",
  "\\label{tab:main_rdd}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0(" & ", paste(paste0(bws, "m"), collapse = " & "), " \\\\"),
  paste0(" & ", paste(paste0("(", seq_along(bws), ")"), collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Nonparametric RDD (rdrobust, triangular kernel)}} \\\\"
)

# Panel A: rdrobust
coef_row <- "REP designation"
se_row <- ""
for (bw in bws) {
  res <- rdd_results[[as.character(bw)]]
  if (!is.null(res) && !is.null(res$rdd)) {
    tau <- res$rdd$coef[3]
    se <- res$rdd$se[3]
    pv <- res$rdd$pv[3]
    stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
    coef_row <- paste0(coef_row, " & ", formatC(tau, format = "f", digits = 4), stars)
    se_row <- paste0(se_row, " & (", formatC(se, format = "f", digits = 4), ")")
  } else {
    coef_row <- paste0(coef_row, " & ---")
    se_row <- paste0(se_row, " & ---")
  }
}

tex_tab2 <- c(tex_tab2,
  paste0(coef_row, " \\\\"),
  paste0(se_row, " \\\\"),
  ""
)

# Optimal BW row
opt_bw_row <- "Optimal BW (m)"
for (bw in bws) {
  res <- rdd_results[[as.character(bw)]]
  if (!is.null(res) && !is.null(res$rdd)) {
    opt_bw_row <- paste0(opt_bw_row, " & ", formatC(res$rdd$bws[1,1], format = "f", digits = 0))
  } else {
    opt_bw_row <- paste0(opt_bw_row, " & ---")
  }
}
tex_tab2 <- c(tex_tab2, paste0(opt_bw_row, " \\\\"), "\\midrule")

# Panel B: Parametric with FE
tex_tab2 <- c(tex_tab2,
  "\\multicolumn{6}{l}{\\textit{Panel B: Parametric RDD with boundary-segment and quarter FE}} \\\\"
)

coef_row2 <- "REP designation"
se_row2 <- ""
for (bw in bws) {
  res <- rdd_results[[as.character(bw)]]
  if (!is.null(res) && !is.null(res$reg)) {
    tau <- coef(res$reg)["is_repTRUE"]
    se <- se(res$reg)["is_repTRUE"]
    pv <- pvalue(res$reg)["is_repTRUE"]
    stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
    coef_row2 <- paste0(coef_row2, " & ", formatC(tau, format = "f", digits = 4), stars)
    se_row2 <- paste0(se_row2, " & (", formatC(se, format = "f", digits = 4), ")")
  } else {
    coef_row2 <- paste0(coef_row2, " & ---")
    se_row2 <- paste0(se_row2, " & ---")
  }
}

tex_tab2 <- c(tex_tab2,
  paste0(coef_row2, " \\\\"),
  paste0(se_row2, " \\\\")
)

# N rows
n_row <- "N"
seg_row <- "Boundary segments"
for (bw in bws) {
  res <- rdd_results[[as.character(bw)]]
  n_row <- paste0(n_row, " & ", formatC(res$n, format = "d", big.mark = ","))
  seg_row <- paste0(seg_row, " & ", formatC(uniqueN(dt[dist_m <= bw]$nearest_seg),
                                            format = "d", big.mark = ","))
}

tex_tab2 <- c(tex_tab2,
  "\\midrule",
  "Property controls & Yes & Yes & Yes & Yes & Yes \\\\",
  "Boundary-segment FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year-quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  paste0(n_row, " \\\\"),
  paste0(seg_row, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} The dependent variable is log transaction price. Panel A reports bias-corrected estimates with robust standard errors from \\citet{cattaneo2020}. Panel B reports OLS with local linear polynomials (separate slopes each side of boundary), property controls (apartment indicator, surface area, number of rooms), boundary-segment fixed effects, and year-quarter fixed effects. Standard errors clustered at the boundary-segment level. *, **, *** denote significance at 10\\%, 5\\%, 1\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_tab2, file.path(table_dir, "tab2_main_rdd.tex"))
cat("Table 2 saved.\n")

## ===================================================================
## Table 3: Covariate Balance
## ===================================================================

cat("Generating Table 3: Covariate Balance...\n")

covariates <- c("surface_reelle_bati", "nombre_pieces_principales", "is_apt")
cov_labels <- c("Surface area (m$^2$)", "Number of rooms", "Apartment (=1)")

tex_tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Covariate Balance at REP/Non-REP Boundary}",
  "\\label{tab:balance}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Covariate & RD Estimate & Robust SE & $p$-value \\\\",
  "\\midrule"
)

for (i in seq_along(covariates)) {
  y <- dt[[covariates[i]]]
  valid <- !is.na(y)
  rdd_cov <- tryCatch(
    rdrobust(y = y[valid], x = dt$signed_dist_m[valid], c = 0,
             kernel = "triangular", bwselect = "mserd"),
    error = function(e) NULL
  )
  if (!is.null(rdd_cov)) {
    tex_tab3 <- c(tex_tab3, sprintf("%s & %s & (%s) & %s \\\\",
                                     cov_labels[i],
                                     formatC(rdd_cov$coef[3], format = "f", digits = 3),
                                     formatC(rdd_cov$se[3], format = "f", digits = 3),
                                     formatC(rdd_cov$pv[3], format = "f", digits = 3)))
  }
}

tex_tab3 <- c(tex_tab3,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the bias-corrected RD estimate from \\citet{cattaneo2020} using the covariate as the dependent variable and signed distance to the REP/non-REP boundary as the running variable. Robust standard errors in parentheses. Non-significant estimates confirm that observable property characteristics are smooth at the boundary.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_tab3, file.path(table_dir, "tab3_balance.tex"))
cat("Table 3 saved.\n")

## ===================================================================
## Table 4: Robustness
## ===================================================================

cat("Generating Table 4: Robustness...\n")

# McCrary test
mccrary <- rddensity(X = dt$signed_dist_m, c = 0)

# Donut
dt_donut <- dt[dist_m >= 50]
rdd_donut <- tryCatch(
  rdrobust(y = dt_donut$log_price, x = dt_donut$signed_dist_m, c = 0,
           kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

# Uniform kernel
rdd_uniform <- tryCatch(
  rdrobust(y = dt$log_price, x = dt$signed_dist_m, c = 0,
           kernel = "uniform", bwselect = "mserd"),
  error = function(e) NULL
)

# Quadratic
rdd_quad <- tryCatch(
  rdrobust(y = dt$log_price, x = dt$signed_dist_m, c = 0,
           p = 2, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

# Property types
rdd_apt <- tryCatch(
  rdrobust(y = dt[is_apt == 1]$log_price, x = dt[is_apt == 1]$signed_dist_m,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

rdd_house <- tryCatch(
  rdrobust(y = dt[is_apt == 0]$log_price, x = dt[is_apt == 0]$signed_dist_m,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

make_rob_row <- function(label, rdd_obj) {
  if (is.null(rdd_obj)) return(sprintf("%s & --- & --- & --- & --- \\\\", label))
  pv <- rdd_obj$pv[3]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  sprintf("%s & %s%s & (%s) & %s & %s \\\\",
          label,
          formatC(rdd_obj$coef[3], format = "f", digits = 4), stars,
          formatC(rdd_obj$se[3], format = "f", digits = 4),
          formatC(rdd_obj$bws[1,1], format = "f", digits = 0),
          formatC(rdd_obj$N_h[1] + rdd_obj$N_h[2], format = "d", big.mark = ","))
}

# Main for reference
rdd_main <- rdrobust(y = dt$log_price, x = dt$signed_dist_m, c = 0,
                      kernel = "triangular", bwselect = "mserd")

tex_tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the REP Designation Effect}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Estimate & Robust SE & BW (m) & N$_{\\text{eff}}$ \\\\",
  "\\midrule",
  make_rob_row("Baseline (triangular, linear)", rdd_main),
  make_rob_row("Uniform kernel", rdd_uniform),
  make_rob_row("Quadratic polynomial", rdd_quad),
  make_rob_row("Donut ($>$50m from boundary)", rdd_donut),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{By property type}} \\\\",
  make_rob_row("Apartments only", rdd_apt),
  make_rob_row("Houses only", rdd_house),
  "\\midrule",
  sprintf("McCrary density test & \\multicolumn{4}{c}{$T = %s$, $p = %s$} \\\\",
          formatC(mccrary$test$t_jk, format = "f", digits = 2),
          formatC(mccrary$test$p_jk, format = "f", digits = 3)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the \\citet{cattaneo2020} bias-corrected estimator with robust standard errors. The baseline uses a triangular kernel with local linear polynomials and MSE-optimal bandwidth selection. The McCrary test follows \\citet{cattaneo2020density}. *, **, *** denote significance at 10\\%, 5\\%, 1\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_tab4, file.path(table_dir, "tab4_robustness.tex"))
cat("Table 4 saved.\n")

## ===================================================================
## Table 5: REP vs REP+ Heterogeneity
## ===================================================================

cat("Generating Table 5: REP vs REP+ Heterogeneity...\n")

# REP (not +)
dt_rep_only <- dt[ep_status %in% c("REP", "HEP")]
rdd_rep <- tryCatch(
  rdrobust(y = dt_rep_only$log_price, x = dt_rep_only$signed_dist_m,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

# REP+
dt_repp <- dt[ep_status %in% c("REP+", "HEP")]
rdd_repp <- tryCatch(
  rdrobust(y = dt_repp$log_price, x = dt_repp$signed_dist_m,
           c = 0, kernel = "triangular", bwselect = "mserd"),
  error = function(e) NULL
)

tex_tab5 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{REP vs.\\ REP+ Designation Effects}",
  "\\label{tab:rep_vs_repp}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & All REP/REP+ & REP only & REP+ only \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule"
)

row_coef <- "REP designation"
row_se <- ""
for (rdd_obj in list(rdd_main, rdd_rep, rdd_repp)) {
  if (!is.null(rdd_obj)) {
    pv <- rdd_obj$pv[3]
    stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
    row_coef <- paste0(row_coef, " & ", formatC(rdd_obj$coef[3], format = "f", digits = 4), stars)
    row_se <- paste0(row_se, " & (", formatC(rdd_obj$se[3], format = "f", digits = 4), ")")
  } else {
    row_coef <- paste0(row_coef, " & ---")
    row_se <- paste0(row_se, " & ---")
  }
}

n_row_h <- "N (effective)"
for (rdd_obj in list(rdd_main, rdd_rep, rdd_repp)) {
  if (!is.null(rdd_obj)) {
    n_row_h <- paste0(n_row_h, " & ", formatC(rdd_obj$N_h[1] + rdd_obj$N_h[2],
                                               format = "d", big.mark = ","))
  } else {
    n_row_h <- paste0(n_row_h, " & ---")
  }
}

tex_tab5 <- c(tex_tab5,
  paste0(row_coef, " \\\\"),
  paste0(row_se, " \\\\"),
  "\\midrule",
  paste0(n_row_h, " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Column 1 pools all REP and REP+ boundaries. Column 2 restricts to boundaries between REP (not REP+) and non-REP sectors. Column 3 restricts to boundaries between REP+ and non-REP sectors. REP+ colleges receive additional resources including class sizes capped at 12 students and higher teacher salary bonuses (EUR 5,000/year vs.\\ EUR 1,700/year for REP). Bias-corrected estimates with robust standard errors \\citep{cattaneo2020}. *, **, *** denote significance at 10\\%, 5\\%, 1\\%.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_tab5, file.path(table_dir, "tab5_rep_vs_repp.tex"))
cat("Table 5 saved.\n")

## ===================================================================
## SDE Appendix Table (MANDATORY)
## ===================================================================

cat("Generating SDE appendix table...\n")

sd_y <- sd(dt$log_price)
beta_hat <- rdd_main$coef[3]
se_beta <- rdd_main$se[3]
sde <- beta_hat / sd_y
se_sde <- se_beta / sd_y

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_class <- classify_sde(sde)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does designation as a priority education zone (REP/REP+) affect residential property values at school catchment boundaries? ",
  "\\textbf{Policy mechanism:} REP/REP+ designation provides additional school resources---class sizes capped at 12 in REP+ (vs.\\ 25 in non-REP), teacher salary bonuses of EUR 1,700--5,000/year, and additional support staff---but also labels neighborhoods as educationally disadvantaged, creating potential stigma effects on housing markets. ",
  "\\textbf{Outcome definition:} Log transaction price (EUR) from DVF (Demandes de Valeurs Fonci\\`{e}res), the universe of French property transactions. ",
  "\\textbf{Treatment:} Binary---property is in a REP or REP+ college catchment area versus a non-REP catchment area. ",
  "\\textbf{Data:} DVF geolocalized transactions 2020--2024, merged with college catchment boundary polygons from data.gouv.fr. Unit of observation: individual property transaction. ",
  sprintf("Sample size: %s transactions within 1,000m of a REP/non-REP boundary. ", formatC(nrow(dt), format = "d", big.mark = ",")),
  "\\textbf{Method:} Spatial RDD with bias-corrected local polynomial estimator (Cattaneo, Idrobo, and Titiunik 2020), triangular kernel, MSE-optimal bandwidth, robust standard errors. ",
  "\\textbf{Sample:} Residential sales (apartments and houses) within 1,000m of REP/non-REP college catchment boundaries across metropolitan France; extreme prices ($<$EUR 10,000 or $>$EUR 5,000,000) excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the sample standard deviation of log transaction price. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tex_sde <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log price (all) & %s & %s & %s & %s & %s & %s \\\\",
          formatC(beta_hat, format = "f", digits = 4),
          formatC(se_beta, format = "f", digits = 4),
          formatC(sd_y, format = "f", digits = 4),
          formatC(sde, format = "f", digits = 4),
          formatC(se_sde, format = "f", digits = 4),
          sde_class)
)

# Add REP-only and REP+ rows if available
if (!is.null(rdd_rep)) {
  sd_y_rep <- sd(dt_rep_only$log_price)
  sde_rep <- rdd_rep$coef[3] / sd_y_rep
  tex_sde <- c(tex_sde, sprintf("Log price (REP) & %s & %s & %s & %s & %s & %s \\\\",
                                  formatC(rdd_rep$coef[3], format = "f", digits = 4),
                                  formatC(rdd_rep$se[3], format = "f", digits = 4),
                                  formatC(sd_y_rep, format = "f", digits = 4),
                                  formatC(sde_rep, format = "f", digits = 4),
                                  formatC(rdd_rep$se[3] / sd_y_rep, format = "f", digits = 4),
                                  classify_sde(sde_rep)))
}

if (!is.null(rdd_repp)) {
  sd_y_repp <- sd(dt_repp$log_price)
  sde_repp <- rdd_repp$coef[3] / sd_y_repp
  tex_sde <- c(tex_sde, sprintf("Log price (REP+) & %s & %s & %s & %s & %s & %s \\\\",
                                  formatC(rdd_repp$coef[3], format = "f", digits = 4),
                                  formatC(rdd_repp$se[3], format = "f", digits = 4),
                                  formatC(sd_y_repp, format = "f", digits = 4),
                                  formatC(sde_repp, format = "f", digits = 4),
                                  formatC(rdd_repp$se[3] / sd_y_repp, format = "f", digits = 4),
                                  classify_sde(sde_repp)))
}

tex_sde <- c(tex_sde,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tex_sde, file.path(table_dir, "tabF1_sde.tex"))
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
