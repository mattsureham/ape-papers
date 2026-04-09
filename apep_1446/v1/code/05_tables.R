## 05_tables.R — Generate all tables including SDE appendix
## apep_1446: X-waiver elimination and buprenorphine desert entry

source("00_packages.R")

DATA <- "../data"
TABLES <- "../tables"
dir.create(TABLES, showWarnings = FALSE, recursive = TRUE)

## ---- Load results ----
results <- readRDS(file.path(DATA, "main_results.rds"))
rob_results <- readRDS(file.path(DATA, "robustness_results.rds"))
panel <- as.data.table(read_parquet(file.path(DATA, "county_month_panel.parquet")))
new_npi_county <- as.data.table(read_parquet(file.path(DATA, "new_npi_county.parquet")))
npi_entry <- as.data.table(read_parquet(file.path(DATA, "npi_entry.parquet")))

panel <- panel[ym >= as.Date("2020-01-01") & ym <= as.Date("2024-06-01")]
panel[, post_num := as.integer(ym >= as.Date("2023-01-01"))]
panel[, desert_num := as.integer(desert)]

## ============================================================================
## TABLE 1: Summary Statistics
## ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-period stats by desert status
pre_panel <- panel[ym < as.Date("2023-01-01")]
post_panel <- panel[ym >= as.Date("2023-01-01")]

sum_stats <- rbind(
  pre_panel[, .(
    Period = "Pre (2020--2022)",
    Group = "Desert",
    Counties = uniqueN(county_fips[desert == TRUE]),
    `Mean Active NPIs` = sprintf("%.3f", mean(active_npis[desert == TRUE])),
    `Mean New Entrants/mo` = sprintf("%.4f", mean(new_entrants[desert == TRUE])),
    `Mean Beneficiaries` = sprintf("%.2f", mean(total_bene[desert == TRUE]))
  )],
  pre_panel[, .(
    Period = "Pre (2020--2022)",
    Group = "Non-Desert",
    Counties = uniqueN(county_fips[desert == FALSE]),
    `Mean Active NPIs` = sprintf("%.3f", mean(active_npis[desert == FALSE])),
    `Mean New Entrants/mo` = sprintf("%.4f", mean(new_entrants[desert == FALSE])),
    `Mean Beneficiaries` = sprintf("%.2f", mean(total_bene[desert == FALSE]))
  )],
  post_panel[, .(
    Period = "Post (2023--2024)",
    Group = "Desert",
    Counties = uniqueN(county_fips[desert == TRUE]),
    `Mean Active NPIs` = sprintf("%.3f", mean(active_npis[desert == TRUE])),
    `Mean New Entrants/mo` = sprintf("%.4f", mean(new_entrants[desert == TRUE])),
    `Mean Beneficiaries` = sprintf("%.2f", mean(total_bene[desert == TRUE]))
  )],
  post_panel[, .(
    Period = "Post (2023--2024)",
    Group = "Non-Desert",
    Counties = uniqueN(county_fips[desert == FALSE]),
    `Mean Active NPIs` = sprintf("%.3f", mean(active_npis[desert == FALSE])),
    `Mean New Entrants/mo` = sprintf("%.4f", mean(new_entrants[desert == FALSE])),
    `Mean Beneficiaries` = sprintf("%.2f", mean(total_bene[desert == FALSE]))
  )]
)

# Write as LaTeX
tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Buprenorphine Provider Activity by County Type}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llcccc}",
  "\\hline\\hline",
  "Period & Group & Counties & Mean Active & Mean New & Mean \\\\",
  " & & & NPIs & Entrants/mo & Beneficiaries \\\\",
  "\\hline"
)

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i]
  tab1_tex <- c(tab1_tex, sprintf("%s & %s & %s & %s & %s & %s \\\\",
                                   row$Period, row$Group, row$Counties,
                                   row$`Mean Active NPIs`, row$`Mean New Entrants/mo`,
                                   row$`Mean Beneficiaries`))
  if (i == 2) tab1_tex <- c(tab1_tex, "\\hline")
}

tab1_tex <- c(tab1_tex,
              "\\hline\\hline",
              "\\end{tabular}",
              paste0("\\begin{tablenotes}[flushleft]\\small"),
              paste0("\\item \\textit{Notes:} Desert counties are defined as counties with zero buprenorphine-billing ",
                     "NPIs in the 12 months prior to January 2023. Active NPIs counts distinct providers billing ",
                     "buprenorphine J-codes (J0571--J0575) in a given month. New entrants are NPIs billing buprenorphine ",
                     "for the first time. Data: T-MSIS Medicaid Provider Spending (2020--2024)."),
              "\\end{tablenotes}",
              "\\end{table}")

writeLines(tab1_tex, file.path(TABLES, "tab1_summary.tex"))

## ============================================================================
## TABLE 2: Main DiD Results
## ============================================================================
cat("Generating Table 2: Main DiD Results...\n")

etable(results$did_main, results$did_active, results$did_bene,
       results$did_both,
       tex = TRUE,
       file = file.path(TABLES, "tab2_did_main.tex"),
       title = "X-Waiver Elimination and Buprenorphine Provider Entry",
       headers = c("New Entrants", "Active NPIs", "Beneficiaries", "2021 + 2023"),
       label = "tab:did_main",
       notes = paste("County $\\times$ month panel, 2020--2024.",
                     "Desert = zero buprenorphine-billing NPIs in 2022.",
                     "Standard errors clustered at county level in parentheses.",
                     "Column (4) separately identifies the April 2021 partial X-waiver relaxation",
                     "and the January 2023 full elimination."),
       style.tex = style.tex("aer"),
       fitstat = c("n", "r2", "ar2"))

## ============================================================================
## TABLE 3: Where New Entrants Go (Cross-Section)
## ============================================================================
cat("Generating Table 3: Entrant Destinations...\n")

dest_stats <- new_npi_county[, .(N = .N), by = is_desert]
dest_stats[, pct := sprintf("%.1f", 100 * N / sum(N))]

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Destination of New Buprenorphine Providers After X-Waiver Elimination}",
  "\\label{tab:destinations}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Destination & New Entrants & Share (\\%) \\\\",
  "\\hline",
  sprintf("Desert counties (0 prior NPIs) & %d & %s \\\\",
          dest_stats[is_desert == TRUE, N], dest_stats[is_desert == TRUE, pct]),
  sprintf("Non-desert counties ($\\geq$1 prior NPI) & %d & %s \\\\",
          dest_stats[is_desert == FALSE, N], dest_stats[is_desert == FALSE, pct]),
  "\\hline",
  sprintf("Total new entrants & %d & 100.0 \\\\", sum(dest_stats$N)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} New entrants are NPIs billing buprenorphine J-codes (J0571--J0575) ",
         "for the first time on or after January 2023. Desert counties had zero buprenorphine-billing ",
         "NPIs in the 12 months prior to January 2023. Provider location from NPPES practice address ",
         "mapped to county via Census ZCTA-to-county crosswalk."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, file.path(TABLES, "tab3_destinations.tex"))

## ============================================================================
## TABLE 4: Robustness
## ============================================================================
cat("Generating Table 4: Robustness...\n")

etable(results$did_main, rob_results$did_d1, rob_results$did_d2,
       results$did_short, rob_results$did_placebo,
       tex = TRUE,
       file = file.path(TABLES, "tab4_robustness.tex"),
       title = "Robustness: Alternative Desert Definitions, Short Window, and Placebo",
       headers = c("Baseline", "Desert $\\leq$1", "Desert $\\leq$2",
                   "Short Window", "Placebo (J1745)"),
       label = "tab:robustness",
       notes = paste("All specifications include county and year-month fixed effects.",
                     "Column (1): baseline (desert = 0 NPIs in 2022).",
                     "Column (2): desert redefined as $\\leq$1 NPI.",
                     "Column (3): desert redefined as $\\leq$2 NPIs.",
                     "Column (4): restricted to Jan 2022--Mar 2023 (pre-Medicaid unwinding).",
                     "Column (5): placebo test using infliximab (J1745), a non-OUD injectable.",
                     sprintf("Permutation inference p-value (500 draws): %.3f.",
                             rob_results$perm_p),
                     "Standard errors clustered at county level."),
       style.tex = style.tex("aer"),
       fitstat = c("n", "r2"))

## ============================================================================
## TABLE 5: New Entrant Survival
## ============================================================================
cat("Generating Table 5: Survival...\n")

surv <- rob_results$surv_stats

tab5_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{New Entrant Persistence: Survival Beyond Six Months}",
  "\\label{tab:survival}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Location & N & Survived 6mo & Survival Rate & Median Active Months \\\\",
  "\\hline"
)

for (i in 1:nrow(surv)) {
  loc <- ifelse(surv$is_desert[i], "Desert counties", "Non-desert counties")
  tab5_tex <- c(tab5_tex, sprintf("%s & %d & %d & %.1f\\%% & %.0f \\\\",
                                   loc, surv$n[i], surv$survived[i],
                                   100 * surv$surv_rate[i], surv$median_months[i]))
}

tab5_tex <- c(tab5_tex,
              "\\hline\\hline",
              "\\end{tabular}",
              "\\begin{tablenotes}[flushleft]\\small",
              paste0("\\item \\textit{Notes:} Survival defined as billing buprenorphine J-codes at least ",
                     "6 months after first billing date. Median active months counts distinct months with ",
                     "any buprenorphine billing. Sample restricted to NPIs first billing on or after ",
                     "January 2023."),
              "\\end{tablenotes}",
              "\\end{table}"
)

writeLines(tab5_tex, file.path(TABLES, "tab5_survival.tex"))

## ============================================================================
## SDE APPENDIX TABLE (tabF1_sde.tex)
## ============================================================================
cat("Generating SDE table...\n")

# Get main coefficients and SDs
did_m <- results$did_main
did_a <- results$did_active
did_b <- results$did_bene

# Pre-treatment SD: use non-desert counties (desert counties have zero variance for entry)
pre_nondesert <- panel[desert == FALSE & ym < as.Date("2023-01-01")]
sd_entry <- sd(pre_nondesert$new_entrants)
sd_active <- sd(pre_nondesert$active_npis)
sd_bene <- sd(pre_nondesert$total_bene)
# If still zero, use post-treatment SD as fallback
if (sd_entry == 0) sd_entry <- sd(panel[desert == FALSE, new_entrants])
cat(sprintf("Pre-treatment SDs (non-desert): entry=%.4f, active=%.4f, bene=%.4f\n", sd_entry, sd_active, sd_bene))

# Coefficients
beta_entry <- coef(did_m)["desert_num:post_num"]
se_entry <- se(did_m)["desert_num:post_num"]
beta_active <- coef(did_a)["desert_num:post_num"]
se_active <- se(did_a)["desert_num:post_num"]
beta_bene <- coef(did_b)["desert_num:post_num"]
se_bene <- se(did_b)["desert_num:post_num"]

# SDE = beta / SD(Y)
sde_entry <- beta_entry / sd_entry
se_sde_entry <- se_entry / sd_entry
sde_active <- beta_active / sd_active
se_sde_active <- se_active / sd_active
sde_bene <- beta_bene / sd_bene
se_sde_bene <- se_bene / sd_bene

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde) || !is.finite(sde)) return("N/A")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Build rows
sde_rows <- data.table(
  Outcome = c("New entrants (count)", "Active NPIs (count)", "Beneficiaries (count)"),
  beta = c(beta_entry, beta_active, beta_bene),
  se = c(se_entry, se_active, se_bene),
  sd_y = c(sd_entry, sd_active, sd_bene),
  sde = c(sde_entry, sde_active, sde_bene),
  se_sde = c(se_sde_entry, se_sde_active, se_sde_bene)
)
sde_rows[, classification := sapply(sde, classify_sde)]

# Panel B: Heterogeneity — split by HPSA status
# Run full DiD on HPSA-designated counties vs non-HPSA counties
hpsa_counties <- readRDS(file.path(DATA, "hpsa_mh_counties.rds"))
panel[, hpsa := as.integer(county_fips %in% hpsa_counties)]

# Subsample: HPSA counties only
hpsa_panel <- panel[hpsa == 1]
hpsa_panel[, ym_fe := as.factor(ym)]
hpsa_panel[, county_fe := as.factor(county_fips)]

did_hpsa <- feols(new_entrants ~ desert_num:post_num | county_fe + ym_fe,
                  data = hpsa_panel, cluster = ~county_fips)

# Subsample: non-HPSA counties only
nonhpsa_panel <- panel[hpsa == 0]
nonhpsa_panel[, ym_fe := as.factor(ym)]
nonhpsa_panel[, county_fe := as.factor(county_fips)]

did_nonhpsa <- feols(new_entrants ~ desert_num:post_num | county_fe + ym_fe,
                     data = nonhpsa_panel, cluster = ~county_fips)

het_beta1 <- coef(did_hpsa)["desert_num:post_num"]
het_se1 <- se(did_hpsa)["desert_num:post_num"]
het_sd1 <- sd_entry
het_sde1 <- het_beta1 / het_sd1
het_sesde1 <- het_se1 / het_sd1

het_beta2 <- coef(did_nonhpsa)["desert_num:post_num"]
het_se2 <- se(did_nonhpsa)["desert_num:post_num"]
het_sd2 <- sd_entry
het_sde2 <- het_beta2 / het_sd2
het_sesde2 <- het_se2 / het_sd2

het_rows <- data.table(
  Outcome = c("New entrants (HPSA counties)", "New entrants (non-HPSA counties)"),
  beta = c(het_beta1, het_beta2),
  se = c(het_se1, het_se2),
  sd_y = c(het_sd1, het_sd2),
  sde = c(het_sde1, het_sde2),
  se_sde = c(het_sesde1, het_sesde2)
)
het_rows[, classification := sapply(sde, classify_sde)]

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the January 2023 elimination of the X-waiver requirement for buprenorphine prescribing cause new providers to enter treatment-desert counties or cluster in already-served markets? ",
  "\\textbf{Policy mechanism:} The Consolidated Appropriations Act of 2023 removed the DATA 2000 X-waiver requirement, allowing any DEA Schedule III registrant to prescribe buprenorphine for opioid use disorder without prior training certification or patient caps, eliminating the credentialing barrier that previously limited prescriber supply. ",
  "\\textbf{Outcome definition:} New entrants counts the number of distinct NPIs billing injectable buprenorphine Medicaid claims (J0571--J0575) for the first time in a given county-month; active NPIs counts all distinct billing NPIs; beneficiaries counts unique Medicaid beneficiaries receiving buprenorphine in a county-month. ",
  "\\textbf{Treatment:} Binary (county is treatment desert with zero buprenorphine-billing NPIs in 2022 vs.\\ non-desert with at least one). ",
  "\\textbf{Data:} T-MSIS Medicaid Provider Spending (HHS), January 2020--June 2024, county-month panel; provider location from NPPES practice ZIP mapped to county FIPS via Census ZCTA-to-county crosswalk. ",
  "\\textbf{Method:} Two-way fixed effects DiD (county + year-month FE), standard errors clustered at county level; pre-trend validation via event study and joint F-test; permutation inference (500 draws). ",
  "\\textbf{Sample:} All U.S.\\ counties with at least one NPI in NPPES; desert counties defined as zero buprenorphine-billing NPIs in 12 months before January 2023. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome in non-desert counties (used as denominator because desert counties have near-zero pre-treatment variance). Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: X-Waiver Elimination and Provider Desert Entry}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows)) {
  sde_tex <- c(sde_tex, sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
                                 sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se[i],
                                 sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
                                 sde_rows$classification[i]))
}

sde_tex <- c(sde_tex,
             "\\hline",
             "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\")

for (i in 1:nrow(het_rows)) {
  sde_tex <- c(sde_tex, sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
                                 het_rows$Outcome[i], het_rows$beta[i], het_rows$se[i],
                                 het_rows$sd_y[i], het_rows$sde[i], het_rows$se_sde[i],
                                 het_rows$classification[i]))
}

sde_tex <- c(sde_tex,
             "\\hline\\hline",
             "\\end{tabular}",
             "\\begin{tablenotes}[flushleft]\\small",
             sde_notes,
             "\\end{tablenotes}",
             "\\end{table}")

writeLines(sde_tex, file.path(TABLES, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
cat(sprintf("Files in %s:\n", TABLES))
cat(paste(list.files(TABLES), collapse = "\n"))
cat("\n")
