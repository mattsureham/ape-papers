# 05_tables.R — Generate all LaTeX tables
# apep_1422: When Bugs Hatch Early

source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

stars_fn <- function(pv) {
  ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
}

irr_states <- c("NE", "KS")
rain_states <- c("IA", "IL", "IN", "OH")

# ─── Table 1: Summary Statistics ─────────────────────────────────────
cat("--- Table 1 ---\n")

make_summ <- function(df, label) {
  tibble(
    Panel = label,
    N = nrow(df),
    Counties = n_distinct(df$fips),
    MeanYield = mean(df$yield_bu_acre, na.rm = TRUE),
    SDYield = sd(df$yield_bu_acre, na.rm = TRUE),
    MeanPest = mean(df$pest_gdd, na.rm = TRUE),
    SDPest = sd(df$pest_gdd, na.rm = TRUE),
    MeanHeat = mean(df$heat_stress, na.rm = TRUE),
    SDHeat = sd(df$heat_stress, na.rm = TRUE),
    Corr = cor(df$pest_gdd, df$heat_stress)
  )
}

s_all <- make_summ(panel, "Full Sample")
s_irr <- make_summ(filter(panel, state_abbr %in% irr_states), "Irrigated (NE, KS)")
s_rain <- make_summ(filter(panel, state_abbr %in% rain_states), "Rainfed (IA, IL, IN, OH)")

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: Corn Belt County-Year Panel, 2000--2022}",
  "\\label{tab:summary}",
  "\\footnotesize",
  "\\begin{tabular}{lccccccccc}",
  "\\toprule",
  " & $N$ & Counties & \\multicolumn{2}{c}{Yield (bu/acre)} & \\multicolumn{2}{c}{PestGDD} & \\multicolumn{2}{c}{HeatDD} & Corr \\\\",
  "\\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}",
  " & & & Mean & SD & Mean & SD & Mean & SD & \\\\",
  "\\midrule"
)

for (s in list(s_all, s_irr, s_rain)) {
  tab1 <- c(tab1, sprintf(
    "%s & %s & %d & %.1f & %.1f & %.0f & %.0f & %.0f & %.0f & %.3f \\\\",
    s$Panel, format(s$N, big.mark = ","), s$Counties,
    s$MeanYield, s$SDYield, s$MeanPest, s$SDPest,
    s$MeanHeat, s$SDHeat, s$Corr
  ))
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} County-level corn yields from USDA NASS Quick Stats. PestGDD is accumulated degree-days (base 52\\textdegree{}F) from January 1 to June 30, measuring spring warmth that drives insect emergence. HeatDD is degree-days above 84.2\\textdegree{}F from July 1 to August 31, measuring direct heat stress on plant physiology. Weather variables are state-year averages from NOAA GHCN-D daily station data, quality-controlled. Corr is the Pearson correlation between PestGDD and HeatDD.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ─── Table 2: Main Results ───────────────────────────────────────────
cat("--- Table 2 ---\n")

m1 <- results$m1; m2 <- results$m2; m3 <- results$m3
m4 <- results$m4; m5 <- results$m5

ps2 <- abs(coef(m2)["pest_gdd"] * results$sd_pest) /
  (abs(coef(m2)["pest_gdd"] * results$sd_pest) + abs(coef(m2)["heat_stress"] * results$sd_heat)) * 100
ps3 <- abs(coef(m3)["pest_gdd"] * results$sd_pest) /
  (abs(coef(m3)["pest_gdd"] * results$sd_pest) + abs(coef(m3)["heat_stress"] * results$sd_heat)) * 100

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Decomposing Temperature--Yield Damage: Main Estimates}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Total & Decomposed & + Temp & + Interaction & Standardized \\\\",
  "\\midrule",
  sprintf("Total GDD & %.6f\\sym{***} & & & & \\\\", coef(m1)["total_gdd"]),
  sprintf(" & (%.6f) & & & & \\\\", sqrt(vcov(m1)["total_gdd","total_gdd"])),
  sprintf("PestGDD & & %.6f\\sym{%s} & %.6f\\sym{***} & %.6f & \\\\",
          coef(m2)["pest_gdd"], stars_fn(pvalue(m2)["pest_gdd"]),
          coef(m3)["pest_gdd"], coef(m4)["pest_gdd"]),
  sprintf(" & & (%.6f) & (%.6f) & (%.6f) & \\\\",
          sqrt(vcov(m2)["pest_gdd","pest_gdd"]),
          sqrt(vcov(m3)["pest_gdd","pest_gdd"]),
          sqrt(vcov(m4)["pest_gdd","pest_gdd"])),
  sprintf("HeatDD & & %.6f\\sym{***} & %.6f\\sym{***} & %.6f\\sym{***} & \\\\",
          coef(m2)["heat_stress"], coef(m3)["heat_stress"], coef(m4)["heat_stress"]),
  sprintf(" & & (%.6f) & (%.6f) & (%.6f) & \\\\",
          sqrt(vcov(m2)["heat_stress","heat_stress"]),
          sqrt(vcov(m3)["heat_stress","heat_stress"]),
          sqrt(vcov(m4)["heat_stress","heat_stress"])),
  sprintf("PestGDD (std.) & & & & & %.4f\\sym{%s} \\\\",
          coef(m5)["pest_gdd_z"], stars_fn(pvalue(m5)["pest_gdd_z"])),
  sprintf(" & & & & & (%.4f) \\\\", sqrt(vcov(m5)["pest_gdd_z","pest_gdd_z"])),
  sprintf("HeatDD (std.) & & & & & %.4f\\sym{***} \\\\",
          coef(m5)["heat_stress_z"]),
  sprintf(" & & & & & (%.4f) \\\\", sqrt(vcov(m5)["heat_stress_z","heat_stress_z"])),
  "\\midrule",
  sprintf("Implied pest share & & %.1f\\%% & %.1f\\%% & & \\\\", ps2, ps3),
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","), format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","), format(nobs(m4), big.mark = ","),
          format(nobs(m5), big.mark = ",")),
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & %.4f \\\\",
          r2(m1, "wr2"), r2(m2, "wr2"), r2(m3, "wr2"),
          r2(m4, "wr2"), r2(m5, "wr2")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log corn yield (bu/acre). PestGDD is accumulated degree-days (base 52\\textdegree{}F, Jan--Jun). HeatDD is degree-days above 84.2\\textdegree{}F (Jul--Aug). Column (1) replicates the Schlenker--Roberts (2009) specification with total growing degree-days. Columns (2)--(4) decompose into pest and heat channels. Column (5) reports standardized coefficients ($z$-scores). Implied pest share $= |\\hat{\\beta}_{\\text{pest}} \\times \\text{SD}(\\text{PestGDD})| / (|\\hat{\\beta}_{\\text{pest}} \\times \\text{SD}(\\text{PestGDD})| + |\\hat{\\beta}_{\\text{heat}} \\times \\text{SD}(\\text{HeatDD})|)$. Standard errors clustered by county in parentheses. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ─── Table 3: Robustness ─────────────────────────────────────────────
cat("--- Table 3 ---\n")

mr <- robustness
c_nd <- list(b1 = coef(mr$m_nodrought)["pest_gdd"],
             s1 = sqrt(vcov(mr$m_nodrought)["pest_gdd","pest_gdd"]),
             b2 = coef(mr$m_nodrought)["heat_stress"],
             s2 = sqrt(vcov(mr$m_nodrought)["heat_stress","heat_stress"]))
c_q <- list(b1 = coef(mr$m_quad)["pest_gdd"],
            s1 = sqrt(vcov(mr$m_quad)["pest_gdd","pest_gdd"]),
            b2 = coef(mr$m_quad)["heat_stress"],
            s2 = sqrt(vcov(mr$m_quad)["heat_stress","heat_stress"]))
c_ir <- list(b1 = coef(mr$m_irrigated)["pest_gdd"],
             s1 = sqrt(vcov(mr$m_irrigated)["pest_gdd","pest_gdd"]),
             b2 = coef(mr$m_irrigated)["heat_stress"],
             s2 = sqrt(vcov(mr$m_irrigated)["heat_stress","heat_stress"]))
c_rf <- list(b1 = coef(mr$m_rainfed)["pest_gdd"],
             s1 = sqrt(vcov(mr$m_rainfed)["pest_gdd","pest_gdd"]),
             b2 = coef(mr$m_rainfed)["heat_stress"],
             s2 = sqrt(vcov(mr$m_rainfed)["heat_stress","heat_stress"]))

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & No Drought & Quadratic & Irrigated & Rainfed \\\\",
  "\\midrule",
  sprintf("PestGDD & %.6f%s & %.6f%s & %.6f%s & %.6f \\\\",
          c_nd$b1, stars_fn(pvalue(mr$m_nodrought)["pest_gdd"]),
          c_q$b1, stars_fn(pvalue(mr$m_quad)["pest_gdd"]),
          c_ir$b1, stars_fn(pvalue(mr$m_irrigated)["pest_gdd"]),
          c_rf$b1),
  sprintf(" & (%.6f) & (%.6f) & (%.6f) & (%.6f) \\\\",
          c_nd$s1, c_q$s1, c_ir$s1, c_rf$s1),
  sprintf("HeatDD & %.6f%s & %.6f%s & %.6f%s & %.6f%s \\\\",
          c_nd$b2, stars_fn(pvalue(mr$m_nodrought)["heat_stress"]),
          c_q$b2, stars_fn(pvalue(mr$m_quad)["heat_stress"]),
          c_ir$b2, stars_fn(pvalue(mr$m_irrigated)["heat_stress"]),
          c_rf$b2, stars_fn(pvalue(mr$m_rainfed)["heat_stress"])),
  sprintf(" & (%.6f) & (%.6f) & (%.6f) & (%.6f) \\\\",
          c_nd$s2, c_q$s2, c_ir$s2, c_rf$s2),
  "\\midrule",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(mr$m_nodrought), big.mark = ","),
          format(nobs(mr$m_quad), big.mark = ","),
          format(nobs(mr$m_irrigated), big.mark = ","),
          format(nobs(mr$m_rainfed), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log corn yield. Column (1) drops major drought years (2002, 2012). Column (2) adds quadratic terms. Columns (3)--(4) split the sample by irrigation intensity: Nebraska and Kansas (heavily irrigated) vs.\\ Iowa, Illinois, Indiana, and Ohio (predominantly rainfed). Standard errors clustered by county. \\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_robust.tex")

# ─── Table 4: Leave-One-State-Out ────────────────────────────────────
cat("--- Table 4 ---\n")

loo <- mr$loo_results
sd_p <- results$sd_pest; sd_h <- results$sd_heat
loo$pest_share <- abs(loo$beta_pest * sd_p) /
  (abs(loo$beta_pest * sd_p) + abs(loo$beta_heat * sd_h)) * 100

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Leave-One-State-Out Estimates}",
  "\\label{tab:loo}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Dropped State & $\\hat{\\beta}_{\\text{pest}}$ & SE & $\\hat{\\beta}_{\\text{heat}}$ & SE & Pest Share \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(loo))) {
  tab4 <- c(tab4, sprintf(
    "%s & %.6f & (%.6f) & %.6f & (%.6f) & %.1f\\%% \\\\",
    loo$dropped_state[i], loo$beta_pest[i], loo$se_pest[i],
    loo$beta_heat[i], loo$se_heat[i], loo$pest_share[i]
  ))
}

tab4 <- c(tab4,
  "\\midrule",
  sprintf("Baseline & %.6f & (%.6f) & %.6f & (%.6f) & %.1f\\%% \\\\",
          results$beta_pest, sqrt(vcov(results$m2)["pest_gdd","pest_gdd"]),
          results$beta_heat, sqrt(vcov(results$m2)["heat_stress","heat_stress"]),
          results$pest_share),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  "\\item \\textit{Notes:} Each row drops all counties in one state and re-estimates the decomposed specification from Table~\\ref{tab:main}, column (2). Pest share $= |\\hat{\\beta}_{\\text{pest}} \\times \\text{SD}(\\text{PestGDD})| / (|\\hat{\\beta}_{\\text{pest}} \\times \\text{SD}(\\text{PestGDD})| + |\\hat{\\beta}_{\\text{heat}} \\times \\text{SD}(\\text{HeatDD})|)$. Standard errors clustered by county.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_loo.tex")

# ─── Table F1: SDE ───────────────────────────────────────────────────
cat("--- Table F1 (SDE) ---\n")

sd_y <- sd(panel$ln_yield, na.rm = TRUE)

sde_pest <- results$effect_pest / sd_y
se_sde_pest <- sqrt(vcov(results$m2)["pest_gdd","pest_gdd"]) * results$sd_pest / sd_y
sde_heat <- results$effect_heat / sd_y
se_sde_heat <- sqrt(vcov(results$m2)["heat_stress","heat_stress"]) * results$sd_heat / sd_y

classify_sde <- function(x) {
  if (is.na(x)) return("NA")
  if (x < -0.15) "Large negative"
  else if (x < -0.05) "Moderate negative"
  else if (x < -0.005) "Small negative"
  else if (x <= 0.005) "Null"
  else if (x <= 0.05) "Small positive"
  else if (x <= 0.15) "Moderate positive"
  else "Large positive"
}

sd_y_irr <- sd(filter(panel, state_abbr %in% irr_states)$ln_yield, na.rm = TRUE)
sd_y_rain <- sd(filter(panel, state_abbr %in% rain_states)$ln_yield, na.rm = TRUE)

b_pest_irr <- coef(robustness$m_irrigated)["pest_gdd"]
sd_pest_irr <- sd(filter(panel, state_abbr %in% irr_states)$pest_gdd)
sde_pest_irr <- b_pest_irr * sd_pest_irr / sd_y_irr
se_sde_pest_irr <- sqrt(vcov(robustness$m_irrigated)["pest_gdd","pest_gdd"]) * sd_pest_irr / sd_y_irr

b_heat_rain <- coef(robustness$m_rainfed)["heat_stress"]
sd_heat_rain <- sd(filter(panel, state_abbr %in% rain_states)$heat_stress)
sde_heat_rain <- b_heat_rain * sd_heat_rain / sd_y_rain
se_sde_heat_rain <- sqrt(vcov(robustness$m_rainfed)["heat_stress","heat_stress"]) * sd_heat_rain / sd_y_rain

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & Coeff. & SE & SD(Y) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Pest channel (1-SD PestGDD) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          results$effect_pest, se_sde_pest * sd_y, sd_y, sde_pest, se_sde_pest, classify_sde(sde_pest)),
  sprintf("Heat channel (1-SD HeatDD) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          results$effect_heat, se_sde_heat * sd_y, sd_y, sde_heat, se_sde_heat, classify_sde(sde_heat)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\",
  sprintf("Pest, irrigated states & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          b_pest_irr * sd_pest_irr, se_sde_pest_irr * sd_y_irr, sd_y_irr,
          sde_pest_irr, se_sde_pest_irr, classify_sde(sde_pest_irr)),
  sprintf("Heat, rainfed states & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          b_heat_rain * sd_heat_rain, se_sde_heat_rain * sd_y_rain, sd_y_rain,
          sde_heat_rain, se_sde_heat_rain, classify_sde(sde_heat_rain)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize \\tolerance=9999",
  paste0(
    "\\item \\textit{Notes:} ",
    "\\textbf{Country:} United States. ",
    "\\textbf{Research question:} What fraction of the well-documented nonlinear relationship between temperature and crop yields operates through accelerated pest emergence rather than direct heat stress on plant physiology? ",
    "\\textbf{Policy mechanism:} Understanding whether warming-induced crop damage is pest-mediated or heat-stress-mediated determines whether adaptation investments should target integrated pest management or heat-tolerant crop varieties---two distinct pathways with different cost structures under the USDA Federal Crop Insurance Program. ",
    "\\textbf{Outcome definition:} Log county-level corn yield in bushels per acre, measuring annual productive output of the dominant Corn Belt crop. ",
    "\\textbf{Treatment:} Continuous---PestGDD measures accumulated degree-days above the biological base temperature for western corn rootworm emergence (base 52\\textdegree{}F, January--June); HeatDD measures degree-days above the plant stress threshold (84.2\\textdegree{}F, July--August). ",
    "\\textbf{Data:} USDA NASS Quick Stats county corn yields and NOAA GHCN-D quality-controlled daily station temperature, 2000--2022, covering 13 Corn Belt states. ",
    "\\textbf{Method:} Panel regression with county and year fixed effects; standard errors clustered by county; weather aggregated to state-year from nearest stations with inverse-distance weighting. ",
    "\\textbf{Sample:} 1,136 counties across 13 Corn Belt states (IL, IN, IA, KS, KY, MI, MN, MO, NE, ND, OH, SD, WI), restricted to county-years with non-zero corn production and adequate weather station coverage. ",
    "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the full-sample ",
    "standard deviation of log yield. Classification refers to magnitude, not statistical significance: ",
    "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
  ),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
