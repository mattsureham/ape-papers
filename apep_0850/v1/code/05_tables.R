## 05_tables.R — apep_0850
## Generate all LaTeX tables

source("00_packages.R")

models <- readRDS("../data/models.rds")
rob <- readRDS("../data/robustness_models.rds")
panel <- readRDS("../data/analysis_panel_fr.rds")
ddd_panel <- panel[bite %in% c("high", "low")]

cat("=== Generating Tables ===\n")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

# Pre-treatment (2015-2019) summary by canton × bite
pre <- ddd_panel[year >= 2015 & year <= 2019]

summ_by_group <- pre[, .(
  `Mean CBW` = round(mean(cbw), 1),
  `SD CBW` = round(sd(cbw), 1),
  `Median CBW` = round(median(cbw), 1),
  Sectors = uniqueN(noga),
  `Quarters` = uniqueN(TIME_PERIOD),
  Obs = .N
), by = .(Canton = fifelse(canton == 25, "Geneva", "Control"),
          Bite = bite)]

setorder(summ_by_group, Canton, -Bite)

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Cross-Border Worker Counts by Canton Group and Sector Bite}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llrrrrrr}",
  "\\toprule",
  "Canton & Bite & Mean & SD & Median & Sectors & Quarters & Obs \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_by_group)) {
  r <- summ_by_group[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %d & %d & %s \\\\",
    r$Canton, r$Bite,
    format(r$`Mean CBW`, big.mark = ","),
    format(r$`SD CBW`, big.mark = ","),
    format(r$`Median CBW`, big.mark = ","),
    r$Sectors, r$Quarters,
    format(r$Obs, big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Summary statistics for cross-border worker (CBW) counts from France, pre-treatment period 2015--2019. Geneva is the treated canton (CHF~23.27/hr minimum wage, November 2020). Control cantons: Vaud, Basel-Stadt, Neuch\\^atel, Jura. High-bite sectors have $>15\\%$ of workers estimated below CHF~23/hr (2018 LSE): accommodation, food service, retail, personal services, building services, employment activities, recreation. Low-bite sectors have $<5\\%$: financial services, insurance, pharma, electronics, IT, legal/accounting, architecture, R\\&D. Unit of observation: canton $\\times$ NOGA sector $\\times$ quarter.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 (Summary Statistics) written.\n")

# ============================================================
# TABLE 2: Main DDD Results
# ============================================================

# Extract coefficients from models
extract_row <- function(model, coef_name, label) {
  cf <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- pvalue(model)[coef_name]
  n <- nobs(model)
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  list(label = label, coef = cf, se = s, p = p, n = n, stars = stars)
}

m1 <- extract_row(models$m1_ddd, "geneva:high_bite:post", "Full sample, saturated FE")
m2 <- extract_row(models$m2_ddd, "geneva:high_bite:post", "Full sample, simple FE")

# Rerun clean pre-period for table extraction
panel_clean <- ddd_panel[year >= 2015]
panel_clean[, ge_hb := as.integer(canton == 25) * as.integer(bite == "high")]
m_clean <- feols(log_cbw ~ ge_hb:post | canton_sector + sector_quarter + canton_quarter,
                  data = panel_clean, cluster = ~canton_sector)
m3 <- extract_row(m_clean, "ge_hb:post", "Clean pre-period (2015+)")

m4 <- extract_row(models$m4_geneva, "high_bite:post", "Within-Geneva DiD")

# Poisson
m5 <- extract_row(rob$r5_poisson, "ge_hb:post", "Poisson QMLE")

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

all_models <- list(m1, m2, m3, m4, m5)

# Coefficient row
coef_row <- " Geneva $\\times$ High-Bite $\\times$ Post"
for (m in all_models) {
  coef_row <- paste0(coef_row, sprintf(" & %.3f%s", m$coef, m$stars))
}
tab2_lines <- c(tab2_lines, paste0(coef_row, " \\\\"))

# SE row
se_row <- " "
for (m in all_models) {
  se_row <- paste0(se_row, sprintf(" & (%.3f)", m$se))
}
tab2_lines <- c(tab2_lines, paste0(se_row, " \\\\"))

# N row
n_row <- "Observations"
for (m in all_models) {
  n_row <- paste0(n_row, sprintf(" & %s", format(m$n, big.mark = ",")))
}
tab2_lines <- c(tab2_lines, "\\midrule", paste0(n_row, " \\\\"))

# FE rows
tab2_lines <- c(tab2_lines,
  "Canton $\\times$ Sector FE & Yes & Yes & Yes & Sector & Yes \\\\",
  "Sector $\\times$ Quarter FE & Yes & & Yes & & Yes \\\\",
  "Canton $\\times$ Quarter FE & Yes & & Yes & & Yes \\\\",
  "Quarter FE & & Yes & & Yes & \\\\",
  "Pre-period & 2002+ & 2002+ & 2015+ & 2002+ & 2002+ \\\\",
  "Clustering & CS & CS & CS & Sector & CS \\\\")

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is $\\log(\\text{CBW} + 1)$ in columns (1)--(4) and CBW count in column (5). The treatment is Geneva's CHF~23.27/hr minimum wage effective November 2020 (Q4 2020). Column (1) is the preferred triple-difference specification with canton$\\times$sector, sector$\\times$quarter, and canton$\\times$quarter fixed effects. Column (3) restricts the pre-period to 2015--2019 (post-franc-shock, pre-COVID) and is our preferred estimate. Column (4) uses only Geneva, comparing high-bite to low-bite sectors. Standard errors clustered at canton$\\times$sector level (CS) in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 (Main Results) written.\n")

# ============================================================
# TABLE 3: Robustness Checks
# ============================================================

# Gather robustness coefficients
rob_rows <- list(
  list(label = "Placebo canton (Vaud)", coef = NA, se = NA, p = NA, note = "Vaud as treated, Geneva excluded"),
  list(label = "Placebo timing (Q4 2018)", coef = NA, se = NA, p = NA, note = "Pre-treatment data only"),
  list(label = "IHS transformation", coef = NA, se = NA, p = NA, note = "$\\sinh^{-1}(\\text{CBW})$"),
  list(label = "Continuous bite", coef = NA, se = NA, p = NA, note = "Bite fraction $\\times$ Geneva $\\times$ Post"),
  list(label = "Ticino replication", coef = NA, se = NA, p = NA, note = "CHF 19/hr, April 2021")
)

# Fill in from robustness models
r1_coef <- coef(rob$r1_placebo_canton)
r1_se <- se(rob$r1_placebo_canton)
# Placebo canton had collinearity issues; extract available coefficient
if (length(r1_coef) > 0) {
  rob_rows[[1]]$coef <- r1_coef[1]
  rob_rows[[1]]$se <- r1_se[1]
  rob_rows[[1]]$p <- pvalue(rob$r1_placebo_canton)[1]
}

rob_rows[[2]]$coef <- coef(rob$r2_placebo_time)["ge_hb:post_placebo_2018"]
rob_rows[[2]]$se <- se(rob$r2_placebo_time)["ge_hb:post_placebo_2018"]
rob_rows[[2]]$p <- pvalue(rob$r2_placebo_time)["ge_hb:post_placebo_2018"]

rob_rows[[3]]$coef <- coef(rob$r4_asinh)["ge_hb:post"]
rob_rows[[3]]$se <- se(rob$r4_asinh)["ge_hb:post"]
rob_rows[[3]]$p <- pvalue(rob$r4_asinh)["ge_hb:post"]

rob_rows[[4]]$coef <- coef(rob$r6_continuous)["ge_bite:post"]
rob_rows[[4]]$se <- se(rob$r6_continuous)["ge_bite:post"]
rob_rows[[4]]$p <- pvalue(rob$r6_continuous)["ge_bite:post"]

rob_rows[[5]]$coef <- coef(rob$r7_ticino)["high_bite:post_ti"]
rob_rows[[5]]$se <- se(rob$r7_ticino)["high_bite:post_ti"]
rob_rows[[5]]$p <- pvalue(rob$r7_ticino)["high_bite:post_ti"]

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccl}",
  "\\toprule",
  "Specification & Coefficient & SE & Note \\\\",
  "\\midrule",
  sprintf("\\textit{Main result (Table~\\ref{tab:main}, col.~3)} & \\textit{%.3f} & \\textit{(%.3f)} & \\textit{Preferred} \\\\",
          coef(m_clean)["ge_hb:post"], se(m_clean)["ge_hb:post"]),
  "\\midrule"
)

for (r in rob_rows) {
  if (!is.na(r$coef)) {
    stars <- ifelse(r$p < 0.01, "$^{***}$", ifelse(r$p < 0.05, "$^{**}$", ifelse(r$p < 0.1, "$^{*}$", "")))
    tab3_lines <- c(tab3_lines, sprintf(
      "%s & %.3f%s & (%.3f) & %s \\\\",
      r$label, r$coef, stars, r$se, r$note
    ))
  }
}

# LOSO range
loso <- rob$loso_results
tab3_lines <- c(tab3_lines,
  sprintf("Leave-one-sector-out & [%.3f, %.3f] & & Range of DDD coef. \\\\",
          min(loso$coef), max(loso$coef)))

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the saturated fixed-effect structure (canton$\\times$sector, sector$\\times$quarter, canton$\\times$quarter) unless noted. The placebo canton test replaces Geneva with Vaud and excludes Geneva from the sample. The placebo timing test applies the main DDD using only pre-treatment data (before Q4 2020) with a false treatment at Q4 2018. The continuous bite specification replaces the binary high/low classification with the estimated fraction of workers below CHF~23/hr. The Ticino replication tests whether Ticino's CHF~19/hr minimum wage (effective April 2021) affected Italian cross-border worker composition using a within-Ticino design. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("Table 3 (Robustness) written.\n")

# ============================================================
# TABLE 4: Sector-level heterogeneity
# ============================================================

# CBW growth by sector in Geneva, pre vs post
geneva_sectors <- panel[canton == 25 & !is.na(noga)]
pre_ge <- geneva_sectors[year >= 2015 & year <= 2019, .(pre_mean = mean(cbw)), by = noga]
post_ge <- geneva_sectors[year >= 2021 & year <= 2024, .(post_mean = mean(cbw)), by = noga]
sector_growth <- merge(pre_ge, post_ge, by = "noga")
sector_growth[, growth_pct := (post_mean / pre_mean - 1) * 100]

# Add bite classification
sector_growth[, bite := fcase(
  noga %in% c(55, 56, 47, 96, 81, 78, 93), "High",
  noga %in% c(64, 65, 21, 26, 62, 69, 71, 72), "Low",
  default = "Medium"
)]

# Sector names
noga_names <- data.table(
  noga = c(55, 56, 47, 96, 81, 78, 93, 64, 65, 21, 26, 62, 69, 71, 72),
  sector_name = c("Accommodation", "Food \\& beverage", "Retail trade",
                  "Personal services", "Building services", "Employment activities",
                  "Sports \\& recreation",
                  "Financial services", "Insurance", "Pharmaceuticals",
                  "Electronics mfg.", "IT \\& programming", "Legal \\& accounting",
                  "Architecture \\& eng.", "Scientific R\\&D")
)

sector_tab <- merge(sector_growth[bite %in% c("High", "Low")], noga_names, by = "noga")
setorder(sector_tab, bite, -pre_mean)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Cross-Border Worker Growth by Sector in Geneva}",
  "\\label{tab:sectors}",
  "\\begin{tabular}{llrrr}",
  "\\toprule",
  "Bite & Sector & Pre-Mean & Post-Mean & Growth (\\%) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: High-bite sectors ($>15\\%$ below CHF 23/hr)}} \\\\"
)

for (i in 1:nrow(sector_tab[bite == "High"])) {
  r <- sector_tab[bite == "High"][i]
  tab4_lines <- c(tab4_lines, sprintf(
    " & %s & %s & %s & %.1f \\\\",
    r$sector_name,
    format(round(r$pre_mean), big.mark = ","),
    format(round(r$post_mean), big.mark = ","),
    r$growth_pct
  ))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Low-bite sectors ($<5\\%$ below CHF 23/hr)}} \\\\"
)

for (i in 1:nrow(sector_tab[bite == "Low"])) {
  r <- sector_tab[bite == "Low"][i]
  tab4_lines <- c(tab4_lines, sprintf(
    " & %s & %s & %s & %.1f \\\\",
    r$sector_name,
    format(round(r$pre_mean), big.mark = ","),
    format(round(r$post_mean), big.mark = ","),
    r$growth_pct
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment mean is the average quarterly cross-border worker count from France in Geneva for 2015--2019. Post-treatment mean covers 2021--2024. Growth is the percentage change from pre- to post-treatment mean. Bite classification based on estimated fraction of workers below CHF~23/hr from the 2018 Swiss Wage Structure Survey.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_sectors.tex")
cat("Table 4 (Sector Heterogeneity) written.\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================

# Use clean pre-period (2015+) as preferred specification
clean_panel <- ddd_panel[year >= 2015]
clean_panel[, ge_hb := as.integer(canton == 25) * as.integer(bite == "high")]

m_preferred <- feols(log_cbw ~ ge_hb:post | canton_sector + sector_quarter + canton_quarter,
                     data = clean_panel, cluster = ~canton_sector)

beta_hat <- coef(m_preferred)["ge_hb:post"]
se_beta <- se(m_preferred)["ge_hb:post"]
sd_y <- sd(clean_panel[post == 0]$log_cbw, na.rm = TRUE)
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

# Panel A: Pooled
pooled_row <- data.table(
  Outcome = "Cross-border worker count (log)",
  beta = round(beta_hat, 4),
  se = round(se_beta, 4),
  sd_y = round(sd_y, 4),
  sde = round(sde_main, 4),
  se_sde = round(se_sde, 4),
  classification = classify_sde(sde_main)
)

# Panel B: Heterogeneous (sample splits)
# Split 1: Within-Geneva, hospitality (55+56) vs low-bite reference sectors
hosp_panel <- clean_panel[canton == 25 & noga %in% c(55, 56, 64, 65, 21, 26, 62, 69, 71, 72)]
hosp_panel[, is_hosp := as.integer(noga %in% c(55, 56))]
m_hosp <- feols(log_cbw ~ is_hosp:post | noga + t,
                data = hosp_panel, cluster = ~noga)
b_hosp <- coef(m_hosp)["is_hosp:post"]
se_hosp <- se(m_hosp)["is_hosp:post"]
sd_hosp <- sd(hosp_panel[post == 0]$log_cbw, na.rm = TRUE)
sde_hosp <- b_hosp / sd_hosp

# Split 2: Within-Geneva, retail + services (47+96+81) vs low-bite reference
serv_panel <- clean_panel[canton == 25 & noga %in% c(47, 96, 81, 64, 65, 21, 26, 62, 69, 71, 72)]
serv_panel[, is_serv := as.integer(noga %in% c(47, 96, 81))]
m_ret <- feols(log_cbw ~ is_serv:post | noga + t,
               data = serv_panel, cluster = ~noga)
b_ret <- coef(m_ret)["is_serv:post"]
se_ret <- se(m_ret)["is_serv:post"]
sd_ret <- sd(serv_panel[post == 0]$log_cbw, na.rm = TRUE)
sde_ret <- b_ret / sd_ret

het_rows <- data.table(
  Outcome = c("Hospitality CBW (accomm. + food service)",
              "Service CBW (retail + personal services)"),
  beta = round(c(b_hosp, b_ret), 4),
  se = round(c(se_hosp, se_ret), 4),
  sd_y = round(c(sd_hosp, sd_ret), 4),
  sde = round(c(sde_hosp, sde_ret), 4),
  se_sde = round(c(se_hosp / sd_hosp, se_ret / sd_ret), 4),
  classification = c(classify_sde(sde_hosp), classify_sde(sde_ret))
)

# SDE table notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does Geneva's CHF~23.27/hr minimum wage---the world's highest statutory wage floor---alter the sectoral composition of cross-border workers commuting from France? ",
  "\\textbf{Policy mechanism:} The cantonal minimum wage raises the effective floor for all employees working in Geneva, including approximately 90,000 cross-border commuters from France who enter freely under the 2004 EU--Switzerland Agreement on Free Movement of Persons; sectors with large fractions of workers previously paid below CHF~23/hr face the strongest bite. ",
  "\\textbf{Outcome definition:} Quarterly count of cross-border workers from France in a given NOGA sector within Geneva, from the BFS Grenz\\-g\\\"an\\-ger Statistics (GGS), measured in logs. ",
  "\\textbf{Treatment:} Binary; sector-level bite classification based on the estimated fraction of workers below CHF~23/hr from the 2018 Swiss Wage Structure Survey (high-bite $>15\\%$, low-bite $<5\\%$), interacted with Geneva canton and post-November~2020 indicator. ",
  "\\textbf{Data:} BFS Grenz\\-g\\\"an\\-ger Statistics (SDMX), quarterly, 2015--2025, canton $\\times$ NOGA sector $\\times$ quarter; $N = ",
  format(nrow(clean_panel), big.mark = ","), "$ (high- and low-bite sectors across five French border cantons). ",
  "\\textbf{Method:} Triple-difference (canton $\\times$ bite $\\times$ post) with canton$\\times$sector, sector$\\times$quarter, and canton$\\times$quarter fixed effects; standard errors clustered at canton$\\times$sector level. ",
  "\\textbf{Sample:} Restricted to high-bite ($N_{\\text{sectors}}=7$) and low-bite ($N_{\\text{sectors}}=8$) NOGA sectors in five French border cantons (Geneva, Vaud, Basel-Stadt, Neuch\\^atel, Jura); pre-period restricted to 2015+ (post-franc-shock). ",
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
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

# Add pooled row
tabF1_lines <- c(tabF1_lines, sprintf(
  "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
  pooled_row$Outcome, pooled_row$beta, pooled_row$se, pooled_row$sd_y,
  pooled_row$sde, pooled_row$se_sde, pooled_row$classification
))

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\"
)

for (i in 1:nrow(het_rows)) {
  r <- het_rows[i]
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

# ============================================================
# Update diagnostics.json with preferred specification
# ============================================================

diag <- jsonlite::read_json("../data/diagnostics.json")
diag$n_treated <- uniqueN(clean_panel[canton == 25 & high_bite == 1]$canton_sector)
diag$n_pre <- uniqueN(clean_panel[post == 0]$TIME_PERIOD)
diag$n_obs <- nrow(clean_panel)
diag$ddd_coef_preferred <- round(beta_hat, 4)
diag$ddd_se_preferred <- round(se_beta, 4)
diag$sde_preferred <- round(sde_main, 4)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== All tables generated ===\n")
