## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- fread("../data/analysis_panel.csv")
load("../data/models.RData")
load("../data/robustness_models.RData")

dir.create("../tables", showWarnings = FALSE)

## ==============================
## Table 1: Summary Statistics
## ==============================
cat("--- Table 1: Summary Statistics ---\n")

stats_2014 <- panel[year == 2014]
stats_all  <- panel

# Panel A: Municipality characteristics in 2014
vars_2014 <- stats_2014[, .(
  emp_total      = emp_total,
  emp_secondary  = emp_secondary,
  emp_tertiary   = emp_tertiary,
  manuf_share    = manuf_share,
  service_share  = service_share,
  est_total      = est_total,
  est_secondary  = est_secondary,
  est_tertiary   = est_tertiary
)]

summ_fn <- function(x) {
  c(Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    P25 = quantile(x, 0.25, na.rm = TRUE),
    Median = median(x, na.rm = TRUE),
    P75 = quantile(x, 0.75, na.rm = TRUE))
}

summ_rows <- rbindlist(lapply(names(vars_2014), function(v) {
  s <- summ_fn(vars_2014[[v]])
  data.table(Variable = v, Mean = s[1], SD = s[2], P25 = s[3], Median = s[4], P75 = s[5])
}))

# Create nice variable labels
var_labels <- c(
  emp_total = "Total employment",
  emp_secondary = "Secondary sector employment",
  emp_tertiary = "Tertiary sector employment",
  manuf_share = "Secondary sector share",
  service_share = "Tertiary sector share",
  est_total = "Total establishments",
  est_secondary = "Secondary establishments",
  est_tertiary = "Tertiary establishments"
)
summ_rows[, Variable := var_labels[Variable]]

# Format numbers
fmt <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ",")
fmt3 <- function(x) formatC(x, format = "f", digits = 3)

tab1_body <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Municipal Employment, 2014}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & P25 & Median & P75 \\\\\n",
  "\\hline\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Municipality characteristics (N = ",
  formatC(nrow(stats_2014), big.mark = ","), ")}} \\\\\n",
  "[3pt]\n"
)

for (i in 1:nrow(summ_rows)) {
  r <- summ_rows[i]
  if (r$Variable %in% c("Secondary sector share", "Tertiary sector share")) {
    tab1_body <- paste0(tab1_body,
      r$Variable, " & ", fmt3(r$Mean), " & ", fmt3(r$SD), " & ",
      fmt3(r$P25), " & ", fmt3(r$Median), " & ", fmt3(r$P75), " \\\\\n")
  } else {
    tab1_body <- paste0(tab1_body,
      r$Variable, " & ", fmt(r$Mean), " & ", fmt(r$SD), " & ",
      fmt(r$P25), " & ", fmt(r$Median), " & ", fmt(r$P75), " \\\\\n")
  }
}

# Panel B: High vs Low manufacturing comparison
high <- stats_2014[high_manuf == 1]
low  <- stats_2014[high_manuf == 0]

tab1_body <- paste0(tab1_body,
  "[6pt]\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: By manufacturing exposure}} \\\\\n",
  "[3pt]\n",
  " & \\multicolumn{2}{c}{High ($>$30\\%)} & \\multicolumn{2}{c}{Low ($\\leq$30\\%)} & Diff \\\\\n",
  " & Mean & SD & Mean & SD & \\\\\n",
  "\\cline{2-6}\n",
  "Secondary share & ", fmt3(mean(high$manuf_share)), " & ", fmt3(sd(high$manuf_share)),
  " & ", fmt3(mean(low$manuf_share)), " & ", fmt3(sd(low$manuf_share)),
  " & ", fmt3(mean(high$manuf_share) - mean(low$manuf_share)), " \\\\\n",
  "Total employment & ", fmt(mean(high$emp_total)), " & ", fmt(sd(high$emp_total)),
  " & ", fmt(mean(low$emp_total)), " & ", fmt(sd(low$emp_total)),
  " & ", fmt(mean(high$emp_total) - mean(low$emp_total)), " \\\\\n",
  "Municipalities & \\multicolumn{2}{c}{", nrow(high), "} & \\multicolumn{2}{c}{", nrow(low), "} & \\\\\n"
)

tab1_body <- paste0(tab1_body,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A reports cross-sectional statistics for all municipalities in the analysis sample ",
  "as of 2014 (last pre-shock year). Secondary sector corresponds to NOGA Sector~II (manufacturing and construction); ",
  "tertiary sector to Sector~III (services). Panel B compares municipalities above and below the 30\\% secondary-sector ",
  "employment threshold. Source: BFS STATENT, 2014.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_body, "../tables/tab1_summary.tex")
cat("  Written: tables/tab1_summary.tex\n")

## ==============================
## Table 2: Event Study Coefficients
## ==============================
cat("--- Table 2: Event Study ---\n")

# Extract event-study coefficients
es_manuf_coefs <- coeftable(es_manuf_share)
es_serv_coefs  <- coeftable(es_service_share)

years_es <- 2011:2023
years_es <- years_es[years_es != 2014]

tab2_body <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Sectoral Employment Shares}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Secondary share} & \\multicolumn{2}{c}{Tertiary share} \\\\\n",
  " & Coef. & SE & Coef. & SE \\\\\n",
  "\\hline\n"
)

for (yr in years_es) {
  pat <- paste0("year::", yr, ":")
  # Find matching row
  idx_m <- grep(pat, rownames(es_manuf_coefs), fixed = TRUE)
  idx_s <- grep(pat, rownames(es_serv_coefs), fixed = TRUE)

  if (length(idx_m) > 0 && length(idx_s) > 0) {
    m_est <- es_manuf_coefs[idx_m, 1]
    m_se  <- es_manuf_coefs[idx_m, 2]
    s_est <- es_serv_coefs[idx_s, 1]
    s_se  <- es_serv_coefs[idx_s, 2]

    # Stars
    m_p <- es_manuf_coefs[idx_m, 4]
    s_p <- es_serv_coefs[idx_s, 4]
    m_star <- ifelse(m_p < 0.01, "^{***}", ifelse(m_p < 0.05, "^{**}", ifelse(m_p < 0.10, "^{*}", "")))
    s_star <- ifelse(s_p < 0.01, "^{***}", ifelse(s_p < 0.05, "^{**}", ifelse(s_p < 0.10, "^{*}", "")))

    label <- ifelse(yr < 2015, paste0("$t = ", yr - 2015, "$"), paste0("$t = +", yr - 2015, "$"))
    if (yr == 2015) label <- "$t = 0$"

    tab2_body <- paste0(tab2_body,
      label, " & $", fmt3(m_est), m_star, "$ & (", fmt3(m_se), ")",
      " & $", fmt3(s_est), s_star, "$ & (", fmt3(s_se), ") \\\\\n")
  }
}

n_mun <- uniqueN(panel$gem_id)
n_obs <- nrow(panel)

tab2_body <- paste0(tab2_body,
  "[3pt]\n",
  "\\hline\n",
  "Municipalities & \\multicolumn{2}{c}{", formatC(n_mun, big.mark = ","), "} ",
  "& \\multicolumn{2}{c}{", formatC(n_mun, big.mark = ","), "} \\\\\n",
  "Observations & \\multicolumn{2}{c}{", formatC(n_obs, big.mark = ","), "} ",
  "& \\multicolumn{2}{c}{", formatC(n_obs, big.mark = ","), "} \\\\\n",
  "Municipality FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Cluster & \\multicolumn{2}{c}{Municipality} & \\multicolumn{2}{c}{Municipality} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each column reports coefficients from a regression of the sectoral employment share ",
  "on interactions of the municipality's 2014 secondary-sector share with year indicators, controlling for ",
  "municipality and year fixed effects. The omitted category is 2014 (last pre-shock year). Standard errors ",
  "clustered at the municipality level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_body, "../tables/tab2_event_study.tex")
cat("  Written: tables/tab2_event_study.tex\n")

## ==============================
## Table 3: Static DiD and Mechanisms
## ==============================
cat("--- Table 3: Static DiD ---\n")

# Use etable from fixest for clean output
etable(did_manuf, did_service, did_log_sec, did_log_tert, did_log_total,
       headers = c("Manuf Share", "Service Share", "Log Sec Emp", "Log Tert Emp", "Log Total Emp"),
       tex = TRUE,
       file = "../tables/tab3_static_did.tex",
       title = "Static Difference-in-Differences: Effect of Manufacturing Exposure",
       label = "tab:static_did",
       notes = paste0("Each column reports the coefficient on the interaction of the municipality's 2014 ",
                      "secondary-sector share with a post-2015 indicator, controlling for municipality and ",
                      "year fixed effects. Standard errors clustered at the municipality level in parentheses. ",
                      "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
       fitstat = c("n", "r2", "ar2"),
       style.tex = style.tex("aer"))
cat("  Written: tables/tab3_static_did.tex\n")

## ==============================
## Table 4: Short-run vs Long-run
## ==============================
cat("--- Table 4: Short-run vs Long-run ---\n")

etable(did_short_long_manuf, did_short_long_serv,
       did_short_long_log_sec, did_short_long_log_tert,
       headers = c("Manuf Share", "Service Share", "Log Sec Emp", "Log Tert Emp"),
       tex = TRUE,
       file = "../tables/tab4_short_long.tex",
       title = "Short-Run vs.\\ Long-Run Effects of Manufacturing Exposure",
       label = "tab:short_long",
       notes = paste0("Short-run = 2015--2017 (immediate aftermath); Long-run = 2018--2023 (recovery period). ",
                      "Each column reports coefficients on interactions of the municipality's 2014 secondary-sector ",
                      "share with period indicators, controlling for municipality and year FE. ",
                      "Standard errors clustered at the municipality level. ",
                      "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"))
cat("  Written: tables/tab4_short_long.tex\n")

## ==============================
## Table 5: Robustness
## ==============================
cat("--- Table 5: Robustness ---\n")

etable(did_manuf, binary_manuf, robust_large, weighted_manuf, trend_manuf, placebo_manuf,
       headers = c("Baseline", "Binary", "Large Only", "Weighted", "Trend Adj.", "Placebo"),
       tex = TRUE,
       file = "../tables/tab5_robustness.tex",
       title = "Robustness Checks: Secondary Sector Share",
       label = "tab:robustness",
       notes = paste0(
         "(1)~Baseline continuous-treatment specification. ",
         "(2)~Binary treatment: municipalities above/below 30\\% manufacturing threshold. ",
         "(3)~Restricts sample to municipalities with $\\geq$100 employees in 2014. ",
         "(4)~Weighted by 2014 total employment. ",
         "(5)~Controls for municipality-specific linear time trends. ",
         "(6)~Placebo test using pre-period data only (2011--2014) with fake shock at 2013. ",
         "All specifications include municipality and year FE. Standard errors clustered at ",
         "the municipality level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"))
cat("  Written: tables/tab5_robustness.tex\n")

## ==============================
## Table F1: Standardized Effect Sizes (SDE Appendix)
## ==============================
cat("--- Table F1: SDE Appendix ---\n")

# Compute SDEs for main outcomes
# SDE = beta * SD(X) / SD(Y) for continuous treatment
# X = manuf_share_2014, Y = outcome

pre_data <- panel[year < 2015]
sd_x <- sd(panel[year == 2014]$manuf_share_2014, na.rm = TRUE)

compute_sde <- function(mod, outcome_var, panel_data) {
  pre <- panel_data[year < 2015]
  sd_y <- sd(pre[[outcome_var]], na.rm = TRUE)
  beta <- coef(mod)[1]
  se_beta <- se(mod)[1]
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s < 0.005) return("Null")
    if (s < 0.05) return("Small positive")
    if (s < 0.15) return("Moderate positive")
    return("Large positive")
  }

  list(beta = beta, se = se_beta, sd_y = sd_y, sde = sde, se_sde = se_sde,
       class = classify(sde))
}

sde_manuf  <- compute_sde(did_manuf, "manuf_share", panel)
sde_serv   <- compute_sde(did_service, "service_share", panel)
sde_log_sec <- compute_sde(did_log_sec, "log_emp_secondary", panel)
sde_log_tert <- compute_sde(did_log_tert, "log_emp_tertiary", panel)

# Heterogeneity: split by municipality size (above/below median employment)
med_emp <- median(panel[year == 2014]$emp_total_2014, na.rm = TRUE)
panel[, large_mun := as.integer(emp_total_2014 >= med_emp)]

het_large <- feols(manuf_share ~ manuf_share_2014:post | gem_id + year,
                   data = panel[large_mun == 1], cluster = ~gem_id)
het_small <- feols(manuf_share ~ manuf_share_2014:post | gem_id + year,
                   data = panel[large_mun == 0], cluster = ~gem_id)

sde_large <- compute_sde(het_large, "manuf_share", panel[large_mun == 1])
sde_small <- compute_sde(het_small, "manuf_share", panel[large_mun == 0])

# Build SDE table
fmt4 <- function(x) formatC(x, format = "f", digits = 4)

sde_rows <- list(
  list(name = "Secondary sector share", sde = sde_manuf),
  list(name = "Tertiary sector share", sde = sde_serv),
  list(name = "Log secondary employment", sde = sde_log_sec),
  list(name = "Log tertiary employment", sde = sde_log_tert)
)

het_rows <- list(
  list(name = "Sec. share (large municipalities)", sde = sde_large),
  list(name = "Sec. share (small municipalities)", sde = sde_small)
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the January 2015 franc appreciation cause permanent structural transformation ",
  "in manufacturing-heavy Swiss municipalities, shifting employment toward services? ",
  "\\textbf{Policy mechanism:} The Swiss National Bank's unexpected removal of the EUR/CHF 1.20 floor on January 15, 2015 ",
  "caused an instant 15\\% franc appreciation, raising the relative cost of Swiss manufactured exports in euro markets ",
  "and differentially exposing municipalities with concentrated secondary-sector employment. ",
  "\\textbf{Outcome definition:} Municipality-level secondary-sector employment share (secondary employment divided by total employment) ",
  "from the BFS Structural Business Statistics (STATENT). ",
  "\\textbf{Treatment:} Continuous; municipality's 2014 secondary-sector employment share (pre-determined). ",
  "\\textbf{Data:} BFS STATENT, 2011--2023, municipality-year panel, ", formatC(nrow(panel), big.mark = ","), " observations across ",
  uniqueN(panel$gem_id), " municipalities. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with municipality and year fixed effects; ",
  "standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} All Swiss municipalities with positive employment in 2014; municipalities with zero 2014 employment excluded. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of ",
  "2014 manufacturing share and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "[3pt]\n"
)

for (r in sde_rows) {
  s <- r$sde
  tab_sde <- paste0(tab_sde,
    r$name, " & ", fmt4(s$beta), " & ", fmt4(s$se), " & ", fmt4(s$sd_y),
    " & ", fmt4(s$sde), " & ", fmt4(s$se_sde), " & ", s$class, " \\\\\n")
}

tab_sde <- paste0(tab_sde,
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by municipality size)}} \\\\\n",
  "[3pt]\n"
)

for (r in het_rows) {
  s <- r$sde
  tab_sde <- paste0(tab_sde,
    r$name, " & ", fmt4(s$beta), " & ", fmt4(s$se), " & ", fmt4(s$sd_y),
    " & ", fmt4(s$sde), " & ", fmt4(s$se_sde), " & ", s$class, " \\\\\n")
}

tab_sde <- paste0(tab_sde,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab_sde, "../tables/tabF1_sde.tex")
cat("  Written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
