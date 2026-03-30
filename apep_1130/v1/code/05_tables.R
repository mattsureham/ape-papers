## 05_tables.R — Generate all LaTeX tables
## apep_1130: SBA Size Standards and Geographic Procurement Redistribution

source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- fread("../data/sector_panel.csv")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ==================================================================
# Table 1: Summary Statistics
# ==================================================================
cat("Table 1: Summary statistics\n")

# Pre-treatment means by treated vs control
pre_treated <- panel[!is.na(treat_year) & fiscal_year < treat_year]
pre_control <- panel[is.na(treat_year)]

stats_fn <- function(dt, label) {
  data.table(
    Group = label,
    `SB Procurement ($M)` = sprintf("%.1f", mean(dt$total_sb, na.rm = TRUE) / 1e6),
    `Total Procurement ($M)` = sprintf("%.1f", mean(dt$total_all, na.rm = TRUE) / 1e6),
    `SB Share` = sprintf("%.3f", mean(dt$sb_share, na.rm = TRUE)),
    `HHI (SB)` = sprintf("%.4f", mean(dt$hhi_sb, na.rm = TRUE)),
    `Metro Share (SB)` = sprintf("%.3f", mean(dt$metro_share_sb, na.rm = TRUE)),
    `N Counties (SB)` = sprintf("%.0f", mean(dt$n_counties_sb, na.rm = TRUE)),
    `Sector-Years` = as.character(nrow(dt))
  )
}

sum_stats <- rbindlist(list(
  stats_fn(pre_treated, "Treated (pre-period)"),
  stats_fn(pre_control, "Never-treated"),
  stats_fn(panel, "Full sample")
))

# Build LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Federal Procurement by NAICS Sector}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & SB Proc. & Total Proc. & SB & HHI & Metro & N Counties & Sector \\\\",
  " & (\\$M) & (\\$M) & Share & (SB) & Share & (SB) & Years \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s \\\\",
    row$Group, row$`SB Procurement ($M)`, row$`Total Procurement ($M)`,
    row$`SB Share`, row$`HHI (SB)`, row$`Metro Share (SB)`,
    row$`N Counties (SB)`, row$`Sector-Years`
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment means for treated sectors (before their respective size standard increase) vs.\\ never-treated control sectors. SB = small business set-aside. HHI = Herfindahl-Hirschman Index of county-level procurement concentration (higher = more concentrated). Metro share = fraction of SB set-aside dollars awarded in metropolitan counties (RUCC $\\leq$ 3). Source: USAspending.gov, FY2008--FY2020.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ==================================================================
# Table 2: Main Results — CS DiD and TWFE
# ==================================================================
cat("Table 2: Main results\n")

# Extract CS results
get_cs <- function(cs_obj) {
  if (is.null(cs_obj)) return(c(NA, NA))
  c(cs_obj$overall.att, cs_obj$overall.se)
}

cs_sb <- get_cs(results$cs_log_sb)
cs_hhi <- get_cs(results$cs_hhi)
cs_metro <- get_cs(results$cs_metro)
cs_ncounty <- get_cs(results$cs_n_counties)

# TWFE results
get_twfe <- function(twfe_obj) {
  cf <- coef(twfe_obj)["post"]
  se <- sqrt(vcov(twfe_obj)["post", "post"])
  c(cf, se)
}

twfe_sb_res <- get_twfe(results$twfe1)
twfe_hhi_res <- get_twfe(results$twfe2)

# Stars function
stars <- function(coef, se) {
  if (is.na(coef) || is.na(se) || se == 0) return("")
  p <- 2 * pnorm(-abs(coef / se))
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

fmt_coef <- function(coef, se, digits = 4) {
  if (is.na(coef)) return(c("---", ""))
  c(
    sprintf(paste0("%.", digits, "f%s"), coef, stars(coef, se)),
    sprintf(paste0("(%.", digits, "f)"), se)
  )
}

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of SBA Size Standard Increases on Procurement Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Log SB & HHI & Metro & N Counties \\\\",
  " & Procurement & (SB) & Share & (SB) \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\"
)

cs_vals <- list(cs_sb, cs_hhi, cs_metro, cs_ncounty)
digits_list <- c(4, 4, 4, 1)

# Coefficient row
coef_row <- "ATT"
se_row <- ""
for (j in seq_along(cs_vals)) {
  fmted <- fmt_coef(cs_vals[[j]][1], cs_vals[[j]][2], digits_list[j])
  coef_row <- paste0(coef_row, " & ", fmted[1])
  se_row <- paste0(se_row, " & ", fmted[2])
}
tab2_lines <- c(tab2_lines, paste0(coef_row, " \\\\"), paste0(se_row, " \\\\"))

tab2_lines <- c(tab2_lines,
  " & & & & \\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: TWFE (fixest)}} \\\\"
)

twfe_sb_fmt <- fmt_coef(twfe_sb_res[1], twfe_sb_res[2], 4)
twfe_hhi_fmt <- fmt_coef(twfe_hhi_res[1], twfe_hhi_res[2], 4)

# TWFE metro if available
twfe_metro_res <- tryCatch({
  twfe3 <- results$twfe3
  if (is.null(twfe3)) stop("no twfe3")
  get_twfe(twfe3)
}, error = function(e) c(NA, NA))
twfe_metro_fmt <- fmt_coef(twfe_metro_res[1], twfe_metro_res[2], 4)

twfe_ncounty_res <- tryCatch(get_twfe(results$twfe4), error = function(e) c(NA, NA))
twfe_ncounty_fmt <- fmt_coef(twfe_ncounty_res[1], twfe_ncounty_res[2], 1)

tab2_lines <- c(tab2_lines,
  sprintf("Post & %s & %s & %s & %s \\\\",
          twfe_sb_fmt[1], twfe_hhi_fmt[1], twfe_metro_fmt[1], twfe_ncounty_fmt[1]),
  sprintf(" & %s & %s & %s & %s \\\\",
          twfe_sb_fmt[2], twfe_hhi_fmt[2], twfe_metro_fmt[2], twfe_ncounty_fmt[2]),
  " & & & & \\\\",
  sprintf("Sector FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nrow(panel[!is.na(log_total_sb)]),
          nrow(panel[!is.na(hhi_sb)]),
          nrow(panel[!is.na(metro_share_sb)]),
          nrow(panel[!is.na(n_counties_sb)])),
  sprintf("Sectors & %d & %d & %d & %d \\\\",
          uniqueN(panel$naics_2d),
          uniqueN(panel[!is.na(hhi_sb)]$naics_2d),
          uniqueN(panel[!is.na(metro_share_sb)]$naics_2d),
          uniqueN(panel$naics_2d)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports Callaway-Sant'Anna (2021) group-time average treatment effects aggregated to the overall ATT. Panel B reports two-way fixed effects estimates. Treatment cohorts: FY2013 (Wholesale, Retail, Information), FY2014 (Finance, Real Estate, Professional Services), FY2016 (Manufacturing). Control group: never-treated sectors. Standard errors clustered at the sector level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ==================================================================
# Table 3: Robustness — Leave-one-cohort-out
# ==================================================================
cat("Table 3: Robustness\n")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Cohort-Out and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Coefficient & SE & N & Description \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Leave-one-cohort-out (Log SB Procurement)}} \\\\"
)

for (cohort_name in names(rob_results$loco)) {
  r <- rob_results$loco[[cohort_name]]
  tab3_lines <- c(tab3_lines, sprintf(
    "Drop %s cohort & %.4f%s & (%.4f) & %d & \\\\",
    cohort_name, r$coef, stars(r$coef, r$se), r$se, r$n
  ))
}

# Placebo
placebo_coef <- coef(rob_results$placebo_all)["post"]
placebo_se <- sqrt(vcov(rob_results$placebo_all)["post", "post"])

# SB share
sb_share_coef <- coef(rob_results$sb_share)["post"]
sb_share_se <- sqrt(vcov(rob_results$sb_share)["post", "post"])

tab3_lines <- c(tab3_lines,
  " & & & & \\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Placebo and Additional Tests}} \\\\",
  sprintf("Total procurement (placebo) & %.4f%s & (%.4f) & %d & Not SB-specific \\\\",
          placebo_coef, stars(placebo_coef, placebo_se), placebo_se, nobs(rob_results$placebo_all)),
  sprintf("SB share of total & %.4f%s & (%.4f) & %d & Composition shift \\\\",
          sb_share_coef, stars(sb_share_coef, sb_share_se), sb_share_se, nobs(rob_results$sb_share)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A drops one treatment cohort at a time and re-estimates the TWFE specification from Table \\ref{tab:main}. Panel B tests whether effects appear in total procurement (not specific to SB set-asides) and whether the SB share of procurement changes. All models include sector and year fixed effects with SEs clustered at the sector level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_robustness.tex"))

# ==================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ==================================================================
cat("Table F1: SDE appendix\n")

# Compute SDEs for main outcomes
compute_sde <- function(coef, se, y_var, panel_data, treat_year_col = "treat_year") {
  # Pre-treatment SD of Y
  pre_data <- panel_data[!is.na(get(treat_year_col)) &
                          fiscal_year < get(treat_year_col)]
  if (nrow(pre_data) == 0) {
    pre_data <- panel_data[is.na(get(treat_year_col))]
  }
  sd_y <- sd(pre_data[[y_var]], na.rm = TRUE)
  if (is.na(sd_y) || sd_y == 0) return(list(sde = NA, se_sde = NA, sd_y = NA))
  sde <- coef / sd_y
  se_sde <- se / sd_y
  list(sde = sde, se_sde = se_sde, sd_y = sd_y)
}

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Use TWFE coefficients for SDE (more straightforward interpretation)
sde_outcomes <- list(
  list(name = "Log SB procurement", coef = twfe_sb_res[1], se = twfe_sb_res[2],
       var = "log_total_sb"),
  list(name = "HHI (SB)", coef = twfe_hhi_res[1], se = twfe_hhi_res[2],
       var = "hhi_sb"),
  list(name = "Metro share (SB)", coef = twfe_metro_res[1], se = twfe_metro_res[2],
       var = "metro_share_sb"),
  list(name = "N counties (SB)", coef = twfe_ncounty_res[1], se = twfe_ncounty_res[2],
       var = "n_counties_sb")
)

sde_rows <- list()
for (out in sde_outcomes) {
  s <- compute_sde(out$coef, out$se, out$var, panel)
  sde_rows[[length(sde_rows) + 1]] <- data.table(
    Outcome = out$name,
    beta = out$coef,
    se = out$se,
    sd_y = s$sd_y,
    sde = s$sde,
    se_sde = s$se_sde,
    classification = classify_sde(s$sde)
  )
}

sde_dt <- rbindlist(sde_rows)

# Heterogeneity panel: split by cohort
het_rows <- list()
for (cohort_yr in c(2013, 2016)) {
  cohort_data <- panel[treat_year == cohort_yr | is.na(treat_year)]
  cohort_data[, post_c := fifelse(!is.na(treat_year) & fiscal_year >= treat_year, 1L, 0L)]
  fit_c <- tryCatch({
    feols(log_total_sb ~ post_c | sector_id + fiscal_year,
          data = cohort_data, cluster = ~sector_id)
  }, error = function(e) NULL)

  if (!is.null(fit_c)) {
    c_coef <- coef(fit_c)["post_c"]
    c_se <- sqrt(vcov(fit_c)["post_c", "post_c"])
    s_c <- compute_sde(c_coef, c_se, "log_total_sb", cohort_data)
    label <- ifelse(cohort_yr == 2013, "Log SB proc. (Cohort 2013)",
                     "Log SB proc. (Cohort 2016)")
    het_rows[[length(het_rows) + 1]] <- data.table(
      Outcome = label,
      beta = c_coef,
      se = c_se,
      sd_y = s_c$sd_y,
      sde = s_c$sde,
      se_sde = s_c$se_sde,
      classification = classify_sde(s_c$sde)
    )
  }
}

het_dt <- rbindlist(het_rows)

# Build LaTeX SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do SBA small business size standard increases ",
  "redistribute federal procurement geographically, shifting contract dollars ",
  "from non-metropolitan to metropolitan counties? ",
  "\\textbf{Policy mechanism:} The SBA periodically raises the employee or revenue ",
  "thresholds that define ``small business'' eligibility for federal set-aside contracts, ",
  "making previously ineligible mid-sized firms newly eligible to compete for reserved procurement. ",
  "\\textbf{Outcome definition:} Log of total small business set-aside procurement dollars ",
  "by NAICS sector-year from USAspending; Herfindahl-Hirschman Index of county-level concentration; ",
  "share of SB dollars in metropolitan counties (RUCC $\\leq$ 3). ",
  "\\textbf{Treatment:} Binary sector-level indicator for post-size-standard-increase, ",
  "with three staggered cohorts (FY2013, FY2014, FY2016). ",
  "\\textbf{Data:} USAspending.gov contract awards, FY2008--FY2020, 19 NAICS 2-digit sectors ",
  "observed annually (247 sector-year observations). ",
  "\\textbf{Method:} Callaway-Sant'Anna (2021) staggered DiD and TWFE with sector and year FE; ",
  "SEs clustered at sector level. ",
  "\\textbf{Sample:} All federal procurement contracts in 19 2-digit NAICS sectors; ",
  "10 treated sectors in 3 cohorts, 9 never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_dt)) {
  r <- sde_dt[i]
  if (is.na(r$beta)) next
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  " & & & & & & \\\\",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by treatment cohort)}} \\\\"
)

for (i in 1:nrow(het_dt)) {
  r <- het_dt[i]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables saved to: %s\n", tables_dir))
cat(sprintf("Files: %s\n", paste(list.files(tables_dir), collapse = ", ")))
