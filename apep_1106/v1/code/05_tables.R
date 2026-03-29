# 05_tables.R — Generate all LaTeX tables
# APEP-1106: The Pollinator Dividend

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

# -------------------------------------------------------------------
# Table 1: Summary Statistics
# -------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics\n")

# Pre-period (2013-2018) statistics by group
pre_panel <- panel %>% filter(year <= 2018)

# Derogation countries
derog_pre <- pre_panel %>%
  filter(ever_derog == 1) %>%
  summarize(
    n_obs = n(),
    n_countries = n_distinct(country_iso2),
    mean_bee = mean(bee_obs, na.rm = TRUE),
    sd_bee = sd(bee_obs, na.rm = TRUE),
    mean_bee_share = mean(bee_share, na.rm = TRUE),
    sd_bee_share = sd(bee_share, na.rm = TRUE),
    mean_beetle = mean(beetle_obs, na.rm = TRUE),
    sd_beetle = sd(beetle_obs, na.rm = TRUE),
    mean_insecta = mean(insecta_obs, na.rm = TRUE),
    sd_insecta = sd(insecta_obs, na.rm = TRUE)
  )

# Non-derogation countries
noderog_pre <- pre_panel %>%
  filter(ever_derog == 0) %>%
  summarize(
    n_obs = n(),
    n_countries = n_distinct(country_iso2),
    mean_bee = mean(bee_obs, na.rm = TRUE),
    sd_bee = sd(bee_obs, na.rm = TRUE),
    mean_bee_share = mean(bee_share, na.rm = TRUE),
    sd_bee_share = sd(bee_share, na.rm = TRUE),
    mean_beetle = mean(beetle_obs, na.rm = TRUE),
    sd_beetle = sd(beetle_obs, na.rm = TRUE),
    mean_insecta = mean(insecta_obs, na.rm = TRUE),
    sd_insecta = sd(insecta_obs, na.rm = TRUE)
  )

fmt <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Ban Period (2013--2018)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Derogation Countries} & \\multicolumn{2}{c}{Non-Derogation Countries} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  "Bee observations & ", fmt(derog_pre$mean_bee), " & ", fmt(derog_pre$sd_bee), " & ",
  fmt(noderog_pre$mean_bee), " & ", fmt(noderog_pre$sd_bee), " \\\\\n",
  "Beetle observations & ", fmt(derog_pre$mean_beetle), " & ", fmt(derog_pre$sd_beetle), " & ",
  fmt(noderog_pre$mean_beetle), " & ", fmt(noderog_pre$sd_beetle), " \\\\\n",
  "Total insect obs. & ", fmt(derog_pre$mean_insecta), " & ", fmt(derog_pre$sd_insecta), " & ",
  fmt(noderog_pre$mean_insecta), " & ", fmt(noderog_pre$sd_insecta), " \\\\\n",
  "Bee share of insects & ", fmt(derog_pre$mean_bee_share, 4), " & ", fmt(derog_pre$sd_bee_share, 4), " & ",
  fmt(noderog_pre$mean_bee_share, 4), " & ", fmt(noderog_pre$sd_bee_share, 4), " \\\\\n",
  "\\midrule\n",
  "Countries & \\multicolumn{2}{c}{", derog_pre$n_countries, "} & \\multicolumn{2}{c}{", noderog_pre$n_countries, "} \\\\\n",
  "Country-years & \\multicolumn{2}{c}{", derog_pre$n_obs, "} & \\multicolumn{2}{c}{", noderog_pre$n_obs, "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Pre-ban period (2013--2018) means and standard deviations. ",
  "Derogation countries are the 11 EU member states that granted Article 53 emergency ",
  "authorizations for neonicotinoid use on sugar beet after the December 2018 ban. ",
  "Bee observations are GBIF citizen science records of Apoidea (superfamily). ",
  "Beetle observations (Coleoptera) serve as a placebo taxon. ",
  "Bee share = bee observations / total insect observations.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# -------------------------------------------------------------------
# Table 2: Main DiD Results
# -------------------------------------------------------------------
cat("Generating Table 2: Main DiD Results\n")

# Extract coefficients
get_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

extract_row <- function(model, varname, label) {
  cf <- coef(model)[varname]
  se_val <- se(model)[varname]
  pv <- pvalue(model)[varname]
  if (is.na(cf)) return(paste0(label, " & --- & --- \\\\\n"))
  stars <- get_stars(pv)
  paste0(label, " & $", formatC(cf, format = "f", digits = 5), stars, "$ & $",
         formatC(cf, format = "f", digits = 5), stars, "$ \\\\\n",
         " & (", formatC(se_val, format = "f", digits = 5), ") & (",
         formatC(se_val, format = "f", digits = 5), ") \\\\\n")
}

# Build table manually for clean formatting
m1 <- results$m1
m2 <- results$m2
m3 <- results$m3

# Helper to format model column
fmt_coef <- function(model, varname) {
  cf <- coef(model)[varname]
  se_val <- se(model)[varname]
  pv <- pvalue(model)[varname]
  if (is.null(cf) || is.na(cf)) return(c("---", ""))
  stars <- get_stars(pv)
  c(paste0("$", formatC(cf, format = "f", digits = 5), stars, "$"),
    paste0("(", formatC(se_val, format = "f", digits = 5), ")"))
}

dd_m1 <- fmt_coef(m1, "treat_dd")
dd_m2 <- fmt_coef(m2, "treat_dd")
dd_m3 <- fmt_coef(m3, "treat_dd")
ddd_m2 <- fmt_coef(m2, "treat_ddd")
ddd_m3 <- fmt_coef(m3, "treat_ddd")

n_obs <- nrow(panel)
n_countries <- n_distinct(panel$country_iso2)

# CS aggregate
cs_cf <- results$cs_agg$overall.att
cs_se <- results$cs_agg$overall.se

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Neonicotinoid Derogations on Bee Observation Share}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & DiD & DDD & DDD + Effort & C\\&S \\\\\n",
  "\\midrule\n",
  "Derogation (DiD) & ", dd_m1[1], " & ", dd_m2[1], " & ", dd_m3[1], " & --- \\\\\n",
  " & ", dd_m1[2], " & ", dd_m2[2], " & ", dd_m3[2], " & \\\\\n",
  "Derog. $\\times$ Sugar Beet (DDD) & --- & ", ddd_m2[1], " & ", ddd_m3[1], " & --- \\\\\n",
  " & & ", ddd_m2[2], " & ", ddd_m3[2], " & \\\\\n",
  "ATT (Callaway-Sant'Anna) & --- & --- & --- & $",
  formatC(cs_cf, format = "f", digits = 5), get_stars(2 * pnorm(-abs(cs_cf / cs_se))), "$ \\\\\n",
  " & & & & (", formatC(cs_se, format = "f", digits = 5), ") \\\\\n",
  "\\midrule\n",
  "Effort control & No & No & Yes & No \\\\\n",
  "Country FE & Yes & Yes & Yes & --- \\\\\n",
  "Year FE & Yes & Yes & Yes & --- \\\\\n",
  "Observations & ", formatC(n_obs, big.mark = ","), " & ", formatC(n_obs, big.mark = ","),
  " & ", formatC(n_obs, big.mark = ","), " & ", formatC(n_obs, big.mark = ","), " \\\\\n",
  "Countries & ", n_countries, " & ", n_countries, " & ", n_countries, " & ", n_countries, " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is bee observation share (bee observations / total insect observations) ",
  "at the country-year level. ``Derogation'' indicates country-years where an Article 53 emergency authorization ",
  "for neonicotinoid use on sugar beet was granted. ``Sugar Beet'' indicates countries with above-median ",
  "pre-ban sugar beet harvested area. Column (4) reports the Callaway and Sant'Anna (2021) ",
  "aggregate ATT using not-yet-treated/never-treated as the control group. ",
  "Standard errors clustered at the country level in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# -------------------------------------------------------------------
# Table 3: Placebo Test (Beetles)
# -------------------------------------------------------------------
cat("Generating Table 3: Placebo Test\n")

m_p1 <- results$m_placebo
m_p2 <- results$m_placebo_ddd

p_dd <- fmt_coef(m_p1, "treat_dd")
p_ddd <- fmt_coef(m_p2, "treat_ddd")

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Placebo Test: Effect of Derogations on Beetle Observation Share}\n",
  "\\label{tab:placebo}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Beetle Share (DiD) & Beetle Share (DDD) \\\\\n",
  "\\midrule\n",
  "Derogation & ", p_dd[1], " & ", fmt_coef(m_p2, "treat_dd")[1], " \\\\\n",
  " & ", p_dd[2], " & ", fmt_coef(m_p2, "treat_dd")[2], " \\\\\n",
  "Derog. $\\times$ Sugar Beet & --- & ", p_ddd[1], " \\\\\n",
  " & & ", p_ddd[2], " \\\\\n",
  "\\midrule\n",
  "Country FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Observations & ", formatC(n_obs, big.mark = ","), " & ", formatC(n_obs, big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is beetle observation share (Coleoptera observations / total insect observations). ",
  "Beetles are not directly sensitive to neonicotinoid seed treatments applied to sugar beet. ",
  "A null result supports the interpretation that the main effect on bees reflects neonicotinoid exposure ",
  "rather than correlated agricultural or environmental trends. ",
  "Standard errors clustered at the country level in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_placebo.tex")

# -------------------------------------------------------------------
# Table 4: Robustness — Event Study and Leave-One-Out
# -------------------------------------------------------------------
cat("Generating Table 4: Event Study\n")

m_es <- robust$m_es
es_names <- c("lead4", "lead3", "lead2", "lag0", "lag1", "lag2", "lag3")
es_labels <- c("$t - 4$", "$t - 3$", "$t - 2$", "$t$ (Impact)", "$t + 1$", "$t + 2$", "$t + 3$")

es_rows <- ""
for (i in seq_along(es_names)) {
  cf_es <- fmt_coef(m_es, es_names[i])
  es_rows <- paste0(es_rows, es_labels[i], " & ", cf_es[1], " \\\\\n")
  es_rows <- paste0(es_rows, " & ", cf_es[2], " \\\\\n")
}

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Bee Observation Share Around Derogation}\n",
  "\\label{tab:event}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n",
  "\\toprule\n",
  "Relative Year & Bee Share \\\\\n",
  "\\midrule\n",
  es_rows,
  "\\midrule\n",
  "Reference period & $t - 1$ \\\\\n",
  "Country FE & Yes \\\\\n",
  "Year FE & Yes \\\\\n",
  "Observations & ", formatC(nrow(panel), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event study coefficients from a TWFE regression of bee observation share ",
  "on leads and lags relative to the first derogation year ($t - 1$ omitted). ",
  "Pre-period coefficients ($t-4$ through $t-2$) test the parallel trends assumption. ",
  "Standard errors clustered at the country level in parentheses. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_event.tex")

# -------------------------------------------------------------------
# Table 5 (SDE Appendix): Standardized Effect Sizes
# -------------------------------------------------------------------
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE for main outcomes
# Bee share — binary treatment
sd_bee_share_pre <- sd(panel$bee_share[panel$year <= 2018], na.rm = TRUE)
beta_bee <- coef(results$m1)["treat_dd"]
se_bee <- se(results$m1)["treat_dd"]
sde_bee <- beta_bee / sd_bee_share_pre
se_sde_bee <- se_bee / sd_bee_share_pre

# Beetle share — placebo
sd_beetle_pre <- sd(panel$beetle_share[panel$year <= 2018], na.rm = TRUE)
beta_beetle <- coef(results$m_placebo)["treat_dd"]
se_beetle <- se(results$m_placebo)["treat_dd"]
sde_beetle <- beta_beetle / sd_beetle_pre
se_sde_beetle <- se_beetle / sd_beetle_pre

# Triple-diff (DDD) coefficient
beta_ddd <- coef(results$m2)["treat_ddd"]
se_ddd <- se(results$m2)["treat_ddd"]
sde_ddd <- beta_ddd / sd_bee_share_pre
se_sde_ddd <- se_ddd / sd_bee_share_pre

# Callaway-Sant'Anna ATT
cs_att <- results$cs_agg$overall.att
cs_se_val <- results$cs_agg$overall.se
sde_cs <- cs_att / sd_bee_share_pre
se_sde_cs <- cs_se_val / sd_bee_share_pre

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde < 0) return("Large negative") else return("Large positive")
}

# Panel B: Heterogeneity (sugar beet countries vs non-sugar-beet among derogation group)
# Sugar beet derogation countries
sb_derog_data <- panel %>% filter(sugar_beet_country == 1)
m_sb <- feols(bee_share ~ treat_dd | country_iso2 + year,
              data = sb_derog_data, cluster = ~country_iso2)
beta_sb <- coef(m_sb)["treat_dd"]
se_sb <- se(m_sb)["treat_dd"]
sd_sb_pre <- sd(sb_derog_data$bee_share[sb_derog_data$year <= 2018], na.rm = TRUE)
sde_sb <- beta_sb / sd_sb_pre
se_sde_sb <- se_sb / sd_sb_pre

# Non-sugar-beet derogation countries
nsb_derog_data <- panel %>% filter(sugar_beet_country == 0)
m_nsb <- feols(bee_share ~ treat_dd | country_iso2 + year,
               data = nsb_derog_data, cluster = ~country_iso2)
beta_nsb <- coef(m_nsb)["treat_dd"]
se_nsb <- se(m_nsb)["treat_dd"]
sd_nsb_pre <- sd(nsb_derog_data$bee_share[nsb_derog_data$year <= 2018], na.rm = TRUE)
sde_nsb <- beta_nsb / sd_nsb_pre
se_sde_nsb <- se_nsb / sd_nsb_pre

fmt5 <- function(x) formatC(x, format = "f", digits = 4)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Do emergency derogations from the EU's 2018 neonicotinoid ban reduce ",
  "pollinator populations in sugar beet growing regions? ",
  "\\textbf{Policy mechanism:} Article 53 emergency authorizations allowed 11 member states to permit ",
  "continued neonicotinoid seed treatment on sugar beet despite the EU-wide outdoor use ban, ",
  "exposing foraging pollinators to systemic insecticide residues in treated fields. ",
  "\\textbf{Outcome definition:} Bee observation share, defined as the ratio of GBIF citizen-science ",
  "Apoidea records to total Insecta records in each country-year cell, capturing relative bee ",
  "abundance while normalizing for observation effort. ",
  "\\textbf{Treatment:} Binary indicator for country-years where an Article 53 neonicotinoid derogation ",
  "was granted for sugar beet. ",
  "\\textbf{Data:} GBIF occurrence records (2013--2022) aggregated to 27 EU countries $\\times$ 10 years; ",
  "Eurostat sugar beet harvested area for treatment heterogeneity; ",
  "derogation timeline from EU Commission DG SANTE notifications. ",
  "\\textbf{Method:} Two-way fixed effects DiD with country and year fixed effects, ",
  "standard errors clustered at the country level; Callaway and Sant'Anna (2021) for heterogeneity-robust estimation. ",
  "\\textbf{Sample:} All 27 EU member states with non-zero GBIF insect records, 2013--2022. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Bee share (DiD) & ", fmt5(beta_bee), " & ", fmt5(se_bee), " & ", fmt5(sd_bee_share_pre),
  " & ", fmt5(sde_bee), " & ", fmt5(se_sde_bee), " & ", classify_sde(sde_bee), " \\\\\n",
  "Bee share (DDD) & ", fmt5(beta_ddd), " & ", fmt5(se_ddd), " & ", fmt5(sd_bee_share_pre),
  " & ", fmt5(sde_ddd), " & ", fmt5(se_sde_ddd), " & ", classify_sde(sde_ddd), " \\\\\n",
  "Bee share (C\\&S) & ", fmt5(cs_att), " & ", fmt5(cs_se_val), " & ", fmt5(sd_bee_share_pre),
  " & ", fmt5(sde_cs), " & ", fmt5(se_sde_cs), " & ", classify_sde(sde_cs), " \\\\\n",
  "Beetle share (placebo) & ", fmt5(beta_beetle), " & ", fmt5(se_beetle), " & ", fmt5(sd_beetle_pre),
  " & ", fmt5(sde_beetle), " & ", fmt5(se_sde_beetle), " & ", classify_sde(sde_beetle), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n",
  "Bee share: SB countries & ", fmt5(beta_sb), " & ", fmt5(se_sb), " & ", fmt5(sd_sb_pre),
  " & ", fmt5(sde_sb), " & ", fmt5(se_sde_sb), " & ", classify_sde(sde_sb), " \\\\\n",
  "Bee share: Non-SB countries & ", fmt5(beta_nsb), " & ", fmt5(se_nsb), " & ", fmt5(sd_nsb_pre),
  " & ", fmt5(sde_nsb), " & ", fmt5(se_sde_nsb), " & ", classify_sde(sde_nsb), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated successfully.\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_placebo.tex\n")
cat("  tables/tab4_event.tex\n")
cat("  tables/tabF1_sde.tex\n")
