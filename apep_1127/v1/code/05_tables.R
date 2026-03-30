# 05_tables.R — Generate all LaTeX tables
# apep_1127: Injection well volume regulations and induced seismicity

source("00_packages.R")

cat("=== Loading results ===\n")
panel <- read_csv("../data/panel_ok.csv", show_col_types = FALSE)
twfe <- readRDS("../data/twfe_results.rds")
rob <- readRDS("../data/robustness_results.rds")
att_overall <- readRDS("../data/att_overall.rds")
es_out <- readRDS("../data/es_results.rds")
loo <- readRDS("../data/loo_results.rds")
diagnostics <- jsonlite::fromJSON("../data/diagnostics.json")

panel_active <- panel |>
  group_by(county_fips) |>
  filter(sum(n_quakes) > 0 | any(treated_county)) |>
  ungroup()

# Helper to format stars
stars_fn <- function(pv) ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

cat("\n=== Table 1: Summary Statistics ===\n")

pre_data <- panel_active |> filter(year < 2015)
post_data <- panel_active |> filter(year >= 2015)

make_summ_row <- function(data, group_label, period_label) {
  data |>
    summarise(
      Group = group_label, Period = period_label,
      mean_q = sprintf("%.2f", mean(n_quakes)),
      sd_q = sprintf("%.2f", sd(n_quakes)),
      max_q = sprintf("%.0f", max(n_quakes)),
      cm = format(n(), big.mark = ","),
      counties = sprintf("%.0f", n_distinct(county_fips))
    )
}

summ_stats <- bind_rows(
  make_summ_row(pre_data |> filter(treated_county), "Treated", "Pre (2010--2014)"),
  make_summ_row(pre_data |> filter(!treated_county), "Control", "Pre (2010--2014)"),
  make_summ_row(post_data |> filter(treated_county), "Treated", "Post (2015--2023)"),
  make_summ_row(post_data |> filter(!treated_county), "Control", "Post (2015--2023)")
)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly Earthquake Counts by Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Group & Period & Mean & SD & Max & County-months & Counties \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i, ]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            row$Group, row$Period, row$mean_q, row$sd_q,
            row$max_q, row$cm, row$counties))
  if (i == 2) tab1_lines <- c(tab1_lines, "\\midrule")
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Unit of observation is county-month. Earthquake counts include events of magnitude 2.5 or greater from the USGS ComCat catalog, spatially assigned to Oklahoma counties via the Census TIGER/Line boundaries. Treated counties contain Arbuckle formation injection wells subject to OCC volume reduction directives (Waves 1--3, March 2015 through September 2016). Control counties are Oklahoma counties with recorded seismic activity but no directive-affected wells.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Saved tab1_summary.tex\n")

# =============================================================================
# TABLE 2: Main Results — CS as primary, TWFE as comparison
# =============================================================================

cat("\n=== Table 2: Main Results ===\n")

# CS estimates
cs_att <- att_overall$overall.att
cs_se <- att_overall$overall.se
cs_pv <- 2 * pnorm(-abs(cs_att / cs_se))
cs_stars <- stars_fn(cs_pv)

# TWFE estimates
twfe_coef <- coef(twfe$m1)["post_treat"]
twfe_se <- se(twfe$m1)["post_treat"]
twfe_pv <- pvalue(twfe$m1)["post_treat"]
twfe_stars <- stars_fn(twfe_pv)

# Poisson
pois_coef <- coef(twfe$m3)["post_treat"]
pois_se <- se(twfe$m3)["post_treat"]
pois_pv <- pvalue(twfe$m3)["post_treat"]
pois_stars <- stars_fn(pois_pv)

# TWFE Log
log_coef <- coef(twfe$m4)["post_treat"]
log_se <- se(twfe$m4)["post_treat"]
log_pv <- pvalue(twfe$m4)["post_treat"]
log_stars <- stars_fn(log_pv)

# Oil interaction model
oil_coef <- coef(rob$m_oil)["post_treat"]
oil_se <- se(rob$m_oil)["post_treat"]
oil_pv <- pvalue(rob$m_oil)["post_treat"]
oil_stars <- stars_fn(oil_pv)

oil_inter_coef <- coef(rob$m_oil)["wti_x_treated"]
oil_inter_se <- se(rob$m_oil)["wti_x_treated"]
oil_inter_pv <- pvalue(rob$m_oil)["wti_x_treated"]
oil_inter_stars <- stars_fn(oil_inter_pv)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of OCC Volume Directives on Induced Seismicity}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & CS & TWFE & TWFE & Poisson & TWFE \\\\",
  " & IHS & IHS & IHS & Count & IHS \\\\",
  "\\midrule",
  sprintf("Directive $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.3f", cs_att), cs_stars,
          sprintf("%.3f", twfe_coef), twfe_stars,
          sprintf("%.3f", oil_coef), oil_stars,
          sprintf("%.3f", pois_coef), pois_stars,
          sprintf("%.3f", log_coef), log_stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          sprintf("%.3f", cs_se),
          sprintf("%.3f", twfe_se),
          sprintf("%.3f", oil_se),
          sprintf("%.3f", pois_se),
          sprintf("%.3f", log_se)),
  sprintf("WTI $\\times$ Treated & & & %s%s & & \\\\",
          sprintf("%.4f", oil_inter_coef), oil_inter_stars),
  sprintf(" & & & (%s) & & \\\\",
          sprintf("%.4f", oil_inter_se)),
  "\\midrule",
  "Estimator & CS & TWFE & TWFE & PPML & TWFE \\\\",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Dep.\\ var.\\ & IHS & IHS & IHS & Count & Log($Y$+1) \\\\"),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(diagnostics$n_obs, big.mark = ","),
          format(nobs(twfe$m1), big.mark = ","),
          format(nobs(rob$m_oil), big.mark = ","),
          format(nobs(twfe$m3), big.mark = ","),
          format(nobs(twfe$m4), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column (1) reports the overall ATT from Callaway and Sant'Anna (2021) using never-treated counties as the control group, estimated on the quarterly county panel. Columns (2)--(5) report TWFE coefficients on the directive exposure indicator interacted with the post-directive period. Column (3) adds a WTI crude oil price $\\times$ treated county interaction. Standard errors clustered at the county level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. The TWFE sign reversal in columns (2) and (5) illustrates the staggered-adoption bias documented by Goodman-Bacon (2021).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Saved tab2_main.tex\n")

# =============================================================================
# TABLE 3: Robustness — Kansas replication, placebo, LOO
# =============================================================================

cat("\n=== Table 3: Robustness ===\n")

# Kansas
ks_coef_val <- ks_se_val <- ks_pv_val <- ks_n_val <- NA
ks_stars_val <- ""
if (file.exists("../data/ks_twfe.rds")) {
  ks_m <- readRDS("../data/ks_twfe.rds")
  ks_coef_val <- coef(ks_m)["post_treat"]
  ks_se_val <- se(ks_m)["post_treat"]
  ks_pv_val <- pvalue(ks_m)["post_treat"]
  ks_stars_val <- stars_fn(ks_pv_val)
  ks_n_val <- nobs(ks_m)
}

# M3.0+ threshold
m3_coef <- coef(rob$m_m3)["post_treat"]
m3_se <- se(rob$m_m3)["post_treat"]
m3_pv <- pvalue(rob$m_m3)["post_treat"]
m3_stars <- stars_fn(m3_pv)

# LOO range
loo_min <- min(loo$coefficient)
loo_max <- max(loo$coefficient)

# Split post (early vs late)
rec_early_coef <- coef(rob$m_recovery)["early_post"]
rec_early_se <- se(rob$m_recovery)["early_post"]
rec_late_coef <- coef(rob$m_recovery)["late_post"]
rec_late_se <- se(rob$m_recovery)["late_post"]
rec_early_stars <- stars_fn(pvalue(rob$m_recovery)["early_post"])
rec_late_stars <- stars_fn(pvalue(rob$m_recovery)["late_post"])

# Event study endpoints
es_data <- data.frame(event.time = es_out$egt, att = es_out$att.egt, se = es_out$se.egt)
es_pre_5to1 <- es_data |> filter(event.time >= -5 & event.time <= -2)
es_post_12to16 <- es_data |> filter(event.time >= 12 & event.time <= 16)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks and External Validation}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $N$ & Notes \\\\",
  "\\midrule",
  "\\textit{Panel A: Baseline and estimator comparison} & & & & \\\\",
  sprintf("\\quad CS ATT (primary) & %s%s & (%s) & %s & Quarterly \\\\",
          sprintf("%.3f", cs_att), cs_stars, sprintf("%.3f", cs_se),
          format(diagnostics$n_obs, big.mark = ",")),
  sprintf("\\quad TWFE (biased) & %s%s & (%s) & %s & Monthly \\\\",
          sprintf("%.3f", twfe_coef), twfe_stars, sprintf("%.3f", twfe_se),
          format(nobs(twfe$m1), big.mark = ",")),
  "\\midrule",
  "\\textit{Panel B: External validation} & & & & \\\\"
)

if (!is.na(ks_coef_val)) {
  tab3_lines <- c(tab3_lines,
    sprintf("\\quad Kansas replication (TWFE) & %s%s & (%s) & %s & Independent \\\\",
            sprintf("%.3f", ks_coef_val), ks_stars_val, sprintf("%.3f", ks_se_val),
            format(ks_n_val, big.mark = ",")))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  "\\textit{Panel C: Alternative thresholds} & & & & \\\\",
  sprintf("\\quad M3.0+ (TWFE) & %s%s & (%s) & %s & Higher threshold \\\\",
          sprintf("%.3f", m3_coef), m3_stars, sprintf("%.3f", m3_se),
          format(nobs(rob$m_m3), big.mark = ",")),
  "\\midrule",
  "\\textit{Panel D: Persistence (split-post TWFE)} & & & & \\\\",
  sprintf("\\quad Early post (2015--2017) & %s%s & (%s) & %s & Oil depressed \\\\",
          sprintf("%.3f", rec_early_coef), rec_early_stars, sprintf("%.3f", rec_early_se),
          format(nobs(rob$m_recovery), big.mark = ",")),
  sprintf("\\quad Late post (2018--2023) & %s%s & (%s) & %s & Oil recovered \\\\",
          sprintf("%.3f", rec_late_coef), rec_late_stars, sprintf("%.3f", rec_late_se),
          format(nobs(rob$m_recovery), big.mark = ",")),
  "\\midrule",
  "\\textit{Panel E: Sensitivity} & & & & \\\\",
  sprintf("\\quad Leave-one-county-out range & [%s, %s] & --- & --- & TWFE \\\\",
          sprintf("%.3f", loo_min), sprintf("%.3f", loo_max)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A compares the Callaway-Sant'Anna (2021) heterogeneity-robust estimator (quarterly county panel) with naive TWFE (monthly). The TWFE sign reversal illustrates staggered-adoption bias. Panel B replicates the analysis in Kansas, where the KCC independently imposed injection restrictions. Panel C raises the magnitude threshold. Panel D splits the post-treatment period: early (2015--2017, when WTI averaged \\$45/barrel) and late (2018--2023, when oil prices recovered to \\$62+). Panel E drops each treated county in turn. All TWFE specifications include county and month fixed effects with standard errors clustered at the county level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Saved tab3_robustness.tex\n")

# =============================================================================
# TABLE 4: Annual Earthquake Counts (Descriptive)
# =============================================================================

cat("\n=== Table 4: Annual earthquake counts ===\n")

annual <- panel_active |>
  group_by(year, treated_county) |>
  summarise(total = sum(n_quakes), .groups = "drop") |>
  pivot_wider(names_from = treated_county, values_from = total,
              names_prefix = "treat_") |>
  mutate(
    treat_TRUE = replace_na(treat_TRUE, 0),
    treat_FALSE = replace_na(treat_FALSE, 0),
    total = treat_TRUE + treat_FALSE
  )

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Annual Earthquake Counts (M2.5+) by Treatment Status, Oklahoma}",
  "\\label{tab:annual}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year & Treated Counties & Control Counties & Total \\\\",
  "\\midrule"
)

for (i in 1:nrow(annual)) {
  row <- annual[i, ]
  marker <- ifelse(row$year == 2015, " $\\dagger$", "")
  tab4_lines <- c(tab4_lines,
    sprintf("%d%s & %s & %s & %s \\\\",
            row$year, marker,
            format(row$treat_TRUE, big.mark = ","),
            format(row$treat_FALSE, big.mark = ","),
            format(row$total, big.mark = ",")))
  if (row$year == 2014) {
    tab4_lines <- c(tab4_lines, "\\midrule")
  }
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Earthquake counts (magnitude 2.5+) from the USGS ComCat catalog assigned to Oklahoma counties via spatial join. Treated counties contain Arbuckle formation injection wells subject to OCC volume directives. $\\dagger$ marks the first year of directive implementation (March 2015). Peak seismicity (2,570 events in treated counties, 2015) declined 98\\% by 2023 (53 events).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_annual.tex")
cat("Saved tab4_annual.tex\n")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# =============================================================================

cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# SDE = β / SD(Y) for binary treatment
pre_treated <- panel_active |>
  filter(treated_county, year < 2015)

sd_ihs <- sd(pre_treated$ihs_quakes)

# Main CS estimate
sde_cs <- cs_att / sd_ihs
se_sde_cs <- cs_se / sd_ihs

# TWFE IHS
sde_twfe <- twfe_coef / sd_ihs
se_sde_twfe <- twfe_se / sd_ihs

# M3.0+ threshold
pre_treated_m3 <- pre_treated |>
  mutate(ihs_m3 = log(n_quakes_m3 + sqrt(n_quakes_m3^2 + 1)))
sd_ihs_m3 <- sd(pre_treated_m3$ihs_m3)
sde_m3 <- m3_coef / sd_ihs_m3
se_sde_m3 <- m3_se / sd_ihs_m3

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  direction <- ifelse(sde < 0, "negative", "positive")
  size <- case_when(
    abs_sde > 0.15 ~ "Large",
    abs_sde > 0.05 ~ "Moderate",
    abs_sde > 0.005 ~ "Small",
    TRUE ~ "Null"
  )
  paste(size, direction)
}

# Build SDE rows — Panel A (Pooled)
sde_rows <- tibble(
  Outcome = c(
    "IHS(Quakes M2.5+), CS",
    "IHS(Quakes M2.5+), TWFE",
    "IHS(Quakes M3.0+), TWFE"
  ),
  beta = c(cs_att, twfe_coef, m3_coef),
  se_val = c(cs_se, twfe_se, m3_se),
  sd_y = c(sd_ihs, sd_ihs, sd_ihs_m3),
  sde = c(sde_cs, sde_twfe, sde_m3),
  se_sde = c(se_sde_cs, se_sde_twfe, se_sde_m3),
  classification = sapply(c(sde_cs, sde_twfe, sde_m3), classify_sde)
)

# Panel B: Heterogeneity by directive wave (sample splits)
panel_het <- panel_active |>
  mutate(wave = case_when(
    !treated_county ~ NA_real_,
    first_treat_ym == (2015 * 12 + 3) ~ 1,
    TRUE ~ 2
  ))

# Wave 1 only
panel_w1 <- panel_het |>
  filter(is.na(wave) | wave == 1) |>
  mutate(post_treat = as.numeric(treat_post))
m_w1 <- feols(ihs_quakes ~ post_treat | county_fips + year_month,
              data = panel_w1, cluster = "county_fips")

# Wave 2+ only
panel_w23 <- panel_het |>
  filter(is.na(wave) | wave == 2) |>
  mutate(post_treat = as.numeric(treat_post))
m_w23 <- feols(ihs_quakes ~ post_treat | county_fips + year_month,
               data = panel_w23, cluster = "county_fips")

beta_w1 <- coef(m_w1)["post_treat"]
se_w1 <- se(m_w1)["post_treat"]
sde_w1 <- beta_w1 / sd_ihs
se_sde_w1 <- se_w1 / sd_ihs

beta_w23 <- coef(m_w23)["post_treat"]
se_w23 <- se(m_w23)["post_treat"]
sde_w23 <- beta_w23 / sd_ihs
se_sde_w23 <- se_w23 / sd_ihs

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-mandated injection well volume reductions ",
  "causally reduce induced seismicity in counties with Arbuckle formation disposal wells? ",
  "\\textbf{Policy mechanism:} The Oklahoma Corporation Commission issued 33+ ",
  "well-specific directives (2015--2017) requiring wastewater disposal volume reductions ",
  "of 40--50\\% for wells injecting into the Arbuckle formation, effectively capping the ",
  "subsurface pressure accumulation that triggers fault slip on critically stressed faults. ",
  "\\textbf{Outcome definition:} Monthly count of earthquakes at or above magnitude 2.5 ",
  "(IHS-transformed) from the USGS ComCat catalog, spatially assigned to counties. ",
  "\\textbf{Treatment:} Binary indicator for counties containing injection wells subject ",
  "to OCC volume reduction directives, with staggered adoption across three waves ",
  "(March 2015, February 2016, September 2016). ",
  "\\textbf{Data:} USGS ComCat earthquake catalog and US Census TIGER/Line county ",
  "boundaries, 2010--2023, at the county-month level. ",
  sprintf("Panel sample: %s county-months across %d counties ",
          format(diagnostics$n_obs, big.mark = ","),
          diagnostics$n_treated + diagnostics$n_control),
  sprintf("(%d treated, %d control). ", diagnostics$n_treated, diagnostics$n_control),
  "\\textbf{Method:} Primary: Callaway and Sant'Anna (2021) with never-treated controls, ",
  "estimated on the quarterly county panel. Comparison: two-way fixed effects (county + month) ",
  "with standard errors clustered at the county level. ",
  "\\textbf{Sample:} Oklahoma counties with any recorded seismic activity (M2.5+) ",
  "or containing directive-affected injection wells; excludes counties with zero ",
  "earthquakes and no regulatory exposure throughout the sample period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2010--2014) ",
  "standard deviation of the outcome among treated counties. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se_val[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
            sde_rows$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\textit{Panel B: Heterogeneous (by directive wave)} & & & & & & \\\\",
  sprintf("Wave 1 counties (March 2015) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_w1, se_w1, sd_ihs, sde_w1, se_sde_w1, classify_sde(sde_w1)),
  sprintf("Wave 2--3 counties (2016) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_w23, se_w23, sd_ihs, sde_w23, se_sde_w23, classify_sde(sde_w23)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
