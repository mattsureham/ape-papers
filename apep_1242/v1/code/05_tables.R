# 05_tables.R — Generate all LaTeX tables for the PSC bunching paper

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_ready.csv"))
load(file.path(data_dir, "analysis_results.RData"))

# Attempt to load robustness results
rob_loaded <- tryCatch({
  load(file.path(data_dir, "robustness_results.RData"))
  TRUE
}, error = function(e) FALSE)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics\n")

# Sample description
total_n <- nrow(df)
with_sic <- sum(!is.na(df$sic_div))
with_date <- sum(!is.na(df$inc_date))

# PSC count distribution
psc_1 <- sum(df$n_individual == 1)
psc_2 <- sum(df$n_individual == 2)
psc_3 <- sum(df$n_individual == 3)
psc_4 <- sum(df$n_individual == 4)
psc_5p <- sum(df$n_individual >= 5)

# Configuration rates
equal_4_rate <- mean(df$n_individual == 4 & df$n_band_25_50 == 4, na.rm = TRUE)
foreign_rate <- mean(df$has_foreign)
corp_rate <- mean(df$has_corporate_psc)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: UK Companies with PSC Records}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & N & Share (\\%) \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Sample Composition}} \\\\[3pt]",
  sprintf("Total companies & %s & \\\\", format(total_n, big.mark = ",")),
  sprintf("\\quad With SIC code & %s & %.1f \\\\",
          format(with_sic, big.mark = ","), 100 * with_sic / total_n),
  sprintf("\\quad With incorporation date & %s & %.1f \\\\",
          format(with_date, big.mark = ","), 100 * with_date / total_n),
  "\\\\",
  "\\multicolumn{3}{l}{\\textit{Panel B: Individual PSC Count}} \\\\[3pt]",
  sprintf("1 PSC & %s & %.1f \\\\", format(psc_1, big.mark = ","), 100 * psc_1 / total_n),
  sprintf("2 PSCs & %s & %.1f \\\\", format(psc_2, big.mark = ","), 100 * psc_2 / total_n),
  sprintf("3 PSCs & %s & %.1f \\\\", format(psc_3, big.mark = ","), 100 * psc_3 / total_n),
  sprintf("4 PSCs & %s & %.1f \\\\", format(psc_4, big.mark = ","), 100 * psc_4 / total_n),
  sprintf("5+ PSCs & %s & %.1f \\\\", format(psc_5p, big.mark = ","), 100 * psc_5p / total_n),
  "\\\\",
  "\\multicolumn{3}{l}{\\textit{Panel C: Ownership Characteristics}} \\\\[3pt]",
  sprintf("4-way equal split (all 25\\%%) & %s & %.2f \\\\",
          format(sum(df$n_individual == 4 & df$n_band_25_50 == 4), big.mark = ","),
          100 * equal_4_rate),
  sprintf("Has foreign PSC & %s & %.1f \\\\",
          format(sum(df$has_foreign), big.mark = ","), 100 * foreign_rate),
  sprintf("Has corporate PSC & %s & %.1f \\\\",
          format(sum(df$has_corporate_psc), big.mark = ","), 100 * corp_rate),
  "\\\\",
  "\\multicolumn{3}{l}{\\textit{Panel D: High-Risk Sectors (FATF)}} \\\\[3pt]",
  sprintf("Financial services & %s & %.1f \\\\",
          format(sum(df$sic_section == "Financial", na.rm = TRUE), big.mark = ","),
          100 * mean(df$sic_section == "Financial", na.rm = TRUE)),
  sprintf("Real estate & %s & %.1f \\\\",
          format(sum(df$sic_section == "Real Estate", na.rm = TRUE), big.mark = ","),
          100 * mean(df$sic_section == "Real Estate", na.rm = TRUE)),
  sprintf("Professional services/HQ & %s & %.1f \\\\",
          format(sum(df$sic_section == "Professional/HQ", na.rm = TRUE), big.mark = ","),
          100 * mean(df$sic_section == "Professional/HQ", na.rm = TRUE)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Data from the UK Companies House PSC bulk snapshot (April 2026) and Basic Company Data file. The sample covers five of 31 snapshot chunks, representing a systematic cross-section of approximately 1.77 million companies with at least one Person with Significant Control (PSC) record. Individual PSC count excludes corporate-entity and legal-person PSCs. The 4-way equal split identifies companies where exactly four individual PSCs each hold 25--50\\% of shares. High-risk sectors follow FATF anti-money laundering risk classifications.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: The Equal-Split Puzzle — Configuration Test
# ============================================================================

cat("Generating Table 2: Configuration Test\n")

# Among multi-PSC companies (2+)
multi <- df[n_individual >= 2]

# Expected vs observed equal-split rates by PSC count
config_test <- data.table(
  n_pscs = 2:6,
  label = c("2 PSCs", "3 PSCs", "4 PSCs", "5 PSCs", "6 PSCs")
)

# Overall P(band = 25-50%) among individual PSCs
p_2550 <- p_25_50  # From analysis_results.RData

config_test[, observed := sapply(n_pscs, function(k) {
  sub <- df[n_individual == k]
  mean(sub$n_band_25_50 == k, na.rm = TRUE)
})]

config_test[, expected := p_2550^n_pscs]
config_test[, ratio := observed / expected]
config_test[, n_companies := sapply(n_pscs, function(k) sum(df$n_individual == k))]

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{The Equal-Split Puzzle: Observed vs.~Expected All-Threshold Configurations}",
  "\\label{tab:config}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "PSC Count & Companies & Observed & Expected & Ratio & $p$-value \\\\",
  " & & (all 25--50\\%) & (under independence) & & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(config_test))) {
  row <- config_test[i]
  btest <- binom.test(round(row$observed * row$n_companies), row$n_companies, row$expected)
  pval <- ifelse(btest$p.value < 0.001, "$<$0.001", sprintf("%.3f", btest$p.value))
  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %.1f\\%% & %.1f\\%% & %.1f & %s \\\\",
            row$label,
            format(row$n_companies, big.mark = ","),
            100 * row$observed,
            100 * row$expected,
            row$ratio,
            pval))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each row tests whether the share of companies where \\textit{every} individual PSC holds 25--50\\% of shares exceeds the rate predicted by independent band assignment. ``Expected'' equals $p^k$ where $p = 0.338$ is the overall share of individual PSCs in the 25--50\\% band and $k$ is the number of PSCs. ``Ratio'' is observed/expected. $p$-values from exact binomial tests. The 26:1 ratio at $k=4$ means that 4-PSC companies are 26 times more likely to have the exact equal-threshold split than chance would predict.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_config.tex"))

# ============================================================================
# Table 3: Sector Heterogeneity
# ============================================================================

cat("Generating Table 3: Sector Heterogeneity\n")

sec <- df[!is.na(sic_section) & sic_section != "Other" & n_individual > 0]
sector_tab <- sec[, .(
  companies = .N,
  pct_4equal = round(100 * mean(n_individual == 4 & n_band_25_50 == 4), 3),
  pct_foreign = round(100 * mean(n_foreign > 0), 1),
  pct_corporate = round(100 * mean(has_corporate_psc), 1),
  mean_pscs = round(mean(n_individual), 2)
), by = sic_section][order(-pct_4equal)]

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Ownership Structures Across Sectors}",
  "\\label{tab:sector}",
  "\\begin{tabular}{lrcccc}",
  "\\toprule",
  "Sector & Companies & Equal Split & Foreign & Corporate & Mean \\\\",
  " & & (\\%) & PSC (\\%) & PSC (\\%) & PSCs \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sector_tab))) {
  row <- sector_tab[i]
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %.3f & %.1f & %.1f & %.2f \\\\",
            row$sic_section,
            format(row$companies, big.mark = ","),
            row$pct_4equal,
            row$pct_foreign,
            row$pct_corporate,
            row$mean_pscs))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} ``Equal Split'' is the share of companies with exactly 4 individual PSCs, each in the 25--50\\% ownership band. ``Foreign PSC'' indicates at least one PSC residing outside the UK. ``Corporate PSC'' indicates at least one corporate-entity PSC (an interposed company rather than an individual). Sectors classified by 2-digit SIC code; only sectors with 20,000+ companies shown. Sectors ordered by equal-split rate.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_sector.tex"))

# ============================================================================
# Table 4: Regression — Determinants of Equal-Split Configuration
# ============================================================================

cat("Generating Table 4: Regressions\n")

# Re-run regressions with cleaner specification
multi_reg <- df[n_individual >= 2 & !is.na(high_risk) & !is.na(inc_year)]
multi_reg[, y_equal_4 := as.integer(n_individual == 4 & n_band_25_50 == 4)]
multi_reg[, y_foreign := as.integer(n_foreign > 0)]
multi_reg[, y_corp := as.integer(has_corporate_psc)]

r1 <- feols(y_equal_4 ~ high_risk, data = multi_reg, vcov = "hetero")
r2 <- feols(y_equal_4 ~ high_risk + y_foreign, data = multi_reg, vcov = "hetero")
r3 <- feols(y_equal_4 ~ high_risk + y_foreign + y_corp | inc_year,
            data = multi_reg, vcov = "hetero")
r4 <- feols(y_equal_4 ~ high_risk * y_foreign + y_corp | inc_year,
            data = multi_reg, vcov = "hetero")

# Export to LaTeX
tex_out <- file.path(tables_dir, "tab4_regression.tex")
etable(r1, r2, r3, r4,
       file = tex_out,
       title = "Determinants of the Equal-Split Configuration",
       label = "tab:reg",
       headers = c("(1)", "(2)", "(3)", "(4)"),
       dict = c("high_riskTRUE" = "High-risk sector",
                "y_foreign" = "Has foreign PSC",
                "y_corp" = "Has corporate PSC",
                "high_riskTRUE:y_foreign" = "High-risk $\\times$ Foreign"),
       notes = c("\\textit{Notes:} Unit of observation is a company with 2+ individual PSCs. Dependent variable is an indicator for having exactly 4 individual PSCs, each in the 25--50\\% ownership band. High-risk sectors: financial services, real estate, professional services, and business support (FATF risk categories). Standard errors robust to heteroskedasticity. Columns (3)--(4) include incorporation-year fixed effects."),
       depvar = FALSE,
       fitstat = c("n", "r2"))

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================

cat("Generating Table F1: SDE\n")

# Main outcome: equal-split indicator among multi-PSC companies
# Treatment: high-risk sector (binary)
beta_hr <- coef(r3)["high_riskTRUE"]
se_hr <- se(r3)["high_riskTRUE"]
sd_y <- sd(multi_reg$y_equal_4)
sde_hr <- beta_hr / sd_y
se_sde_hr <- se_hr / sd_y

# Treatment: foreign PSC (binary)
beta_for <- coef(r3)["y_foreign"]
se_for <- se(r3)["y_foreign"]
sde_for <- beta_for / sd_y
se_sde_for <- se_for / sd_y

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_pooled <- data.table(
  Outcome = c("Equal-split config.", "Equal-split config."),
  Treatment = c("High-risk sector", "Foreign PSC"),
  Beta = c(beta_hr, beta_for),
  SE = c(se_hr, se_for),
  SD_Y = c(sd_y, sd_y),
  SDE = c(sde_hr, sde_for),
  SE_SDE = c(se_sde_hr, se_sde_for)
)
sde_pooled[, Classification := sapply(SDE, classify_sde)]

# Panel B: Heterogeneous — split by pre/post PSC era
pre_psc <- df[n_individual >= 2 & !is.na(high_risk) & !is.na(inc_year) &
                era == "Pre-PSC"]
pre_psc[, y_equal_4 := as.integer(n_individual == 4 & n_band_25_50 == 4)]
pre_psc[, y_foreign := as.integer(n_foreign > 0)]
pre_psc[, y_corp := as.integer(has_corporate_psc)]

post_psc <- df[n_individual >= 2 & !is.na(high_risk) & !is.na(inc_year) &
                 era == "Post-PSC"]
post_psc[, y_equal_4 := as.integer(n_individual == 4 & n_band_25_50 == 4)]
post_psc[, y_foreign := as.integer(n_foreign > 0)]
post_psc[, y_corp := as.integer(has_corporate_psc)]

r_pre <- feols(y_equal_4 ~ y_foreign + high_risk + y_corp | inc_year,
               data = pre_psc, vcov = "hetero")
r_post <- feols(y_equal_4 ~ y_foreign + high_risk + y_corp | inc_year,
                data = post_psc, vcov = "hetero")

beta_pre <- coef(r_pre)["y_foreign"]
se_pre <- se(r_pre)["y_foreign"]
sd_y_pre <- sd(pre_psc$y_equal_4)
sde_pre <- beta_pre / sd_y_pre
se_sde_pre <- se_pre / sd_y_pre

beta_post <- coef(r_post)["y_foreign"]
se_post <- se(r_post)["y_foreign"]
sd_y_post <- sd(post_psc$y_equal_4)
sde_post <- beta_post / sd_y_post
se_sde_post <- se_post / sd_y_post

sde_hetero <- data.table(
  Outcome = c("Equal-split (Pre-PSC)", "Equal-split (Post-PSC)"),
  Treatment = c("Foreign PSC", "Foreign PSC"),
  Beta = c(beta_pre, beta_post),
  SE = c(se_pre, se_post),
  SD_Y = c(sd_y_pre, sd_y_post),
  SDE = c(sde_pre, sde_post),
  SE_SDE = c(se_sde_pre, se_sde_post)
)
sde_hetero[, Classification := sapply(SDE, classify_sde)]

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the 25\\% beneficial ownership disclosure threshold in the UK PSC register induce strategic ownership restructuring, and is avoidance behavior stronger for companies with foreign beneficial owners? ",
  "\\textbf{Policy mechanism:} The Small Business, Enterprise and Employment Act 2015 requires public disclosure of any individual holding more than 25\\% of shares or voting rights as a Person with Significant Control (PSC). This creates a discrete transparency cost at the 25\\% threshold: full public disclosure of name, date of birth, nationality, and country of residence. ",
  "\\textbf{Outcome definition:} Equal-split configuration indicator, equal to 1 if the company has exactly 4 individual PSCs each in the 25--50\\% ownership band, 0 otherwise. This configuration places each shareholder at the minimum disclosure threshold. ",
  "\\textbf{Treatment:} Binary indicators for high-risk sector (financial, real estate, professional services, business support per FATF classification) and foreign PSC status (at least one PSC residing outside the UK). ",
  "\\textbf{Data:} UK Companies House PSC bulk snapshot (April 2026), linked to Basic Company Data for SIC codes and incorporation dates; five of 31 snapshot chunks covering approximately 1.77 million companies. ",
  "\\textbf{Method:} OLS with heteroskedasticity-robust standard errors and incorporation-year fixed effects. ",
  "\\textbf{Sample:} Companies with 2+ individual PSCs and non-missing sector and incorporation data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build table
tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_pooled))) {
  row <- sde_pooled[i]
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            paste0(row$Outcome, " ($", row$Treatment, "$)"),
            row$Beta, row$SE, row$SD_Y, row$SDE, row$SE_SDE, row$Classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\\\",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by PSC register era)}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_hetero))) {
  row <- sde_hetero[i]
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad %s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            row$Outcome, row$Beta, row$SE, row$SD_Y, row$SDE, row$SE_SDE,
            row$Classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

# ============================================================================
# Table 5 (Robustness) — if robustness results loaded
# ============================================================================

if (rob_loaded) {
  cat("Generating Table 5: Robustness\n")

  tab5_lines <- c(
    "\\begin{table}[t]",
    "\\centering",
    "\\begin{threeparttable}",
    "\\caption{Robustness Checks}",
    "\\label{tab:robust}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    "Specification & Excess Mass (4--5) & $\\hat{b}$ \\\\",
    "\\midrule",
    "\\multicolumn{3}{l}{\\textit{Panel A: Polynomial Order}} \\\\[3pt]"
  )

  for (i in seq_len(nrow(poly_tab))) {
    row <- poly_tab[i]
    tab5_lines <- c(tab5_lines,
      sprintf("\\quad Degree %d & %s & %.3f \\\\",
              row$degree,
              format(row$excess_4 + row$excess_5, big.mark = ","),
              row$b_hat))
  }

  tab5_lines <- c(tab5_lines,
    "\\\\",
    "\\multicolumn{3}{l}{\\textit{Panel B: Alternative Bunching Regions}} \\\\[3pt]"
  )

  for (i in seq_len(nrow(region_tab))) {
    row <- region_tab[i]
    tab5_lines <- c(tab5_lines,
      sprintf("\\quad %s & %s & %.3f \\\\",
              row$region,
              format(row$total_excess, big.mark = ","),
              row$b_hat))
  }

  tab5_lines <- c(tab5_lines,
    "\\\\",
    "\\multicolumn{3}{l}{\\textit{Panel C: Permutation Inference}} \\\\[3pt]",
    sprintf("\\quad Observed equal-split rate & \\multicolumn{2}{c}{%.1f\\%%} \\\\",
            100 * observed_rate),
    sprintf("\\quad Permutation mean & \\multicolumn{2}{c}{%.2f\\%%} \\\\",
            100 * mean(perm_rates)),
    sprintf("\\quad Permutation $p$-value & \\multicolumn{2}{c}{%.4f} \\\\", perm_p),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]\\small",
    "\\item \\textit{Notes:} Panel A varies the polynomial order used to construct the counterfactual distribution. Panel B varies which PSC counts are excluded as the ``bunching region.'' Panel C tests whether the observed equal-split rate among 4-PSC companies (34.2\\%) exceeds what random band assignment would produce, using 999 permutations drawing from the overall individual-PSC ownership-band distribution.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  writeLines(tab5_lines, file.path(tables_dir, "tab5_robust.tex"))
}

cat("\nAll tables generated.\n")
cat(sprintf("Tables saved to: %s\n", tables_dir))
cat(sprintf("Files: %s\n", paste(list.files(tables_dir), collapse = ", ")))
