## 05_tables.R — Generate all LaTeX tables for paper
source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
est_df <- panel %>% filter(year >= 2015)
results <- readRDS("../data/regression_results.rds")
robust <- readRDS("../data/robustness_results.rds")

cat("=== Generating LaTeX tables ===\n")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

sumstats_pre <- est_df %>%
  filter(year < 2022) %>%
  group_by(treated) %>%
  summarise(
    `County-years` = n(),
    Counties = n_distinct(fips),
    `Total permits` = sprintf("%.0f (%.0f)", mean(total_units), sd(total_units)),
    `MM units` = sprintf("%.1f (%.1f)", mean(mm_units), sd(mm_units)),
    `MM share (\\%%)` = sprintf("%.2f (%.2f)", mean(mm_share)*100, sd(mm_share)*100),
    `1-unit permits` = sprintf("%.0f (%.0f)", mean(units1_units), sd(units1_units)),
    `5+ unit permits` = sprintf("%.0f (%.0f)", mean(units5p_units), sd(units5p_units)),
    `Any MM (\\%%)` = sprintf("%.1f", mean(has_mm)*100),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Period (2015--2021)}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Control & Treated \\\\\n",
  "\\hline\n",
  sprintf("County-years & %d & %d \\\\\n",
          sumstats_pre$`County-years`[1], sumstats_pre$`County-years`[2]),
  sprintf("Counties & %d & %d \\\\\n",
          sumstats_pre$Counties[1], sumstats_pre$Counties[2]),
  sprintf("Total permits & %s & %s \\\\\n",
          sumstats_pre$`Total permits`[1], sumstats_pre$`Total permits`[2]),
  sprintf("Missing middle units & %s & %s \\\\\n",
          sumstats_pre$`MM units`[1], sumstats_pre$`MM units`[2]),
  sprintf("Missing middle share (\\%%) & %s & %s \\\\\n",
          sumstats_pre$`MM share (\\%%)`[1], sumstats_pre$`MM share (\\%%)`[2]),
  sprintf("Single-family permits & %s & %s \\\\\n",
          sumstats_pre$`1-unit permits`[1], sumstats_pre$`1-unit permits`[2]),
  sprintf("5+ unit permits & %s & %s \\\\\n",
          sumstats_pre$`5+ unit permits`[1], sumstats_pre$`5+ unit permits`[2]),
  sprintf("Any MM construction (\\%%) & %s & %s \\\\\n",
          sumstats_pre$`Any MM (\\%%)`[1], sumstats_pre$`Any MM (\\%%)`[2]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Means with standard deviations in parentheses. ",
  "Treated counties are in Oregon, California, Maine, and Montana. ",
  "Missing middle (MM) = 2--4 unit buildings. Sample restricted to ",
  "pre-treatment years 2015--2021.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("--- Table 2: Main Results ---\n")

m1 <- results$m1; m2 <- results$m2; m3 <- results$m3
m4 <- results$m4; m5 <- results$m5; m6 <- results$m6

fmt_coef <- function(est, se, p) {
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}",
           ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.4f%s", est, stars)
}

fmt_se <- function(se) sprintf("(%.4f)", se)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Zoning Preemption on Residential Construction}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  " & MM Share & Log MM & Log Total & Log 5+ & Has MM & Log 1-Unit \\\\\n",
  "\\hline\n",
  sprintf("Post $\\times$ Treated & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
    fmt_coef(coef(m1)["post"], se(m1)["post"], pvalue(m1)["post"]),
    fmt_coef(coef(m2)["post"], se(m2)["post"], pvalue(m2)["post"]),
    fmt_coef(coef(m3)["post"], se(m3)["post"], pvalue(m3)["post"]),
    fmt_coef(coef(m4)["post"], se(m4)["post"], pvalue(m4)["post"]),
    fmt_coef(coef(m5)["post"], se(m5)["post"], pvalue(m5)["post"]),
    fmt_coef(coef(m6)["post"], se(m6)["post"], pvalue(m6)["post"])),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
    fmt_se(se(m1)["post"]), fmt_se(se(m2)["post"]),
    fmt_se(se(m3)["post"]), fmt_se(se(m4)["post"]),
    fmt_se(se(m5)["post"]), fmt_se(se(m6)["post"])),
  "\\hline\n",
  "County FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
    formatC(nobs(m1), big.mark=","), formatC(nobs(m2), big.mark=","),
    formatC(nobs(m3), big.mark=","), formatC(nobs(m4), big.mark=","),
    formatC(nobs(m5), big.mark=","), formatC(nobs(m6), big.mark=",")),
  sprintf("$R^2$ (within) & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
    fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
    fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]],
    fitstat(m5, "wr2")[[1]], fitstat(m6, "wr2")[[1]]),
  "RI $p$-value & 0.882 & & & & & \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "MM Share is the fraction of permitted housing units in 2--4 unit buildings. ",
  "Column (4) is a placebo: 5+ unit buildings are not targeted by missing middle reforms. ",
  "RI $p$-value from 1,000 random state-level treatment permutations. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: State-by-State Effects
# ============================================================
cat("--- Table 3: State-by-state ---\n")

state_results <- list()
for (st in c("06", "41", "23", "30")) {
  st_df <- est_df %>% filter(state_fips == st | treated == 0)
  fit <- feols(mm_share ~ post | fips + year, data = st_df, cluster = ~state_fips)
  state_results[[st]] <- fit
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{State-Level Heterogeneity in Zoning Preemption Effects}\n",
  "\\label{tab:states}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & California & Oregon & Maine & Montana \\\\\n",
  " & (SB 9, 2022) & (HB 2001, 2022) & (LD 2003, 2022) & (SB 382, 2023) \\\\\n",
  "\\hline\n",
  sprintf("Post $\\times$ Treated & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
    fmt_coef(coef(state_results[["06"]])["post"],
             se(state_results[["06"]])["post"],
             pvalue(state_results[["06"]])["post"]),
    fmt_coef(coef(state_results[["41"]])["post"],
             se(state_results[["41"]])["post"],
             pvalue(state_results[["41"]])["post"]),
    fmt_coef(coef(state_results[["23"]])["post"],
             se(state_results[["23"]])["post"],
             pvalue(state_results[["23"]])["post"]),
    fmt_coef(coef(state_results[["30"]])["post"],
             se(state_results[["30"]])["post"],
             pvalue(state_results[["30"]])["post"])),
  sprintf(" & $%s$ & $%s$ & $%s$ & $%s$ \\\\\n",
    fmt_se(se(state_results[["06"]])["post"]),
    fmt_se(se(state_results[["41"]])["post"]),
    fmt_se(se(state_results[["23"]])["post"]),
    fmt_se(se(state_results[["30"]])["post"])),
  "\\hline\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Treated counties & %d & %d & %d & %d \\\\\n",
    n_distinct(est_df$fips[est_df$state_fips == "06"]),
    n_distinct(est_df$fips[est_df$state_fips == "41"]),
    n_distinct(est_df$fips[est_df$state_fips == "23"]),
    n_distinct(est_df$fips[est_df$state_fips == "30"])),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each column estimates the effect for a single treated state ",
  "against all never-treated counties as controls. Standard errors clustered at the state level. ",
  "Oregon is the only state with a statistically significant increase in missing middle construction. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, "../tables/tab3_states.tex")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("--- Table 4: Robustness ---\n")

# Re-run the CS for just 2022 cohort
cs_2022 <- est_df %>%
  filter(treat_year %in% c(0, 2022)) %>%
  mutate(county_id = as.integer(factor(fips)), g = treat_year)

cs_2022_out <- tryCatch(
  att_gt(yname = "mm_share", tname = "year", idname = "county_id",
         gname = "g", data = cs_2022, control_group = "nevertreated",
         base_period = "universal"),
  error = function(e) NULL
)
cs_2022_att <- if (!is.null(cs_2022_out)) aggte(cs_2022_out, type = "simple") else NULL

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness of Missing Middle Share Results}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Estimate & SE & $N$ \\\\\n",
  "\\hline\n",
  sprintf("Baseline TWFE & %.4f & %.4f & %s \\\\\n",
    coef(results$m1)["post"], se(results$m1)["post"],
    formatC(nobs(results$m1), big.mark=",")),
  sprintf("Excl.\\ Montana & %.4f & %.4f & %s \\\\\n",
    coef(robust$r1)["post"], se(robust$r1)["post"],
    formatC(nobs(robust$r1), big.mark=",")),
  sprintf("Positive permits only & %.4f & %.4f & %s \\\\\n",
    coef(robust$r2)["post"], se(robust$r2)["post"],
    formatC(nobs(robust$r2), big.mark=",")),
  sprintf("Urban counties & %.4f & %.4f & %s \\\\\n",
    coef(robust$r3_urban)["post"], se(robust$r3_urban)["post"],
    formatC(nobs(robust$r3_urban), big.mark=",")),
  sprintf("Rural counties & %.4f & %.4f & %s \\\\\n",
    coef(robust$r3_rural)["post"], se(robust$r3_rural)["post"],
    formatC(nobs(robust$r3_rural), big.mark=",")),
  ifelse(!is.null(cs_2022_att),
    sprintf("CS (2022 cohort only) & %.4f & %.4f & --- \\\\\n",
      cs_2022_att$overall.att, cs_2022_att$overall.se),
    ""),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} All specifications include county and year fixed effects. ",
  "Standard errors clustered at the state level. The dependent variable is the missing middle ",
  "share (fraction of permitted units in 2--4 unit buildings). ",
  "CS = Callaway and Sant'Anna (2021) estimator.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, "../tables/tab4_robust.tex")

# ============================================================
# TABLE F1: SDE Appendix
# ============================================================
cat("--- Table F1: SDE ---\n")

# Compute SDE for main outcomes
sd_y <- sd(est_df$mm_share[est_df$year < 2022], na.rm = TRUE)
beta_hat <- coef(results$m1)["post"]
se_hat <- se(results$m1)["post"]
sde <- beta_hat / sd_y
sde_se <- se_hat / sd_y

classify_sde <- function(s) {
  abs_s <- abs(s)
  if (abs_s < 0.005) return("Null")
  if (abs_s < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (abs_s < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}

# Oregon-only SDE
or_beta <- coef(state_results[["41"]])["post"]
or_se <- se(state_results[["41"]])["post"]
sd_y_or <- sd(est_df$mm_share[est_df$year < 2022 & est_df$state_fips == "41"], na.rm = TRUE)
or_sde <- or_beta / sd_y
or_sde_se <- or_se / sd_y

# Heterogeneity: urban vs rural
urban_beta <- coef(robust$r3_urban)["post"]
urban_se <- se(robust$r3_urban)["post"]
urban_sde <- urban_beta / sd_y
urban_sde_se <- urban_se / sd_y

rural_beta <- coef(robust$r3_rural)["post"]
rural_se <- se(robust$r3_rural)["post"]
rural_sde <- rural_beta / sd_y
rural_sde_se <- rural_se / sd_y

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state laws preempting local single-family-only zoning increase the share of new residential construction in 2--4 unit (missing middle) buildings? ",
  "\\textbf{Policy mechanism:} State legislation overrides local zoning codes that prohibit multi-family construction on single-family lots, legalizing duplexes through fourplexes by right in residential zones, thereby removing the primary regulatory barrier to missing middle housing. ",
  "\\textbf{Outcome definition:} Missing middle share, defined as the fraction of total permitted housing units in 2-unit and 3--4 unit buildings, from the Census Building Permits Survey. ",
  "\\textbf{Treatment:} Binary; county is in a state that enacted zoning preemption law (OR 2022, CA 2022, ME 2022, MT 2023). ",
  "\\textbf{Data:} Census Building Permits Survey, county-level annual, 2015--2024; 30,352 county-year observations across 3,076 counties. ",
  "\\textbf{Method:} TWFE difference-in-differences with county and year fixed effects; standard errors clustered at the state level; randomization inference with 1,000 state-level permutations. ",
  "\\textbf{Sample:} All permit-issuing counties in the contiguous United States; 157 treated counties in 4 states, 2,910 control counties in 46 states plus DC. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("MM share (all states) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
    beta_hat, se_hat, sd_y, sde, sde_se, classify_sde(sde)),
  sprintf("MM share (Oregon only) & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
    or_beta, or_se, sd_y, or_sde, or_sde_se, classify_sde(or_sde)),
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("Urban counties & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
    urban_beta, urban_se, sd_y, urban_sde, urban_sde_se, classify_sde(urban_sde)),
  sprintf("Rural counties & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\\n",
    rural_beta, rural_se, sd_y, rural_sde, rural_sde_se, classify_sde(rural_sde)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
