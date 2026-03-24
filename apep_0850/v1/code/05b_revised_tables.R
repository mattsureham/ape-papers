## 05b_revised_tables.R — apep_0850
## Regenerate tables using revised models (Vaud excluded)

source("00_packages.R")
library(fixest)
library(data.table)

models <- readRDS("../data/revised_models.rds")
panel <- readRDS("../data/analysis_panel_fr.rds")

# Exclude Vaud
ddd_panel <- panel[bite %in% c("high", "low") & canton != 22]
clean_panel <- ddd_panel[year >= 2015]
clean_panel[, ge_hb := as.integer(canton == 25) * as.integer(bite == "high")]

cat("=== Regenerating Tables (Vaud excluded) ===\n")

# ============================================================
# TABLE 2: Main DDD Results (revised)
# ============================================================

m1 <- models$m_full      # Full sample, saturated FE
m3 <- models$m_preferred  # 2015+, saturated FE
m4 <- models$m_geneva     # Within-Geneva
m5 <- models$m_poisson    # Poisson

# Simple FE for column 2
m2 <- feols(
  log_cbw ~ I(canton == 25):I(bite == "high"):post +
    I(canton == 25):post + I(bite == "high"):post |
    canton_sector + t,
  data = ddd_panel,
  cluster = ~canton_sector
)

# Extract info
get_row <- function(m, cn) {
  cf <- coef(m)[cn]; s <- se(m)[cn]; p <- pvalue(m)[cn]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  list(cf=cf, s=s, p=p, n=nobs(m), stars=stars)
}

r1 <- get_row(m1, "ge_hb:post")
# m2 has a longer name
m2_cn <- grep("TRUE:post$", names(coef(m2)), value=TRUE)
m2_cn <- m2_cn[grepl("canton.*bite", m2_cn)]
r2 <- if(length(m2_cn) > 0) get_row(m2, m2_cn[1]) else list(cf=NA, s=NA, p=NA, n=nobs(m2), stars="")
r3 <- get_row(m3, "ge_hb:post")

# Within-Geneva
m4_cn <- grep("post", names(coef(m4)), value=TRUE)[1]
r4 <- get_row(m4, m4_cn)

r5 <- get_row(m5, "ge_hb:post")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Geneva's Minimum Wage on Cross-Border Worker Flows}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & DDD & DDD & DDD & Geneva DiD & Poisson \\\\",
  " & Full & Simple FE & 2015+ & High vs.~Low & QMLE \\\\",
  "\\midrule"
)

# Coefficient row
tab2_lines <- c(tab2_lines, sprintf(
  " Geneva $\\times$ High-Bite $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
  r1$cf, r1$stars, r2$cf, r2$stars, r3$cf, r3$stars, r4$cf, r4$stars, r5$cf, r5$stars
))

# SE row
tab2_lines <- c(tab2_lines, sprintf(
  " & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
  r1$s, r2$s, r3$s, r4$s, r5$s
))

# N row
tab2_lines <- c(tab2_lines, "\\midrule", sprintf(
  "Observations & %s & %s & %s & %s & %s \\\\",
  format(r1$n, big.mark=","), format(r2$n, big.mark=","),
  format(r3$n, big.mark=","), format(r4$n, big.mark=","),
  format(r5$n, big.mark=",")
))

tab2_lines <- c(tab2_lines,
  "Canton $\\times$ Sector FE & Yes & Yes & Yes & Sector & Yes \\\\",
  "Sector $\\times$ Quarter FE & Yes & & Yes & & Yes \\\\",
  "Canton $\\times$ Quarter FE & Yes & & Yes & & Yes \\\\",
  "Quarter FE & & Yes & & Yes & \\\\",
  "Pre-period & 2002+ & 2002+ & 2015+ & 2015+ & 2015+ \\\\",
  "Clustering & CS & CS & CS & Sector & CS \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is $\\log(\\text{CBW} + 1)$ in columns (1)--(4) and CBW count in column (5). The treatment is Geneva's CHF~23.27/hr minimum wage effective November 2020 (Q4 2020). Vaud is excluded from the control group because it adopted its own cantonal minimum wage in January 2021. Column (3) is the preferred specification, restricting the pre-period to 2015--2019 (post-franc-shock, pre-COVID). Column (4) uses only Geneva, comparing high-bite to low-bite sectors. Standard errors clustered at canton$\\times$sector level (CS) in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 (Main Results) updated.\n")

# ============================================================
# TABLE 3: Robustness (revised)
# ============================================================

m_plac <- models$m_placebo_time
perm <- models$perm_results

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccl}",
  "\\toprule",
  "Specification & Coefficient & SE & Note \\\\",
  "\\midrule",
  sprintf("\\textit{Preferred (Table~\\ref{tab:main}, col.~3)} & \\textit{%.3f} & \\textit{(%.3f)} & \\textit{Preferred} \\\\",
          coef(m3)["ge_hb:post"], se(m3)["ge_hb:post"]),
  "\\midrule"
)

# Placebo timing
p_plac <- pvalue(m_plac)["ge_hb:post_placebo"]
s_plac <- ifelse(p_plac < 0.1, "$^{*}$", "")
tab3_lines <- c(tab3_lines, sprintf(
  "Placebo timing (Q4 2018) & %.3f%s & (%.3f) & Pre-treatment data only \\\\",
  coef(m_plac)["ge_hb:post_placebo"], s_plac, se(m_plac)["ge_hb:post_placebo"]))

# Permutation results
for (i in 1:nrow(perm)) {
  cname <- c("12" = "Basel-Stadt", "24" = "Neuch\\^atel", "26" = "Jura")[as.character(perm$canton[i])]
  tab3_lines <- c(tab3_lines, sprintf(
    "Placebo canton (%s) & %.3f & (%.3f) & Canton as if treated \\\\",
    cname, perm$coef[i], perm$se[i]))
}

# Ticino
panel_ti <- readRDS("../data/analysis_panel_ti.rds")
panel_ti[, high_bite := as.integer(bite == "high")]
panel_ti[, log_cbw := log(cbw + 1)]
panel_ti[, t := as.integer(factor(TIME_PERIOD))]
ti_treatment_q <- panel_ti[TIME_PERIOD == "2021-Q2", unique(t)]
panel_ti[, post_ti := as.integer(t >= ti_treatment_q)]
ti_panel <- panel_ti[bite %in% c("high", "low")]
m_ti <- feols(log_cbw ~ high_bite:post_ti | noga + t, data = ti_panel, cluster = ~noga)
tab3_lines <- c(tab3_lines, sprintf(
  "Ticino replication & %.3f & (%.3f) & CHF 19/hr, April 2021, Italian CBW \\\\",
  coef(m_ti)["high_bite:post_ti"], se(m_ti)["high_bite:post_ti"]))

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the saturated fixed-effect structure (canton$\\times$sector, sector$\\times$quarter, canton$\\times$quarter) and exclude Vaud from the control group unless noted. The placebo timing test uses only pre-treatment data with a false treatment at Q4 2018. Placebo canton tests assign treatment to each control canton individually, excluding Geneva. The Ticino replication tests whether Ticino's CHF~19/hr minimum wage (effective April 2021) affected Italian cross-border worker composition. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Table 3 (Robustness) updated.\n")

# ============================================================
# TABLE F1: SDE (revised)
# ============================================================

beta_hat <- coef(m3)["ge_hb:post"]
se_beta <- se(m3)["ge_hb:post"]
sd_y <- sd(clean_panel[clean_panel$post == 0, ]$log_cbw, na.rm = TRUE)
sde_main <- beta_hat / sd_y
se_sde <- se_beta / sd_y

classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s <= 0.005) "Null"
  else if (s <= 0.05) "Small positive"
  else if (s <= 0.15) "Moderate positive"
  else "Large positive"
}

# Panel B: heterogeneity splits within Geneva
# Split 1: Hospitality (55+56) vs low-bite reference
hosp_panel <- clean_panel[canton == 25 & noga %in% c(55, 56, 64, 65, 21, 26, 62, 69, 71, 72)]
hosp_panel[, is_hosp := as.integer(noga %in% c(55, 56))]
m_hosp <- feols(log_cbw ~ is_hosp:post | noga + t, data = hosp_panel, cluster = ~noga)
b_hosp <- coef(m_hosp)["is_hosp:post"]
se_hosp <- se(m_hosp)["is_hosp:post"]
sd_hosp <- sd(hosp_panel[hosp_panel$post == 0,]$log_cbw, na.rm = TRUE)
sde_hosp <- b_hosp / sd_hosp

# Split 2: Services (47+96+81) vs low-bite reference
serv_panel <- clean_panel[canton == 25 & noga %in% c(47, 96, 81, 64, 65, 21, 26, 62, 69, 71, 72)]
serv_panel[, is_serv := as.integer(noga %in% c(47, 96, 81))]
m_serv <- feols(log_cbw ~ is_serv:post | noga + t, data = serv_panel, cluster = ~noga)
b_serv <- coef(m_serv)["is_serv:post"]
se_serv <- se(m_serv)["is_serv:post"]
sd_serv <- sd(serv_panel[serv_panel$post == 0,]$log_cbw, na.rm = TRUE)
sde_serv <- b_serv / sd_serv

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does Geneva's CHF~23.27/hr minimum wage---the world's highest statutory wage floor---alter the sectoral composition of cross-border workers commuting from France? ",
  "\\textbf{Policy mechanism:} The cantonal minimum wage raises the effective floor for all employees working in Geneva, including approximately 90,000 cross-border commuters from France who enter freely under the 2004 EU--Switzerland Agreement on Free Movement of Persons; sectors with large fractions of workers previously paid below CHF~23/hr face the strongest bite. ",
  "\\textbf{Outcome definition:} Quarterly count of cross-border workers from France in a given NOGA sector within Geneva, from the BFS Grenz\\-g\\\"an\\-ger Statistics (GGS), measured in logs. ",
  "\\textbf{Treatment:} Binary; sector-level bite classification based on the estimated fraction of workers below CHF~23/hr from the 2018 Swiss Wage Structure Survey (high-bite $>15\\%$, low-bite $<5\\%$), interacted with Geneva canton and post-November~2020 indicator. ",
  "\\textbf{Data:} BFS Grenz\\-g\\\"an\\-ger Statistics (SDMX), quarterly, 2015--2025, canton $\\times$ NOGA sector $\\times$ quarter; $N = ",
  format(nrow(clean_panel), big.mark = ","), "$ (high- and low-bite sectors across four French border cantons, excluding Vaud). ",
  "\\textbf{Method:} Triple-difference (canton $\\times$ bite $\\times$ post) with canton$\\times$sector, sector$\\times$quarter, and canton$\\times$quarter fixed effects; standard errors clustered at canton$\\times$sector level. ",
  "\\textbf{Sample:} Restricted to high-bite ($N_{\\text{sectors}}=7$) and low-bite ($N_{\\text{sectors}}=8$) NOGA sectors in four French border cantons (Geneva, Basel-Stadt, Neuch\\^atel, Jura); Vaud excluded due to own minimum wage; pre-period restricted to 2015+ (post-franc-shock). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

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
  sprintf("Cross-border worker count (log) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_hat, se_beta, sd_y, sde_main, se_sde, classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\",
  sprintf("Hospitality CBW (accomm.~+ food service) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b_hosp, se_hosp, sd_hosp, sde_hosp, se_hosp/sd_hosp, classify_sde(sde_hosp)),
  sprintf("Service CBW (retail + personal + building) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b_serv, se_serv, sd_serv, sde_serv, se_serv/sd_serv, classify_sde(sde_serv)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) updated.\n")

cat("\n=== All tables regenerated ===\n")
