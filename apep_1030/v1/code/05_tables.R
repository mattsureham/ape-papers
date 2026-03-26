## 05_tables.R — Generate all LaTeX tables
## apep_1030: EU Deposit Return Schemes and Packaging Waste Recycling

source("00_packages.R")

df        <- readRDS("../data/analysis_panel.rds")
cs_att    <- readRDS("../data/cs_att.rds")
ddd_fit   <- readRDS("../data/ddd_fit.rds")
twfe_fit  <- readRDS("../data/twfe_fit.rds")
ddd_no_de <- readRDS("../data/ddd_no_de.rds")
ddd_alt   <- readRDS("../data/ddd_alt_glass.rds")
dose_fit  <- readRDS("../data/dose_fit.rds")

dir.create("../tables", showWarnings = FALSE)

stars <- function(p) {
  if (length(p) == 0 || is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("=== Table 1 ===\n")

sumtab <- df %>%
  filter(material != "Total", !is.na(recycle_rate), !is.na(first_treat)) %>%
  mutate(drs_status = ifelse(drs_adopted == 1, "Post-DRS", "Pre/No DRS")) %>%
  group_by(material, drs_status) %>%
  summarise(N = n(), Mean = round(mean(recycle_rate), 1),
            SD = round(sd(recycle_rate), 1), .groups = "drop")

# Pivot for table
pre <- sumtab %>% filter(drs_status == "Pre/No DRS") %>% select(-drs_status) %>%
  rename(N_pre = N, Mean_pre = Mean, SD_pre = SD)
post <- sumtab %>% filter(drs_status == "Post-DRS") %>% select(-drs_status) %>%
  rename(N_post = N, Mean_post = Mean, SD_post = SD)
tab <- full_join(pre, post, by = "material")

tab1_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics: Packaging Waste Recycling Rates by Material}\n",
  "\\label{tab:summary}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrrr}\n\\toprule\n",
  " & \\multicolumn{3}{c}{Pre/No DRS} & \\multicolumn{3}{c}{Post-DRS} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  "Material & N & Mean & SD & N & Mean & SD \\\\\n\\midrule\n"
)

for (i in 1:nrow(tab)) {
  tab1_tex <- paste0(tab1_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    tab$material[i],
    ifelse(is.na(tab$N_pre[i]), "---", format(tab$N_pre[i], big.mark = ",")),
    ifelse(is.na(tab$Mean_pre[i]), "---", tab$Mean_pre[i]),
    ifelse(is.na(tab$SD_pre[i]), "---", tab$SD_pre[i]),
    ifelse(is.na(tab$N_post[i]), "---", format(tab$N_post[i], big.mark = ",")),
    ifelse(is.na(tab$Mean_post[i]), "---", tab$Mean_post[i]),
    ifelse(is.na(tab$SD_post[i]), "---", tab$SD_post[i])
  ))
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Recycling rates (\\%) from Eurostat (cei\\_wm020), 2000--2023. ",
  "``Pre/No DRS'' includes country-year observations before DRS adoption or in never-DRS countries. ",
  "``Post-DRS'' includes observations after adoption. ",
  "Always-treated countries (Finland, Sweden) excluded from estimation sample.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------
cat("=== Table 2 ===\n")

cs_coef  <- cs_att$overall.att
cs_se    <- cs_att$overall.se
cs_p     <- 2 * pnorm(-abs(cs_coef / cs_se))

ddd_coef <- coef(ddd_fit)["drs_adopted:targeted_num"]
ddd_se   <- se(ddd_fit)["drs_adopted:targeted_num"]
ddd_p    <- 2 * pnorm(-abs(ddd_coef / ddd_se))

twfe_coef <- coef(twfe_fit)["drs_adopted"]
twfe_se   <- se(twfe_fit)["drs_adopted"]
twfe_p    <- 2 * pnorm(-abs(twfe_coef / twfe_se))

cs_n    <- 342  # balanced panel
ddd_n   <- nrow(readRDS("../data/ddd_data.rds"))
twfe_n  <- 583

tab2_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Effect of Deposit Return Schemes on Packaging Waste Recycling}\n",
  "\\label{tab:main}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & CS ATT & DDD & TWFE \\\\\n",
  " & Total Rate & Targeted vs.\\ Non-Targeted & Total Rate \\\\\n",
  "\\midrule\n",
  sprintf("DRS Adopted & %s%s & & %s%s \\\\\n",
          format(round(cs_coef, 2), nsmall = 2), stars(cs_p),
          format(round(twfe_coef, 2), nsmall = 2), stars(twfe_p)),
  sprintf(" & (%s) & & (%s) \\\\\n",
          format(round(cs_se, 2), nsmall = 2),
          format(round(twfe_se, 2), nsmall = 2)),
  sprintf("DRS $\\times$ Targeted & & %s%s & \\\\\n",
          format(round(ddd_coef, 2), nsmall = 2), stars(ddd_p)),
  sprintf(" & & (%s) & \\\\\n",
          format(round(ddd_se, 2), nsmall = 2)),
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(cs_n, big.mark = ","), format(ddd_n, big.mark = ","), format(twfe_n, big.mark = ",")),
  "Country $\\times$ Year FE & & $\\checkmark$ & \\\\\n",
  "Material $\\times$ Year FE & & $\\checkmark$ & \\\\\n",
  "Country $\\times$ Material FE & & $\\checkmark$ & \\\\\n",
  "Country \\& Year FE & $\\checkmark$ & & $\\checkmark$ \\\\\n",
  "Estimator & CS (2021) & OLS & OLS \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column~(1): Callaway--Sant'Anna (2021) aggregate ATT for total packaging recycling rate, never-treated control group, balanced panel 2005--2022. ",
  "Column~(2): triple-difference---DRS adoption $\\times$ targeted material (plastic, metal) relative to non-targeted (paper, wood)---with three sets of two-way fixed effects. ",
  "Column~(3): two-way FE for comparison. ",
  "Standard errors clustered at country level. ",
  "Always-treated countries (Finland, Sweden) excluded. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ---------------------------------------------------------------
# Table 3: Material-Specific Effects
# ---------------------------------------------------------------
cat("=== Table 3 ===\n")

mats <- c("Plastic", "Metal", "Paper", "Wood")
mat_fits <- lapply(mats, function(m) readRDS(paste0("../data/twfe_", tolower(m), ".rds")))
names(mat_fits) <- mats

tab3_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{DRS Effects by Material Type}\n\\label{tab:material}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lcccc}\n\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Plastic & Metal & Paper & Wood \\\\\n",
  " & \\textit{Targeted} & \\textit{Targeted} & \\textit{Placebo} & \\textit{Placebo} \\\\\n",
  "\\midrule\n"
)

coefs_row <- "DRS Adopted"
se_row <- ""
n_row <- "Observations"

for (m in mats) {
  f <- mat_fits[[m]]
  b <- coef(f)["drs_adopted"]
  s <- se(f)["drs_adopted"]
  p <- 2 * pnorm(-abs(b / s))
  n <- nobs(f)
  coefs_row <- paste0(coefs_row, sprintf(" & %s%s", format(round(b, 2), nsmall = 2), stars(p)))
  se_row <- paste0(se_row, sprintf(" & (%s)", format(round(s, 2), nsmall = 2)))
  n_row <- paste0(n_row, sprintf(" & %s", format(n, big.mark = ",")))
}

tab3_tex <- paste0(tab3_tex,
  coefs_row, " \\\\\n", se_row, " \\\\\n\\midrule\n",
  n_row, " \\\\\n",
  "Country \\& Year FE & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} TWFE regressions of recycling rate on DRS adoption, separately by material. ",
  "Columns~(1)--(2): materials targeted by DRS. Columns~(3)--(4): placebo materials not covered by DRS. ",
  "If DRS operates through the deposit incentive, effects should concentrate in (1)--(2). ",
  "Always-treated countries excluded. SEs clustered at country level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_material.tex")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("=== Table 4 ===\n")

specs <- list(
  list(name = "Baseline", fit = ddd_fit, cname = "drs_adopted:targeted_num", type = "DDD"),
  list(name = "Drop Germany", fit = ddd_no_de, cname = "drs_adopted:targeted_num", type = "DDD"),
  list(name = "Glass as control", fit = ddd_alt, cname = "drs_adopted:targeted_alt", type = "DDD"),
  list(name = "Dose-response", fit = dose_fit, cname = "deposit_active", type = "TWFE")
)

tab4_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Robustness Checks}\n\\label{tab:robust}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lcccc}\n\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & Drop Germany & Glass Control & Dose-Response \\\\\n",
  "\\midrule\n"
)

# DDD rows
ddd_row <- "DRS $\\times$ Targeted"
ddd_se_row <- ""
dose_row <- "Deposit (EUR)"
dose_se_row <- ""

for (i in 1:4) {
  sp <- specs[[i]]
  b <- coef(sp$fit)[sp$cname]
  s <- se(sp$fit)[sp$cname]
  p <- 2 * pnorm(-abs(b / s))
  n <- nobs(sp$fit)

  if (sp$type == "DDD") {
    ddd_row <- paste0(ddd_row, sprintf(" & %s%s", format(round(b, 2), nsmall = 2), stars(p)))
    ddd_se_row <- paste0(ddd_se_row, sprintf(" & (%s)", format(round(s, 2), nsmall = 2)))
    dose_row <- paste0(dose_row, " & ")
    dose_se_row <- paste0(dose_se_row, " & ")
  } else {
    ddd_row <- paste0(ddd_row, " & ")
    ddd_se_row <- paste0(ddd_se_row, " & ")
    dose_row <- paste0(dose_row, sprintf(" & %s%s", format(round(b, 2), nsmall = 2), stars(p)))
    dose_se_row <- paste0(dose_se_row, sprintf(" & (%s)", format(round(s, 2), nsmall = 2)))
  }
}

tab4_tex <- paste0(tab4_tex,
  ddd_row, " \\\\\n", ddd_se_row, " \\\\\n",
  dose_row, " \\\\\n", dose_se_row, " \\\\\n",
  "\\midrule\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(specs[[1]]$fit), big.mark = ","),
          format(nobs(specs[[2]]$fit), big.mark = ","),
          format(nobs(specs[[3]]$fit), big.mark = ","),
          format(nobs(specs[[4]]$fit), big.mark = ",")),
  "Specification & DDD & DDD & DDD & TWFE \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column~(1): baseline DDD from Table~\\ref{tab:main}. ",
  "(2): drops Germany. (3): adds glass to the non-targeted control group. ",
  "(4): replaces binary DRS with deposit amount in EUR (dose-response). ",
  "All DDD specs include country$\\times$year, material$\\times$year, country$\\times$material FE. ",
  "SEs clustered at country level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robust.tex")

# ---------------------------------------------------------------
# Table F1: SDE
# ---------------------------------------------------------------
cat("=== Table F1: SDE ===\n")

classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# SD(Y) from pre-treatment
sd_y_total <- sd(df$recycle_rate[df$material == "Total" & !is.na(df$first_treat) & df$drs_adopted == 0], na.rm = TRUE)
sd_y_ddd <- sd(df$recycle_rate[!is.na(df$targeted) & !is.na(df$first_treat) & df$drs_adopted == 0], na.rm = TRUE)
sd_y_pla <- sd(df$recycle_rate[df$material == "Plastic" & !is.na(df$first_treat) & df$drs_adopted == 0], na.rm = TRUE)
sd_y_met <- sd(df$recycle_rate[df$material == "Metal" & !is.na(df$first_treat) & df$drs_adopted == 0], na.rm = TRUE)

# Pooled
sde_cs <- cs_coef / sd_y_total; se_sde_cs <- cs_se / sd_y_total
sde_ddd <- ddd_coef / sd_y_ddd; se_sde_ddd <- ddd_se / sd_y_ddd

# Heterogeneous
pla_b <- coef(mat_fits[["Plastic"]])["drs_adopted"]
pla_s <- se(mat_fits[["Plastic"]])["drs_adopted"]
met_b <- coef(mat_fits[["Metal"]])["drs_adopted"]
met_s <- se(mat_fits[["Metal"]])["drs_adopted"]

sde_pla <- pla_b / sd_y_pla; se_sde_pla <- pla_s / sd_y_pla
sde_met <- met_b / sd_y_met; se_sde_met <- met_s / sd_y_met

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states plus EEA). ",
  "\\textbf{Research question:} Whether national deposit return schemes for beverage containers causally increase material-specific packaging waste recycling rates across EU member states. ",
  "\\textbf{Policy mechanism:} DRS requires consumers to pay a refundable deposit (EUR~0.07--0.50) on single-use beverage containers (plastic bottles, metal cans); the deposit is refunded upon return to collection points, creating a direct monetary incentive for proper disposal absent under standard municipal waste collection. ",
  "\\textbf{Outcome definition:} Annual recycling rate of packaging waste by material type from Eurostat (cei\\_wm020), measured as percentage of packaging waste recycled. ",
  "\\textbf{Treatment:} Binary indicator for national DRS adoption (staggered across countries, 2002--2023). ",
  "\\textbf{Data:} Eurostat cei\\_wm020, annual country$\\times$material panel, 28 EU/EEA countries, 2000--2023, 2,317 observations in DDD specification. ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD for aggregate rates; triple-difference (country$\\times$material$\\times$year) for material-specific effects with country$\\times$year, material$\\times$year, and country$\\times$material fixed effects; country-clustered standard errors. ",
  "\\textbf{Sample:} EU/EEA countries with Eurostat packaging waste recycling data; always-treated countries (Finland, Sweden) excluded; targeted materials are plastic and metal packaging; non-targeted placebo materials are paper/cardboard and wood packaging. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

fmt <- function(x, d = 2) format(round(x, d), nsmall = d)
fmt3 <- function(x) format(round(x, 3), nsmall = 3)

sde_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccl}\n\\toprule\n",
  "Outcome & Spec. & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Total recycling & CS ATT & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(cs_coef), fmt(cs_se), fmt(sd_y_total, 1), fmt3(sde_cs), fmt3(se_sde_cs), classify_sde(sde_cs)),
  sprintf("Targeted materials & DDD & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(ddd_coef), fmt(ddd_se), fmt(sd_y_ddd, 1), fmt3(sde_ddd), fmt3(se_sde_ddd), classify_sde(sde_ddd)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by material)}} \\\\\n",
  sprintf("Plastic & TWFE & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(pla_b), fmt(pla_s), fmt(sd_y_pla, 1), fmt3(sde_pla), fmt3(se_sde_pla), classify_sde(sde_pla)),
  sprintf("Metal & TWFE & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(met_b), fmt(met_s), fmt(sd_y_met, 1), fmt3(sde_met), fmt3(se_sde_met), classify_sde(sde_met)),
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
