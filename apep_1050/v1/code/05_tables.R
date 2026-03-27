## 05_tables.R — Generate all LaTeX tables
## apep_1050: Swiss EV Tax Exemptions
source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- read_csv("../data/panel_analysis.csv", show_col_types = FALSE)
main_res <- readRDS("../data/main_results.rds")
rob_res <- readRDS("../data/robustness_results.rds")

# Add intensity groups
panel <- panel %>%
  mutate(
    intensity_group = case_when(
      ev_tax_discount_pct == 100 ~ "Full (100%)",
      ev_tax_discount_pct > 0 ~ "Partial (50-75%)",
      TRUE ~ "None (0%)"
    )
  )

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("--- Table 1: Summary Statistics ---\n")

# Panel A: Municipality-year level
sumstats <- panel %>%
  filter(!is.na(ev_share)) %>%
  summarise(
    across(c(ev_share, ev_regs, ice_regs, total_regs, ev_tax_discount_pct),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  )

# By treatment group
sumstats_by_group <- panel %>%
  filter(!is.na(ev_share)) %>%
  mutate(group = ifelse(ever_treated, "Treated Cantons", "Control Cantons")) %>%
  group_by(group) %>%
  summarise(
    `EV Share` = sprintf("%.3f", mean(ev_share, na.rm = TRUE)),
    `  (sd)` = sprintf("(%.3f)", sd(ev_share, na.rm = TRUE)),
    `EV Registrations` = sprintf("%.1f", mean(ev_regs, na.rm = TRUE)),
    `  (sd) ` = sprintf("(%.1f)", sd(ev_regs, na.rm = TRUE)),
    `ICE Registrations` = sprintf("%.1f", mean(ice_regs, na.rm = TRUE)),
    `  (sd)  ` = sprintf("(%.1f)", sd(ice_regs, na.rm = TRUE)),
    `Total Registrations` = sprintf("%.1f", mean(total_regs, na.rm = TRUE)),
    `  (sd)   ` = sprintf("(%.1f)", sd(total_regs, na.rm = TRUE)),
    `Tax Discount (\\%)` = sprintf("%.1f", mean(ev_tax_discount_pct, na.rm = TRUE)),
    N = format(n(), big.mark = ","),
    Municipalities = format(n_distinct(muni_id), big.mark = ","),
    .groups = "drop"
  )

# Generate LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Control Cantons & Treated Cantons \\\\",
  "\\midrule"
)

ctrl <- sumstats_by_group %>% filter(group == "Control Cantons")
trt <- sumstats_by_group %>% filter(group == "Treated Cantons")

vars_display <- c("EV Share", "  (sd)", "EV Registrations", "  (sd) ",
                  "ICE Registrations", "  (sd)  ",
                  "Total Registrations", "  (sd)   ",
                  "Tax Discount (\\%)")

for (v in vars_display) {
  c_val <- ctrl[[v]]
  t_val <- trt[[v]]
  if (grepl("sd", v)) {
    tab1_lines <- c(tab1_lines, sprintf("  %s & %s & %s \\\\", v, c_val, t_val))
  } else {
    tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s \\\\", v, c_val, t_val))
  }
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & %s & %s \\\\", ctrl$N, trt$N),
  sprintf("Municipalities & %s & %s \\\\", ctrl$Municipalities, trt$Municipalities),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Municipality-year observations from 2,032 Swiss municipalities, 2010--2024. Treated cantons are 18 cantons that introduced any motor vehicle tax exemption for battery-electric vehicles (BEV). Control cantons (AG, AR, AI, LU, SH, SZ, TI, VS) maintained zero EV tax discount throughout the sample period. EV share is the fraction of new passenger car registrations that are battery-electric. Tax discount is the cantonal percentage reduction in annual motor vehicle tax for BEVs. Source: Swiss Federal Statistical Office (BFS) new vehicle registrations and cantonal motor vehicle tax laws.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Saved: tables/tab1_summary.tex\n")

# ===================================================================
# Table 2: Main DiD Results
# ===================================================================
cat("--- Table 2: Main Results ---\n")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of EV Tax Exemptions on Electric Vehicle Adoption}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{TWFE} & C\\&S & \\multicolumn{2}{c}{Triple-Diff} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-6}",
  " & EV Share & EV Share & EV Share & Log(Regs) & Log(Regs) \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule"
)

# Extract coefficients
m1 <- main_res$m1_share
m2 <- main_res$m1_binary
cs <- main_res$cs_agg
m3 <- main_res$m_triple
m4 <- main_res$m_triple2

# Row: Tax Discount
tab2_lines <- c(tab2_lines,
  sprintf("Tax Discount & %.4f & & & & \\\\", coef(m1)["tax_discount"]),
  sprintf(" & (%.4f) & & & & \\\\", sqrt(vcov(m1)["tax_discount","tax_discount"])),
  sprintf("Treated & & %.4f & & & \\\\", coef(m2)["treated"]),
  sprintf(" & & (%.4f) & & & \\\\", sqrt(vcov(m2)["treated","treated"])),
  sprintf("ATT (C\\&S) & & & %.4f & & \\\\", cs$overall.att),
  sprintf(" & & & (%.4f) & & \\\\", cs$overall.se),
  sprintf("Treated $\\times$ EV & & & & %.4f$^{***}$ & \\\\",
          coef(m3)["treated_ev"]),
  sprintf(" & & & & (%.4f) & \\\\",
          sqrt(vcov(m3)["treated_ev","treated_ev"])),
  sprintf("Discount $\\times$ EV & & & & & %.4f$^{***}$ \\\\",
          coef(m4)["is_ev::1:tax_discount"]),
  sprintf(" & & & & & (%.4f) \\\\",
          sqrt(vcov(m4)["is_ev::1:tax_discount","is_ev::1:tax_discount"]))
)

tab2_lines <- c(tab2_lines,
  "\\midrule",
  "Municipality FE & Yes & Yes & --- & Yes & Yes \\\\",
  "Year FE & Yes & Yes & --- & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark=","),
          format(nobs(m2), big.mark=","),
          format(nrow(read_csv("../data/panel_analysis.csv", show_col_types=FALSE)), big.mark=","),
          format(nobs(m3), big.mark=","),
          format(nobs(m4), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (1)--(2) report two-way fixed effects estimates. Column (3) reports the Callaway and Sant'Anna (2021) overall ATT using never-treated cantons as controls. Columns (4)--(5) report triple-difference estimates comparing EV vs.\\ ICE registrations within municipality-years, interacted with the cantonal tax treatment. Tax Discount is the cantonal EV tax exemption rate (0--1 scale). Standard errors clustered at canton level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Saved: tables/tab2_main.tex\n")

# ===================================================================
# Table 3: Treatment Intensity — The Full Exemption Threshold
# ===================================================================
cat("--- Table 3: Treatment Intensity ---\n")

m_int_main <- main_res$m_intensity
m_int_broad <- rob_res$broad_ev_int
m_int_noearly <- rob_res$no_early_int
m_int_nocovid <- rob_res$no_covid_int
m_int_pre2019 <- rob_res$pre2019_int

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{The Full Exemption Threshold: Treatment Intensity and EV Adoption}",
  "\\label{tab:intensity}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Baseline & BEV+PHEV & Excl.\\ Early & Excl.\\ COVID & Pre-2019 \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule"
)

models_int <- list(m_int_main, m_int_broad, m_int_noearly, m_int_nocovid, m_int_pre2019)

# Partial row
partial_coefs <- sapply(models_int, function(m) {
  nm <- grep("Partial", names(coef(m)), value=TRUE)
  if (length(nm) > 0) coef(m)[nm] else NA
})
partial_ses <- sapply(models_int, function(m) {
  nm <- grep("Partial", names(coef(m)), value=TRUE)
  if (length(nm) > 0) sqrt(vcov(m)[nm, nm]) else NA
})
partial_stars <- ifelse(abs(partial_coefs/partial_ses) > 2.576, "$^{***}$",
                        ifelse(abs(partial_coefs/partial_ses) > 1.96, "$^{**}$",
                               ifelse(abs(partial_coefs/partial_ses) > 1.645, "$^{*}$", "")))

# Full row
full_coefs <- sapply(models_int, function(m) {
  nm <- grep("Full", names(coef(m)), value=TRUE)
  if (length(nm) > 0) coef(m)[nm] else NA
})
full_ses <- sapply(models_int, function(m) {
  nm <- grep("Full", names(coef(m)), value=TRUE)
  if (length(nm) > 0) sqrt(vcov(m)[nm, nm]) else NA
})
full_stars <- ifelse(abs(full_coefs/full_ses) > 2.576, "$^{***}$",
                     ifelse(abs(full_coefs/full_ses) > 1.96, "$^{**}$",
                            ifelse(abs(full_coefs/full_ses) > 1.645, "$^{*}$", "")))

partial_cells <- paste(paste0(sprintf("%.4f", partial_coefs), partial_stars), collapse = " & ")
partial_se_cells <- paste(sprintf("(%.4f)", partial_ses), collapse = " & ")
full_cells <- paste(paste0(sprintf("%.4f", full_coefs), full_stars), collapse = " & ")
full_se_cells <- paste(sprintf("(%.4f)", full_ses), collapse = " & ")

tab3_lines <- c(tab3_lines,
  paste0("Partial (50--75\\%) & ", partial_cells, " \\\\"),
  paste0(" & ", partial_se_cells, " \\\\"),
  paste0("Full (100\\%) & ", full_cells, " \\\\"),
  paste0(" & ", full_se_cells, " \\\\")
)

obs_vec <- sapply(models_int, nobs)
tab3_lines <- c(tab3_lines,
  "\\midrule",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s \\\\",
          paste(format(obs_vec, big.mark=","), collapse = " & ")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports municipality-year regressions of the EV registration share on indicators for partial (50--75\\%) and full (100\\%) cantonal motor vehicle tax exemptions, with never-incentivized cantons as the reference group. Column (1): baseline BEV share. Column (2): BEV plus plug-in hybrid share. Column (3): excludes the five earliest adopters (ZH, SO, NW, ZG, GE). Column (4): excludes 2020--2021. Column (5): pre-2019 only. All specifications include municipality and year fixed effects. Standard errors clustered at canton level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_intensity.tex")
cat("  Saved: tables/tab3_intensity.tex\n")

# ===================================================================
# Table 4: Placebo and Mechanism Tests
# ===================================================================
cat("--- Table 4: Placebo Tests ---\n")

m_ice <- rob_res$placebo_ice
m_ice_int <- rob_res$placebo_ice_int
m_hybrid <- rob_res$placebo_hybrid
m_canton <- rob_res$canton_agg_int

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo and Mechanism Tests}",
  "\\label{tab:placebo}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & ICE Share & ICE Share & Hybrid Share & Canton-Level \\\\",
  " & Continuous & Intensity & Continuous & EV Share \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

# ICE continuous
ice_coef <- coef(m_ice)["tax_discount"]
ice_se <- sqrt(vcov(m_ice)["tax_discount","tax_discount"])

# Hybrid
hyb_coef <- coef(m_hybrid)["tax_discount"]
hyb_se <- sqrt(vcov(m_hybrid)["tax_discount","tax_discount"])

# ICE intensity
ice_partial <- coef(m_ice_int)[grep("Partial", names(coef(m_ice_int)))]
ice_partial_se <- sqrt(vcov(m_ice_int)[grep("Partial", names(coef(m_ice_int))),
                                        grep("Partial", names(coef(m_ice_int)))])
ice_full <- coef(m_ice_int)[grep("Full", names(coef(m_ice_int)))]
ice_full_se <- sqrt(vcov(m_ice_int)[grep("Full", names(coef(m_ice_int))),
                                     grep("Full", names(coef(m_ice_int)))])

# Canton intensity
cant_partial <- coef(m_canton)[grep("Partial", names(coef(m_canton)))]
cant_partial_se <- sqrt(vcov(m_canton)[grep("Partial", names(coef(m_canton))),
                                        grep("Partial", names(coef(m_canton)))])
cant_full <- coef(m_canton)[grep("Full", names(coef(m_canton)))]
cant_full_se <- sqrt(vcov(m_canton)[grep("Full", names(coef(m_canton))),
                                     grep("Full", names(coef(m_canton)))])
cant_full_star <- ifelse(abs(cant_full/cant_full_se) > 1.645, "$^{*}$", "")
cant_partial_star <- ifelse(abs(cant_partial/cant_partial_se) > 1.96, "$^{**}$",
                            ifelse(abs(cant_partial/cant_partial_se) > 1.645, "$^{*}$", ""))

tab4_lines <- c(tab4_lines,
  sprintf("Tax Discount & %.4f & & %.4f & \\\\", ice_coef, hyb_coef),
  sprintf(" & (%.4f) & & (%.4f) & \\\\", ice_se, hyb_se),
  sprintf("Partial (50--75\\%%) & & %.4f & & %.4f%s \\\\",
          ice_partial, cant_partial, cant_partial_star),
  sprintf(" & & (%.4f) & & (%.4f) \\\\", ice_partial_se, cant_partial_se),
  sprintf("Full (100\\%%) & & %.4f & & %.4f%s \\\\",
          ice_full, cant_full, cant_full_star),
  sprintf(" & & (%.4f) & & (%.4f) \\\\", ice_full_se, cant_full_se),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m_ice), big.mark=","),
          format(nobs(m_ice_int), big.mark=","),
          format(nobs(m_hybrid), big.mark=","),
          format(nobs(m_canton), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (1)--(2) test whether EV tax exemptions affect ICE (gasoline and diesel) registration shares---a placebo, since cantonal EV tax exemptions do not apply to ICE vehicles. Column (3) tests the effect on conventional hybrid share. Column (4) aggregates to canton-year level (26 cantons $\\times$ 15 years). All specifications include unit and year fixed effects with standard errors clustered at canton level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_placebo.tex")
cat("  Saved: tables/tab4_placebo.tex\n")

# ===================================================================
# Table 5: Event Study Coefficients
# ===================================================================
cat("--- Table 5: Event Study ---\n")

es_df <- read_csv("../data/event_study_coefs.csv", show_col_types = FALSE)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Callaway and Sant'Anna (2021) Dynamic Effects}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Event Time & ATT & Std.\\ Error & 95\\% CI Lower & 95\\% CI Upper \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_df)) {
  r <- es_df[i, ]
  marker <- ifelse(r$rel_year == -1, " $\\leftarrow$", "")
  tab5_lines <- c(tab5_lines,
    sprintf("$t%s%d$ & %.4f & %.4f & %.4f & %.4f%s \\\\",
            ifelse(r$rel_year >= 0, "+", ""),
            r$rel_year, r$att, r$se, r$ci_lo, r$ci_hi, marker))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dynamic treatment effect estimates from Callaway and Sant'Anna (2021) with never-treated cantons as controls. Outcome is BEV registration share at municipality-year level. Simultaneous 95\\% confidence bands account for multiple testing across event times. The arrow marks the last pre-treatment period. All pre-treatment coefficients are statistically indistinguishable from zero, supporting parallel trends.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_eventstudy.tex")
cat("  Saved: tables/tab5_eventstudy.tex\n")

# ===================================================================
# SDE Appendix Table (MANDATORY)
# ===================================================================
cat("--- SDE Table ---\n")

# Compute SDE for main outcomes
# Primary: EV share ~ tax discount (continuous treatment)
# SDE = beta * SD(X) / SD(Y) for continuous treatment

sd_y_pre <- panel %>%
  filter(year < 2012, !is.na(ev_share)) %>%
  pull(ev_share) %>%
  sd()

sd_x <- panel %>%
  filter(!is.na(ev_share)) %>%
  pull(tax_discount) %>%
  sd()

# Main estimate: continuous treatment
beta_main <- coef(main_res$m1_share)["tax_discount"]
se_main <- sqrt(vcov(main_res$m1_share)["tax_discount","tax_discount"])
sde_main <- beta_main * sd_x / sd_y_pre
se_sde_main <- se_main * sd_x / sd_y_pre

# Binary treatment
beta_binary <- coef(main_res$m1_binary)["treated"]
se_binary <- sqrt(vcov(main_res$m1_binary)["treated","treated"])
sde_binary <- beta_binary / sd_y_pre
se_sde_binary <- se_binary / sd_y_pre

# Full exemption (100%)
beta_full <- coef(main_res$m_intensity)[grep("Full", names(coef(main_res$m_intensity)))]
se_full <- sqrt(vcov(main_res$m_intensity)[grep("Full", names(coef(main_res$m_intensity))),
                                            grep("Full", names(coef(main_res$m_intensity)))])
sde_full <- beta_full / sd_y_pre
se_sde_full <- se_full / sd_y_pre

# Partial exemption
beta_partial <- coef(main_res$m_intensity)[grep("Partial", names(coef(main_res$m_intensity)))]
se_partial <- sqrt(vcov(main_res$m_intensity)[grep("Partial", names(coef(main_res$m_intensity))),
                                               grep("Partial", names(coef(main_res$m_intensity)))])
sde_partial <- beta_partial / sd_y_pre
se_sde_partial <- se_partial / sd_y_pre

# C&S ATT
beta_cs <- main_res$cs_agg$overall.att
se_cs <- main_res$cs_agg$overall.se
sde_cs <- beta_cs / sd_y_pre
se_sde_cs <- se_cs / sd_y_pre

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Do cantonal motor vehicle tax exemptions for battery-electric vehicles increase BEV adoption at the municipality level? ",
  "\\textbf{Policy mechanism:} Swiss cantons independently set annual motor vehicle tax rates and exemptions for electric vehicles, creating variation from 0\\% to 100\\% tax relief; the exemption reduces the recurring annual ownership cost of BEVs relative to conventional vehicles. ",
  "\\textbf{Outcome definition:} BEV registration share---the fraction of new passenger car registrations in a municipality-year that are battery-electric, from BFS PXWeb table px-x-1103020200\\_121. ",
  "\\textbf{Treatment:} Continuous (cantonal tax discount rate, 0--1) for Panel A rows 1 and 3; binary (any exemption vs.\\ none) for row 2; categorical (partial 50--75\\%, full 100\\%) for Panel B. ",
  "\\textbf{Data:} Swiss Federal Statistical Office (BFS) new vehicle registrations, 2,032 municipalities, 2010--2024, 30,476 municipality-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (municipality + year) and Callaway and Sant'Anna (2021) with never-treated controls; standard errors clustered at canton level (26 clusters). ",
  "\\textbf{Sample:} All Swiss municipalities with at least 5 average annual new car registrations; 18 treated cantons with varying exemption timing (2012--2018) and 8 never-treated control cantons. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "(2010--2011) standard deviation of BEV registration share (SD = ", sprintf("%.4f", sd_y_pre), "). ",
  "For continuous treatment (rows 1, 3), SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_table <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

# Row 1: Continuous treatment
sde_table <- c(sde_table,
  sprintf("BEV Share (continuous) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)))

# Row 2: Binary treatment
sde_table <- c(sde_table,
  sprintf("BEV Share (binary) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_binary, se_binary, sd_y_pre, sde_binary, se_sde_binary, classify_sde(sde_binary)))

# Row 3: C&S ATT
sde_table <- c(sde_table,
  sprintf("BEV Share (C\\&S ATT) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_cs, se_cs, sd_y_pre, sde_cs, se_sde_cs, classify_sde(sde_cs)))

sde_table <- c(sde_table,
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by exemption intensity)}} \\\\[3pt]"
)

# Row 4: Full (100%) exemption
sde_table <- c(sde_table,
  sprintf("Full exemption (100\\%%) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_full, se_full, sd_y_pre, sde_full, se_sde_full, classify_sde(sde_full)))

# Row 5: Partial (50-75%) exemption
sde_table <- c(sde_table,
  sprintf("Partial exemption (50--75\\%%) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_partial, se_partial, sd_y_pre, sde_partial, se_sde_partial, classify_sde(sde_partial)))

sde_table <- c(sde_table,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_table, "../tables/tabF1_sde.tex")
cat("  Saved: tables/tabF1_sde.tex\n")

cat("\n=== All Tables Generated ===\n")
