# 05_tables.R — Generate all LaTeX tables
# APEP-1310: The Compression Shock

source("00_packages.R")

results <- readRDS("../data/results.rds")
robustness <- readRDS("../data/robustness.rds")
panel <- results$panel

# ── Table 1: Summary Statistics ────────────────────────────────
tab1_data <- panel %>%
  group_by(country) %>%
  summarise(
    n_obs = n(),
    n_sectors = n_distinct(sector),
    mean_emp = mean(employment, na.rm = TRUE),
    sd_emp = sd(employment, na.rm = TRUE),
    mean_wage_val = mean(mean_wage, na.rm = TRUE),
    sd_wage = sd(mean_wage, na.rm = TRUE),
    mean_kaitz = mean(kaitz, na.rm = TRUE),
    sd_kaitz = sd(kaitz, na.rm = TRUE),
    .groups = "drop"
  )

country_names <- c(LTU = "Lithuania", LVA = "Latvia", EST = "Estonia")

tab1_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics by Country, 2013--2023}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{Employment (000s)} & \\multicolumn{2}{c}{Mean Wage (EUR)} & \\multicolumn{2}{c}{Kaitz Index} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Country & Mean & SD & Mean & SD & Mean & SD \\\\"
)

for (i in 1:nrow(tab1_data)) {
  r <- tab1_data[i, ]
  tab1_tex <- c(tab1_tex,
    sprintf("\\midrule"),
    sprintf("%s & %.1f & %.1f & %.0f & %.0f & %.3f & %.3f \\\\",
            country_names[r$country], r$mean_emp, r$sd_emp,
            r$mean_wage_val, r$sd_wage, r$mean_kaitz, r$sd_kaitz))
}

# Overall statistics
overall <- panel %>%
  summarise(
    mean_emp = mean(employment, na.rm = TRUE),
    sd_emp = sd(employment, na.rm = TRUE),
    mean_wage_val = mean(mean_wage, na.rm = TRUE),
    sd_wage = sd(mean_wage, na.rm = TRUE),
    mean_kaitz = mean(kaitz, na.rm = TRUE),
    sd_kaitz = sd(kaitz, na.rm = TRUE)
  )

tab1_tex <- c(tab1_tex,
  "\\midrule",
  sprintf("All & %.1f & %.1f & %.0f & %.0f & %.3f & %.3f \\\\",
          overall$mean_emp, overall$sd_emp, overall$mean_wage_val, overall$sd_wage,
          overall$mean_kaitz, overall$sd_kaitz),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s country-sector-year observations across %d countries, %d ISIC Rev.4 sectors, and %d years (2013--2023). Employment is in thousands. Mean wage is the sector average monthly earnings in EUR from ILO STAT. Kaitz index = statutory minimum wage / sector mean wage. Lithuania's minimum wage increased from 400 to 555 EUR (+38.75\\%%) in January 2019; Latvia's was frozen at 430 EUR; Estonia's rose from 500 to 540 EUR (+8\\%%).",
          format(nrow(panel), big.mark = ","),
          n_distinct(panel$country), n_distinct(panel$sector), n_distinct(panel$year)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ── Table 2: 2018 Kaitz Indices by Sector ──────────────────────
kaitz_tab <- panel %>%
  filter(country == "LTU", year == 2018) %>%
  select(sector, sector_label, kaitz_2018, employment, mean_wage) %>%
  arrange(desc(kaitz_2018))

tab2_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Pre-Reform Kaitz Indices by Sector, Lithuania 2018}",
  "\\label{tab:kaitz}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccc}",
  "\\toprule",
  "ISIC4 & Sector & Kaitz Index & Employment (000s) & Mean Wage (EUR) \\\\",
  "\\midrule"
)

for (i in 1:nrow(kaitz_tab)) {
  r <- kaitz_tab[i, ]
  label <- ifelse(is.na(r$sector_label), r$sector, r$sector_label)
  tab2_tex <- c(tab2_tex,
    sprintf("%s & %s & %.3f & %.1f & %.0f \\\\",
            r$sector, label, r$kaitz_2018, r$employment, r$mean_wage))
}

tab2_tex <- c(tab2_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Kaitz index = statutory minimum wage (400 EUR in 2018) divided by sector average monthly earnings. Higher values indicate greater minimum wage binding. Sectors ordered by Kaitz index (most binding first). Employment and wage data from ILO STAT.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_kaitz.tex")
cat("Table 2 written.\n")

# ── Table 3: Main Results ──────────────────────────────────────
m1 <- results$main_continuous
m2 <- results$main_binary
m4 <- results$triple_diff

tab3_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Minimum Wage Binding on Sector Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "& (1) & (2) & (3) \\\\",
  "& Continuous & Binary & Triple Diff \\\\",
  "\\midrule"
)

# Column 1: continuous treatment
b1 <- coef(m1)["treat_intensity"]
s1 <- se(m1)["treat_intensity"]
p1 <- pvalue(m1)["treat_intensity"]
stars1 <- ifelse(p1 < 0.01, "***", ifelse(p1 < 0.05, "**", ifelse(p1 < 0.1, "*", "")))

tab3_tex <- c(tab3_tex,
  sprintf("LT $\\times$ Post $\\times$ Kaitz$_{2018}$ & %.3f%s & & \\\\", b1, stars1),
  sprintf("& (%.3f) & & \\\\", s1))

# Column 2: binary treatment
b2 <- coef(m2)["treat_binary"]
s2 <- se(m2)["treat_binary"]
p2 <- pvalue(m2)["treat_binary"]
stars2 <- ifelse(p2 < 0.01, "***", ifelse(p2 < 0.05, "**", ifelse(p2 < 0.1, "*", "")))

tab3_tex <- c(tab3_tex,
  sprintf("LT $\\times$ Post $\\times$ High Binding & & %.3f%s & \\\\", b2, stars2),
  sprintf("& & (%.3f) & \\\\", s2))

# Column 3: triple diff
b3_lt <- coef(m4)["lt_post_kaitz"]
s3_lt <- se(m4)["lt_post_kaitz"]
p3_lt <- pvalue(m4)["lt_post_kaitz"]
stars3_lt <- ifelse(p3_lt < 0.01, "***", ifelse(p3_lt < 0.05, "**", ifelse(p3_lt < 0.1, "*", "")))

b3_ee <- coef(m4)["ee_post_kaitz"]
s3_ee <- se(m4)["ee_post_kaitz"]
p3_ee <- pvalue(m4)["ee_post_kaitz"]
stars3_ee <- ifelse(p3_ee < 0.01, "***", ifelse(p3_ee < 0.05, "**", ifelse(p3_ee < 0.1, "*", "")))

tab3_tex <- c(tab3_tex,
  sprintf("LT $\\times$ Post $\\times$ Kaitz$_{2018}$ & & & %.3f%s \\\\", b3_lt, stars3_lt),
  sprintf("& & & (%.3f) \\\\", s3_lt),
  sprintf("EE $\\times$ Post $\\times$ Kaitz$_{2018}$ & & & %.3f%s \\\\", b3_ee, stars3_ee),
  sprintf("& & & (%.3f) \\\\", s3_ee))

tab3_tex <- c(tab3_tex,
  "\\midrule",
  "Country $\\times$ Sector FE & Yes & Yes & Yes \\\\",
  "Country $\\times$ Year FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m4), big.mark = ",")),
  sprintf("R$^2$ (within) & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]], fitstat(m4, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is ln(sector employment in thousands). Column (1): continuous treatment = Lithuania $\\times$ Post-2019 $\\times$ 2018 Kaitz index. Column (2): binary treatment = Lithuania $\\times$ Post-2019 $\\times$ above-median Kaitz. Column (3): triple difference separating Lithuania (+46\\% MW hike) from Estonia (+8\\%) with Latvia (0\\%) as the pure control. Standard errors clustered at the country-sector level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_main.tex")
cat("Table 3 written.\n")

# ── Table 4: Event Study Coefficients ──────────────────────────
m3 <- results$event_study
es_coefs <- coef(m3)
es_ses <- se(m3)
es_pvals <- pvalue(m3)

# Extract year interactions
es_names <- names(es_coefs)
es_years <- as.integer(gsub("year_f::([0-9]+):lt_kaitz", "\\1", es_names))

tab4_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects of Kaitz Binding}",
  "\\label{tab:event}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year & Coefficient & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in order(es_years)) {
  yr <- es_years[i]
  b <- es_coefs[i]
  s <- es_ses[i]
  p <- es_pvals[i]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  ci_lo <- b - 1.96 * s
  ci_hi <- b + 1.96 * s
  marker <- ifelse(yr == 2018, " (base)", "")
  if (yr == 2018) next  # skip reference year
  tab4_tex <- c(tab4_tex,
    sprintf("%d & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\",
            yr, b, stars, s, ci_lo, ci_hi))
}

tab4_tex <- c(tab4_tex,
  "\\midrule",
  "2018 (base) & --- & --- & --- \\\\",
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\", format(nobs(m3), big.mark = ",")),
  "Country $\\times$ Sector FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Country $\\times$ Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event study coefficients from regressing ln(sector employment) on year $\\times$ Lithuania $\\times$ 2018 Kaitz index interactions, with 2018 as the reference year. Pre-2019 coefficients test the parallel trends assumption: insignificant pre-trends support the identifying assumption that high- and low-binding sectors in Lithuania would have followed similar trajectories to their Baltic counterparts absent the 2019 MW hike. Standard errors clustered at the country-sector level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_tex, "../tables/tab4_event.tex")
cat("Table 4 written.\n")

# ── Table 5: Robustness ───────────────────────────────────────
m_p16 <- robustness$placebo_2016
m_p14 <- robustness$placebo_2014
m_ltlv <- robustness$lt_lv
m_ltee <- robustness$lt_ee

tab5_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness and Falsification Tests}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "& Placebo 2016 & Placebo 2014 & LT vs LV & LT vs EE \\\\",
  "\\midrule"
)

for (i in 1:4) {
  m <- list(m_p16, m_p14, m_ltlv, m_ltee)[[i]]
  tname <- names(coef(m))[1]
  b <- coef(m)[tname]
  s <- se(m)[tname]
  p <- pvalue(m)[tname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  if (i == 1) {
    tab5_tex <- c(tab5_tex,
      sprintf("Treatment & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
              b, stars,
              coef(m_p14)[1], ifelse(pvalue(m_p14)[1] < 0.01, "***", ifelse(pvalue(m_p14)[1] < 0.05, "**", ifelse(pvalue(m_p14)[1] < 0.1, "*", ""))),
              coef(m_ltlv)["treat_intensity"], ifelse(pvalue(m_ltlv)["treat_intensity"] < 0.01, "***", ifelse(pvalue(m_ltlv)["treat_intensity"] < 0.05, "**", ifelse(pvalue(m_ltlv)["treat_intensity"] < 0.1, "*", ""))),
              coef(m_ltee)["treat_intensity"], ifelse(pvalue(m_ltee)["treat_intensity"] < 0.01, "***", ifelse(pvalue(m_ltee)["treat_intensity"] < 0.05, "**", ifelse(pvalue(m_ltee)["treat_intensity"] < 0.1, "*", "")))),
      sprintf("& (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
              s, se(m_p14)[1], se(m_ltlv)["treat_intensity"], se(m_ltee)["treat_intensity"]))
    break
  }
}

tab5_tex <- c(tab5_tex,
  "\\midrule",
  sprintf("Sample & 2013--2018 & 2013--2018 & LT, LV & LT, EE \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m_p16), big.mark = ","), format(nobs(m_p14), big.mark = ","),
          format(nobs(m_ltlv), big.mark = ","), format(nobs(m_ltee), big.mark = ",")),
  sprintf("Permutation $p$-value & \\multicolumn{4}{c}{%.3f (1,000 permutations)} \\\\",
          robustness$perm_pvalue),
  "Country $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\",
  "Country $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1): placebo test using Lithuania's 2016 MW hike (+24\\%, 325$\\to$380 EUR) on the 2013--2018 sample. Column (2): placebo test using an artificial 2014 break. Columns (3)--(4): main specification estimated with alternative control countries. Permutation $p$-value from 1,000 random reassignments of Kaitz indices across sectors (two-sided). Standard errors clustered at the country-sector level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_tex, "../tables/tab5_robust.tex")
cat("Table 5 written.\n")

# ── SDE Table (Appendix F1) ───────────────────────────────────
# Extract main result for SDE computation
m_main <- results$main_continuous
beta_main <- coef(m_main)["treat_intensity"]
se_main <- se(m_main)["treat_intensity"]

# SD(Y) — unconditional SD of ln(employment)
sd_y <- sd(panel$ln_emp, na.rm = TRUE)

# SD(X) — SD of treatment intensity (continuous treatment)
sd_x <- sd(panel$treat_intensity, na.rm = TRUE)

# SDE for continuous treatment
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

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

# Wage compression result for secondary outcome
m_wage <- robustness$wage_compression
panel$ln_wage <- log(panel$mean_wage)
panel$treat_wage <- panel$lt * panel$post2019 * panel$kaitz_2018
beta_wage <- coef(m_wage)["treat_wage"]
se_wage <- se(m_wage)["treat_wage"]
sd_y_wage <- sd(panel$ln_wage, na.rm = TRUE)
sd_x_wage <- sd(panel$treat_wage, na.rm = TRUE)
sde_wage <- beta_wage * sd_x_wage / sd_y_wage
se_sde_wage <- se_wage * sd_x_wage / sd_y_wage

# Heterogeneity: high-binding vs low-binding sectors
median_k <- results$median_kaitz
panel_high <- panel %>% filter(kaitz_2018 > median_k)
panel_low <- panel %>% filter(kaitz_2018 <= median_k)

m_high <- feols(ln_emp ~ treat_intensity | cs_f + cy_f,
                data = panel_high, cluster = ~ cs_f)
m_low <- feols(ln_emp ~ treat_intensity | cs_f + cy_f,
               data = panel_low, cluster = ~ cs_f)

beta_high <- coef(m_high)["treat_intensity"]
se_high <- se(m_high)["treat_intensity"]
sd_y_high <- sd(panel_high$ln_emp, na.rm = TRUE)
sd_x_high <- sd(panel_high$treat_intensity, na.rm = TRUE)
sde_high <- beta_high * sd_x_high / sd_y_high
se_sde_high <- se_high * sd_x_high / sd_y_high

beta_low <- coef(m_low)["treat_intensity"]
se_low <- se(m_low)["treat_intensity"]
sd_y_low <- sd(panel_low$ln_emp, na.rm = TRUE)
sd_x_low <- sd(panel_low$treat_intensity, na.rm = TRUE)
sde_low <- beta_low * sd_x_low / sd_y_low
se_sde_low <- se_low * sd_x_low / sd_y_low

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Lithuania, Latvia, Estonia. ",
  "\\textbf{Research question:} Does an extreme minimum wage increase (+39\\%) reduce employment differentially in sectors where the minimum wage binds most intensely relative to Baltic peers? ",
  "\\textbf{Policy mechanism:} Lithuania's January 2019 Government Resolution No.~1303 raised the statutory monthly minimum wage from 400 to 555~EUR, compressing the wage distribution in sectors where the minimum wage exceeded 30--45\\% of the average sectoral wage, thereby increasing labor costs most sharply in accommodation, agriculture, and retail relative to ICT and finance. ",
  "\\textbf{Outcome definition:} Log sector-level employment (thousands of workers) from ILO STAT annual estimates by ISIC Rev.4 one-letter sector. ",
  "\\textbf{Treatment:} Continuous --- the Kaitz index (statutory minimum wage divided by sector mean wage) measured in 2018 Lithuania, interacted with a Lithuania indicator and a post-2019 indicator. ",
  "\\textbf{Data:} ILO STAT employment and earnings indicators for Lithuania, Latvia, and Estonia, 2013--2023, at the country-sector-year level (N~$\\approx$~", format(nrow(panel), big.mark = ","), "). ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with country$\\times$sector and country$\\times$year fixed effects; standard errors clustered at the country-sector level; inference supplemented by sector permutation test (1,000 draws). ",
  "\\textbf{Sample:} ISIC Rev.4 one-letter sectors with non-missing employment and wage data in all three Baltic countries across the full 2013--2023 panel; sectors without a computable 2018 Kaitz index are excluded. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of ln(employment) and SD($X$) is the unconditional standard deviation of the treatment intensity variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Employment & Main (continuous) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_main, sd_x, sd_y, sde_main, se_sde_main, classify(sde_main)),
  sprintf("Wages & Compression check & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_wage, sd_x_wage, sd_y_wage, sde_wage, se_sde_wage, classify(sde_wage)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Employment & High-binding sectors & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_high, sd_x_high, sd_y_high, sde_high, se_sde_high, classify(sde_high)),
  sprintf("Employment & Low-binding sectors & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_low, sd_x_low, sd_y_low, sde_low, se_sde_low, classify(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{adjustbox}",
  "\\end{table}"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\n=== All tables generated ===\n")
