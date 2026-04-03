# 05_tables.R — Generate all tables
# apep_1348: Groningen Regulatory Rebound

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
models <- readRDS(file.path(data_dir, "models.rds"))
diagnostics <- jsonlite::read_json(file.path(data_dir, "diagnostics.json"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

# By distance bin
sumstats <- panel %>%
  group_by(dist_bin) %>%
  summarise(
    N_munis = n_distinct(region_code),
    N_obs = n(),
    Mean_price = mean(value, na.rm = TRUE),
    SD_price = sd(value, na.rm = TRUE),
    Mean_price_pre = mean(value[year <= 2012], na.rm = TRUE),
    Mean_price_post = mean(value[year >= 2013], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(dist_bin)

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics by Distance to Huizinge Epicenter}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Distance Bin & Municipalities & Obs. & Mean Price & SD & Pre-2013 Mean & Post-2013 Mean \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sumstats))) {
  row <- sumstats[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %d & %s & %s & %s & %s & %s \\\\",
    as.character(row$dist_bin),
    row$N_munis,
    format(row$N_obs, big.mark = ","),
    format(round(row$Mean_price), big.mark = ","),
    format(round(row$SD_price), big.mark = ","),
    format(round(row$Mean_price_pre), big.mark = ","),
    format(round(row$Mean_price_post), big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Housing prices are average purchase prices of existing ",
         "owner-occupied dwellings in euros, from CBS StatLine (table 83625NED). ",
         "Distance bins are computed from each municipality centroid to the Huizinge earthquake ",
         "epicenter (53.348\\textdegree N, 6.664\\textdegree E). Pre-2013 denotes 1997--2012; ",
         "Post-2013 denotes 2013--2023. Panel covers ", diagnostics$n_municipalities,
         " municipalities over ", diagnostics$n_years, " years."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_sumstats.tex"))

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("Generating Table 2: Main DiD Results...\n")

etable(
  models$did1, models$did2, models$did3, models$did4,
  file = file.path(tables_dir, "tab2_main_did.tex"),
  title = "Effect of Groningen Earthquakes on Housing Prices",
  label = "tab:main_did",
  headers = c("Inv. Distance", "Three-Period", "Donut (>10km)", "Distance Bins"),
  notes = paste0(
    "All specifications include municipality and year fixed effects. ",
    "Standard errors clustered at the municipality level in parentheses. ",
    "The dependent variable is log average housing purchase price. ",
    "Column (1) interacts a post-2012 indicator with inverse distance (km) to the ",
    "Huizinge epicenter. Column (2) splits the post period into decline (2013--2017) ",
    "and recovery (2018--2023). Column (3) drops municipalities within 10km of the ",
    "epicenter. Column (4) uses distance bins (reference: $>$150km). ",
    "Sample: ", format(diagnostics$n_obs, big.mark = ","),
    " municipality-year observations, ", diagnostics$n_municipalities,
    " municipalities, ", diagnostics$n_years, " years."
  ),
  style.tex = style.tex("aer"),
  fitstat = ~ n + r2 + wr2,
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1)
)

# ============================================================
# Table 3: Robustness — Distance Thresholds
# ============================================================
cat("Generating Table 3: Distance Threshold Robustness...\n")

threshold_results <- readRDS(file.path(data_dir, "threshold_robustness.rds"))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness to Alternative Distance Thresholds}",
  "\\label{tab:thresholds}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Treatment Threshold & Treated Municipalities & $\\hat{\\beta}$ & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(threshold_results))) {
  row <- threshold_results[i, ]
  stars <- ifelse(abs(row$coef / row$se) > 2.576, "***",
           ifelse(abs(row$coef / row$se) > 1.96, "**",
           ifelse(abs(row$coef / row$se) > 1.645, "*", "")))
  tab3_lines <- c(tab3_lines, sprintf(
    "$\\leq$ %d km & %d & %.4f%s & (%.4f) \\\\",
    row$threshold_km, row$n_treated, row$coef, stars, row$se
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each row reports the coefficient on Post$\\times$Treated ",
         "from a separate regression of log housing price on municipality and year fixed effects. ",
         "Treated is a binary indicator for municipalities within the specified distance threshold ",
         "of the Huizinge epicenter. Standard errors clustered at the municipality level. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.1$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_thresholds.tex"))

# ============================================================
# Table 4: Mechanism — Production and Earthquakes
# ============================================================
cat("Generating Table 4: Mechanism...\n")

production <- readRDS(file.path(data_dir, "groningen_production.rds"))
eq_annual <- readRDS(file.path(data_dir, "earthquake_annual.rds"))

mech_df <- production %>%
  left_join(eq_annual, by = "year") %>%
  mutate(n_quakes = replace_na(n_quakes, 0),
         max_mag = replace_na(max_mag, 0))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Production Caps and Seismic Activity: The Mechanism}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Production (bcm)} & \\multicolumn{2}{c}{Earthquakes ($M \\geq 1.0$)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Period & Mean & Range & Annual Mean & Max Magnitude \\\\",
  "\\midrule"
)

# Pre-cap (2003-2013)
pre <- mech_df %>% filter(year >= 2003, year <= 2013)
post <- mech_df %>% filter(year >= 2014, year <= 2019)
late <- mech_df %>% filter(year >= 2020)

tab4_lines <- c(tab4_lines,
  sprintf("Pre-cap (2003--2013) & %.1f & %.1f--%.1f & %.1f & %.1f \\\\",
    mean(pre$production_bcm), min(pre$production_bcm), max(pre$production_bcm),
    mean(pre$n_quakes), max(pre$max_mag)),
  sprintf("Cap era (2014--2019) & %.1f & %.1f--%.1f & %.1f & %.1f \\\\",
    mean(post$production_bcm), min(post$production_bcm), max(post$production_bcm),
    mean(post$n_quakes), max(post$max_mag)),
  sprintf("Wind-down (2020--2023) & %.1f & %.1f--%.1f & %.1f & %.1f \\\\",
    mean(late$production_bcm), min(late$production_bcm), max(late$production_bcm),
    mean(late$n_quakes), max(late$max_mag))
)

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Production data from NAM/Rijksoverheid official publications. ",
         "Earthquake counts from KNMI FDSN catalog (magnitude $\\geq 1.0$, Groningen region: ",
         "lat 52.5--53.8, lon 5.5--7.5). The production-to-earthquake link is physically determined: ",
         "gas extraction causes compaction-driven fault slip. The decline in both production and seismicity ",
         "after 2014 reflects the government's production cap policy."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_mechanism.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Get pre-treatment SD of log prices
sd_y_pre <- sd(panel$log_price[panel$year <= 2012], na.rm = TRUE)

# For continuous treatment, SDE = beta * SD(X) / SD(Y)
# Treatment is inverse distance; SD(X) = SD(1/dist_km)
sd_x <- sd(panel$treat_intensity, na.rm = TRUE)

# Main specification (did1): Post × Inverse Distance
beta_main <- coef(models$did1)[1]
se_main <- se(models$did1)[1]
sde_main <- beta_main * sd_x / sd_y_pre
se_sde_main <- se_main * sd_x / sd_y_pre

# Three-period: decline phase
beta_decline <- coef(models$did2)[1]
se_decline <- se(models$did2)[1]
sde_decline <- beta_decline * sd_x / sd_y_pre
se_sde_decline <- se_decline * sd_x / sd_y_pre

# Three-period: recovery phase
beta_recovery <- coef(models$did2)[2]
se_recovery <- se(models$did2)[2]
sde_recovery <- beta_recovery * sd_x / sd_y_pre
se_sde_recovery <- se_recovery * sd_x / sd_y_pre

# Classify SDE
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
pooled_rows <- data.frame(
  Outcome = c("Housing price (post-earthquake)", "Housing price (decline phase)", "Housing price (recovery phase)"),
  beta = c(beta_main, beta_decline, beta_recovery),
  se = c(se_main, se_decline, se_recovery),
  sd_y = rep(sd_y_pre, 3),
  sde = c(sde_main, sde_decline, sde_recovery),
  se_sde = c(se_sde_main, se_sde_decline, se_sde_recovery),
  classification = c(classify_sde(sde_main), classify_sde(sde_decline), classify_sde(sde_recovery)),
  stringsAsFactors = FALSE
)

# Panel B: Heterogeneous (by pre-treatment price level)
# Split at median pre-treatment price
median_price_pre <- median(panel$value[panel$year <= 2012], na.rm = TRUE)

panel_low <- panel %>%
  group_by(region_code) %>%
  mutate(mean_pre_price = mean(value[year <= 2012], na.rm = TRUE)) %>%
  ungroup() %>%
  filter(mean_pre_price <= median_price_pre)

panel_high <- panel %>%
  group_by(region_code) %>%
  mutate(mean_pre_price = mean(value[year <= 2012], na.rm = TRUE)) %>%
  ungroup() %>%
  filter(mean_pre_price > median_price_pre)

did_low <- feols(log_price ~ post_huizinge:treat_intensity | region_code + year,
                 data = panel_low, cluster = ~region_code)
did_high <- feols(log_price ~ post_huizinge:treat_intensity | region_code + year,
                  data = panel_high, cluster = ~region_code)

sd_y_low <- sd(panel_low$log_price[panel_low$year <= 2012], na.rm = TRUE)
sd_y_high <- sd(panel_high$log_price[panel_high$year <= 2012], na.rm = TRUE)
sd_x_low <- sd(panel_low$treat_intensity, na.rm = TRUE)
sd_x_high <- sd(panel_high$treat_intensity, na.rm = TRUE)

het_rows <- data.frame(
  Outcome = c("Housing price (low-price municipalities)", "Housing price (high-price municipalities)"),
  beta = c(coef(did_low)[1], coef(did_high)[1]),
  se = c(se(did_low)[1], se(did_high)[1]),
  sd_y = c(sd_y_low, sd_y_high),
  sde = c(coef(did_low)[1] * sd_x_low / sd_y_low, coef(did_high)[1] * sd_x_high / sd_y_high),
  se_sde = c(se(did_low)[1] * sd_x_low / sd_y_low, se(did_high)[1] * sd_x_high / sd_y_high),
  classification = c(classify_sde(coef(did_low)[1] * sd_x_low / sd_y_low),
                     classify_sde(coef(did_high)[1] * sd_x_high / sd_y_high)),
  stringsAsFactors = FALSE
)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Netherlands. ",
  "\\textbf{Research question:} Do government-imposed gas production caps, triggered by induced seismicity from the Groningen gas field, lead to housing price recovery in nearby municipalities? ",
  "\\textbf{Policy mechanism:} The Dutch government imposed progressively tighter annual production caps on the Groningen gas field (from 53.9 bcm in 2013 to 11.8 bcm in 2019 and full closure in 2023), directly reducing the frequency and intensity of induced earthquakes that had depressed housing values in the surrounding region. ",
  "\\textbf{Outcome definition:} Log average purchase price of existing owner-occupied dwellings per municipality per year, from CBS StatLine table 83625NED. ",
  "\\textbf{Treatment:} Continuous; inverse Haversine distance (km) from municipality centroid to the Huizinge earthquake epicenter (53.348\\textdegree N, 6.664\\textdegree E), interacted with post-2012 indicators. ",
  "\\textbf{Data:} CBS StatLine 83625NED (housing prices), KNMI FDSN (earthquake catalog), NAM/Rijksoverheid (production); 1997--2023; municipality-year; ",
  format(diagnostics$n_obs, big.mark = ","), " observations across ", diagnostics$n_municipalities, " municipalities. ",
  "\\textbf{Method:} Two-way fixed effects (municipality + year), standard errors clustered at municipality level; event study and three-period specifications. ",
  "\\textbf{Sample:} Balanced panel of Dutch municipalities with at least 80\\% year coverage over 1997--2023; production data covers 2003--2023. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2013) ",
  "standard deviation of log housing prices. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in seq_len(nrow(pooled_rows))) {
  r <- pooled_rows[i, ]
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-treatment price level)}} \\\\"
)

for (i in seq_len(nrow(het_rows))) {
  r <- het_rows[i, ]
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
