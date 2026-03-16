# 05_tables.R — Generate all LaTeX tables
# apep_0710: Ukraine ProZorro Procurement Thresholds

source("00_packages.R")

df <- readRDS("../data/prozorro_clean.rds")
load("../data/models.RData")

bw <- 100000
df_bw <- df %>% filter(abs(running) <= bw)

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ══════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════

summ_pre <- df %>% filter(post == 0) %>%
  summarise(
    N = n(),
    Value = sprintf("%.0f (%.0f)", mean(value_uah), sd(value_uah)),
    Savings = sprintf("%.1f (%.1f)", mean(savings_pct, na.rm = TRUE), sd(savings_pct, na.rm = TRUE)),
    Bids = sprintf("%.2f (%.2f)", mean(n_bids, na.rm = TRUE), sd(n_bids, na.rm = TRUE)),
    Competitive = sprintf("%.1f", mean(is_competitive, na.rm = TRUE) * 100),
    Oblasts = n_distinct(region_en)
  )

summ_post <- df %>% filter(post == 1) %>%
  summarise(
    N = n(),
    Value = sprintf("%.0f (%.0f)", mean(value_uah), sd(value_uah)),
    Savings = sprintf("%.1f (%.1f)", mean(savings_pct, na.rm = TRUE), sd(savings_pct, na.rm = TRUE)),
    Bids = sprintf("%.2f (%.2f)", mean(n_bids, na.rm = TRUE), sd(n_bids, na.rm = TRUE)),
    Competitive = sprintf("%.1f", mean(is_competitive, na.rm = TRUE) * 100),
    Oblasts = n_distinct(region_en)
  )

summ_all <- df %>%
  summarise(
    N = n(),
    Value = sprintf("%.0f (%.0f)", mean(value_uah), sd(value_uah)),
    Savings = sprintf("%.1f (%.1f)", mean(savings_pct, na.rm = TRUE), sd(savings_pct, na.rm = TRUE)),
    Bids = sprintf("%.2f (%.2f)", mean(n_bids, na.rm = TRUE), sd(n_bids, na.rm = TRUE)),
    Competitive = sprintf("%.1f", mean(is_competitive, na.rm = TRUE) * 100),
    Oblasts = n_distinct(region_en)
  )

tab1_tex <- sprintf(
  "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:summ}
\\begin{tabular}{lccc}
\\toprule
 & Pre-War & Post-War & Full Sample \\\\
 & (2017--2021) & (2022--2024) & \\\\
\\midrule
Observations & %s & %s & %s \\\\
Contract value, UAH & %s & %s & %s \\\\
Price savings (\\%%) & %s & %s & %s \\\\
Number of bids & %s & %s & %s \\\\
Competitive procedure (\\%%) & %s & %s & %s \\\\
Oblasts & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard deviations in parentheses. Price savings = (expected value $-$ award value) / expected value. Competitive procedure includes aboveThresholdUA/EU types. Sample restricted to contracts valued 50,000--500,000 UAH. Post-war period begins February 24, 2022. Source: ProZorro public API.
\\end{tablenotes}
\\end{table}",
  format(summ_pre$N, big.mark = ","), format(summ_post$N, big.mark = ","), format(summ_all$N, big.mark = ","),
  summ_pre$Value, summ_post$Value, summ_all$Value,
  summ_pre$Savings, summ_post$Savings, summ_all$Savings,
  summ_pre$Bids, summ_post$Bids, summ_all$Bids,
  summ_pre$Competitive, summ_post$Competitive, summ_all$Competitive,
  summ_pre$Oblasts, summ_post$Oblasts, summ_all$Oblasts
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ══════════════════════════════════════════════════════════════════
# Table 2: Peacetime RD Estimates
# ══════════════════════════════════════════════════════════════════

# Extract rdrobust results
extract_rd <- function(rd, label) {
  if (is.null(rd)) return(NULL)
  data.frame(
    Outcome = label,
    Estimate = sprintf("%.3f", rd$coef[1]),
    SE = sprintf("(%.3f)", rd$se[3]),  # Robust SE
    pval = rd$pv[3],
    BW = sprintf("%.0f", rd$bws[1, 1]),
    N_eff = rd$N_h[1] + rd$N_h[2],
    Stars = ifelse(rd$pv[3] < 0.01, "***",
                   ifelse(rd$pv[3] < 0.05, "**",
                          ifelse(rd$pv[3] < 0.1, "*", "")))
  )
}

rd_rows_pre <- bind_rows(
  extract_rd(rd_savings_pre, "Price savings (\\%)"),
  extract_rd(rd_bids_pre, "Number of bids"),
  extract_rd(rd_comp_pre, "Competitive procedure")
)

rd_rows_post <- bind_rows(
  extract_rd(rd_savings_post, "Price savings (\\%)"),
  extract_rd(rd_bids_post, "Number of bids"),
  extract_rd(rd_comp_post, "Competitive procedure")
)

# Build LaTeX
tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{RD Estimates at the UAH 200,000 Threshold}",
  "\\label{tab:rd}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-War (2017--2021)} & \\multicolumn{2}{c}{Post-War (2022--2024)} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Outcome & Estimate & $N_{\\text{eff}}$ & Estimate & $N_{\\text{eff}}$ & BW (UAH) \\\\"
)
tab2_lines <- c(tab2_lines, "\\midrule")

outcomes <- c("Price savings (\\%)", "Number of bids", "Competitive procedure")
for (i in seq_along(outcomes)) {
  pre_row <- if (i <= nrow(rd_rows_pre)) rd_rows_pre[i, ] else NULL
  post_row <- if (!is.null(rd_rows_post) && i <= nrow(rd_rows_post)) rd_rows_post[i, ] else NULL

  est_pre <- if (!is.null(pre_row)) paste0(pre_row$Estimate, pre_row$Stars) else "---"
  se_pre <- if (!is.null(pre_row)) pre_row$SE else ""
  n_pre <- if (!is.null(pre_row)) format(pre_row$N_eff, big.mark = ",") else "---"
  est_post <- if (!is.null(post_row)) paste0(post_row$Estimate, post_row$Stars) else "---"
  se_post <- if (!is.null(post_row)) post_row$SE else ""
  n_post <- if (!is.null(post_row)) format(post_row$N_eff, big.mark = ",") else "---"
  bw_val <- if (!is.null(pre_row)) pre_row$BW else "---"

  tab2_lines <- c(tab2_lines,
    sprintf("%s & %s & %s & %s & %s & %s \\\\", outcomes[i], est_pre, n_pre, est_post, n_post, bw_val),
    sprintf(" & %s & & %s & & \\\\", se_pre, se_post)
  )
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Local polynomial RD estimates using \\texttt{rdrobust} with triangular kernel and MSE-optimal bandwidth. Robust bias-corrected standard errors in parentheses. $N_{\\text{eff}}$ is the effective sample within the optimal bandwidth. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_rd.tex"))

# ══════════════════════════════════════════════════════════════════
# Table 3: Diff-in-Discontinuities
# ══════════════════════════════════════════════════════════════════

if (!is.null(did_savings) && !is.null(did_bids) && !is.null(did_comp)) {
  etable(
    did_savings, did_bids, did_comp,
    headers = c("Savings (%)", "Bids", "Competitive"),
    keep = c("%above", "%post"),
    drop = c("%running"),
    coefstat = "se",
    fitstat = c("n", "r2"),
    style.tex = style.tex("aer"),
    file = file.path(tables_dir, "tab3_did.tex"),
    replace = TRUE,
    title = "Difference-in-Discontinuities Estimates",
    label = "tab:did",
    notes = paste0(
      "\\\\item \\\\textit{Notes:} ",
      "Sample restricted to contracts within $\\\\pm$100,000 UAH of the 200,000 threshold. ",
      "Linear control in running variable with different slopes above and below. ",
      "Oblast and year fixed effects. Standard errors clustered by oblast in parentheses. ",
      "Post = 1 after February 24, 2022. Above = 1 if contract value exceeds 200,000 UAH. ",
      "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$."
    )
  )
}

# ══════════════════════════════════════════════════════════════════
# Table 4: Triple Difference (Frontline Heterogeneity)
# ══════════════════════════════════════════════════════════════════

if (!is.null(ddd_savings) && !is.null(ddd_bids) && !is.null(ddd_comp)) {
  etable(
    ddd_savings, ddd_bids, ddd_comp,
    headers = c("Savings (%)", "Bids", "Competitive"),
    keep = c("%above", "%post", "%frontline"),
    drop = c("%running"),
    coefstat = "se",
    fitstat = c("n", "r2"),
    style.tex = style.tex("aer"),
    file = file.path(tables_dir, "tab4_ddd.tex"),
    replace = TRUE,
    title = "Triple-Difference: Frontline Oblast Heterogeneity",
    label = "tab:ddd",
    notes = paste0(
      "\\\\item \\\\textit{Notes:} ",
      "Frontline oblasts: Donetsk, Luhansk, Zaporizhzhia, Kherson, Kharkiv, Mykolaiv. ",
      "Same bandwidth and specification as Table~\\\\ref{tab:did} with addition of ",
      "frontline indicator and all interactions. Triple-interaction (Above $\\\\times$ Post $\\\\times$ Frontline) ",
      "identifies differential erosion in frontline oblasts. ",
      "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$."
    )
  )
}

# ══════════════════════════════════════════════════════════════════
# Table 5: Robustness — Bandwidth Sensitivity
# ══════════════════════════════════════════════════════════════════

bw_results <- readRDS("../data/bw_sensitivity.rds")

if (length(bw_results) > 0) {
  bw_df <- bind_rows(lapply(bw_results, as.data.frame))

  tab5_lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Bandwidth Sensitivity: Diff-in-Disc Estimate for Price Savings}",
    "\\label{tab:bw}",
    "\\begin{tabular}{lccc}",
    "\\toprule",
    "Bandwidth (UAH) & Above $\\times$ Post & SE & N \\\\",
    "\\midrule"
  )

  for (i in 1:nrow(bw_df)) {
    stars <- ifelse(abs(bw_df$coef[i] / bw_df$se[i]) > 2.576, "***",
                    ifelse(abs(bw_df$coef[i] / bw_df$se[i]) > 1.96, "**",
                           ifelse(abs(bw_df$coef[i] / bw_df$se[i]) > 1.645, "*", "")))
    tab5_lines <- c(tab5_lines,
      sprintf("$\\pm$%s & %.2f%s & (%.2f) & %s \\\\",
              format(bw_df$bw[i], big.mark = ","),
              bw_df$coef[i], stars, bw_df$se[i],
              format(bw_df$n[i], big.mark = ",")))
  }

  tab5_lines <- c(tab5_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each row re-estimates the diff-in-disc specification from Table~\\ref{tab:did} using a different bandwidth around the 200,000 UAH threshold. Baseline bandwidth is $\\pm$100,000 UAH. Standard errors clustered by oblast.",
    "\\end{tablenotes}",
    "\\end{table}"
  )

  writeLines(tab5_lines, file.path(tables_dir, "tab5_bw.tex"))
}

# ══════════════════════════════════════════════════════════════════
# Appendix: SDE Table (MANDATORY)
# ══════════════════════════════════════════════════════════════════

cat("\n=== Generating SDE Table ===\n")

# Compute SDEs for main diff-in-disc outcomes
sde_rows <- list()

if (!is.null(did_savings)) {
  beta <- coef(did_savings)["above:post"]
  se_beta <- se(did_savings)["above:post"]
  sd_y <- sd(df_bw$savings_pct[df_bw$post == 0], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  sde_class <- ifelse(sde > 0.15, "Large positive",
               ifelse(sde > 0.05, "Moderate positive",
               ifelse(sde > 0.005, "Small positive",
               ifelse(sde > -0.005, "Null",
               ifelse(sde > -0.05, "Small negative",
               ifelse(sde > -0.15, "Moderate negative", "Large negative"))))))
  sde_rows[["savings"]] <- data.frame(
    Outcome = "Price savings (\\%)",
    Beta = sprintf("%.3f", beta),
    SE = sprintf("%.3f", se_beta),
    SD_Y = sprintf("%.3f", sd_y),
    SDE = sprintf("%.3f", sde),
    SE_SDE = sprintf("%.3f", se_sde),
    Classification = sde_class
  )
}

if (!is.null(did_bids)) {
  beta <- coef(did_bids)["above:post"]
  se_beta <- se(did_bids)["above:post"]
  sd_y <- sd(df_bw$n_bids[df_bw$post == 0], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  sde_class <- ifelse(sde > 0.15, "Large positive",
               ifelse(sde > 0.05, "Moderate positive",
               ifelse(sde > 0.005, "Small positive",
               ifelse(sde > -0.005, "Null",
               ifelse(sde > -0.05, "Small negative",
               ifelse(sde > -0.15, "Moderate negative", "Large negative"))))))
  sde_rows[["bids"]] <- data.frame(
    Outcome = "Number of bids",
    Beta = sprintf("%.3f", beta),
    SE = sprintf("%.3f", se_beta),
    SD_Y = sprintf("%.3f", sd_y),
    SDE = sprintf("%.3f", sde),
    SE_SDE = sprintf("%.3f", se_sde),
    Classification = sde_class
  )
}

if (!is.null(did_comp)) {
  beta <- coef(did_comp)["above:post"]
  se_beta <- se(did_comp)["above:post"]
  sd_y <- sd(df_bw$is_competitive[df_bw$post == 0], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  sde_class <- ifelse(sde > 0.15, "Large positive",
               ifelse(sde > 0.05, "Moderate positive",
               ifelse(sde > 0.005, "Small positive",
               ifelse(sde > -0.005, "Null",
               ifelse(sde > -0.05, "Small negative",
               ifelse(sde > -0.15, "Moderate negative", "Large negative"))))))
  sde_rows[["comp"]] <- data.frame(
    Outcome = "Competitive procedure",
    Beta = sprintf("%.3f", beta),
    SE = sprintf("%.3f", se_beta),
    SD_Y = sprintf("%.3f", sd_y),
    SDE = sprintf("%.3f", sde),
    SE_SDE = sprintf("%.3f", se_sde),
    Classification = sde_class
  )
}

sde_df <- bind_rows(sde_rows)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Ukraine. ",
  "\\textbf{Research question:} Does the competitive advantage generated by Ukraine's UAH 200,000 mandatory open-auction procurement threshold erode after the February 2022 Russian invasion? ",
  "\\textbf{Policy mechanism:} Law No.\\ 922-VIII (2015) requires all public contracts above UAH 200,000 to use mandatory open electronic auction on ProZorro; ",
  "Cabinet Resolution No.\\ 169 (Feb 2022) suspended this requirement under martial law, allowing emergency direct contracting. ",
  "\\textbf{Outcome definition:} Price savings = (expected value $-$ award value) / expected value; ",
  "number of valid bids per tender; binary indicator for competitive procedure type. ",
  "\\textbf{Treatment:} Binary --- above vs.\\ below the UAH 200,000 threshold, interacted with post-invasion indicator. ",
  "\\textbf{Data:} ProZorro public API, 2017--2024, contract-level observations within $\\pm$100,000 UAH of threshold, ",
  sprintf("%s observations. ", format(nrow(df_bw), big.mark = ",")),
  "\\textbf{Method:} Difference-in-discontinuities with linear running variable, oblast and year FE, SEs clustered by oblast. ",
  "\\textbf{Sample:} Contracts valued 100,000--300,000 UAH across 25 Ukrainian oblasts, excluding cancelled tenders. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-war ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: Diff-in-Discontinuities Estimates}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_df)) {
  sde_tex <- c(sde_tex,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            sde_df$Outcome[i], sde_df$Beta[i], sde_df$SE[i],
            sde_df$SD_Y[i], sde_df$SDE[i], sde_df$SE_SDE[i],
            sde_df$Classification[i]))
}

sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("All tables generated.\n")
