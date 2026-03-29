# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# ==============================================================================

source("00_packages.R")

# --- Load all results ---
panel <- readRDS("../data/panel_final.rds")
diagnostics <- jsonlite::read_json("../data/diagnostics.json")

# Main results
att_visible <- readRDS("../data/att_visible.rds")
att_opaque <- readRDS("../data/att_opaque.rds")
att_earn <- readRDS("../data/att_earn.rds")
es_visible <- readRDS("../data/es_visible.rds")
es_opaque <- readRDS("../data/es_opaque.rds")

# TWFE
twfe_visible <- readRDS("../data/twfe_visible.rds")
twfe_opaque <- readRDS("../data/twfe_opaque.rds")
twfe_earn <- readRDS("../data/twfe_earn.rds")

# Placebo
twfe_nh_visible <- readRDS("../data/twfe_nh_visible.rds")
twfe_nh_opaque <- readRDS("../data/twfe_nh_opaque.rds")

# Triple-diff
twfe_ddd <- readRDS("../data/twfe_ddd.rds")

# Robustness
twfe_nr_visible <- readRDS("../data/twfe_nr_visible.rds")
twfe_nr_opaque <- readRDS("../data/twfe_nr_opaque.rds")
twfe_late_visible <- readRDS("../data/twfe_late_visible.rds")
twfe_constr <- readRDS("../data/twfe_constr.rds")

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

hisp <- panel[ethnicity == "A2"]
nonhisp <- panel[ethnicity == "A1"]

# Pre-treatment period (before any SC activation, roughly 2005-2007)
pre_hisp <- hisp[year <= 2007]
pre_nonhisp <- nonhisp[year <= 2007]

summ_stats <- data.frame(
  Variable = c(
    "\\textit{Panel A: Hispanic Workers}",
    "Total employment",
    "Visible-sector share",
    "Opaque-sector share",
    "Visible-sector earnings (\\$/month)",
    "",
    "\\textit{Panel B: Non-Hispanic Workers}",
    "Total employment",
    "Visible-sector share",
    "Opaque-sector share"
  ),
  Mean = c(
    "", sprintf("%.0f", mean(pre_hisp$total_emp, na.rm = TRUE)),
    sprintf("%.4f", mean(pre_hisp$emp_share_visible, na.rm = TRUE)),
    sprintf("%.4f", mean(pre_hisp$emp_share_opaque, na.rm = TRUE)),
    sprintf("%.0f", mean(pre_hisp$earn_weighted_visible[pre_hisp$emp_visible > 0], na.rm = TRUE)),
    "",
    "", sprintf("%.0f", mean(pre_nonhisp$total_emp, na.rm = TRUE)),
    sprintf("%.4f", mean(pre_nonhisp$emp_share_visible, na.rm = TRUE)),
    sprintf("%.4f", mean(pre_nonhisp$emp_share_opaque, na.rm = TRUE))
  ),
  SD = c(
    "", sprintf("%.0f", sd(pre_hisp$total_emp, na.rm = TRUE)),
    sprintf("%.4f", sd(pre_hisp$emp_share_visible, na.rm = TRUE)),
    sprintf("%.4f", sd(pre_hisp$emp_share_opaque, na.rm = TRUE)),
    sprintf("%.0f", sd(pre_hisp$earn_weighted_visible[pre_hisp$emp_visible > 0], na.rm = TRUE)),
    "",
    "", sprintf("%.0f", sd(pre_nonhisp$total_emp, na.rm = TRUE)),
    sprintf("%.4f", sd(pre_nonhisp$emp_share_visible, na.rm = TRUE)),
    sprintf("%.4f", sd(pre_nonhisp$emp_share_opaque, na.rm = TRUE))
  ),
  N = c(
    "", as.character(nrow(pre_hisp)),
    "", "", "", "",
    "", as.character(nrow(pre_nonhisp)),
    "", ""
  )
)

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: Pre-Treatment Period (2005--2007)}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Mean & SD & N \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i, ]
  if (row$Variable == "") {
    tab1_lines <- c(tab1_lines, "\\addlinespace")
  } else if (grepl("Panel", row$Variable)) {
    tab1_lines <- c(tab1_lines, paste0(row$Variable, " & & & \\\\"))
  } else {
    tab1_lines <- c(tab1_lines,
      paste0(row$Variable, " & ", row$Mean, " & ", row$SD, " & ", row$N, " \\\\"))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Statistics computed over the pre-treatment period ",
         "(2005Q1--2007Q4) for counties in the analysis sample. ",
         "Visible-sector industries include construction (NAICS 236--238) and manufacturing ",
         "(NAICS 311--339). Opaque-sector industries include food services (722), ",
         "social assistance (624), and healthcare (621--623). ",
         "Employment shares are computed as sector employment divided by total county employment for each ethnicity group. ",
         "Source: Census QWI."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

# ==============================================================================
# TABLE 2: Main Results (C-S ATT + TWFE)
# ==============================================================================

cat("=== Generating Table 2: Main Results ===\n")

# Build table manually for clean formatting
get_stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("^{***}")
  if (pval < 0.05) return("^{**}")
  if (pval < 0.1) return("^{*}")
  return("")
}

# Extract C-S results
cs_vis_att <- att_visible$overall.att
cs_vis_se <- att_visible$overall.se
cs_vis_p <- 2 * pnorm(-abs(cs_vis_att / cs_vis_se))

cs_opq_att <- att_opaque$overall.att
cs_opq_se <- att_opaque$overall.se
cs_opq_p <- 2 * pnorm(-abs(cs_opq_att / cs_opq_se))

cs_earn_att <- att_earn$overall.att
cs_earn_se <- att_earn$overall.se
cs_earn_p <- 2 * pnorm(-abs(cs_earn_att / cs_earn_se))

# Extract TWFE results
tw_vis_coef <- coef(twfe_visible)["post"]
tw_vis_se <- sqrt(vcov(twfe_visible)["post", "post"])
tw_vis_p <- 2 * pnorm(-abs(tw_vis_coef / tw_vis_se))

tw_opq_coef <- coef(twfe_opaque)["post"]
tw_opq_se <- sqrt(vcov(twfe_opaque)["post", "post"])
tw_opq_p <- 2 * pnorm(-abs(tw_opq_coef / tw_opq_se))

tw_earn_coef <- coef(twfe_earn)["post"]
tw_earn_se <- sqrt(vcov(twfe_earn)["post", "post"])
tw_earn_p <- 2 * pnorm(-abs(tw_earn_coef / tw_earn_se))

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Effect of Secure Communities on Hispanic Industry Composition}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & Visible Share & Opaque Share & Visible Earnings \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\midrule",
  "\\textit{Panel A: Callaway-Sant'Anna} & & & \\\\",
  sprintf("SC Activation & $%.5f%s$ & $%.5f%s$ & $%.1f%s$ \\\\",
          cs_vis_att, get_stars(cs_vis_p),
          cs_opq_att, get_stars(cs_opq_p),
          cs_earn_att, get_stars(cs_earn_p)),
  sprintf(" & $(%.5f)$ & $(%.5f)$ & $(%.1f)$ \\\\",
          cs_vis_se, cs_opq_se, cs_earn_se),
  "\\addlinespace",
  "\\textit{Panel B: TWFE} & & & \\\\",
  sprintf("Post $\\times$ SC & $%.5f%s$ & $%.5f%s$ & $%.1f%s$ \\\\",
          tw_vis_coef, get_stars(tw_vis_p),
          tw_opq_coef, get_stars(tw_opq_p),
          tw_earn_coef, get_stars(tw_earn_p)),
  sprintf(" & $(%.5f)$ & $(%.5f)$ & $(%.1f)$ \\\\",
          tw_vis_se, tw_opq_se, tw_earn_se),
  "\\addlinespace",
  sprintf("Pre-treatment mean & %.4f & %.4f & %.0f \\\\",
          mean(hisp[year <= 2007]$emp_share_visible, na.rm = TRUE),
          mean(hisp[year <= 2007]$emp_share_opaque, na.rm = TRUE),
          mean(hisp[year <= 2007 & emp_visible > 0]$earn_weighted_visible, na.rm = TRUE)),
  sprintf("Counties & %s & %s & %s \\\\",
          format(diagnostics$n_counties, big.mark = ","),
          format(diagnostics$n_counties, big.mark = ","),
          format(uniqueN(panel[ethnicity == "A2" & emp_visible > 0]$county_fips), big.mark = ",")),
  sprintf("Observations & %s & %s & %s \\\\",
          format(diagnostics$n_obs, big.mark = ","),
          format(diagnostics$n_obs, big.mark = ","),
          format(nrow(panel[ethnicity == "A2" & emp_visible > 0]), big.mark = ",")),
  "Clustering & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Panel A reports the simple ATT from Callaway and Sant'Anna (2021) ",
         "with not-yet-treated counties as controls. Panel B reports TWFE with county and quarter fixed effects. ",
         "Visible-sector industries: construction (NAICS 236--238) and manufacturing (311--339). ",
         "Opaque-sector industries: food services (722), social assistance (624), healthcare (621--623). ",
         "Standard errors clustered at the state level in parentheses. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ==============================================================================
# TABLE 3: Placebo and Triple-Difference
# ==============================================================================

cat("=== Generating Table 3: Placebo + Triple-Diff ===\n")

# Non-Hispanic TWFE results
nh_vis_coef <- coef(twfe_nh_visible)["post"]
nh_vis_se <- sqrt(vcov(twfe_nh_visible)["post", "post"])
nh_vis_p <- 2 * pnorm(-abs(nh_vis_coef / nh_vis_se))

nh_opq_coef <- coef(twfe_nh_opaque)["post"]
nh_opq_se <- sqrt(vcov(twfe_nh_opaque)["post", "post"])
nh_opq_p <- 2 * pnorm(-abs(nh_opq_coef / nh_opq_se))

# Triple-diff results
ddd_coef <- coef(twfe_ddd)["post:hispanic"]
ddd_se <- sqrt(vcov(twfe_ddd)["post:hispanic", "post:hispanic"])
ddd_p <- 2 * pnorm(-abs(ddd_coef / ddd_se))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Placebo Tests and Triple-Difference}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Visible Share & Opaque Share \\\\",
  " & (1) & (2) \\\\",
  "\\midrule",
  "\\textit{Panel A: Hispanic (baseline)} & & \\\\",
  sprintf("Post $\\times$ SC & $%.5f%s$ & $%.5f%s$ \\\\",
          tw_vis_coef, get_stars(tw_vis_p),
          tw_opq_coef, get_stars(tw_opq_p)),
  sprintf(" & $(%.5f)$ & $(%.5f)$ \\\\", tw_vis_se, tw_opq_se),
  "\\addlinespace",
  "\\textit{Panel B: Non-Hispanic (placebo)} & & \\\\",
  sprintf("Post $\\times$ SC & $%.5f%s$ & $%.5f%s$ \\\\",
          nh_vis_coef, get_stars(nh_vis_p),
          nh_opq_coef, get_stars(nh_opq_p)),
  sprintf(" & $(%.5f)$ & $(%.5f)$ \\\\", nh_vis_se, nh_opq_se),
  "\\addlinespace",
  "\\textit{Panel C: Triple-Difference} & & \\\\",
  sprintf("Post $\\times$ SC $\\times$ Hispanic & $%.5f%s$ & \\\\",
          ddd_coef, get_stars(ddd_p)),
  sprintf(" & $(%.5f)$ & \\\\", ddd_se),
  "\\addlinespace",
  sprintf("Observations & %s & %s \\\\",
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  "Clustering & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} All specifications include county and quarter fixed effects. ",
         "Panel A repeats the baseline Hispanic TWFE estimates. ",
         "Panel B estimates the same specification for non-Hispanic workers as a placebo test. ",
         "Panel C reports the triple-difference estimate from a pooled Hispanic/non-Hispanic regression ",
         "with county$\\times$ethnicity and quarter$\\times$ethnicity fixed effects. ",
         "Standard errors clustered at the state level. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_placebo.tex")

# ==============================================================================
# TABLE 4: Robustness
# ==============================================================================

cat("=== Generating Table 4: Robustness ===\n")

recession_qs <- c(2008 * 4 + 4, 2009 * 4 + 1, 2009 * 4 + 2)

# Extract robustness coefficients
nr_vis_coef <- coef(twfe_nr_visible)["post"]
nr_vis_se <- sqrt(vcov(twfe_nr_visible)["post", "post"])
nr_vis_p <- 2 * pnorm(-abs(nr_vis_coef / nr_vis_se))

nr_opq_coef <- coef(twfe_nr_opaque)["post"]
nr_opq_se <- sqrt(vcov(twfe_nr_opaque)["post", "post"])
nr_opq_p <- 2 * pnorm(-abs(nr_opq_coef / nr_opq_se))

late_vis_coef <- coef(twfe_late_visible)["post"]
late_vis_se <- sqrt(vcov(twfe_late_visible)["post", "post"])
late_vis_p <- 2 * pnorm(-abs(late_vis_coef / late_vis_se))

constr_coef <- coef(twfe_constr)["post"]
constr_se <- sqrt(vcov(twfe_constr)["post", "post"])
constr_p <- 2 * pnorm(-abs(constr_coef / constr_se))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness Checks: Hispanic Visible-Sector Employment Share}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Baseline & Drop Recession & Late Activators & Construction \\\\",
  " &  & Cohorts & Only (2010+) & Only \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Post $\\times$ SC & $%.5f%s$ & $%.5f%s$ & $%.5f%s$ & $%.5f%s$ \\\\",
          tw_vis_coef, get_stars(tw_vis_p),
          nr_vis_coef, get_stars(nr_vis_p),
          late_vis_coef, get_stars(late_vis_p),
          constr_coef, get_stars(constr_p)),
  sprintf(" & $(%.5f)$ & $(%.5f)$ & $(%.5f)$ & $(%.5f)$ \\\\",
          tw_vis_se, nr_vis_se, late_vis_se, constr_se),
  "\\addlinespace",
  sprintf("Counties & %s & %s & %s & %s \\\\",
          format(diagnostics$n_counties, big.mark = ","),
          format(uniqueN(panel[ethnicity == "A2" & !(activation_time_q %in% recession_qs)]$county_fips), big.mark = ","),
          format(uniqueN(panel[ethnicity == "A2" & (activation_time_q == 0 | activation_time_q >= 2010 * 4 + 1)]$county_fips), big.mark = ","),
          format(diagnostics$n_counties, big.mark = ",")),
  "Clustering & State & State & State & State \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} All specifications use TWFE with county and quarter fixed effects. ",
         "Column 1: baseline. Column 2: drops counties activated during the Great Recession ",
         "(2008Q4--2009Q2). Column 3: restricts treated sample to late activators (2010Q1--2013Q1). ",
         "Column 4: uses construction employment share (NAICS 236--238) only as the outcome, ",
         "excluding manufacturing. Standard errors clustered at the state level. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")

# ==============================================================================
# TABLE 5: Event Study Coefficients
# ==============================================================================

cat("=== Generating Table 5: Event Study ===\n")

es_vis_beta <- es_visible$att.egt
es_vis_se <- es_visible$se.egt
es_vis_e <- es_visible$egt

es_opq_beta <- es_opaque$att.egt
es_opq_se <- es_opaque$se.egt
es_opq_e <- es_opaque$egt

# Align event times
all_e <- sort(union(es_vis_e, es_opq_e))

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Event-Study Estimates: Quarters Relative to SC Activation}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Quarter & Visible Share & Opaque Share \\\\",
  "\\midrule"
)

for (e in all_e) {
  vis_idx <- which(es_vis_e == e)
  opq_idx <- which(es_opq_e == e)

  vis_str <- if (length(vis_idx) > 0) {
    p <- 2 * pnorm(-abs(es_vis_beta[vis_idx] / es_vis_se[vis_idx]))
    sprintf("$%.5f%s$", es_vis_beta[vis_idx], get_stars(p))
  } else { "" }

  opq_str <- if (length(opq_idx) > 0) {
    p <- 2 * pnorm(-abs(es_opq_beta[opq_idx] / es_opq_se[opq_idx]))
    sprintf("$%.5f%s$", es_opq_beta[opq_idx], get_stars(p))
  } else { "" }

  vis_se_str <- if (length(vis_idx) > 0) {
    sprintf("$(%.5f)$", es_vis_se[vis_idx])
  } else { "" }

  opq_se_str <- if (length(opq_idx) > 0) {
    sprintf("$(%.5f)$", es_opq_se[opq_idx])
  } else { "" }

  # Add separator between pre and post
  if (e == 0) {
    tab5_lines <- c(tab5_lines, "\\midrule")
  }

  tab5_lines <- c(tab5_lines,
    sprintf("$k = %d$ & %s & %s \\\\", e, vis_str, opq_str),
    sprintf(" & %s & %s \\\\", vis_se_str, opq_se_str))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Event-study estimates from Callaway and Sant'Anna (2021) ",
         "with not-yet-treated controls. $k$ denotes quarters relative to SC activation. ",
         "Standard errors clustered at the state level. ",
         "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_eventstudy.tex")

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ==============================================================================

cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Pre-treatment SDs
pre_hisp <- panel[ethnicity == "A2" & year <= 2007]
sd_visible <- sd(pre_hisp$emp_share_visible, na.rm = TRUE)
sd_opaque <- sd(pre_hisp$emp_share_opaque, na.rm = TRUE)
sd_earn <- sd(pre_hisp$earn_weighted_visible[pre_hisp$emp_visible > 0], na.rm = TRUE)

# SDE = beta_hat / SD(Y)
sde_visible <- cs_vis_att / sd_visible
sde_visible_se <- cs_vis_se / sd_visible

sde_opaque <- cs_opq_att / sd_opaque
sde_opaque_se <- cs_opq_se / sd_opaque

sde_earn <- cs_earn_att / sd_earn
sde_earn_se <- cs_earn_se / sd_earn

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# --- Heterogeneity: High vs Low Hispanic share counties ---
# Split at median pre-treatment Hispanic employment share
county_hisp_share <- pre_hisp[, .(mean_hisp_total = mean(total_emp, na.rm = TRUE)),
                               by = county_fips]
med_hisp <- median(county_hisp_share$mean_hisp_total, na.rm = TRUE)

high_hisp_counties <- county_hisp_share[mean_hisp_total >= med_hisp]$county_fips
low_hisp_counties <- county_hisp_share[mean_hisp_total < med_hisp]$county_fips

# Re-run TWFE for subsamples
hisp_all <- panel[ethnicity == "A2"]
hisp_all[, county_id := as.integer(factor(county_fips))]
hisp_all[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]

hisp_high <- hisp_all[county_fips %in% high_hisp_counties]
hisp_high[, county_id_h := as.integer(factor(county_fips))]
twfe_high <- feols(emp_share_visible ~ post | county_id_h + time_q,
                   data = hisp_high, vcov = ~state_fips)

hisp_low <- hisp_all[county_fips %in% low_hisp_counties]
hisp_low[, county_id_l := as.integer(factor(county_fips))]
twfe_low <- feols(emp_share_visible ~ post | county_id_l + time_q,
                  data = hisp_low, vcov = ~state_fips)

# SDE for subsamples
sd_vis_high <- sd(pre_hisp[county_fips %in% high_hisp_counties]$emp_share_visible, na.rm = TRUE)
sd_vis_low <- sd(pre_hisp[county_fips %in% low_hisp_counties]$emp_share_visible, na.rm = TRUE)

sde_high <- coef(twfe_high)["post"] / sd_vis_high
sde_high_se <- sqrt(vcov(twfe_high)["post", "post"]) / sd_vis_high

sde_low <- coef(twfe_low)["post"] / sd_vis_low
sde_low_se <- sqrt(vcov(twfe_low)["post", "post"]) / sd_vis_low

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the activation of Secure Communities immigration enforcement shift Hispanic workers ",
  "from enforcement-visible industries toward enforcement-opaque sectors? ",
  "\\textbf{Policy mechanism:} Secure Communities requires local jails to share arrestee fingerprints with ICE for immigration checks, ",
  "raising the expected cost of employment in industries with higher workplace enforcement visibility (construction sites, factories) ",
  "relative to less visible sectors (restaurants, home healthcare). ",
  "\\textbf{Outcome definition:} Visible-sector employment share is the fraction of county-level Hispanic quarterly employment ",
  "in construction (NAICS 236--238) and manufacturing (NAICS 311--339); opaque-sector share covers food services (722), ",
  "social assistance (624), and healthcare (621--623); visible-sector earnings are average monthly earnings of stable Hispanic ",
  "employees in visible-sector industries. ",
  "\\textbf{Treatment:} Binary; county-level activation of Secure Communities (staggered 2008--2013). ",
  "\\textbf{Data:} Census QWI (Quarterly Workforce Indicators) by ethnicity and NAICS-3 industry, ",
  sprintf("%s counties, 2005Q1--2015Q4, %s county-quarter observations. ",
          format(diagnostics$n_counties, big.mark = ","),
          format(diagnostics$n_obs, big.mark = ",")),
  "\\textbf{Method:} Callaway-Sant'Anna (2021) ATT with not-yet-treated controls for pooled panel; ",
  "TWFE with county and quarter fixed effects for heterogeneity splits; standard errors clustered at state level. ",
  "\\textbf{Sample:} Counties with at least 20 quarters of QWI data and mean Hispanic employment of 50 or more workers; ",
  "visible-sector earnings restricted to county-quarters with positive visible-sector employment. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2005--2007) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Visible share & $%.5f$ & $%.5f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
          cs_vis_att, cs_vis_se, sd_visible, sde_visible, sde_visible_se, classify_sde(sde_visible)),
  sprintf("Opaque share & $%.5f$ & $%.5f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
          cs_opq_att, cs_opq_se, sd_opaque, sde_opaque, sde_opaque_se, classify_sde(sde_opaque)),
  sprintf("Visible earnings & $%.1f$ & $%.1f$ & $%.0f$ & $%.4f$ & $%.4f$ & %s \\\\",
          cs_earn_att, cs_earn_se, sd_earn, sde_earn, sde_earn_se, classify_sde(sde_earn)),
  "\\addlinespace",
  "\\textit{Panel B: Heterogeneous (visible share)} & & & & & & \\\\",
  sprintf("High Hispanic pop. & $%.5f$ & $%.5f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
          coef(twfe_high)["post"], sqrt(vcov(twfe_high)["post", "post"]),
          sd_vis_high, sde_high, sde_high_se, classify_sde(sde_high)),
  sprintf("Low Hispanic pop. & $%.5f$ & $%.5f$ & $%.4f$ & $%.4f$ & $%.4f$ & %s \\\\",
          coef(twfe_low)["post"], sqrt(vcov(twfe_low)["post", "post"]),
          sd_vis_low, sde_low, sde_low_se, classify_sde(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_placebo.tex\n")
cat("  tab4_robust.tex\n")
cat("  tab5_eventstudy.tex\n")
cat("  tabF1_sde.tex\n")
