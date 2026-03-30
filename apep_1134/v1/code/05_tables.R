## 05_tables.R — Generate all LaTeX tables
## apep_1134: EEG Clawback Threshold Bunching

source("00_packages.R")

de_episodes <- readRDS("../data/de_episodes.rds")
bunching_results <- readRDS("../data/bunching_results.rds")
curtail_reg <- readRDS("../data/curtail_reg.rds")
curtail_wind <- readRDS("../data/curtail_wind.rds")
curtail_solar <- readRDS("../data/curtail_solar.rds")
cross_did <- readRDS("../data/cross_did.rds")
episode_gen <- readRDS("../data/episode_gen.rds")
robustness_summary <- readRDS("../data/robustness_summary.rds")
curtail_profile <- readRDS("../data/curtail_profile.rds")

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  ""
}
fmt <- function(x, digits = 3) formatC(x, digits = digits, format = "f")

extract_coef <- function(model, var_pattern) {
  ct <- coeftable(model)
  idx <- grep(var_pattern, rownames(ct))
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA))
  list(b = ct[idx[1], 1], se = ct[idx[1], 2], p = ct[idx[1], 4])
}

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

tab1_rows <- de_episodes %>%
  mutate(regime = case_when(
    year < 2021 ~ "Pre-2021 (6h)",
    year >= 2021 & year < 2024 ~ "2021--2023 (4h)",
    TRUE ~ "2024 (3h)"
  )) %>%
  group_by(regime) %>%
  summarize(
    n = n(),
    mean_dur = mean(duration_hours),
    sd_dur = sd(duration_hours),
    med_dur = median(duration_hours),
    mean_price = mean(mean_price),
    min_price = min(min_price),
    pct_above = mean(above_threshold) * 100,
    pct_just_below = mean(duration_hours == (first(threshold) - 1)) * 100,
    .groups = "drop"
  )

regime_order <- c("Pre-2021 (6h)", "2021--2023 (4h)", "2024 (3h)")
tab1_rows <- tab1_rows[match(regime_order, tab1_rows$regime), ]

mk_row <- function(label, var, d = 1) {
  sprintf("%s & %s & %s & %s \\\\", label,
          fmt(tab1_rows[[var]][1], d), fmt(tab1_rows[[var]][2], d), fmt(tab1_rows[[var]][3], d))
}

tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Negative-Price Episodes in Germany}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Pre-2021 (6h) & 2021--2023 (4h) & 2024 (3h) \\\\",
  "\\hline",
  mk_row("Number of episodes", "n", 0),
  mk_row("Mean duration (hours)", "mean_dur", 1),
  mk_row("SD duration", "sd_dur", 1),
  mk_row("Median duration (hours)", "med_dur", 1),
  mk_row("Mean price (EUR/MWh)", "mean_price", 1),
  mk_row("Min price (EUR/MWh)", "min_price", 1),
  mk_row("\\% above clawback threshold", "pct_above", 1),
  mk_row("\\% ending just below threshold", "pct_just_below", 1),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  paste0("\\item \\textit{Notes:} A negative-price episode is a maximal consecutive run of hours ",
         "with day-ahead price below zero in the German (DE-LU) bidding zone. The clawback threshold ",
         "is the minimum episode duration triggering loss of EEG market premium: 6 hours before 2021, ",
         "4 hours in 2021--2023, and 3 hours from 2024. ``Just below threshold'' means duration equals ",
         "threshold minus one. Data from Fraunhofer ISE Energy-Charts, 2019--2024."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Wrote tab1_summary.tex\n")

# =============================================================================
# TABLE 2: Within-Episode Generation Profiles
# =============================================================================
cat("=== Table 2: Generation Profiles ===\n")

profile_tab <- curtail_profile %>%
  filter(hours_to_thresh >= -2 & hours_to_thresh <= 4) %>%
  arrange(desc(hours_to_thresh))

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Renewable Generation by Hours to Clawback Threshold}",
  "\\label{tab:profiles}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Hours to Threshold & Renewable (MW) & Wind (MW) & Solar (MW) & $N$ \\\\",
  "\\hline"
)

for (i in 1:nrow(profile_tab)) {
  r <- profile_tab[i, ]
  label <- ifelse(r$hours_to_thresh > 0,
                  sprintf("$h - %d$", r$hours_to_thresh),
                  ifelse(r$hours_to_thresh == 0, "$h$ (threshold)",
                         sprintf("$h + %d$ (post-threshold)", abs(r$hours_to_thresh))))
  tab2_tex <- c(tab2_tex,
    sprintf("%s & %s & %s & %s & %d \\\\",
            label,
            formatC(round(r$mean_renewable_mw), big.mark = ","),
            formatC(round(r$mean_wind_mw), big.mark = ","),
            formatC(round(r$mean_solar_mw), big.mark = ","),
            r$n))
}

tab2_tex <- c(tab2_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  paste0("\\item \\textit{Notes:} Mean generation (MW) by fuel type, indexed by hours to the ",
         "clawback threshold ($h$). $h - k$ denotes $k$ hours before the threshold would trigger; ",
         "$h + k$ denotes $k$ hours after. Sample restricted to episodes with duration $\\geq 3$ hours. ",
         "Renewable includes wind (onshore + offshore), solar, biomass, hydro run-of-river, and geothermal."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_profiles.tex")
cat("  Wrote tab2_profiles.tex\n")

# =============================================================================
# TABLE 3: Curtailment Regressions
# =============================================================================
cat("=== Table 3: Curtailment Regressions ===\n")

c_ren <- extract_coef(curtail_reg, "near_thresholdTRUE")
c_wind <- extract_coef(curtail_wind, "near_thresholdTRUE")
c_solar <- extract_coef(curtail_solar, "near_thresholdTRUE")

# Cross-regime
cross_c <- extract_coef(cross_did, "near_thresholdTRUE:post_reformTRUE")
cross_main <- extract_coef(cross_did, "^near_thresholdTRUE$")
cross_post <- extract_coef(cross_did, "^post_reformTRUE$")

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Within-Episode Curtailment at the Clawback Threshold}",
  "\\label{tab:curtailment}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Renewable & Wind & Solar & Renewable \\\\",
  "\\hline",
  sprintf("Near threshold & %s%s & %s%s & %s%s & %s \\\\",
          fmt(c_ren$b, 1), stars(c_ren$p),
          fmt(c_wind$b, 1), stars(c_wind$p),
          fmt(c_solar$b, 1), stars(c_solar$p),
          fmt(cross_main$b, 1)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(c_ren$se, 1), fmt(c_wind$se, 1), fmt(c_solar$se, 1), fmt(cross_main$se, 1)),
  sprintf("Post-2021 & & & & %s \\\\", fmt(cross_post$b, 1)),
  sprintf(" & & & & (%s) \\\\", fmt(cross_post$se, 1)),
  sprintf("Near threshold $\\times$ Post-2021 & & & & %s \\\\", fmt(cross_c$b, 1)),
  sprintf(" & & & & (%s) \\\\", fmt(cross_c$se, 1)),
  "\\hline",
  "Episode FE & Yes & Yes & Yes & No \\\\",
  "Hour-of-day FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & No & No & No & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(curtail_reg), big.mark = ","),
          formatC(nobs(curtail_wind), big.mark = ","),
          formatC(nobs(curtail_solar), big.mark = ","),
          formatC(nobs(cross_did), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  paste0("\\item \\textit{Notes:} Dependent variable is generation (MW). ``Near threshold'' equals one ",
         "if the episode-hour is zero or one hours from the clawback threshold. Columns (1)--(3) include ",
         "episode fixed effects and hour-of-day fixed effects; sample restricted to episodes with ",
         "duration $\\geq 3$ hours. Column (4) replaces episode FE with month FE and adds an interaction ",
         "with the 2021 reform (threshold tightened from 6h to 4h), using only pre-2021 and 2021--2023 episodes. ",
         "Standard errors clustered by date. ",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_curtailment.tex")
cat("  Wrote tab3_curtailment.tex\n")

# =============================================================================
# TABLE 4: Cross-Country Placebo
# =============================================================================
cat("=== Table 4: Cross-Country Placebo ===\n")

placebo_df <- tryCatch(readRDS("../data/placebo_bunching.rds"), error = function(e) NULL)

if (!is.null(placebo_df)) {
  tab4_tex <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\caption{Placebo: Bunching at 4-Hour Threshold Across Countries}",
    "\\label{tab:placebo}",
    "\\begin{tabular}{lcccc}",
    "\\hline\\hline",
    "Country & Episodes & Bunching $\\hat{b}$ & SE & EEG Clawback? \\\\",
    "\\hline"
  )

  for (i in 1:nrow(placebo_df)) {
    r <- placebo_df[i, ]
    p_val <- if (!is.na(r$se) && r$se > 0) 2 * pnorm(-abs(r$bunching_b / r$se)) else NA
    s <- stars(p_val)
    clawback <- ifelse(r$country == "DE", "Yes", "No")
    tab4_tex <- c(tab4_tex,
      sprintf("%s & %d & %s%s & (%s) & %s \\\\",
              r$country, r$n_episodes,
              fmt(r$bunching_b), s, fmt(r$se), clawback))
  }

  tab4_tex <- c(tab4_tex,
    "\\hline\\hline",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\footnotesize",
    paste0("\\item \\textit{Notes:} Bunching estimated at the 4-hour duration mark for all countries ",
           "using the full 2019--2024 sample. Germany (DE) is the only country with an EEG-style ",
           "clawback at this threshold. France, Austria, Netherlands, and Spain experience negative ",
           "prices but have no equivalent subsidy clawback rule. Estimates use a 5th-order polynomial ",
           "counterfactual with $\\pm 2$ hour exclusion bandwidth. Standard errors from 500 bootstrap replications. ",
           "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tab4_tex, "../tables/tab4_placebo.tex")
  cat("  Wrote tab4_placebo.tex\n")
}

# =============================================================================
# TABLE 5: Robustness
# =============================================================================
cat("=== Table 5: Robustness ===\n")

poly_sens <- robustness_summary$poly_sensitivity
bw_sens <- robustness_summary$bw_sensitivity

tab5_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness of Bunching Estimates (2021--2023, 4h Threshold)}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & $\\hat{b}$ & SE \\\\",
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial Order}} \\\\"
)

for (i in 1:nrow(poly_sens)) {
  p_val <- if (!is.na(poly_sens$se[i]) && poly_sens$se[i] > 0) {
    2 * pnorm(-abs(poly_sens$b[i] / poly_sens$se[i]))
  } else NA
  tab5_tex <- c(tab5_tex,
    sprintf("\\quad Order %d & %s%s & (%s) \\\\",
            poly_sens$poly[i], fmt(poly_sens$b[i]), stars(p_val), fmt(poly_sens$se[i])))
}

tab5_tex <- c(tab5_tex,
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel B: Bandwidth}} \\\\"
)

for (i in 1:nrow(bw_sens)) {
  p_val <- if (!is.na(bw_sens$se[i]) && bw_sens$se[i] > 0) {
    2 * pnorm(-abs(bw_sens$b[i] / bw_sens$se[i]))
  } else NA
  tab5_tex <- c(tab5_tex,
    sprintf("\\quad $\\pm$ %d hours & %s%s & (%s) \\\\",
            bw_sens$bandwidth[i], fmt(bw_sens$b[i]), stars(p_val), fmt(bw_sens$se[i])))
}

donut_p <- if (!is.na(robustness_summary$donut$se) && robustness_summary$donut$se > 0) {
  2 * pnorm(-abs(robustness_summary$donut$b / robustness_summary$donut$se))
} else NA
p5h_p <- if (!is.na(robustness_summary$placebo_5h$se) && robustness_summary$placebo_5h$se > 0) {
  2 * pnorm(-abs(robustness_summary$placebo_5h$b / robustness_summary$placebo_5h$se))
} else NA

tab5_tex <- c(tab5_tex,
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel C: Additional Tests}} \\\\",
  sprintf("\\quad Donut (excl.\\ duration = 4) & %s%s & (%s) \\\\",
          fmt(robustness_summary$donut$b), stars(donut_p), fmt(robustness_summary$donut$se)),
  sprintf("\\quad Placebo threshold (5h) & %s%s & (%s) \\\\",
          fmt(robustness_summary$placebo_5h$b), stars(p5h_p), fmt(robustness_summary$placebo_5h$se)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  paste0("\\item \\textit{Notes:} All specifications use episodes from 2021--2023 and test ",
         "bunching at the 4-hour clawback threshold. Panel A varies the polynomial order of the ",
         "counterfactual distribution (baseline: 5th order). Panel B varies the exclusion bandwidth ",
         "(baseline: $\\pm 2$ hours). Panel C reports a donut specification and placebo test at 5h. ",
         "Standard errors from 200 bootstrap replications. ",
         "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_tex, "../tables/tab5_robustness.tex")
cat("  Wrote tab5_robustness.tex\n")

# =============================================================================
# TABLE F1: SDE Appendix
# =============================================================================
cat("=== Table F1: SDE ===\n")

pre_data <- episode_gen %>%
  filter(lubridate::year(date) < 2021, duration_hours >= 3) %>%
  mutate(near_threshold = (threshold - episode_hour) >= 0 & (threshold - episode_hour) <= 1)

sd_ren_pre <- sd(pre_data$renewable_gen_mw, na.rm = TRUE)
sd_wind_pre <- sd(pre_data$wind_gen_mw, na.rm = TRUE)
sd_solar_pre <- sd(pre_data$solar_gen_mw, na.rm = TRUE)

c_ren <- extract_coef(curtail_reg, "near_thresholdTRUE")
c_wind <- extract_coef(curtail_wind, "near_thresholdTRUE")
c_solar <- extract_coef(curtail_solar, "near_thresholdTRUE")

sde_data <- data.frame(
  outcome = c("Renewable generation", "Wind generation", "Solar generation"),
  beta = c(c_ren$b, c_wind$b, c_solar$b),
  se_beta = c(c_ren$se, c_wind$se, c_solar$se),
  sd_y = c(sd_ren_pre, sd_wind_pre, sd_solar_pre)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde >= -0.15 & sde < -0.05 ~ "Moderate negative",
      sde >= -0.05 & sde < -0.005 ~ "Small negative",
      sde >= -0.005 & sde <= 0.005 ~ "Null",
      sde > 0.005 & sde <= 0.05 ~ "Small positive",
      sde > 0.05 & sde <= 0.15 ~ "Moderate positive",
      sde > 0.15 ~ "Large positive"
    )
  )

# Heterogeneity: daytime vs nighttime (sample splits)
de_episodes_day <- de_episodes %>%
  mutate(daytime = hour_of_day_start >= 6 & hour_of_day_start <= 18)

curtail_het <- episode_gen %>%
  filter(duration_hours >= 3) %>%
  mutate(
    hours_to_thresh = threshold - episode_hour,
    near_threshold = hours_to_thresh >= 0 & hours_to_thresh <= 1
  ) %>%
  left_join(de_episodes_day %>% select(run_id, daytime), by = c("episode_id" = "run_id"))

pre_het <- curtail_het %>% filter(lubridate::year(date) < 2021)
sd_ren_day <- sd(pre_het$renewable_gen_mw[pre_het$daytime == TRUE], na.rm = TRUE)
sd_ren_night <- sd(pre_het$renewable_gen_mw[pre_het$daytime == FALSE], na.rm = TRUE)

reg_day <- feols(renewable_gen_mw ~ near_threshold | episode_id + hour,
                 data = curtail_het %>% filter(daytime == TRUE), cluster = ~date)
reg_night <- feols(renewable_gen_mw ~ near_threshold | episode_id + hour,
                   data = curtail_het %>% filter(daytime == FALSE), cluster = ~date)

c_day <- extract_coef(reg_day, "near_thresholdTRUE")
c_night <- extract_coef(reg_night, "near_thresholdTRUE")

het_data <- data.frame(
  outcome = c("Renewable (daytime)", "Renewable (nighttime)"),
  beta = c(c_day$b, c_night$b),
  se_beta = c(c_day$se, c_night$se),
  sd_y = c(sd_ren_day, sd_ren_night)
) %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se_beta / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde >= -0.15 & sde < -0.05 ~ "Moderate negative",
      sde >= -0.05 & sde < -0.005 ~ "Small negative",
      sde >= -0.005 & sde <= 0.005 ~ "Null",
      sde > 0.005 & sde <= 0.05 ~ "Small positive",
      sde > 0.05 & sde <= 0.15 ~ "Moderate positive",
      sde > 0.15 ~ "Large positive"
    )
  )

n_obs_for_notes <- nrow(episode_gen %>% filter(duration_hours >= 3))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Germany. ",
  "\\textbf{Research question:} Do renewable generators curtail electricity output ",
  "as negative-price episodes approach the EEG subsidy clawback threshold? ",
  "\\textbf{Policy mechanism:} Under the EEG market premium, renewable generators above 400\\,kW ",
  "lose their subsidy for an entire negative-price episode once it reaches the clawback duration; ",
  "we test whether generation drops in the hours immediately before this threshold triggers, ",
  "which would indicate strategic curtailment to preserve subsidies. ",
  "\\textbf{Outcome definition:} Hourly electricity generation (MW) by fuel type during ",
  "negative-price episodes, aggregated from 15-minute Fraunhofer ISE Energy-Charts data. ",
  "\\textbf{Treatment:} Binary; episode-hour is within zero or one hours of the clawback threshold ",
  "versus farther from it. ",
  "\\textbf{Data:} Fraunhofer ISE Energy-Charts, 2019--2024, episode-hour level, ",
  formatC(n_obs_for_notes, big.mark = ","), " observations across 209 episodes. ",
  "\\textbf{Method:} OLS with episode and hour-of-day fixed effects; standard errors clustered by date. ",
  "\\textbf{Sample:} Negative-price episodes in Germany with duration $\\geq 3$ hours. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2021) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_data)) {
  tabF1_tex <- c(tabF1_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            sde_data$outcome[i],
            fmt(sde_data$beta[i], 1), fmt(sde_data$se_beta[i], 1),
            formatC(round(sde_data$sd_y[i]), big.mark = ","),
            fmt(sde_data$sde[i], 3), fmt(sde_data$se_sde[i], 3),
            sde_data$classification[i]))
}

tabF1_tex <- c(tabF1_tex,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\"
)

for (i in 1:nrow(het_data)) {
  tabF1_tex <- c(tabF1_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            het_data$outcome[i],
            fmt(het_data$beta[i], 1), fmt(het_data$se_beta[i], 1),
            formatC(round(het_data$sd_y[i]), big.mark = ","),
            fmt(het_data$sde[i], 3), fmt(het_data$se_sde[i], 3),
            het_data$classification[i]))
}

tabF1_tex <- c(tabF1_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
