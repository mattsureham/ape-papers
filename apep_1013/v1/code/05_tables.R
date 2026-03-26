# 05_tables.R — Generate LaTeX tables for apep_1013

library(dplyr)
library(tidyr)
library(fixest)
library(modelsummary)
library(kableExtra)

data_dir <- file.path(dirname(getwd()), "data")
table_dir <- file.path(dirname(getwd()), "tables")
if (!dir.exists(table_dir)) dir.create(table_dir, recursive = TRUE)

# Load data and models
sector_panel <- readRDS(file.path(data_dir, "sector_panel.rds"))
panel <- readRDS(file.path(data_dir, "product_panel.rds"))
energy_int <- readRDS(file.path(data_dir, "energy_intensity.rds"))
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Reconstruct variables
sector_panel <- sector_panel %>%
  mutate(
    treat_binary_x_post = as.integer(energy_group == "high") * post,
    treat_x_post = treat_cont * post,
    rel_year = year - 2013,
    rel_year_capped = pmin(pmax(rel_year, -5L), 8L),
    treat_hi = as.integer(energy_group == "high")
  )

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-reform descriptives by energy group
pre_stats <- sector_panel %>%
  filter(year < 2014) %>%
  group_by(energy_group) %>%
  summarise(
    `N Sectors` = n_distinct(isic2),
    `Mean Exports (\\$M)` = sprintf("%.1f", mean(total_exports / 1e6, na.rm = TRUE)),
    `SD Exports (\\$M)` = sprintf("%.1f", sd(total_exports / 1e6, na.rm = TRUE)),
    `Mean Log Exports` = sprintf("%.2f", mean(log_exports, na.rm = TRUE)),
    `SD Log Exports` = sprintf("%.2f", sd(log_exports, na.rm = TRUE)),
    `Mean Energy Intensity` = sprintf("%.3f", mean(energy_intensity, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(energy_group = factor(energy_group, levels = c("high", "medium", "low")))

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Egyptian Manufacturing Exports by Energy Intensity (2005--2013)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & N Sectors & Mean Exports & SD Exports & Mean Log & SD Log & Mean Energy \\\\",
  " & & (\\$M) & (\\$M) & Exports & Exports & Intensity \\\\",
  "\\midrule"
)

for (g in c("high", "medium", "low")) {
  row <- pre_stats %>% filter(energy_group == g)
  label <- switch(g, high = "High", medium = "Medium", low = "Low")
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    label, row$`N Sectors`, row$`Mean Exports (\\$M)`, row$`SD Exports (\\$M)`,
    row$`Mean Log Exports`, row$`SD Log Exports`, row$`Mean Energy Intensity`
  ))
}

# Add full sample row
full_pre <- sector_panel %>%
  filter(year < 2014) %>%
  summarise(
    n_sec = n_distinct(isic2),
    me = sprintf("%.1f", mean(total_exports / 1e6, na.rm = TRUE)),
    sde = sprintf("%.1f", sd(total_exports / 1e6, na.rm = TRUE)),
    mle = sprintf("%.2f", mean(log_exports, na.rm = TRUE)),
    sdle = sprintf("%.2f", sd(log_exports, na.rm = TRUE)),
    mei = sprintf("%.3f", mean(energy_intensity, na.rm = TRUE))
  )

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("All & %s & %s & %s & %s & %s & %s \\\\",
          full_pre$n_sec, full_pre$me, full_pre$sde, full_pre$mle, full_pre$sdle, full_pre$mei),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-reform period (2005--2013). Exports measured in millions of current USD from UN Comtrade. Energy intensity is the energy cost share of value added, measured from pre-reform UNIDO/IEA data. High: energy intensity $>$ 0.15; Medium: 0.05--0.15; Low: $<$ 0.05. N = 180 sector-year observations (20 sectors $\\times$ 9 years).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("  tab1_summary.tex written\n")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main DiD Results ===\n")

# Refit models for clean modelsummary output
m1 <- feols(log_exports ~ treat_binary_x_post | isic2 + year,
            data = sector_panel, cluster = ~isic2)
m2 <- feols(log_exports ~ treat_x_post | isic2 + year,
            data = sector_panel, cluster = ~isic2)

sp_r <- sector_panel %>% filter(year >= 2009)
m3 <- feols(log_exports ~ treat_x_post | isic2 + year,
            data = sp_r, cluster = ~isic2)

# Sector trends
sector_panel$trend <- sector_panel$year - 2005
m4 <- feols(log_exports ~ treat_x_post + i(isic2, trend) | isic2 + year,
            data = sector_panel, cluster = ~isic2)

# Product-level
panel <- panel %>% mutate(treat_x_post = energy_intensity * post)
m5 <- feols(log_exports ~ treat_x_post | hs2 + year,
            data = panel, cluster = ~isic2)

models <- list(
  "(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5
)

cm <- c(
  "treat_binary_x_post" = "High Energy $\\times$ Post",
  "treat_x_post" = "Energy Intensity $\\times$ Post"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: isic2", "clean" = "Sector FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: hs2", "clean" = "Product FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

# Manual table 2 for clean LaTeX
fmt_coef <- function(model, varname) {
  ct <- summary(model)$coeftable
  if (varname %in% rownames(ct)) {
    b <- ct[varname, "Estimate"]
    se <- ct[varname, "Std. Error"]
    p <- ct[varname, "Pr(>|t|)"]
    stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
    return(list(coef = sprintf("%.3f%s", b, stars), se = sprintf("(%.3f)", se)))
  }
  return(list(coef = "", se = ""))
}

r1 <- lapply(models, function(m) fmt_coef(m, "treat_binary_x_post"))
r2 <- lapply(models, function(m) fmt_coef(m, "treat_x_post"))

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Energy Subsidy Reform on Egyptian Manufacturing Exports}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("High Energy $\\times$ Post & %s & & & & \\\\",
          r1[["(1)"]]$coef),
  sprintf(" & %s & & & & \\\\", r1[["(1)"]]$se),
  sprintf("Energy Intensity $\\times$ Post & & %s & %s & %s & %s \\\\",
          r2[["(2)"]]$coef, r2[["(3)"]]$coef, r2[["(4)"]]$coef, r2[["(5)"]]$coef),
  sprintf(" & & %s & %s & %s & %s \\\\",
          r2[["(2)"]]$se, r2[["(3)"]]$se, r2[["(4)"]]$se, r2[["(5)"]]$se),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5)),
  "Sector FE & Yes & Yes & Yes & Yes & \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Product FE & & & & & Yes \\\\",
  "Sector trends & & & & Yes & \\\\",
  "Sample & Full & Full & 2009+ & Full & Full \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the ISIC 2-digit sector level in parentheses. Dependent variable: log exports (current USD). Columns (1)--(4): sector-level panel (20 ISIC sectors). Column (5): product-level panel (71 HS2 codes). $^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main_results.tex"))
cat("  tab2_main_results.tex written\n")

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("=== Table 3: Event Study ===\n")

m_es <- feols(log_exports ~ i(rel_year_capped, treat_cont, ref = 0) |
                isic2 + year,
              data = sector_panel, cluster = ~isic2)

es_coefs <- as.data.frame(summary(m_es)$coeftable)
es_coefs$rel_year <- as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_coefs)))
es_coefs <- es_coefs %>%
  arrange(rel_year) %>%
  mutate(
    stars = case_when(
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.10 ~ "*",
      TRUE ~ ""
    )
  )

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of Energy Subsidy Reform on Exports}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year Relative & Coefficient & Std. Error & \\\\",
  "to Reform & & (Clustered) & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_coefs))) {
  r <- es_coefs[i, ]
  yr_label <- ifelse(r$rel_year < 0, sprintf("$t%d$", r$rel_year),
                     ifelse(r$rel_year == 0, "$t = 0$ (ref.)", sprintf("$t+%d$", r$rel_year)))
  if (r$rel_year == 0) {
    tab3_lines <- c(tab3_lines, sprintf("\\textit{%s} & --- & --- & \\\\", yr_label))
    next
  }
  tab3_lines <- c(tab3_lines, sprintf(
    "%s & %.3f%s & (%.3f) & \\\\",
    yr_label, r$Estimate, r$stars, r$`Std. Error`
  ))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%d} \\\\", nrow(sector_panel)),
  sprintf("Within $R^2$ & \\multicolumn{3}{c}{%.3f} \\\\",
          summary(m_es)$r2["r2.within"]),
  "Sector FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Coefficients on interactions of energy intensity (continuous) with year indicators, relative to 2013 ($t=0$). Standard errors clustered at the ISIC 2-digit sector level. The reference year is the last pre-reform year. $^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_event_study.tex"))
cat("  tab3_event_study.tex written\n")

# ============================================================
# TABLE 4: Robustness & Heterogeneity
# ============================================================
cat("=== Table 4: Robustness ===\n")

# Large vs small sector split
median_exports <- sector_panel %>%
  filter(year < 2014) %>%
  group_by(isic2) %>%
  summarise(mean_pre = mean(log_exports, na.rm = TRUE)) %>%
  pull(mean_pre) %>%
  median()

pre_means <- sector_panel %>%
  filter(year < 2014) %>%
  group_by(isic2) %>%
  summarise(mean_pre_exports = mean(log_exports, na.rm = TRUE))

sector_panel <- sector_panel %>%
  select(-any_of("mean_pre_exports")) %>%
  left_join(pre_means, by = "isic2") %>%
  mutate(large_sector = as.integer(mean_pre_exports > median_exports))

m_rob1 <- feols(log_exports ~ treat_x_post | isic2 + year,
                data = sector_panel %>% filter(year >= 2009), cluster = ~isic2)
m_rob2 <- feols(log_exports ~ treat_x_post + i(isic2, trend) | isic2 + year,
                data = sector_panel, cluster = ~isic2)
m_rob3 <- feols(log_exports ~ treat_x_post | isic2 + year,
                data = sector_panel %>% filter(large_sector == 1), cluster = ~isic2)
m_rob4 <- feols(log_exports ~ treat_x_post | isic2 + year,
                data = sector_panel %>% filter(large_sector == 0), cluster = ~isic2)

rob_models_list <- list(
  "(1) 2009+" = m_rob1,
  "(2) Trends" = m_rob2,
  "(3) Large" = m_rob3,
  "(4) Small" = m_rob4
)

cm_rob <- c("treat_x_post" = "Energy Intensity $\\times$ Post")

# Manual table 4
r_rob <- lapply(rob_models_list, function(m) fmt_coef(m, "treat_x_post"))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks and Heterogeneity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & 2009+ & Sector Trends & Large Sectors & Small Sectors \\\\",
  "\\midrule",
  sprintf("Energy Intensity $\\times$ Post & %s & %s & %s & %s \\\\",
          r_rob[["(1) 2009+"]]$coef, r_rob[["(2) Trends"]]$coef,
          r_rob[["(3) Large"]]$coef, r_rob[["(4) Small"]]$coef),
  sprintf(" & %s & %s & %s & %s \\\\",
          r_rob[["(1) 2009+"]]$se, r_rob[["(2) Trends"]]$se,
          r_rob[["(3) Large"]]$se, r_rob[["(4) Small"]]$se),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(m_rob1), nobs(m_rob2), nobs(m_rob3), nobs(m_rob4)),
  "Sector FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable: log exports. Standard errors clustered at ISIC 2-digit level. Column (1): sample restricted to 2009--2023. Column (2): includes sector-specific linear trends. Columns (3)--(4): sample split at median pre-reform export level. Wild cluster bootstrap (Webb weights, 9,999 draws) $p$-value for the baseline specification: 0.163. $^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("  tab4_robustness.tex written\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_y <- sd(sector_panel$log_exports, na.rm = TRUE)
sd_x <- sd(sector_panel$treat_cont, na.rm = TRUE)
sd_y_pre <- sd(sector_panel$log_exports[sector_panel$year < 2014], na.rm = TRUE)

# Main specification: continuous DiD
beta_main <- results$continuous_did$coef
se_main <- results$continuous_did$se

sde_main <- beta_main * sd_x / sd_y_pre
se_sde_main <- se_main * sd_x / sd_y_pre

# Restricted sample
beta_r <- rob_results$restricted_sample$coef
se_r <- rob_results$restricted_sample$se
sde_r <- beta_r * sd_x / sd_y_pre
se_sde_r <- se_r * sd_x / sd_y_pre

# Large sectors
beta_large <- coef(m_rob3)["treat_x_post"]
se_large <- sqrt(vcov(m_rob3)["treat_x_post", "treat_x_post"])
sd_y_large <- sd(sector_panel$log_exports[sector_panel$large_sector == 1 & sector_panel$year < 2014], na.rm = TRUE)
sde_large <- beta_large * sd_x / sd_y_large
se_sde_large <- se_large * sd_x / sd_y_large

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate negative", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_rows <- data.frame(
  Outcome = c("Log exports (pooled)", "Log exports (2009+)", "Log exports (large sectors)"),
  Beta = c(beta_main, beta_r, beta_large),
  SE = c(se_main, se_r, se_large),
  SD_Y = c(sd_y_pre, sd_y_pre, sd_y_large),
  SDE = c(sde_main, sde_r, sde_large),
  SE_SDE = c(se_sde_main, se_sde_r, se_sde_large),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Egypt. ",
  "\\textbf{Research question:} Does the removal of energy subsidies for industrial users reduce manufacturing export activity in energy-intensive sectors relative to non-energy-intensive sectors? ",
  "\\textbf{Policy mechanism:} Egypt's July 2014 energy price liberalization raised industrial electricity prices by 25--40\\% and heavy fuel oil prices by 64--80\\%, ",
  "eliminating subsidies that disproportionately benefited energy-intensive manufacturing sectors (cement, steel, ceramics, chemicals, petroleum refining). ",
  "\\textbf{Outcome definition:} Log of annual export value (current USD) at the ISIC Rev.4 2-digit manufacturing sector level, constructed from customs-reported trade data. ",
  "\\textbf{Treatment:} Continuous; pre-reform energy cost share of value added by sector (range: 0.02 for tobacco to 0.55 for petroleum refining). ",
  "\\textbf{Data:} UN Comtrade HS 2-digit exports for Egypt, mapped to 20 ISIC 2-digit manufacturing sectors, 2005--2023. N = 380 sector-year observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with sector and year fixed effects. Standard errors clustered at ISIC 2-digit level (20 clusters). Wild cluster bootstrap reported. ",
  "\\textbf{Sample:} Manufacturing sectors only (ISIC 10--32); agricultural and mineral extraction excluded. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of energy intensity. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Panel A: Pooled
# Panel B: Heterogeneous (large vs small sectors)
beta_small <- coef(m_rob4)["treat_x_post"]
se_small <- sqrt(vcov(m_rob4)["treat_x_post", "treat_x_post"])
sd_y_small <- sd(sector_panel$log_exports[sector_panel$large_sector == 0 & sector_panel$year < 2014], na.rm = TRUE)
sde_small <- beta_small * sd_x / sd_y_small
se_sde_small <- se_small * sd_x / sd_y_small

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log exports (full sample) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
  sprintf("Log exports (2009--2023) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_r, se_r, sd_y_pre, sde_r, se_sde_r, classify_sde(sde_r)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-reform export level)}} \\\\",
  sprintf("Large export sectors & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_large, se_large, sd_y_large, sde_large, se_sde_large, classify_sde(sde_large)),
  sprintf("Small export sectors & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_small, se_small, sd_y_small, sde_small, se_sde_small, classify_sde(sde_small)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  tabF1_sde.tex written\n")

cat("\n=== All tables generated ===\n")
cat("Files in", table_dir, ":\n")
print(list.files(table_dir))
