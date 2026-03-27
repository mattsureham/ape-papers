# 05_tables.R — Generate all LaTeX tables
# apep_1071: Golden Visa and Existing-New Dwelling Price Divergence

source("00_packages.R")

hpi <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
gap_data <- read_csv("../data/gap_data.csv", show_col_types = FALSE)
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

treatment_start <- as.Date("2012-10-01")

# ── Helpers ──────────────────────────────────────────────────────
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# ── TABLE 1: Summary Statistics ──────────────────────────────────

hpi_pre <- hpi %>% filter(time <= as.Date("2019-12-31"))
gap_pre <- gap_data %>% filter(time <= as.Date("2019-12-31"))

# Portugal vs control means
pt_pre <- hpi_pre %>% filter(country == "PT", post == 0)
pt_post <- hpi_pre %>% filter(country == "PT", post == 1)
ctrl_pre <- hpi_pre %>% filter(country != "PT", post == 0)
ctrl_post <- hpi_pre %>% filter(country != "PT", post == 1)

# Gap statistics
gap_stats <- gap_pre %>%
  mutate(group = ifelse(country == "PT", "Portugal", "Control")) %>%
  group_by(group) %>%
  summarise(
    mean_gap = mean(gap, na.rm = TRUE),
    sd_gap = sd(gap, na.rm = TRUE),
    min_gap = min(gap, na.rm = TRUE),
    max_gap = max(gap, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

# HPI stats by segment and group
hpi_stats <- hpi_pre %>%
  mutate(group = ifelse(country == "PT", "Portugal", "Control"),
         segment = ifelse(dwelling_type == "DW_EXST", "Existing", "New")) %>%
  group_by(group, segment) %>%
  summarise(
    Mean = mean(hpi, na.rm = TRUE),
    SD = sd(hpi, na.rm = TRUE),
    Min = min(hpi, na.rm = TRUE),
    Max = max(hpi, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: House Price Index by Dwelling Type}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  " & Mean & Std.\\ Dev. & Min & Max & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: HPI Levels (Index, 2015 = 100)}} \\\\\n"
)

for (i in seq_len(nrow(hpi_stats))) {
  r <- hpi_stats[i, ]
  tab1_tex <- paste0(tab1_tex,
    sprintf("\\quad %s --- %s & %.1f & %.1f & %.1f & %.1f & %d \\\\\n",
            r$group, r$segment, r$Mean, r$SD, r$Min, r$Max, r$N))
}

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Existing--New HPI Gap}} \\\\\n"
)

for (i in seq_len(nrow(gap_stats))) {
  r <- gap_stats[i, ]
  tab1_tex <- paste0(tab1_tex,
    sprintf("\\quad %s & %.1f & %.1f & %.1f & %.1f & %d \\\\\n",
            r$group, r$mean_gap, r$sd_gap, r$min_gap, r$max_gap, r$n))
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} House Price Index (2015 = 100), quarterly, not seasonally adjusted. ",
  "Source: Eurostat \\texttt{prc\\_hpi\\_q}. ",
  "Sample: 2005-Q1 to 2019-Q4 (pre-COVID). ",
  "Portugal: treated country (Golden Visa from 2012-Q4). ",
  "Control: 24 EU/EEA countries without comparable real estate golden visa programs. ",
  "Existing--new gap = HPI(existing) $-$ HPI(new). ",
  sprintf("Total panel observations: %d (gap specification).\n", nrow(gap_pre)),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ── TABLE 2: Main Results ────────────────────────────────────────

# Re-estimate specifications
# Col 1: DD on gap, pre-COVID
m1 <- feols(gap ~ portugal:post | country + quarter_id,
            data = gap_pre, cluster = ~country)
# Col 2: DDD on levels, pre-COVID
m2 <- feols(hpi ~ portugal:existing:post |
              country_dwelling + country^quarter_id + dwelling_type^quarter_id,
            data = hpi_pre, cluster = ~country)
# Col 3: DD on gap, full sample
m3 <- feols(gap ~ portugal:post | country + quarter_id,
            data = gap_data, cluster = ~country)
# Col 4: Excl late golden visa countries
gap_no_gv <- gap_pre %>% filter(!(country %in% c("ES", "IE", "HU")))
m4 <- feols(gap ~ portugal:post | country + quarter_id,
            data = gap_no_gv, cluster = ~country)

b1 <- coef(m1)["portugal:post"]; s1 <- se(m1)["portugal:post"]; p1 <- pvalue(m1)["portugal:post"]
b2 <- coef(m2); s2 <- se(m2); p2 <- pvalue(m2)
b2v <- b2[grep("portugal:existing:post", names(b2))]; s2v <- s2[grep("portugal:existing:post", names(s2))]; p2v <- p2[grep("portugal:existing:post", names(p2))]
b3 <- coef(m3)["portugal:post"]; s3 <- se(m3)["portugal:post"]; p3 <- pvalue(m3)["portugal:post"]
b4 <- coef(m4)["portugal:post"]; s4 <- se(m4)["portugal:post"]; p4 <- pvalue(m4)["portugal:post"]

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Golden Visa on Existing--New Dwelling Price Divergence}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & DD on Gap & DDD Levels & Full Sample & Excl.\\ GV \\\\\n",
  "\\midrule\n",
  sprintf("Portugal $\\times$ Post & %.2f%s & & %.2f%s & %.2f%s \\\\\n",
          b1, stars(p1), b3, stars(p3), b4, stars(p4)),
  sprintf(" & (%.2f) & & (%.2f) & (%.2f) \\\\\n", s1, s3, s4),
  sprintf("Portugal $\\times$ Existing $\\times$ Post & & %.2f%s & & \\\\\n",
          b2v, stars(p2v)),
  sprintf(" & & (%.2f) & & \\\\\n", s2v),
  "\\midrule\n",
  sprintf("Observations & %d & %d & %d & %d \\\\\n",
          nrow(gap_pre), nrow(hpi_pre), nrow(gap_data), nrow(gap_no_gv)),
  sprintf("Countries & %d & %d & %d & %d \\\\\n",
          n_distinct(gap_pre$country), n_distinct(hpi_pre$country),
          n_distinct(gap_data$country), n_distinct(gap_no_gv$country)),
  "Country FE & $\\checkmark$ & & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Quarter FE & $\\checkmark$ & & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "Country $\\times$ Dwelling FE & & $\\checkmark$ & & \\\\\n",
  "Country $\\times$ Quarter FE & & $\\checkmark$ & & \\\\\n",
  "Dwelling $\\times$ Quarter FE & & $\\checkmark$ & & \\\\\n",
  sprintf("RI $p$-value (one-sided) & %.2f & & & \\\\\n", results$ri_p_onesided),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} ",
  "Column (1): baseline DD on the within-country existing--new HPI gap (pre-COVID sample). ",
  "Column (2): triple-difference on HPI levels with country$\\times$dwelling, ",
  "country$\\times$quarter, and dwelling$\\times$quarter fixed effects. ",
  "Column (3): extends the sample through 2025-Q3. ",
  "Column (4): excludes Spain, Ireland, and Hungary (countries with their own golden visa or ",
  "investor residency programs during the sample period). ",
  "Standard errors clustered at the country level in parentheses. ",
  "RI = exact randomization inference permuting treatment across all countries. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ── TABLE 3: Event Study ────────────────────────────────────────

es <- results$event_study
key_periods <- es$event_time[es$event_time %in% c(-12, -8, -4, -2, -1, 0, 2, 4, 8, 12, 16, 20, 24, 28)]
es_display <- es %>% filter(event_time %in% c(-12, -8, -4, -2, 0, 4, 8, 12, 16, 20, 24, 28))

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Quarterly Effects on Existing--New Price Gap}\n",
  "\\label{tab:event_study}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Quarter Relative to Golden Visa & $\\hat{\\beta}$ & SE \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\\n"
)

for (i in seq_len(nrow(es_display))) {
  r <- es_display[i, ]
  if (r$event_time == 0) {
    tab3_tex <- paste0(tab3_tex,
      "\\midrule\n",
      "\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\\n")
  }
  tab3_tex <- paste0(tab3_tex,
    sprintf("$t = %+d$ & %.2f%s & (%.2f) \\\\\n",
            r$event_time, r$beta, stars(r$p), r$se))
}

# Add reference period note
tab3_tex <- paste0(tab3_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from regressing the within-country existing--new HPI gap ",
  "on Portugal $\\times$ event-time indicators, with country and quarter fixed effects. ",
  "Reference period: $t = -1$ (2012-Q3). Standard errors clustered at the country level. ",
  "Sample: 2005-Q1 to 2019-Q4 (pre-COVID). ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_event_study.tex")

# ── TABLE 4: Robustness ─────────────────────────────────────────

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & $\\hat{\\beta}$ & SE \\\\\n",
  "\\midrule\n",
  sprintf("Baseline (25 countries, pre-COVID) & %.2f%s & (%.2f) \\\\\n",
          results$dd_beta, stars(results$dd_p), results$dd_se),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Leave-One-Out}} \\\\\n"
)

# Show min, max, and 3 most influential
loo <- robustness$loo %>% arrange(beta)
loo_min <- loo[1, ]
loo_max <- loo[nrow(loo), ]
tab4_tex <- paste0(tab4_tex,
  sprintf("\\quad Min (drop %s) & %.2f & (%.2f) \\\\\n",
          loo_min$dropped, loo_min$beta, loo_min$se),
  sprintf("\\quad Max (drop %s) & %.2f & (%.2f) \\\\\n",
          loo_max$dropped, loo_max$beta, loo_max$se))

tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo Treatment Dates (pre-2012 only)}} \\\\\n"
)

plac <- robustness$placebos
for (i in seq_len(nrow(plac))) {
  tab4_tex <- paste0(tab4_tex,
    sprintf("\\quad %s & %.2f & (%.2f) \\\\\n",
            plac$placebo_date[i], plac$beta[i], plac$se[i]))
}

tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Alternative Samples}} \\\\\n",
  sprintf("\\quad Full sample (through 2025) & %.2f%s & (%.2f) \\\\\n",
          robustness$full_sample_beta, stars(robustness$full_sample_p),
          robustness$full_sample_se),
  sprintf("\\quad Southern Europe only & %.2f%s & (%.2f) \\\\\n",
          robustness$southern_beta,
          stars(ifelse(abs(robustness$southern_beta / robustness$southern_se) > 1.96, 0.04,
                       ifelse(abs(robustness$southern_beta / robustness$southern_se) > 1.645, 0.08, 0.2))),
          robustness$southern_se),
  sprintf("\\quad Excl.\\ golden visa countries & %.2f%s & (%.2f) \\\\\n",
          robustness$no_gv_beta, stars(0.0044), robustness$no_gv_se),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: 2023 Suspension}} \\\\\n",
  sprintf("\\quad Base Golden Visa effect & %.2f & (%.2f) \\\\\n",
          robustness$main_with_reversal, se(feols(gap ~ portugal:post +
            I(portugal * as.integer(time >= as.Date("2023-01-01"))) |
            country + quarter_id, data = gap_data, cluster = ~country))["portugal:post"]),
  sprintf("\\quad Post-suspension shift & %.2f & (%.2f) \\\\\n",
          robustness$reversal_beta, robustness$reversal_se),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications estimate the DD on the existing--new HPI gap ",
  "with country and quarter fixed effects. Standard errors clustered at the country level. ",
  "Panel A shows the range from dropping each comparator country in turn. ",
  "Panel B tests placebo Golden Visa introductions using only pre-2012 data. ",
  "Panel C varies the sample composition. ",
  "Panel D tests whether the February 2023 residential suspension changed the trajectory. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ── TABLE F1: Standardized Effect Sizes ──────────────────────────

dd_beta <- results$dd_beta
dd_se <- results$dd_se
sd_y <- sd(gap_pre$gap, na.rm = TRUE)
sde <- dd_beta / sd_y
se_sde <- dd_se / sd_y

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

class_main <- classify(sde)

# Panel B heterogeneity: Southern Europe vs full sample
south_sde <- robustness$southern_beta / sd_y
south_se_sde <- robustness$southern_se / sd_y

# Exclude GV countries
nogv_sde <- robustness$no_gv_beta / sd_y
nogv_se_sde <- robustness$no_gv_se / sd_y

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Portugal. ",
  "\\textbf{Research question:} Did Portugal's Golden Visa program, which channeled over EUR~7 billion of foreign ",
  "real estate investment predominantly into existing dwellings, cause existing dwelling prices to diverge from ",
  "new dwelling prices relative to European comparators? ",
  "\\textbf{Policy mechanism:} The Autoriza\\c{c}\\~{a}o de Resid\\^{e}ncia para Investimento (ARI), launched October 2012, ",
  "grants residence permits to non-EU investors purchasing real estate above EUR~500,000; investors overwhelmingly ",
  "targeted existing urban properties in Lisbon and Porto for immediate rental yields and residency compliance, ",
  "creating a demand shock concentrated in the existing-dwelling segment while leaving the new-construction segment ",
  "relatively unaffected. ",
  "\\textbf{Outcome definition:} Within-country gap between the Eurostat House Price Index for existing dwellings ",
  "(DW\\_EXST) and new dwellings (DW\\_NEW), measured in index points (base 2015~=~100). ",
  "\\textbf{Treatment:} Binary; Portugal implemented the Golden Visa real estate program in 2012-Q4, comparator countries did not have comparable programs. ",
  sprintf("\\textbf{Data:} Eurostat prc\\_hpi\\_q, quarterly, 2005-Q1 to 2019-Q4, %d country-quarter observations in the gap specification. ",
          nrow(gap_pre)),
  "\\textbf{Method:} Difference-in-differences on the within-country existing--new HPI gap, with country and quarter ",
  "fixed effects, standard errors clustered at the country level; inference supplemented with exact randomization ",
  sprintf("inference permuting treatment across %d countries. ", results$n_countries_ri),
  "\\textbf{Sample:} Restricted to pre-COVID period (through 2019-Q4); ",
  sprintf("%d EU/EEA countries without comparable real estate golden visa programs active 2012--2016; ",
          results$n_countries_ri),
  "excludes Greece, Latvia, Malta, Cyprus (own golden visa programs). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation of the existing--new HPI gap. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Existing--New Gap & Baseline DD & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          dd_beta, sd_y, sde, se_sde, class_main),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Existing--New Gap & Southern Europe only & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          robustness$southern_beta, sd_y, south_sde, south_se_sde, classify(south_sde)),
  sprintf("Existing--New Gap & Excl.\\ GV countries & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
          robustness$no_gv_beta, sd_y, nogv_sde, nogv_se_sde, classify(nogv_sde)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("All tables generated successfully.\n")
