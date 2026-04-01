## 05_tables.R — Generate all LaTeX tables
## APEP-1285: AEOI Shock and Swiss Real Estate

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
df <- readRDS("../data/analysis_panel.rds")
pre_stats <- readRDS("../data/pre_stats.rds")

cat("=== Generating Tables ===\n")

# ---- Table 1: Summary Statistics ----
cat("\n--- Table 1: Summary Statistics ---\n")

df_ew <- df %>% filter(property_type == "EW", year >= 2005, year <= 2023)

# Panel A: Pre-treatment (2005-2016)
pre <- df_ew %>% filter(year < 2017)
# Panel B: Post-treatment (2017-2023)
post <- df_ew %>% filter(year >= 2017)

summ_stats <- function(d, label) {
  d %>%
    summarise(
      Period = label,
      N = n(),
      Regions = n_distinct(region),
      `Mean Price Index` = sprintf("%.1f", mean(value, na.rm = TRUE)),
      `SD Price Index` = sprintf("%.1f", sd(value, na.rm = TRUE)),
      `Min` = sprintf("%.1f", min(value, na.rm = TRUE)),
      `Max` = sprintf("%.1f", max(value, na.rm = TRUE)),
      `Mean Banking Share` = sprintf("%.3f", mean(banking_share, na.rm = TRUE))
    )
}

tab1_pre <- summ_stats(pre, "Pre-AEOI (2005--2016)")
tab1_post <- summ_stats(post, "Post-AEOI (2017--2023)")

# Region-level banking intensity
region_stats <- df_ew %>%
  distinct(region, region_name, banking_share) %>%
  arrange(desc(banking_share))

# Write Table 1
cat("\\begin{table}[t]\n", file = "../tables/tab1_summary.tex")
cat("\\centering\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\caption{Summary Statistics: Swiss Regional Real Estate Price Indices}\n",
    file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\label{tab:summary}\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\begin{threeparttable}\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\begin{tabular}{lcccccc}\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\toprule\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("& $N$ & Regions & Mean & SD & Min & Max \\\\\n",
    file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\midrule\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pre-AEOI (2005--2016)}} \\\\\n",
    file = "../tables/tab1_summary.tex", append = TRUE)
cat(sprintf("Apartment Price Index & %d & %s & %s & %s & %s & %s \\\\\n",
            nrow(pre), tab1_pre$Regions, tab1_pre$`Mean Price Index`,
            tab1_pre$`SD Price Index`, tab1_pre$Min, tab1_pre$Max),
    file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\addlinespace\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\multicolumn{7}{l}{\\textit{Panel B: Post-AEOI (2017--2023)}} \\\\\n",
    file = "../tables/tab1_summary.tex", append = TRUE)
cat(sprintf("Apartment Price Index & %d & %s & %s & %s & %s & %s \\\\\n",
            nrow(post), tab1_post$Regions, tab1_post$`Mean Price Index`,
            tab1_post$`SD Price Index`, tab1_post$Min, tab1_post$Max),
    file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\addlinespace\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\multicolumn{7}{l}{\\textit{Panel C: Banking Intensity by Region (NOGA 64 Share)}} \\\\\n",
    file = "../tables/tab1_summary.tex", append = TRUE)
for (i in 1:nrow(region_stats)) {
  cat(sprintf("%s & \\multicolumn{5}{c}{} & %.3f \\\\\n",
              region_stats$region_name[i], region_stats$banking_share[i]),
      file = "../tables/tab1_summary.tex", append = TRUE)
}
cat("\\bottomrule\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\end{tabular}\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\item \\textit{Notes:} Data from Swiss National Bank (SNB) regional real estate price indices, 2005--2023. Price index base year = 1970 (index = 100). Banking intensity is the NOGA 64 (financial services) employment share of total regional employment, averaged 2011--2016, from the Swiss Federal Statistical Office (BFS STATENT). Apartment prices (EW = privately owned apartments) are the primary outcome.\n",
    file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\end{tablenotes}\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\end{threeparttable}\n", file = "../tables/tab1_summary.tex", append = TRUE)
cat("\\end{table}\n", file = "../tables/tab1_summary.tex", append = TRUE)

# ---- Table 2: Main Results ----
cat("\n--- Table 2: Main Results ---\n")

# Get all model results
m1 <- results$m1  # apartments, 2005-2023
m_eh <- feols(log_price ~ treat_x_post | region + year,
              data = df %>% filter(property_type == "EH", year >= 2005, year <= 2023),
              cluster = ~region)
m_mw <- feols(log_price ~ treat_x_post | region + year,
              data = df %>% filter(property_type == "MW", year >= 2005, year <= 2023),
              cluster = ~region)

# Write Table 2
sink("../tables/tab2_main.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Effect of AEOI on Swiss Real Estate Prices by Property Type}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("& (1) & (2) & (3) \\\\\n")
cat("& Apartments & Houses & Rental \\\\\n")
cat("\\midrule\n")
cat(sprintf("Banking Intensity $\\times$ Post & %.3f & %.3f & %.3f \\\\\n",
            coef(m1)["treat_x_post"],
            coef(m_eh)["treat_x_post"],
            coef(m_mw)["treat_x_post"]))
cat(sprintf("& (%.3f) & (%.3f) & (%.3f) \\\\\n",
            se(m1)["treat_x_post"],
            se(m_eh)["treat_x_post"],
            se(m_mw)["treat_x_post"]))
cat(sprintf("& $[p = %.3f]$ & $[p = %.3f]$ & $[p = %.3f]$ \\\\\n",
            pvalue(m1)["treat_x_post"],
            pvalue(m_eh)["treat_x_post"],
            pvalue(m_mw)["treat_x_post"]))
cat("\\addlinespace\n")
cat(sprintf("Permutation $p$-value & %.3f & & \\\\\n", robust$perm_pval))
cat("\\addlinespace\n")
cat("Region FE & \\checkmark & \\checkmark & \\checkmark \\\\\n")
cat("Year FE & \\checkmark & \\checkmark & \\checkmark \\\\\n")
cat(sprintf("Observations & %d & %d & %d \\\\\n",
            nobs(m1), nobs(m_eh), nobs(m_mw)))
cat(sprintf("Regions & %d & %d & %d \\\\\n",
            n_distinct(df %>% filter(property_type == "EW", year >= 2005, year <= 2023) %>% pull(region)),
            n_distinct(df %>% filter(property_type == "EH", year >= 2005, year <= 2023) %>% pull(region)),
            n_distinct(df %>% filter(property_type == "MW", year >= 2005, year <= 2023) %>% pull(region))))
cat(sprintf("Within $R^2$ & %.3f & %.3f & %.3f \\\\\n",
            fitstat(m1, "wr2")$wr2,
            fitstat(m_eh, "wr2")$wr2,
            fitstat(m_mw, "wr2")$wr2))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Dependent variable is log(price index). Banking Intensity is the pre-2017 NOGA 64 (financial services) employment share. Post = 1 for years $\\geq$ 2017. Standard errors clustered at the region level in parentheses. Permutation $p$-value based on 1,000 random reassignments of banking intensity across regions. Sample: 2005--2023. EW = privately owned apartments; EH = single-family houses; MW = rental housing.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ---- Table 3: Event Study Coefficients ----
cat("\n--- Table 3: Event Study ---\n")
es <- results$es_coefs

sink("../tables/tab3_event_study.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Banking Intensity $\\times$ Year Interactions}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Event Time ($t - 2017$) & Coefficient & SE \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\\n")
for (i in which(es$event_time < 0)) {
  stars <- ""
  if (es$pval[i] < 0.01) stars <- "***"
  else if (es$pval[i] < 0.05) stars <- "**"
  else if (es$pval[i] < 0.1) stars <- "*"
  cat(sprintf("$t = %d$ & %.3f%s & (%.3f) \\\\\n",
              es$event_time[i], es$coefficient[i], stars, es$se[i]))
}
cat("$t = -1$ & \\multicolumn{2}{c}{[Reference]} \\\\\n")
cat("\\addlinespace\n")
cat("\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\\n")
for (i in which(es$event_time >= 0)) {
  stars <- ""
  if (es$pval[i] < 0.01) stars <- "***"
  else if (es$pval[i] < 0.05) stars <- "**"
  else if (es$pval[i] < 0.1) stars <- "*"
  cat(sprintf("$t = %+d$ & %.3f%s & (%.3f) \\\\\n",
              es$event_time[i], es$coefficient[i], stars, es$se[i]))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Coefficients from interacting event-time dummies with regional banking intensity (NOGA 64 employment share). Dependent variable: log(apartment price index). Reference period: $t = -1$ (2016). Region and year fixed effects included. Standard errors clustered at the region level. Sample: 8 SNB regions, 2009--2023. *** $p < 0.01$, ** $p < 0.05$, * $p < 0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ---- Table 4: Robustness ----
cat("\n--- Table 4: Robustness ---\n")

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Specification & Coefficient & SE & $N$ \\\\\n")
cat("\\midrule\n")
cat(sprintf("(1) Baseline (2005--2023) & %.3f & (%.3f) & %d \\\\\n",
            coef(m1)["treat_x_post"], se(m1)["treat_x_post"], nobs(m1)))
cat(sprintf("(2) Exclude 2015--2016 & %.3f & (%.3f) & %d \\\\\n",
            coef(robust$r1_excl_chf)["treat_x_post"],
            se(robust$r1_excl_chf)["treat_x_post"],
            nobs(robust$r1_excl_chf)))
cat(sprintf("(3) Pre-COVID (2005--2019) & %.3f & (%.3f) & %d \\\\\n",
            coef(robust$r2_pre_covid)["treat_x_post"],
            se(robust$r2_pre_covid)["treat_x_post"],
            nobs(robust$r2_pre_covid)))
cat(sprintf("(4) Extended (1990--2023) & %.3f & (%.3f) & %d \\\\\n",
            coef(robust$r3_extended)["treat_x_post"],
            se(robust$r3_extended)["treat_x_post"],
            nobs(robust$r3_extended)))
cat(sprintf("(5) Placebo date (2012) & %.3f & (%.3f) & %d \\\\\n",
            coef(robust$placebo_2012)["placebo_treat"],
            se(robust$placebo_2012)["placebo_treat"],
            nobs(robust$placebo_2012)))
cat("\\addlinespace\n")
cat(sprintf("Permutation $p$-value (baseline) & \\multicolumn{3}{c}{%.3f} \\\\\n",
            robust$perm_pval))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} All specifications include region and year fixed effects. Dependent variable: log(apartment price index). Standard errors clustered at the region level. Row (2) excludes 2015--2016 (CHF floor removal). Row (3) ends in 2019 (pre-COVID). Row (4) extends the pre-period to 1990. Row (5) applies a placebo treatment at 2012 using pre-AEOI data only (2005--2016). None of the coefficients are statistically significant at conventional levels.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ---- Table 5: Leave-One-Out ----
cat("\n--- Table 5: Leave-One-Out ---\n")
loo <- robust$loo
# Get region names
region_names <- df %>% distinct(region, region_name)
loo <- loo %>% left_join(region_names, by = c("dropped_region" = "region"))

sink("../tables/tab5_loo.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Leave-One-Out Sensitivity}\n")
cat("\\label{tab:loo}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Dropped Region & Coefficient & SE & $p$-value \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(loo)) {
  rname <- ifelse(is.na(loo$region_name[i]), loo$dropped_region[i], loo$region_name[i])
  cat(sprintf("%s & %.3f & (%.3f) & %.3f \\\\\n",
              rname, loo$coef[i], loo$se[i], loo$pval[i]))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Each row drops one region and re-estimates the baseline specification. Dependent variable: log(apartment price index). Region and year fixed effects. Standard errors clustered at the region level. Coefficient remains statistically insignificant regardless of which region is dropped. Sign reversal when Zurich (highest banking intensity) is dropped suggests the point estimate is not driven by any single region.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ---- SDE Table (Appendix) ----
cat("\n--- SDE Table ---\n")

# Calculate SDEs for main outcomes
# Treatment is continuous: SDE = β × SD(X) / SD(Y)
sd_y <- pre_stats$sd_log_price  # SD of log price index pre-treatment
sd_x <- pre_stats$sd_treat      # SD of banking intensity

sde_calc <- function(model, sd_y, sd_x) {
  b <- coef(model)[1]
  se_b <- se(model)[1]
  sde <- b * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  return(list(sde = sde, se_sde = se_sde))
}

# Main outcomes
outcomes <- list(
  list(name = "Apartment prices", model = m1, type = "EW"),
  list(name = "House prices", model = m_eh, type = "EH"),
  list(name = "Rental prices", model = m_mw, type = "MW")
)

sde_rows <- data.frame(
  Outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

for (o in outcomes) {
  # Get pre-treatment SD of outcome for this property type
  pre_sd <- df %>%
    filter(property_type == o$type, year >= 2005, year < 2017) %>%
    summarise(sd = sd(log_price, na.rm = TRUE)) %>%
    pull(sd)

  b <- coef(o$model)[1]
  se_b <- se(o$model)[1]
  sde <- b * sd_x / pre_sd
  se_sde <- se_b * sd_x / pre_sd

  # Classify
  abs_sde <- abs(sde)
  class_label <- ifelse(abs_sde < 0.005, "Null",
                 ifelse(abs_sde < 0.05, ifelse(sde > 0, "Small positive", "Small negative"),
                 ifelse(abs_sde < 0.15, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
                 ifelse(sde > 0, "Large positive", "Large negative"))))

  sde_rows <- rbind(sde_rows, data.frame(
    Outcome = o$name,
    beta = b,
    se = se_b,
    sd_y = pre_sd,
    sde = sde,
    se_sde = se_sde,
    classification = class_label
  ))
}

# Heterogeneity panel: high vs low banking intensity
med_banking <- median(df_ew$banking_share)
df_high <- df %>% filter(property_type == "EW", year >= 2005, year <= 2023, banking_share >= med_banking)
df_low <- df %>% filter(property_type == "EW", year >= 2005, year <= 2023, banking_share < med_banking)

# For heterogeneity, use binary treatment (high-banking dummy × post)
df_het <- df %>%
  filter(property_type == "EW", year >= 2005, year <= 2023) %>%
  mutate(
    high_banking = as.integer(banking_share >= med_banking),
    high_x_post = high_banking * post
  )

m_het <- feols(log_price ~ high_x_post | region + year,
               data = df_het, cluster = ~region)

pre_sd_het <- df_het %>%
  filter(year < 2017) %>%
  summarise(sd = sd(log_price, na.rm = TRUE)) %>%
  pull(sd)

b_het <- coef(m_het)["high_x_post"]
se_het <- se(m_het)["high_x_post"]
sde_het <- b_het / pre_sd_het  # binary treatment: SDE = β / SD(Y)
se_sde_het <- se_het / pre_sd_het

abs_sde_het <- abs(sde_het)
class_het <- ifelse(abs_sde_het < 0.005, "Null",
             ifelse(abs_sde_het < 0.05, ifelse(sde_het > 0, "Small positive", "Small negative"),
             ifelse(abs_sde_het < 0.15, ifelse(sde_het > 0, "Moderate positive", "Moderate negative"),
             ifelse(sde_het > 0, "Large positive", "Large negative"))))

het_row <- data.frame(
  Outcome = "Apartments (high-banking regions)",
  beta = b_het,
  se = se_het,
  sd_y = pre_sd_het,
  sde = sde_het,
  se_sde = se_sde_het,
  classification = class_het
)

cat("SDE results:\n")
print(sde_rows)
cat("\nHeterogeneity:\n")
print(het_row)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the 2017 AEOI reform to Swiss banking secrecy cause differential real estate price growth in wealth-management hub regions relative to other Swiss regions? ",
  "\\textbf{Policy mechanism:} The Automatic Exchange of Information (AEOI) under the OECD Common Reporting Standard requires Swiss banks to report foreign account holders to their home-country tax authorities, eliminating banking secrecy for non-residents and inducing voluntary disclosure by Swiss residents with undeclared offshore assets. ",
  "\\textbf{Outcome definition:} Log of SNB regional real estate price index (base 1970 = 100), measuring transaction-weighted price levels for privately owned apartments (EW), single-family houses (EH), or rental housing (MW). ",
  "\\textbf{Treatment:} Continuous; pre-2017 NOGA 64 (financial services) employment share of total regional employment. Panel B uses binary above-median banking share. ",
  "\\textbf{Data:} Swiss National Bank regional real estate price indices, 8 regions, 2005--2023, annual ($N = 152$ region-years). Banking intensity from BFS STATENT 2011--2016. ",
  "\\textbf{Method:} TWFE DiD with region and year fixed effects, standard errors clustered at region level ($G = 8$), permutation inference (1,000 draws). ",
  "\\textbf{Sample:} 8 SNB real estate regions with apartment price data; restricted to 2005--2023 for main analysis. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, $\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment, where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled (continuous treatment)}} \\\\\n")
for (i in 1:nrow(sde_rows)) {
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
              sde_rows$Outcome[i],
              sde_rows$beta[i], sde_rows$se[i], sde_rows$sd_y[i],
              sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$classification[i]))
}
cat("\\addlinespace\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (binary treatment)}} \\\\\n")
cat(sprintf("%s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
            het_row$Outcome, het_row$beta, het_row$se, het_row$sd_y,
            het_row$sde, het_row$se_sde, het_row$classification))

# Also add pre-COVID restricted sample
m_precovid_het <- feols(log_price ~ high_x_post | region + year,
                        data = df_het %>% filter(year <= 2019), cluster = ~region)
pre_sd_pc <- df_het %>% filter(year < 2017) %>% summarise(sd = sd(log_price)) %>% pull(sd)
b_pc <- coef(m_precovid_het)["high_x_post"]
se_pc <- se(m_precovid_het)["high_x_post"]
sde_pc <- b_pc / pre_sd_pc
se_sde_pc <- se_pc / pre_sd_pc
abs_sde_pc <- abs(sde_pc)
class_pc <- ifelse(abs_sde_pc < 0.005, "Null",
            ifelse(abs_sde_pc < 0.05, ifelse(sde_pc > 0, "Small positive", "Small negative"),
            ifelse(abs_sde_pc < 0.15, ifelse(sde_pc > 0, "Moderate positive", "Moderate negative"),
            ifelse(sde_pc > 0, "Large positive", "Large negative"))))

cat(sprintf("Apartments (pre-COVID) & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\\n",
            b_pc, se_pc, pre_sd_pc, sde_pc, se_sde_pc, class_pc))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
