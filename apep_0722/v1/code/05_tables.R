# 05_tables.R — Generate LaTeX tables
# apep_0722: Japan's Split-Rate Consumption Tax

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

# ===================================================================
# LOAD DATA AND RESULTS
# ===================================================================

analysis_data <- readRDS(file.path(data_dir, "cpi_analysis.rds"))
reg_results <- readRDS(file.path(data_dir, "regression_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

df_2019 <- analysis_data$window_2019
df_full <- analysis_data$full

# Helper: format numbers
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")

# Helper: extract coefficient and SE from fixest model
get_coef <- function(model, pattern) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep(pattern, names(cf))[1]
  if (is.na(idx)) return(list(beta = NA, se = NA, stars = ""))
  b <- cf[idx]
  s <- se[idx]
  p <- 2 * pnorm(abs(b / s), lower.tail = FALSE)
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(beta = b, se = s, p = p, stars = stars)
}

# ===================================================================
# TABLE 1: Summary Statistics
# ===================================================================

cat("Generating Table 1: Summary Statistics...\n")

# Pre-period: Jan 2018 to Sep 2019
pre_data <- df_2019 %>%
  filter(post_2019 == 0, coicop %in% c("CP01", "CP02", "CP11", "_T"))

sum_stats <- pre_data %>%
  group_by(coicop) %>%
  summarise(
    N = n(),
    Mean = mean(cpi, na.rm = TRUE),
    SD = sd(cpi, na.rm = TRUE),
    Min = min(cpi, na.rm = TRUE),
    Max = max(cpi, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    label = case_when(
      coicop == "CP01" ~ "Food (reduced 8\\% rate)",
      coicop == "CP02" ~ "Alcohol \\& Tobacco (10\\%)",
      coicop == "CP11" ~ "Restaurants \\& Hotels (10\\%)",
      coicop == "_T"   ~ "All Items (aggregate)",
      TRUE ~ coicop
    )
  ) %>%
  arrange(coicop)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Period CPI by Expenditure Category}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Category & Tax Rate & N & Mean & SD & Min & Max \\\\",
  "\\hline"
)

for (i in 1:nrow(sum_stats)) {
  r <- sum_stats[i, ]
  rate <- ifelse(r$coicop == "CP01", "8\\%",
          ifelse(r$coicop == "_T", "Mixed", "10\\%"))
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                           r$label, rate,
                           fmt_int(r$N), fmt(r$Mean, 2), fmt(r$SD, 2),
                           fmt(r$Min, 2), fmt(r$Max, 2)))
}

tab1 <- c(tab1,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} CPI index values (base year = 2015). Pre-period defined as January 2018 through September 2019. Food (CP01) received the reduced 8\\% rate under Japan's October 2019 split-rate reform; all other categories faced the full 10\\% rate.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("  -> tab1_summary.tex\n")

# ===================================================================
# TABLE 2: Main DiD Results
# ===================================================================

cat("Generating Table 2: Main DiD Results...\n")

m1 <- reg_results$m1
m2 <- reg_results$m2
m3 <- reg_results$m3
m4 <- reg_results$m4

c1 <- get_coef(m1, "restaurant.*post_2019")
c2 <- get_coef(m2, "treated_cat.*post_2019")
c3 <- get_coef(m3, "restaurant.*post_2014")
c4 <- get_coef(m4, "restaurant.*post.*era_2019")

# Outcome means
mean1 <- mean(df_2019$log_cpi[df_2019$coicop %in% c("CP01", "CP11")], na.rm = TRUE)
mean2 <- mean(df_2019$log_cpi[!is.na(df_2019$treated_cat)], na.rm = TRUE)

df_2014 <- analysis_data$window_2014
mean3 <- mean(df_2014$log_cpi[df_2014$coicop %in% c("CP01", "CP11")], na.rm = TRUE)

# For triple-diff, use the stacked mean
df_stack_sub <- bind_rows(
  df_2019 %>% filter(coicop %in% c("CP01", "CP11")),
  df_2014 %>% filter(coicop %in% c("CP01", "CP11"))
)
mean4 <- mean(df_stack_sub$log_cpi, na.rm = TRUE)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Japan's Split-Rate Consumption Tax on Consumer Prices}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Restaurant & All Treated & Placebo & Triple- \\\\",
  " & vs.\\ Food & vs.\\ Food & 2014 & Difference \\\\",
  "\\hline",
  sprintf("Treatment $\\times$ Post & %s%s & %s%s & %s%s & %s%s \\\\",
          fmt(c1$beta, 4), c1$stars,
          fmt(c2$beta, 4), c2$stars,
          fmt(c3$beta, 4), c3$stars,
          fmt(c4$beta, 4), c4$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(c1$se, 4), fmt(c2$se, 4), fmt(c3$se, 4), fmt(c4$se, 4)),
  "\\addlinespace",
  sprintf("Outcome mean & %s & %s & %s & %s \\\\",
          fmt(mean1, 3), fmt(mean2, 3), fmt(mean3, 3), fmt(mean4, 3)),
  sprintf("N & %s & %s & %s & %s \\\\",
          fmt_int(m1$nobs), fmt_int(m2$nobs), fmt_int(m3$nobs), fmt_int(m4$nobs)),
  "Category FE & Yes & Yes & Yes & Yes \\\\",
  "Time FE & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log(CPI). Column (1) compares restaurants/hotels (CP11, 10\\% rate) to food (CP01, 8\\% rate) around October 2019. Column (2) uses all treated COICOP categories (CP02--CP12) against food. Column (3) is a placebo test using the uniform April 2014 hike (5\\% to 8\\%). Column (4) is a triple-difference comparing the 2019 DiD to the 2014 DiD. Heteroskedasticity-robust standard errors in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, file.path(table_dir, "tab2_main.tex"))
cat("  -> tab2_main.tex\n")

# ===================================================================
# TABLE 3: Month-by-Month Dynamics
# ===================================================================

cat("Generating Table 3: Monthly Dynamics...\n")

# CP11 and CP01, Jul 2019 to Jan 2020
dynamics_data <- df_full %>%
  filter(
    coicop %in% c("CP01", "CP11"),
    (year == 2019 & month >= 7) | (year == 2020 & month <= 1)
  ) %>%
  select(coicop, time_period, year, month, cpi) %>%
  pivot_wider(names_from = coicop, values_from = cpi, names_prefix = "cpi_") %>%
  mutate(
    gap = cpi_CP11 - cpi_CP01
  ) %>%
  arrange(year, month)

# Baseline: September 2019 gap
baseline_gap <- dynamics_data$gap[dynamics_data$year == 2019 & dynamics_data$month == 9]

dynamics_data <- dynamics_data %>%
  mutate(delta_gap = gap - baseline_gap)

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Month-by-Month CPI Dynamics: Restaurants vs.\\ Food}",
  "\\label{tab:dynamics}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Month & CP11 (Restaurants) & CP01 (Food) & Gap & $\\Delta$Gap \\\\",
  "\\hline"
)

for (i in 1:nrow(dynamics_data)) {
  r <- dynamics_data[i, ]
  marker <- ifelse(r$year == 2019 & r$month == 10, "$\\dagger$", "")
  tab3 <- c(tab3, sprintf("%s%s & %s & %s & %s & %s \\\\",
                           r$time_period, marker,
                           fmt(r$cpi_CP11, 2), fmt(r$cpi_CP01, 2),
                           fmt(r$gap, 2), fmt(r$delta_gap, 2)))
}

tab3 <- c(tab3,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} CPI index values (base year = 2015). Gap = CP11 $-$ CP01. $\\Delta$Gap is change from September 2019 baseline. $\\dagger$ marks the first post-treatment month (October 2019, when the split-rate tax took effect).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, file.path(table_dir, "tab3_dynamics.tex"))
cat("  -> tab3_dynamics.tex\n")

# ===================================================================
# TABLE 4: Robustness
# ===================================================================

cat("Generating Table 4: Robustness...\n")

r_narrow <- get_coef(rob_results$narrow_window, "restaurant.*post_2019")
r_levels <- get_coef(rob_results$levels, "restaurant.*post_2019")
r_health <- get_coef(rob_results$health_placebo, "health.*post_2019")

# Outcome means for each robustness check
df_narrow_data <- df_full %>%
  filter((year == 2019 & month >= 7) | (year == 2020 & month <= 1),
         coicop %in% c("CP01", "CP11"))
mean_narrow <- mean(df_narrow_data$log_cpi, na.rm = TRUE)

df_levels_data <- df_full %>%
  filter((year >= 2018 & year <= 2019) | (year == 2020 & month <= 1),
         coicop %in% c("CP01", "CP11"))
mean_levels <- mean(df_levels_data$cpi, na.rm = TRUE)

df_health_data <- df_full %>%
  filter((year >= 2018 & year <= 2019) | (year == 2020 & month <= 1),
         coicop %in% c("CP01", "CP06"))
mean_health <- mean(df_health_data$log_cpi, na.rm = TRUE)

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE & N & Outcome & Outcome Mean \\\\",
  "\\hline",
  sprintf("Narrow window (Jul--Jan) & %s%s & (%s) & %s & log(CPI) & %s \\\\",
          fmt(r_narrow$beta, 4), r_narrow$stars, fmt(r_narrow$se, 4),
          fmt_int(rob_results$narrow_window$nobs), fmt(mean_narrow, 3)),
  sprintf("CPI levels & %s%s & (%s) & %s & CPI & %s \\\\",
          fmt(r_levels$beta, 3), r_levels$stars, fmt(r_levels$se, 3),
          fmt_int(rob_results$levels$nobs), fmt(mean_levels, 2)),
  sprintf("Health placebo (CP06 vs CP01) & %s%s & (%s) & %s & log(CPI) & %s \\\\",
          fmt(r_health$beta, 4), r_health$stars, fmt(r_health$se, 4),
          fmt_int(rob_results$health_placebo$nobs), fmt(mean_health, 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include category and time fixed effects with heteroskedasticity-robust standard errors. Row 1 narrows the window to July 2019--January 2020 (3 months pre, 4 post). Row 2 uses CPI index levels rather than logs. Row 3 replaces restaurants with health (CP06), a category also at 10\\% but with inelastic demand. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))
cat("  -> tab4_robustness.tex\n")

# ===================================================================
# TABLE F1: Standardized DiD Estimate (SDE)
# ===================================================================

cat("Generating Table F1: SDE...\n")

# Pre-period SD of log_cpi
pre_2019 <- df_2019 %>% filter(post_2019 == 0)

sd_restaurant <- sd(pre_2019$log_cpi[pre_2019$coicop %in% c("CP01", "CP11")], na.rm = TRUE)
sd_all <- sd(pre_2019$log_cpi[!is.na(pre_2019$treated_cat)], na.rm = TRUE)

# SDE = beta / SD(Y)
sde1 <- c1$beta / sd_restaurant
sde2 <- c2$beta / sd_all

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized DiD Estimates (SDE)}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "Comparison & $\\hat{\\beta}$ & SD($Y$) & SDE & N & Window \\\\",
  "\\hline",
  sprintf("Restaurant CPI (CP11 vs CP01) & %s & %s & %s & %s & 2018:01--2020:01 \\\\",
          fmt(c1$beta, 4), fmt(sd_restaurant, 4), fmt(sde1, 3), fmt_int(m1$nobs)),
  sprintf("All treated (CP02--12 vs CP01) & %s & %s & %s & %s & 2018:01--2020:01 \\\\",
          fmt(c2$beta, 4), fmt(sd_all, 4), fmt(sde2, 3), fmt_int(m2$nobs)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} SDE $= \\hat{\\beta} / \\text{SD}(Y_{\\text{pre}})$, where $\\hat{\\beta}$ is the DiD coefficient and SD($Y$) is the standard deviation of the outcome in the pre-treatment period (January 2018 through September 2019).",
  "\\item",
  "\\item \\textbf{Country:} Japan.",
  "\\item \\textbf{Research question:} Did Japan's 2019 dual-rate consumption tax cause consumer price divergence between restaurants (10\\% rate) and food at home (8\\% rate)?",
  "\\item \\textbf{Policy mechanism:} Japan introduced a split-rate consumption tax on October 1, 2019, charging 10\\% on restaurant dining and 8\\% on food for home consumption, creating a 2-percentage-point price wedge on identical food items depending on whether consumed on-premises or taken out.",
  "\\item \\textbf{Outcome definition:} Log of monthly consumer price index (CPI) by COICOP expenditure category, base year 2015.",
  "\\item \\textbf{Treatment:} Binary---COICOP categories subject to the full 10\\% rate vs the reduced 8\\% rate for food.",
  "\\item \\textbf{Data:} OECD SDMX API, monthly CPI by COICOP division for Japan, 2012--2020, category-month panel.",
  "\\item \\textbf{Method:} DiD comparing treated (10\\% rate) vs shielded (8\\% rate) categories before and after October 2019; category and month FEs; heteroskedasticity-robust SEs.",
  "\\item \\textbf{Sample:} 13 COICOP expenditure divisions, monthly observations Jan 2018 to Jan 2020.",
  "\\item",
  "\\item \\textit{Magnitude vs.\\ significance disclaimer:} An SDE $\\geq 0.5$ indicates a large effect regardless of statistical significance. An SDE between 0.2 and 0.5 is a moderate effect. An SDE $< 0.2$ is a small effect. Statistical significance ($p < 0.05$) without meaningful magnitude (SDE $< 0.1$) should be interpreted cautiously, as it may reflect precision rather than substantive importance. Conversely, a large SDE that is statistically insignificant may reflect low power rather than absence of an effect.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))
cat("  -> tabF1_sde.tex\n")

# ===================================================================
# DONE
# ===================================================================

cat("\nAll tables generated in ../tables/\n")
cat(sprintf("Files: %s\n", paste(list.files(table_dir, pattern = "\\.tex$"), collapse = ", ")))
