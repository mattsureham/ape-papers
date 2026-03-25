# 05_tables.R — All Tables for apep_0892
# Moldova Wine Embargo: Weaponized Trade and Local Economic Costs

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]
vineyard <- fread(file.path(data_dir, "vineyard_shares.csv"))
trade <- fread(file.path(data_dir, "trade_clean.csv"))
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel[post == 0]
post_d <- panel[post == 1]

# By high/low wine groups
stats_pre_high <- pre[high_wine == 1, .(
  Mean = mean(mean, na.rm = TRUE),
  SD = sd(mean, na.rm = TRUE),
  N_raions = length(unique(raion)),
  N_obs = .N
)]
stats_pre_low <- pre[high_wine == 0, .(
  Mean = mean(mean, na.rm = TRUE),
  SD = sd(mean, na.rm = TRUE),
  N_raions = length(unique(raion)),
  N_obs = .N
)]

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Nighttime Light Radiance by Wine Dependence}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-Embargo (Jan 2012--Aug 2013)} & \\multicolumn{2}{c}{Post-Embargo (Sep 2013--May 2024)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & High Wine & Low Wine & High Wine & Low Wine \\\\",
  "\\hline",
  sprintf("Mean radiance (nW/cm$^2$/sr) & %.3f & %.3f & %.3f & %.3f \\\\",
          pre[high_wine == 1, mean(mean, na.rm = TRUE)],
          pre[high_wine == 0, mean(mean, na.rm = TRUE)],
          post_d[high_wine == 1, mean(mean, na.rm = TRUE)],
          post_d[high_wine == 0, mean(mean, na.rm = TRUE)]),
  sprintf("SD & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          pre[high_wine == 1, sd(mean, na.rm = TRUE)],
          pre[high_wine == 0, sd(mean, na.rm = TRUE)],
          post_d[high_wine == 1, sd(mean, na.rm = TRUE)],
          post_d[high_wine == 0, sd(mean, na.rm = TRUE)]),
  sprintf("Log mean radiance & %.3f & %.3f & %.3f & %.3f \\\\",
          pre[high_wine == 1, mean(log_mean, na.rm = TRUE)],
          pre[high_wine == 0, mean(log_mean, na.rm = TRUE)],
          post_d[high_wine == 1, mean(log_mean, na.rm = TRUE)],
          post_d[high_wine == 0, mean(log_mean, na.rm = TRUE)]),
  sprintf("Vineyard ha per capita & %.3f & %.3f & --- & --- \\\\",
          vineyard[high_wine == 1, mean(vine_per_cap)],
          vineyard[high_wine == 0, mean(vine_per_cap)]),
  sprintf("Raions & %d & %d & %d & %d \\\\",
          pre[high_wine == 1, length(unique(raion))],
          pre[high_wine == 0, length(unique(raion))],
          post_d[high_wine == 1, length(unique(raion))],
          post_d[high_wine == 0, length(unique(raion))]),
  sprintf("Raion-months & %s & %s & %s & %s \\\\",
          format(nrow(pre[high_wine == 1]), big.mark = ","),
          format(nrow(pre[high_wine == 0]), big.mark = ","),
          format(nrow(post_d[high_wine == 1]), big.mark = ","),
          format(nrow(post_d[high_wine == 0]), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Nighttime light radiance from VIIRS monthly composites (EOAtlas, 2012--2024).",
  "High Wine = above-median vineyard hectares per capita from the 2011 General Agricultural Census.",
  "37 administrative units (raions) observed monthly. Embargo date: September 2013.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_sumstats.tex"))
cat("  Saved tab1_sumstats.tex\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results
# ═══════════════════════════════════════════════════════════════════════
cat("=== Table 2: Main Results ===\n")

# Extract coefficients and SEs
get_results <- function(model) {
  ct <- coeftable(model)
  list(
    coef = ct[1, 1],
    se = ct[1, 2],
    pval = ct[1, 4],
    n = model$nobs,
    r2 = fitstat(model, "r2")$r2,
    wr2 = fitstat(model, "wr2")$wr2
  )
}

r1 <- get_results(m1)
r2 <- get_results(m2)
r3 <- get_results(m3)
r4 <- get_results(m4)

stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Wine Embargo on Nighttime Light Radiance}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Level & Log & Level & Log \\\\",
  "\\hline",
  "\\\\[-1em]",
  sprintf("Vineyard Share $\\times$ Post & %.3f%s & %.3f%s & & \\\\",
          r1$coef, stars(r1$pval), r2$coef, stars(r2$pval)),
  sprintf(" & (%.3f) & (%.3f) & & \\\\", r1$se, r2$se),
  "\\\\[-0.5em]",
  sprintf("High Wine $\\times$ Post & & & %.3f%s & %.3f%s \\\\",
          r3$coef, stars(r3$pval), r4$coef, stars(r4$pval)),
  sprintf(" & & & (%.3f) & (%.3f) \\\\", r3$se, r4$se),
  "\\\\[-0.5em]",
  "\\hline",
  "Treatment & Continuous & Continuous & Binary & Binary \\\\",
  "Raion FE & Yes & Yes & Yes & Yes \\\\",
  "Year-month FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","),
          format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","),
          format(r4$n, big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          r1$r2, r2$r2, r3$r2, r4$r2),
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f \\\\",
          r1$wr2, r2$wr2, r3$wr2, r4$wr2),
  sprintf("Bootstrap SE & & [%.3f] & & \\\\", boot_se),
  sprintf("Bootstrap $p$ & & %.3f & & \\\\", boot_pval),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Standard errors clustered at the raion level in parentheses.",
  "Pairs cluster bootstrap SE in brackets (999 replications).",
  "Vineyard Share = vineyard hectares per capita from 2011 Agricultural Census.",
  "High Wine = above-median vineyard share.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: Period-Specific Effects
# ═══════════════════════════════════════════════════════════════════════
cat("=== Table 3: Period-Specific Effects ===\n")

ct_periods <- coeftable(m_periods)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Period-Specific Effects of the Wine Embargo}",
  "\\label{tab:periods}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & Log Radiance & Log Radiance \\\\",
  " & Pooled Post & By Period \\\\",
  "\\hline",
  "\\\\[-1em]",
  sprintf("Vineyard Share $\\times$ Post & %.3f & \\\\", coef(m2)[1]),
  sprintf(" & (%.3f) & \\\\", se(m2)[1]),
  "\\\\[-0.5em]",
  sprintf("Vineyard Share $\\times$ Short Run & & %.3f \\\\", ct_periods[1, 1]),
  sprintf("\\quad (Sep 2013--May 2014) & & (%.3f) \\\\", ct_periods[1, 2]),
  "\\\\[-0.5em]",
  sprintf("Vineyard Share $\\times$ Medium Run & & %.3f \\\\", ct_periods[2, 1]),
  sprintf("\\quad (Jun 2014--Dec 2016) & & (%.3f) \\\\", ct_periods[2, 2]),
  "\\\\[-0.5em]",
  sprintf("Vineyard Share $\\times$ Long Run & & %.3f \\\\", ct_periods[3, 1]),
  sprintf("\\quad (Jan 2017--May 2024) & & (%.3f) \\\\", ct_periods[3, 2]),
  "\\\\[-0.5em]",
  "\\hline",
  "Raion FE & Yes & Yes \\\\",
  "Year-month FE & Yes & Yes \\\\",
  sprintf("Observations & %s & %s \\\\",
          format(m2$nobs, big.mark = ","),
          format(m_periods$nobs, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable: log mean nighttime radiance.",
  "Standard errors clustered at the raion level.",
  "Short Run = September 2013 to May 2014 (pre-EU Association Agreement).",
  "Medium Run = June 2014 to December 2016 (EU agreement signed, initial adjustment).",
  "Long Run = January 2017 to May 2024 (full adjustment).",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_periods.tex"))
cat("  Saved tab3_periods.tex\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 4: Robustness
# ═══════════════════════════════════════════════════════════════════════
cat("=== Table 4: Robustness ===\n")

r_placebo <- get_results(placebo_m)
r_notrans <- get_results(m_no_trans)
r_nochi <- get_results(m_no_chi)
r_sum <- get_results(m_sum)

# Trend-controlled model
ct_trend <- coeftable(m_trend)
trend_coef <- ct_trend["vine_per_cap:post", 1]
trend_se <- ct_trend["vine_per_cap:post", 2]
trend_pval <- ct_trend["vine_per_cap:post", 4]

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Coefficient & SE & $N$ \\\\",
  "\\hline",
  "\\\\[-1em]",
  sprintf("\\textit{Panel A: Main specification} & %.3f & (%.3f) & %s \\\\",
          coef(m2)[1], se(m2)[1], format(m2$nobs, big.mark = ",")),
  "\\\\[-0.5em]",
  sprintf("\\textit{Panel B: Placebo (Sep 2012)} & %.3f%s & (%.3f) & %s \\\\",
          r_placebo$coef, stars(r_placebo$pval), r_placebo$se,
          format(r_placebo$n, big.mark = ",")),
  "\\\\[-0.5em]",
  sprintf("\\textit{Panel C: Raion-specific trends} & %.3f & (%.3f) & %s \\\\",
          trend_coef, trend_se, format(m_trend$nobs, big.mark = ",")),
  "\\\\[-0.5em]",
  sprintf("\\textit{Panel D: Exclude Transnistria} & %.3f & (%.3f) & %s \\\\",
          r_notrans$coef, r_notrans$se, format(r_notrans$n, big.mark = ",")),
  "\\\\[-0.5em]",
  sprintf("\\textit{Panel E: Exclude Chisinau} & %.3f & (%.3f) & %s \\\\",
          r_nochi$coef, r_nochi$se, format(r_nochi$n, big.mark = ",")),
  "\\\\[-0.5em]",
  sprintf("\\textit{Panel F: Log sum radiance} & %.3f & (%.3f) & %s \\\\",
          r_sum$coef, r_sum$se, format(r_sum$n, big.mark = ",")),
  "\\\\[-0.5em]",
  "\\hline",
  sprintf("Randomization inference $p$-value & \\multicolumn{3}{c}{%.3f} \\\\", ri_pval),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable: log mean nighttime radiance in all panels except F.",
  "All specifications include raion and year-month fixed effects.",
  "Standard errors clustered at the raion level. Panel B uses only pre-embargo observations",
  "(Jan 2012--Aug 2013) with a placebo treatment date of September 2012.",
  "Panel C adds raion-specific linear time trends. Randomization inference",
  "permutes vineyard shares across raions (999 replications).",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robust.tex"))
cat("  Saved tab4_robust.tex\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 5 (APPENDIX): Event Study Coefficients
# ═══════════════════════════════════════════════════════════════════════
cat("=== Table 5: Event Study ===\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

# Parse event bins from coefficient names
es_coefs[, bin := as.integer(gsub("event_bin::(-?\\d+):vine_per_cap", "\\1", term))]
es_coefs <- es_coefs[order(bin)]

# Build event study table
es_rows <- character()
for (i in 1:nrow(es_coefs)) {
  row <- es_coefs[i]
  bin_label <- ifelse(row$bin < 0,
                      paste0("$t", row$bin, "$"),
                      paste0("$t+", row$bin, "$"))
  es_rows <- c(es_rows,
               sprintf("%s & %.3f%s & (%.3f) \\\\",
                       bin_label, row$estimate, stars(row$pvalue), row$se))
}

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Bimonthly Coefficients}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Estimate & SE \\\\",
  "\\hline",
  "\\\\[-1em]",
  "\\textit{Pre-embargo} & & \\\\",
  es_rows[es_coefs$bin < 0],
  "\\\\[-0.5em]",
  "\\textit{Post-embargo} & & \\\\",
  es_rows[es_coefs$bin >= 0],
  "\\\\[-0.5em]",
  "\\hline",
  "Reference period & \\multicolumn{2}{c}{$t-2$ (Jul--Aug 2013)} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(es_model$nobs, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from interacting bimonthly event-time indicators",
  "with vineyard hectares per capita. Reference period: two months before embargo",
  "(July--August 2013). Includes raion and year-month fixed effects.",
  "Standard errors clustered at the raion level.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(table_dir, "tab5_eventstudy.tex"))
cat("  Saved tab5_eventstudy.tex\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Size (MANDATORY)
# ═══════════════════════════════════════════════════════════════════════
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Pre-treatment SD for SDE denominator
pre_sd <- panel[post == 0, sd(log_mean, na.rm = TRUE)]

# Main outcomes and their SDEs
# Model 2 (log, continuous): continuous treatment
# Continuous SDE = beta * SD(X) / SD(Y)
sd_x <- sd(unique(panel[, .(raion, vine_per_cap)])$vine_per_cap)

sde_continuous <- coef(m2)[1] * sd_x / pre_sd
se_sde_continuous <- se(m2)[1] * sd_x / pre_sd

# Model 4 (log, binary): binary treatment
sde_binary <- coef(m4)[1] / pre_sd
se_sde_binary <- se(m4)[1] / pre_sd

# Trend-controlled (preferred)
sde_trend <- trend_coef * sd_x / pre_sd
se_sde_trend <- trend_se * sd_x / pre_sd

# Short-run effect
ct_p <- coeftable(m_periods)
sde_shortrun <- ct_p[1, 1] * sd_x / pre_sd
se_sde_shortrun <- ct_p[1, 2] * sd_x / pre_sd

classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde >= 0.005 & sde < 0.05) return("Small positive")
  if (sde >= 0.05 & sde < 0.15) return("Moderate positive")
  if (sde >= 0.15) return("Large positive")
  if (sde <= -0.005 & sde > -0.05) return("Small negative")
  if (sde <= -0.05 & sde > -0.15) return("Moderate negative")
  if (sde <= -0.15) return("Large negative")
}

# --- Heterogeneous panel (sample splits) ---
# Split by urbanization: Chisinau + Balti + Bender vs. rural raions
urban_raions <- c("Chisinau", "Balti", "Bender")
panel[, urban := as.integer(raion %in% urban_raions)]

m_rural <- feols(log_mean ~ vine_per_cap:post | raion + ym_fe,
                 data = panel[urban == 0], cluster = ~raion)
m_urban <- feols(log_mean ~ vine_per_cap:post | raion + ym_fe,
                 data = panel[urban == 1], cluster = ~raion)

sde_rural <- coef(m_rural)[1] * sd_x / pre_sd
se_sde_rural <- se(m_rural)[1] * sd_x / pre_sd
sde_urban <- coef(m_urban)[1] * sd_x / pre_sd
se_sde_urban <- se(m_urban)[1] * sd_x / pre_sd

# SDE table notes (for Oracle training data)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Moldova. ",
  "\\textbf{Research question:} Does Russia's September 2013 wine import embargo impose ",
  "subnational economic costs on wine-dependent administrative districts in Moldova? ",
  "\\textbf{Policy mechanism:} Russia banned Moldovan wine imports in September 2013 as ",
  "geopolitical retaliation for Moldova's EU Association Agreement negotiations, collapsing ",
  "bilateral wine exports by 75\\% (\\$40M to \\$10M annually) and disproportionately affecting ",
  "raions with high pre-embargo vineyard concentration. ",
  "\\textbf{Outcome definition:} Monthly mean VIIRS nighttime light radiance (nW/cm$^2$/sr) ",
  "at the administrative district (raion) level, a satellite-based proxy for local economic activity. ",
  "\\textbf{Treatment:} Continuous --- vineyard hectares per capita from the 2011 General ",
  "Agricultural Census, measuring pre-determined exposure to the wine export shock. ",
  "\\textbf{Data:} EOAtlas VIIRS monthly nightlights (2012--2024), 37 raions, 5,365 raion-months ",
  "after excluding missing observations; UN Comtrade for aggregate trade validation. ",
  "\\textbf{Method:} Bartik shift-share DiD with raion and year-month fixed effects, standard ",
  "errors clustered at raion level, pairs cluster bootstrap (999 replications), and ",
  "randomization inference (999 permutations). ",
  "\\textbf{Sample:} All 37 Moldovan administrative districts (raions) including Gagauzia ",
  "autonomous region and Transnistria; 20 pre-embargo months and 129 post-embargo months. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-raion standard ",
  "deviation of vineyard hectares per capita (0.043) and SD($Y$) is the pre-embargo standard deviation of log ",
  "mean radiance (0.653). Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\\\[-1em]",
  "\\textit{Panel A: Pooled} & & & & & & \\\\",
  sprintf("Log radiance (continuous) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m2)[1], se(m2)[1], pre_sd, sde_continuous, se_sde_continuous,
          classify_sde(sde_continuous)),
  sprintf("Log radiance (w/ trends) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          trend_coef, trend_se, pre_sd, sde_trend, se_sde_trend,
          classify_sde(sde_trend)),
  sprintf("Log radiance (short run) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          ct_p[1, 1], ct_p[1, 2], pre_sd, sde_shortrun, se_sde_shortrun,
          classify_sde(sde_shortrun)),
  "\\\\[-0.5em]",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\",
  sprintf("Rural raions only & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_rural)[1], se(m_rural)[1], pre_sd, sde_rural, se_sde_rural,
          classify_sde(sde_rural)),
  sprintf("Urban raions only & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(m_urban)[1], se(m_urban)[1], pre_sd, sde_urban, se_sde_urban,
          classify_sde(sde_urban)),
  "\\\\[-0.5em]",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All Tables Complete ===\n")
