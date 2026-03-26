# 05_tables.R — Generate all LaTeX tables
# apep_0990: Nebraska groundwater allocations and crop adaptation

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
panel <- results$panel

cat("=== Generating Tables ===\n")

# =================================================================
# Table 1: Summary Statistics
# =================================================================
cat("Table 1: Summary Statistics\n")

sumstat_data <- panel %>%
  filter(!is.na(corn_share)) %>%
  select(corn_share, sorghum_share, wheat_share, soybean_share,
         drought_tolerant_share, total_crop_acres) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "value") %>%
  filter(!is.na(value)) %>%
  group_by(variable) %>%
  summarise(
    Mean = mean(value),
    SD = sd(value),
    Min = min(value),
    Max = max(value),
    N = n(),
    .groups = "drop"
  )

# Treated vs control comparison
treat_means <- panel %>%
  filter(!is.na(corn_share)) %>%
  mutate(ever_treated = is.finite(treat_year)) %>%
  group_by(ever_treated) %>%
  summarise(
    corn_share_mean = mean(corn_share, na.rm = TRUE),
    sorghum_share_mean = mean(sorghum_share, na.rm = TRUE),
    wheat_share_mean = mean(wheat_share, na.rm = TRUE),
    drought_tol_mean = mean(drought_tolerant_share, na.rm = TRUE),
    total_acres_mean = mean(total_crop_acres, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    n_obs = n(),
    .groups = "drop"
  )

# Format variable names for LaTeX
var_labels <- c(
  corn_share = "Corn share of cropland",
  sorghum_share = "Sorghum share of cropland",
  wheat_share = "Wheat share of cropland",
  soybean_share = "Soybean share of cropland",
  drought_tolerant_share = "Drought-tolerant share (sorghum + wheat)",
  total_crop_acres = "Total crop acres"
)

# Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Nebraska County-Level Crop Composition, 1988--2023}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Ever-Treated} & \\multicolumn{2}{c}{Never-Treated} & & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

# Calculate separate stats for treated and control
for (var in c("corn_share", "sorghum_share", "wheat_share", "soybean_share",
              "drought_tolerant_share", "total_crop_acres")) {

  treated_vals <- panel %>% filter(is.finite(treat_year), !is.na(.data[[var]])) %>% pull(!!sym(var))
  control_vals <- panel %>% filter(!is.finite(treat_year), !is.na(.data[[var]])) %>% pull(!!sym(var))
  all_vals <- c(treated_vals, control_vals)

  fmt <- ifelse(var == "total_crop_acres", "%.0f", "%.3f")

  line <- paste0(
    var_labels[var], " & ",
    sprintf(fmt, mean(treated_vals)), " & ",
    sprintf(fmt, sd(treated_vals)), " & ",
    sprintf(fmt, mean(control_vals)), " & ",
    sprintf(fmt, sd(control_vals)), " & ",
    sprintf(fmt, min(all_vals)), " & ",
    sprintf(fmt, max(all_vals)), " \\\\"
  )
  tab1_lines <- c(tab1_lines, line)
}

n_treated <- n_distinct(panel$county_fips[is.finite(panel$treat_year)])
n_control <- n_distinct(panel$county_fips[!is.finite(panel$treat_year)])
n_obs_treated <- nrow(panel %>% filter(is.finite(treat_year)))
n_obs_control <- nrow(panel %>% filter(!is.finite(treat_year)))

tab1_lines <- c(tab1_lines,
  "\\midrule",
  paste0("Counties & \\multicolumn{2}{c}{", n_treated,
         "} & \\multicolumn{2}{c}{", n_control, "} & & \\\\"),
  paste0("County-years & \\multicolumn{2}{c}{",
         format(n_obs_treated, big.mark = ","),
         "} & \\multicolumn{2}{c}{",
         format(n_obs_control, big.mark = ","),
         "} & & \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  paste0("\\item \\textit{Notes:} Crop acreage shares are computed as the area harvested ",
         "for each crop divided by total area harvested across corn, sorghum, wheat, and soybeans. ",
         "Ever-treated counties are those in NRDs that adopted mandatory groundwater allocations ",
         "between 1979 and 2014. Never-treated counties are in NRDs without binding allocations ",
         "during the sample period. Source: USDA NASS Quick Stats, 1988--2023."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

# =================================================================
# Table 2: Main Results — Callaway-Sant'Anna ATT
# =================================================================
cat("Table 2: Main Results\n")

# Extract ATT results
att_results <- tibble(
  outcome = c("Corn share", "Sorghum share", "Wheat share",
              "Drought-tolerant share", "Log total acres"),
  att = c(results$att_corn$overall.att,
          results$att_sorghum$overall.att,
          results$att_wheat$overall.att,
          results$att_drought$overall.att,
          results$att_acres$overall.att),
  se = c(results$att_corn$overall.se,
         results$att_sorghum$overall.se,
         results$att_wheat$overall.se,
         results$att_drought$overall.se,
         results$att_acres$overall.se),
  # TWFE comparison
  twfe_att = c(coef(results$twfe_corn)["treated"],
               coef(results$twfe_sorghum)["treated"],
               coef(results$twfe_drought)["treated"] - coef(results$twfe_sorghum)["treated"],
               coef(results$twfe_drought)["treated"],
               NA),
  twfe_se = c(se(results$twfe_corn)["treated"],
              se(results$twfe_sorghum)["treated"],
              NA,
              se(results$twfe_drought)["treated"],
              NA)
)

# Build table
tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Mandatory Groundwater Allocations on Crop Composition}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & (1) & (2) \\\\",
  " & Callaway--Sant'Anna & TWFE \\\\",
  "\\midrule"
)

for (i in 1:nrow(att_results)) {
  r <- att_results[i, ]
  stars_cs <- ifelse(abs(r$att / r$se) > 2.576, "***",
              ifelse(abs(r$att / r$se) > 1.96, "**",
              ifelse(abs(r$att / r$se) > 1.645, "*", "")))

  cs_str <- paste0(sprintf("%.4f", r$att), stars_cs)
  cs_se_str <- paste0("(", sprintf("%.4f", r$se), ")")

  if (!is.na(r$twfe_att) && !is.na(r$twfe_se)) {
    stars_twfe <- ifelse(abs(r$twfe_att / r$twfe_se) > 2.576, "***",
                  ifelse(abs(r$twfe_att / r$twfe_se) > 1.96, "**",
                  ifelse(abs(r$twfe_att / r$twfe_se) > 1.645, "*", "")))
    twfe_str <- paste0(sprintf("%.4f", r$twfe_att), stars_twfe)
    twfe_se_str <- paste0("(", sprintf("%.4f", r$twfe_se), ")")
  } else {
    twfe_str <- "---"
    twfe_se_str <- ""
  }

  tab2_lines <- c(tab2_lines,
    paste0("\\textit{", r$outcome, "} & ", cs_str, " & ", twfe_str, " \\\\"),
    paste0(" & ", cs_se_str, " & ", twfe_se_str, " \\\\"),
    "\\\\[-0.5em]"
  )
}

n_obs <- nrow(panel %>% filter(!is.na(corn_share)))
n_counties <- n_distinct(panel$county_fips[!is.na(panel$corn_share)])

tab2_lines <- c(tab2_lines,
  "\\midrule",
  paste0("County-years & ", format(n_obs, big.mark = ","),
         " & ", format(n_obs, big.mark = ","), " \\\\"),
  paste0("Counties & ", n_counties, " & ", n_counties, " \\\\"),
  paste0("Control group & Not-yet-treated & --- \\\\"),
  paste0("Clustering & NRD & NRD \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Column (1) reports the overall ATT from Callaway and ",
         "Sant'Anna (2021) with not-yet-treated control group and universal base period. ",
         "Column (2) reports two-way fixed effects estimates with county and year fixed effects. ",
         "Standard errors clustered at the NRD level in parentheses. ",
         "Crop shares are defined as area harvested for each crop divided by total area ",
         "harvested across corn, sorghum, wheat, and soybeans. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Written tables/tab2_main.tex\n")

# =================================================================
# Table 3: Event Study Coefficients
# =================================================================
cat("Table 3: Event Study\n")

# Use TWFE event study (has proper SEs, unlike CS which has singular covariance)
twfe_es <- results$twfe_es_corn
twfe_es_dt <- results$twfe_es_drought
et_vars <- paste0("et_", c(paste0("m", 8:2), paste0("p", 0:12)))
event_times <- c(-8:-2, 0:12)

es_coefs <- coef(twfe_es)[et_vars]
es_ses <- se(twfe_es)[et_vars]
es_coefs_dt <- coef(twfe_es_dt)[et_vars]
es_ses_dt <- se(twfe_es_dt)[et_vars]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Effect of Groundwater Allocations on Crop Shares}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Corn Share} & \\multicolumn{2}{c}{Drought-Tolerant Share} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Years since adoption & Estimate & SE & Estimate & SE \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Pre-treatment (reference: $t = -1$)}} \\\\"
)

for (i in seq_along(event_times)) {
  e <- event_times[i]
  b_corn <- es_coefs[i]
  s_corn <- es_ses[i]
  b_dt <- es_coefs_dt[i]
  s_dt <- es_ses_dt[i]

  stars_corn <- ifelse(abs(b_corn/s_corn) > 2.576, "***",
                ifelse(abs(b_corn/s_corn) > 1.96, "**",
                ifelse(abs(b_corn/s_corn) > 1.645, "*", "")))
  stars_dt <- ifelse(abs(b_dt/s_dt) > 2.576, "***",
              ifelse(abs(b_dt/s_dt) > 1.96, "**",
              ifelse(abs(b_dt/s_dt) > 1.645, "*", "")))

  if (e == 0) {
    tab3_lines <- c(tab3_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Post-treatment}} \\\\"
    )
  }

  tab3_lines <- c(tab3_lines,
    paste0(e, " & ",
           sprintf("%.4f", b_corn), stars_corn, " & (",
           sprintf("%.4f", s_corn), ") & ",
           sprintf("%.4f", b_dt), stars_dt, " & (",
           sprintf("%.4f", s_dt), ") \\\\")
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} TWFE event study with county and year fixed effects. ",
         "Event-time indicators for $e \\in \\{-8, \\ldots, -2, 0, \\ldots, 12\\}$; ",
         "$t = -1$ is the omitted reference period. Always-treated counties (Upper Republican NRD) excluded. ",
         "Standard errors clustered at the NRD level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")
cat("  Written tables/tab3_eventstudy.tex\n")

# =================================================================
# Table 4: Robustness
# =================================================================
cat("Table 4: Robustness\n")

# Collect robustness results
rob_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications for Corn Share}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Estimate & SE \\\\",
  "\\midrule"
)

# Main CS result
rob_lines <- c(rob_lines,
  paste0("\\textit{Main: CS (not-yet-treated)} & ",
         sprintf("%.4f", results$att_corn$overall.att), " & (",
         sprintf("%.4f", results$att_corn$overall.se), ") \\\\")
)

# Never-treated control
cs_nt <- tryCatch(readRDS("../data/cs_corn_nevertreated.rds"), error = function(e) NULL)
if (!is.null(cs_nt)) {
  att_nt <- aggte(cs_nt, type = "simple", na.rm = TRUE)
  rob_lines <- c(rob_lines,
    paste0("CS (never-treated controls) & ",
           sprintf("%.4f", att_nt$overall.att), " & (",
           sprintf("%.4f", att_nt$overall.se), ") \\\\")
  )
}

# TWFE
rob_lines <- c(rob_lines,
  paste0("TWFE & ",
         sprintf("%.4f", coef(results$twfe_corn)["treated"]), " & (",
         sprintf("%.4f", se(results$twfe_corn)["treated"]), ") \\\\")
)

# Leave-one-out
rob_lines <- c(rob_lines,
  paste0("Drop Upper Republican NRD & ",
         sprintf("%.4f", coef(robustness$twfe_loo)["treated"]), " & (",
         sprintf("%.4f", se(robustness$twfe_loo)["treated"]), ") \\\\")
)

# Placebo
rob_lines <- c(rob_lines,
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Placebo}} \\\\",
  paste0("Soybean share & ",
         sprintf("%.4f", coef(robustness$twfe_soybean_placebo)["treated"]), " & (",
         sprintf("%.4f", se(robustness$twfe_soybean_placebo)["treated"]), ") \\\\")
)

# Block bootstrap p-value
boot_res <- tryCatch(readRDS("../data/boot_corn.rds"), error = function(e) NULL)
if (!is.null(boot_res)) {
  rob_lines <- c(rob_lines,
    "\\midrule",
    paste0("\\textit{Block bootstrap SE} & \\multicolumn{2}{c}{",
           sprintf("%.4f", boot_res$se), "} \\\\"),
    paste0("\\textit{Block bootstrap $p$-value} & \\multicolumn{2}{c}{",
           sprintf("%.3f", boot_res$p_val), "} \\\\")
  )
}

rob_lines <- c(rob_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} All specifications use corn share of total cropland as the outcome. ",
         "Row 1 is the baseline Callaway--Sant'Anna estimator with not-yet-treated controls. ",
         "Row 2 uses never-treated counties only. Row 3 is TWFE with county and year FE. ",
         "Row 4 drops the earliest-adopting NRD (Upper Republican, 1979). ",
         "The placebo tests soybean share, which should not respond to irrigation constraints ",
         "as soybeans require less water than corn. ",
         "Block bootstrap resamples NRDs with replacement (999 iterations). ",
         "Standard errors clustered at the NRD level. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(rob_lines, "../tables/tab4_robustness.tex")
cat("  Written tables/tab4_robustness.tex\n")

# =================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =================================================================
cat("Table F1: SDE\n")

# Extract pre-treatment SDs for SDE computation
sd_corn <- sd(panel$corn_share[!is.na(panel$corn_share) &
               (panel$year < panel$first_treat | panel$first_treat == 0)], na.rm = TRUE)
sd_sorghum <- sd(panel$sorghum_share[!is.na(panel$sorghum_share) &
                  (panel$year < panel$first_treat | panel$first_treat == 0)], na.rm = TRUE)
sd_drought <- sd(panel$drought_tolerant_share[!is.na(panel$drought_tolerant_share) &
                  (panel$year < panel$first_treat | panel$first_treat == 0)], na.rm = TRUE)

# SDE computation
sde_corn <- results$att_corn$overall.att / sd_corn
se_sde_corn <- results$att_corn$overall.se / sd_corn
sde_sorghum <- results$att_sorghum$overall.att / sd_sorghum
se_sde_sorghum <- results$att_sorghum$overall.se / sd_sorghum
sde_drought <- results$att_drought$overall.att / sd_drought
se_sde_drought <- results$att_drought$overall.se / sd_drought

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

# Heterogeneity: Early vs Late adopters
# Early: treat_year <= 2000, Late: treat_year > 2000
panel_early <- panel %>% filter(is.finite(treat_year), treat_year <= 2000)
panel_late <- panel %>% filter(is.finite(treat_year), treat_year > 2000)

twfe_early <- tryCatch({
  feols(corn_share ~ treated | county_id + year,
        data = bind_rows(panel_early, panel %>% filter(!is.finite(treat_year))) %>%
          mutate(county_id = as.integer(as.factor(county_fips))),
        cluster = ~nrd_name)
}, error = function(e) NULL)

twfe_late <- tryCatch({
  feols(corn_share ~ treated | county_id + year,
        data = bind_rows(panel_late, panel %>% filter(!is.finite(treat_year))) %>%
          mutate(county_id = as.integer(as.factor(county_fips))),
        cluster = ~nrd_name)
}, error = function(e) NULL)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do mandatory groundwater pumping allocations imposed by Nebraska's Natural Resources Districts cause farmers to shift crop composition away from water-intensive corn toward drought-tolerant alternatives? ",
  "\\textbf{Policy mechanism:} NRDs impose binding annual or multi-year volumetric limits on groundwater pumping (typically 9--18 inches per acre per year), enforced via metered wells and penalties, directly constraining irrigation water available for crop production. ",
  "\\textbf{Outcome definition:} Corn share of total cropland, defined as county-level corn area harvested divided by total area harvested across corn, sorghum, wheat, and soybeans from USDA NASS Quick Stats. ",
  "\\textbf{Treatment:} Binary --- adoption of mandatory groundwater allocations by the county's NRD, with staggered rollout from 1979 to 2014. ",
  "\\textbf{Data:} USDA NASS Quick Stats annual Survey, 1990--2023, county-year level across Nebraska. ",
  "\\textbf{Method:} Staggered DiD with Callaway--Sant'Anna (2021) estimator, not-yet-treated control group, standard errors clustered at the NRD level. ",
  "\\textbf{Sample:} Nebraska counties mapped to NRDs with confirmed allocation status; excludes counties with missing crop acreage data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\footnotesize",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

# Panel A rows
sde_lines <- c(sde_lines,
  paste0("Corn share & CS ATT & ",
         sprintf("%.4f", results$att_corn$overall.att), " & ",
         sprintf("%.3f", sd_corn), " & ",
         sprintf("%.3f", sde_corn), " & ",
         sprintf("%.3f", se_sde_corn), " & ",
         classify(sde_corn), " \\\\"),
  paste0("Sorghum share & CS ATT & ",
         sprintf("%.4f", results$att_sorghum$overall.att), " & ",
         sprintf("%.3f", sd_sorghum), " & ",
         sprintf("%.3f", sde_sorghum), " & ",
         sprintf("%.3f", se_sde_sorghum), " & ",
         classify(sde_sorghum), " \\\\"),
  paste0("Drought-tolerant share & CS ATT & ",
         sprintf("%.4f", results$att_drought$overall.att), " & ",
         sprintf("%.3f", sd_drought), " & ",
         sprintf("%.3f", sde_drought), " & ",
         sprintf("%.3f", se_sde_drought), " & ",
         classify(sde_drought), " \\\\"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\"
)

# Panel B rows
if (!is.null(twfe_early)) {
  beta_early <- coef(twfe_early)["treated"]
  se_early <- se(twfe_early)["treated"]
  sde_early <- beta_early / sd_corn
  se_sde_early <- se_early / sd_corn

  sde_lines <- c(sde_lines,
    paste0("Corn share (early adopters, $\\leq$2000) & TWFE & ",
           sprintf("%.4f", beta_early), " & ",
           sprintf("%.3f", sd_corn), " & ",
           sprintf("%.3f", sde_early), " & ",
           sprintf("%.3f", se_sde_early), " & ",
           classify(sde_early), " \\\\")
  )
}

if (!is.null(twfe_late)) {
  beta_late <- coef(twfe_late)["treated"]
  se_late <- se(twfe_late)["treated"]
  sde_late <- beta_late / sd_corn
  se_sde_late <- se_late / sd_corn

  sde_lines <- c(sde_lines,
    paste0("Corn share (late adopters, $>$2000) & TWFE & ",
           sprintf("%.4f", beta_late), " & ",
           sprintf("%.3f", sd_corn), " & ",
           sprintf("%.3f", sde_late), " & ",
           sprintf("%.3f", se_sde_late), " & ",
           classify(sde_late), " \\\\")
  )
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\scriptsize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
