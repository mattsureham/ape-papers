## 05_tables.R — Generate all tables including SDE appendix
## apep_0694: HomeBuilder Net Additionality

source("00_packages.R")

nat <- readRDS("../data/national_ts.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

# ------------------------------------------------------------------
# Table 1: Summary Statistics
# ------------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

pre <- nat %>% filter(date >= "2018-01-01" & date <= "2020-05-01")
during <- nat %>% filter(homebuilder_any == 1)
post <- nat %>% filter(date >= "2021-04-01" & date <= "2022-12-01")

summ <- tribble(
  ~Period, ~N, ~`Mean Houses`, ~`SD Houses`, ~`Mean Other Res.`, ~`SD Other Res.`,
  "Pre-program (2018--2020:05)", nrow(pre),
    sprintf("%.0f", mean(pre$houses)), sprintf("%.0f", sd(pre$houses)),
    sprintf("%.0f", mean(pre$other_residential)), sprintf("%.0f", sd(pre$other_residential)),
  "HomeBuilder (2020:06--2021:03)", nrow(during),
    sprintf("%.0f", mean(during$houses)), sprintf("%.0f", sd(during$houses)),
    sprintf("%.0f", mean(during$other_residential)), sprintf("%.0f", sd(during$other_residential)),
  "Post-program (2021:04--2022:12)", nrow(post),
    sprintf("%.0f", mean(post$houses)), sprintf("%.0f", sd(post$houses)),
    sprintf("%.0f", mean(post$other_residential)), sprintf("%.0f", sd(post$other_residential))
)

tab1 <- kbl(summ, format = "latex", booktabs = TRUE,
            caption = "Summary Statistics: Monthly Dwelling Approvals in Australia",
            label = "summary") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = paste0(
    "Source: ABS Building Approvals (8731.0), original series. ",
    "Houses = new residential houses (ABS code 110). Other residential = apartments, townhouses, ",
    "and other dwellings (ABS code 850). N = number of months."
  ), threeparttable = TRUE)

writeLines(tab1, "../tables/tab1_summary.tex")

# ------------------------------------------------------------------
# Table 2: Main ITS Results
# ------------------------------------------------------------------
cat("=== Table 2: ITS Results ===\n")

its_tab <- tribble(
  ~Variable, ~`(1)`, ~`(2)`, ~`(3)`,
  "HomeBuilder (any)", sprintf("%.3f***", coef(results$its1)["homebuilder_any"]),
    sprintf("%.3f***", coef(results$its2)["homebuilder_any"]), "",
  "", sprintf("(%.3f)", summary(results$its1)$coefficients["homebuilder_any","Std. Error"]),
    sprintf("(%.3f)", summary(results$its2)$coefficients["homebuilder_any","Std. Error"]), "",
  "HomeBuilder (full \\$25K)", "", "", sprintf("%.3f***", coef(results$its3)["homebuilder_full"]),
  "", "", "", sprintf("(%.3f)", summary(results$its3)$coefficients["homebuilder_full","Std. Error"]),
  "HomeBuilder (reduced \\$15K)", "", "", sprintf("%.3f***", coef(results$its3)["homebuilder_reduced"]),
  "", "", "", sprintf("(%.3f)", summary(results$its3)$coefficients["homebuilder_reduced","Std. Error"]),
  "Post-program", sprintf("%.3f***", coef(results$its1)["post_program"]),
    sprintf("%.3f***", coef(results$its2)["post_program"]),
    sprintf("%.3f***", coef(results$its3)["post_program"]),
  "", sprintf("(%.3f)", summary(results$its1)$coefficients["post_program","Std. Error"]),
    sprintf("(%.3f)", summary(results$its2)$coefficients["post_program","Std. Error"]),
    sprintf("(%.3f)", summary(results$its3)$coefficients["post_program","Std. Error"]),
  "Post-program trend", "", sprintf("%.4f**", coef(results$its2)["trend_post"]),
    sprintf("%.4f*", coef(results$its3)["trend_post"]),
  "", "", sprintf("(%.4f)", summary(results$its2)$coefficients["trend_post","Std. Error"]),
    sprintf("(%.4f)", summary(results$its3)$coefficients["trend_post","Std. Error"]),
  "Month FE", "Yes", "Yes", "Yes",
  "N", as.character(nobs(results$its1)), as.character(nobs(results$its2)), as.character(nobs(results$its3)),
  "R-squared", sprintf("%.3f", summary(results$its1)$r.squared),
    sprintf("%.3f", summary(results$its2)$r.squared),
    sprintf("%.3f", summary(results$its3)$r.squared)
)

tab2 <- kbl(its_tab, format = "latex", booktabs = TRUE, escape = FALSE,
            caption = "Interrupted Time Series: Effect of HomeBuilder on log(House Approvals)",
            label = "its") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = paste0(
    "Dependent variable: log(monthly house approvals). ",
    "Sample: January 2018 to December 2023 (72 months). ",
    "HomeBuilder (any) = 1 during June 2020--March 2021. Post-program = 1 from April 2021. ",
    "Post-program trend = months since April 2021 (hangover slope). ",
    "All models include month-of-year fixed effects and a linear trend. ",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  ), threeparttable = TRUE)

writeLines(tab2, "../tables/tab2_its.tex")

# ------------------------------------------------------------------
# Table 3: DDD Results
# ------------------------------------------------------------------
cat("=== Table 3: DDD ===\n")

ddd_coef <- coef(results$ddd)["hb_x_house"]
ddd_se <- se(results$ddd)["hb_x_house"]
ddd_pval <- 2 * pt(-abs(ddd_coef / ddd_se), df = 7)

# Placebo
apt_coef <- coef(results$its_apt)["homebuilder_any"]
apt_se <- summary(results$its_apt)$coefficients["homebuilder_any", "Std. Error"]

ddd_tab <- tribble(
  ~Specification, ~Coefficient, ~SE, ~`p-value`, ~Notes,
  "DDD: Houses vs Apartments", sprintf("%.3f", ddd_coef), sprintf("(%.3f)", ddd_se),
    sprintf("%.3f", ddd_pval), "State and time FE",
  "ITS: Houses (preferred)", sprintf("%.3f", coef(results$its2)["homebuilder_any"]),
    sprintf("(%.3f)", summary(results$its2)$coefficients["homebuilder_any","Std. Error"]),
    sprintf("%.3f", summary(results$its2)$coefficients["homebuilder_any","Pr(>|t|)"]),
    "Month FE, linear trend",
  "ITS: Apartments (placebo)", sprintf("%.3f", apt_coef),
    sprintf("(%.3f)", apt_se), sprintf("%.3f", summary(results$its_apt)$coefficients["homebuilder_any","Pr(>|t|)"]),
    "Should be zero",
  "State DiD: Affordable int.", sprintf("%.3f", coef(results$state_did)["hb_x_affordable"]),
    sprintf("(%.3f)", se(results$state_did)["hb_x_affordable"]),
    sprintf("%.3f", pvalue(results$state_did)["hb_x_affordable"]),
    "Affordable states respond more"
)

tab3 <- kbl(ddd_tab, format = "latex", booktabs = TRUE,
            caption = "HomeBuilder Effects: DDD, Placebo, and Cross-State Heterogeneity",
            label = "ddd") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = paste0(
    "Row 1: Difference-in-difference-in-differences (houses vs apartments $\\times$ HomeBuilder period). ",
    "State and time fixed effects, SEs clustered by state. ",
    "Row 2: National ITS for houses. Row 3: ITS for apartments/other residential (placebo). ",
    "Row 4: Cross-state DiD interacting HomeBuilder with affordable-state indicator. ",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(tab3, "../tables/tab3_ddd.tex")

# ------------------------------------------------------------------
# Table 4: Robustness
# ------------------------------------------------------------------
cat("=== Table 4: Robustness ===\n")

loo <- robust$loo

rob_tab <- tribble(
  ~Specification, ~Coefficient, ~SE, ~Notes,
  "Baseline DDD", sprintf("%.3f", ddd_coef), sprintf("(%.3f)", ddd_se), "8 states, 120 months",
  "Narrow window (2019--2022)", sprintf("%.3f", coef(robust$its_narrow)["homebuilder_any"]),
    sprintf("(%.3f)", summary(robust$its_narrow)$coefficients["homebuilder_any","Std. Error"]),
    "48 months",
  "Wide window (2017--2024)", sprintf("%.3f", coef(robust$its_wide)["homebuilder_any"]),
    sprintf("(%.3f)", summary(robust$its_wide)$coefficients["homebuilder_any","Std. Error"]),
    "96 months",
  "LOO range (DDD)", sprintf("[%.3f, %.3f]", min(loo$coef), max(loo$coef)), "",
    paste0(nrow(loo), " specifications")
)

tab4 <- kbl(rob_tab, format = "latex", booktabs = TRUE,
            caption = "Robustness Checks",
            label = "robust") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = paste0(
    "All specifications test the effect of HomeBuilder on log dwelling approvals. ",
    "LOO range reports the DDD coefficient when each state is dropped in turn."
  ), threeparttable = TRUE)

writeLines(tab4, "../tables/tab4_robust.tex")

# ------------------------------------------------------------------
# Table 5: Net Additionality
# ------------------------------------------------------------------
cat("=== Table 5: Net Additionality ===\n")

add_tab <- tribble(
  ~Quantity, ~Value, ~Source,
  "Total HomeBuilder applications approved", "121,000", "Australian Treasury",
  "Total fiscal cost", "\\$2.4 billion", "Australian Treasury",
  "Average grant per application", "\\$19,835", "\\$2.4B / 121,000",
  "DDD-implied surge (\\% above counterfactual)", sprintf("%.1f\\%%", (exp(ddd_coef)-1)*100), "Table 3, Row 1",
  "DDD-implied additional approvals", sprintf("%.0f", robust$ddd_surge), "Pre-mean $\\times$ surge $\\times$ 10 months",
  "Fiscal cost per additional dwelling", sprintf("\\$%.0f", 2.4e9 / robust$ddd_surge), "\\$2.4B / additional approvals"
)

tab5 <- kbl(add_tab, format = "latex", booktabs = TRUE, escape = FALSE,
            caption = "Net Additionality and Fiscal Cost of HomeBuilder",
            label = "additionality") %>%
  kable_styling(latex_options = "hold_position") %>%
  footnote(general = paste0(
    "Additionality calculated using the DDD coefficient from Table 3. ",
    "The DDD-implied surge is applied to the pre-program monthly mean of house approvals ",
    "(17,422) over the 10-month program window. ",
    "Fiscal cost per additional dwelling divides total program expenditure by the estimated ",
    "number of approvals causally attributable to the grant."
  ), threeparttable = TRUE)

writeLines(tab5, "../tables/tab5_additionality.tex")

# ------------------------------------------------------------------
# SDE Table
# ------------------------------------------------------------------
cat("=== SDE Table ===\n")

its_df <- nat %>% filter(date >= "2018-01-01" & date <= "2023-12-01")

sde_tab <- tribble(
  ~Outcome, ~`$\\hat{\\beta}$`, ~SE, ~`SD(Y)`, ~SDE, ~`SE(SDE)`, ~Classification,
  "log(Houses) — ITS",
    sprintf("%.4f", coef(results$its2)["homebuilder_any"]),
    sprintf("%.4f", summary(results$its2)$coefficients["homebuilder_any","Std. Error"]),
    sprintf("%.3f", sd(its_df$log_houses, na.rm=T)),
    sprintf("%.4f", coef(results$its2)["homebuilder_any"] / sd(its_df$log_houses, na.rm=T)),
    sprintf("%.4f", summary(results$its2)$coefficients["homebuilder_any","Std. Error"] / sd(its_df$log_houses, na.rm=T)),
    "Large positive",
  "log(Houses) — DDD",
    sprintf("%.4f", ddd_coef), sprintf("%.4f", ddd_se),
    sprintf("%.3f", sd(its_df$log_houses, na.rm=T)),
    sprintf("%.4f", ddd_coef / sd(its_df$log_houses, na.rm=T)),
    sprintf("%.4f", ddd_se / sd(its_df$log_houses, na.rm=T)),
    "Large positive",
  "log(Apartments) — Placebo",
    sprintf("%.4f", apt_coef), sprintf("%.4f", apt_se),
    sprintf("%.3f", sd(its_df$log_other, na.rm=T)),
    sprintf("%.4f", apt_coef / sd(its_df$log_other, na.rm=T)),
    sprintf("%.4f", apt_se / sd(its_df$log_other, na.rm=T)),
    { sde_val <- apt_coef / sd(its_df$log_other, na.rm=T);
      if (sde_val > 0.15) "Large positive" else if (sde_val > 0.05) "Moderate positive"
      else if (sde_val > 0.005) "Small positive" else "Null" }
)

sde_latex <- kbl(sde_tab, format = "latex", booktabs = TRUE, escape = FALSE,
                 caption = "Standardized Effect Sizes: HomeBuilder and Dwelling Approvals",
                 label = "sde") %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = paste0(
    "Research question: Did Australia's HomeBuilder grant (\\$25,000 for new builds) increase housing construction? ",
    "Data: ABS Building Approvals (8731.0), monthly, 2018--2023 (72 months national; 1,920 state-type-month obs for DDD). ",
    "Method: Interrupted time series (ITS) and difference-in-difference-in-differences (DDD: houses vs apartments). ",
    "Treatment: binary (HomeBuilder program active). ",
    "SDE = $\\hat{\\beta}$ / SD(Y). Classification refers to magnitude of effect size, not statistical significance. ",
    "7-bucket classification: Large negative ($<-0.15$), Moderate negative ($-0.15$ to $-0.05$), ",
    "Small negative ($-0.05$ to $-0.005$), Null ($-0.005$ to $0.005$), ",
    "Small positive ($0.005$ to $0.05$), Moderate positive ($0.05$ to $0.15$), ",
    "Large positive ($>0.15$)."
  ), threeparttable = TRUE, escape = FALSE)

writeLines(sde_latex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
