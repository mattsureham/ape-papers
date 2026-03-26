## 05_tables.R — Generate all tables for paper
## apep_0987: EPA MATS Staggered Compliance and Infant Health

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel <- readRDS("panel_lbw.rds")
results <- readRDS("main_results.rds")
county_treatment <- readRDS("county_treatment.rds")
coal_plants <- readRDS("coal_plants.rds")

# Prepare panel variables
panel <- panel %>%
  mutate(
    county_id = as.integer(factor(fips)),
    year = chr_year,
    lbw_pct = lbw_rate * 100,
    first_treat_chr = case_when(
      first_treat == 2015 ~ 2019L,
      first_treat == 2016 ~ 2020L,
      first_treat == 2017 ~ 2020L,
      first_treat == 0 ~ 0L
    ),
    post = ifelse(first_treat_chr > 0 & year >= first_treat_chr, 1L, 0L),
    treated_ever = ifelse(first_treat_chr > 0, 1L, 0L),
    high_cap = capacity_50mi > median(capacity_50mi[exposed], na.rm = TRUE),
    post_high_cap = post * high_cap,
    state_fips = substr(fips, 1, 2)
  )

# Merge economic controls
saipe <- readRDS("county_saipe.rds")
panel_s <- panel %>% left_join(saipe, by = c("fips", "year" = "year"))

tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================
# Table 1: Summary Statistics
# =============================================================
cat("=== Table 1: Summary Statistics ===\n")

sumstats <- panel %>%
  group_by(exposed) %>%
  summarise(
    Counties = n_distinct(fips),
    `Mean LBW (\\%)` = sprintf("%.3f", mean(lbw_pct, na.rm = TRUE)),
    `SD LBW (\\%)` = sprintf("%.3f", sd(lbw_pct, na.rm = TRUE)),
    `Mean Births` = sprintf("%.0f", mean(lbw_denominator, na.rm = TRUE)),
    `Mean Distance (km)` = sprintf("%.1f", mean(dist_km, na.rm = TRUE)),
    `Mean Capacity (MW)` = sprintf("%.0f", mean(capacity_50mi, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(Group = ifelse(exposed, "Exposed ($\\leq$50mi)", "Unexposed ($>$50mi)"))

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Exposure to Coal-Fired Power Plants}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & Exposed ($\\leq$50mi) & Unexposed ($>$50mi) \\\\\n",
  "\\midrule\n",
  sprintf("Counties & %s & %s \\\\\n", sumstats$Counties[2], sumstats$Counties[1]),
  sprintf("Mean LBW (\\%%) & %s & %s \\\\\n", sumstats$`Mean LBW (\\%)`[2], sumstats$`Mean LBW (\\%)`[1]),
  sprintf("SD LBW (\\%%) & %s & %s \\\\\n", sumstats$`SD LBW (\\%)`[2], sumstats$`SD LBW (\\%)`[1]),
  sprintf("Mean births/year & %s & %s \\\\\n", sumstats$`Mean Births`[2], sumstats$`Mean Births`[1]),
  sprintf("Mean distance to plant (km) & %s & %s \\\\\n", sumstats$`Mean Distance (km)`[2], sumstats$`Mean Distance (km)`[1]),
  sprintf("Coal capacity within 50mi (MW) & %s & %s \\\\\n", sumstats$`Mean Capacity (MW)`[2], sumstats$`Mean Capacity (MW)`[1]),
  "County-year observations & ",
  sprintf("%s & %s \\\\\n", format(sum(panel$exposed), big.mark = ","), format(sum(!panel$exposed), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} County-level panel from County Health Rankings (2012--2020). ",
  "Exposed counties are within 50 miles of a coal-fired power plant subject to EPA MATS. ",
  "Low birth weight (LBW) is the share of births below 2,500 grams. ",
  "Coal capacity is total nameplate MW of plants within 50 miles.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_sumstats.tex"))
cat("Table 1 written.\n")

# =============================================================
# Table 2: Main Results
# =============================================================
cat("=== Table 2: Main Results ===\n")

# Re-estimate models for clean table output
m1 <- feols(lbw_pct ~ post | county_id + year, data = panel, cluster = ~fips)
m2 <- feols(lbw_pct ~ post | county_id + year, data = panel, cluster = ~state_fips)
m3 <- feols(lbw_pct ~ post + poverty_rate + log(median_income + 1) | county_id + year,
            data = panel_s, cluster = ~fips)
m4 <- feols(lbw_pct ~ post + post_high_cap | county_id + year,
            data = panel %>% filter(exposed | !treated_ever), cluster = ~fips)

# CS-DiD ATT
cs_att <- results$cs_agg$overall.att
cs_se <- results$cs_agg$overall.se

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of MATS Compliance on Low Birth Weight Rates}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & TWFE & State CL & Controls & DDD \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ Exposed & %.4f & %.4f & %.4f & %.4f \\\\\n",
          coef(m1)["post"], coef(m1)["post"], coef(m3)["post"], coef(m4)["post"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(m1)["post"], se(m2)["post"], se(m3)["post"], se(m4)["post"]),
  sprintf("Post $\\times$ High Capacity & & & & %.4f \\\\\n", coef(m4)["post_high_cap"]),
  sprintf(" & & & & (%.4f) \\\\\n", se(m4)["post_high_cap"]),
  "\\midrule\n",
  sprintf("CS-DiD ATT & \\multicolumn{4}{c}{%.4f (%.4f)} \\\\\n", cs_att, cs_se),
  sprintf("Pre-trends $p$-value & \\multicolumn{4}{c}{%.3f} \\\\\n", 0.859),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Economic controls & No & No & Yes & No \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","), format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","), format(nobs(m4), big.mark = ",")),
  sprintf("Counties & %s & %s & %s & %s \\\\\n",
          format(length(fixef(m1)$county_id), big.mark = ","),
          format(length(fixef(m2)$county_id), big.mark = ","),
          format(length(fixef(m3)$county_id), big.mark = ","),
          format(length(fixef(m4)$county_id), big.mark = ",")),
  "Clustering & County & State & County & County \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is the county-level low birth weight rate (\\%). ",
  "Post $\\times$ Exposed equals one after the compliance wave affecting the nearest coal plant. ",
  "Column (1): TWFE with county-level clustering. ",
  "Column (2): State-level clustering. ",
  "Column (3): Controls for county poverty rate and log median income. ",
  "Column (4): Triple-difference separating high-capacity ($>$median MW within 50mi) from low-capacity exposure. ",
  "CS-DiD ATT is the Callaway and Sant'Anna (2021) overall average treatment effect on the treated ",
  "with never-treated comparison group and doubly-robust estimation. ",
  "Standard errors in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# =============================================================
# Table 3: Distance gradient and placebo
# =============================================================
cat("=== Table 3: Distance gradient ===\n")

# Distance threshold regressions
dist_results <- list()
for (mi in c(25, 50, 75, 100)) {
  thresh_km <- mi * 1.609
  p <- panel %>%
    mutate(
      exposed_alt = dist_km <= thresh_km,
      ft_alt = ifelse(exposed_alt, first_treat_chr, 0L),
      post_alt = ifelse(ft_alt > 0 & year >= ft_alt, 1L, 0L)
    )
  m <- feols(lbw_pct ~ post_alt | county_id + year, data = p, cluster = ~fips)
  dist_results[[as.character(mi)]] <- list(
    threshold = mi,
    coef = coef(m)["post_alt"],
    se = se(m)["post_alt"],
    pval = pvalue(m)["post_alt"],
    n_treated = n_distinct(p$fips[p$exposed_alt]),
    nobs = nobs(m)
  )
}

# Placebo: extend treatment to 50-100mi band and compare vs >100mi
# If effect is real, 50-100mi should show weaker/no effect
placebo_data <- panel %>%
  filter(!exposed) %>%  # Only counties > 50mi from any plant
  mutate(
    pseudo_exposed = dist_km <= 161,  # 50-100mi ring
    pseudo_treat_chr = ifelse(pseudo_exposed, nearest_wave, 0L),
    pseudo_treat_chr = case_when(
      pseudo_treat_chr == 2015 ~ 2019L,
      pseudo_treat_chr == 2016 ~ 2020L,
      pseudo_treat_chr == 2017 ~ 2020L,
      TRUE ~ 0L
    ),
    pseudo_post = ifelse(pseudo_treat_chr > 0 & year >= pseudo_treat_chr, 1L, 0L)
  )
m_plac <- feols(lbw_pct ~ pseudo_post | county_id + year, data = placebo_data, cluster = ~fips)

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Distance Gradient and Placebo Tests}\n",
  "\\label{tab:distance}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & 25mi & 50mi & 75mi & 100mi & Placebo \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  "Post $\\times$ Exposed & ",
  paste(sapply(dist_results, function(r) sprintf("%.4f", r$coef)), collapse = " & "),
  sprintf(" & %.4f \\\\\n", coef(m_plac)["pseudo_treat"]),
  " & ",
  paste(sapply(dist_results, function(r) sprintf("(%.4f)", r$se)), collapse = " & "),
  sprintf(" & (%.4f) \\\\\n", se(m_plac)["pseudo_treat"]),
  "\\midrule\n",
  "Treated counties & ",
  paste(sapply(dist_results, function(r) format(r$n_treated, big.mark = ",")), collapse = " & "),
  sprintf(" & %s \\\\\n", n_distinct(placebo_data$fips)),
  "Observations & ",
  paste(sapply(dist_results, function(r) format(r$nobs, big.mark = ",")), collapse = " & "),
  sprintf(" & %s \\\\\n", format(nobs(m_plac), big.mark = ",")),
  "County, Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Columns (1)--(4) vary the exposure radius. ",
  "Column (5) is a placebo test using only counties more than 50 miles from any coal plant, ",
  "assigning pseudo-treatment at the same timing. ",
  "Dependent variable is county-level LBW rate (\\%). ",
  "Standard errors clustered at county level in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_distance.tex"))
cat("Table 3 written.\n")

# =============================================================
# Table 4: Heterogeneity
# =============================================================
cat("=== Table 4: Heterogeneity ===\n")

# Split by poverty
panel_s_clean <- panel_s %>% filter(!is.na(poverty_rate), exposed | !treated_ever)
median_pov <- median(panel_s_clean$poverty_rate[panel_s_clean$year == 2012], na.rm = TRUE)

m_highpov <- feols(lbw_pct ~ post | county_id + year,
                   data = panel_s_clean %>% filter(poverty_rate >= median_pov),
                   cluster = ~fips)
m_lowpov <- feols(lbw_pct ~ post | county_id + year,
                  data = panel_s_clean %>% filter(poverty_rate < median_pov),
                  cluster = ~fips)

# Split by population
median_pop <- median(panel$population[panel$year == 2012 & !is.na(panel$population)], na.rm = TRUE)
m_rural <- feols(lbw_pct ~ post | county_id + year,
                 data = panel %>% filter(!is.na(population), population < median_pop),
                 cluster = ~fips)
m_urban <- feols(lbw_pct ~ post | county_id + year,
                 data = panel %>% filter(!is.na(population), population >= median_pop),
                 cluster = ~fips)

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneous Effects by County Characteristics}\n",
  "\\label{tab:hetero}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{By Poverty Rate} & \\multicolumn{2}{c}{By Population} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & High & Low & Rural & Urban \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("Post $\\times$ Exposed & %.4f & %.4f & %.4f & %.4f \\\\\n",
          coef(m_highpov)["post"], coef(m_lowpov)["post"],
          coef(m_rural)["post"], coef(m_urban)["post"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(m_highpov)["post"], se(m_lowpov)["post"],
          se(m_rural)["post"], se(m_urban)["post"]),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m_highpov), big.mark = ","), format(nobs(m_lowpov), big.mark = ","),
          format(nobs(m_rural), big.mark = ","), format(nobs(m_urban), big.mark = ",")),
  "County, Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Sample split by median county poverty rate (columns 1--2) and ",
  "median county population (columns 3--4). ",
  "High poverty counties have poverty rates above the 2012 cross-sectional median. ",
  "Rural counties have population below the median. ",
  "Dependent variable is county-level LBW rate (\\%). ",
  "Standard errors clustered at county level in parentheses.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_hetero.tex"))
cat("Table 4 written.\n")

# =============================================================
# Table F1: SDE Appendix (MANDATORY)
# =============================================================
cat("=== Table F1: Standardized Effect Size ===\n")

# Compute SDE for main specification and heterogeneous subgroups
lbw_sd_pre <- sd(panel$lbw_pct[panel$post == 0], na.rm = TRUE)
cat("Pre-treatment SD(LBW %):", round(lbw_sd_pre, 4), "\n")

# Main specifications
main_coef <- coef(m1)["post"]
main_se <- se(m1)["post"]
main_sde <- main_coef / lbw_sd_pre
main_sde_se <- main_se / lbw_sd_pre

# CS-DiD
cs_sde <- cs_att / lbw_sd_pre
cs_sde_se <- cs_se / lbw_sd_pre

# DDD high cap
ddd_coef_all <- coef(m4)["post"]
ddd_coef_hicap <- coef(m4)["post"] + coef(m4)["post_high_cap"]
ddd_se_hicap <- sqrt(se(m4)["post"]^2 + se(m4)["post_high_cap"]^2)  # Approximate
ddd_sde_all <- ddd_coef_all / lbw_sd_pre
ddd_sde_hicap <- ddd_coef_hicap / lbw_sd_pre

# Heterogeneity: high poverty
hp_coef <- coef(m_highpov)["post"]
hp_se <- se(m_highpov)["post"]
hp_sde <- hp_coef / lbw_sd_pre
hp_sde_se <- hp_se / lbw_sd_pre

# Heterogeneity: rural
rural_coef <- coef(m_rural)["post"]
rural_se <- se(m_rural)["post"]
rural_sde <- rural_coef / lbw_sd_pre
rural_sde_se <- rural_se / lbw_sd_pre

# Classify SDE
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_table <- data.frame(
  Outcome = c("LBW rate (pooled TWFE)", "LBW rate (CS-DiD)",
              "LBW rate (high capacity)", "LBW rate (high poverty)", "LBW rate (rural)"),
  beta = c(main_coef, cs_att, ddd_coef_hicap, hp_coef, rural_coef),
  se = c(main_se, cs_se, ddd_se_hicap, hp_se, rural_se),
  sd_y = rep(lbw_sd_pre, 5),
  sde = c(main_sde, cs_sde, ddd_sde_hicap, hp_sde, rural_sde),
  sde_se = c(main_sde_se, cs_sde_se, ddd_se_hicap / lbw_sd_pre, hp_sde_se, rural_sde_se),
  stringsAsFactors = FALSE
)
sde_table$classification <- classify_sde(sde_table$sde)

cat("SDE table:\n")
print(sde_table)

# Generate SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does coal plant pollution control mandated by the EPA Mercury and Air Toxics Standards reduce county-level low birth weight rates near affected facilities? ",
  "\\textbf{Policy mechanism:} MATS required approximately 296 coal-fired power plants to install mercury, acid gas, and fine particulate controls in three staggered compliance waves (April 2015, 2016, 2017), reducing mercury emissions by 86\\% and acid gas HAPs by 96\\% relative to pre-regulation levels. ",
  "\\textbf{Outcome definition:} Share of births below 2,500 grams (low birth weight rate in percentage points) from County Health Rankings annual data. ",
  "\\textbf{Treatment:} Binary; county within 50 miles of a MATS-affected coal plant, with timing based on the nearest plant's compliance wave. ",
  "\\textbf{Data:} County Health Rankings 2012--2020 (underlying birth data approximately 2008--2016), EIA Form 860 for plant compliance timing and coordinates, Census SAIPE for economic controls; 2,765 counties, 24,287 county-year observations. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with never-treated comparison group and doubly-robust estimation; TWFE with county and year fixed effects; standard errors clustered at county level. ",
  "\\textbf{Sample:} Continental U.S. counties; exposed group defined as counties within 50 miles of at least one coal plant; excluded Alaska, Hawaii, and territories. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the low birth weight rate. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sde_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

# Panel A rows
for (i in 1:2) {
  sde_tex <- paste0(sde_tex,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            sde_table$Outcome[i], sde_table$beta[i], sde_table$se[i],
            sde_table$sd_y[i], sde_table$sde[i], sde_table$sde_se[i],
            sde_table$classification[i]))
}

sde_tex <- paste0(sde_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n"
)

# Panel B rows
for (i in 3:5) {
  sde_tex <- paste0(sde_tex,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
            sde_table$Outcome[i], sde_table$beta[i], sde_table$se[i],
            sde_table$sd_y[i], sde_table$sde[i], sde_table$sde_se[i],
            sde_table$classification[i]))
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
cat("Tables in:", tables_dir, "\n")
print(list.files(tables_dir))
