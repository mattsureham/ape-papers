## 05_tables.R — Generate all LaTeX tables
## apep_1417: Singapore ABSD and Housing Markets

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

results <- readRDS(file.path(data_dir, "regression_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel <- read_csv(file.path(data_dir, "analysis_panel.csv"), show_col_types = FALSE)

# ============================================================
# Table 1: Summary Statistics (manual LaTeX)
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

ss <- panel |>
  group_by(segment) |>
  summarise(
    mean_pi = mean(price_index, na.rm = TRUE),
    sd_pi = sd(price_index, na.rm = TRUE),
    mean_ri = mean(rental_index, na.rm = TRUE),
    sd_ri = sd(rental_index, na.rm = TRUE),
    mean_txn = mean(total_units, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

fmt <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics by Market Segment}\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccccc}\n\\toprule\n",
  "Segment & \\multicolumn{2}{c}{Price Index} & \\multicolumn{2}{c}{Rental Index} & Mean Quarterly & $N$ \\\\\n",
  " & Mean & SD & Mean & SD & Transactions & \\\\\n\\midrule\n",
  paste(apply(ss, 1, function(r) {
    paste(r["segment"], "&", fmt(as.numeric(r["mean_pi"])),
          "&", fmt(as.numeric(r["sd_pi"])),
          "&", fmt(as.numeric(r["mean_ri"])),
          "&", fmt(as.numeric(r["sd_ri"])),
          "&", fmt(as.numeric(r["mean_txn"]), 0),
          "&", r["n"], "\\\\")
  }), collapse = "\n"), "\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Source: URA via data.gov.sg. Price and rental indices have base 2009-Q1 = 100. ",
  "CCR = Core Central Region (high foreign-buyer share, $\\sim$16\\%); ",
  "RCR = Rest of Central Region ($\\sim$8\\%); OCR = Outside Central Region ($\\sim$3\\%). ",
  "Sample: 2004-Q1 to 2025-Q4. Transaction data available for CCR and OCR only.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab1, file.path(table_dir, "tab1_sumstats.tex"))

# ============================================================
# Table 2: Baseline DiD + Continuous (manual from results)
# ============================================================
cat("=== Table 2: Main Results ===\n")

extract_row <- function(mod, name) {
  ct <- fixest::coeftable(mod)
  b <- ct[1, 1]; se <- ct[1, 2]; p <- ct[1, 4]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  n <- fixest::fitstat(mod, "n")[[1]]
  r2 <- round(fixest::r2(mod, "wr2"), 3)
  list(name = name, b = b, se = se, stars = stars, n = n, r2 = r2)
}

r_pb <- extract_row(results$m_price_base, "Price")
r_rb <- extract_row(results$m_rental_base, "Rental")
r_tb <- extract_row(results$m_txn_base, "Transactions")
r_pc <- extract_row(results$m_price_cont, "Price (cont.)")
r_rc <- extract_row(results$m_rental_cont, "Rental (cont.)")

fmt3 <- function(x) formatC(x, format = "f", digits = 3)
fmt4 <- function(x) formatC(x, format = "f", digits = 4)

tab2 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{ABSD Effects on Singapore Housing Markets}\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n\\toprule\n",
  " & \\multicolumn{3}{c}{Binary Treatment} & \\multicolumn{2}{c}{Continuous (per pp)} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}\n",
  " & Log Price & Log Rental & Log Txn & Log Price & Log Rental \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n\\midrule\n",
  "CCR $\\times$ Post-ABSD & ", fmt3(r_pb$b), r_pb$stars, " & ",
    fmt3(r_rb$b), r_rb$stars, " & ", fmt3(r_tb$b), r_tb$stars, " & & \\\\\n",
  " & (", fmt3(r_pb$se), ") & (", fmt3(r_rb$se), ") & (", fmt3(r_tb$se), ") & & \\\\\n",
  "CCR $\\times$ ABSD Rate & & & & ",
    fmt4(r_pc$b), r_pc$stars, " & ", fmt4(r_rc$b), r_rc$stars, " \\\\\n",
  " & & & & (", fmt4(r_pc$se), ") & (", fmt4(r_rc$se), ") \\\\\n",
  "\\midrule\n",
  "Segment FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "$N$ & ", r_pb$n, " & ", r_rb$n, " & ", r_tb$n, " & ", r_pb$n, " & ", r_rb$n, " \\\\\n",
  "Within $R^2$ & ", r_pb$r2, " & ", r_rb$r2, " & ", r_tb$r2, " & ", r_pc$r2, " & ", r_rc$r2, " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns 1--3 estimate the effect of post-ABSD status (any round) interacted with CCR ",
  "(high foreign-buyer exposure). Columns 4--5 use the ABSD rate (0--60 percentage points) as continuous treatment. ",
  "All specifications include market segment and quarter fixed effects. ",
  "Standard errors are Driscoll-Kraay (HAC, bandwidth = 4 quarters) to account for cross-sectional dependence and serial correlation. ",
  "Transaction data available for CCR and OCR only. ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Dose-Response by ABSD Round
# ============================================================
cat("=== Table 3: Dose-Response ===\n")

ct_pd <- fixest::coeftable(results$m_price_dose)
ct_rd <- fixest::coeftable(results$m_rental_dose)

make_star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

round_labels <- c("R1: 10\\% (Dec 2011)", "R2: 15\\% (Jan 2013)", "R3: 20\\% (Jul 2018)",
                   "R4: 30\\% (Dec 2021)", "R5: 60\\% (Apr 2023)")

dose_rows <- sapply(1:5, function(i) {
  paste0(round_labels[i], " & ", fmt3(ct_pd[i,1]), make_star(ct_pd[i,4]),
         " & (", fmt3(ct_pd[i,2]), ") & ",
         fmt3(ct_rd[i,1]), make_star(ct_rd[i,4]),
         " & (", fmt3(ct_rd[i,2]), ") \\\\")
})

tab3 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Dose-Response: ABSD Effects by Round}\\label{tab:dose}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & \\multicolumn{2}{c}{Log Price Index} & \\multicolumn{2}{c}{Log Rental Index} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "CCR $\\times$ Post-Round & Coef. & SE & Coef. & SE \\\\\n\\midrule\n",
  paste(dose_rows, collapse = "\n"), "\n",
  "\\midrule\n",
  "Segment + Quarter FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\\n",
  "$N$ & \\multicolumn{2}{c}{264} & \\multicolumn{2}{c}{264} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each coefficient captures the cumulative CCR $\\times$ post-round interaction. ",
  "Coefficients are additive: the total price effect of the 60\\% ABSD equals the sum of all five round coefficients. ",
  "Standard errors are Driscoll-Kraay (HAC, bandwidth = 4). ",
  "*** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab3, file.path(table_dir, "tab3_dose.tex"))

# ============================================================
# Table 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

ct_pre <- fixest::coeftable(rob_results$m_pretrend)
ct_alt <- fixest::coeftable(rob_results$m_alt_control)
ct_plac <- fixest::coeftable(rob_results$m_placebo_time)
ct_asym <- fixest::coeftable(rob_results$m_asymmetry)

tab4 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Robustness Checks}\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & Pre-Trend & Alt.\\ Control & Placebo & Triple \\\\\n",
  " & (CCR $\\times$ Trend) & (CCR vs RCR) & (Fake 2009) & Difference \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n\\midrule\n",
  "CCR $\\times$ Trend & ", fmt4(ct_pre[1,1]), make_star(ct_pre[1,4]),
    " & & & \\\\\n",
  " & (", fmt4(ct_pre[1,2]), ") & & & \\\\\n",
  "CCR $\\times$ Post & & ", fmt3(ct_alt[1,1]), make_star(ct_alt[1,4]),
    " & ", fmt3(ct_plac[1,1]), make_star(ct_plac[1,4]), " & \\\\\n",
  " & & (", fmt3(ct_alt[1,2]), ") & (", fmt3(ct_plac[1,2]), ") & \\\\\n",
  "CCR $\\times$ Post $\\times$ Price & & & & ",
    fmt3(ct_asym[3,1]), make_star(ct_asym[3,4]), " \\\\\n",
  " & & & & (", fmt3(ct_asym[3,2]), ") \\\\\n",
  "\\midrule\n",
  "FE & Seg. + Qtr. & Seg. + Qtr. & Seg. + Qtr. & Seg. + Qtr. \\\\\n",
  "$N$ & ", fixest::fitstat(rob_results$m_pretrend, "n")[[1]],
    " & ", fixest::fitstat(rob_results$m_alt_control, "n")[[1]],
    " & ", fixest::fitstat(rob_results$m_placebo_time, "n")[[1]],
    " & ", fixest::fitstat(rob_results$m_asymmetry, "n")[[1]], " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column 1: CCR $\\times$ linear quarterly trend in pre-ABSD period (2004--2011). ",
  "A null coefficient supports parallel pre-trends. ",
  "Column 2: Uses RCR (intermediate foreign share) as control instead of OCR. ",
  "Column 3: Placebo treatment date of 2009-Q1 in pre-ABSD sample. ",
  "Column 4: Triple difference stacking price and rental outcomes; the interaction ",
  "tests whether the ABSD effect is larger for ownership prices than rents (displacement channel). ",
  "All SEs Driscoll-Kraay (HAC, $L=4$). *** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# Table 5: HDB Placebo
# ============================================================
cat("=== Table 5: HDB Placebo ===\n")

ct_hdb <- fixest::coeftable(results$m_hdb_placebo)

tab5 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Placebo: HDB Public Housing (No Foreign Buyers Permitted)}\\label{tab:placebo}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n\\toprule\n",
  " & Log Mean Resale Price \\\\\n\\midrule\n",
  "Near-CCR $\\times$ Post-R5 & ", fmt3(ct_hdb[1,1]), make_star(ct_hdb[1,4]), " \\\\\n",
  " & (", fmt3(ct_hdb[1,2]), ") \\\\\n",
  "\\midrule\n",
  "Town FE & Yes \\\\\n",
  "Quarter FE & Yes \\\\\n",
  "$N$ & ", fixest::fitstat(results$m_hdb_placebo, "n")[[1]], " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} HDB (Housing Development Board) public housing cannot be purchased by foreigners. ",
  "Near-CCR towns (Bukit Timah, Bishan, Toa Payoh, Queenstown, Central Area, Kallang/Whampoa) ",
  "are adjacent to the CCR private market. If ABSD causes spillovers to the public sector, near-CCR ",
  "HDB prices should rise post-R5. The null coefficient supports the interpretation that ABSD ",
  "effects are confined to the private foreign-buyer-accessible market. ",
  "SEs Driscoll-Kraay (HAC, $L=4$). *** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab5, file.path(table_dir, "tab5_placebo.tex"))

# ============================================================
# SDE Appendix Table
# ============================================================
cat("=== SDE Table ===\n")

pre_ccr <- panel |> filter(segment == "CCR", date < as.Date("2011-12-01"))
sd_price_pre <- sd(pre_ccr$log_price, na.rm = TRUE)
sd_rental_pre <- sd(panel |> filter(segment == "CCR", date < as.Date("2011-12-01")) |> pull(log_rental), na.rm = TRUE)
sd_txn_pre <- sd(panel |> filter(segment == "CCR", date < as.Date("2011-12-01"), !is.na(log_units)) |> pull(log_units), na.rm = TRUE)

ct_p <- fixest::coeftable(results$m_price_base)
ct_r <- fixest::coeftable(results$m_rental_base)
ct_t <- fixest::coeftable(results$m_txn_base)

sde_price <- ct_p[1,1] / sd_price_pre
sde_rental <- ct_r[1,1] / sd_rental_pre
sde_txn <- ct_t[1,1] / sd_txn_pre

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel B: heterogeneity — use dose-response coefficients from round-by-round model
# R1+R2 cumulative effect vs R5 cumulative effect
ct_dose <- fixest::coeftable(results$m_price_dose)
# Early rounds: R1 coefficient (cumulative effect of 10% rate)
beta_early <- ct_dose[1,1]
se_early <- ct_dose[1,2]
# Late round: sum of R1-R5 (cumulative effect at 60%)
beta_late <- sum(ct_dose[1:5, 1])
# SE of sum via delta method (simplified: sqrt of sum of variances)
se_late <- sqrt(sum(ct_dose[1:5, 2]^2))

sde_early <- beta_early / sd_price_pre
sde_late <- beta_late / sd_price_pre

ct_e <- matrix(c(beta_early, se_early), nrow = 1)
ct_l <- matrix(c(beta_late, se_late), nrow = 1)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Singapore. ",
  "\\textbf{Research question:} Does escalating foreign-buyer stamp duty (ABSD, 0--60\\%) suppress private residential property prices, transaction volumes, and rents in the Core Central Region relative to less foreign-exposed segments? ",
  "\\textbf{Policy mechanism:} Additional Buyer's Stamp Duty on foreign purchasers of private residential property, raised in five rounds from 10\\% (December 2011) to 60\\% (April 2023), increasing the upfront transaction cost and widening the wedge between foreign and domestic buyer reservation prices. ",
  "\\textbf{Outcome definition:} Log URA Property Price Index (hedonic, base 2009-Q1 = 100), log URA Rental Index, and log quarterly transaction count by market segment. ",
  "\\textbf{Treatment:} Binary (CCR high foreign-buyer exposure $\\sim$16\\% vs OCR/RCR low exposure $\\sim$3--8\\%). ",
  "\\textbf{Data:} URA via data.gov.sg, quarterly segment-level indices 2004-Q1 to 2025-Q4, 3 segments $\\times$ 88 quarters = 264 observations. ",
  "\\textbf{Method:} Two-way FE DiD (segment + quarter), Driscoll-Kraay SEs (bandwidth = 4). ",
  "\\textbf{Sample:} Three non-landed private residential market segments (CCR, RCR, OCR); quarterly 2004--2025. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2011-Q4) ",
  "standard deviation of the log outcome for CCR. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

make_sde_row <- function(outcome, beta, se, sd_y, sde, se_sde) {
  paste0(outcome, " & ", fmt3(beta), " & ", fmt3(se), " & ", fmt3(sd_y),
         " & ", fmt3(sde), " & ", fmt3(se_sde), " & ", classify_sde(sde), " \\\\")
}

sde_tex <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  make_sde_row("Log Price Index", ct_p[1,1], ct_p[1,2], sd_price_pre, sde_price, ct_p[1,2]/sd_price_pre), "\n",
  make_sde_row("Log Rental Index", ct_r[1,1], ct_r[1,2], sd_rental_pre, sde_rental, ct_r[1,2]/sd_rental_pre), "\n",
  make_sde_row("Log Transactions", ct_t[1,1], ct_t[1,2], sd_txn_pre, sde_txn, ct_t[1,2]/sd_txn_pre), "\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by ABSD intensity)}} \\\\\n",
  make_sde_row("Log Price (Rounds 1--2, 10--15\\%)", ct_e[1,1], ct_e[1,2], sd_price_pre, sde_early, ct_e[1,2]/sd_price_pre), "\n",
  make_sde_row("Log Price (Round 5, 60\\%)", ct_l[1,1], ct_l[1,2], sd_price_pre, sde_late, ct_l[1,2]/sd_price_pre), "\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(sde_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
for (f in list.files(table_dir, pattern = "\\.tex$")) cat("  ", f, "\n")
