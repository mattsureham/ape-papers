## 05_tables.R — Generate all LaTeX tables
## APEP-1185: Kratom Bans and Opioid Overdose Mortality

source("00_packages.R")

models <- readRDS("../data/twfe_models.rds")
results_twfe <- readRDS("../data/results_twfe.rds")
pre_stats <- readRDS("../data/pre_stats.rds")
sumstats <- readRDS("../data/sumstats.rds")
df <- readRDS("../data/analysis_panel.rds")

df <- df %>%
  mutate(
    log_opioids = log(opioids_all + 1),
    log_synthetic = log(opioids_synthetic + 1),
    log_natural = log(opioids_natural + 1),
    log_heroin = log(heroin + 1),
    log_psychostim = log(psychostimulants + 1),
    log_cocaine = log(cocaine + 1),
    log_allod = log(all_drug_od + 1)
  )

# Load optional results
boot_res <- tryCatch(readRDS("../data/boot_opioid.rds"), error = function(e) NULL)
ri_res <- tryCatch(readRDS("../data/ri_results.rds"), error = function(e) NULL)
loo_df <- tryCatch(readRDS("../data/loo_results.rds"), error = function(e) NULL)
cs_res <- tryCatch(readRDS("../data/cs_results.rds"), error = function(e) NULL)
m_neighbor <- tryCatch(readRDS("../data/m_neighbor.rds"), error = function(e) NULL)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics...\n")

# Compute summary stats by treatment group
tab1_data <- df %>%
  mutate(group = if_else(treated_state == 1, "Ban States", "Control States")) %>%
  group_by(group) %>%
  summarize(
    `N (state-months)` = n(),
    `States` = n_distinct(state_name),
    `Opioid Deaths (12m)` = sprintf("%.0f", mean(opioids_all, na.rm = TRUE)),
    `SD` = sprintf("%.0f", sd(opioids_all, na.rm = TRUE)),
    `Synthetic Opioid Deaths` = sprintf("%.0f", mean(opioids_synthetic, na.rm = TRUE)),
    `Heroin Deaths` = sprintf("%.0f", mean(heroin, na.rm = TRUE)),
    `Psychostimulant Deaths` = sprintf("%.0f", mean(psychostimulants, na.rm = TRUE)),
    `All Drug OD Deaths` = sprintf("%.0f", mean(all_drug_od, na.rm = TRUE)),
    .groups = "drop"
  )

tab1_tex <- kbl(tab1_data, format = "latex", booktabs = TRUE,
                caption = "Summary Statistics: 12-Month Ending Drug Overdose Deaths by Treatment Status",
                label = "tab:sumstats") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "Data from CDC VSRR Provisional Drug Overdose Deaths (2015--2025). ",
    "Each observation is a state-month 12-month ending count. ",
    "Ban states: Alabama, Arkansas, Indiana, Rhode Island, Wisconsin. ",
    "Control states: 41 states and DC with no kratom prohibition."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# ============================================================================
# Table 2: Main Results — Drug-Type Decomposition
# ============================================================================

cat("Generating Table 2: Drug-Type Decomposition...\n")

# Use etable from fixest for clean LaTeX output
tab2 <- etable(
  models$m1_allod, models$m1_opioid, models$m1_synthetic,
  models$m1_natural, models$m1_heroin,
  models$m1_psychostim, models$m1_cocaine,
  headers = c("All Drug OD", "All Opioids", "Synthetic", "Natural",
              "Heroin", "Psychostim.", "Cocaine"),
  se.below = TRUE,
  dict = c(post_ban = "Kratom Ban"),
  drop = "Intercept",
  fitstat = ~n + wr2,
  tex = TRUE,
  title = "The Substitution Trap: Drug-Type Decomposition of Kratom Ban Effects",
  label = "tab:main",
  notes = paste0(
    "Each column reports a TWFE regression of log(deaths + 1) on a kratom ban indicator ",
    "with state and year-month fixed effects. Deaths are 12-month ending provisional counts ",
    "from CDC VSRR (2015--2025). Standard errors clustered at the state level in parentheses. ",
    "Columns (1)--(5) cover opioid categories; columns (6)--(7) are negative controls ",
    "(kratom is an opioid receptor agonist, not a psychostimulant or cocaine substitute). ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Robustness — Alternative Inference and Specifications
# ============================================================================

cat("Generating Table 3: Robustness...\n")

# Build robustness table manually
rob_rows <- list()

# Row 1: Main TWFE
rob_rows[[1]] <- c(
  "TWFE (baseline)",
  sprintf("%.4f", coef(models$m1_opioid)),
  sprintf("%.4f", se(models$m1_opioid)),
  sprintf("%.3f", pvalue(models$m1_opioid)),
  as.character(nobs(models$m1_opioid))
)

# Row 2: Wild cluster bootstrap p-value
if (!is.null(boot_res)) {
  rob_rows[[2]] <- c(
    "Wild cluster bootstrap",
    sprintf("%.4f", coef(models$m1_opioid)),
    "---",
    sprintf("%.3f", boot_res$p_val),
    as.character(nobs(models$m1_opioid))
  )
}

# Row 3: Randomization inference
if (!is.null(ri_res)) {
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Randomization inference",
    sprintf("%.4f", ri_res$obs_coef),
    "---",
    sprintf("%.3f", ri_res$ri_pvalue),
    as.character(nobs(models$m1_opioid))
  )
}

# Row 4: Callaway-Sant'Anna
if (!is.null(cs_res)) {
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Callaway-Sant'Anna (AR, AL, RI)",
    sprintf("%.4f", cs_res$cs_agg$overall.att),
    sprintf("%.4f", cs_res$cs_agg$overall.se),
    "---",
    "---"
  )
}

# Row 5: Neighbor controls
if (!is.null(m_neighbor)) {
  rob_rows[[length(rob_rows) + 1]] <- c(
    "Neighbor states only",
    sprintf("%.4f", coef(m_neighbor)),
    sprintf("%.4f", se(m_neighbor)),
    sprintf("%.3f", pvalue(m_neighbor)),
    as.character(nobs(m_neighbor))
  )
}

rob_df <- as.data.frame(do.call(rbind, rob_rows))
names(rob_df) <- c("Specification", "Coefficient", "SE", "p-value", "N")

tab3_tex <- kbl(rob_df, format = "latex", booktabs = TRUE,
                caption = "Robustness: Alternative Inference Methods and Control Groups",
                label = "tab:robust", align = "lcccc") %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = paste0(
    "Outcome: log(opioid overdose deaths + 1). Row 1: baseline TWFE with state and ",
    "year-month FEs, clustered SEs. Row 2: Webb (2023) six-point wild cluster bootstrap. ",
    "Row 3: randomization inference (1,000 permutations of treatment assignment). ",
    "Row 4: Callaway and Sant'Anna (2021) with 3 treatment cohorts (AR 2015, AL 2016, ",
    "RI 2017) and never-treated comparison. Row 5: control group restricted to states ",
    "bordering ban states."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tab3_tex, "../tables/tab3_robust.tex")

# ============================================================================
# Table 4: Leave-One-Out
# ============================================================================

cat("Generating Table 4: Leave-One-Out...\n")

if (!is.null(loo_df)) {
  loo_df$stars <- ifelse(abs(loo_df$coef / loo_df$se) > 2.576, "***",
                  ifelse(abs(loo_df$coef / loo_df$se) > 1.96, "**",
                  ifelse(abs(loo_df$coef / loo_df$se) > 1.645, "*", "")))

  loo_display <- loo_df %>%
    mutate(
      `Dropped State` = dropped,
      `Coefficient` = sprintf("%.4f%s", coef, stars),
      `SE` = sprintf("(%.4f)", se)
    ) %>%
    select(`Dropped State`, Coefficient, SE)

  # Add full sample row
  full_row <- tibble(
    `Dropped State` = "None (full sample)",
    Coefficient = sprintf("%.4f", coef(models$m1_opioid)),
    SE = sprintf("(%.4f)", se(models$m1_opioid))
  )
  loo_display <- bind_rows(full_row, loo_display)

  tab4_tex <- kbl(loo_display, format = "latex", booktabs = TRUE,
                  caption = "Leave-One-Out: Sensitivity to Individual Ban States",
                  label = "tab:loo", align = "lcc") %>%
    kable_styling(latex_options = c("hold_position")) %>%
    footnote(general = paste0(
      "Each row drops one treated state and re-estimates the TWFE specification. ",
      "Outcome: log(opioid overdose deaths + 1). ",
      "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
    ), threeparttable = TRUE, escape = FALSE)

  writeLines(tab4_tex, "../tables/tab4_loo.tex")
}

# ============================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================================

cat("Generating Table F1: Standardized Effect Sizes...\n")

# SDE = beta / SD(Y) for binary treatment
sd_y_opioid <- pre_stats$sd_log_opioids
sd_y_synthetic <- pre_stats$sd_log_synthetic
sd_y_heroin <- pre_stats$sd_log_heroin
sd_y_psychostim <- pre_stats$sd_log_psychostim

sde_data <- tibble(
  Outcome = c(
    "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
    "All opioid deaths (log)",
    "Synthetic opioid deaths (log)",
    "Heroin deaths (log)",
    "Psychostimulant deaths (log)",
    "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous --- Pre-Ban Opioid Burden}} \\\\",
    "High-burden states: all opioids"
  )
)

# Compute SDEs
beta_opioid <- coef(models$m1_opioid)["post_ban"]
se_opioid <- se(models$m1_opioid)["post_ban"]
sde_opioid <- beta_opioid / sd_y_opioid
se_sde_opioid <- se_opioid / sd_y_opioid

beta_synth <- coef(models$m1_synthetic)["post_ban"]
se_synth <- se(models$m1_synthetic)["post_ban"]
sde_synth <- beta_synth / sd_y_synthetic
se_sde_synth <- se_synth / sd_y_synthetic

beta_heroin <- coef(models$m1_heroin)["post_ban"]
se_heroin <- se(models$m1_heroin)["post_ban"]
sde_heroin <- beta_heroin / sd_y_heroin
se_sde_heroin <- se_heroin / sd_y_heroin

beta_psych <- coef(models$m1_psychostim)["post_ban"]
se_psych <- se(models$m1_psychostim)["post_ban"]
sde_psych <- beta_psych / sd_y_psychostim
se_sde_psych <- se_psych / sd_y_psychostim

# Heterogeneity: high-burden states (above-median pre-ban opioid death rate)
pre_burden <- df %>%
  filter(year <= 2015) %>%
  group_by(state_name) %>%
  summarize(pre_opioid = mean(opioids_all, na.rm = TRUE), .groups = "drop")

median_burden <- median(pre_burden$pre_opioid, na.rm = TRUE)
high_burden <- pre_burden$state_name[pre_burden$pre_opioid >= median_burden]

df_high <- df %>%
  filter(state_name %in% high_burden) %>%
  mutate(log_opioids = log(opioids_all + 1))

m_high <- tryCatch(
  feols(log_opioids ~ post_ban | state_id + ym,
        data = df_high, cluster = ~state_id),
  error = function(e) NULL
)

if (!is.null(m_high)) {
  sd_y_high <- sd(df_high$log_opioids[df_high$post_ban == 0 | df_high$treated_state == 0], na.rm = TRUE)
  beta_high <- coef(m_high)["post_ban"]
  se_high <- se(m_high)["post_ban"]
  sde_high <- beta_high / sd_y_high
  se_sde_high <- se_high / sd_y_high
} else {
  beta_high <- se_high <- sd_y_high <- sde_high <- se_sde_high <- NA_real_
}

# Low-burden heterogeneity
low_burden <- pre_burden$state_name[pre_burden$pre_opioid < median_burden]

df_low <- df %>%
  filter(state_name %in% low_burden) %>%
  mutate(log_opioids = log(opioids_all + 1))

m_low <- tryCatch(
  feols(log_opioids ~ post_ban | state_id + ym,
        data = df_low, cluster = ~state_id),
  error = function(e) NULL
)

if (!is.null(m_low)) {
  sd_y_low <- sd(df_low$log_opioids[df_low$post_ban == 0 | df_low$treated_state == 0], na.rm = TRUE)
  beta_low <- coef(m_low)["post_ban"]
  se_low <- se(m_low)["post_ban"]
  sde_low <- beta_low / sd_y_low
  se_sde_low <- se_low / sd_y_low
} else {
  beta_low <- se_low <- sd_y_low <- sde_low <- se_sde_low <- NA_real_
}

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table data
sde_rows <- tribble(
  ~Outcome,        ~Beta,       ~SE_beta,  ~SD_Y,         ~SDE,        ~SE_SDE,      ~Class,
  "All opioid OD deaths (log)", beta_opioid, se_opioid, sd_y_opioid, sde_opioid, se_sde_opioid, classify_sde(sde_opioid),
  "Synthetic opioid deaths (log)", beta_synth, se_synth, sd_y_synthetic, sde_synth, se_sde_synth, classify_sde(sde_synth),
  "Heroin deaths (log)", beta_heroin, se_heroin, sd_y_heroin, sde_heroin, se_sde_heroin, classify_sde(sde_heroin),
  "Psychostimulant deaths (log)", beta_psych, se_psych, sd_y_psychostim, sde_psych, se_sde_psych, classify_sde(sde_psych)
)

# Build heterogeneity rows, skipping NA entries
sde_het_list <- list()
if (!is.na(beta_high)) {
  sde_het_list[[length(sde_het_list) + 1]] <- tibble(
    Outcome = "All opioids --- high burden",
    Beta = beta_high, SE_beta = se_high, SD_Y = sd_y_high,
    SDE = sde_high, SE_SDE = se_sde_high, Class = classify_sde(sde_high)
  )
}
if (!is.na(beta_low)) {
  sde_het_list[[length(sde_het_list) + 1]] <- tibble(
    Outcome = "All opioids --- low burden",
    Beta = beta_low, SE_beta = se_low, SD_Y = sd_y_low,
    SDE = sde_low, SE_SDE = se_sde_low, Class = classify_sde(sde_low)
  )
}
sde_het_rows <- bind_rows(sde_het_list)

# Format numbers
fmt_sde <- function(rows) {
  rows %>% mutate(
    Beta = sprintf("%.4f", Beta),
    SE_beta = sprintf("%.4f", SE_beta),
    SD_Y = sprintf("%.3f", SD_Y),
    SDE = sprintf("%.4f", SDE),
    SE_SDE = sprintf("%.4f", SE_SDE)
  )
}

sde_rows_fmt <- fmt_sde(sde_rows)
sde_het_fmt <- fmt_sde(sde_het_rows)

# Build LaTeX manually for proper panel structure
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level kratom bans increase opioid overdose mortality by eliminating a harm-reduction substitute? ",
  "\\textbf{Policy mechanism:} Five states classified kratom (a plant-based partial opioid agonist used for pain and withdrawal) as Schedule~I during 2014--2017, criminalizing possession and sale and removing a legal, lower-risk alternative to illicit opioids. ",
  "\\textbf{Outcome definition:} 12-month ending provisional drug overdose death counts from CDC VSRR, decomposed by ICD-10 T-codes into opioid subtypes and negative-control drug classes. ",
  "\\textbf{Treatment:} Binary indicator equal to one after a state enacts a kratom ban. ",
  "\\textbf{Data:} CDC VSRR Provisional Drug Overdose Deaths, state-month panel, 2015--2025, 46 states, 5,979 state-months. ",
  "\\textbf{Method:} TWFE with state and year-month fixed effects; standard errors clustered at the state level; robustness via wild cluster bootstrap and randomization inference. ",
  "\\textbf{Sample:} 5 ban states (AL, AR, IN, RI, WI) vs.\\ 41 control states; excludes 8 states with $>$50\\% suppressed opioid counts. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pooled pre-treatment standard deviation of the log outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(apply(sde_rows_fmt, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous --- Pre-Ban Opioid Burden}} \\\\\n",
  paste(apply(sde_het_fmt, 1, function(r) paste(r, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
