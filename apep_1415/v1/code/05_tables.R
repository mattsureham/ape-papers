# 05_tables.R — Generate all LaTeX tables
# APEP 1415: Morocco Cannabis Legalization

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))
sde_info <- readRDS(file.path(data_dir, "sde_info.rds"))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

cat("=== Table 1: Summary Statistics ===\n")

# Compute by treatment group
sumstats <- panel %>%
  group_by(Group = ifelse(treated == 1, "Eligible", "Ineligible")) %>%
  summarize(
    `N cells` = n_distinct(cell_id),
    `Mean NL` = mean(nl_mean, na.rm = TRUE),
    `SD NL` = sd(nl_mean, na.rm = TRUE),
    `Mean asinh(NL)` = mean(asinh_nl, na.rm = TRUE),
    `SD asinh(NL)` = sd(asinh_nl, na.rm = TRUE),
    `Mean dist. (km)` = mean(dist_to_boundary_km, na.rm = TRUE),
    .groups = "drop"
  )

# Pre/post comparison
pre_post <- panel %>%
  mutate(Period = ifelse(post == 0, "Pre (2014--2021)", "Post (2022--2023)"),
         Group = ifelse(treated == 1, "Eligible", "Ineligible")) %>%
  group_by(Group, Period) %>%
  summarize(
    `Mean NL` = mean(nl_mean, na.rm = TRUE),
    `Mean asinh(NL)` = mean(asinh_nl, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nSummary:\n")
print(sumstats)
cat("\nPre/post:\n")
print(pre_post)

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{Eligible Provinces} & \\multicolumn{3}{c}{Ineligible Provinces} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  " & Mean & SD & N & Mean & SD & N \\\\\n",
  "\\midrule\n"
)

# Eligible stats
el <- sumstats %>% filter(Group == "Eligible")
in_el <- sumstats %>% filter(Group == "Ineligible")

tab1_tex <- paste0(tab1_tex,
  sprintf("Nightlight radiance (nW/cm\\textsuperscript{2}/sr) & %.3f & %.3f & %d & %.3f & %.3f & %d \\\\\n",
          el$`Mean NL`, el$`SD NL`, el$`N cells`,
          in_el$`Mean NL`, in_el$`SD NL`, in_el$`N cells`),
  sprintf("asinh(Nightlight radiance) & %.3f & %.3f & & %.3f & %.3f & \\\\\n",
          el$`Mean asinh(NL)`, el$`SD asinh(NL)`,
          in_el$`Mean asinh(NL)`, in_el$`SD asinh(NL)`),
  sprintf("Distance to boundary (km) & %.1f & & & %.1f & & \\\\\n",
          el$`Mean dist. (km)`, in_el$`Mean dist. (km)`)
)

# Pre/post means
el_pre <- pre_post %>% filter(Group == "Eligible", grepl("Pre", Period))
el_post <- pre_post %>% filter(Group == "Eligible", grepl("Post", Period))
in_pre <- pre_post %>% filter(Group == "Ineligible", grepl("Pre", Period))
in_post <- pre_post %>% filter(Group == "Ineligible", grepl("Post", Period))

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Pre/Post Means}} \\\\\n",
  sprintf("Pre-treatment asinh(NL) & %.3f & & & %.3f & & \\\\\n",
          el_pre$`Mean asinh(NL)`, in_pre$`Mean asinh(NL)`),
  sprintf("Post-treatment asinh(NL) & %.3f & & & %.3f & & \\\\\n",
          el_post$`Mean asinh(NL)`, in_post$`Mean asinh(NL)`),
  sprintf("$\\Delta$ & %.3f & & & %.3f & & \\\\\n",
          el_post$`Mean asinh(NL)` - el_pre$`Mean asinh(NL)`,
          in_post$`Mean asinh(NL)` - in_pre$`Mean asinh(NL)`)
)

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Unit of observation is a 5km $\\times$ 5km grid cell. ",
  sprintf("N = %s grid-cell-year observations across %d cells and %d years (2014--2023). ",
          format(nrow(panel), big.mark = ","), n_distinct(panel$cell_id),
          n_distinct(panel$year)),
  "Nightlight radiance from NASA Black Marble VNP46A4 annual composites. ",
  "Eligible provinces: Al Hoceima, Chefchaouen, Taounate (designated under Decree 2-22-159). ",
  "Ineligible provinces: Taza, Larache, T\\'etouan, M'diq-Fnideq, Fahs-Anjra, Nador (adjacent). ",
  "Distance measured from grid cell centroid to nearest eligible province boundary.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================

cat("\n=== Table 2: Main Results ===\n")

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3

# Get C-S overall
cs_att <- results$cs_overall$overall.att
cs_se <- results$cs_overall$overall.se

# Border sample
m_border <- rob$m_border

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Cannabis Legalization on Nighttime Light Intensity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & TWFE & Lat.~trends & Log(NL) & C--S & Border 20km \\\\\n",
  "\\midrule\n",
  sprintf("Eligible $\\times$ Post & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
          coef(m1)["treat_post"], coef(m2)["treat_post"],
          coef(m3)["treat_post"], cs_att, coef(m_border)["treat_post"]),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          sqrt(vcov(m1)["treat_post", "treat_post"]),
          sqrt(vcov(m2)["treat_post", "treat_post"]),
          sqrt(vcov(m3)["treat_post", "treat_post"]),
          cs_se,
          sqrt(vcov(m_border)["treat_post", "treat_post"])),
  " \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m1), big.mark = ","),
          format(nobs(m_border), big.mark = ",")),
  "Grid cell FE & Yes & Yes & Yes & --- & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & --- & Yes \\\\\n",
  "Lat. $\\times$ Year & No & Yes & No & No & No \\\\\n",
  sprintf("$R^2$ (within) & %.4f & %.4f & %.4f & --- & %.4f \\\\\n",
          fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
          fitstat(m3, "wr2")[[1]], fitstat(m_border, "wr2")[[1]]),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Standard errors clustered at the province level in parentheses. ",
  "Dependent variable: asinh(nightlight radiance) in columns (1)--(2), (4)--(5); ",
  "log(radiance + 0.01) in column (3). ",
  "Column (4) reports the Callaway and Sant'Anna (2021) aggregate ATT using never-treated as control. ",
  "Column (5) restricts to grid cells within 20km of the eligible/ineligible boundary. ",
  "Treatment is an indicator for cells in Al Hoceima, Chefchaouen, or Taounate interacted with ",
  "Post $\\geq$ 2022 (effective date of Decree 2-22-159). ",
  "Unit of observation: 5km $\\times$ 5km grid cell $\\times$ year.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# =============================================================================
# Table 3: Event Study Coefficients
# =============================================================================

cat("\n=== Table 3: Event Study ===\n")

es <- results$es_model
es_coefs <- coeftable(es)

# Extract relative year coefficients
rel_years <- as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_coefs)))
es_df <- data.frame(
  rel_year = rel_years,
  estimate = es_coefs[, 1],
  se = es_coefs[, 2],
  p = es_coefs[, 4]
)

# Add C-S dynamic estimates
cs_es <- results$cs_es
cs_df <- data.frame(
  e = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
)

# Merge
es_merged <- es_df %>%
  left_join(cs_df, by = c("rel_year" = "e"))

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Pre-Treatment Trends and Dynamic Effects}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{TWFE} & \\multicolumn{2}{c}{Callaway--Sant'Anna} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Relative Year & Estimate & SE & ATT & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_merged)) {
  ry <- es_merged$rel_year[i]
  marker <- ifelse(ry == -1, " (ref.)", "")

  twfe_est <- ifelse(ry == -1, "---",
                     sprintf("%.4f", es_merged$estimate[i]))
  twfe_se <- ifelse(ry == -1, "---",
                    sprintf("(%.4f)", es_merged$se[i]))

  cs_est <- ifelse(is.na(es_merged$att[i]), "---",
                   sprintf("%.4f", es_merged$att[i]))
  cs_se_val <- ifelse(is.na(es_merged$se.y[i]), "---",
                      sprintf("(%.4f)", es_merged$se.y[i]))

  tab3_lines <- c(tab3_lines,
    sprintf("$t %+d$%s & %s & %s & %s & %s \\\\",
            ry, marker, twfe_est, twfe_se, cs_est, cs_se_val))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Relative year $t = 0$ corresponds to 2022 (effective date of Decree 2-22-159). ",
  "TWFE estimates from \\Cref{eq:did} with cell and year fixed effects; ",
  "reference period is $t - 1$ (2021). ",
  "Callaway--Sant'Anna (2021) dynamic aggregation with never-treated control group. ",
  "Standard errors clustered at the province level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:eventstudy}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_eventstudy.tex"))
cat("Table 3 written.\n")

# =============================================================================
# Table 4: Robustness
# =============================================================================

cat("\n=== Table 4: Robustness ===\n")

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE & N \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Placebo Treatment Years}} \\\\\n",
  sprintf("Placebo: 2019 & %.4f & (%.4f) & %s \\\\\n",
          coef(rob$placebo_2019)["placebo_treat"],
          sqrt(vcov(rob$placebo_2019)["placebo_treat", "placebo_treat"]),
          format(nobs(rob$placebo_2019), big.mark = ",")),
  sprintf("Placebo: 2020 & %.4f & (%.4f) & %s \\\\\n",
          coef(rob$placebo_2020)["placebo_treat_2020"],
          sqrt(vcov(rob$placebo_2020)["placebo_treat_2020", "placebo_treat_2020"]),
          format(nobs(rob$placebo_2020), big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative Samples}} \\\\\n",
  sprintf("Level NL (not transformed) & %.4f & (%.4f) & %s \\\\\n",
          coef(rob$m_level)["treat_post"],
          sqrt(vcov(rob$m_level)["treat_post", "treat_post"]),
          format(nobs(rob$m_level), big.mark = ",")),
  sprintf("Trimmed (excl.\\ top 5\\%%) & %.4f & (%.4f) & %s \\\\\n",
          coef(rob$m_trim)["treat_post"],
          sqrt(vcov(rob$m_trim)["treat_post", "treat_post"]),
          format(nobs(rob$m_trim), big.mark = ",")),
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Heterogeneity}} \\\\\n",
  sprintf("Urban cells (high baseline NL) & %.4f & (%.4f) & %s \\\\\n",
          coef(rob$m_urban)["treat_post"],
          sqrt(vcov(rob$m_urban)["treat_post", "treat_post"]),
          format(nobs(rob$m_urban), big.mark = ",")),
  sprintf("Rural cells (low baseline NL) & %.4f & (%.4f) & %s \\\\\n",
          coef(rob$m_rural)["treat_post"],
          sqrt(vcov(rob$m_rural)["treat_post", "treat_post"]),
          format(nobs(rob$m_rural), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications include cell and year fixed effects. ",
  "Standard errors clustered at the province level. ",
  "Panel A tests for differential trends prior to treatment. ",
  "Panel B varies the sample and outcome transformation. ",
  "Panel C splits by pre-treatment nightlight intensity (median split).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robustness}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_robustness.tex"))
cat("Table 4 written.\n")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================

cat("\n=== Table F1: SDE ===\n")

sd_y <- sde_info$sd_y_pre

# Main outcome: asinh(NL)
beta_twfe <- sde_info$beta_m1
se_twfe <- sde_info$se_m1
sde_twfe <- beta_twfe / sd_y
se_sde_twfe <- se_twfe / sd_y

# C-S ATT
beta_cs <- sde_info$beta_cs
se_cs <- sde_info$se_cs
sde_cs <- beta_cs / sd_y
se_sde_cs <- se_cs / sd_y

# Border sample
beta_bor <- coef(rob$m_border)["treat_post"]
se_bor <- sqrt(vcov(rob$m_border)["treat_post", "treat_post"])
sde_bor <- beta_bor / sd_y
se_sde_bor <- se_bor / sd_y

# Urban
beta_urb <- coef(rob$m_urban)["treat_post"]
se_urb <- sqrt(vcov(rob$m_urban)["treat_post", "treat_post"])
sd_y_urban <- sd(panel$asinh_nl[panel$post == 0 &
  panel$cell_id %in% {
    baseline_nl <- panel %>%
      filter(year < 2022) %>%
      group_by(cell_id) %>%
      summarize(bl = mean(nl_mean, na.rm=TRUE), .groups="drop")
    baseline_nl$cell_id[baseline_nl$bl > median(baseline_nl$bl, na.rm=TRUE)]
  }], na.rm=TRUE)
sde_urb <- beta_urb / sd_y_urban
se_sde_urb <- se_urb / sd_y_urban

# Rural
beta_rur <- coef(rob$m_rural)["treat_post"]
se_rur <- sqrt(vcov(rob$m_rural)["treat_post", "treat_post"])
sd_y_rural <- sd(panel$asinh_nl[panel$post == 0 &
  panel$cell_id %in% {
    baseline_nl <- panel %>%
      filter(year < 2022) %>%
      group_by(cell_id) %>%
      summarize(bl = mean(nl_mean, na.rm=TRUE), .groups="drop")
    baseline_nl$cell_id[baseline_nl$bl <= median(baseline_nl$bl, na.rm=TRUE)]
  }], na.rm=TRUE)
sde_rur <- beta_rur / sd_y_rural
se_sde_rur <- se_rur / sd_y_rural

# Classify
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Morocco. ",
  "\\textbf{Research question:} Does legalizing cannabis cultivation in designated provinces increase ",
  "local economic activity, as measured by satellite nighttime luminosity? ",
  "\\textbf{Policy mechanism:} Law 13-21 (2021) and Decree 2-22-159 (March 2022) restrict legal cannabis ",
  "cultivation to three Rif Mountain provinces (Al Hoceima, Chefchaouen, Taounate), creating permits for ",
  "farmers previously growing illicitly; legal prices are approximately 1/50th of black-market prices. ",
  "\\textbf{Outcome definition:} Annual average nighttime radiance from NASA Black Marble VNP46A4 ",
  "(nW/cm\\textsuperscript{2}/sr), transformed using the inverse hyperbolic sine. ",
  "\\textbf{Treatment:} Binary indicator for grid cells in eligible provinces, interacted with post-2022. ",
  "\\textbf{Data:} NASA Black Marble VNP46A4 annual composites (2014--2023) extracted to ",
  "5km $\\times$ 5km grid cells; HDX/OCHA Morocco province boundaries. ",
  sprintf("N = %s grid-cell-year observations, 1,274 cells, 10 years. ",
          format(nrow(panel), big.mark = ",")),
  "\\textbf{Method:} Two-way fixed effects DiD with cell and year fixed effects; ",
  "standard errors clustered at province level (9 clusters). ",
  "Callaway--Sant'Anna (2021) as robustness. ",
  "\\textbf{Sample:} Grid cells in three eligible and six adjacent ineligible provinces in northern Morocco; ",
  "border sample restricts to cells within 20km of the eligibility boundary. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("TWFE DiD & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_twfe, se_twfe, sd_y, sde_twfe, se_sde_twfe, classify_sde(sde_twfe)),
  sprintf("Callaway--Sant'Anna & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_cs, se_cs, sd_y, sde_cs, se_sde_cs, classify_sde(sde_cs)),
  sprintf("Border sample (20km) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_bor, se_bor, sd_y, sde_bor, se_sde_bor, classify_sde(sde_bor)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("Urban cells & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_urb, se_urb, sd_y_urban, sde_urb, se_sde_urb, classify_sde(sde_urb)),
  sprintf("Rural cells & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_rur, se_rur, sd_y_rural, sde_rur, se_sde_rur, classify_sde(sde_rur)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:sde}",
  "\\end{table}"
)

writeLines(tab_sde, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
