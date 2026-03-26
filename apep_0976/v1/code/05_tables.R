## 05_tables.R — Generate all LaTeX tables
## apep_0976: Yakuza Exclusion Ordinances and Real Estate Markets

source("00_packages.R")
load("../data/models.RData")
load("../data/robustness.RData")

dir.create("../tables", showWarnings = FALSE)

# ══════════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 1: Summary Statistics\n")

summ_vars <- analysis %>%
  filter(fy >= 2005, fy <= 2019) %>%
  summarise(
    across(c(land_price_residential, land_price_change_pct,
             building_starts, crime_rate, rough_crime_rate,
             violent_crime_rate, population),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)),
           .names = "{.col}__{.fn}")
  )

var_labels <- c(
  "Residential land price (yen/m$^2$)",
  "Land price change (\\%)",
  "Building starts",
  "Crime rate (per 1,000)",
  "Rough crime rate (per 1,000)",
  "Violent crime rate (per 1,000)",
  "Population"
)
var_names <- c("land_price_residential", "land_price_change_pct",
               "building_starts", "crime_rate", "rough_crime_rate",
               "violent_crime_rate", "population")

tab1_rows <- ""
for (i in seq_along(var_names)) {
  v <- var_names[i]
  m <- summ_vars[[paste0(v, "__mean")]]
  s <- summ_vars[[paste0(v, "__sd")]]
  mn <- summ_vars[[paste0(v, "__min")]]
  mx <- summ_vars[[paste0(v, "__max")]]
  fmt <- ifelse(m > 100, "%.0f", "%.3f")
  tab1_rows <- paste0(tab1_rows,
    var_labels[i], " & ",
    sprintf(fmt, m), " & ", sprintf(fmt, s), " & ",
    sprintf(fmt, mn), " & ", sprintf(fmt, mx), " \\\\\n")
}

tab1 <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\caption{Summary Statistics}\n",
"\\label{tab:summary}\n",
"\\begin{threeparttable}\n",
"\\begin{tabular}{lrrrr}\n",
"\\toprule\n",
"Variable & Mean & Std.\\ Dev. & Min & Max \\\\\n",
"\\midrule\n",
tab1_rows,
"\\bottomrule\n",
"\\end{tabular}\n",
"\\begin{tablenotes}[flushleft]\n",
"\\small\n",
"\\item \\textit{Notes:} $N = 705$ prefecture-year observations ",
"(47 prefectures $\\times$ 15 years, 2005--2019). ",
"Crime rates are reported criminal offenses per 1,000 population. ",
"Rough crime includes assault and intimidation. ",
"Violent crime includes murder and robbery. ",
"Land prices are official benchmark residential land prices from the ",
"System of Social and Demographic Statistics (e-Stat).\n",
"\\end{tablenotes}\n",
"\\end{threeparttable}\n",
"\\end{table}\n")

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Written tab1_summary.tex\n")

# ══════════════════════════════════════════════════════════════════════
# Table 2: Main Results (CS DiD + TWFE)
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 2: Main Results\n")

fmt_coef <- function(est, se, stars = TRUE) {
  pval <- 2 * pnorm(-abs(est / se))
  star <- ""
  if (stars) {
    if (pval < 0.01) star <- "^{***}"
    else if (pval < 0.05) star <- "^{**}"
    else if (pval < 0.10) star <- "^{*}"
  }
  paste0(sprintf("%.4f", est), "$", star, "$")
}

# CS ATT values
cs_vals <- list(
  land = list(att = cs_land_att$overall.att, se = cs_land_att$overall.se),
  crime = list(att = cs_crime_att$overall.att, se = cs_crime_att$overall.se),
  rough = list(att = cs_rough_att$overall.att, se = cs_rough_att$overall.se),
  build = list(att = cs_build_att$overall.att, se = cs_build_att$overall.se)
)

# TWFE values
twfe_vals <- list(
  land = list(est = coef(twfe_land)["treated"], se = se(twfe_land)["treated"]),
  crime = list(est = coef(twfe_crime)["treated"], se = se(twfe_crime)["treated"]),
  rough = list(est = coef(twfe_rough)["treated"], se = se(twfe_rough)["treated"]),
  build = list(est = coef(twfe_build)["treated"], se = se(twfe_build)["treated"])
)

tab2 <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\caption{Effect of Yakuza Exclusion Ordinances on Real Estate and Crime}\n",
"\\label{tab:main}\n",
"\\begin{threeparttable}\n",
"\\begin{adjustbox}{max width=\\textwidth}\n",
"\\begin{tabular}{lcccc}\n",
"\\toprule\n",
" & (1) & (2) & (3) & (4) \\\\\n",
" & Log Land & Crime Rate & Rough Crime & Log Building \\\\\n",
" & Price & (per 1,000) & Rate (per 1,000) & Starts \\\\\n",
"\\midrule\n",
"\\multicolumn{5}{l}{\\textit{Panel A: Callaway--Sant'Anna}} \\\\\n",
"[0.5em]\n",
"ATT & ", fmt_coef(cs_vals$land$att, cs_vals$land$se), " & ",
           fmt_coef(cs_vals$crime$att, cs_vals$crime$se), " & ",
           fmt_coef(cs_vals$rough$att, cs_vals$rough$se), " & ",
           fmt_coef(cs_vals$build$att, cs_vals$build$se), " \\\\\n",
" & (", sprintf("%.4f", cs_vals$land$se), ") & ",
   "(", sprintf("%.4f", cs_vals$crime$se), ") & ",
   "(", sprintf("%.4f", cs_vals$rough$se), ") & ",
   "(", sprintf("%.4f", cs_vals$build$se), ") \\\\\n",
"[0.5em]\n",
"\\midrule\n",
"\\multicolumn{5}{l}{\\textit{Panel B: TWFE}} \\\\\n",
"[0.5em]\n",
"YEO Adopted & ", fmt_coef(twfe_vals$land$est, twfe_vals$land$se), " & ",
                   fmt_coef(twfe_vals$crime$est, twfe_vals$crime$se), " & ",
                   fmt_coef(twfe_vals$rough$est, twfe_vals$rough$se), " & ",
                   fmt_coef(twfe_vals$build$est, twfe_vals$build$se), " \\\\\n",
" & (", sprintf("%.4f", twfe_vals$land$se), ") & ",
   "(", sprintf("%.4f", twfe_vals$crime$se), ") & ",
   "(", sprintf("%.4f", twfe_vals$rough$se), ") & ",
   "(", sprintf("%.4f", twfe_vals$build$se), ") \\\\\n",
"[0.5em]\n",
"\\midrule\n",
"Prefectures & 47 & 47 & 47 & 47 \\\\\n",
"Years & 2005--2019 & 2005--2019 & 2005--2019 & 2005--2019 \\\\\n",
"Observations & 705 & 705 & 705 & 705 \\\\\n",
"Prefecture FE & Yes & Yes & Yes & Yes \\\\\n",
"Year FE & Yes & Yes & Yes & Yes \\\\\n",
"\\bottomrule\n",
"\\end{tabular}\n",
"\\end{adjustbox}\n",
"\\begin{tablenotes}[flushleft]\n",
"\\small\n",
"\\item \\textit{Notes:} Panel A reports Callaway--Sant'Anna (2021) ATT ",
"estimates using not-yet-treated prefectures as controls. Panel B reports ",
"TWFE estimates with prefecture and year fixed effects. Standard errors ",
"clustered at the prefecture level in parentheses. ",
"$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
"\\end{tablenotes}\n",
"\\end{threeparttable}\n",
"\\end{table}\n")

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Written tab2_main.tex\n")

# ══════════════════════════════════════════════════════════════════════
# Table 3: Heterogeneity by baseline crime
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 3: Heterogeneity\n")

tab3 <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\caption{Heterogeneity by Baseline Organized Crime Exposure}\n",
"\\label{tab:het}\n",
"\\begin{threeparttable}\n",
"\\begin{tabular}{lcccc}\n",
"\\toprule\n",
" & \\multicolumn{2}{c}{Log Land Price} & \\multicolumn{2}{c}{Crime Rate} \\\\\n",
"\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
" & (1) & (2) & (3) & (4) \\\\\n",
" & High Crime & Low Crime & High Crime & Low Crime \\\\\n",
"\\midrule\n",
"YEO Adopted & ", fmt_coef(coef(land_high)["treated"], se(land_high)["treated"]), " & ",
                   fmt_coef(coef(land_low)["treated"], se(land_low)["treated"]), " & ",
                   fmt_coef(coef(crime_high)["treated"], se(crime_high)["treated"]), " & ",
                   fmt_coef(coef(crime_low)["treated"], se(crime_low)["treated"]), " \\\\\n",
" & (", sprintf("%.4f", se(land_high)["treated"]), ") & ",
   "(", sprintf("%.4f", se(land_low)["treated"]), ") & ",
   "(", sprintf("%.4f", se(crime_high)["treated"]), ") & ",
   "(", sprintf("%.4f", se(crime_low)["treated"]), ") \\\\\n",
"[0.5em]\n",
"\\midrule\n",
"Prefectures & 24 & 23 & 24 & 23 \\\\\n",
"Observations & ", nrow(filter(analysis, high_crime == 1)), " & ",
                    nrow(filter(analysis, high_crime == 0)), " & ",
                    nrow(filter(analysis, high_crime == 1)), " & ",
                    nrow(filter(analysis, high_crime == 0)), " \\\\\n",
"Prefecture FE & Yes & Yes & Yes & Yes \\\\\n",
"Year FE & Yes & Yes & Yes & Yes \\\\\n",
"\\bottomrule\n",
"\\end{tabular}\n",
"\\begin{tablenotes}[flushleft]\n",
"\\small\n",
"\\item \\textit{Notes:} Prefectures split at the median of pre-treatment ",
"(2005--2009) rough crime rate (assault and intimidation per 1,000 population). ",
"Rough crime is the most yakuza-proximate crime category. ",
"TWFE with prefecture and year fixed effects. ",
"Standard errors clustered at the prefecture level. ",
"$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
"\\end{tablenotes}\n",
"\\end{threeparttable}\n",
"\\end{table}\n")

writeLines(tab3, "../tables/tab3_heterogeneity.tex")
cat("  Written tab3_heterogeneity.tex\n")

# ══════════════════════════════════════════════════════════════════════
# Table 4: Robustness
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table 4: Robustness\n")

rob_rows <- paste0(
  "Baseline (CS ATT) & ",
    fmt_coef(cs_land_att$overall.att, cs_land_att$overall.se), " & ",
    fmt_coef(cs_crime_att$overall.att, cs_crime_att$overall.se), " \\\\\n",
  " & (", sprintf("%.4f", cs_land_att$overall.se), ") & ",
    "(", sprintf("%.4f", cs_crime_att$overall.se), ") \\\\\n",
  "[0.3em]\n",
  "Excl.\\ Tohoku (CS ATT) & ",
    fmt_coef(cs_land_notohoku_att$overall.att, cs_land_notohoku_att$overall.se), " & ",
    fmt_coef(cs_crime_notohoku_att$overall.att, cs_crime_notohoku_att$overall.se), " \\\\\n",
  " & (", sprintf("%.4f", cs_land_notohoku_att$overall.se), ") & ",
    "(", sprintf("%.4f", cs_crime_notohoku_att$overall.se), ") \\\\\n",
  "[0.3em]\n",
  "Placebo: violent crime & & ",
    fmt_coef(coef(rob_violent)["treated"], se(rob_violent)["treated"]), " \\\\\n",
  " & & (", sprintf("%.4f", se(rob_violent)["treated"]), ") \\\\\n",
  "[0.3em]\n",
  "Placebo: 2 years early & ",
    fmt_coef(coef(placebo_land)["fake_treated"], se(placebo_land)["fake_treated"]), " & ",
    fmt_coef(coef(placebo_crime)["fake_treated"], se(placebo_crime)["fake_treated"]), " \\\\\n",
  " & (", sprintf("%.4f", se(placebo_land)["fake_treated"]), ") & ",
    "(", sprintf("%.4f", se(placebo_crime)["fake_treated"]), ") \\\\\n",
  "[0.3em]\n",
  "Region-clustered SEs & ",
    fmt_coef(coef(rob_region)["treated"], se(rob_region)["treated"]), " & ",
    fmt_coef(coef(rob_region_crime)["treated"], se(rob_region_crime)["treated"]), " \\\\\n",
  " & (", sprintf("%.4f", se(rob_region)["treated"]), ") & ",
    "(", sprintf("%.4f", se(rob_region_crime)["treated"]), ") \\\\\n",
  "[0.3em]\n",
  "Narrow window (2007--2014) & ",
    fmt_coef(coef(rob_narrow_land)["treated"], se(rob_narrow_land)["treated"]), " & ",
    fmt_coef(coef(rob_narrow_crime)["treated"], se(rob_narrow_crime)["treated"]), " \\\\\n",
  " & (", sprintf("%.4f", se(rob_narrow_land)["treated"]), ") & ",
    "(", sprintf("%.4f", se(rob_narrow_crime)["treated"]), ") \\\\\n"
)

tab4 <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\caption{Robustness Checks}\n",
"\\label{tab:robustness}\n",
"\\begin{threeparttable}\n",
"\\begin{tabular}{lcc}\n",
"\\toprule\n",
" & Log Land Price & Crime Rate \\\\\n",
"\\midrule\n",
rob_rows,
"\\bottomrule\n",
"\\end{tabular}\n",
"\\begin{tablenotes}[flushleft]\n",
"\\small\n",
"\\item \\textit{Notes:} Each row reports a separate specification. ",
"Baseline uses Callaway--Sant'Anna (2021) with not-yet-treated controls. ",
"Excl.\\ Tohoku drops Iwate, Miyagi, and Fukushima (March 2011 earthquake). ",
"Placebo: violent crime tests murder/robbery (less yakuza-linked). ",
"Placebo: 2 years early assigns fake treatment dates shifted back 2 years, ",
"estimated on the pre-treatment sample only. ",
"Standard errors in parentheses. ",
"$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
"\\end{tablenotes}\n",
"\\end{threeparttable}\n",
"\\end{table}\n")

writeLines(tab4, "../tables/tab4_robustness.tex")
cat("  Written tab4_robustness.tex\n")

# ══════════════════════════════════════════════════════════════════════
# Table F1: Standardized Effect Sizes (SDE)
# ══════════════════════════════════════════════════════════════════════
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDEs
sd_log_land <- sd(analysis$log_land_price[analysis$fy < 2010], na.rm = TRUE)
sd_crime <- sd(analysis$crime_rate[analysis$fy < 2010], na.rm = TRUE)

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Panel A: Pooled
sde_land <- cs_land_att$overall.att / sd_log_land
se_sde_land <- cs_land_att$overall.se / sd_log_land
sde_crime <- cs_crime_att$overall.att / sd_crime
se_sde_crime <- cs_crime_att$overall.se / sd_crime

# Panel B: Heterogeneous (sample splits)
sd_log_land_h <- sd(analysis$log_land_price[analysis$fy < 2010 & analysis$high_crime == 1], na.rm = TRUE)
sd_log_land_l <- sd(analysis$log_land_price[analysis$fy < 2010 & analysis$high_crime == 0], na.rm = TRUE)
sd_crime_h <- sd(analysis$crime_rate[analysis$fy < 2010 & analysis$high_crime == 1], na.rm = TRUE)
sd_crime_l <- sd(analysis$crime_rate[analysis$fy < 2010 & analysis$high_crime == 0], na.rm = TRUE)

sde_land_h <- coef(land_high)["treated"] / sd_log_land_h
se_sde_land_h <- se(land_high)["treated"] / sd_log_land_h
sde_land_l <- coef(land_low)["treated"] / sd_log_land_l
se_sde_land_l <- se(land_low)["treated"] / sd_log_land_l

fmt_sde_row <- function(outcome, spec, beta, se_beta, sd_y, sde, se_sde) {
  paste0(outcome, " & ", spec, " & ",
         sprintf("%.4f", beta), " & ",
         sprintf("%.4f", se_beta), " & ",
         sprintf("%.4f", sd_y), " & ",
         sprintf("%.4f", sde), " & ",
         sprintf("%.4f", se_sde), " & ",
         classify(sde), " \\\\")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Do prefectural ordinances prohibiting citizens from transacting with organized crime members affect residential property values and reported crime rates? ",
  "\\textbf{Policy mechanism:} Yakuza Exclusion Ordinances criminalize the demand side of organized crime transactions --- making it illegal for ordinary citizens, businesses, and landlords to knowingly provide goods, services, or real estate to yakuza members, thereby severing organized crime's economic integration into legitimate markets. ",
  "\\textbf{Outcome definition:} Log of official benchmark residential land price (yen per square meter) from the System of Social and Demographic Statistics; total reported criminal offenses per 1,000 population from prefectural police. ",
  "\\textbf{Treatment:} Binary; equals one in the year a prefecture's YEO took effect and all subsequent years. ",
  "\\textbf{Data:} e-Stat System of Social and Demographic Statistics, 2005--2019, prefecture-year panel, $N = 705$. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD estimator with not-yet-treated controls; standard errors clustered at the prefecture level. ",
  "\\textbf{Sample:} All 47 Japanese prefectures, restricted to 2005--2019 to ensure adequate pre-treatment periods for the earliest adopters. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\caption{Standardized Effect Sizes for Main Outcomes}\n",
"\\label{tab:sde}\n",
"\\begin{threeparttable}\n",
"\\begin{adjustbox}{max width=\\textwidth}\n",
"\\begin{tabular}{llcccccl}\n",
"\\toprule\n",
"Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
"\\midrule\n",
"\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
fmt_sde_row("Log land price", "CS ATT",
            cs_land_att$overall.att, cs_land_att$overall.se,
            sd_log_land, sde_land, se_sde_land), "\n",
fmt_sde_row("Crime rate", "CS ATT",
            cs_crime_att$overall.att, cs_crime_att$overall.se,
            sd_crime, sde_crime, se_sde_crime), "\n",
"\\midrule\n",
"\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
fmt_sde_row("Log land price", "High-crime pref.",
            as.numeric(coef(land_high)["treated"]),
            as.numeric(se(land_high)["treated"]),
            sd_log_land_h, sde_land_h, se_sde_land_h), "\n",
fmt_sde_row("Log land price", "Low-crime pref.",
            as.numeric(coef(land_low)["treated"]),
            as.numeric(se(land_low)["treated"]),
            sd_log_land_l, sde_land_l, se_sde_land_l), "\n",
"\\bottomrule\n",
"\\end{tabular}\n",
"\\end{adjustbox}\n",
"\\begin{tablenotes}[flushleft]\n",
"\\small\n",
sde_notes, "\n",
"\\end{tablenotes}\n",
"\\end{threeparttable}\n",
"\\end{table}\n")

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Written tabF1_sde.tex\n")

cat("\n✓ All tables generated successfully.\n")
