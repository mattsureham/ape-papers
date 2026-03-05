## ==========================================================================
## 06_tables.R — All Tables for Constitutional Carry Paper
## ==========================================================================

source("00_packages.R")
data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

## ==========================================================================
## LOAD DATA
## ==========================================================================

panel_a <- fread(file.path(data_dir, "panel_a_suicide.csv"))
panel_b <- fread(file.path(data_dir, "panel_b_firearm.csv"))
panel_c <- fread(file.path(data_dir, "panel_c_nics.csv"))
state_treat <- fread(file.path(data_dir, "state_treatment.csv"))
twfe_data <- fread(file.path(data_dir, "twfe_results.csv"))
cs_data <- fread(file.path(data_dir, "cs_results.csv"))
loo_data <- fread(file.path(data_dir, "leave_one_out.csv"))
welfare_data <- fread(file.path(data_dir, "welfare_calculation.csv"))

panel_a[, state_id := as.integer(as.factor(state))]
panel_b[, state_id := as.integer(as.factor(state))]
panel_c[, state_id := as.integer(as.factor(state))]

## ==========================================================================
## TABLE 1: Summary Statistics
## ==========================================================================

cat("=== Table 1: Summary Statistics ===\n")

# Panel A
stats_a <- panel_a[, .(
  Mean = c(mean(suicide_rate, na.rm = TRUE),
           mean(uninj_rate, na.rm = TRUE),
           mean(heart_rate, na.rm = TRUE),
           mean(cancer_rate, na.rm = TRUE),
           mean(population, na.rm = TRUE),
           mean(poverty_rate, na.rm = TRUE),
           mean(pct_black, na.rm = TRUE)),
  SD = c(sd(suicide_rate, na.rm = TRUE),
         sd(uninj_rate, na.rm = TRUE),
         sd(heart_rate, na.rm = TRUE),
         sd(cancer_rate, na.rm = TRUE),
         sd(population, na.rm = TRUE),
         sd(poverty_rate, na.rm = TRUE),
         sd(pct_black, na.rm = TRUE)),
  Variable = c("Suicide rate (per 100K)", "Unintentional injury rate",
                "Heart disease rate", "Cancer rate",
                "Population", "Poverty rate (%)",
                "Percent Black (%)")
)]

# Panel B
stats_b <- panel_b[, .(
  Mean = c(mean(rate_fa_deaths, na.rm = TRUE),
           mean(rate_fa_homicide, na.rm = TRUE),
           mean(rate_fa_suicide, na.rm = TRUE),
           mean(rate_all_homicide, na.rm = TRUE),
           mean(rate_all_suicide, na.rm = TRUE),
           mean(nf_homicide_rate, na.rm = TRUE),
           mean(nf_suicide_rate, na.rm = TRUE)),
  SD = c(sd(rate_fa_deaths, na.rm = TRUE),
         sd(rate_fa_homicide, na.rm = TRUE),
         sd(rate_fa_suicide, na.rm = TRUE),
         sd(rate_all_homicide, na.rm = TRUE),
         sd(rate_all_suicide, na.rm = TRUE),
         sd(nf_homicide_rate, na.rm = TRUE),
         sd(nf_suicide_rate, na.rm = TRUE)),
  Variable = c("Firearm death rate", "Firearm homicide rate",
                "Firearm suicide rate", "All-cause homicide rate",
                "All-cause suicide rate",
                "Non-firearm homicide rate", "Non-firearm suicide rate")
)]

# Panel C
stats_c <- panel_c[, .(
  Mean = c(mean(nics_pc, na.rm = TRUE),
           mean(nics_total, na.rm = TRUE),
           mean(population, na.rm = TRUE)),
  SD = c(sd(nics_pc, na.rm = TRUE),
         sd(nics_total, na.rm = TRUE),
         sd(population, na.rm = TRUE)),
  Variable = c("NICS checks per capita",
                "NICS total checks",
                "Population")
)]

stats_all <- rbind(
  data.table(Panel = "A: 1999-2017", stats_a),
  data.table(Panel = "B: 2019-2024", stats_b),
  data.table(Panel = "C: 2000-2023", stats_c)
)

stats_all[, Mean := round(Mean, 2)]
stats_all[, SD := round(SD, 2)]
stats_display <- stats_all[, .(Variable, Mean, SD)]

tab1_tex <- kbl(stats_display, format = "latex", booktabs = TRUE,
                caption = "Summary Statistics",
                label = "summary",
                col.names = c("Variable", "Mean", "SD")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  pack_rows("Panel A: Suicide \\& Placebo (1999-2017)", 1, 7, escape = FALSE) %>%
  pack_rows("Panel B: Firearm-Specific (2019-2024)", 8, 14, escape = FALSE) %>%
  pack_rows("Panel C: NICS Background Checks (2000-2023)", 15, 17, escape = FALSE)

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))

## ==========================================================================
## TABLE 2: Treatment Timing
## ==========================================================================

cat("=== Table 2: Treatment Timing ===\n")

treat_tab <- state_treat[first_treat > 0][order(first_treat)]
treat_tab[, n_states := .N, by = first_treat]

# Group by year
treat_by_year <- treat_tab[, .(States = paste(state, collapse = ", ")),
                            by = .(Year = first_treat)]

tab2_tex <- kbl(treat_by_year, format = "latex", booktabs = TRUE,
                caption = "Constitutional Carry Adoption Timing",
                label = "timing",
                col.names = c("Year", "States")) %>%
  kable_styling(latex_options = c("hold_position"))

writeLines(tab2_tex, file.path(tab_dir, "tab2_timing.tex"))

## ==========================================================================
## TABLE 3: Main Results (TWFE + CS-DiD + Sun-Abraham)
## ==========================================================================

cat("=== Table 3: Main Results ===\n")

# Re-run key regressions for proper etable output
twfe_a1 <- feols(suicide_rate ~ treated | state_id + year,
                 data = panel_a, cluster = ~state_id)
twfe_a2 <- feols(suicide_rate ~ treated + poverty_rate + pct_black + log_pop +
                   median_income | state_id + year,
                 data = panel_a, cluster = ~state_id)
sa_a <- feols(suicide_rate ~ sunab(first_treat, year) | state_id + year,
              data = panel_a[first_treat != 0 | ever_treated == FALSE],
              cluster = ~state_id)

twfe_b_fad <- feols(rate_fa_deaths ~ treated | state_id + year,
                    data = panel_b, cluster = ~state_id)
twfe_b_fah <- feols(rate_fa_homicide ~ treated | state_id + year,
                    data = panel_b, cluster = ~state_id)
twfe_b_fas <- feols(rate_fa_suicide ~ treated | state_id + year,
                    data = panel_b, cluster = ~state_id)

# Helper: significance stars from model p-value
pv_star <- function(mod) {
  p <- fixest::pvalue(mod)
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Panel A table — manual construction to avoid Sun-Abraham coefficient dump
sa_att <- summary(sa_a, agg = "ATT")$coeftable
cs_att_a <- tryCatch({
  cs_obj <- att_gt(yname = "suicide_rate", tname = "year", idname = "state_id",
                   gname = "first_treat", data = as.data.frame(panel_a),
                   control_group = "nevertreated", anticipation = 0,
                   base_period = "universal", clustervars = "state_id",
                   print_details = FALSE)
  aggte(cs_obj, type = "simple")
}, error = function(e) NULL)

tab3a_manual <- data.table(
  Specification = c("Constitutional Carry", "", "Covariates", "Observations",
                    "Within $R^2$", "States", "Years"),
  `(1) TWFE` = c(sprintf("%.3f%s", coef(twfe_a1), pv_star(twfe_a1)),
                  sprintf("(%.3f)", se(twfe_a1)),
                  "No", as.character(nobs(twfe_a1)),
                  sprintf("%.3f", r2(twfe_a1, "wr2")),
                  "49", "19"),
  `(2) TWFE + Cov` = {
    p2 <- fixest::pvalue(twfe_a2)["treated"]
    s2 <- if (p2 < 0.01) "***" else if (p2 < 0.05) "**" else if (p2 < 0.10) "*" else ""
    c(sprintf("%.3f%s", coef(twfe_a2)["treated"], s2),
      sprintf("(%.3f)", se(twfe_a2)["treated"]),
      "Yes", as.character(nobs(twfe_a2)),
      sprintf("%.3f", r2(twfe_a2, "wr2")),
      "49", "18")
  },
  `(3) Sun-Abraham` = {
    sa_p <- sa_att[1, 4]
    sa_s <- if (sa_p < 0.01) "***" else if (sa_p < 0.05) "**" else if (sa_p < 0.10) "*" else ""
    c(sprintf("%.3f%s", sa_att[1, 1], sa_s),
      sprintf("(%.3f)", sa_att[1, 2]),
      "No", as.character(nobs(sa_a)),
      sprintf("%.3f", r2(sa_a, "wr2")),
      "49", "19")
  },
  `(4) CS-DiD` = {
    # Try live computation; fall back to saved CSV
    cs_att_val <- cs_se_val <- NA_real_
    if (!is.null(cs_att_a)) {
      cs_att_val <- cs_att_a$overall.att
      cs_se_val <- cs_att_a$overall.se
    } else {
      cs_saved <- fread(file.path(data_dir, "cs_results.csv"))
      cs_row <- cs_saved[panel == "A" & outcome == "Suicide Rate"]
      if (nrow(cs_row) > 0) {
        cs_att_val <- cs_row$coef[1]
        cs_se_val <- cs_row$se[1]
      }
    }
    c(if (!is.na(cs_att_val)) sprintf("%.3f", cs_att_val) else "---",
      if (!is.na(cs_se_val)) sprintf("(%.3f)", cs_se_val) else "",
      "No", as.character(nobs(twfe_a1)), "N/A", "49", "19")
  }
)

tab3a_tex <- kbl(tab3a_manual, format = "latex", booktabs = TRUE, escape = FALSE,
                 caption = "Effect of Constitutional Carry on Suicide Rate (Panel A: 1999--2017)",
                 label = "main_panela",
                 align = c("l", "c", "c", "c", "c")) %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = "Dependent variable: age-adjusted suicide rate per 100,000. All specifications include state and year fixed effects with 49 units (48 states plus DC). The treatment variable identifies the 10 states adopting constitutional carry within the 1999--2017 panel window; the remaining 15 eventually-treated states (adopting 2019--2023) serve as not-yet-treated controls. Within $R^2$ is not defined for the CS-DiD doubly-robust estimator. Standard errors clustered by state in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab3a_tex, file.path(tab_dir, "tab3a_main_panela.tex"))

# Panel B table — manual construction
twfe_b_allh <- feols(rate_all_homicide ~ treated | state_id + year,
                     data = panel_b, cluster = ~state_id)
twfe_b_alls <- feols(rate_all_suicide ~ treated | state_id + year,
                     data = panel_b, cluster = ~state_id)

make_cell <- function(mod, stars = "") {
  c(paste0(sprintf("%.3f", coef(mod)), stars),
    sprintf("(%.3f)", se(mod)))
}

make_col4 <- function(mod) {
  c(make_cell(mod, pv_star(mod)),
    as.character(nobs(mod)),
    sprintf("%.3f", r2(mod, "wr2")))
}

tab3b_manual <- data.table(
  Specification = c("Constitutional Carry", "", "Observations", "Within $R^2$"),
  `(1) FA Deaths` = make_col4(twfe_b_fad),
  `(2) FA Homicide` = make_col4(twfe_b_fah),
  `(3) FA Suicide` = make_col4(twfe_b_fas),
  `(4) All Homicide` = make_col4(twfe_b_allh),
  `(5) All Suicide` = make_col4(twfe_b_alls)
)

tab3b_tex <- kbl(tab3b_manual, format = "latex", booktabs = TRUE, escape = FALSE,
                 caption = "Effect of Constitutional Carry on Mortality Outcomes (Panel B: 2019--2024)",
                 label = "main_panelb",
                 align = c("l", "c", "c", "c", "c", "c")) %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = "Dependent variable: age-adjusted rate per 100,000. FA = Firearm. All specifications include state and year fixed effects with 49 units (48 states plus DC) and state-clustered standard errors. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab3b_tex, file.path(tab_dir, "tab3b_main_panelb.tex"))

## ==========================================================================
## TABLE 4: Placebo Outcomes
## ==========================================================================

cat("=== Table 4: Placebo Outcomes ===\n")

twfe_uninj <- feols(uninj_rate ~ treated | state_id + year,
                    data = panel_a, cluster = ~state_id)
twfe_heart <- feols(heart_rate ~ treated | state_id + year,
                    data = panel_a, cluster = ~state_id)
twfe_cancer <- feols(cancer_rate ~ treated | state_id + year,
                     data = panel_a, cluster = ~state_id)
twfe_nfh <- feols(nf_homicide_rate ~ treated | state_id + year,
                  data = panel_b, cluster = ~state_id)
twfe_nfs <- feols(nf_suicide_rate ~ treated | state_id + year,
                  data = panel_b, cluster = ~state_id)

tab4_manual <- data.table(
  Specification = c("Constitutional Carry", "", "Panel", "Observations"),
  `(1) Uninj. Injury` = c(make_cell(twfe_uninj, pv_star(twfe_uninj)),
                           "A (1999--2017)", as.character(nobs(twfe_uninj))),
  `(2) Heart Disease` = c(make_cell(twfe_heart, pv_star(twfe_heart)),
                           "A (1999--2017)", as.character(nobs(twfe_heart))),
  `(3) Cancer` = c(make_cell(twfe_cancer, pv_star(twfe_cancer)),
                    "A (1999--2017)", as.character(nobs(twfe_cancer))),
  `(4) NF Homicide` = c(make_cell(twfe_nfh, pv_star(twfe_nfh)),
                         "B (2019--2024)", as.character(nobs(twfe_nfh))),
  `(5) NF Suicide` = c(make_cell(twfe_nfs, pv_star(twfe_nfs)),
                        "B (2019--2024)", as.character(nobs(twfe_nfs)))
)

tab4_tex <- kbl(tab4_manual, format = "latex", booktabs = TRUE, escape = FALSE,
                caption = "Placebo Outcomes: Constitutional Carry Effect on Non-Firearm Causes",
                label = "placebo",
                align = c("l", "c", "c", "c", "c", "c")) %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = "All regressions include state and year fixed effects with state-clustered SEs. Non-firearm rates = all-cause minus firearm-specific. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
           threeparttable = TRUE, escape = FALSE)

writeLines(tab4_tex, file.path(tab_dir, "tab4_placebo.tex"))

## ==========================================================================
## TABLE 5: Robustness
## ==========================================================================

cat("=== Table 5: Robustness ===\n")

twfe_early <- feols(suicide_rate ~ treated | state_id + year,
                    data = panel_a[!first_treat %in% c(2019, 2021, 2022, 2023) | first_treat == 0],
                    cluster = ~state_id)

robustness_tab <- data.table(
  Specification = c("Baseline TWFE", "TWFE + Covariates",
                    "Sun-Abraham IW", "Early Adopters Only",
                    "Randomization Inference"),
  Coefficient = round(c(coef(twfe_a1), coef(twfe_a2)["treated"],
                        summary(sa_a, agg = "ATT")$coeftable["ATT", 1],
                        coef(twfe_early), coef(twfe_a1)), 3),
  SE = round(c(se(twfe_a1), se(twfe_a2)["treated"],
               summary(sa_a, agg = "ATT")$coeftable["ATT", 2],
               se(twfe_early), se(twfe_a1)), 3),
  `P-value` = c(sprintf("%.3f", fixest::pvalue(twfe_a1)),
                sprintf("%.3f", fixest::pvalue(twfe_a2)["treated"]),
                sprintf("%.3f", summary(sa_a, agg = "ATT")$coeftable["ATT", 4]),
                sprintf("%.3f", fixest::pvalue(twfe_early)),
                paste0(fread(file.path(data_dir, "randomization_inference.csv"))$ri_pval[1], " (RI)")),
  N = c(nobs(twfe_a1), nobs(twfe_a2), nobs(sa_a), nobs(twfe_early), nobs(twfe_a1))
)

tab5_tex <- kbl(robustness_tab, format = "latex", booktabs = TRUE,
                caption = "Robustness of Constitutional Carry Effect on Suicide Rate",
                label = "robustness",
                col.names = c("Specification", "Coefficient", "SE", "P-value", "N"),
                align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(latex_options = c("hold_position")) %>%
  footnote(general = "Dependent variable: age-adjusted suicide rate per 100,000. All regressions include state and year fixed effects. Standard errors clustered at the state level. RI p-value is two-sided from 500 permutations.",
           threeparttable = TRUE)

writeLines(tab5_tex, file.path(tab_dir, "tab5_robustness.tex"))

## ==========================================================================
## TABLE 6: Welfare Calculation
## ==========================================================================

cat("=== Table 6: Welfare ===\n")

welfare_data[, formatted := fifelse(
  grepl("ATT", metric), sprintf("%.2f", value),
  fifelse(grepl("deaths/state", metric), sprintf("%.1f", value),
          format(round(value, 0), big.mark = ","))
)]
welfare_tab <- welfare_data[, .(Metric = metric, Value = formatted)]

tab6_tex <- kbl(welfare_tab, format = "latex", booktabs = TRUE,
                caption = "Back-of-Envelope Welfare Calculation",
                label = "welfare",
                col.names = c("Metric", "Value"),
                align = c("l", "r")) %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = "VSL = 11.6 million USD (2023 DOT). Permit fee savings assume 150 USD average fee and 500,000 permit holders per treated state. These are illustrative bounds, not structural estimates.",
           threeparttable = TRUE)

writeLines(tab6_tex, file.path(tab_dir, "tab6_welfare.tex"))

cat("\n=== All tables saved to", tab_dir, "===\n")
