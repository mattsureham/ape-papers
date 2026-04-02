# 05_tables.R — Generate all tables
# APEP Working Paper apep_1290

source("00_packages.R")

results <- readRDS("../data/results.rds")
robustness <- readRDS("../data/robustness.rds")
panel <- readRDS("../data/panel_scm.rds")
params <- readRDS("../data/params.rds")
geo_ids <- readRDS("../data/geo_ids.rds")
time_ids <- readRDS("../data/time_ids.rds")

ireland_id <- params$ireland_id
treat_start <- params$treat_start
event2_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2020 Q3")]
event3_time <- time_ids$time_id[time_ids$yq == zoo::as.yearqtr("2024 Q3")]

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------

ie_data <- panel %>% filter(geo_id == ireland_id)
donor_data <- panel %>% filter(geo_id != ireland_id)
ie_pre <- ie_data %>% filter(time_id < treat_start)
ie_post <- ie_data %>% filter(time_id >= treat_start)

make_row <- function(var, label, df_ie_pre, df_ie_post, df_donor_pre) {
  sprintf("    %s & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
          label,
          mean(df_ie_pre[[var]], na.rm=T), sd(df_ie_pre[[var]], na.rm=T),
          mean(df_ie_post[[var]], na.rm=T), sd(df_ie_post[[var]], na.rm=T),
          mean(df_donor_pre[[var]], na.rm=T), sd(df_donor_pre[[var]], na.rm=T))
}

donor_pre <- donor_data %>% filter(time_id < treat_start)

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Ireland and EU Donor Pool}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Ireland Pre-Ruling} & \\multicolumn{2}{c}{Ireland Post-Ruling} & \\multicolumn{2}{c}{Donors Pre-Ruling} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  make_row("tax_pct_gdp", "Income tax/GDP (\\%)", ie_pre, ie_post, donor_pre),
  make_row("tax_mio_eur", "Income tax (EUR mn)", ie_pre, ie_post, donor_pre),
  make_row("gdp_meur", "GDP (EUR mn)", ie_pre, ie_post, donor_pre),
  sprintf("    Quarters & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(ie_pre), nrow(ie_post), n_distinct(donor_pre$time_id)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Pre-ruling period: 2002-Q1 to 2016-Q2 (%d quarters). Post-ruling period: 2016-Q3 to 2025-Q3 (%d quarters). Donor pool comprises %d EU member states with complete quarterly data. Income tax (D51) includes taxes on personal and corporate income. GDP is at current market prices in millions of euros.",
          nrow(ie_pre), nrow(ie_post), n_distinct(donor_data$geo_id)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ---------------------------------------------------------------
# Table 2: SCM Weights
# ---------------------------------------------------------------

w <- results$weights_df %>%
  filter(weight > 0.001) %>%
  mutate(weight_pct = sprintf("%.1f", weight * 100))

# Country labels
geo_labels <- c(AT="Austria", BE="Belgium", BG="Bulgaria", CY="Cyprus",
                CZ="Czechia", DE="Germany", DK="Denmark", EE="Estonia",
                EL="Greece", ES="Spain", FI="Finland", FR="France",
                HR="Croatia", HU="Hungary", IE="Ireland", IT="Italy",
                LT="Lithuania", LU="Luxembourg", LV="Latvia", MT="Malta",
                NL="Netherlands", PL="Poland", PT="Portugal", RO="Romania",
                SE="Sweden", SI="Slovenia", SK="Slovakia")

w$country <- geo_labels[w$geo]

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Synthetic Control Weights (Tax/GDP Specification)}",
  "\\label{tab:weights}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "Country & Weight (\\%) \\\\",
  "\\midrule",
  paste0("    ", w$country, " & ", w$weight_pct, " \\\\"),
  "\\midrule",
  sprintf("    Total & %.1f \\\\", sum(w$weight) * 100),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Weights estimated by the synthetic control method of \\citet{abadie2010synthetic}. Only countries with weight $> 0.1\\%$ shown. Synthetic Ireland is constructed to match pre-2016 income tax/GDP trajectory using 22 EU donor states over 58 pre-treatment quarters (2002-Q1 to 2016-Q2).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_weights.tex")
cat("Table 2 written.\n")

# ---------------------------------------------------------------
# Table 3: Main Results — SCM Gaps by Period and Outcome
# ---------------------------------------------------------------

# Main outcome: tax/GDP
gap_p1_main <- results$gap_period1$mean_gap
gap_p2_main <- results$gap_period2$mean_gap
gap_p3_main <- results$gap_period3$mean_gap

# Log levels
gap_p1_lev <- robustness$gap_lev_p1
gap_p2_lev <- robustness$gap_lev_p2
gap_p3_lev <- robustness$gap_lev_p3

# Convert log gaps to percentages
pct_p1 <- (exp(gap_p1_lev) - 1) * 100
pct_p2 <- (exp(gap_p2_lev) - 1) * 100
pct_p3 <- (exp(gap_p3_lev) - 1) * 100

# Tax share of revenue
gap_p1_share <- robustness$gap_share_p1

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Synthetic Control Gaps: Ireland vs.~Synthetic Ireland}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Post-Treatment Period} \\\\",
  "\\cmidrule(lr){2-4}",
  " & Ruling & Annulment & Reinstatement \\\\",
  " & (2016-Q3--2020-Q2) & (2020-Q3--2024-Q2) & (2024-Q3--2025-Q3) \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Income Tax as \\% of GDP}} \\\\",
  sprintf("    Mean gap (pp) & %.2f & %.2f & %.2f \\\\", gap_p1_main, gap_p2_main, gap_p3_main),
  sprintf("    Pre-treatment RMSPE & \\multicolumn{3}{c}{%.2f pp} \\\\", results$pre_rmspe),
  sprintf("    Permutation $p$-value & \\multicolumn{3}{c}{%.3f} \\\\", results$p_value_ratio),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Log Income Tax Revenue (EUR mn)}} \\\\",
  sprintf("    Mean gap (log points) & %.3f & %.3f & %.3f \\\\", gap_p1_lev, gap_p2_lev, gap_p3_lev),
  sprintf("    Implied \\%% difference & %.1f\\%% & %.1f\\%% & %.1f\\%% \\\\", pct_p1, pct_p2, pct_p3),
  sprintf("    Pre-treatment RMSPE & \\multicolumn{3}{c}{%.3f} \\\\", robustness$pre_rmspe_lev),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Income Tax as \\% of Total Revenue}} \\\\",
  sprintf("    Mean gap (pp) & %.2f & --- & --- \\\\", gap_p1_share),
  sprintf("    Pre-treatment RMSPE & \\multicolumn{3}{c}{%.2f pp} \\\\", robustness$pre_rmspe_share),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each panel reports the mean gap (actual Ireland minus synthetic Ireland) for three post-treatment windows defined by the European Commission ruling (2016-Q3), General Court annulment (2020-Q3), and CJEU reinstatement (2024-Q3). Panel~A uses income tax as a percentage of GDP; Panel~B uses log income tax revenue in millions of euros; Panel~C uses income tax as a share of total government revenue. Pre-treatment RMSPE is the root mean squared prediction error over 58 pre-treatment quarters. Permutation $p$-value is the fraction of 22 placebo SCM estimates with a post/pre MSPE ratio at least as large as Ireland's.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_main_results.tex")
cat("Table 3 written.\n")

# ---------------------------------------------------------------
# Table 4: Leave-One-Out Robustness
# ---------------------------------------------------------------

loo <- robustness$loo_gaps
loo_df <- data.frame(
  dropped = names(loo),
  gap = unlist(loo)
) %>%
  mutate(country = geo_labels[dropped]) %>%
  arrange(gap)

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Leave-One-Out Robustness: Post-Ruling Tax/GDP Gap}",
  "\\label{tab:loo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Dropped Country & Original Weight (\\%) & Post-Treatment Gap (pp) \\\\",
  "\\midrule",
  sprintf("    Baseline (full donor pool) & --- & %.2f \\\\", results$gap_period1$mean_gap),
  "\\midrule",
  paste0("    ", loo_df$country, " & ",
         sapply(loo_df$dropped, function(g) {
           wt <- results$weights_df$weight[results$weights_df$geo == g]
           if (length(wt) > 0) sprintf("%.1f", wt * 100) else "0.0"
         }),
         " & ", sprintf("%.2f", loo_df$gap), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row re-estimates the synthetic control dropping one donor country with weight $> 1\\%$ in the baseline. Gap is the mean difference between actual and synthetic Ireland over 2016-Q3 to 2025-Q3. Negative values indicate Ireland's tax/GDP fell relative to synthetic Ireland.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_loo.tex")
cat("Table 4 written.\n")

# ---------------------------------------------------------------
# Table 5: Descriptive Decomposition
# ---------------------------------------------------------------

ie_all <- panel %>% filter(geo_id == ireland_id) %>% arrange(time_id)

# Annual averages for key years
years_of_interest <- c(2014, 2016, 2018, 2020, 2022, 2024)
annual <- ie_all %>%
  mutate(yr = lubridate::year(time)) %>%
  filter(yr %in% years_of_interest) %>%
  group_by(yr) %>%
  summarise(
    tax_eur = mean(tax_mio_eur, na.rm=T),
    gdp_eur = mean(gdp_meur, na.rm=T),
    tax_gdp = mean(tax_pct_gdp, na.rm=T),
    .groups = "drop"
  )

tab5 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Ireland's Income Tax and GDP: Selected Years}",
  "\\label{tab:decomp}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Year & Tax Revenue & GDP & Tax/GDP & Event \\\\",
  " & (EUR bn, quarterly avg) & (EUR bn, quarterly avg) & (\\%) & \\\\",
  "\\midrule",
  paste0("    ", annual$yr, " & ",
         sprintf("%.1f", annual$tax_eur / 1000), " & ",
         sprintf("%.1f", annual$gdp_eur / 1000), " & ",
         sprintf("%.1f", annual$tax_gdp), " & ",
         ifelse(annual$yr == 2016, "EC Ruling",
                ifelse(annual$yr == 2020, "GC Annulment",
                       ifelse(annual$yr == 2024, "CJEU Reinstatement", "---"))),
         " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Quarterly averages within each calendar year. Tax revenue is income tax (ESA2010 code D51) for the general government sector. GDP is at current market prices. Ireland's GDP includes the output of multinational corporations headquartered in Ireland, including intellectual property imports that inflated GDP by approximately 26\\% in 2015 (``Leprechaun economics'').",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5, "../tables/tab5_decomp.tex")
cat("Table 5 written.\n")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE)
# ---------------------------------------------------------------

# Main outcome: tax_pct_gdp, treatment = Ireland post-ruling
# Binary treatment (Ireland × post), DiD coefficient from TWFE
did_model <- results$did_model
coefs <- coef(did_model)
ses <- sqrt(diag(vcov(did_model)))

# Primary coefficient: post_ruling × treated
beta_ruling <- coefs["event_bin::post_ruling:treated"]
se_ruling <- ses["event_bin::post_ruling:treated"]

# SD(Y) — unconditional SD of tax_pct_gdp
sd_y <- sd(panel$tax_pct_gdp, na.rm = TRUE)

# SDE
sde_ruling <- beta_ruling / sd_y
se_sde_ruling <- se_ruling / sd_y

# For log-level SCM: use average post-treatment gap
# The "beta" is the mean gap, SE estimated from gap variance
gap_post <- results$gap_df %>% filter(time_id >= treat_start)
beta_level <- mean(gap_post$gap)
se_level <- sd(gap_post$gap) / sqrt(nrow(gap_post))
sd_y_pctgdp <- sd_y  # same for percentage point outcome

sde_level <- beta_level / sd_y_pctgdp
se_sde_level <- se_level / sd_y_pctgdp

# Log-level SCM gap
beta_log <- robustness$post_mean_lev  # mean gap in log points
sd_y_log <- sd(log(panel$tax_mio_eur + 1), na.rm = TRUE)
sde_log <- beta_log / sd_y_log
# SE from log gap variance
if (!is.null(robustness$gap_lev_df)) {
  gap_log_post <- robustness$gap_lev_df %>% filter(time_id >= treat_start)
  se_log <- sd(gap_log_post$gap) / sqrt(nrow(gap_log_post))
  se_sde_log <- se_log / sd_y_log
} else {
  se_sde_log <- NA
}

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

# Heterogeneity: Period 1 (Ruling) vs Period 2 (Annulment) gap
gap_p1 <- results$gap_period1$mean_gap
gap_p2 <- results$gap_period2$mean_gap
se_p1 <- results$gap_period1$sd_gap / sqrt(results$gap_period1$n)
se_p2 <- results$gap_period2$sd_gap / sqrt(results$gap_period2$n)

sde_p1 <- gap_p1 / sd_y
sde_p2 <- gap_p2 / sd_y
se_sde_p1 <- se_p1 / sd_y
se_sde_p2 <- se_p2 / sd_y

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Ireland and 22 EU member states. ",
  "\\textbf{Research question:} Does supranational state aid enforcement by the European Commission ",
  "alter a country's income tax collections, measured as the gap between actual and synthetic control outcomes? ",
  "\\textbf{Policy mechanism:} The EC's 2016 ruling that Ireland granted illegal state aid to Apple through selective tax rulings, ",
  "ordering EUR~13 billion in back-tax recovery, the largest state aid decision in EU history, ",
  "signaling to all multinationals that preferential tax treatment is subject to Commission enforcement. ",
  "\\textbf{Outcome definition:} Quarterly income tax revenue (ESA2010 code D51, general government) as a percentage of GDP ",
  "at current market prices; robustness uses log income tax revenue in millions of euros. ",
  "\\textbf{Treatment:} Binary --- Ireland vs.~synthetic Ireland constructed from 22 EU donor states. ",
  "\\textbf{Data:} Eurostat GOV\\_10Q\\_GGNFA and NAMQ\\_10\\_GDP, 2002-Q1 to 2025-Q3, country-quarter panel, ",
  "$N = 2{,}185$ country-quarter observations (23 countries $\\times$ 95 quarters). ",
  "\\textbf{Method:} Synthetic control method with permutation inference (in-space placebos); ",
  "robustness via TWFE DiD with country and quarter fixed effects, standard errors clustered by country. ",
  "\\textbf{Sample:} EU member states with at least 40 quarters of pre-treatment data (2002-Q1 to 2016-Q2). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("    Tax/GDP (pp) & SCM gap (all post) & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          beta_level, sd_y, sde_level, se_sde_level, classify(sde_level)),
  sprintf("    Tax/GDP (pp) & TWFE DiD (post-ruling) & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          beta_ruling, sd_y, sde_ruling, se_sde_ruling, classify(sde_ruling)),
  sprintf("    Log tax (EUR mn) & SCM gap (all post) & %.3f & %.2f & %.3f & %.3f & %s \\\\",
          beta_log, sd_y_log, sde_log, se_sde_log, classify(sde_log)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by enforcement phase)}} \\\\",
  sprintf("    Tax/GDP: Ruling phase & SCM (2016-Q3 to 2020-Q2) & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          gap_p1, sd_y, sde_p1, se_sde_p1, classify(sde_p1)),
  sprintf("    Tax/GDP: Annulment phase & SCM (2020-Q3 to 2024-Q2) & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          gap_p2, sd_y, sde_p2, se_sde_p2, classify(sde_p2)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
