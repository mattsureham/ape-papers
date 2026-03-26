# 05_tables.R — Generate all tables for apep_0974

source("00_packages.R")

panel <- arrow::read_parquet("../data/panel.parquet")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
sde_info <- readRDS("../data/sde_info.rds")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

pre_panel <- panel |> filter(CLAIM_FROM_MONTH < "2021-04")

# Build summary by treatment group
sum_stats <- pre_panel |>
  group_by(Group = ifelse(early_terminator, "Early Terminator", "Late/Control")) |>
  summarize(
    `Mean ED Claims` = sprintf("%.0f", mean(ed_claims, na.rm = TRUE)),
    `Mean PC Claims` = sprintf("%.0f", mean(pc_claims, na.rm = TRUE)),
    `ED Share` = sprintf("%.3f", mean(ed_share, na.rm = TRUE)),
    `SD ED Share` = sprintf("%.3f", sd(ed_share, na.rm = TRUE)),
    `ED High-Acuity Share` = sprintf("%.3f", mean(ed_high_share, na.rm = TRUE)),
    `ED Providers` = sprintf("%.0f", mean(n_ed_providers, na.rm = TRUE)),
    `PC Providers` = sprintf("%.0f", mean(n_pc_providers, na.rm = TRUE)),
    `States` = as.character(n_distinct(state)),
    `State-Months` = as.character(n()),
    .groups = "drop"
  )

# Transpose for LaTeX
sum_t <- t(sum_stats[,-1])
colnames(sum_t) <- sum_stats$Group

tab1_tex <- kableExtra::kbl(sum_t, format = "latex", booktabs = TRUE,
                             caption = "Pre-Treatment Summary Statistics (January 2018--March 2021)") |>
  kableExtra::kable_styling(latex_options = c("hold_position")) |>
  kableExtra::footnote(general = "Monthly Medicaid claims from T-MSIS, geocoded to states via NPPES. ED claims include CPT codes 99281--99285; primary care includes 99213--99215. ED share is ED claims divided by total (ED + PC) claims. High-acuity ED share is the fraction of ED claims coded 99284--99285.",
                        threeparttable = TRUE)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main Results (TWFE and CS-DiD)
# =============================================================================
cat("Generating Table 2: Main Results\n")

# Extract CS-DiD ATT results
cs_results <- data.frame(
  Outcome = c("ED Share", "Log ED Claims", "Log PC Claims",
              "ED High-Acuity Share", "ED Claims/Provider"),
  `CS-DiD ATT` = c(
    sprintf("%.4f", results$agg_simple$overall.att),
    sprintf("%.4f", results$agg_ed$overall.att),
    sprintf("%.4f", results$agg_pc$overall.att),
    sprintf("%.4f", results$agg_acuity$overall.att),
    sprintf("%.1f", results$agg_workload$overall.att)
  ),
  `CS SE` = c(
    sprintf("(%.4f)", results$agg_simple$overall.se),
    sprintf("(%.4f)", results$agg_ed$overall.se),
    sprintf("(%.4f)", results$agg_pc$overall.se),
    sprintf("(%.4f)", results$agg_acuity$overall.se),
    sprintf("(%.1f)", results$agg_workload$overall.se)
  ),
  check.names = FALSE
)

# Add TWFE for comparison
twfe_coefs <- c(
  coef(results$twfe_share)["post_ea"],
  coef(results$twfe_ed)["post_ea"],
  coef(results$twfe_pc)["post_ea"],
  coef(results$twfe_acuity)["post_ea"],
  NA
)
twfe_ses <- c(
  se(results$twfe_share)["post_ea"],
  se(results$twfe_ed)["post_ea"],
  se(results$twfe_pc)["post_ea"],
  se(results$twfe_acuity)["post_ea"],
  NA
)

cs_results$`TWFE` <- ifelse(is.na(twfe_coefs), "---",
                             sprintf("%.4f", twfe_coefs))
cs_results$`TWFE SE` <- ifelse(is.na(twfe_ses), "",
                                sprintf("(%.4f)", twfe_ses))

tab2_tex <- kableExtra::kbl(cs_results, format = "latex", booktabs = TRUE,
                             caption = "Effect of SNAP EA Expiration on Medicaid Utilization Composition",
                             align = c("l", "r", "r", "r", "r")) |>
  kableExtra::kable_styling(latex_options = c("hold_position")) |>
  kableExtra::footnote(general = "Callaway-Sant\\\\textquotesingle Anna (2021) staggered DiD estimates with never-treated control group. TWFE shown for comparison. Treatment: first month state SNAP Emergency Allotments expire. 18 early-terminating states (April 2021--January 2023), 33 late/control states. Standard errors clustered at state level. State and calendar month fixed effects included.",
                        threeparttable = TRUE, escape = FALSE)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Robustness Checks
# =============================================================================
cat("Generating Table 3: Robustness\n")

rob_data <- data.frame(
  Specification = c(
    "Baseline (TWFE)",
    "Wild cluster bootstrap",
    "Excluding COVID peak (Mar--Jun 2020)",
    "State-specific linear trends",
    paste0("Leave-one-out range")
  ),
  Coefficient = c(
    sprintf("%.4f", coef(results$twfe_share)["post_ea"]),
    sprintf("%.4f", coef(results$twfe_share)["post_ea"]),
    sprintf("%.4f", coef(robust$twfe_nocovid)["post_ea"]),
    sprintf("%.4f", coef(robust$twfe_trends)["post_ea"]),
    sprintf("[%.4f, %.4f]", min(robust$loo_results$coef), max(robust$loo_results$coef))
  ),
  SE = c(
    sprintf("(%.4f)", se(results$twfe_share)["post_ea"]),
    sprintf("[%.4f, %.4f]", robust$boot_share$conf_int[1], robust$boot_share$conf_int[2]),
    sprintf("(%.4f)", se(robust$twfe_nocovid)["post_ea"]),
    sprintf("(%.4f)", se(robust$twfe_trends)["post_ea"]),
    ""
  ),
  stringsAsFactors = FALSE
)

tab3_tex <- kableExtra::kbl(rob_data, format = "latex", booktabs = TRUE,
                             caption = "Robustness: ED Share Coefficient Under Alternative Specifications",
                             align = c("l", "r", "r")) |>
  kableExtra::kable_styling(latex_options = c("hold_position")) |>
  kableExtra::footnote(general = "All specifications include state and month FEs. Bootstrap uses Webb weights with 999 replications. COVID peak excludes March--June 2020. Leave-one-out drops each early-terminating state individually.",
                        threeparttable = TRUE)

writeLines(tab3_tex, "../tables/tab3_robustness.tex")

# =============================================================================
# Table 4: Placebo Test
# =============================================================================
cat("Generating Table 4: Placebo\n")

placebo_data <- data.frame(
  Outcome = c("ED Share (main)", "Behavioral Health (placebo)"),
  Coefficient = c(
    sprintf("%.4f", coef(results$twfe_share)["post_ea"]),
    sprintf("%.4f", coef(robust$placebo_bh)["post_ea"])
  ),
  SE = c(
    sprintf("(%.4f)", se(results$twfe_share)["post_ea"]),
    sprintf("(%.4f)", se(robust$placebo_bh)["post_ea"])
  ),
  `p-value` = c(
    sprintf("%.3f", pvalue(results$twfe_share)["post_ea"]),
    sprintf("%.3f", pvalue(robust$placebo_bh)["post_ea"])
  ),
  check.names = FALSE
)

tab4_tex <- kableExtra::kbl(placebo_data, format = "latex", booktabs = TRUE,
                             caption = "Placebo Test: Behavioral Health Utilization",
                             align = c("l", "r", "r", "r")) |>
  kableExtra::kable_styling(latex_options = c("hold_position")) |>
  kableExtra::footnote(general = "Behavioral health claims (CPT/HCPCS codes H0015, H0020, H0004, 90834, 90837) serve as a placebo outcome: SNAP benefit reductions should not directly affect mental health service utilization in the short run. Same specification as main results.",
                        threeparttable = TRUE)

writeLines(tab4_tex, "../tables/tab4_placebo.tex")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# =============================================================================
cat("Generating Table F1: SDE Appendix\n")

# SDE = beta / SD(Y) for binary treatment
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

# Panel A: Pooled
sde_pooled <- data.frame(
  Outcome = c("ED Share", "Log ED Claims", "Log PC Claims",
              "ED High-Acuity Share"),
  Beta = c(results$agg_simple$overall.att,
           results$agg_ed$overall.att,
           results$agg_pc$overall.att,
           results$agg_acuity$overall.att),
  SE = c(results$agg_simple$overall.se,
         results$agg_ed$overall.se,
         results$agg_pc$overall.se,
         results$agg_acuity$overall.se),
  SD_Y = c(sde_info$sd_ed_share,
           sde_info$sd_log_ed,
           sde_info$sd_log_pc,
           sde_info$sd_ed_high_share)
)

sde_pooled <- sde_pooled |>
  mutate(
    SDE = Beta / SD_Y,
    SE_SDE = SE / SD_Y,
    Classification = classify_sde(SDE)
  )

# Panel B: Heterogeneous (by state Medicaid expansion status)
# Split: Medicaid expansion states vs non-expansion states
expansion_states <- c("AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "HI",
                       "IL", "IN", "IA", "KY", "LA", "MD", "MA", "MI", "MN",
                       "MT", "NV", "NH", "NJ", "NM", "NY", "ND", "OH", "OR",
                       "PA", "RI", "VT", "VA", "WA", "WV")

panel_exp <- panel |> mutate(medicaid_expansion = state %in% expansion_states)

# ED share by expansion status
twfe_exp <- feols(ed_share ~ post_ea | state + year_month,
                   data = filter(panel, state %in% expansion_states),
                   cluster = ~state)
twfe_noexp <- feols(ed_share ~ post_ea | state + year_month,
                     data = filter(panel, !state %in% expansion_states),
                     cluster = ~state)

pre_exp <- panel |> filter(CLAIM_FROM_MONTH < "2021-04", state %in% expansion_states)
pre_noexp <- panel |> filter(CLAIM_FROM_MONTH < "2021-04", !state %in% expansion_states)

sde_hetero <- data.frame(
  Outcome = c("ED Share (Expansion States)", "ED Share (Non-Expansion States)"),
  Beta = c(coef(twfe_exp)["post_ea"], coef(twfe_noexp)["post_ea"]),
  SE = c(se(twfe_exp)["post_ea"], se(twfe_noexp)["post_ea"]),
  SD_Y = c(sd(pre_exp$ed_share, na.rm = TRUE), sd(pre_noexp$ed_share, na.rm = TRUE))
)

sde_hetero <- sde_hetero |>
  mutate(
    SDE = Beta / SD_Y,
    SE_SDE = SE / SD_Y,
    Classification = classify_sde(SDE)
  )

# Format for LaTeX
format_sde_row <- function(d) {
  sprintf("%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s",
          d$Outcome, d$Beta, d$SE, d$SD_Y, d$SDE, d$SE_SDE, d$Classification)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the expiration of SNAP Emergency Allotments shift Medicaid utilization from primary care to emergency departments? ",
  "\\textbf{Policy mechanism:} SNAP EA provided \\$95--\\$250/month in additional food benefits during COVID-19; ",
  "18 states terminated these allotments between April 2021 and January 2023, creating sudden income shocks ",
  "that may degrade dietary quality and increase acute health episodes requiring emergency care. ",
  "\\textbf{Outcome definition:} ED share is the ratio of emergency department E\\&M claims (CPT 99281--99285) ",
  "to total emergency plus primary care claims (CPT 99213--99215) per state-month in Medicaid. ",
  "\\textbf{Treatment:} Binary indicator equal to one after a state's SNAP EA expires. ",
  "\\textbf{Data:} CMS T-MSIS Medicaid claims, January 2018--December 2024, state-month panel, ",
  "51 units (50 states + DC) $\\times$ 84 months. ",
  "\\textbf{Method:} Callaway-Sant'Anna (2021) staggered DiD with never-treated control group; ",
  "standard errors clustered at state level. ",
  "\\textbf{Sample:} All Medicaid ED and primary care E\\&M claims; 18 early-terminating states as treated, ",
  "33 states retaining EA through February 2023 as controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table manually for proper two-panel structure
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
  "\\addlinespace\n"
)

for (i in 1:nrow(sde_pooled)) {
  sde_tex <- paste0(sde_tex, format_sde_row(sde_pooled[i,]), " \\\\\n")
}

sde_tex <- paste0(sde_tex,
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Medicaid Expansion Status)}} \\\\\n",
  "\\addlinespace\n"
)

for (i in 1:nrow(sde_hetero)) {
  sde_tex <- paste0(sde_tex, format_sde_row(sde_hetero[i,]), " \\\\\n")
}

sde_tex <- paste0(sde_tex,
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
