## ============================================================
## 05_tables.R — Generate all LaTeX tables
## apep_1124: Sanctions at Sea
## ============================================================

source("00_packages.R")

cat("=== Loading data and results ===\n")

panel <- read_csv("../data/panel_annual.csv", show_col_types = FALSE) %>%
  mutate(
    first_treat = ifelse(first_treat == 2012, 2013, first_treat),
    treated = as.integer(first_treat > 0 & year >= first_treat),
    cohort = ifelse(first_treat == 0, 10000, first_treat)
  )

descriptives <- readRDS("../data/descriptives.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
iuu_cards <- read_csv("../data/iuu_cards.csv", show_col_types = FALSE)
cohorts <- read_csv("../data/cohorts.csv", show_col_types = FALSE)

panel_balanced <- panel %>%
  group_by(flag_id) %>%
  filter(n() >= 8) %>%
  ungroup()

pre_sd <- descriptives$pre_sd
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

stars <- function(coef_val, se_val) {
  if (is.na(coef_val) | is.na(se_val) | se_val == 0) return("")
  p <- 2 * pnorm(-abs(coef_val / se_val))
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------

cat("=== Table 1: Summary Statistics ===\n")

make_sumstats <- function(df, label) {
  df %>%
    summarise(
      Countries = n_distinct(flag_id),
      Observations = n(),
      `FH_mean` = mean(fishing_hours),
      `FH_sd` = sd(fishing_hours),
      `V_mean` = mean(n_vessels),
      `HPV_mean` = mean(fishing_hours / pmax(n_vessels, 1))
    ) %>%
    mutate(Sample = label)
}

ss_all <- make_sumstats(panel_balanced, "Full Sample")
ss_treated <- make_sumstats(panel_balanced %>% filter(first_treat > 0), "Carded Countries")
ss_control <- make_sumstats(panel_balanced %>% filter(first_treat == 0), "Never-Carded")
sumstats <- bind_rows(ss_all, ss_treated, ss_control)

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Fishing Effort by EU IUU Carding Status}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & Countries & Obs. & \\multicolumn{2}{c}{Fishing Hours} & Vessels & Hours/ \\\\",
  " & & & Mean & SD & (mean) & Vessel \\\\",
  "\\midrule"
)

for (i in 1:nrow(sumstats)) {
  r <- sumstats[i, ]
  tab1 <- c(tab1, sprintf(
    "%s & %d & %s & %s & %s & %s & %s \\\\",
    r$Sample, r$Countries,
    formatC(r$Observations, format = "d", big.mark = ","),
    formatC(r$FH_mean, format = "f", digits = 0, big.mark = ","),
    formatC(r$FH_sd, format = "f", digits = 0, big.mark = ","),
    formatC(r$V_mean, format = "f", digits = 0, big.mark = ","),
    formatC(r$HPV_mean, format = "f", digits = 1)))
}

tab1 <- c(tab1,
  "\\midrule",
  sprintf("Years & \\multicolumn{6}{c}{%d--%d} \\\\", min(panel_balanced$year), max(panel_balanced$year)),
  sprintf("Treatment cohorts & \\multicolumn{6}{c}{%d cohorts (%d--%d)} \\\\",
          nrow(cohorts), min(cohorts$first_treat), max(cohorts$first_treat)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Unit of observation is flag state $\\times$ year. Fishing hours and vessel counts from Global Fishing Watch AIS satellite tracking data (2012--2024). ``Carded'' countries received an EU IUU yellow card; ``Never-Carded'' serve as controls. Hours/Vessel is total fishing hours divided by unique AIS-transmitting vessels. Panel restricted to flag states with $\\geq$ 8 years of positive fishing activity.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ---------------------------------------------------------------
# Table 2: Treatment Cohorts
# ---------------------------------------------------------------

cat("=== Table 2: Treatment Cohorts ===\n")

cohort_detail <- iuu_cards %>%
  arrange(yellow_date) %>%
  mutate(
    outcome = case_when(
      !is.na(red_date) ~ "Red Card",
      !is.na(green_date) ~ "Green (Lifted)",
      TRUE ~ "Yellow (Ongoing)"
    )
  )

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{EU IUU Fishing Carding Decisions, 2012--2023}",
  "\\label{tab:cohorts}",
  "\\begin{tabular}{llll}",
  "\\toprule",
  "Country & ISO3 & Yellow Card Date & Status \\\\",
  "\\midrule"
)

for (i in 1:nrow(cohort_detail)) {
  r <- cohort_detail[i, ]
  tab2 <- c(tab2, sprintf("%s & %s & %s & %s \\\\",
    r$country_name, r$flag_iso3,
    format(r$yellow_date, "%b %d, %Y"), r$outcome))
}

tab2 <- c(tab2,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Yellow card = formal warning under EU IUU Regulation 1005/2008. Red Card = trade ban on seafood imports to EU. Green (Lifted) = yellow card removed after reforms. Source: European Commission DG MARE decisions.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_cohorts.tex")

# ---------------------------------------------------------------
# Table 3: Main Results
# ---------------------------------------------------------------

cat("=== Table 3: Main Results ===\n")

# Sun-Abraham ATTs
sa_c <- as.numeric(coef(results$sa_att_summary))
sa_s <- as.numeric(se(results$sa_att_summary))
sa_vc <- as.numeric(coef(results$sa_v_att_summary))
sa_vs <- as.numeric(se(results$sa_v_att_summary))
sa_ic <- as.numeric(coef(results$sa_i_att_summary))
sa_is <- as.numeric(se(results$sa_i_att_summary))

# TWFE
tw_c <- as.numeric(coef(results$twfe_main)["treated"])
tw_s <- as.numeric(se(results$twfe_main)["treated"])
tw_vc <- as.numeric(coef(results$twfe_vessels)["treated"])
tw_vs <- as.numeric(se(results$twfe_vessels)["treated"])
tw_ic <- as.numeric(coef(results$twfe_intensive)["treated"])
tw_is <- as.numeric(se(results$twfe_intensive)["treated"])

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of EU IUU Yellow Cards on Fishing Effort}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Sun-Abraham} & \\multicolumn{3}{c}{TWFE} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Log Fish. & Log & Log Hrs/ & Log Fish. & Log & Log Hrs/ \\\\",
  " & Hours & Vessels & Vessel & Hours & Vessels & Vessel \\\\",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\midrule",
  sprintf("Carded & %s%s & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(sa_c), stars(sa_c, sa_s), fmt(sa_vc), stars(sa_vc, sa_vs),
    fmt(sa_ic), stars(sa_ic, sa_is),
    fmt(tw_c), stars(tw_c, tw_s), fmt(tw_vc), stars(tw_vc, tw_vs),
    fmt(tw_ic), stars(tw_ic, tw_is)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(sa_s), fmt(sa_vs), fmt(sa_is), fmt(tw_s), fmt(tw_vs), fmt(tw_is)),
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%s} & \\multicolumn{3}{c}{%s} \\\\",
    formatC(nrow(panel_balanced), format = "d", big.mark = ","),
    formatC(nrow(panel_balanced), format = "d", big.mark = ",")),
  sprintf("Countries & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
    n_distinct(panel_balanced$flag_id), n_distinct(panel_balanced$flag_id)),
  "Estimator & \\multicolumn{3}{c}{Sun-Abraham (2021)} & \\multicolumn{3}{c}{Two-Way FE} \\\\",
  "Clustering & \\multicolumn{3}{c}{Flag State} & \\multicolumn{3}{c}{Flag State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns 1--3 report Sun and Abraham (2021) interaction-weighted estimates aggregated to a single ATT, using never-treated flag states as the control group. Columns 4--6 report standard TWFE. Fishing effort from Global Fishing Watch satellite AIS data, 2012--2024. Standard errors clustered at the flag-state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_main.tex")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------

cat("=== Table 4: Robustness ===\n")

rob_specs <- list()
add_rob <- function(label, mod, n_override = NULL) {
  c_val <- as.numeric(coef(mod)[1])
  s_val <- as.numeric(se(mod)[1])
  nn <- if (!is.null(n_override)) n_override else nobs(mod)
  list(label = label, coef = c_val, se = s_val, n = nn)
}

rob_specs[[1]] <- list(label = "Main (SA, never-treated)", coef = sa_c, se = sa_s,
                        n = nrow(panel_balanced))
rob_specs[[2]] <- add_rob("TWFE", results$twfe_main)

# SA on late cohorts
sa_late_c <- as.numeric(coef(robustness$sa_late_att))
sa_late_s <- as.numeric(se(robustness$sa_late_att))
panel_late <- panel_balanced %>% filter(first_treat == 0 | first_treat >= 2015)
rob_specs[[3]] <- list(label = "SA, cohorts 2015+ only", coef = sa_late_c, se = sa_late_s,
                        n = nrow(panel_late))

rob_specs[[4]] <- add_rob("Drop 2013 cohort", robustness$twfe_no13)
rob_specs[[5]] <- add_rob("Large fleets ($\\geq$ 50 vessels)", robustness$twfe_large)
rob_specs[[6]] <- add_rob("Placebo: small fleets ($<$ 50)", robustness$twfe_placebo_small)

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Effect on Log Fishing Hours}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Estimate & SE & Obs. \\\\",
  "\\midrule"
)

for (rs in rob_specs) {
  tab4 <- c(tab4, sprintf("%s & %s%s & (%s) & %s \\\\",
    rs$label, fmt(rs$coef), stars(rs$coef, rs$se), fmt(rs$se),
    formatC(rs$n, format = "d", big.mark = ",")))
}

tab4 <- c(tab4,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row is a separate specification with log fishing hours as the outcome. Row 1 is the preferred Sun-Abraham estimate. Row 3 restricts to cohorts carded 2015 or later (more pre-treatment periods). Row 5 restricts to flag states with average fleet $\\geq$ 50 vessels. Row 6 is a placebo on small fleets where the mechanism should not operate. All SEs clustered at flag-state level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ---------------------------------------------------------------
# Table 5: Event Study
# ---------------------------------------------------------------

cat("=== Table 5: Event Study ===\n")

es_summ <- results$sa_es_agg
es_coefs <- coef(es_summ)
es_ses <- se(es_summ)
es_names <- names(es_coefs)

# Parse event times
es_times <- as.integer(gsub("year::", "", es_names))

es_tab_df <- data.frame(
  event_time = es_times,
  coef = as.numeric(es_coefs),
  se = as.numeric(es_ses)
) %>%
  filter(event_time >= -4, event_time <= 8) %>%
  arrange(event_time) %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se
  )

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects on Log Fishing Hours}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{rcccc}",
  "\\toprule",
  "Event Time & Estimate & SE & \\multicolumn{2}{c}{95\\% CI} \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_tab_df)) {
  r <- es_tab_df[i, ]
  label <- ifelse(r$event_time == -1, "$-1$ (ref.)", sprintf("$%+d$", r$event_time))
  if (r$event_time == -1) {
    tab5 <- c(tab5, sprintf("%s & 0.000 & --- & --- & --- \\\\", label))
  } else {
    tab5 <- c(tab5, sprintf("%s & %s%s & (%s) & %s & %s \\\\",
      label, fmt(r$coef), stars(r$coef, r$se), fmt(r$se),
      fmt(r$ci_lo), fmt(r$ci_hi)))
  }
}

tab5 <- c(tab5,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sun and Abraham (2021) event-study coefficients aggregated across cohorts, relative to event time $-1$. Event time 0 is the year of yellow card issuance. Pre-treatment coefficients test parallel trends. Standard errors clustered at flag-state level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5, "../tables/tab5_eventstudy.tex")

# ---------------------------------------------------------------
# Table F1: SDE Appendix
# ---------------------------------------------------------------

cat("=== Table F1: Standardized Effect Sizes ===\n")

# Panel A: Pooled
sde_fishing <- sa_c / pre_sd$sd_ln_fishing
sde_fishing_se <- sa_s / pre_sd$sd_ln_fishing
sde_vessels <- sa_vc / pre_sd$sd_ln_vessels
sde_vessels_se <- sa_vs / pre_sd$sd_ln_vessels
sde_intensive <- sa_ic / pre_sd$sd_ln_hpv
sde_intensive_se <- sa_is / pre_sd$sd_ln_hpv

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: Heterogeneity by card resolution
het_resolved_c <- NA; het_resolved_s <- NA
het_escalated_c <- NA; het_escalated_s <- NA

if (!is.null(robustness$twfe_resolved)) {
  het_resolved_c <- as.numeric(coef(robustness$twfe_resolved)["treated"])
  het_resolved_s <- as.numeric(se(robustness$twfe_resolved)["treated"])
}
if (!is.null(robustness$twfe_escalated)) {
  het_escalated_c <- as.numeric(coef(robustness$twfe_escalated)["treated"])
  het_escalated_s <- as.numeric(se(robustness$twfe_escalated)["treated"])
}

sde_resolved <- het_resolved_c / pre_sd$sd_ln_fishing
sde_resolved_se <- het_resolved_s / pre_sd$sd_ln_fishing
sde_escalated <- het_escalated_c / pre_sd$sd_ln_fishing
sde_escalated_se <- het_escalated_s / pre_sd$sd_ln_fishing

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Multiple countries (26 flag states carded by EU, globally distributed across Africa, Asia, Pacific, Caribbean, South America). ",
  "\\textbf{Research question:} Do EU illegal fishing (IUU) yellow card trade-sanction threats reduce satellite-measured fishing effort by sanctioned countries' fleets? ",
  "\\textbf{Policy mechanism:} The EU's IUU Regulation (1005/2008) issues yellow cards to countries with inadequate fisheries governance, ",
  "threatening a complete ban on seafood exports to the EU (the world's largest seafood importer) unless reforms are implemented; ",
  "escalation to a red card triggers the trade ban. ",
  "\\textbf{Outcome definition:} Log annual fishing hours from Global Fishing Watch AIS satellite tracking, measuring total time vessels of each flag state spend actively fishing across all ocean areas. ",
  "\\textbf{Treatment:} Binary---flag-state fleet is treated from the year of yellow card issuance onward. ",
  "\\textbf{Data:} Global Fishing Watch v3 vessel-level data (Zenodo record 14982712), 2012--2024, aggregated to flag state $\\times$ year; 190,000+ tracked fishing vessels across all oceans. ",
  "\\textbf{Method:} Sun and Abraham (2021) interaction-weighted staggered DiD with never-treated control group; standard errors clustered at flag-state level with wild cluster bootstrap robustness. ",
  "\\textbf{Sample:} Flag states with $\\geq$ 8 years of positive fishing hours in GFW data; ",
  "25 treated flag states across 8 treatment cohorts (2013--2021), 177 never-treated control flag states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Log Fishing Hours & %s & %s & %s & %s & %s & %s \\\\",
    fmt(sa_c), fmt(sa_s), fmt(pre_sd$sd_ln_fishing),
    fmt(sde_fishing), fmt(sde_fishing_se), classify_sde(sde_fishing)),
  sprintf("Log Vessels & %s & %s & %s & %s & %s & %s \\\\",
    fmt(sa_vc), fmt(sa_vs), fmt(pre_sd$sd_ln_vessels),
    fmt(sde_vessels), fmt(sde_vessels_se), classify_sde(sde_vessels)),
  sprintf("Log Hours/Vessel & %s & %s & %s & %s & %s & %s \\\\",
    fmt(sa_ic), fmt(sa_is), fmt(pre_sd$sd_ln_hpv),
    fmt(sde_intensive), fmt(sde_intensive_se), classify_sde(sde_intensive)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by card resolution)}} \\\\[3pt]",
  sprintf("Resolved (green card) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(het_resolved_c), fmt(het_resolved_s), fmt(pre_sd$sd_ln_fishing),
    fmt(sde_resolved), fmt(sde_resolved_se), classify_sde(sde_resolved)),
  sprintf("Escalated (red card) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(het_escalated_c), fmt(het_escalated_s), fmt(pre_sd$sd_ln_fishing),
    fmt(sde_escalated), fmt(sde_escalated_se), classify_sde(sde_escalated)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
