## 05_tables.R — Generate all LaTeX tables
## apep_0670: Comment Period Length and Public Participation

source("00_packages.R")

cat("=== Generating Tables ===\n")

df <- read_csv("../data/rules_analysis.csv", show_col_types = FALSE)
load("../data/models.RData")
load("../data/robustness_models.RData")

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("Table 1: Summary Statistics\n")

n_total <- nrow(df)
n_with_comments <- sum(df$has_comments)

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Mean & SD & Median & Min & Max \\\\",
  "\\midrule",
  sprintf("Comment period (days) & %.1f & %.1f & %.0f & %d & %d \\\\",
    mean(df$comment_days), sd(df$comment_days), median(df$comment_days),
    min(df$comment_days), max(df$comment_days)),
  sprintf("Total comments & %s & %s & %d & %d & %s \\\\",
    format(round(mean(df$total_comments)), big.mark = ","),
    format(round(sd(df$total_comments)), big.mark = ","),
    median(df$total_comments), min(df$total_comments),
    format(max(df$total_comments), big.mark = ",")),
  sprintf("Log(comments + 1) & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
    mean(df$log_comments), sd(df$log_comments), median(df$log_comments),
    min(df$log_comments), max(df$log_comments)),
  sprintf("Has comments (\\%%) & %.1f & & & & \\\\",
    100 * mean(df$has_comments)),
  sprintf("Page length & %.1f & %.1f & %d & %d & %d \\\\",
    mean(df$page_length, na.rm = TRUE), sd(df$page_length, na.rm = TRUE),
    as.integer(median(df$page_length, na.rm = TRUE)),
    min(df$page_length, na.rm = TRUE), max(df$page_length, na.rm = TRUE)),
  sprintf("CFR parts affected & %.1f & %.1f & %d & %d & %d \\\\",
    mean(df$n_cfr_parts), sd(df$n_cfr_parts), as.integer(median(df$n_cfr_parts)),
    min(df$n_cfr_parts), max(df$n_cfr_parts)),
  sprintf("Significant rule (\\%%) & %.1f & & & & \\\\",
    100 * mean(df$is_significant)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s proposed rules from the \\textit{Federal Register} (2010--2023) with comment periods between 10 and 180 days and matched to Regulations.gov comment counts. Comment counts obtained from the Federal Register API's \\texttt{regulations\\_dot\\_gov\\_info} field.",
    format(n_total, big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  -> tab1_summary.tex\n")

# ============================================================
# Table 2: Comment Period Distribution
# ============================================================

cat("Table 2: Distribution\n")

dist <- df |>
  group_by(period_bin) |>
  summarise(
    n = n(),
    pct = 100 * n() / nrow(df),
    mean_comments = mean(total_comments),
    median_comments = median(total_comments),
    pct_zero = 100 * mean(total_comments == 0),
    mean_pages = mean(page_length, na.rm = TRUE),
    pct_sig = 100 * mean(is_significant),
    .groups = "drop"
  )

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Distribution of Comment Period Lengths}",
  "\\label{tab:distribution}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & N & \\% & Mean & Median & \\% Zero & Mean & \\% Sig. \\\\",
  " & & & Comments & Comments & Comments & Pages & \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(dist))) {
  tab2 <- c(tab2, sprintf("%s & %s & %.1f & %s & %d & %.1f & %.1f & %.1f \\\\",
    as.character(dist$period_bin[i]),
    format(dist$n[i], big.mark = ","),
    dist$pct[i],
    format(round(dist$mean_comments[i]), big.mark = ","),
    as.integer(dist$median_comments[i]),
    dist$pct_zero[i],
    dist$mean_pages[i],
    dist$pct_sig[i]))
}

tab2 <- c(tab2,
  "\\midrule",
  sprintf("Total & %s & 100.0 & %s & %d & %.1f & %.1f & %.1f \\\\",
    format(nrow(df), big.mark = ","),
    format(round(mean(df$total_comments)), big.mark = ","),
    as.integer(median(df$total_comments)),
    100 * mean(df$total_comments == 0),
    mean(df$page_length, na.rm = TRUE),
    100 * mean(df$is_significant)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All proposed rules 2010--2023 with comment periods 10--180 days. The APA requires a minimum 30-day period. ``Significant'' rules are designated under Executive Order 12866.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_distribution.tex")
cat("  -> tab2_distribution.tex\n")

# ============================================================
# Table 3: Main Regression Results
# ============================================================

cat("Table 3: Main Results\n")

models_main <- list("(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5)

cm <- c(
  "comment_days" = "Comment period (days)",
  "log_pages" = "Log(page length)",
  "n_cfr_parts" = "CFR parts affected",
  "is_significantTRUE" = "Significant rule"
)

gm <- tibble::tribble(
  ~raw, ~clean, ~fmt,
  "nobs", "Observations", function(x) format(round(x), big.mark = ","),
  "r.squared", "$R^2$", function(x) sprintf("%.3f", x)
)

add_rows <- data.frame(
  term = c("Agency FE", "Agency $\\times$ Year FE"),
  `(1)` = c("", ""),
  `(2)` = c("", ""),
  `(3)` = c("$\\checkmark$", ""),
  `(4)` = c("", "$\\checkmark$"),
  `(5)` = c("", "$\\checkmark$"),
  check.names = FALSE
)

modelsummary(
  models_main,
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Comment Period Length and Public Participation\\label{tab:main}",
  notes = list(
    "\\\\textit{Notes:} Dependent variable is log(total comments + 1). Standard errors in parentheses.",
    "Column (5) restricts to rules with 20--90 day comment periods.",
    "$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$."
  ),
  add_rows = add_rows,
  output = "../tables/tab3_main.tex",
  escape = FALSE
)

cat("  -> tab3_main.tex\n")

# ============================================================
# Table 4: Robustness and Heterogeneity
# ============================================================

cat("Table 4: Robustness\n")

models_robust <- list(
  "Poisson" = m_poisson,
  "Excl. Sig." = m_nonsig,
  "Quadratic" = m_quad,
  "Log-Log" = m_loglog,
  "Sig. Only" = m_sig
)

cm4 <- c(
  "comment_days" = "Comment period (days)",
  "I(I(comment_days^2))" = "Comment period$^2$ ($\\times 10^{-5}$)",
  "log(comment_days)" = "Log(comment period)",
  "log_pages" = "Log(page length)",
  "n_cfr_parts" = "CFR parts affected"
)

modelsummary(
  models_robust,
  coef_map = cm4,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Robustness and Heterogeneity\\label{tab:robustness}",
  notes = list(
    "\\\\textit{Notes:} Column (1) uses Poisson PPML with total comments as outcome.",
    "Column (2) excludes rules designated ``significant'' under EO 12866.",
    "Column (3) adds quadratic term. Column (4) uses log-log specification.",
    "Column (5) restricts to significant rules only. All include agency $\\\\times$ year FE.",
    "$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$."
  ),
  output = "../tables/tab4_robustness.tex",
  escape = FALSE
)

cat("  -> tab4_robustness.tex\n")

# ============================================================
# Table F1: Standardized Effect Sizes
# ============================================================

cat("Table F1: SDE\n")

sd_x <- sd(df$comment_days)
sd_y <- sd(df$log_comments)

# Main outcome
beta1 <- coef(m4)["comment_days"]
se1 <- se(m4)["comment_days"]
sde1 <- beta1 * sd_x / sd_y
sde_se1 <- se1 * sd_x / sd_y

# Extensive margin
sd_y_ext <- sd(df$has_comments)
beta2 <- coef(m_ext)["comment_days"]
se2 <- se(m_ext)["comment_days"]
sde2 <- beta2 * sd_x / sd_y_ext
sde_se2 <- se2 * sd_x / sd_y_ext

# Intensive margin
df_pos <- df |> filter(has_comments)
sd_y_int <- sd(df_pos$log_comments)
beta3 <- coef(m_int)["comment_days"]
se3 <- se(m_int)["comment_days"]
sde3 <- beta3 * sd_x / sd_y_int
sde_se3 <- se3 * sd_x / sd_y_int

classify <- function(s) {
  if (is.na(s)) return("---")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log(comments + 1) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta1, se1, sd_y, sde1, sde_se1, classify(sde1)),
  sprintf("Has comments & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta2, se2, sd_y_ext, sde2, sde_se2, classify(sde2)),
  sprintf("Log(comments) $|$ $>0$ & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    beta3, se3, sd_y_int, sde3, sde_se3, classify(sde3)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} Standardized effect sizes computed as SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment (comment period length in days, SD($X$) = %.1f). Estimates from preferred specification with agency $\\times$ year fixed effects (Table~\\ref{tab:main}, Column 4). Research question: Does extending the public comment period for proposed federal rules increase public participation? Data: Federal Register API proposed rules (2010--2023). Method: OLS with agency $\\times$ year fixed effects. N = %s. Treatment: comment period length (continuous, days). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.",
    sd_x, format(nrow(df), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  -> tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
