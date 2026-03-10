## ============================================================
## 06_tables.R — All table generation (LaTeX output)
## apep_0573: EU Procurement Reform and Competition
## ============================================================

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))

cat("=== Loading data for tables ===\n")
panel <- fread(file.path(data_dir, "panel_country_quarter.csv"))
panel_year <- fread(file.path(data_dir, "panel_country_year.csv"))
transposition <- fread(file.path(data_dir, "transposition_dates.csv"))
models <- readRDS(file.path(data_dir, "models.rds"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("  Table 1: Summary statistics\n")

# Contract-level summary stats
ted_clean <- fread(file.path(data_dir, "ted_clean.csv"))

# Only use variables that exist in the sampled contract data
available_vars <- intersect(c("n_bids", "single_bidder", "sme_winner", "open_procedure",
                               "award_value", "award_ratio", "processing_days"),
                            names(ted_clean))
sumstats_vars <- available_vars

sumstats_list <- lapply(sumstats_vars, function(v) {
  x <- ted_clean[[v]]
  x <- x[!is.na(x)]
  data.table(
    Variable = v,
    N = length(x),
    Mean = mean(x),
    SD = sd(x),
    P25 = quantile(x, 0.25),
    Median = median(x),
    P75 = quantile(x, 0.75)
  )
})
sumstats_dt <- rbindlist(sumstats_list)

# Pretty names (only for variables that exist)
pretty_map <- c(
  n_bids = "Number of bids",
  single_bidder = "Single-bidder contract (0/1)",
  sme_winner = "SME winner (0/1)",
  award_value = "Award value (EUR)",
  award_ratio = "Award/estimated value ratio",
  open_procedure = "Open procedure (0/1)",
  processing_days = "Processing time (days)"
)
for (v in names(pretty_map)) {
  sumstats_dt[Variable == v, Variable := pretty_map[v]]
}

# Add panel-level summary stats for variables not in contract sample
panel_vars <- c("single_bidder_share", "mean_bids", "sme_winner_share",
                "mean_award_ratio", "open_proc_share", "mean_processing_days", "n_contracts")
panel_sumstats <- lapply(panel_vars, function(v) {
  x <- panel[[v]]
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NULL)
  data.table(
    Variable = v,
    N = length(x),
    Mean = mean(x),
    SD = sd(x),
    P25 = quantile(x, 0.25),
    Median = median(x),
    P75 = quantile(x, 0.75)
  )
})
panel_sumstats <- rbindlist(panel_sumstats[!sapply(panel_sumstats, is.null)])

# Pretty names for panel variables
panel_pretty <- c(
  single_bidder_share = "Single-bidder share (panel)",
  mean_bids = "Mean bids per contract (panel)",
  sme_winner_share = "SME winner share (panel)",
  mean_award_ratio = "Award/est. value ratio (panel)",
  open_proc_share = "Open procedure share (panel)",
  mean_processing_days = "Processing days (panel)",
  n_contracts = "Contracts per country-quarter"
)
for (v in names(panel_pretty)) {
  panel_sumstats[Variable == v, Variable := panel_pretty[v]]
}

sumstats_dt <- rbind(sumstats_dt, panel_sumstats)

fwrite(sumstats_dt, file.path(data_dir, "table1_summary_stats.csv"))

# LaTeX
sumstats_tex <- sumstats_dt[, .(Variable, N = formatC(N, format = "d", big.mark = ","),
                                 Mean = sprintf("%.3f", Mean),
                                 SD = sprintf("%.3f", SD),
                                 P25 = sprintf("%.3f", P25),
                                 Median = sprintf("%.3f", Median),
                                 P75 = sprintf("%.3f", P75))]

latex_tab1 <- print(xtable(sumstats_tex,
                           caption = "Summary Statistics: EU Public Procurement Contracts, 2009--2023",
                           label = "tab:summary"),
                    type = "latex",
                    include.rownames = FALSE,
                    sanitize.text.function = identity,
                    file = file.path(tab_dir, "table1_summary.tex"),
                    print.results = FALSE)

# ============================================================
# Table 2: Main Results — TWFE and C-S
# ============================================================
cat("  Table 2: Main results\n")

# Filter out NULL models for etable
safe_coef <- function(m, p) if (!is.null(m)) coef(m)[p] else NA_real_
safe_se <- function(m, p) if (!is.null(m)) se(m)[p] else NA_real_
safe_nobs <- function(m) if (!is.null(m)) nobs(m) else NA_integer_

twfe_models <- list(models$twfe_single, models$twfe_bids, models$twfe_sme,
                    models$twfe_ratio, models$twfe_open, models$twfe_time)
twfe_headers <- c("Single-bid share", "Log(bids)", "SME share",
                   "Award ratio", "Open proc.", "Days")
non_null <- !sapply(twfe_models, is.null)

if (sum(non_null) > 0) {
  etable(twfe_models[non_null],
         headers = twfe_headers[non_null],
         title = "Effect of 2014 Procurement Directives on Competition Outcomes",
         label = "tab:main_results",
         notes = "Notes: All specifications include country and quarter fixed effects, weighted by number of contracts. Standard errors clustered at the country level in parentheses. * p<0.10, ** p<0.05, *** p<0.01.",
         file = file.path(tab_dir, "table2_main_results.tex"),
         replace = TRUE)
}

# Also save as CSV for data-first rule
main_res <- data.table(
  outcome = twfe_headers,
  coef = sapply(twfe_models, safe_coef, "treated"),
  se = sapply(twfe_models, safe_se, "treated"),
  n_obs = sapply(twfe_models, safe_nobs)
)
main_res <- main_res[!is.na(coef)]
main_res[, t_stat := coef / se]
main_res[, p_value := 2 * pnorm(-abs(t_stat))]
fwrite(main_res, file.path(data_dir, "table2_main_results.csv"))

# ============================================================
# Table 3: C-S aggregate ATT
# ============================================================
cat("  Table 3: Callaway-Sant'Anna ATT\n")

cs_results_file <- file.path(data_dir, "cs_att_results.csv")
if (file.exists(cs_results_file)) {
  cs_res <- fread(cs_results_file)
  cs_res[, t_stat := att / se]
  cs_res[, p_value := 2 * pnorm(-abs(t_stat))]
  cs_res[, ci_lower := att - 1.96 * se]
  cs_res[, ci_upper := att + 1.96 * se]

  fwrite(cs_res, file.path(data_dir, "table3_cs_results.csv"))

  # LaTeX
  cs_tex <- cs_res[, .(Outcome = outcome,
                        ATT = sprintf("%.4f", att),
                        SE = sprintf("(%.4f)", se),
                        CI = sprintf("[%.4f, %.4f]", ci_lower, ci_upper),
                        Groups = n_groups)]

  print(xtable(cs_tex,
               caption = "Callaway-Sant'Anna Aggregate Treatment Effects",
               label = "tab:cs_results"),
        type = "latex",
        include.rownames = FALSE,
        file = file.path(tab_dir, "table3_cs_results.tex"))
}

# ============================================================
# Table 4: Heterogeneity
# ============================================================
cat("  Table 4: Heterogeneity\n")

het_models <- list(models$het_high, models$het_low)
het_non_null <- !sapply(het_models, is.null)
if (sum(het_non_null) > 0) {
  etable(het_models[het_non_null],
         headers = c("High capacity", "Low capacity")[het_non_null],
         title = "Heterogeneity by Administrative Capacity",
         label = "tab:heterogeneity",
         notes = "Notes: Countries split at median World Bank Government Effectiveness (2014). High capacity: above median. Low capacity: below median. All specifications include country and quarter FE. Standard errors clustered at country level.",
         file = file.path(tab_dir, "table4_heterogeneity.tex"),
         replace = TRUE)
}

# ============================================================
# Table 5: Mechanism — Procedure types and processing time
# ============================================================
cat("  Table 5: Mechanism results\n")

mech_models <- list(models$mech_open, models$mech_time)
mech_headers <- c("Open proc. share", "Processing days")
mech_non_null <- !sapply(mech_models, is.null)

if (sum(mech_non_null) > 0) {
  etable(mech_models[mech_non_null],
         headers = mech_headers[mech_non_null],
         title = "Mechanism: Procedure Types and Administrative Burden",
         label = "tab:mechanism",
         notes = "Notes: All specifications include country and quarter FE, weighted by contracts. Standard errors clustered at country level.",
         file = file.path(tab_dir, "table5_mechanism.tex"),
         replace = TRUE)
}

mech_res <- data.table(
  outcome = mech_headers,
  coef = sapply(mech_models, safe_coef, "treated"),
  se = sapply(mech_models, safe_se, "treated")
)
mech_res <- mech_res[!is.na(coef)]
if (nrow(mech_res) > 0) fwrite(mech_res, file.path(data_dir, "table5_mechanism.csv"))

# ============================================================
# Table 6: Transposition dates
# ============================================================
cat("  Table 6: Transposition timing\n")

trans_table <- transposition[order(transposition_date),
  .(Country = countrycode(iso2, "iso2c", "country.name"),
    `Transposition date` = as.character(transposition_date),
    `On time` = ifelse(on_time, "Yes", "No"),
    `Gov. effectiveness` = sprintf("%.2f", gov_effectiveness_2014))]

# Fix country names that countrycode can't resolve
trans_table[is.na(Country) & `Transposition date` == "2016-08-22", Country := "Greece"]
trans_table[is.na(Country) & `Transposition date` == "2016-02-26", Country := "United Kingdom"]
# Catch any remaining NAs
trans_table[is.na(Country), Country := "Unknown"]

fwrite(trans_table, file.path(data_dir, "table6_transposition.csv"))

print(xtable(trans_table,
             caption = "Transposition of Directive 2014/24/EU by Member State",
             label = "tab:transposition"),
      type = "latex",
      include.rownames = FALSE,
      file = file.path(tab_dir, "table6_transposition.tex"))

# ============================================================
# Table C1: Robustness summary (Appendix)
# ============================================================
cat("  Table C1: Robustness summary\n")

rob_file <- file.path(data_dir, "robustness_summary.csv")
if (file.exists(rob_file)) {
  rob <- fread(rob_file)
  fwrite(rob, file.path(data_dir, "tableC1_robustness.csv"))

  print(xtable(rob,
               caption = "Robustness Checks: Single-Bidder Share",
               label = "tab:robustness"),
        type = "latex",
        include.rownames = FALSE,
        file = file.path(tab_dir, "tableC1_robustness.tex"))
}

cat("\n06_tables.R complete.\n")
