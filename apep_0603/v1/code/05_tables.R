## 05_tables.R — Generate all LaTeX tables including SDE appendix
## apep_0603: Local Fiscal Multiplier of Poland's Family 500+

source("00_packages.R")
load("../data/main_models.RData")
load("../data/robustness_models.RData")

## ------------------------------------------------------------------
## Helper: format number with significance stars
## ------------------------------------------------------------------
fmt_stars <- function(est, pval) {
  stars <- ifelse(pval < 0.01, "***",
           ifelse(pval < 0.05, "**",
           ifelse(pval < 0.1, "*", "")))
  sprintf("%.3f%s", est, stars)
}

## ------------------------------------------------------------------
## TABLE 1: Summary Statistics
## ------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

summ <- df %>%
  filter(year <= 2015) %>%
  select(biz_rate, unemp_rate, birth_rate, marriage_rate,
         infant_mortality_per1k, population, intensity_raw) %>%
  pivot_longer(everything(), names_to = "variable") %>%
  group_by(variable) %>%
  summarise(
    N = sum(!is.na(value)),
    Mean = mean(value, na.rm = TRUE),
    SD = sd(value, na.rm = TRUE),
    Min = min(value, na.rm = TRUE),
    Max = max(value, na.rm = TRUE),
    .groups = "drop"
  )

# Nice labels
var_labels <- c(
  "biz_rate" = "New Business Registrations (per 10K)",
  "unemp_rate" = "Unemployment Rate (\\%)",
  "birth_rate" = "Birth Rate (per 1,000)",
  "marriage_rate" = "Marriage Rate (per 1,000)",
  "infant_mortality_per1k" = "Infant Mortality (per 1,000)",
  "population" = "Population",
  "intensity_raw" = "Treatment Intensity (raw)"
)

summ$Variable <- var_labels[summ$variable]
summ <- summ %>% select(Variable, N, Mean, SD, Min, Max)

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Pre-Program Period (2010--2015)}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat("Variable & N & Mean & SD & Min & Max \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(summ))) {
  r <- summ[i, ]
  if (r$Variable == "Population") {
    cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
                r$Variable,
                formatC(r$N, format = "d", big.mark = ","),
                formatC(r$Mean, format = "f", digits = 0, big.mark = ","),
                formatC(r$SD, format = "f", digits = 0, big.mark = ","),
                formatC(r$Min, format = "f", digits = 0, big.mark = ","),
                formatC(r$Max, format = "f", digits = 0, big.mark = ",")))
  } else {
    cat(sprintf("%s & %s & %.2f & %.2f & %.2f & %.2f \\\\\n",
                r$Variable,
                formatC(r$N, format = "d", big.mark = ","),
                r$Mean, r$SD, r$Min, r$Max))
  }
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Summary statistics for the pre-program period (2010--2015) across all powiats in the analysis sample. Treatment intensity is the pre-program measure of child density used to construct the Bartik-style instrument. See text for construction details.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ------------------------------------------------------------------
## TABLE 2: Main Results
## ------------------------------------------------------------------
cat("Generating Table 2: Main Results...\n")

nice_outcomes <- c(
  "biz_rate" = "New Business Reg. (per 10K)",
  "unemp_rate" = "Unemployment Rate (\\%)",
  "birth_rate" = "Birth Rate (per 1,000)",
  "marriage_rate" = "Marriage Rate (per 1,000)",
  "infant_mortality_per1k" = "Infant Mortality (per 1,000)"
)

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Family 500+ Transfer Intensity on Local Economic Activity}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{2}{c}{Baseline} & \\multicolumn{2}{c}{Voivod.$\\times$Year FE} & \\multicolumn{2}{c}{Two-Shock} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n")
cat("Outcome & $\\hat{\\beta}$ & SE & $\\hat{\\beta}$ & SE & Phase I & Phase II \\\\\n")
cat("\\midrule\n")

for (i in seq_along(outcomes)) {
  y <- outcomes[i]

  # Baseline
  ct_b <- coeftable(models_baseline[[y]])
  beta_b <- ct_b["treat_post", "Estimate"]
  se_b <- ct_b["treat_post", "Std. Error"]
  p_b <- ct_b["treat_post", "Pr(>|t|)"]

  # Voivodeship × Year
  ct_v <- coeftable(models_voi[[y]])
  beta_v <- ct_v["treat_post", "Estimate"]
  se_v <- ct_v["treat_post", "Std. Error"]
  p_v <- ct_v["treat_post", "Pr(>|t|)"]

  # Two-shock
  ct_t <- coeftable(models_twoshock[[y]])
  beta_t1 <- ct_t["treat_post", "Estimate"]
  se_t1 <- ct_t["treat_post", "Std. Error"]
  p_t1 <- ct_t["treat_post", "Pr(>|t|)"]
  beta_t2 <- ct_t["treat_post2", "Estimate"]
  se_t2 <- ct_t["treat_post2", "Std. Error"]
  p_t2 <- ct_t["treat_post2", "Pr(>|t|)"]

  cat(sprintf("%s & %s & (%s) & %s & (%s) & %s & %s \\\\\n",
              nice_outcomes[y],
              fmt_stars(beta_b, p_b), formatC(se_b, format = "f", digits = 3),
              fmt_stars(beta_v, p_v), formatC(se_v, format = "f", digits = 3),
              fmt_stars(beta_t1, p_t1), fmt_stars(beta_t2, p_t2)))
  cat(sprintf(" & & & & & (%s) & (%s) \\\\\n",
              formatC(se_t1, format = "f", digits = 3),
              formatC(se_t2, format = "f", digits = 3)))
}

# Add N and clusters
n_obs_b <- nobs(models_baseline[[outcomes[1]]])
n_clust <- length(unique(df$powiat_id))
cat("\\midrule\n")
cat(sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
            formatC(n_obs_b, format = "d", big.mark = ","),
            formatC(nobs(models_voi[[outcomes[1]]]), format = "d", big.mark = ","),
            formatC(nobs(models_twoshock[[outcomes[1]]]), format = "d", big.mark = ",")))
cat(sprintf("Powiats & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
            n_clust, n_clust, n_clust))
cat("Powiat FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\n")
cat("Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{---} & \\multicolumn{2}{c}{Yes} \\\\\n")
cat("Voivod.$\\times$Year FE & \\multicolumn{2}{c}{No} & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{No} \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Each cell reports the coefficient on treatment intensity $\\times$ Post from a TWFE regression with powiat and year (or voivodeship$\\times$year) fixed effects. Treatment intensity is the standardized pre-program (2015) child density measure. Standard errors clustered at the powiat level in parentheses. The Two-Shock specification separates Phase I (2016) and Phase II (2019 universalization) effects. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ------------------------------------------------------------------
## TABLE 3: Robustness
## ------------------------------------------------------------------
cat("Generating Table 3: Robustness Checks...\n")

sink("../tables/tab3_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & Placebo (2013) & Drop Cities & RI $p$-value & Baseline \\\\\n")
cat("Outcome & $\\hat{\\beta}$ & $\\hat{\\beta}$ & & $\\hat{\\beta}$ \\\\\n")
cat("\\midrule\n")

for (i in seq_along(outcomes)) {
  y <- outcomes[i]

  # Placebo
  ct_p <- coeftable(placebo_models[[y]])
  beta_p <- ct_p["fake_treat", "Estimate"]
  se_p <- ct_p["fake_treat", "Std. Error"]
  p_p <- ct_p["fake_treat", "Pr(>|t|)"]

  # Rural
  ct_r <- coeftable(models_rural[[y]])
  beta_r <- ct_r["treat_post", "Estimate"]
  se_r <- ct_r["treat_post", "Std. Error"]
  p_r <- ct_r["treat_post", "Pr(>|t|)"]

  # RI
  ri_p <- ri_pvalues[y]

  # Baseline (for comparison)
  ct_b <- coeftable(models_baseline[[y]])
  beta_b <- ct_b["treat_post", "Estimate"]
  se_b <- ct_b["treat_post", "Std. Error"]
  p_b <- ct_b["treat_post", "Pr(>|t|)"]

  cat(sprintf("%s & %s & %s & %.3f & %s \\\\\n",
              nice_outcomes[y],
              fmt_stars(beta_p, p_p),
              fmt_stars(beta_r, p_r),
              ri_p,
              fmt_stars(beta_b, p_b)))
  cat(sprintf(" & (%s) & (%s) & & (%s) \\\\\n",
              formatC(se_p, format = "f", digits = 3),
              formatC(se_r, format = "f", digits = 3),
              formatC(se_b, format = "f", digits = 3)))
}

cat("\\midrule\n")
cat(sprintf("Powiats & %d & %d & %d & %d \\\\\n",
            n_distinct(df %>% filter(year <= 2015) %>% pull(powiat_id)),
            n_distinct(df %>% filter(!is_city_powiat) %>% pull(powiat_id)),
            n_clust, n_clust))
cat("Powiat FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Placebo assigns a fake treatment in 2013 using pre-period data only (2010--2015). Drop Cities excludes city-powiats (powiaty grodzkie). RI $p$-value is from randomization inference with 500 permutations of treatment assignment. Baseline reproduced for comparison. Standard errors clustered at powiat level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ------------------------------------------------------------------
## TABLE 4: Heterogeneity by Income
## ------------------------------------------------------------------
cat("Generating Table 4: Heterogeneity...\n")

sink("../tables/tab4_heterogeneity.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Heterogeneity by Baseline Income Level}\n")
cat("\\label{tab:heterogeneity}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & Low Income & High Income & Difference \\\\\n")
cat("Outcome & $\\hat{\\beta}$ & $\\hat{\\beta}$ & $p$-value \\\\\n")
cat("\\midrule\n")

for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  ct <- coeftable(het_models[[y]])

  beta_lo <- ct["treat_post_lo", "Estimate"]
  se_lo <- ct["treat_post_lo", "Std. Error"]
  p_lo <- ct["treat_post_lo", "Pr(>|t|)"]

  beta_hi <- ct["treat_post_hi", "Estimate"]
  se_hi <- ct["treat_post_hi", "Std. Error"]
  p_hi <- ct["treat_post_hi", "Pr(>|t|)"]

  # Wald test for equality
  diff <- beta_lo - beta_hi
  se_diff <- sqrt(se_lo^2 + se_hi^2)  # conservative
  p_diff <- 2 * pnorm(-abs(diff / se_diff))

  cat(sprintf("%s & %s & %s & %.3f \\\\\n",
              nice_outcomes[y],
              fmt_stars(beta_lo, p_lo),
              fmt_stars(beta_hi, p_hi),
              p_diff))
  cat(sprintf(" & (%s) & (%s) & \\\\\n",
              formatC(se_lo, format = "f", digits = 3),
              formatC(se_hi, format = "f", digits = 3)))
}

cat("\\midrule\n")
cat("Powiat FE & Yes & Yes & \\\\\n")
cat("Year FE & Yes & Yes & \\\\\n")
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Powiats split at median 2015 business registration rate (proxy for income). Low-income powiats have below-median rates. Difference $p$-value from a Wald test of equality of the two coefficients. If the MPC channel operates, low-income powiats should show larger effects. Standard errors clustered at powiat level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ------------------------------------------------------------------
## TABLE F1: Standardized Effect Sizes (SDE Appendix)
## ------------------------------------------------------------------
cat("Generating Table F1: SDE Appendix...\n")

# Compute SD(Y) for each outcome in the pre-period
sd_y <- df %>%
  filter(year <= 2015) %>%
  summarise(across(all_of(outcomes), ~sd(.x, na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "outcome", values_to = "sd_y")

# Get main coefficients
sde_table <- tibble(outcome = outcomes)
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  ct <- coeftable(models_baseline[[y]])
  sde_table$beta[i] <- ct["treat_post", "Estimate"]
  sde_table$se[i] <- ct["treat_post", "Std. Error"]
}

sde_table <- sde_table %>%
  left_join(sd_y, by = "outcome") %>%
  mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

sde_labels <- c(
  "biz_rate" = "New Business Reg.",
  "unemp_rate" = "Unemployment Rate",
  "birth_rate" = "Birth Rate",
  "marriage_rate" = "Marriage Rate",
  "infant_mortality_per1k" = "Infant Mortality"
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD(Y) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")

for (i in seq_len(nrow(sde_table))) {
  r <- sde_table[i, ]
  cat(sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
              sde_labels[r$outcome],
              r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Standardized effect sizes (SDE) computed as $\\hat{\\beta} / \\text{SD}(Y)$, where SD(Y) is the pre-treatment (2010--2015) standard deviation of each outcome across powiat-years. The treatment is continuous: a one-standard-deviation increase in pre-program child density (Bartik-style instrument). Classification follows 7-bucket scheme: Large ($|\\text{SDE}| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). Classification refers to the magnitude of the standardized effect, not its statistical significance. Research question: What is the local fiscal multiplier of Poland's Family 500+ unconditional cash transfer? Data: GUS BDL (Statistics Poland), 2010--2022. Method: Continuous-treatment TWFE with powiat and year fixed effects. Sample: ")
n_panel <- nrow(df)
cat(sprintf("%s powiat-year observations.\n", formatC(n_panel, format = "d", big.mark = ",")))
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated successfully.\n")
