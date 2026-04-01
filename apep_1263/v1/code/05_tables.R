## 05_tables.R — Generate all tables for paper
## apep_1263: The Opt-Out Illusion

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

## ---- Table 1: Summary Statistics by Nation and Treatment Status ----

sumstats <- panel[, .(
  Years = .N,
  `Mean DD pmp` = round(mean(dd_pmp), 1),
  `SD DD pmp` = round(sd(dd_pmp), 1),
  `Mean TX pmp` = round(mean(tx_pmp), 1),
  `Mean LD pmp` = round(mean(ld_pmp), 1),
  `Opt-Out FY` = paste0(cohort[1], "/", substr(cohort[1]+1, 3, 4))
), by = nation]

sumstats_pre <- panel[optout == 0, .(
  `Pre-Treatment DD pmp` = round(mean(dd_pmp), 1),
  `Pre-Treatment TX pmp` = round(mean(tx_pmp), 1)
), by = nation]

sumstats_post <- panel[optout == 1, .(
  `Post-Treatment DD pmp` = round(mean(dd_pmp), 1),
  `Post-Treatment TX pmp` = round(mean(tx_pmp), 1)
), by = nation]

tab1_data <- merge(merge(sumstats_pre, sumstats_post, by = "nation", all = TRUE),
                   sumstats[, .(nation, `Opt-Out FY`)], by = "nation")

# Write Table 1
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Nation}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat(" & Opt-Out & \\multicolumn{2}{c}{Pre-Treatment} & \\multicolumn{2}{c}{Post-Treatment} & Pre--Post \\\\\n")
cat("\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}\n")
cat("Nation & Effective & DD pmp & TX pmp & DD pmp & TX pmp & $\\Delta$ DD pmp \\\\\n")
cat("\\midrule\n")

for (n in c("Wales", "England", "Scotland", "Northern Ireland")) {
  row <- tab1_data[nation == n]
  pre_dd <- row$`Pre-Treatment DD pmp`
  post_dd <- row$`Post-Treatment DD pmp`
  delta <- if (!is.na(post_dd) && !is.na(pre_dd)) round(post_dd - pre_dd, 1) else "---"
  post_dd_str <- if (is.na(post_dd)) "---" else as.character(post_dd)
  post_tx_str <- if (is.na(row$`Post-Treatment TX pmp`)) "---" else as.character(row$`Post-Treatment TX pmp`)
  cat(sprintf("%s & %s & %.1f & %.1f & %s & %s & %s \\\\\n",
              n, row$`Opt-Out FY`, pre_dd, row$`Pre-Treatment TX pmp`,
              post_dd_str, post_tx_str, delta))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} DD = deceased donors; TX = transplants from deceased donors; ")
cat("pmp = per million population. Pre-treatment and post-treatment means computed ")
cat("over financial years (April--March). Population denominators from ONS mid-year estimates. ")
cat("Source: NHSBT Annual Activity Reports 2015/16--2024/25.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ---- Table 2: Main DiD Results ----

m1 <- feols(dd_pmp ~ optout | nation + year, data = panel)
m2 <- feols(tx_pmp ~ optout | nation + year, data = panel)
m3 <- feols(ld_pmp ~ optout | nation + year, data = panel)
m4 <- feols(dd_pmp ~ optout | nation + year, data = panel[covid == 0])
m5 <- feols(tx_pmp ~ optout | nation + year, data = panel[covid == 0])

sink("../tables/tab2_did.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Opt-Out Legislation on Organ Donation}\n")
cat("\\label{tab:did}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & \\multicolumn{3}{c}{Full Sample} & \\multicolumn{2}{c}{Excl.\\ COVID Year} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}\n")
cat(" & DD pmp & TX pmp & LD pmp & DD pmp & TX pmp \\\\\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("\\midrule\n")

# Get coefficients and SEs
get_coef_se <- function(m, var = "optout") {
  b <- coef(m)[var]
  se <- sqrt(vcov(m, vcov = "hetero")[var, var])
  list(b = b, se = se)
}

cs <- list(get_coef_se(m1), get_coef_se(m2), get_coef_se(m3),
           get_coef_se(m4), get_coef_se(m5))

cat(sprintf("Opt-Out & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n",
            cs[[1]]$b, cs[[2]]$b, cs[[3]]$b, cs[[4]]$b, cs[[5]]$b))
cat(sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\\n",
            cs[[1]]$se, cs[[2]]$se, cs[[3]]$se, cs[[4]]$se, cs[[5]]$se))

# RI p-values
cat(sprintf("RI $p$-value & %.3f & %.3f & %.3f & --- & --- \\\\\n",
            results$main$dd$ri_p, results$main$tx$ri_p, results$main$ld$ri_p))

cat("\\midrule\n")
cat(sprintf("Nation FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
            nrow(panel), nrow(panel), nrow(panel),
            nrow(panel[covid==0]), nrow(panel[covid==0])))
cat(sprintf("Nations & 4 & 4 & 4 & 4 & 4 \\\\\n"))
cat(sprintf("Pre-treat mean & %.1f & %.1f & %.1f & --- & --- \\\\\n",
            panel[optout == 0, mean(dd_pmp)],
            panel[optout == 0, mean(tx_pmp)],
            panel[optout == 0, mean(ld_pmp)]))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} ")
cat("Two-way fixed effects estimates with nation and year fixed effects. ")
cat("Heteroskedasticity-robust standard errors in parentheses. ")
cat("RI $p$-values from 5{,}000 permutations of treatment assignment across nations. ")
cat("DD = deceased donors; TX = transplants; LD = living donors; pmp = per million population. ")
cat("Column (3) is a placebo: living donor rates should not respond to deceased consent legislation. ")
cat("Columns (4)--(5) exclude the COVID-disrupted year 2020/21. ")
cat("Source: NHSBT Annual Activity Reports 2015/16--2024/25.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ---- Table 3: Deemed Consent Authorization Rates (The Paradox) ----

consent_panel <- panel[!is.na(consent_rate)]

sink("../tables/tab3_paradox.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{The Paradox: Consent Rates vs.\\ Deemed Consent Authorization}\n")
cat("\\label{tab:paradox}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & 2021/22 & 2022/23 & 2023/24 & 2024/25 \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Overall Consent/Authorisation Rate (\\%)}} \\\\\n")
for (n in c("England", "Wales", "Scotland", "Northern Ireland")) {
  vals <- consent_panel[nation == n, consent_rate]
  vals_str <- sprintf("%.1f", vals)
  cat(sprintf("\\quad %s & %s \\\\\n", n, paste(vals_str, collapse = " & ")))
}
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel B: Deemed Consent Authorisation Rate (\\%)}} \\\\\n")
for (n in c("England", "Wales", "Scotland", "Northern Ireland")) {
  vals <- consent_panel[nation == n, deemed_consent_rate]
  vals_str <- ifelse(is.na(vals), "---", sprintf("%.1f", vals))
  cat(sprintf("\\quad %s & %s \\\\\n", n, paste(vals_str, collapse = " & ")))
}
cat("\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel C: Family Overrides of Expressed Opt-In}} \\\\\n")
for (n in c("England", "Wales", "Scotland", "Northern Ireland")) {
  vals <- consent_panel[nation == n, family_overrides]
  vals_str <- as.character(vals)
  cat(sprintf("\\quad %s & %s \\\\\n", n, paste(vals_str, collapse = " & ")))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} ")
cat("Panel A shows the overall consent/authorisation rate combining DBD and DCD donors. ")
cat("Panel B shows the authorisation rate when deemed consent applies --- i.e., when the ")
cat("patient had not made an explicit decision. Values below 50\\% indicate that families ")
cat("decline donation in the majority of deemed consent cases. ")
cat("Panel C shows the number of families who overruled their loved one's expressed opt-in ")
cat("decision on the Organ Donor Register. ")
cat("Northern Ireland adopted opt-out in June 2023; deemed consent rates unavailable for earlier years. ")
cat("Source: NHSBT Potential Donor Audit, Annual Activity Reports.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ---- Table 4: Robustness ----

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness of Opt-Out Effect on Deceased Donors pmp}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Specification & $\\hat{\\beta}$ & SE & Nations & Obs. \\\\\n")
cat("\\midrule\n")

# Main
cat(sprintf("Main (levels) & %.2f & %.2f & 4 & %d \\\\\n",
            coef(m1)["optout"], sqrt(vcov(m1, "hetero")["optout","optout"]), nrow(panel)))

# Leave-one-out
loo <- rob$loo
for (i in seq_len(nrow(loo))) {
  cat(sprintf("Drop %s & %.2f & %.2f & 3 & %d \\\\\n",
              loo$dropped[i], loo$beta[i], loo$se[i], loo$n[i]))
}

# Exclude COVID
cat(sprintf("Excl.\\ COVID year & %.2f & %.2f & 4 & %d \\\\\n",
            coef(m4)["optout"], sqrt(vcov(m4, "hetero")["optout","optout"]),
            nrow(panel[covid == 0])))

# Log
m_log <- feols(ln_dd_pmp ~ optout | nation + year, data = panel)
cat(sprintf("Log specification & %.3f & %.3f & 4 & %d \\\\\n",
            coef(m_log)["optout"],
            sqrt(vcov(m_log, "hetero")["optout","optout"]),
            nrow(panel)))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} ")
cat("All specifications include nation and year fixed effects. ")
cat("Heteroskedasticity-robust standard errors reported. ")
cat("``Drop X'' removes nation X from the sample. ")
cat("Source: NHSBT Annual Activity Reports 2015/16--2024/25.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ---- SDE Table (Appendix) ----

# Standardized effect sizes
pre_sd_dd <- panel[optout == 0, sd(dd_pmp)]
pre_sd_tx <- panel[optout == 0, sd(tx_pmp)]
pre_sd_ld <- panel[optout == 0, sd(ld_pmp)]

beta_dd <- coef(m1)["optout"]
beta_tx <- coef(m2)["optout"]
beta_ld <- coef(m3)["optout"]
se_dd <- sqrt(vcov(m1, "hetero")["optout","optout"])
se_tx <- sqrt(vcov(m2, "hetero")["optout","optout"])
se_ld <- sqrt(vcov(m3, "hetero")["optout","optout"])

sde_dd <- beta_dd / pre_sd_dd
sde_tx <- beta_tx / pre_sd_tx
sde_ld <- beta_ld / pre_sd_ld
se_sde_dd <- se_dd / pre_sd_dd
se_sde_tx <- se_tx / pre_sd_tx
se_sde_ld <- se_ld / pre_sd_ld

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: split by early vs late adopters
early <- panel[nation %in% c("Wales", "England")]
late <- panel[nation %in% c("Scotland", "Northern Ireland")]

m_early <- feols(dd_pmp ~ optout | nation + year, data = early)
m_late <- feols(dd_pmp ~ optout | nation + year, data = late)

beta_early <- coef(m_early)["optout"]
beta_late <- coef(m_late)["optout"]
se_early <- sqrt(vcov(m_early, "hetero")["optout","optout"])
se_late <- sqrt(vcov(m_late, "hetero")["optout","optout"])

pre_sd_early <- early[optout == 0, sd(dd_pmp)]
pre_sd_late <- late[optout == 0, sd(dd_pmp)]

sde_early <- beta_early / pre_sd_early
sde_late <- beta_late / pre_sd_late
se_sde_early <- se_early / pre_sd_early
se_sde_late <- se_late / pre_sd_late

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England, Wales, Scotland, Northern Ireland). ",
  "\\textbf{Research question:} Does opt-out (deemed consent) organ donation legislation increase deceased donor rates and transplantation? ",
  "\\textbf{Policy mechanism:} Deemed consent laws shift the legal default from requiring explicit opt-in registration to presuming consent unless the individual has actively opted out, effectively reclassifying non-registrants as potential donors and transferring the decision burden to families at the point of death. ",
  "\\textbf{Outcome definition:} Deceased donors per million population (dd\\_pmp), counting all donors from whom at least one organ was retrieved for transplant, per NHSBT definition. ",
  "\\textbf{Treatment:} Binary indicator equal to one from the first full financial year after deemed consent legislation took effect in each nation (Wales 2016/17, England 2020/21, Scotland 2021/22, Northern Ireland 2023/24). ",
  "\\textbf{Data:} NHSBT Annual Activity Reports, financial years 2015/16--2024/25, nation-year panel, 40 observations (4 nations $\\times$ 10 years). ",
  "\\textbf{Method:} Two-way fixed effects (nation + year FE), heteroskedasticity-robust SEs, randomization inference (5,000 permutations of treatment assignment). ",
  "\\textbf{Sample:} All four UK nations; treatment is staggered across nations (Wales first, NI last). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lS[table-format=-1.2]S[table-format=1.2]S[table-format=1.2]S[table-format=-1.3]S[table-format=1.3]l}\n")
cat("\\toprule\n")
cat("Outcome & {$\\hat{\\beta}$} & {SE} & {SD($Y$)} & {SDE} & {SE(SDE)} & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Deceased donors pmp & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_dd, se_dd, pre_sd_dd, sde_dd, se_sde_dd, classify_sde(sde_dd)))
cat(sprintf("Transplants pmp & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_tx, se_tx, pre_sd_tx, sde_tx, se_sde_tx, classify_sde(sde_tx)))
cat(sprintf("Living donors pmp & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_ld, se_ld, pre_sd_ld, sde_ld, se_sde_ld, classify_sde(sde_ld)))
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Early vs.\\ Late Adopters)}} \\\\\n")
cat(sprintf("Early adopters (W, E) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_early, se_early, pre_sd_early, sde_early, se_sde_early, classify_sde(sde_early)))
cat(sprintf("Late adopters (S, NI) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
            beta_late, se_late, pre_sd_late, sde_late, se_sde_late, classify_sde(sde_late)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes)
cat("\n\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated.\n")
