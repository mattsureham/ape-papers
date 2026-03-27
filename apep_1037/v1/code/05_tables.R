# 05_tables.R — Generate all LaTeX tables
# apep_1037: The Round-Trip Tax

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

taiex_m <- readRDS(file.path(data_dir, "taiex_monthly_panel.rds"))
taiex_q <- readRDS(file.path(data_dir, "taiex_quarterly_panel.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
sym_test <- readRDS(file.path(data_dir, "symmetry_test.rds"))

fmt <- function(x, d = 3) formatC(x, digits = d, format = "f", big.mark = ",")
fmt0 <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

# ============================================================================
# Table 1: TAIEX Summary Statistics
# ============================================================================

cat("Table 1: Summary Statistics...\n")

summ <- taiex_q %>%
  mutate(regime = factor(case_when(
    yq < 20122 ~ "Pre-Announce",
    yq >= 20122 & yq < 20131 ~ "Announcement",
    yq >= 20131 & yq <= 20153 ~ "CGT Active",
    yq >= 20154 ~ "Post-Repeal"
  ), levels = c("Pre-Announce", "Announcement", "CGT Active", "Post-Repeal"))) %>%
  group_by(regime) %>%
  summarise(
    n = n(),
    vol_mean = mean(avg_daily_vol / 1e9),
    vol_sd = sd(avg_daily_vol / 1e9),
    val_mean = mean(total_val / 1e12),
    val_sd = sd(total_val / 1e12),
    .groups = "drop"
  )

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{TWSE Market Summary Statistics by Policy Period}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Pre-Announce & Announcement & CGT Active & Post-Repeal \\\\",
  " & (2010--2012Q1) & (2012Q2--Q4) & (2013Q1--2015Q3) & (2015Q4--2018) \\\\",
  "\\midrule"
)

for (i in 1:4) {
  s <- summ[i, ]
  if (i == 1) {
    tab1 <- c(tab1, sprintf("Avg.~daily volume (B shares) & %s & %s & %s & %s \\\\",
      fmt(summ$vol_mean[1], 2), fmt(summ$vol_mean[2], 2),
      fmt(summ$vol_mean[3], 2), fmt(summ$vol_mean[4], 2)))
    tab1 <- c(tab1, sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
      fmt(summ$vol_sd[1], 2), fmt(summ$vol_sd[2], 2),
      fmt(summ$vol_sd[3], 2), fmt(summ$vol_sd[4], 2)))
    break
  }
}

tab1 <- c(tab1,
  sprintf("Avg.~daily volume (B shares) & %s & %s & %s & %s \\\\",
    fmt(summ$vol_mean[1], 2), fmt(summ$vol_mean[2], 2),
    fmt(summ$vol_mean[3], 2), fmt(summ$vol_mean[4], 2)))
# Remove duplicate — clean up
tab1 <- tab1[!duplicated(tab1)]

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{TWSE Market Summary Statistics by Policy Period}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Pre-Announce & Announcement & CGT Active & Post-Repeal \\\\",
  " & (2010--2012Q1) & (2012Q2--Q4) & (2013Q1--2015Q3) & (2015Q4--2018) \\\\",
  "\\midrule",
  sprintf("Avg.~daily vol.~(B shares) & %s & %s & %s & %s \\\\",
    fmt(summ$vol_mean[1], 2), fmt(summ$vol_mean[2], 2),
    fmt(summ$vol_mean[3], 2), fmt(summ$vol_mean[4], 2)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(summ$vol_sd[1], 2), fmt(summ$vol_sd[2], 2),
    fmt(summ$vol_sd[3], 2), fmt(summ$vol_sd[4], 2)),
  sprintf("Total qtr.~value (T TWD) & %s & %s & %s & %s \\\\",
    fmt(summ$val_mean[1], 2), fmt(summ$val_mean[2], 2),
    fmt(summ$val_mean[3], 2), fmt(summ$val_mean[4], 2)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(summ$val_sd[1], 2), fmt(summ$val_sd[2], 2),
    fmt(summ$val_sd[3], 2), fmt(summ$val_sd[4], 2)),
  sprintf("Quarters & %d & %d & %d & %d \\\\",
    summ$n[1], summ$n[2], summ$n[3], summ$n[4]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Standard deviations in parentheses. Data from TWSE Open API. Volume measured in billions of shares; value in trillions of TWD. Pre-Announce covers 2010Q1 through 2012Q1. Announcement covers 2012Q2 through 2012Q4 (Cabinet proposal to legislative passage). CGT Active covers 2013Q1 through 2015Q3 (tax in effect). Post-Repeal covers 2015Q4 through 2018Q4.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results — TAIEX Volume
# ============================================================================

cat("Table 2: Main Results...\n")

m1a <- models$m1a
m1b <- models$m1b
nw1a <- models$nw_se_1a
nw1b <- models$nw_se_1b

# Extract coefficients
get_row <- function(model, nw_se, varname, label) {
  b <- coef(model)[varname]
  se <- nw_se[varname]
  p <- 2 * pt(abs(b / se), df = model$df.residual, lower.tail = FALSE)
  list(label = label, b = b, se = se, p = p)
}

# Also get robustness models
rob1 <- rob_models$rob1_exclude_announce
nw_r1 <- rob_models$nw_rob1
rob2 <- rob_models$rob2_quarterly
nw_r2 <- rob_models$nw_rob2

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of CGT on TWSE Trading Volume}",
  "\\label{tab:main_did}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Monthly & Monthly & Monthly & Quarterly \\\\",
  " & Baseline & + Trend & No Announce & Total Vol. \\\\",
  "\\midrule"
)

# Announcement row
p1 <- 2 * pt(abs(coef(m1a)["announce"] / nw1a["announce"]), df = m1a$df.residual, lower.tail = FALSE)
p2 <- 2 * pt(abs(coef(m1b)["announce"] / nw1b["announce"]), df = m1b$df.residual, lower.tail = FALSE)
p4 <- 2 * pt(abs(coef(rob2)["announce"] / nw_r2["announce"]), df = rob2$df.residual, lower.tail = FALSE)

tab2 <- c(tab2,
  sprintf("Announcement & %s%s & %s%s & --- & %s%s \\\\",
    fmt(coef(m1a)["announce"], 4), stars(p1),
    fmt(coef(m1b)["announce"], 4), stars(p2),
    fmt(coef(rob2)["announce"], 4), stars(p4)),
  sprintf(" & (%s) & (%s) & & (%s) \\\\[4pt]",
    fmt(nw1a["announce"], 4), fmt(nw1b["announce"], 4), fmt(nw_r2["announce"], 4))
)

# CGT Active row
p1c <- 2 * pt(abs(coef(m1a)["cgt_active"] / nw1a["cgt_active"]), df = m1a$df.residual, lower.tail = FALSE)
p2c <- 2 * pt(abs(coef(m1b)["cgt_active"] / nw1b["cgt_active"]), df = m1b$df.residual, lower.tail = FALSE)
p3c <- 2 * pt(abs(coef(rob1)["cgt_active"] / nw_r1["cgt_active"]), df = rob1$df.residual, lower.tail = FALSE)
p4c <- 2 * pt(abs(coef(rob2)["cgt_active"] / nw_r2["cgt_active"]), df = rob2$df.residual, lower.tail = FALSE)

tab2 <- c(tab2,
  sprintf("CGT Active & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(coef(m1a)["cgt_active"], 4), stars(p1c),
    fmt(coef(m1b)["cgt_active"], 4), stars(p2c),
    fmt(coef(rob1)["cgt_active"], 4), stars(p3c),
    fmt(coef(rob2)["cgt_active"], 4), stars(p4c)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\[4pt]",
    fmt(nw1a["cgt_active"], 4), fmt(nw1b["cgt_active"], 4),
    fmt(nw_r1["cgt_active"], 4), fmt(nw_r2["cgt_active"], 4))
)

# Post-Repeal row
p1r <- 2 * pt(abs(coef(m1a)["post_repeal"] / nw1a["post_repeal"]), df = m1a$df.residual, lower.tail = FALSE)
p2r <- 2 * pt(abs(coef(m1b)["post_repeal"] / nw1b["post_repeal"]), df = m1b$df.residual, lower.tail = FALSE)
p3r <- 2 * pt(abs(coef(rob1)["post_repeal"] / nw_r1["post_repeal"]), df = rob1$df.residual, lower.tail = FALSE)
p4r <- 2 * pt(abs(coef(rob2)["post_repeal"] / nw_r2["post_repeal"]), df = rob2$df.residual, lower.tail = FALSE)

tab2 <- c(tab2,
  sprintf("Post-Repeal & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(coef(m1a)["post_repeal"], 4), stars(p1r),
    fmt(coef(m1b)["post_repeal"], 4), stars(p2r),
    fmt(coef(rob1)["post_repeal"], 4), stars(p3r),
    fmt(coef(rob2)["post_repeal"], 4), stars(p4r)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\[4pt]",
    fmt(nw1a["post_repeal"], 4), fmt(nw1b["post_repeal"], 4),
    fmt(nw_r1["post_repeal"], 4), fmt(nw_r2["post_repeal"], 4))
)

# Linear trend
tab2 <- c(tab2,
  sprintf("Linear trend & & %s%s & & \\\\",
    fmt(coef(m1b)["time_trend"], 5),
    stars(2 * pt(abs(coef(m1b)["time_trend"] / nw1b["time_trend"]),
                 df = m1b$df.residual, lower.tail = FALSE))),
  sprintf(" & & (%s) & & \\\\",
    fmt(nw1b["time_trend"], 5))
)

tab2 <- c(tab2,
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nobs(m1a), nobs(m1b), nobs(rob1), nobs(rob2)),
  sprintf("$R^2$ & %s & %s & %s & %s \\\\",
    fmt(summary(m1a)$r.squared, 3), fmt(summary(m1b)$r.squared, 3),
    fmt(summary(rob1)$r.squared, 3), fmt(summary(rob2)$r.squared, 3)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log average daily trading volume (shares) on the TWSE. Newey-West HAC standard errors in parentheses (6-month lag for monthly, 3-quarter lag for quarterly). Announcement = 1 for 2012Q2--Q4 (Cabinet proposal through legislative passage). CGT Active = 1 for 2013Q1--2015Q3 (tax in effect). Post-Repeal = 1 for 2015Q4 onward. Column (3) drops the announcement period. Column (4) uses quarterly total volume. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2, file.path(tables_dir, "tab2_main_did.tex"))

# ============================================================================
# Table 3: Valuation and Composition Effects
# ============================================================================

cat("Table 3: Valuation and Composition...\n")

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Valuation and Investor Composition Effects}",
  "\\label{tab:valuation}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log P/E & Div.~Yield & Foreign Net & Pr(Foreign \\\\",
  " & Ratio & (\\%) & (TWD) & Buy $>$ 0) \\\\",
  "\\midrule"
)

# P/E model
if (!is.null(models$m2_pe)) {
  pe_b_cgt <- coef(models$m2_pe)["cgt_active"]
  pe_se_cgt <- se(models$m2_pe)["cgt_active"]
  pe_p_cgt <- pvalue(models$m2_pe)["cgt_active"]
  pe_b_rep <- coef(models$m2_pe)["post_repeal"]
  pe_se_rep <- se(models$m2_pe)["post_repeal"]
  pe_p_rep <- pvalue(models$m2_pe)["post_repeal"]
} else {
  pe_b_cgt <- pe_se_cgt <- pe_b_rep <- pe_se_rep <- NA
  pe_p_cgt <- pe_p_rep <- 1
}

# Div yield
if (!is.null(models$m2_dy)) {
  dy_b_cgt <- coef(models$m2_dy)["cgt_active"]
  dy_se_cgt <- se(models$m2_dy)["cgt_active"]
  dy_p_cgt <- pvalue(models$m2_dy)["cgt_active"]
  dy_b_rep <- coef(models$m2_dy)["post_repeal"]
  dy_se_rep <- se(models$m2_dy)["post_repeal"]
  dy_p_rep <- pvalue(models$m2_dy)["post_repeal"]
} else {
  dy_b_cgt <- dy_se_cgt <- dy_b_rep <- dy_se_rep <- NA
  dy_p_cgt <- dy_p_rep <- 1
}

# Foreign net
if (!is.null(models$m3_foreign_net)) {
  fn_b_cgt <- coef(models$m3_foreign_net)["cgt_active"]
  fn_se_cgt <- se(models$m3_foreign_net)["cgt_active"]
  fn_p_cgt <- pvalue(models$m3_foreign_net)["cgt_active"]
  fn_b_rep <- coef(models$m3_foreign_net)["post_repeal"]
  fn_se_rep <- se(models$m3_foreign_net)["post_repeal"]
  fn_p_rep <- pvalue(models$m3_foreign_net)["post_repeal"]
} else {
  fn_b_cgt <- fn_se_cgt <- fn_b_rep <- fn_se_rep <- NA
  fn_p_cgt <- fn_p_rep <- 1
}

# Foreign positive
if (!is.null(models$m3_foreign)) {
  fp_b_cgt <- coef(models$m3_foreign)["cgt_active"]
  fp_se_cgt <- se(models$m3_foreign)["cgt_active"]
  fp_p_cgt <- pvalue(models$m3_foreign)["cgt_active"]
  fp_b_rep <- coef(models$m3_foreign)["post_repeal"]
  fp_se_rep <- se(models$m3_foreign)["post_repeal"]
  fp_p_rep <- pvalue(models$m3_foreign)["post_repeal"]
} else {
  fp_b_cgt <- fp_se_cgt <- fp_b_rep <- fp_se_rep <- NA
  fp_p_cgt <- fp_p_rep <- 1
}

tab3 <- c(tab3,
  sprintf("CGT Active & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(pe_b_cgt, 4), stars(pe_p_cgt),
    fmt(dy_b_cgt, 2), stars(dy_p_cgt),
    fmt0(round(fn_b_cgt)), stars(fn_p_cgt),
    fmt(fp_b_cgt, 4), stars(fp_p_cgt)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\[4pt]",
    fmt(pe_se_cgt, 4), fmt(dy_se_cgt, 2),
    fmt0(round(fn_se_cgt)), fmt(fp_se_cgt, 4)),
  sprintf("Post-Repeal & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(pe_b_rep, 4), stars(pe_p_rep),
    fmt(dy_b_rep, 2), stars(dy_p_rep),
    fmt0(round(fn_b_rep)), stars(fn_p_rep),
    fmt(fp_b_rep, 4), stars(fp_p_rep)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(pe_se_rep, 4), fmt(dy_se_rep, 2),
    fmt0(round(fn_se_rep)), fmt(fp_se_rep, 4)),
  "\\midrule",
  "Firm FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    if (!is.null(models$m2_pe)) fmt0(nobs(models$m2_pe)) else "---",
    if (!is.null(models$m2_dy)) fmt0(nobs(models$m2_dy)) else "---",
    if (!is.null(models$m3_foreign_net)) fmt0(nobs(models$m3_foreign_net)) else "---",
    if (!is.null(models$m3_foreign)) fmt0(nobs(models$m3_foreign)) else "---"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} All specifications include firm fixed effects with standard errors clustered at the firm level. Column (1): log P/E ratio, winsorized at 99th percentile. Column (2): dividend yield (\\%). Column (3): foreign investor net purchase value (TWD). Column (4): probability that foreign investor net purchases are positive. Data: TWSE P/E and institutional trading reports, 2012Q3--2018Q4. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, file.path(tables_dir, "tab3_valuation.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================

cat("Table 4: Robustness...\n")

rob3 <- rob_models$rob3_quadratic
nw_r3 <- rob_models$nw_rob3
rob4 <- rob_models$rob4_placebo
nw_r4 <- rob_models$nw_rob4

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: Log Average Daily Volume}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Baseline & Quadratic & Placebo \\\\",
  " & (Monthly) & Trend & (Pre-Period) \\\\",
  "\\midrule"
)

p_ann <- 2 * pt(abs(coef(m1a)["announce"] / nw1a["announce"]), df = m1a$df.residual, lower.tail = FALSE)
p_ann3 <- 2 * pt(abs(coef(rob3)["announce"] / nw_r3["announce"]), df = rob3$df.residual, lower.tail = FALSE)

tab4 <- c(tab4,
  sprintf("Announcement & %s%s & %s%s & \\\\",
    fmt(coef(m1a)["announce"], 4), stars(p_ann),
    fmt(coef(rob3)["announce"], 4), stars(p_ann3)),
  sprintf(" & (%s) & (%s) & \\\\[4pt]",
    fmt(nw1a["announce"], 4), fmt(nw_r3["announce"], 4)),
  sprintf("CGT Active & %s%s & %s%s & \\\\",
    fmt(coef(m1a)["cgt_active"], 4), stars(p1c),
    fmt(coef(rob3)["cgt_active"], 4),
    stars(2 * pt(abs(coef(rob3)["cgt_active"] / nw_r3["cgt_active"]),
                 df = rob3$df.residual, lower.tail = FALSE))),
  sprintf(" & (%s) & (%s) & \\\\[4pt]",
    fmt(nw1a["cgt_active"], 4), fmt(nw_r3["cgt_active"], 4)),
  sprintf("Post-Repeal & %s%s & %s%s & \\\\",
    fmt(coef(m1a)["post_repeal"], 4), stars(p1r),
    fmt(coef(rob3)["post_repeal"], 4),
    stars(2 * pt(abs(coef(rob3)["post_repeal"] / nw_r3["post_repeal"]),
                 df = rob3$df.residual, lower.tail = FALSE))),
  sprintf(" & (%s) & (%s) & \\\\[4pt]",
    fmt(nw1a["post_repeal"], 4), fmt(nw_r3["post_repeal"], 4)),
  sprintf("Placebo (2011Q1) & & & %s%s \\\\",
    fmt(coef(rob4)["placebo"], 4),
    stars(2 * pt(abs(coef(rob4)["placebo"] / nw_r4["placebo"]),
                 df = rob4$df.residual, lower.tail = FALSE))),
  sprintf(" & & & (%s) \\\\",
    fmt(nw_r4["placebo"], 4)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d \\\\",
    nobs(m1a), nobs(rob3), nobs(rob4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Dependent variable is log average daily trading volume. Column (1) reproduces the baseline from Table 2. Column (2) adds a quadratic time trend. Column (3) tests for pre-trends by imposing a pseudo-treatment at 2011Q1 using only pre-announcement data (2010Q1--2012Q1). Newey-West HAC standard errors in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================================

cat("Table F1: SDE...\n")

pre_sd <- sd(taiex_m$log_daily_vol[taiex_m$yq < 20122], na.rm = TRUE)

# Main effects from baseline model
b_ann <- coef(m1a)["announce"]
se_ann <- nw1a["announce"]
b_cgt <- coef(m1a)["cgt_active"]
se_cgt <- nw1a["cgt_active"]
b_rep <- coef(m1a)["post_repeal"]
se_rep <- nw1a["post_repeal"]

classify <- function(s) case_when(
  s < -0.15 ~ "Large negative",
  s < -0.05 ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <= 0.005 ~ "Null",
  s <= 0.05 ~ "Small positive",
  s <= 0.15 ~ "Moderate positive",
  TRUE ~ "Large positive"
)

sde_data <- data.frame(
  outcome = c("Daily volume (announcement)", "Daily volume (CGT active)",
              "Daily volume (post-repeal)"),
  beta = c(b_ann, b_cgt, b_rep),
  se = c(se_ann, se_cgt, se_rep),
  sd_y = rep(pre_sd, 3)
) %>% mutate(
  sde = beta / sd_y,
  se_sde = se / sd_y,
  classification = classify(sde)
)

# Heterogeneity: P/E panel effects
if (!is.null(models$m2_pe)) {
  pe_pre_sd <- sd(log(readRDS(file.path(data_dir, "pe_clean.rds"))$pe[
    readRDS(file.path(data_dir, "pe_clean.rds"))$yq < 20131
  ]), na.rm = TRUE)

  sde_het <- data.frame(
    outcome = c("Log P/E ratio (CGT active)", "Div.~yield (CGT active)"),
    beta = c(coef(models$m2_pe)["cgt_active"],
             coef(models$m2_dy)["cgt_active"]),
    se = c(se(models$m2_pe)["cgt_active"],
           se(models$m2_dy)["cgt_active"]),
    sd_y = c(pe_pre_sd,
             sd(readRDS(file.path(data_dir, "pe_clean.rds"))$div_yield[
               readRDS(file.path(data_dir, "pe_clean.rds"))$yq < 20131
             ], na.rm = TRUE))
  ) %>% mutate(
    sde = beta / sd_y,
    se_sde = se / sd_y,
    classification = classify(sde)
  )
} else {
  sde_het <- data.frame(
    outcome = "N/A", beta = NA, se = NA, sd_y = NA,
    sde = NA, se_sde = NA, classification = "N/A"
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Taiwan. ",
  "\\textbf{Research question:} Does a capital gains tax on securities reduce stock market trading activity, or does the market response concentrate in the announcement period rather than during implementation? ",
  "\\textbf{Policy mechanism:} Taiwan introduced a 15\\% capital gains tax on individual investors with gains exceeding TWD 1 billion (effective January 2013), after a 24-year absence of any securities CGT; the tax was fully repealed in November 2015 following market backlash and political pressure. ",
  "\\textbf{Outcome definition:} Log average daily trading volume on the Taiwan Stock Exchange, measured in shares, aggregated from all trading days within each calendar month. ",
  "\\textbf{Treatment:} Binary indicators for three policy periods: Announcement (2012Q2--Q4), CGT Active (2013Q1--2015Q3), and Post-Repeal (2015Q4+), relative to the pre-announcement baseline (2010Q1--2012Q1). ",
  "\\textbf{Data:} TWSE Open API, monthly aggregate market data, 2010M1--2018M12, 104 monthly observations. ",
  "\\textbf{Method:} OLS time-series regression with Newey-West HAC standard errors (6-month bandwidth). ",
  "\\textbf{Sample:} Full TWSE market aggregate; covers all listed ordinary shares. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled Effects}} \\\\[3pt]"
)

for (i in 1:nrow(sde_data)) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
      sde_data$outcome[i], fmt(sde_data$beta[i], 4), fmt(sde_data$se[i], 4),
      fmt(sde_data$sd_y[i], 3), fmt(sde_data$sde[i], 4),
      fmt(sde_data$se_sde[i], 4), sde_data$classification[i]))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous Effects (Firm-Level)}} \\\\[3pt]"
)

for (i in 1:nrow(sde_het)) {
  if (!is.na(sde_het$beta[i])) {
    sde_lines <- c(sde_lines,
      sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
        sde_het$outcome[i], fmt(sde_het$beta[i], 4), fmt(sde_het$se[i], 4),
        fmt(sde_het$sd_y[i], 3), fmt(sde_het$sde[i], 4),
        fmt(sde_het$se_sde[i], 4), sde_het$classification[i]))
  }
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
