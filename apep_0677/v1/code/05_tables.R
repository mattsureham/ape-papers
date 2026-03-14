## 05_tables.R — Generate all tables for the paper

source("code/00_packages.R")

cat("=== GENERATING TABLES ===\n")

panel <- fread("data/panel.csv")
shares <- fread("data/eu_shares.csv")
models <- readRDS("data/main_models.rds")
rob <- readRDS("data/robustness_results.rds")
rob_models <- readRDS("data/robustness_models.rds")
diag <- jsonlite::fromJSON("data/diagnostics.json")

# ── Table 1: Summary Statistics ────────────────────────────────────
cat("\n--- Table 1: Summary Statistics ---\n")

# Pre-period (2018-2021) by commodity type × destination
pre <- panel[year <= 2021]

summ_stats <- pre[, .(
  `Mean Trade Value (\\$M)` = round(mean(trade_value / 1e6, na.rm = TRUE), 1),
  `SD Trade Value (\\$M)` = round(sd(trade_value / 1e6, na.rm = TRUE), 1),
  `Mean Quantity (kt)` = round(mean(trade_qty / 1e6, na.rm = TRUE), 1),
  Observations = .N
), by = .(
  `Commodity Type` = ifelse(regulated == 1, "EUDR Regulated", "Control"),
  `Destination` = dest_group
)]
setorder(summ_stats, `Commodity Type`, Destination)

# LaTeX output
sink("tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Pre-EUDR Bilateral Trade Flows (2018--2021)}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{llrrrr}\n")
cat("\\hline\\hline\n")
cat("Commodity Type & Destination & Mean Value & SD Value & Mean Qty & Obs. \\\\\n")
cat(" & & (\\$M) & (\\$M) & (kt) & \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ_stats)) {
  row <- summ_stats[i]
  cat(sprintf("%s & %s & %.1f & %.1f & %.1f & %d \\\\\n",
              as.character(row[[1]]), as.character(row[[2]]),
              as.numeric(row[[3]]), as.numeric(row[[4]]),
              as.numeric(row[[5]]), as.integer(row[[6]])))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\vspace{0.3em}\\footnotesize\n")
cat("\\textit{Notes:} Unit of observation is exporter $\\times$ HS4 commodity $\\times$ destination group $\\times$ year. Trade values in millions of US dollars; quantities in kilotonnes. EUDR-regulated commodities: cattle (0102), coffee (0901), soybeans (1201), palm oil (1511), cocoa (1801), rubber (4001), wood (4403). Control commodities: tea (0902), pepper (0904), coconut oil (1513), fruit juice (2009), tobacco (2401). Destination groups: EU-27, China, Other. Sample restricted to 10 major tropical commodity exporters.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tables/tab1_summary.tex\n")

# ── Table 2: Main DDD Results ─────────────────────────────────────
cat("\n--- Table 2: Main DDD Results ---\n")

sink("tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{The Trade Diversion Effect of the EU Deforestation Regulation}\n")
cat("\\label{tab:main}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & ln(Value) & ln(Value) & ln(Value) & ln(Quantity) \\\\\n")
cat("\\hline\n")

# Extract coefficients
get_star <- function(pv) {
  if (is.na(pv)) return("")
  if (pv < 0.01) return("$^{***}$")
  if (pv < 0.05) return("$^{**}$")
  if (pv < 0.1) return("$^{*}$")
  return("")
}

# Helper to extract DDD coefficient from coeftable
extract_coef <- function(model, pattern) {
  ct <- coeftable(model)
  idx <- grep(pattern, rownames(ct))
  if (length(idx) == 0) return(list(b = NA, se = NA, pv = NA))
  list(b = ct[idx[1], 1], se = ct[idx[1], 2], pv = ct[idx[1], 4])
}

# Model 1: Basic DDD (proposal)
r1 <- extract_coef(models$m1, "regulated.*eu_dest.*post_proposal")
b1 <- r1$b; se1 <- r1$se; pv1 <- r1$pv

# Model 2: DDD (passage)
r2 <- extract_coef(models$m2, "regulated.*eu_dest.*post_passage")
b2 <- r2$b; se2 <- r2$se; pv2 <- r2$pv

# Model 3: Saturated DDD
r3 <- extract_coef(models$m3, "ddd_proposal")
b3 <- r3$b; se3 <- r3$se; pv3 <- r3$pv

# Model 4: Quantity
r4 <- extract_coef(models$m4, "ddd_proposal")
b4 <- r4$b; se4 <- r4$se; pv4 <- r4$pv

cat(sprintf("Regulated $\\times$ EU $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            b1, get_star(pv1), b2, get_star(pv2), b3, get_star(pv3), b4, get_star(pv4)))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n", se1, se2, se3, se4))
cat("\\hline\n")
cat(sprintf("Post definition & Proposal & Passage & Proposal & Proposal \\\\\n"))
cat(sprintf("Fixed effects & Basic & Basic & Saturated & Saturated \\\\\n"))
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(models$m1), big.mark = ","),
            format(nobs(models$m2), big.mark = ","),
            format(nobs(models$m3), big.mark = ","),
            format(nobs(models$m4), big.mark = ",")))
cat(sprintf("R$^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
            r2(models$m1, "r2"), r2(models$m2, "r2"), r2(models$m3, "r2"), r2(models$m4, "r2")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\vspace{0.3em}\\footnotesize\n")
cat("\\textit{Notes:} Triple-difference estimates. Dependent variable is log bilateral trade value (columns 1--3) or log quantity (column 4). ``Proposal'' defines post as 2022+ (EU Commission proposal November 2021); ``Passage'' defines post as 2023+ (regulation entered into force June 2023). ``Basic'' includes exporter, commodity, destination, and year fixed effects plus all two-way interactions. ``Saturated'' includes commodity$\\times$destination, commodity$\\times$year, destination$\\times$year, and exporter fixed effects. Standard errors clustered at commodity and destination level in parentheses. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tables/tab2_main.tex\n")

# ── Table 3: EU Share and China Diversion ──────────────────────────
cat("\n--- Table 3: EU Share + China Diversion ---\n")

r6 <- extract_coef(models$m6, "regulated.*post_proposal")
b6 <- c(r6$b); se6_val <- c(r6$se); pv6 <- c(r6$pv)

r7 <- extract_coef(models$m7, "china_ddd")
b7 <- r7$b; se7 <- r7$se; pv7 <- r7$pv

sink("tables/tab3_diversion.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Where Do Diverted Exports Go? EU Share Decline and China Absorption}\n")
cat("\\label{tab:diversion}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) \\\\\n")
cat(" & EU Import Share & ln(Value to China) \\\\\n")
cat("\\hline\n")
cat(sprintf("Regulated $\\times$ Post & %.4f%s & \\\\\n", b6[1], get_star(pv6[1])))
cat(sprintf(" & (%.4f) & \\\\\n", se6_val[1]))
cat(sprintf("Regulated $\\times$ China $\\times$ Post & & %.3f%s \\\\\n", b7, get_star(pv7)))
cat(sprintf(" & & (%.3f) \\\\\n", se7))
cat("\\hline\n")
cat(sprintf("Observations & %s & %s \\\\\n",
            format(nobs(models$m6), big.mark = ","),
            format(nobs(models$m7), big.mark = ",")))
cat(sprintf("R$^2$ & %.3f & %.3f \\\\\n", r2(models$m6, "r2"), r2(models$m7, "r2")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\vspace{0.3em}\\footnotesize\n")
cat("\\textit{Notes:} Column 1: dependent variable is EU-27 share of each exporter's total exports of each commodity (exporter$\\times$commodity$\\times$year level). Column 2: triple-difference with China as destination instead of EU (panel level). Post defined as 2022+. All specifications include exporter, commodity, and year fixed effects. Standard errors clustered at commodity level. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.1.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tables/tab3_diversion.tex\n")

# ── Table 4: Robustness ───────────────────────────────────────────
cat("\n--- Table 4: Robustness ---\n")

loo <- fread("data/loo_results.csv")

# Map HS codes to commodity names
hs_names <- c("0102" = "Cattle", "0901" = "Coffee", "1201" = "Soybeans",
              "1511" = "Palm oil", "1801" = "Cocoa", "4001" = "Rubber",
              "4403" = "Wood")

sink("tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Leave-One-Out Commodity and Exporter Heterogeneity}\n")
cat("\\label{tab:robust}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat("Specification & DDD Coefficient & SE \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Leave-one-out commodity}} \\\\\n")
for (i in 1:nrow(loo)) {
  hs <- loo$dropped_commodity[i]
  name <- hs_names[hs]
  cat(sprintf("\\quad Drop %s (%s) & %.3f & (%.3f) \\\\\n",
              name, hs, loo$coef[i], loo$se[i]))
}
cat("\\hline\n")
cat("\\multicolumn{3}{l}{\\textit{Panel B: Exporter risk classification}} \\\\\n")

b_sr <- coef(rob_models$m_high)["ddd_proposal"]
se_sr <- sqrt(vcov(rob_models$m_high)["ddd_proposal", "ddd_proposal"])
b_lr <- coef(rob_models$m_low)["ddd_proposal"]
se_lr <- sqrt(vcov(rob_models$m_low)["ddd_proposal", "ddd_proposal"])

cat(sprintf("\\quad Standard-risk exporters & %.3f & (%.3f) \\\\\n", b_sr, se_sr))
cat(sprintf("\\quad Other exporters & %.3f & (%.3f) \\\\\n", b_lr, se_lr))
cat("\\hline\n")
cat("\\multicolumn{3}{l}{\\textit{Panel C: Inference}} \\\\\n")
cat(sprintf("\\quad Randomization inference $p$-value & \\multicolumn{2}{c}{%.3f} \\\\\n",
            rob$ri_pval))

b_alt <- coef(rob_models$m_alt)["ddd_passage"]
se_alt <- sqrt(vcov(rob_models$m_alt)["ddd_passage", "ddd_passage"])
cat(sprintf("\\quad Alternative timing (passage 2023+) & %.3f & (%.3f) \\\\\n", b_alt, se_alt))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\vspace{0.3em}\\footnotesize\n")
cat("\\textit{Notes:} Panel A drops one regulated commodity at a time from the saturated DDD specification. Panel B splits the sample by EUDR country risk classification: standard-risk exporters (Brazil, Indonesia, Colombia, C\\^ote d'Ivoire, Ghana) vs.\\ others. Panel C reports randomization inference $p$-value from 200 random commodity-treatment permutations and an alternative specification using passage (2023+) instead of proposal (2022+) as the post-period cutoff. All specifications use the saturated fixed effects structure from Table~\\ref{tab:main}, Column 3.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tables/tab4_robustness.tex\n")

# ── Table F1: Standardized Effect Sizes (SDE) ─────────────────────
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

# Compute SDE for main outcomes
sd_ln_value <- sd(panel$ln_value, na.rm = TRUE)
sd_ln_qty <- sd(panel$ln_qty, na.rm = TRUE)
sd_eu_share <- sd(shares$eu_share, na.rm = TRUE)

# Main DDD (value)
sde_value <- b3 / sd_ln_value
sde_value_se <- se3 / sd_ln_value

# DDD (quantity)
sde_qty <- b4 / sd_ln_qty
sde_qty_se <- se4 / sd_ln_qty

# EU share
sde_share <- b6[1] / sd_eu_share
sde_share_se <- se6_val[1] / sd_eu_share

# China DDD
sde_china <- b7 / sd_ln_value
sde_china_se <- se7 / sd_ln_value

classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sink("tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lrrrrrr}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat(sprintf("ln(Trade Value) to EU & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            b3, se3, sd_ln_value, sde_value, sde_value_se, classify_sde(sde_value)))
cat(sprintf("ln(Quantity) to EU & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            b4, se4, sd_ln_qty, sde_qty, sde_qty_se, classify_sde(sde_qty)))
cat(sprintf("EU Import Share & %.4f & %.4f & %.2f & %.3f & %.3f & %s \\\\\n",
            b6[1], se6_val[1], sd_eu_share, sde_share, sde_share_se, classify_sde(sde_share)))
cat(sprintf("ln(Trade Value) to China & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
            b7, se7, sd_ln_value, sde_china, sde_china_se, classify_sde(sde_china)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\vspace{0.3em}\\footnotesize\n")
cat("\\textit{Notes:} Standardized effect sizes computed as SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. This paper estimates the triple-difference effect of the EU Deforestation Regulation on bilateral commodity trade. Data: UN Comtrade bilateral trade flows for 12 commodities (7 regulated, 5 control) across 10 exporters and 3 destination groups, 2018--2024 ($N = ", format(nrow(panel), big.mark = ","), "$). Method: saturated triple-difference with commodity$\\times$destination, commodity$\\times$year, destination$\\times$year, and exporter fixed effects. Classification is based on SDE magnitude and refers to effect size, not statistical significance.\n", sep = "")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()
cat("Wrote tables/tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
