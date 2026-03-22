## 05_tables.R — Generate all tables for the paper
## apep_0748: GP Practice Closures and A&E Utilization

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

panel_clean <- panel %>%
  filter(!is.na(type1_attendances), type1_attendances > 0) %>%
  mutate(
    log_type1 = log(type1_attendances),
    log_total = log(total_attendances),
    covid = as.integer(period >= as.Date("2020-03-01") & period <= as.Date("2021-06-30"))
  )

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("=== Table 1: Summary Statistics ===\n")

## Panel A: Trust-level outcomes
ever_treated <- panel_clean %>% filter(cohort > 0)
never_treated <- panel_clean %>% filter(cohort == 0)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & N \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: A\\&E Trust-Month Panel (2017--2025)}} \\\\[4pt]",
  sprintf("Type 1 A\\&E Attendances & %s & %s & %s & %s & %s \\\\",
          format(round(mean(panel_clean$type1_attendances)), big.mark = ","),
          format(round(sd(panel_clean$type1_attendances)), big.mark = ","),
          format(round(min(panel_clean$type1_attendances)), big.mark = ","),
          format(round(max(panel_clean$type1_attendances)), big.mark = ","),
          format(nrow(panel_clean), big.mark = ",")),
  sprintf("Total A\\&E Attendances & %s & %s & %s & %s & %s \\\\",
          format(round(mean(panel_clean$total_attendances, na.rm = TRUE)), big.mark = ","),
          format(round(sd(panel_clean$total_attendances, na.rm = TRUE)), big.mark = ","),
          format(round(min(panel_clean$total_attendances, na.rm = TRUE)), big.mark = ","),
          format(round(max(panel_clean$total_attendances, na.rm = TRUE)), big.mark = ","),
          format(sum(!is.na(panel_clean$total_attendances)), big.mark = ",")),
  sprintf("Cumulative GP Closures (10km) & %.1f & %.1f & %d & %d & %s \\\\",
          mean(panel_clean$cumulative_closures),
          sd(panel_clean$cumulative_closures),
          min(panel_clean$cumulative_closures),
          max(panel_clean$cumulative_closures),
          format(nrow(panel_clean), big.mark = ",")),
  sprintf("Post-Closure (binary) & %.3f & %.3f & 0 & 1 & %s \\\\",
          mean(panel_clean$treated),
          sd(panel_clean$treated),
          format(nrow(panel_clean), big.mark = ",")),
  "\\\\",
  "\\multicolumn{6}{l}{\\textit{Panel B: GP Practice Closures (2017--2025)}} \\\\[4pt]",
  sprintf("Total closures & \\multicolumn{4}{c}{%s} & \\\\",
          format(sum(panel_clean$closures_this_month), big.mark = ",")),
  sprintf("Unique A\\&E trusts & \\multicolumn{4}{c}{%d} & \\\\",
          length(unique(panel_clean$provider_code))),
  sprintf("Ever-treated trusts & \\multicolumn{4}{c}{%d} & \\\\",
          sum(panel_clean$cohort > 0 & !duplicated(panel_clean$provider_code))),
  sprintf("Never-treated trusts & \\multicolumn{4}{c}{%d} & \\\\",
          sum(panel_clean$cohort == 0 & !duplicated(panel_clean$provider_code))),
  sprintf("Months & \\multicolumn{4}{c}{%d} & \\\\",
          length(unique(panel_clean$period))),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports trust-month level statistics for the balanced panel of 122 NHS trusts with Type 1 (major) A\\&E departments, April 2017 to March 2025. Cumulative GP closures counts the number of GP practices that closed within 10km of each trust's main site up to that month. Post-closure is a binary indicator equal to one after any GP practice within 10km closes. Panel B summarizes the treatment structure.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

## ============================================================
## Table 2: Main Results
## ============================================================
cat("=== Table 2: Main Results ===\n")

## Re-estimate models for clean table output
m1 <- feols(log_type1 ~ treated | provider_code + period,
            data = panel_clean, cluster = ~provider_code)

pre_covid <- panel_clean %>% filter(period < as.Date("2020-03-01"))
post_covid <- panel_clean %>% filter(period >= as.Date("2022-01-01"))
no_covid <- panel_clean %>% filter(period < as.Date("2020-03-01") | period >= as.Date("2022-01-01"))

m2 <- feols(log_type1 ~ treated | provider_code + period,
            data = pre_covid, cluster = ~provider_code)
m3 <- feols(log_type1 ~ treated | provider_code + period,
            data = post_covid, cluster = ~provider_code)
m4 <- feols(log_type1 ~ treated | provider_code + period,
            data = no_covid, cluster = ~provider_code)
m5 <- feols(log_type1 ~ cumulative_closures | provider_code + period,
            data = panel_clean, cluster = ~provider_code)

## Extract coefficients
get_coef <- function(m, var) {
  b <- coef(m)[var]
  se <- sqrt(vcov(m)[var, var])
  p <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = se, p = p, stars = stars)
}

c1 <- get_coef(m1, "treated")
c2 <- get_coef(m2, "treated")
c3 <- get_coef(m3, "treated")
c4 <- get_coef(m4, "treated")
c5 <- get_coef(m5, "cumulative_closures")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of GP Practice Closures on Type 1 A\\&E Attendances}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Full Sample & Pre-COVID & Post-COVID & Excl.\\ COVID & Intensity \\\\",
  "\\hline",
  sprintf("Post-Closure & %s%s & %s%s & %s%s & %s%s & \\\\",
          format(round(c1$b, 4), nsmall = 4), c1$stars,
          format(round(c2$b, 4), nsmall = 4), c2$stars,
          format(round(c3$b, 4), nsmall = 4), c3$stars,
          format(round(c4$b, 4), nsmall = 4), c4$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & \\\\",
          format(round(c1$se, 4), nsmall = 4),
          format(round(c2$se, 4), nsmall = 4),
          format(round(c3$se, 4), nsmall = 4),
          format(round(c4$se, 4), nsmall = 4)),
  sprintf("Cumulative Closures & & & & & %s%s \\\\",
          format(round(c5$b, 5), nsmall = 5), c5$stars),
  sprintf(" & & & & & (%s) \\\\",
          format(round(c5$se, 5), nsmall = 5)),
  "\\\\",
  "Trust FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m4), big.mark = ","),
          format(nobs(m5), big.mark = ",")),
  sprintf("Trusts & %d & %d & %d & %d & %d \\\\",
          length(unique(panel_clean$provider_code)),
          length(unique(pre_covid$provider_code)),
          length(unique(post_covid$provider_code)),
          length(unique(no_covid$provider_code)),
          length(unique(panel_clean$provider_code))),
  sprintf("R$^2$ (within) & %s & %s & %s & %s & %s \\\\",
          format(round(r2(m1, "wr2"), 4), nsmall = 4),
          format(round(r2(m2, "wr2"), 4), nsmall = 4),
          format(round(r2(m3, "wr2"), 4), nsmall = 4),
          format(round(r2(m4, "wr2"), 4), nsmall = 4),
          format(round(r2(m5, "wr2"), 4), nsmall = 4)),
  sprintf("Mean Dep.\\ Var.\\ & %s & %s & %s & %s & %s \\\\",
          format(round(mean(panel_clean$log_type1, na.rm = TRUE), 2), nsmall = 2),
          format(round(mean(pre_covid$log_type1, na.rm = TRUE), 2), nsmall = 2),
          format(round(mean(post_covid$log_type1, na.rm = TRUE), 2), nsmall = 2),
          format(round(mean(no_covid$log_type1, na.rm = TRUE), 2), nsmall = 2),
          format(round(mean(panel_clean$log_type1, na.rm = TRUE), 2), nsmall = 2)),
  sprintf("RI $p$-value & %s & & & & \\\\",
          format(round(robust$ri_pvalue, 3), nsmall = 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a two-way fixed effects regression of log Type 1 A\\&E attendances on a GP closure treatment indicator. Post-Closure equals one after any GP practice within 10km of the trust closes. Cumulative Closures counts the total number of GP closures within 10km up to that month. Pre-COVID restricts to April 2017--February 2020. Post-COVID restricts to January 2022--March 2025. Standard errors clustered at the trust level in parentheses. RI $p$-value reports the randomization inference $p$-value from 500 permutations of treatment assignment across trusts. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("Table 2 saved.\n")

## ============================================================
## Table 3: Region Heterogeneity
## ============================================================
cat("=== Table 3: Region Heterogeneity ===\n")

m_region <- feols(log_type1 ~ treated:trust_region | provider_code + period,
                  data = panel_clean %>% filter(!is.na(trust_region)),
                  cluster = ~provider_code)

region_coefs <- data.frame(
  region = gsub("treated:trust_region", "", names(coef(m_region))),
  beta = unname(coef(m_region)),
  se = sqrt(diag(vcov(m_region)))
) %>%
  mutate(
    p = 2 * pnorm(-abs(beta / se)),
    stars = case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.1 ~ "*", TRUE ~ ""),
    n_trusts = NA_integer_
  ) %>%
  arrange(desc(abs(beta)))

## Count trusts per region
trust_regions <- panel_clean %>%
  filter(!is.na(trust_region), !duplicated(provider_code)) %>%
  count(trust_region)

region_coefs <- region_coefs %>%
  left_join(trust_regions, by = c("region" = "trust_region"))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Region}",
  "\\label{tab:region}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Region & $\\hat{\\beta}$ & SE & Trusts & $p$-value \\\\",
  "\\hline"
)

for (i in seq_len(nrow(region_coefs))) {
  r <- region_coefs[i, ]
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s%s & (%s) & %s & %s \\\\",
            r$region,
            format(round(r$beta, 4), nsmall = 4), r$stars,
            format(round(r$se, 4), nsmall = 4),
            ifelse(is.na(r$n), "--", as.character(r$n)),
            format(round(r$p, 3), nsmall = 3)))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from a regression of log Type 1 A\\&E attendances on the post-closure indicator interacted with region dummies. Trust and month fixed effects included. Standard errors clustered at the trust level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_region.tex"))
cat("Table 3 saved.\n")

## ============================================================
## Table 4: Robustness Summary
## ============================================================
cat("=== Table 4: Robustness Summary ===\n")

## Total attendances
m_total <- feols(log_total ~ treated | provider_code + period,
                 data = panel_clean %>% filter(!is.na(total_attendances), total_attendances > 0),
                 cluster = ~provider_code)
c_total <- get_coef(m_total, "treated")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Specification & $\\hat{\\beta}$ & SE & $N$ \\\\",
  "\\hline",
  sprintf("Baseline (Type 1, 10km) & %s & (%s) & %s \\\\",
          format(round(c1$b, 4), nsmall = 4),
          format(round(c1$se, 4), nsmall = 4),
          format(nobs(m1), big.mark = ",")),
  sprintf("Total Attendances & %s & (%s) & %s \\\\",
          format(round(c_total$b, 4), nsmall = 4),
          format(round(c_total$se, 4), nsmall = 4),
          format(nobs(m_total), big.mark = ",")),
  sprintf("Pre-COVID (2017--2020) & %s & (%s) & %s \\\\",
          format(round(c2$b, 4), nsmall = 4),
          format(round(c2$se, 4), nsmall = 4),
          format(nobs(m2), big.mark = ",")),
  sprintf("Post-COVID (2022--2025) & %s%s & (%s) & %s \\\\",
          format(round(c3$b, 4), nsmall = 4), c3$stars,
          format(round(c3$se, 4), nsmall = 4),
          format(nobs(m3), big.mark = ",")),
  sprintf("Excluding COVID & %s & (%s) & %s \\\\",
          format(round(c4$b, 4), nsmall = 4),
          format(round(c4$se, 4), nsmall = 4),
          format(nobs(m4), big.mark = ",")),
  sprintf("Treatment Intensity & %s%s & (%s) & %s \\\\",
          format(round(c5$b, 5), nsmall = 5), c5$stars,
          format(round(c5$se, 5), nsmall = 5),
          format(nobs(m5), big.mark = ",")),
  sprintf("RI $p$-value (500 perms) & \\multicolumn{3}{c}{%s} \\\\",
          format(round(robust$ri_pvalue, 3), nsmall = 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on the treatment variable from a two-way fixed effects regression with trust and month fixed effects. Standard errors clustered at the trust level. The treatment intensity specification uses cumulative closures within 10km instead of the binary post-closure indicator. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robust.tex"))
cat("Table 4 saved.\n")

## ============================================================
## Table F1: Standardized Effect Size (SDE) — MANDATORY
## ============================================================
cat("=== Table F1: Standardized Effect Size ===\n")

## Compute SDEs for main outcomes
## SDE = β̂ / SD(Y) for binary treatment
sd_type1_pre <- sd(panel_clean$type1_attendances[panel_clean$treated == 0], na.rm = TRUE)
sd_total_pre <- sd(panel_clean$total_attendances[panel_clean$treated == 0], na.rm = TRUE)

## Main coefficients (in levels, not logs — need to convert)
## For log specification: β_log ≈ % change, so level effect ≈ β_log × mean(Y)
mean_type1 <- mean(panel_clean$type1_attendances, na.rm = TRUE)
mean_total <- mean(panel_clean$total_attendances[!is.na(panel_clean$total_attendances)], na.rm = TRUE)

## Full sample
beta_type1 <- c1$b * mean_type1  # Approximate level effect
se_type1_level <- c1$se * mean_type1
sde_type1 <- beta_type1 / sd_type1_pre
se_sde_type1 <- se_type1_level / sd_type1_pre

## Post-COVID
beta_postcovid <- c3$b * mean(post_covid$type1_attendances, na.rm = TRUE)
se_postcovid_level <- c3$se * mean(post_covid$type1_attendances, na.rm = TRUE)
sd_type1_postcovid_pre <- sd(post_covid$type1_attendances[post_covid$treated == 0], na.rm = TRUE)
## If no untreated obs in post-COVID, use full-sample pre-treatment SD
if (is.na(sd_type1_postcovid_pre) || sd_type1_postcovid_pre == 0) {
  sd_type1_postcovid_pre <- sd_type1_pre
}
sde_postcovid <- beta_postcovid / sd_type1_postcovid_pre
se_sde_postcovid <- se_postcovid_level / sd_type1_postcovid_pre

## Total attendances
beta_total <- c_total$b * mean_total
se_total_level <- c_total$se * mean_total
sde_total <- beta_total / sd_total_pre
se_sde_total <- se_total_level / sd_total_pre

## Classification function
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

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England). ",
  "\\textbf{Research question:} Does the closure of GP practices in England's NHS increase emergency department (A\\&E) utilization at nearby hospital trusts? ",
  "\\textbf{Policy mechanism:} GP practice closures, driven primarily by GP partner retirements, funding pressures, and NHS consolidation, remove patients' regular primary care access point, potentially forcing them to seek care at emergency departments for conditions that could be managed by a GP. ",
  "\\textbf{Outcome definition:} Monthly count of Type 1 (major) A\\&E department attendances per NHS trust, from the NHS England Monthly A\\&E Statistics. ",
  "\\textbf{Treatment:} Binary; equals one after any GP practice within 10km of the trust's main site closes. ",
  "\\textbf{Data:} NHS Organisation Data Service (GP practice locations and closure dates, 2,464 closures), NHS England Monthly A\\&E Statistics by provider (122 trusts, 94 months, April 2017--March 2025), postcodes.io for geocoding. ",
  "\\textbf{Method:} Two-way fixed effects (trust + month FE); Callaway-Sant'Anna attempted with not-yet-treated controls; standard errors clustered at trust level; randomization inference with 500 permutations. ",
  "\\textbf{Sample:} Balanced panel of 122 NHS trusts reporting Type 1 A\\&E attendances in at least 60 of 94 months; 119 trusts are ever-treated (experienced a GP closure within 10km). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sprintf("Type 1 A\\&E (full sample) & %s & %s & %s & %s & %s & %s \\\\",
          format(round(beta_type1, 1), nsmall = 1),
          format(round(se_type1_level, 1), nsmall = 1),
          format(round(sd_type1_pre, 1), nsmall = 1),
          format(round(sde_type1, 4), nsmall = 4),
          format(round(se_sde_type1, 4), nsmall = 4),
          classify_sde(sde_type1)),
  sprintf("Type 1 A\\&E (post-COVID) & %s & %s & %s & %s & %s & %s \\\\",
          format(round(beta_postcovid, 1), nsmall = 1),
          format(round(se_postcovid_level, 1), nsmall = 1),
          format(round(sd_type1_postcovid_pre, 1), nsmall = 1),
          format(round(sde_postcovid, 4), nsmall = 4),
          format(round(se_sde_postcovid, 4), nsmall = 4),
          classify_sde(sde_postcovid)),
  sprintf("Total A\\&E (full sample) & %s & %s & %s & %s & %s & %s \\\\",
          format(round(beta_total, 1), nsmall = 1),
          format(round(se_total_level, 1), nsmall = 1),
          format(round(sd_total_pre, 1), nsmall = 1),
          format(round(sde_total, 4), nsmall = 4),
          format(round(se_sde_total, 4), nsmall = 4),
          classify_sde(sde_total)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
list.files(table_dir)
