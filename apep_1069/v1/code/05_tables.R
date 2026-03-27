## 05_tables.R — Generate all LaTeX tables including SDE appendix
## apep_1069: The Compensation Cliff

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

panel <- panel %>%
  mutate(
    rel_year = year - 2020,
    year_factor = factor(year),
    tercile_2 = as.integer(exposure_tercile == 2),
    tercile_3 = as.integer(exposure_tercile == 3),
    q2 = as.integer(exposure_quartile == 2),
    q3 = as.integer(exposure_quartile == 3),
    q4 = as.integer(exposure_quartile == 4)
  )

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

pre <- panel %>% filter(year <= 2020)
post <- panel %>% filter(year >= 2021)

summ_data <- pre %>%
  group_by(Group = ifelse(treated_median == 1, "High Exposure", "Low Exposure")) %>%
  summarise(
    `N Buurten` = n_distinct(buurt_code),
    `Mean WOZ (000s EUR)` = sprintf("%.1f", mean(woz, na.rm = TRUE)),
    `SD WOZ` = sprintf("%.1f", sd(woz, na.rm = TRUE)),
    `Mean Dwellings` = sprintf("%.0f", mean(n_dwellings, na.rm = TRUE)),
    `Owner-Occ. (\\%)` = sprintf("%.1f", mean(pct_owner, na.rm = TRUE)),
    `Cum. PGA` = sprintf("%.1f", mean(cum_pga, na.rm = TRUE)),
    `Earthquakes (10km)` = sprintf("%.0f", mean(n_earthquakes_10km, na.rm = TRUE)),
    .groups = "drop"
  )

# Write LaTeX table
tab1 <- "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Treatment Period (2016--2020)}
\\label{tab:summary}
\\begin{tabular}{lcc}
\\hline\\hline
 & High Exposure & Low Exposure \\\\
\\hline"

for (i in 2:ncol(summ_data)) {
  tab1 <- paste0(tab1, "\n", names(summ_data)[i], " & ",
                 summ_data[[i]][summ_data$Group == "High Exposure"], " & ",
                 summ_data[[i]][summ_data$Group == "Low Exposure"], " \\\\")
}

tab1 <- paste0(tab1, "
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} High Exposure = neighborhoods with above-median cumulative peak ground acceleration (PGA) from Groningen gas field earthquakes. WOZ = Waardering Onroerende Zaken (property tax assessment), reflecting market value as of January~1 each year. Cumulative PGA calculated from 1,637 induced seismic events (1986--2020) using a simplified Groningen GMPE. Data from CBS Kerncijfers wijken en buurten and KNMI earthquake catalog.
\\end{tablenotes}
\\end{table}")

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================================
# Table 2: Main DiD Results
# ============================================================================
cat("=== Generating Table 2: Main Results ===\n")

# Re-run models for clean table output
did1 <- feols(woz ~ treated_median:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)
did2 <- feols(log_woz ~ treated_median:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)
did3 <- feols(woz ~ log_cum_pga:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)
did4 <- feols(log_woz ~ log_cum_pga:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

# Manual LaTeX table for precise control
coefs <- list(did1, did2, did3, did4)
beta_vals <- sapply(coefs, function(m) coef(m)[1])
se_vals <- sapply(coefs, function(m) sqrt(diag(vcov(m)))[1])
n_vals <- sapply(coefs, nobs)
r2_vals <- sapply(coefs, function(m) fitstat(m, "wr2")$wr2)

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}
pvals <- sapply(coefs, function(m) {
  t <- coef(m)[1] / sqrt(diag(vcov(m)))[1]
  2 * pt(-abs(t), df = nobs(m) - length(coef(m)) - fixef(m)$buurt_code - fixef(m)$year)
})

tab2 <- paste0("\\begin{table}[htbp]
\\centering
\\caption{Effect of Earthquake Exposure on Property Values After Compensation Announcement}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) \\\\
 & WOZ & Log WOZ & WOZ & Log WOZ \\\\
\\hline
High Exposure $\\times$ Post & ", sprintf("%.3f%s", beta_vals[1], stars(pvals[1])),
" & ", sprintf("%.4f%s", beta_vals[2], stars(pvals[2])), " & & \\\\
 & (", sprintf("%.3f", se_vals[1]), ") & (", sprintf("%.4f", se_vals[2]), ") & & \\\\[6pt]
Log(Cum.\\ PGA) $\\times$ Post & & & ", sprintf("%.3f%s", beta_vals[3], stars(pvals[3])),
" & ", sprintf("%.4f%s", beta_vals[4], stars(pvals[4])), " \\\\
 & & & (", sprintf("%.3f", se_vals[3]), ") & (", sprintf("%.4f", se_vals[4]), ") \\\\[6pt]
\\hline
Buurt FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Observations & ", format(n_vals[1], big.mark = ","), " & ", format(n_vals[2], big.mark = ","),
" & ", format(n_vals[3], big.mark = ","), " & ", format(n_vals[4], big.mark = ","), " \\\\
Within $R^2$ & ", sprintf("%.4f", r2_vals[1]), " & ", sprintf("%.4f", r2_vals[2]),
" & ", sprintf("%.4f", r2_vals[3]), " & ", sprintf("%.4f", r2_vals[4]), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable is average WOZ property valuation (in thousands of EUR) or its natural log at the buurt (neighborhood) level. High Exposure = above-median cumulative PGA. Post = year $\\geq$ 2021 (WOZ values reflecting market conditions after September 2020 compensation announcement). Standard errors clustered at the buurt level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}")

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================
cat("=== Generating Table 3: Event Study ===\n")

es1 <- feols(woz ~ i(year_factor, treated_median, ref = "2020") |
               buurt_code + year,
             data = panel, cluster = ~buurt_code)

es_c <- coef(es1)
es_s <- sqrt(diag(vcov(es1)))
es_t <- es_c / es_s
es_p <- 2 * pt(-abs(es_t), df = nobs(es1) - 100)  # approximate

years_es <- c(2016, 2017, 2018, 2019, 2021, 2023)
labels_es <- c("2016", "2017", "2018", "2019", "2021", "2023")

tab3_rows <- ""
for (i in seq_along(years_es)) {
  tab3_rows <- paste0(tab3_rows,
    labels_es[i], " $\\times$ High Exposure & ",
    sprintf("%.3f%s", es_c[i], stars(es_p[i])), " \\\\
 & (", sprintf("%.3f", es_s[i]), ") \\\\[3pt]\n")
}

tab3 <- paste0("\\begin{table}[htbp]
\\centering
\\caption{Event Study: Year-by-Year Effects of Earthquake Exposure on WOZ Values}
\\label{tab:event_study}
\\begin{tabular}{lc}
\\hline\\hline
 & WOZ (000s EUR) \\\\
\\hline
", tab3_rows, "\\hline
Reference year & 2020 \\\\
Buurt FE & Yes \\\\
Year FE & Yes \\\\
Observations & ", format(nobs(es1), big.mark = ","), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each coefficient represents the differential WOZ change in high-exposure neighborhoods relative to low-exposure neighborhoods, compared to the reference year 2020 (last pre-announcement year). The September 2020 compensation announcement affects WOZ values from 2021 onward (WOZ reference date is January~1). Standard errors clustered at buurt level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}")

writeLines(tab3, file.path(tables_dir, "tab3_event_study.tex"))
cat("Table 3 written.\n")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Generating Table 4: Robustness ===\n")

# Placebo
plac <- rob_results$placebo_2018
# Groningen only
panel_gron <- panel %>% filter(gemeente %in% readRDS(file.path(data_dir, "study_municipalities.rds"))$groningen)
gron <- feols(woz ~ treated_median:post | buurt_code + year,
              data = panel_gron, cluster = ~buurt_code)
# Dose response
dose <- rob_results$dose_response

tab4 <- paste0("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{lccc}
\\hline\\hline
 & (1) & (2) & (3) \\\\
 & Placebo (2018) & Groningen Only & Dose-Response \\\\
\\hline
High Exp.\\ $\\times$ Fake Post & ", sprintf("%.3f", coef(plac)[1]),
" & & \\\\
 & (", sprintf("%.3f", sqrt(diag(vcov(plac)))[1]), ") & & \\\\[6pt]
High Exp.\\ $\\times$ Post & & ", sprintf("%.3f", coef(gron)[1]),
" & \\\\
 & & (", sprintf("%.3f", sqrt(diag(vcov(gron)))[1]), ") & \\\\[6pt]
Q2 $\\times$ Post & & & ", sprintf("%.3f%s", coef(dose)[1], stars(2*pt(-abs(coef(dose)[1]/sqrt(diag(vcov(dose)))[1]), 500))),
" \\\\
 & & & (", sprintf("%.3f", sqrt(diag(vcov(dose)))[1]), ") \\\\[3pt]
Q3 $\\times$ Post & & & ", sprintf("%.3f", coef(dose)[2]),
" \\\\
 & & & (", sprintf("%.3f", sqrt(diag(vcov(dose)))[2]), ") \\\\[3pt]
Q4 $\\times$ Post & & & ", sprintf("%.3f%s", coef(dose)[3], stars(2*pt(-abs(coef(dose)[3]/sqrt(diag(vcov(dose)))[3]), 500))),
" \\\\
 & & & (", sprintf("%.3f", sqrt(diag(vcov(dose)))[3]), ") \\\\[6pt]
\\hline
Sample & Pre-2021 & Groningen & Full \\\\
Buurt FE & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes \\\\
Obs. & ", format(nobs(plac), big.mark = ","),
" & ", format(nobs(gron), big.mark = ","),
" & ", format(nobs(dose), big.mark = ","), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column~(1) assigns placebo treatment at 2018, using only pre-announcement data. Column~(2) restricts to Groningen province municipalities. Column~(3) replaces binary treatment with quartile indicators of cumulative earthquake exposure (Q1 = lowest). Standard errors clustered at buurt level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{table}")

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

# ============================================================================
# Table F1: SDE Appendix (MANDATORY)
# ============================================================================
cat("=== Generating SDE Table ===\n")

sd_y <- results$sd_y_pre
sd_y_log <- results$sd_y_pre_log

# Main outcomes for SDE table
sde_rows <- data.frame(
  outcome = c("WOZ Value (000s EUR)", "Log WOZ Value",
              "WOZ -- Groningen Only", "WOZ -- High Owner-Occ."),
  beta = c(coef(did1)[1], coef(did2)[1],
           coef(gron)[1], NA),
  se = c(sqrt(diag(vcov(did1)))[1], sqrt(diag(vcov(did2)))[1],
         sqrt(diag(vcov(gron)))[1], NA),
  sd_y = c(sd_y, sd_y_log, sd(panel_gron$woz[panel_gron$year <= 2020], na.rm=TRUE), NA)
)

# Calculate high owner-occupancy separately
med_own <- median(panel$pct_owner, na.rm = TRUE)
panel_ho <- panel %>% filter(pct_owner >= med_own)
if (nrow(panel_ho) > 100) {
  did_ho <- feols(woz ~ treated_median:post | buurt_code + year,
                  data = panel_ho, cluster = ~buurt_code)
  sde_rows$beta[4] <- coef(did_ho)[1]
  sde_rows$se[4] <- sqrt(diag(vcov(did_ho)))[1]
  sde_rows$sd_y[4] <- sd(panel_ho$woz[panel_ho$year <= 2020], na.rm=TRUE)
}

sde_rows <- sde_rows %>%
  filter(!is.na(beta)) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

cat("\nSDE Summary:\n")
print(sde_rows %>% select(outcome, beta, se, sd_y, sde, se_sde, classification))

# Build LaTeX SDE table
sde_body <- ""
for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  sde_body <- paste0(sde_body,
    r$outcome, " & ",
    sprintf("%.3f", r$beta), " & ",
    sprintf("%.3f", r$se), " & ",
    sprintf("%.2f", r$sd_y), " & ",
    sprintf("%.4f", r$sde), " & ",
    sprintf("%.4f", r$se_sde), " & ",
    r$classification, " \\\\\n")
}

# Heterogeneity panel: Groningen vs Border provinces
sde_het_rows <- data.frame(
  outcome = character(), beta = numeric(), se = numeric(),
  sd_y = numeric(), stringsAsFactors = FALSE
)

# Groningen subgroup
sde_het_rows <- rbind(sde_het_rows, data.frame(
  outcome = "WOZ -- Groningen Province",
  beta = coef(gron)[1],
  se = sqrt(diag(vcov(gron)))[1],
  sd_y = sd(panel_gron$woz[panel_gron$year <= 2020], na.rm = TRUE)
))

# Border provinces
panel_border <- panel %>%
  filter(gemeente %in% c(readRDS(file.path(data_dir, "study_municipalities.rds"))$drenthe_border,
                          readRDS(file.path(data_dir, "study_municipalities.rds"))$friesland_border))
if (nrow(panel_border) > 100) {
  did_border <- feols(woz ~ treated_median:post | buurt_code + year,
                      data = panel_border, cluster = ~buurt_code)
  sde_het_rows <- rbind(sde_het_rows, data.frame(
    outcome = "WOZ -- Border Provinces",
    beta = coef(did_border)[1],
    se = sqrt(diag(vcov(did_border)))[1],
    sd_y = sd(panel_border$woz[panel_border$year <= 2020], na.rm = TRUE)
  ))
}

sde_het_rows <- sde_het_rows %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

sde_het_body <- ""
for (i in 1:nrow(sde_het_rows)) {
  r <- sde_het_rows[i, ]
  sde_het_body <- paste0(sde_het_body,
    r$outcome, " & ",
    sprintf("%.3f", r$beta), " & ",
    sprintf("%.3f", r$se), " & ",
    sprintf("%.2f", r$sd_y), " & ",
    sprintf("%.4f", r$sde), " & ",
    sprintf("%.4f", r$se_sde), " & ",
    r$classification, " \\\\\n")
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} The Netherlands. ",
  "\\textbf{Research question:} Does the announcement of government earthquake damage compensation (IMG Waardedalingsregeling) capitalize into neighborhood-level property values in the Groningen gas extraction region? ",
  "\\textbf{Policy mechanism:} The Waardedalingsregeling, enacted September 2020 under the Tijdelijke wet Groningen, compensates homeowners in designated postcodes for 2.07--12.22\\% of property value decline caused by induced seismicity from the Groningen gas field; eligibility is determined by a 20\\% damage-claim filing rate threshold at the 4-digit postcode level, with payments retroactive to January 2013 sales. ",
  "\\textbf{Outcome definition:} Average WOZ (Waardering Onroerende Zaken) property tax assessment value per buurt (neighborhood), reflecting assessed market value as of January~1 each year, in thousands of EUR. ",
  "\\textbf{Treatment:} Binary indicator for neighborhoods with above-median cumulative peak ground acceleration (PGA) from 1,637 pre-2020 induced seismic events, calculated using a Groningen-specific ground motion prediction equation. ",
  "\\textbf{Data:} CBS Kerncijfers wijken en buurten (2016--2023) merged with KNMI induced earthquake catalog (1986--2025) and PDOK buurt shapefiles; 1,104 neighborhoods, 5,417 buurt-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (buurt + year), standard errors clustered at buurt level. ",
  "\\textbf{Sample:} Neighborhoods in Groningen province and adjacent Drenthe/Friesland border municipalities with non-missing WOZ data and at least 20 dwellings. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes: Earthquake Compensation and Property Values}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
", sde_body, "\\hline
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Geographic Subsamples)}} \\\\[3pt]
", sde_het_body, "\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{table}")

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table written.\n")

cat("\n=== All tables generated ===\n")
