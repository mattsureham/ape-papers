# 05_tables.R — Generate all LaTeX tables
# apep_1162: Belgium SSC Cut and Employment

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel      <- readRDS("panel.rds")
lci        <- readRDS("lci.rds")
comp       <- readRDS("comp.rds")
labor_int  <- readRDS("labor_intensity.rds")

tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

primary <- panel |> filter(geo %in% c("BE", "NL", "DE", "LU"))

# ─────────────────────────────────────────────────────────────
# Re-estimate all models (fixest needs data in scope for vcov)
# ─────────────────────────────────────────────────────────────

# First stage: non-wage cost
lci_norm <- lci |>
  group_by(geo) |>
  mutate(
    base_nw = nonwage_index[which.min(abs(yq - 2015.75))],
    base_w  = wage_index[which.min(abs(yq - 2015.75))],
    nw_norm = nonwage_index / base_nw * 100,
    w_norm  = wage_index / base_w * 100
  ) |>
  ungroup() |>
  mutate(belgium = as.integer(geo == "BE"),
         post = as.integer(yq >= 2016.25))

fs_model <- feols(nw_norm ~ belgium:post | geo + yq, data = lci_norm)
m_wage   <- feols(w_norm ~ belgium:post | geo + yq, data = lci_norm)

# SSC share
comp_panel <- comp |>
  filter(geo %in% c("BE", "NL", "DE", "LU"), !is.na(ssc_share)) |>
  mutate(belgium = as.integer(geo == "BE"),
         post = as.integer(yq >= 2016.25),
         cs_id = paste(geo, nace, sep = "_"),
         time_id = as.integer(factor(yq)))
m_ssc <- feols(ssc_share ~ belgium:post | cs_id + time_id, data = comp_panel, cluster = ~geo)

# Main models
m1 <- feols(log_emp ~ belgium:post | cs_id + time_id, data = primary, cluster = ~geo)

m2 <- feols(log_emp ~ belgium:full_post | cs_id + time_id, data = primary, cluster = ~geo)

primary_phase <- primary |>
  mutate(phase1 = as.integer(yq >= 2016.25 & yq < 2018.0),
         phase2 = as.integer(yq >= 2018.0))
m3 <- feols(log_emp ~ belgium:phase1 + belgium:phase2 | cs_id + time_id,
            data = primary_phase, cluster = ~geo)

m4 <- feols(log_emp ~ belgium:post:labor_intensity_z + belgium:post | cs_id + time_id,
            data = primary, cluster = ~cs_id)  # country×sector clustering for triple-diff

# Expanded controls
expanded <- panel |> filter(geo %in% c("BE", "NL", "DE", "LU", "AT", "FR", "DK", "FI", "SE"))
m_expanded <- feols(log_emp ~ belgium:post | cs_id + time_id, data = expanded, cluster = ~geo)

# Placebos
m_placebo_pub <- feols(log_emp ~ belgium:post | cs_id + time_id,
                       data = primary |> filter(nace == "O-Q"), cluster = ~geo)
m_placebo_re  <- feols(log_emp ~ belgium:post | cs_id + time_id,
                       data = primary |> filter(nace == "L"), cluster = ~geo)

# Permutation p-value (re-run quickly)
control_countries <- setdiff(unique(expanded$geo), "BE")
perm_coefs <- numeric(length(control_countries))
names(perm_coefs) <- control_countries
for (cc in control_countries) {
  perm_data <- expanded |>
    filter(geo %in% c(cc, setdiff(control_countries, cc))) |>
    mutate(placebo_treat = as.integer(geo == cc))
  perm_fit <- tryCatch(
    feols(log_emp ~ placebo_treat:post | cs_id + time_id, data = perm_data, cluster = ~geo),
    error = function(e) NULL
  )
  if (!is.null(perm_fit)) {
    coef_name <- grep("placebo_treat.*post", names(coef(perm_fit)), value = TRUE)
    if (length(coef_name) > 0) perm_coefs[cc] <- coef(perm_fit)[coef_name[1]]
  }
}
be_coef <- coef(m1)[grep("belgium.*post", names(coef(m1)))[1]]
perm_pval <- mean(abs(perm_coefs) >= abs(be_coef))

# Leave-one-out
sectors <- unique(primary$nace)
loo_coefs <- numeric(length(sectors))
names(loo_coefs) <- sectors
for (s in sectors) {
  loo_fit <- feols(log_emp ~ belgium:post | cs_id + time_id,
                   data = primary |> filter(nace != s), cluster = ~geo)
  coef_name <- grep("belgium.*post", names(coef(loo_fit)), value = TRUE)
  if (length(coef_name) > 0) loo_coefs[s] <- coef(loo_fit)[coef_name[1]]
}

# ─────────────────────────────────────────────────────────────
# Helper: extract DiD coefficient
# ─────────────────────────────────────────────────────────────

get_did <- function(model, pattern = "belgium.*post") {
  cn <- names(coef(model))
  idx <- grep(pattern, cn)
  if (length(idx) == 0) return(list(b = NA, se = NA))
  list(b = coef(model)[idx[1]], se = se(model)[idx[1]])
}

stars <- function(b, se_val) {
  if (is.na(b) || is.na(se_val) || se_val == 0) return("")
  p <- 2 * pnorm(-abs(b / se_val))
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

fmt <- function(est, d = 4) {
  if (is.na(est$b)) return(c("", ""))
  s <- stars(est$b, est$se)
  c(sprintf("%.*f%s", d, est$b, s), sprintf("(%.*f)", d, est$se))
}

# ─────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ─────────────────────────────────────────────────────────────

cat("=== Generating Table 1 ===\n")

pre_be   <- primary |> filter(belgium == 1, !post)
pre_ctrl <- primary |> filter(belgium == 0, !post)
post_be  <- primary |> filter(belgium == 1, post == 1)
post_ctrl<- primary |> filter(belgium == 0, post == 1)

sr <- function(df) {
  c(nrow(df),
    mean(df$emp, na.rm = TRUE), sd(df$emp, na.rm = TRUE),
    mean(df$log_emp, na.rm = TRUE), sd(df$log_emp, na.rm = TRUE),
    mean(df$labor_share, na.rm = TRUE))
}

s1 <- sr(pre_be); s2 <- sr(pre_ctrl); s3 <- sr(post_be); s4 <- sr(post_ctrl)

tab1 <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\begin{threeparttable}
\\begin{tabular}{lrrrrrr}
\\toprule
 & N & \\multicolumn{2}{c}{Employment (000s)} & \\multicolumn{2}{c}{Log Employment} & Labor \\\\
 & & Mean & SD & Mean & SD & Share \\\\
\\midrule
Belgium, Pre-reform & %d & %.1f & %.1f & %.2f & %.2f & %.2f \\\\
Controls, Pre-reform & %d & %.1f & %.1f & %.2f & %.2f & %.2f \\\\
Belgium, Post-reform & %d & %.1f & %.1f & %.2f & %.2f & %.2f \\\\
Controls, Post-reform & %d & %.1f & %.1f & %.2f & %.2f & %.2f \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Employment measured in thousands of persons by NACE A*10 sector (seasonally and calendar adjusted) from Eurostat (namq\\_10\\_a10\\_e). Control countries: Netherlands, Germany, Luxembourg. Pre-reform: 2013-Q1 to 2016-Q1 (13 quarters). Post-reform: 2016-Q2 to 2019-Q4 (15 quarters). Labor share is sector-level compensation of employees divided by gross value added (Eurostat nama\\_10\\_a10, 2013--2015 average).
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:summary}
\\end{table}",
s1[1], s1[2], s1[3], s1[4], s1[5], s1[6],
s2[1], s2[2], s2[3], s2[4], s2[5], s2[6],
s3[1], s3[2], s3[3], s3[4], s3[5], s3[6],
s4[1], s4[2], s4[3], s4[4], s4[5], s4[6])

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

# ─────────────────────────────────────────────────────────────
# TABLE 2: First Stage
# ─────────────────────────────────────────────────────────────

cat("=== Generating Table 2 ===\n")

fs  <- get_did(fs_model, "belgium.*post")
ssc <- get_did(m_ssc, "belgium.*post")
wg  <- get_did(m_wage, "belgium.*post")

fs_f  <- fmt(fs, 2)
ssc_f <- fmt(ssc, 4)
wg_f  <- fmt(wg, 2)

tab2 <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{First Stage: Effect of Belgium's SSC Reform on Labor Costs}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
 & (1) & (2) & (3) \\\\
 & Non-wage Cost & Employer SSC & Wage \\\\
 & Index & Share & Index \\\\
\\midrule
Belgium $\\times$ Post & %s & %s & %s \\\\
 & %s & %s & %s \\\\
\\\\
Country$\\times$Sector FE & Yes & Yes & Yes \\\\
Time FE & Yes & Yes & Yes \\\\
N & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (1): Eurostat Labor Cost Index (non-wage component, 2020 = 100), normalized to 2015-Q4. Column (2): employer social security contributions as share of total compensation, from national accounts (namq\\_10\\_a10). Column (3): Eurostat Labor Cost Index (wage component). Controls: Netherlands, Germany, Luxembourg (cols 2--3), plus Austria, France (col 1). Pre-reform: 2013-Q1 to 2016-Q1. Post-reform: 2016-Q2 to 2019-Q4.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:first_stage}
\\end{table}",
fs_f[1], ssc_f[1], wg_f[1],
fs_f[2], ssc_f[2], wg_f[2],
nobs(fs_model), nobs(m_ssc), nobs(m_wage))

writeLines(tab2, file.path(tables_dir, "tab2_first_stage.tex"))

# ─────────────────────────────────────────────────────────────
# TABLE 3: Main Results
# ─────────────────────────────────────────────────────────────

cat("=== Generating Table 3 ===\n")

m1c <- get_did(m1, "belgium.*post")
m2c <- get_did(m2, "belgium.*full_post")
m3p1 <- get_did(m3, "phase1")
m3p2 <- get_did(m3, "phase2")
m4d  <- get_did(m4, "belgium:post$")
m4t  <- get_did(m4, "labor_intensity")
mec  <- get_did(m_expanded, "belgium.*post")

m1f <- fmt(m1c); m2f <- fmt(m2c); m3f1 <- fmt(m3p1); m3f2 <- fmt(m3p2)
m4df <- fmt(m4d); m4tf <- fmt(m4t); mef <- fmt(mec)

tab3 <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Main Results: Effect of Belgium's SSC Reform on Employment}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & (1) & (2) & (3) & (4) & (5) \\\\
 & Baseline & Full Cut & Phase-in & Triple-Diff & Expanded \\\\
\\midrule
Belgium $\\times$ Post & %s & & & %s & %s \\\\
 & %s & & & %s & %s \\\\
Belgium $\\times$ Phase 1 (30\\%%%%) & & & %s & & \\\\
 & & & %s & & \\\\
Belgium $\\times$ Phase 2 (25\\%%%%) & & %s & %s & & \\\\
 & & %s & %s & & \\\\
Belgium $\\times$ Post $\\times$ Labor Int. & & & & %s & \\\\
 & & & & %s & \\\\
\\\\
Country$\\times$Sector FE & Yes & Yes & Yes & Yes & Yes \\\\
Time FE & Yes & Yes & Yes & Yes & Yes \\\\
Controls & NL, DE, LU & NL, DE, LU & NL, DE, LU & NL, DE, LU & +AT,FR,DK,FI,SE \\\\
N & %d & %d & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable: log quarterly employment (thousands of persons, seasonally adjusted). Standard errors clustered at country level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Phase 1: 2016-Q2 to 2017-Q4 (SSC cut from 32.4\\%%%% to 30\\%%%%). Phase 2: 2018-Q1 to 2019-Q4 (SSC cut to 25\\%%%%). Labor Intensity is standardized (mean 0, SD 1) pre-reform sector-level labor share (compensation/GVA). Column (5) expands controls to include Austria, France, Denmark, Finland, and Sweden. Permutation p-value (two-sided) for baseline: %.3f.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:main}
\\end{table}",
m1f[1], m4df[1], mef[1],
m1f[2], m4df[2], mef[2],
m3f1[1], m3f1[2],
m2f[1], m3f2[1], m2f[2], m3f2[2],
m4tf[1], m4tf[2],
nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m_expanded),
perm_pval)

writeLines(tab3, file.path(tables_dir, "tab3_main.tex"))

# ─────────────────────────────────────────────────────────────
# TABLE 4: Robustness
# ─────────────────────────────────────────────────────────────

cat("=== Generating Table 4 ===\n")

nace_labels <- c(
  "A"="Agriculture", "B-E"="Industry", "F"="Construction",
  "G-I"="Trade/Transport/Hosp.", "J"="ICT", "K"="Finance/Insurance",
  "L"="Real Estate", "M_N"="Prof./Admin Services",
  "O-Q"="Public Admin/Educ/Health", "R-U"="Arts/Other Services"
)

loo_rows <- ""
for (s in names(loo_coefs)) {
  lab <- ifelse(s %in% names(nace_labels), nace_labels[s], s)
  loo_rows <- paste0(loo_rows, sprintf("Excl. %s & %.4f \\\\\n", lab, loo_coefs[s]))
}

pub_f <- fmt(get_did(m_placebo_pub, "belgium.*post"))
re_f  <- fmt(get_did(m_placebo_re, "belgium.*post"))

tab4 <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Robustness: Leave-One-Sector-Out and Placebo Outcomes}
\\begin{threeparttable}
\\begin{tabular}{lc}
\\toprule
\\multicolumn{2}{l}{\\textit{Panel A: Leave-one-sector-out}} \\\\
\\midrule
Specification & Belgium $\\times$ Post \\\\
\\midrule
%s\\midrule
Baseline (all sectors) & %.4f \\\\
\\midrule
\\multicolumn{2}{l}{\\textit{Panel B: Placebo outcomes}} \\\\
\\midrule
Public sector (NACE O--Q) & %s \\\\
 & %s \\\\
Real estate (NACE L) & %s \\\\
 & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Panel A shows Belgium $\\times$ Post coefficient when excluding one NACE A*10 sector at a time. Panel B tests placebo outcomes: public administration (NACE O--Q) and real estate (NACE L) should be unaffected by employer SSC cuts because public employers do not profit-maximize and real estate is capital-intensive. All specifications include country$\\times$sector and time fixed effects with country-clustered standard errors.
\\end{tablenotes}
\\end{threeparttable}
\\label{tab:robustness}
\\end{table}",
loo_rows, m1c$b,
pub_f[1], pub_f[2],
re_f[1], re_f[2])

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))

# ─────────────────────────────────────────────────────────────
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# ─────────────────────────────────────────────────────────────

cat("=== Generating Table F1 ===\n")

sd_y <- sd(primary$log_emp[primary$post == 0], na.rm = TRUE)

# Panel A: Pooled
sde_main <- m1c$b / sd_y
se_sde_main <- m1c$se / sd_y
sde_full <- m2c$b / sd_y
se_sde_full <- m2c$se / sd_y

classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Panel B: Heterogeneous (sample splits by sector labor intensity)
median_ls <- median(primary$labor_share[primary$belgium == 1], na.rm = TRUE)
high_li <- primary |> filter(labor_share >= median_ls)
low_li  <- primary |> filter(labor_share < median_ls)

m_high <- feols(log_emp ~ belgium:post | cs_id + time_id, data = high_li, cluster = ~geo)
m_low  <- feols(log_emp ~ belgium:post | cs_id + time_id, data = low_li, cluster = ~geo)

b_high <- get_did(m_high, "belgium.*post")
b_low  <- get_did(m_low, "belgium.*post")

sd_y_high <- sd(high_li$log_emp[high_li$post == 0], na.rm = TRUE)
sd_y_low  <- sd(low_li$log_emp[low_li$post == 0], na.rm = TRUE)

sde_high <- b_high$b / sd_y_high
se_sde_high <- b_high$se / sd_y_high
sde_low <- b_low$b / sd_y_low
se_sde_low <- b_low$se / sd_y_low

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Belgium (treated) vs.\\ Netherlands, Germany, and Luxembourg (controls). ",
  "\\textbf{Research question:} Does a large reduction in the statutory employer social security contribution rate increase sectoral employment when automatic wage indexation prevents pass-through to workers? ",
  "\\textbf{Policy mechanism:} The 2016--2018 Belgian tax shift (Loi du 26 d\\'{e}cembre 2015) reduced the standard employer SSC rate from 32.4\\%{} to 25\\%{} in two steps, ",
  "lowering non-wage labor costs while Belgium's automatic wage indexation and sectoral collective bargaining prevented any corresponding reduction in gross wages---making the cut a pure windfall to employers. ",
  "\\textbf{Outcome definition:} Log of quarterly employment in thousands of persons (seasonally and calendar adjusted, domestic concept) by NACE Rev.~2 A*10 sector, from Eurostat table namq\\_10\\_a10\\_e. ",
  "\\textbf{Treatment:} Binary (Belgium = 1 post-2016-Q2; controls = 0). ",
  "\\textbf{Data:} Eurostat quarterly national accounts and labor cost indices, 2013-Q1 to 2019-Q4, country$\\times$sector$\\times$quarter panel. ",
  "\\textbf{Method:} Difference-in-differences with country$\\times$sector and time fixed effects; standard errors clustered at the country level; permutation inference across placebo-treated control countries. ",
  "\\textbf{Sample:} 10 NACE A*10 sectors $\\times$ 4 countries $\\times$ 28 quarters; pre-COVID truncation at 2019-Q4. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log employment. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{llcccccc}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\
Log empl. & Any post (2016--2019) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
Log empl. & Full cut (2018--2019) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (sample splits by sector labor intensity)}} \\\\
Log empl. & High labor-intensity & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
Log empl. & Low labor-intensity & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{table}",
m1c$b, m1c$se, sd_y, sde_main, se_sde_main, classify(sde_main),
m2c$b, m2c$se, sd_y, sde_full, se_sde_full, classify(sde_full),
b_high$b, b_high$se, sd_y_high, sde_high, se_sde_high, classify(sde_high),
b_low$b, b_low$se, sd_y_low, sde_low, se_sde_low, classify(sde_low),
sde_notes)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat(sprintf("\nAll tables written to %s/\n", tables_dir))
