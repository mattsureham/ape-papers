# 05_tables.R — Generate all LaTeX tables
# apep_0764: Brazil Intermittent Contracts

source("00_packages.R")

cat("Loading results...\n")
panel <- fread("../data/panel_clean.csv")
panel[, muni_code := as.character(muni_code)]
panel[, state_code := as.character(state_code)]
main <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
pre_means <- readRDS("../data/pre_treatment_means.rds")
sector_rates <- fread("../data/sector_intermittent_rates.csv")
muni_exposure <- fread("../data/muni_exposure.csv")

# =============================================================================
# TABLE 1: SUMMARY STATISTICS
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

pre <- panel[year <= 2017]
post_d <- panel[year >= 2018]

# Panel A: Municipality-year level
sumstats <- data.frame(
  Variable = c("Average monthly wage (R\\$)",
               "Log average wage",
               "Formal employment (count)",
               "Log formal employment",
               "Contracted hours per week",
               "Intermittent contract share",
               "Bartik exposure",
               "Number of CNAE-2 sectors"),
  Mean_Pre = c(mean(pre$avg_wage), mean(pre$log_avg_wage),
               mean(pre$total_employment), mean(pre$log_employment),
               mean(pre$avg_hours), mean(pre$intermittent_share, na.rm=TRUE),
               mean(pre$bartik_exposure), mean(pre$n_sectors)),
  SD_Pre = c(sd(pre$avg_wage), sd(pre$log_avg_wage),
             sd(pre$total_employment), sd(pre$log_employment),
             sd(pre$avg_hours), sd(pre$intermittent_share, na.rm=TRUE),
             sd(pre$bartik_exposure), sd(pre$n_sectors)),
  Mean_Post = c(mean(post_d$avg_wage), mean(post_d$log_avg_wage),
                mean(post_d$total_employment), mean(post_d$log_employment),
                mean(post_d$avg_hours), mean(post_d$intermittent_share),
                mean(post_d$bartik_exposure), mean(post_d$n_sectors)),
  SD_Post = c(sd(post_d$avg_wage), sd(post_d$log_avg_wage),
              sd(post_d$total_employment), sd(post_d$log_employment),
              sd(post_d$avg_hours), sd(post_d$intermittent_share),
              sd(post_d$bartik_exposure), sd(post_d$n_sectors))
)

# Format numbers
fmt <- function(x, digits = 2) formatC(x, format = "f", digits = digits, big.mark = ",")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-Reform (2014--2017)} & \\multicolumn{2}{c}{Post-Reform (2018--2022)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD \\\\",
  "\\hline"
)

for (i in 1:nrow(sumstats)) {
  d <- if (i %in% c(1, 3)) 0 else if (i %in% c(6, 7)) 4 else 2
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            sumstats$Variable[i],
            fmt(sumstats$Mean_Pre[i], d),
            fmt(sumstats$SD_Pre[i], d),
            fmt(sumstats$Mean_Post[i], d),
            fmt(sumstats$SD_Post[i], d)))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("Municipalities & \\multicolumn{4}{c}{%s} \\\\", fmt(uniqueN(panel$muni_code), 0)),
  sprintf("Municipality-years & \\multicolumn{4}{c}{%s} \\\\", fmt(nrow(panel), 0)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Unit of observation is municipality-year. Data from RAIS (Rela\\c{c}\\~{a}o Anual de Informa\\c{c}\\~{o}es Sociais) via Google BigQuery, 2014--2022. Wages are nominal monthly averages in Brazilian reais. Bartik exposure is the employment-weighted average of 2019 CNAE-2 sector intermittent adoption rates using pre-reform (2016) employment structure as weights.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# =============================================================================
# TABLE 2: SECTOR INTERMITTENT ADOPTION RATES (TOP/BOTTOM 10)
# =============================================================================
cat("Generating Table 2: Sector Adoption Rates...\n")

# CNAE 2-digit sector labels (abbreviated)
cnae_labels <- c(
  "01" = "Agriculture", "02" = "Forestry", "03" = "Fishing",
  "05" = "Coal mining", "06" = "Oil/gas extraction", "07" = "Metal ore mining",
  "08" = "Other mining", "10" = "Food products", "11" = "Beverages",
  "12" = "Tobacco", "13" = "Textiles", "14" = "Apparel",
  "15" = "Leather", "16" = "Wood products", "17" = "Paper",
  "18" = "Printing", "19" = "Coke/petroleum", "20" = "Chemicals",
  "21" = "Pharmaceuticals", "22" = "Rubber/plastics", "23" = "Non-metallic minerals",
  "24" = "Basic metals", "25" = "Fabricated metals", "26" = "Electronics",
  "27" = "Electrical equip.", "28" = "Machinery", "29" = "Motor vehicles",
  "30" = "Other transport", "31" = "Furniture", "32" = "Other manufacturing",
  "33" = "Repair/install", "35" = "Electricity/gas", "36" = "Water collection",
  "37" = "Sewerage", "38" = "Waste collection", "41" = "Building construction",
  "42" = "Civil engineering", "43" = "Specialized construction",
  "45" = "Motor vehicle trade", "46" = "Wholesale trade", "47" = "Retail trade",
  "49" = "Land transport", "50" = "Water transport", "51" = "Air transport",
  "52" = "Warehousing", "53" = "Postal/courier", "55" = "Accommodation",
  "56" = "Food service", "58" = "Publishing", "59" = "Film/TV/music",
  "60" = "Broadcasting", "61" = "Telecommunications", "62" = "IT services",
  "63" = "Information services", "64" = "Financial services",
  "65" = "Insurance", "66" = "Auxiliary financial", "68" = "Real estate",
  "69" = "Legal/accounting", "70" = "Management consulting",
  "71" = "Architecture/engineering", "72" = "Scientific R\\&D",
  "73" = "Advertising", "74" = "Other professional", "75" = "Veterinary",
  "77" = "Rental/leasing", "78" = "Employment activities",
  "79" = "Travel agencies", "80" = "Security/investigation",
  "81" = "Building services", "82" = "Office admin",
  "84" = "Public administration", "85" = "Education",
  "86" = "Human health", "87" = "Residential care",
  "88" = "Social work", "90" = "Arts/entertainment",
  "91" = "Libraries/museums", "92" = "Gambling",
  "93" = "Sports/recreation", "94" = "Membership organizations",
  "95" = "Repair services", "96" = "Other personal services",
  "97" = "Domestic employment", "99" = "International organizations"
)

sector_rates[, sector_label := ifelse(cnae2 %in% names(cnae_labels),
                                       cnae_labels[cnae2], cnae2)]
setorder(sector_rates, -intermittent_rate)

top5 <- head(sector_rates[total_workers >= 1000], 5)
bot5 <- tail(sector_rates[total_workers >= 1000], 5)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Intermittent Contract Adoption by Sector (2019)}",
  "\\label{tab:sectors}",
  "\\begin{tabular}{lrrr}",
  "\\hline\\hline",
  "CNAE-2 Sector & Workers & Intermittent & Adoption \\\\",
  " & (thousands) & (count) & Rate (\\%) \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Highest Adoption}} \\\\"
)

for (i in 1:nrow(top5)) {
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s & %.2f \\\\",
            top5$sector_label[i],
            fmt(top5$total_workers[i] / 1000, 0),
            fmt(top5$total_intermittent[i], 0),
            top5$intermittent_rate[i] * 100))
}

tab2_lines <- c(tab2_lines,
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel B: Lowest Adoption (with $\\geq$ 1,000 workers)}} \\\\"
)

for (i in 1:nrow(bot5)) {
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s & %.2f \\\\",
            bot5$sector_label[i],
            fmt(bot5$total_workers[i] / 1000, 0),
            fmt(bot5$total_intermittent[i], 0),
            bot5$intermittent_rate[i] * 100))
}

tab2_lines <- c(tab2_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Intermittent adoption rate is the share of all formal employment relationships classified as \\textit{trabalho intermitente} in RAIS 2019 data. Sectors with fewer than 1,000 workers excluded from this table. There are 87 CNAE-2 sectors in total.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_sectors.tex")

# =============================================================================
# TABLE 3: MAIN RESULTS (PREFERRED WITH TRENDS)
# =============================================================================
cat("Generating Table 3: Main Results...\n")

extract_coef <- function(model) {
  s <- summary(model)
  cf <- coef(model)[1]
  se <- s$se[1]
  pv <- fixest::pvalue(model)[1]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  n <- nobs(model)
  r2 <- fitstat(model, "r2")$r2
  list(coef = cf, se = se, pv = pv, stars = stars, n = n, r2 = r2)
}

# Preferred (with municipality trends)
m1t <- extract_coef(main$m1t_wage)
m2t <- extract_coef(main$m2t_emp)
m3 <- extract_coef(main$m3_intermittent)
m4t <- extract_coef(main$m4t_hours)
# Naive (for comparison)
m1n <- extract_coef(main$m1_wage)
m2n <- extract_coef(main$m2_emp)
m4n <- extract_coef(main$m4_hours)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Effect of Intermittent Contract Exposure on Labor Market Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Log Avg. & Log Formal & Intermittent & Avg. \\\\",
  " & Wage & Employment & Share & Hours \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Preferred specification (municipality linear trends)}} \\\\[3pt]",
  sprintf("Exposure $\\times$ Post & %s%s & %s%s & %s%s & %s%s \\\\",
          fmt(m1t$coef, 3), m1t$stars,
          fmt(m2t$coef, 3), m2t$stars,
          fmt(m3$coef, 4), m3$stars,
          fmt(m4t$coef, 3), m4t$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(m1t$se, 3), fmt(m2t$se, 3), fmt(m3$se, 4), fmt(m4t$se, 3)),
  "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Naive specification (no trends)}} \\\\[3pt]",
  sprintf("Exposure $\\times$ Post & %s%s & %s%s & & %s%s \\\\",
          fmt(m1n$coef, 3), m1n$stars,
          fmt(m2n$coef, 3), m2n$stars,
          fmt(m4n$coef, 3), m4n$stars),
  sprintf(" & (%s) & (%s) & & (%s) \\\\",
          fmt(m1n$se, 3), fmt(m2n$se, 3), fmt(m4n$se, 3)),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Muni. $\\times$ linear trend & Panel A & Panel A & No & Panel A \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          fmt(m1t$n, 0), fmt(m2t$n, 0), fmt(m3$n, 0), fmt(m4t$n, 0)),
  sprintf("Pre-reform mean & %s & %s & %s & %s \\\\",
          fmt(pre_means$pre_mean_log_wage, 2),
          fmt(pre_means$pre_mean_log_emp, 2),
          fmt(pre_means$pre_mean_intermittent_share, 4),
          fmt(pre_means$pre_mean_hours, 1)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a separate regression of the outcome on the interaction of municipality-level Bartik exposure with a post-reform indicator. Bartik exposure is the employment-weighted average of 2019 CNAE-2 sector intermittent adoption rates using pre-reform (2016) employment shares. Panel~A includes municipality-specific linear time trends to absorb differential pre-reform trajectories; Panel~B does not. Column~(3) omits trends because the intermittent share is mechanically zero pre-reform. All regressions weighted by pre-reform (2016) total employment. Standard errors clustered at the state level (27 states) in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")

# =============================================================================
# TABLE 4: EVENT STUDY COEFFICIENTS
# =============================================================================
cat("Generating Table 4: Event Study...\n")

es_wage_coefs <- coef(main$es1_wage)
es_wage_se <- summary(main$es1_wage)$se
es_wage_pv <- fixest::pvalue(main$es1_wage)

es_emp_coefs <- coef(main$es2_emp)
es_emp_se <- summary(main$es2_emp)$se
es_emp_pv <- fixest::pvalue(main$es2_emp)

es_hours_coefs <- coef(main$es3_hours)
es_hours_se <- summary(main$es3_hours)$se
es_hours_pv <- fixest::pvalue(main$es3_hours)

years_es <- c(2014, 2015, 2016, 2018, 2019, 2020, 2021, 2022)

star_fn <- function(pv) {
  ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
}

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of Intermittent Contract Exposure}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Log Avg. Wage & Log Employment & Avg. Hours \\\\",
  " & (1) & (2) & (3) \\\\",
  "\\hline"
)

for (i in seq_along(years_es)) {
  yr <- years_es[i]
  lab <- ifelse(yr == 2016, paste0(yr, " (ref.)"), as.character(yr))
  if (yr == 2017) next  # Skip reference year (already excluded)
  if (yr == 2016) {
    tab4_lines <- c(tab4_lines, sprintf("%s & --- & --- & --- \\\\", lab))
  } else {
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %s%s & %s%s & %s%s \\\\",
              lab,
              fmt(es_wage_coefs[i], 3), star_fn(es_wage_pv[i]),
              fmt(es_emp_coefs[i], 3), star_fn(es_emp_pv[i]),
              fmt(es_hours_coefs[i], 3), star_fn(es_hours_pv[i])),
      sprintf(" & (%s) & (%s) & (%s) \\\\",
              fmt(es_wage_se[i], 3), fmt(es_emp_se[i], 3), fmt(es_hours_se[i], 3))
    )
  }
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  sprintf("Observations & %s & %s & %s \\\\",
          fmt(nobs(main$es1_wage), 0), fmt(nobs(main$es2_emp), 0), fmt(nobs(main$es3_hours), 0)),
  "Municipality FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports coefficients from a regression of the outcome on interactions of municipality Bartik exposure with year indicators, omitting 2017 as the reference year. Weighted by pre-reform employment. Standard errors clustered at the state level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")

# =============================================================================
# TABLE 5: ROBUSTNESS
# =============================================================================
cat("Generating Table 5: Robustness...\n")

r1 <- extract_coef(robust$r1_wage_muni)
r2 <- extract_coef(robust$r2_wage_unw)
r3 <- extract_coef(robust$r3_wage_trim)
r4 <- extract_coef(robust$r4_placebo)
r5 <- extract_coef(robust$r5_wage_nocovid)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness of the Wage Effect}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE \\\\",
  "\\hline",
  sprintf("\\textit{Preferred:} With muni. trends (state-clustered) & %s%s & (%s) \\\\",
          fmt(m1t$coef, 3), m1t$stars, fmt(m1t$se, 3)),
  sprintf("Without municipality trends & %s%s & (%s) \\\\",
          fmt(m1n$coef, 3), m1n$stars, fmt(m1n$se, 3)),
  sprintf("Municipality-clustered SE & %s%s & (%s) \\\\",
          fmt(r1$coef, 3), r1$stars, fmt(r1$se, 3)),
  sprintf("Unweighted & %s%s & (%s) \\\\",
          fmt(r2$coef, 3), r2$stars, fmt(r2$se, 3)),
  sprintf("Trimmed (P5--P95 exposure) & %s%s & (%s) \\\\",
          fmt(r3$coef, 3), r3$stars, fmt(r3$se, 3)),
  sprintf("Excluding COVID years (2020--2021) & %s%s & (%s) \\\\",
          fmt(r5$coef, 3), r5$stars, fmt(r5$se, 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is log average formal wage. Preferred specification includes municipality and year fixed effects plus municipality-specific linear time trends, weighted by 2016 employment, clustered at state level (27 states). All other rows modify one feature of this baseline. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")

# =============================================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE) APPENDIX
# =============================================================================
cat("Generating SDE table...\n")

# Compute SDEs for main outcomes using PREFERRED (trends) specification
# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_exposure <- sd(panel$bartik_exposure)

outcomes <- data.frame(
  Outcome = c("Average formal wage (log)",
               "Formal employment (log)",
               "Intermittent contract share",
               "Average contracted hours"),
  beta = c(m1t$coef, m2t$coef, m3$coef, m4t$coef),
  se = c(m1t$se, m2t$se, m3$se, m4t$se),
  sd_y = c(pre_means$pre_sd_log_wage, pre_means$pre_sd_log_emp,
           pre_means$pre_sd_intermittent_share, pre_means$pre_sd_hours),
  stringsAsFactors = FALSE
)

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
outcomes$sde <- outcomes$beta * sd_exposure / outcomes$sd_y
outcomes$se_sde <- outcomes$se * sd_exposure / outcomes$sd_y

# Classification
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

outcomes$classification <- sapply(outcomes$sde, classify_sde)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does the introduction of intermittent labor contracts through Brazil's 2017 labor reform (Lei 13.467) affect formal wages, employment levels, and working hours in municipalities with greater sectoral exposure to the new contract type? ",
  "\\textbf{Policy mechanism:} The reform created a new formal employment category (\\textit{trabalho intermitente}) allowing employers to hire workers with a signed work card but no guaranteed minimum hours, reducing the cost of formal employment in sectors with variable labor demand. ",
  "\\textbf{Outcome definition:} Log average monthly formal wage (RAIS \\textit{valor\\_remuneracao\\_media}), log total formal employment count, share of employment relationships classified as intermittent, and average contracted weekly hours. ",
  "\\textbf{Treatment:} Continuous Bartik exposure measure constructed as the employment-weighted average of CNAE-2 sector intermittent adoption rates (2019) using pre-reform (2016) employment structure. ",
  "\\textbf{Data:} RAIS matched employer-employee administrative records via Google BigQuery, 2012--2022, aggregated to municipality-year level across 5,568 municipalities and 87 CNAE-2 sectors. ",
  "\\textbf{Method:} Bartik (shift-share) difference-in-differences with municipality and year fixed effects, weighted by pre-reform employment, standard errors clustered at the state level (27 states). ",
  "\\textbf{Sample:} All Brazilian municipalities with at least 7 of 9 years of RAIS data and positive formal employment; cells with fewer than 5 workers per municipality-sector-year excluded for confidentiality. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-municipality standard deviation of Bartik exposure and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Remove intermittent share from SDE (pre-treatment SD ~0, making SDE meaningless)
outcomes <- outcomes[outcomes$Outcome != "Intermittent contract share", ]

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(outcomes)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            outcomes$Outcome[i],
            fmt(outcomes$beta[i], 4),
            fmt(outcomes$se[i], 4),
            fmt(outcomes$sd_y[i], 4),
            fmt(outcomes$sde[i], 4),
            fmt(outcomes$se_sde[i], 4),
            outcomes$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
