## 05_tables.R — Generate all tables for apep_0752
source("00_packages.R")
data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

state_panel <- readRDS(file.path(data_dir, "state_panel_analysis.rds"))
county_panel <- readRDS(file.path(data_dir, "county_panel_analysis.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

median_aian <- median(state_panel$state_aian_share[state_panel$gaming_state], na.rm = TRUE)
state_panel <- state_panel |>
  mutate(
    high_aian = state_aian_share > median_aian,
    period = case_when(
      year <= 2006 ~ "pre_opioid",
      year <= 2013 ~ "rx_wave",
      year <= 2019 ~ "synth_wave",
      TRUE ~ "post_covid"
    )
  )

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

# State-level descriptives by gaming status and period
sum_stats <- state_panel |>
  filter(period != "post_covid") |>
  group_by(gaming_state, period) |>
  summarize(
    n_states = n_distinct(state),
    mean_od_rate = round(mean(od_rate, na.rm = TRUE), 1),
    sd_od_rate = round(sd(od_rate, na.rm = TRUE), 1),
    mean_aian_pct = round(mean(state_aian_share * 100, na.rm = TRUE), 2),
    .groups = "drop"
  ) |>
  mutate(gaming_label = ifelse(gaming_state, "Gaming States", "Non-Gaming States"))

# Write summary stats table
sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Drug Overdose Death Rates by Gaming Status and Opioid Wave}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{llcccc}\n")
cat("\\hline\\hline\n")
cat(" & & States & Mean OD Rate & SD & AI/AN (\\%) \\\\\n")
cat("\\hline\n")
for (gs in c(TRUE, FALSE)) {
  label <- ifelse(gs, "Gaming States", "Non-Gaming States")
  cat("\\multicolumn{6}{l}{\\textit{", label, "}} \\\\\n", sep = "")
  for (p in c("pre_opioid", "rx_wave", "synth_wave")) {
    p_label <- c(pre_opioid = "Pre-Opioid (1999--2006)",
                 rx_wave = "Rx Wave (2007--2013)",
                 synth_wave = "Synthetic Wave (2014--2019)")[p]
    row <- sum_stats |> filter(gaming_state == gs, period == p)
    if (nrow(row) > 0) {
      cat("  & ", p_label, " & ", row$n_states, " & ",
          row$mean_od_rate, " & ", row$sd_od_rate, " & ",
          row$mean_aian_pct, " \\\\\n", sep = "")
    }
  }
  cat("\\hline\n")
}
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Drug overdose death rates are age-adjusted per 100,000 population from CDC NCHS. Gaming states are the 29 states with tribal-state gaming compacts approved under IGRA (Indian Gaming Regulatory Act of 1988). AI/AN share is the 2010 Census American Indian and Alaska Native alone population as a share of total state population. Opioid wave periods follow CDC classification: Pre-Opioid (1999--2006), Prescription Wave (2007--2013), Synthetic Wave (2014--2019).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab1_summary.tex written\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================

cat("=== Table 2: Main Results ===\n")

# Extract key coefficients for a clean hand-formatted table
m1 <- models$m1; m2 <- models$m2; m4 <- models$m4

sink(file.path(table_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Tribal Gaming and Drug Overdose Deaths: Main Results}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & Baseline & Gaming $\\times$ & DDD: Gaming $\\times$ \\\\\n")
cat(" & & High AI/AN & AI/AN $\\times$ Wave \\\\\n")
cat("\\hline\n")

# Helper to format coefficients
fmt_coef <- function(model, varname, digits = 2) {
  est <- coef(model)[varname]
  se <- sqrt(vcov(model)[varname, varname])
  stars <- ifelse(abs(est/se) > 2.576, "***",
           ifelse(abs(est/se) > 1.96, "**",
           ifelse(abs(est/se) > 1.645, "*", "")))
  paste0(format(round(est, digits), nsmall = digits), stars)
}
fmt_se <- function(model, varname, digits = 2) {
  se <- sqrt(vcov(model)[varname, varname])
  paste0("(", format(round(se, digits), nsmall = digits), ")")
}

# Row 1: Gaming state
cat("Gaming State & ", fmt_coef(m1, "gaming_stateTRUE"), " & ",
    fmt_coef(m2, "gaming_stateTRUE"), " & ",
    fmt_coef(m4, "gaming_stateTRUE"), " \\\\\n")
cat(" & ", fmt_se(m1, "gaming_stateTRUE"), " & ",
    fmt_se(m2, "gaming_stateTRUE"), " & ",
    fmt_se(m4, "gaming_stateTRUE"), " \\\\\n")

# Row 2: Gaming × High AI/AN (specs 2-3)
cat("Gaming $\\times$ High AI/AN & & ",
    fmt_coef(m2, "gaming_stateTRUE:high_aianTRUE"), " & ",
    fmt_coef(m4, "gaming_stateTRUE:high_aianTRUE"), " \\\\\n")
cat(" & & ",
    fmt_se(m2, "gaming_stateTRUE:high_aianTRUE"), " & ",
    fmt_se(m4, "gaming_stateTRUE:high_aianTRUE"), " \\\\\n")

# Row 3: Gaming × Synth Wave (spec 3)
sw_var <- "gaming_stateTRUE:period_fsynth_wave"
cat("Gaming $\\times$ Synth. Wave & & & ",
    fmt_coef(m4, sw_var), " \\\\\n")
cat(" & & & ", fmt_se(m4, sw_var), " \\\\\n")

# Row 4: Triple interaction (spec 3)
triple_var <- "gaming_stateTRUE:high_aianTRUE:period_fsynth_wave"
cat("Gaming $\\times$ High AI/AN & & & ",
    fmt_coef(m4, triple_var), " \\\\\n")
cat("\\quad $\\times$ Synth. Wave & & & ",
    fmt_se(m4, triple_var), " \\\\\n")

cat("\\hline\n")
cat("Year FE & Yes & Yes & Yes \\\\\n")
cat("Observations & ", nrow(state_panel |> filter(year <= 2019)), " & ",
    nrow(state_panel |> filter(year <= 2019)), " & ",
    nrow(state_panel |> filter(year <= 2019)), " \\\\\n")
cat("States & ", n_distinct(state_panel$state), " & ",
    n_distinct(state_panel$state), " & ",
    n_distinct(state_panel$state), " \\\\\n")
cat("Mean Dep. Var. & ", round(mean(state_panel$od_rate[state_panel$year <= 2019], na.rm = TRUE), 1),
    " & ", round(mean(state_panel$od_rate[state_panel$year <= 2019], na.rm = TRUE), 1),
    " & ", round(mean(state_panel$od_rate[state_panel$year <= 2019], na.rm = TRUE), 1), " \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Dependent variable is the state-level age-adjusted drug overdose death rate per 100,000. Gaming states are the 29 states with tribal-state gaming compacts under IGRA. High AI/AN indicates states with above-median AI/AN population share among gaming states ($>$", round(median_aian * 100, 2), "\\%). Synthetic Wave = 2014--2019. Standard errors clustered by state in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab2_main.tex written\n")

# ============================================================
# TABLE 3: County-Level Cross-Section
# ============================================================

cat("=== Table 3: County-Level Results ===\n")
m5 <- models$m5; m6 <- models$m6

sink(file.path(table_dir, "tab3_county.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{County-Level Drug Overdose Deaths: Casino vs.\\ Non-Casino Counties (2020--2023)}\n")
cat("\\label{tab:county}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) \\\\\n")
cat(" & OD Rate & OD Rate $\\times$ AI/AN \\\\\n")
cat("\\hline\n")

cat("Casino County & ", fmt_coef(m5, "has_casinoTRUE"), " & ",
    fmt_coef(m6, "has_casinoTRUE"), " \\\\\n")
cat(" & ", fmt_se(m5, "has_casinoTRUE"), " & ",
    fmt_se(m6, "has_casinoTRUE"), " \\\\\n")

if ("has_tribal_landTRUE" %in% names(coef(m5))) {
  cat("Tribal (No Casino) & ", fmt_coef(m5, "has_tribal_landTRUE"), " & ",
      fmt_coef(m6, "has_tribal_landTRUE"), " \\\\\n")
  cat(" & ", fmt_se(m5, "has_tribal_landTRUE"), " & ",
      fmt_se(m6, "has_tribal_landTRUE"), " \\\\\n")
}

if ("has_casinoTRUE:aian_share_2010" %in% names(coef(m6))) {
  cat("Casino $\\times$ AI/AN Share & & ",
      fmt_coef(m6, "has_casinoTRUE:aian_share_2010"), " \\\\\n")
  cat(" & & ", fmt_se(m6, "has_casinoTRUE:aian_share_2010"), " \\\\\n")
}

cat("\\hline\n")
cat("Year FE & Yes & Yes \\\\\n")
cat("Observations & ", nrow(county_panel), " & ", nrow(county_panel), " \\\\\n")
cat("Counties & ", n_distinct(county_panel$fips), " & ", n_distinct(county_panel$fips), " \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Dependent variable is the county-level drug overdose death rate per 100,000, from CDC VSRR Provisional County-Level Drug Overdose Deaths (2020--2023). Casino County indicates a county containing federally recognized tribal land in a state with an approved IGRA gaming compact. Tribal (No Casino) indicates a county with tribal land but no gaming compact. AI/AN Share is the 2010 Census American Indian/Alaska Native alone population share. Standard errors clustered by county. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab3_county.tex written\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================

cat("=== Table 4: Robustness ===\n")

sink(file.path(table_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks: Gaming $\\times$ High AI/AN $\\times$ Synthetic Wave}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Baseline & Log & Pre-COVID & Drop Low \\\\\n")
cat(" & & Spec. & Only & AI/AN \\\\\n")
cat("\\hline\n")

# Extract triple interaction from each model
m4_main <- models$m4
tv <- "gaming_stateTRUE:high_aianTRUE:period_fsynth_wave"

cat("Gaming $\\times$ High AI/AN & ", fmt_coef(m4_main, tv), " & ",
    fmt_coef(rob_models$r1, tv), " & ",
    fmt_coef(rob_models$r2, tv), " & ",
    fmt_coef(rob_models$r5, tv), " \\\\\n")
cat("\\quad $\\times$ Synth. Wave & ", fmt_se(m4_main, tv), " & ",
    fmt_se(rob_models$r1, tv), " & ",
    fmt_se(rob_models$r2, tv), " & ",
    fmt_se(rob_models$r5, tv), " \\\\\n")

cat("\\hline\n")
cat("Dep. Var. & Level & Log & Level & Level \\\\\n")
cat("Sample & Full & Full & $\\leq$2018 & AI/AN$>$0.5\\% \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Each column reports the triple-difference coefficient Gaming $\\times$ High AI/AN $\\times$ Synthetic Wave from variants of the specification in Table~\\ref{tab:main}, column (3). Column (1) reproduces the baseline. Column (2) uses log(OD rate + 0.1). Column (3) restricts to years 1999--2018 (pre-COVID). Column (4) drops states with AI/AN population share below 0.5\\%. All specifications include year fixed effects and cluster standard errors by state.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab4_robustness.tex written\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================

cat("=== Table F1: SDE Appendix ===\n")

# Compute SDE for main outcomes
# SDE = beta_hat / SD(Y)
sd_y <- sd(state_panel$od_rate[state_panel$year <= 2019], na.rm = TRUE)

# Main results from m4 (DDD specification)
sde_rows <- list()

# 1. Gaming state (baseline, pre-opioid)
b1 <- coef(m4_main)["gaming_stateTRUE"]
se1 <- sqrt(vcov(m4_main)["gaming_stateTRUE", "gaming_stateTRUE"])
sde1 <- b1 / sd_y
se_sde1 <- se1 / sd_y

# 2. Gaming × High AI/AN
b2 <- coef(m4_main)["gaming_stateTRUE:high_aianTRUE"]
se2 <- sqrt(vcov(m4_main)["gaming_stateTRUE:high_aianTRUE", "gaming_stateTRUE:high_aianTRUE"])
sde2 <- b2 / sd_y
se_sde2 <- se2 / sd_y

# 3. Gaming × Synthetic Wave
b3 <- coef(m4_main)["gaming_stateTRUE:period_fsynth_wave"]
se3 <- sqrt(vcov(m4_main)["gaming_stateTRUE:period_fsynth_wave", "gaming_stateTRUE:period_fsynth_wave"])
sde3 <- b3 / sd_y
se_sde3 <- se3 / sd_y

# 4. Triple: Gaming × High AI/AN × Synthetic Wave
b4 <- coef(m4_main)[tv]
se4 <- sqrt(vcov(m4_main)[tv, tv])
sde4 <- b4 / sd_y
se_sde4 <- se4 / sd_y

# Classification function
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_df <- tibble(
  outcome = c("Gaming State (baseline)", "Gaming $\\times$ High AI/AN",
              "Gaming $\\times$ Synth. Wave", "Gaming $\\times$ High AI/AN $\\times$ Synth. Wave"),
  beta = c(b1, b2, b3, b4),
  se = c(se1, se2, se3, se4),
  sd_y = sd_y,
  sde = c(sde1, sde2, sde3, sde4),
  se_sde = c(se_sde1, se_sde2, se_sde3, se_sde4),
  classification = classify_sde(c(sde1, sde2, sde3, sde4))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does tribal casino gaming income protect ",
  "or harm American Indian/Alaska Native communities during the opioid epidemic? ",
  "\\textbf{Policy mechanism:} The Indian Gaming Regulatory Act (1988) authorized ",
  "tribal-state gaming compacts that enabled casino operations on tribal lands ",
  "in 29 states, generating per capita revenue distributions and employment. ",
  "\\textbf{Outcome definition:} State-level age-adjusted drug overdose death rate ",
  "per 100,000 population from CDC NCHS. ",
  "\\textbf{Treatment:} Binary: state has approved tribal gaming compact under IGRA. ",
  "\\textbf{Data:} CDC NCHS and VSRR, 1999--2019, state-year panel, 51 states, ",
  "1,071 state-year observations. ",
  "\\textbf{Method:} Triple-difference (gaming state $\\times$ high AI/AN share ",
  "$\\times$ opioid wave period) with year fixed effects and state-clustered standard errors. ",
  "\\textbf{Sample:} All 50 states plus DC; gaming states are the 29 with IGRA compacts; ",
  "high AI/AN defined as above-median AI/AN share among gaming states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-state ",
  "standard deviation of age-adjusted OD rate. Classification refers to magnitude, ",
  "not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sde_df)) {
  cat(sde_df$outcome[i], " & ",
      format(round(sde_df$beta[i], 2), nsmall = 2), " & ",
      format(round(sde_df$se[i], 2), nsmall = 2), " & ",
      format(round(sde_df$sd_y[i], 2), nsmall = 2), " & ",
      format(round(sde_df$sde[i], 3), nsmall = 3), " & ",
      format(round(sde_df$se_sde[i], 3), nsmall = 3), " & ",
      sde_df$classification[i], " \\\\\n")
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tabF1_sde.tex written\n")

cat("\nAll tables generated.\n")
