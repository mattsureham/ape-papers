# 05_tables.R — Generate all LaTeX tables
# apep_0900: CBAM product-scope loophole

source("00_packages.R")

# Fix namespace conflict: scales::pvalue masks fixest::pvalue
pvalue <- fixest::pvalue

load("../data/main_results.RData")
load("../data/robustness_results.RData")

# ========================================================
# TABLE 1: Descriptive Statistics
# ========================================================

cat("=== Generating Table 1: Descriptive Statistics ===\n")

# Summary by group × period
desc <- panel[material == "iron_steel", .(
  mean_value = mean(value_usd / 1e6),
  sd_value = sd(value_usd / 1e6),
  mean_qty = mean(qty_kg / 1e6),
  n = .N
), by = .(covered, high_carbon, post)]

# Also compute pre-treatment SD(Y) for SDE
pre_sd_value <- sd(panel_hs4[post == 0]$log_value)
pre_sd_qty <- sd(panel_hs4[post == 0 & qty_kg > 0]$log_qty)
pre_sd_value_fe <- sd(panel_hs4[post == 0 & material == "iron_steel"]$log_value)

cat(sprintf("Pre-treatment SD(log value): %.3f\n", pre_sd_value))
cat(sprintf("Pre-treatment SD(log value, iron/steel): %.3f\n", pre_sd_value_fe))

# Create descriptive statistics table
tab1 <- data.table(
  Panel = c(
    rep("Panel A: Pre-CBAM (2019--2023)", 4),
    rep("Panel B: Post-CBAM (2024)", 4)
  ),
  Group = rep(c(
    "Covered $\\times$ High-carbon",
    "Covered $\\times$ Low-carbon",
    "Exempt $\\times$ High-carbon",
    "Exempt $\\times$ Low-carbon"
  ), 2),
  `Mean imports (\\$M)` = c(
    desc[covered == 1 & high_carbon == 1 & post == 0, mean_value],
    desc[covered == 1 & high_carbon == 0 & post == 0, mean_value],
    desc[covered == 0 & high_carbon == 1 & post == 0, mean_value],
    desc[covered == 0 & high_carbon == 0 & post == 0, mean_value],
    desc[covered == 1 & high_carbon == 1 & post == 1, mean_value],
    desc[covered == 1 & high_carbon == 0 & post == 1, mean_value],
    desc[covered == 0 & high_carbon == 1 & post == 1, mean_value],
    desc[covered == 0 & high_carbon == 0 & post == 1, mean_value]
  )
)

# Build LaTeX table 1
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Descriptive Statistics: EU Extra-EU Metal Imports}\n",
  "\\label{tab:descriptive}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Mean Annual Imports (\\$B)} \\\\\n",
  "\\cmidrule(lr){2-3}\n",
  " & Iron/Steel (HS~72--73) & Aluminum (HS~76) \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Pre-CBAM (2019--2023)}} \\\\\n",
  "\\addlinespace[3pt]\n"
)

# Compute means by material for the table
fe_stats <- panel[, .(mean_B = round(mean(value_usd) / 1e9, 1)),
                  by = .(material, covered, high_carbon, post)]

# Iron/Steel pre-period
pre_fe <- fe_stats[material == "iron_steel" & post == 0]
post_fe <- fe_stats[material == "iron_steel" & post == 1]
# Aluminum pre-period
pre_al <- fe_stats[material == "aluminum" & post == 0]
post_al <- fe_stats[material == "aluminum" & post == 1]

# Fill in missing aluminum values with 0 if needed
get_val <- function(dt, cov, hc) {
  val <- dt[covered == cov & high_carbon == hc, mean_B]
  if (length(val) == 0) return("---")
  return(sprintf("%.1f", val))
}

tab1_tex <- paste0(tab1_tex,
  sprintf("~~Covered $\\times$ High-carbon & %s & %s \\\\\n",
          get_val(pre_fe, 1, 1), get_val(pre_al, 1, 1)),
  sprintf("~~Covered $\\times$ Low-carbon & %s & %s \\\\\n",
          get_val(pre_fe, 1, 0), get_val(pre_al, 1, 0)),
  sprintf("~~Exempt $\\times$ High-carbon & %s & %s \\\\\n",
          get_val(pre_fe, 0, 1), get_val(pre_al, 0, 1)),
  sprintf("~~Exempt $\\times$ Low-carbon & %s & %s \\\\\n",
          get_val(pre_fe, 0, 0), get_val(pre_al, 0, 0)),
  "\\addlinespace[6pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Post-CBAM (2024)}} \\\\\n",
  "\\addlinespace[3pt]\n",
  sprintf("~~Covered $\\times$ High-carbon & %s & %s \\\\\n",
          get_val(post_fe, 1, 1), get_val(post_al, 1, 1)),
  sprintf("~~Covered $\\times$ Low-carbon & %s & %s \\\\\n",
          get_val(post_fe, 1, 0), get_val(post_al, 1, 0)),
  sprintf("~~Exempt $\\times$ High-carbon & %s & %s \\\\\n",
          get_val(post_fe, 0, 1), get_val(post_al, 0, 1)),
  sprintf("~~Exempt $\\times$ Low-carbon & %s & %s \\\\\n",
          get_val(post_fe, 0, 0), get_val(post_al, 0, 0)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Annual EU extra-EU import values in billions of USD from UN Comtrade. ",
  "``Covered'' products face CBAM reporting requirements (HS~72: iron and steel; HS~7601--7603: unwrought aluminum). ",
  "``Exempt'' products are downstream articles from the same materials (HS~73: articles of iron/steel; HS~7604--7616: aluminum articles). ",
  "``High-carbon'' partners: China, India, Turkey, Russia, Ukraine, Vietnam (steel carbon intensity $>$1.5 tCO\\textsubscript{2}/t). ",
  "``Low-carbon'' partners: Japan, South Korea, Brazil ($<$1.2 tCO\\textsubscript{2}/t). ",
  "Pre-CBAM period: 2019--2023; Post-CBAM: 2024 (first full year of transitional phase).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_descriptive.tex")
cat("Written: tables/tab1_descriptive.tex\n")

# ========================================================
# TABLE 2: Main DDD Results
# ========================================================

cat("\n=== Generating Table 2: Main DDD Results ===\n")

# Extract coefficients and SEs
extract_coef <- function(model, var_pattern = "covered:high_carbon:post") {
  cf <- coef(model)
  ses <- se(model)
  pv <- pvalue(model)
  idx <- grep(var_pattern, names(cf))
  if (length(idx) == 0) return(list(beta = NA, se = NA, p = NA))
  list(beta = cf[idx], se = ses[idx], p = pv[idx])
}

# Also extract covered:post DD coefficient where available
extract_dd <- function(model, var_pattern = "covered:post") {
  cf <- coef(model)
  ses <- se(model)
  pv <- pvalue(model)
  idx <- grep(paste0("^", var_pattern, "$"), names(cf))
  if (length(idx) == 0) return(list(beta = NA, se = NA, p = NA))
  list(beta = cf[idx], se = ses[idx], p = pv[idx])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

# Models: m1 (DD), m2 (DDD HS2), m3 (DDD HS2 full FE), m4 (DDD HS4), m5 (qty), r1 (iron/steel)
models <- list(m1, m3, m4, r1, m5)
model_names <- c("DD", "DDD (HS2)", "DDD (HS4)", "Iron/Steel", "Quantity")

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{The Effect of CBAM on EU Metal Imports: Triple-Difference Estimates}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\small\n",
  "\\begin{tabular}{l*{5}{c}}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & DD & DDD & DDD & DDD & DDD \\\\\n",
  " & All metals & All metals & All metals & Iron/steel & Quantity \\\\\n",
  "\\hline\n",
  "\\addlinespace[3pt]\n"
)

# DDD row
ddd_row <- "Covered $\\times$ High-carbon $\\times$ Post & "
for (i in seq_along(models)) {
  r <- extract_coef(models[[i]])
  if (i == 1) {
    # m1 is DD only, no DDD coefficient
    ddd_row <- paste0(ddd_row, "---")
  } else {
    ddd_row <- paste0(ddd_row, sprintf("%.3f%s", r$beta, stars(r$p)))
  }
  if (i < length(models)) ddd_row <- paste0(ddd_row, " & ")
}
ddd_row <- paste0(ddd_row, " \\\\\n")

# SE row
se_row <- " & "
for (i in seq_along(models)) {
  r <- extract_coef(models[[i]])
  if (i == 1) {
    se_row <- paste0(se_row, "")
  } else {
    se_row <- paste0(se_row, sprintf("(%.3f)", r$se))
  }
  if (i < length(models)) se_row <- paste0(se_row, " & ")
}
se_row <- paste0(se_row, " \\\\\n")

# DD row (covered × post) — only for m1
dd_coef <- extract_coef(m1, "covered:post")
dd_row <- sprintf("Covered $\\times$ Post & %.3f%s & ", dd_coef$beta, stars(dd_coef$p))
dd_se_row <- sprintf(" & (%.3f) & ", dd_coef$se)
for (i in 2:length(models)) {
  dd_row <- paste0(dd_row, "---")
  dd_se_row <- paste0(dd_se_row, "")
  if (i < length(models)) {
    dd_row <- paste0(dd_row, " & ")
    dd_se_row <- paste0(dd_se_row, " & ")
  }
}
dd_row <- paste0(dd_row, " \\\\\n")
dd_se_row <- paste0(dd_se_row, " \\\\\n")

# Fixed effects rows
fe_rows <- paste0(
  "\\addlinespace[3pt]\n",
  "\\hline\n",
  "\\addlinespace[3pt]\n",
  "Product FE & \\checkmark & & & & \\\\\n",
  "Partner FE & \\checkmark & & & & \\\\\n",
  "Year FE & \\checkmark & & & & \\\\\n",
  "Product $\\times$ Partner FE & & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Product $\\times$ Year FE & & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Partner $\\times$ Year FE & & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n"
)

# N and R2
n_r2_rows <- paste0(
  "\\addlinespace[3pt]\n",
  "\\hline\n",
  "\\addlinespace[3pt]\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m4), big.mark = ","),
          format(nobs(r1), big.mark = ","),
          format(nobs(m5), big.mark = ",")),
  sprintf("Product level & HS2 & HS2 & HS4 & HS4 & HS4 \\\\\n"),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
          r2(m1, "ar2"), r2(m3, "ar2"), r2(m4, "ar2"), r2(r1, "ar2"), r2(m5, "ar2"))
)

tab2_tex <- paste0(tab2_tex, dd_row, dd_se_row, "\\addlinespace[6pt]\n",
                   ddd_row, se_row, fe_rows, n_r2_rows,
                   "\\hline\\hline\n",
                   "\\end{tabular}\n",
                   "\\begin{tablenotes}[flushleft]\\footnotesize\n",
                   "\\item \\textit{Notes:} Dependent variable: log import value (USD) in columns 1--4; log import quantity (kg) in column~5. ",
                   "``Covered'' = CBAM-covered HS codes (HS~72, HS~7601--7603); ``Exempt'' = downstream articles (HS~73, HS~7604--7616). ",
                   "``High-carbon'' = China, India, Turkey, Russia, Ukraine, Vietnam; ``Low-carbon'' = Japan, South Korea, Brazil. ",
                   "``Post'' = 2024 (first full year of CBAM transitional phase). ",
                   "Standard errors clustered at product$\\times$partner level in parentheses. ",
                   "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
                   "\\end{tablenotes}\n",
                   "\\end{threeparttable}\n",
                   "\\end{table}\n")

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Written: tables/tab2_main.tex\n")

# ========================================================
# TABLE 3: Robustness
# ========================================================

cat("\n=== Generating Table 3: Robustness ===\n")

# r1 (iron/steel), r2 (post=2023+), r3 (drop RU/UA), r4 (unit value)
rob_models <- list(r1, r2, r3, r4)
rob_names <- c("Iron/steel", "Post = 2023+", "Drop RU/UA", "Unit value")

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\small\n",
  "\\begin{tabular}{l*{4}{c}}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  sprintf(" & %s & %s & %s & %s \\\\\n",
          rob_names[1], rob_names[2], rob_names[3], rob_names[4]),
  "\\hline\n",
  "\\addlinespace[3pt]\n"
)

# DDD coefficients
ddd_rob_row <- "Covered $\\times$ High-carbon $\\times$ Post & "
se_rob_row <- " & "
for (i in seq_along(rob_models)) {
  r <- extract_coef(rob_models[[i]], "covered:high_carbon:post")
  ddd_rob_row <- paste0(ddd_rob_row, sprintf("%.3f%s", r$beta, stars(r$p)))
  se_rob_row <- paste0(se_rob_row, sprintf("(%.3f)", r$se))
  if (i < length(rob_models)) {
    ddd_rob_row <- paste0(ddd_rob_row, " & ")
    se_rob_row <- paste0(se_rob_row, " & ")
  }
}
ddd_rob_row <- paste0(ddd_rob_row, " \\\\\n")
se_rob_row <- paste0(se_rob_row, " \\\\\n")

tab3_tex <- paste0(tab3_tex, ddd_rob_row, se_rob_row,
  "\\addlinespace[3pt]\n",
  "\\hline\n",
  "\\addlinespace[3pt]\n",
  "Full two-way FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(r1), big.mark = ","),
          format(nobs(r2), big.mark = ","),
          format(nobs(r3), big.mark = ","),
          format(nobs(r4), big.mark = ",")),
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n",
          r2(r1, "ar2"), r2(r2, "ar2"), r2(r3, "ar2"), r2(r4, "ar2")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} All columns include product$\\times$partner, product$\\times$year, and partner$\\times$year fixed effects. ",
  "Column~1 restricts to iron and steel products (HS~72 vs.~73). ",
  "Column~2 redefines the post period to include 2023 (CBAM announced Q2~2023). ",
  "Column~3 drops Russia and Ukraine (subject to separate EU sanctions). ",
  "Column~4 uses log unit value (USD/kg) as the dependent variable. ",
  "Standard errors clustered at product$\\times$partner level. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_robustness.tex")
cat("Written: tables/tab3_robustness.tex\n")

# ========================================================
# TABLE 4: Event Study Coefficients
# ========================================================

cat("\n=== Generating Table 4: Event Study ===\n")

es_cf <- coef(es)
es_se <- se(es)
es_pv <- pvalue(es)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Pre-Trends and Post-Treatment Effects}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Coefficient & Std.\\ Error \\\\\n",
  "\\hline\n",
  "\\addlinespace[3pt]\n",
  sprintf("$\\beta_{2019}$ (Covered $\\times$ High-carbon $\\times$ 2019) & %.3f%s & (%.3f) \\\\\n",
          es_cf["year::2019:treat"], stars(es_pv["year::2019:treat"]), es_se["year::2019:treat"]),
  sprintf("$\\beta_{2020}$ (Covered $\\times$ High-carbon $\\times$ 2020) & %.3f%s & (%.3f) \\\\\n",
          es_cf["year::2020:treat"], stars(es_pv["year::2020:treat"]), es_se["year::2020:treat"]),
  sprintf("$\\beta_{2021}$ (Covered $\\times$ High-carbon $\\times$ 2021) & %.3f%s & (%.3f) \\\\\n",
          es_cf["year::2021:treat"], stars(es_pv["year::2021:treat"]), es_se["year::2021:treat"]),
  "\\addlinespace[3pt]\n",
  "$\\beta_{2022}$ (Reference year) & 0 & --- \\\\\n",
  "\\addlinespace[3pt]\n",
  sprintf("$\\beta_{2024}$ (Covered $\\times$ High-carbon $\\times$ 2024) & %.3f%s & (%.3f) \\\\\n",
          es_cf["year::2024:treat"], stars(es_pv["year::2024:treat"]), es_se["year::2024:treat"]),
  "\\addlinespace[3pt]\n",
  "\\hline\n",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\\n", format(nobs(es), big.mark = ",")),
  "Product $\\times$ Partner FE & \\multicolumn{2}{c}{\\checkmark} \\\\\n",
  "Product $\\times$ Year FE & \\multicolumn{2}{c}{\\checkmark} \\\\\n",
  "Partner $\\times$ Year FE & \\multicolumn{2}{c}{\\checkmark} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Event study specification interacting Covered $\\times$ High-carbon with year indicators. ",
  "Base year: 2022 (last full pre-treatment year). Year 2023 dropped (transition year: CBAM enacted May 2023, transitional phase began October 2023). ",
  "Sample restricted to HS 4-digit products. ",
  "Standard errors clustered at product$\\times$partner level. ",
  "$^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_eventstudy.tex")
cat("Written: tables/tab4_eventstudy.tex\n")

# ========================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# ========================================================

cat("\n=== Generating Table F1: SDE ===\n")

# Compute SDEs for main outcomes
# Main spec (m4): all metals, log value
beta_m4 <- coef(m4)["covered:high_carbon:post"]
se_m4 <- se(m4)["covered:high_carbon:post"]
sd_y_m4 <- pre_sd_value
sde_m4 <- beta_m4 / sd_y_m4
sde_se_m4 <- se_m4 / sd_y_m4

# Iron/steel (r1): log value
beta_r1 <- coef(r1)["covered:high_carbon:post"]
se_r1 <- se(r1)["covered:high_carbon:post"]
sd_y_r1 <- pre_sd_value_fe
sde_r1 <- beta_r1 / sd_y_r1
sde_se_r1 <- se_r1 / sd_y_r1

# Quantity (m5): log qty
beta_m5 <- coef(m5)["covered:high_carbon:post"]
se_m5 <- se(m5)["covered:high_carbon:post"]
sd_y_m5 <- pre_sd_qty
sde_m5 <- beta_m5 / sd_y_m5
sde_se_m5 <- se_m5 / sd_y_m5

# Unit value (r4)
beta_r4 <- coef(r4)["covered:high_carbon:post"]
se_r4 <- se(r4)["covered:high_carbon:post"]
panel_hs4[, unit_value := value_usd / qty_kg]
panel_hs4[, log_uv := log(unit_value + 1)]
sd_y_r4 <- sd(panel_hs4[post == 0 & is.finite(log_uv)]$log_uv, na.rm = TRUE)
sde_r4 <- beta_r4 / sd_y_r4
sde_se_r4 <- se_r4 / sd_y_r4

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneous: high-carbon only (DD within high-carbon partners)
hs4_hc <- panel_hs4[high_carbon == 1]
m_hc <- feols(log_value ~ covered:post | hs4 + partner_code + year,
              data = hs4_hc, cluster = ~hs4 + partner_code)
beta_hc <- coef(m_hc)["covered:post"]
se_hc <- se(m_hc)["covered:post"]
sd_y_hc <- sd(hs4_hc[post == 0]$log_value)
sde_hc <- beta_hc / sd_y_hc
sde_se_hc <- se_hc / sd_y_hc

# Heterogeneous: low-carbon only (DD within low-carbon partners)
hs4_lc <- panel_hs4[high_carbon == 0]
m_lc <- feols(log_value ~ covered:post | hs4 + partner_code + year,
              data = hs4_lc, cluster = ~hs4 + partner_code)
beta_lc <- coef(m_lc)["covered:post"]
se_lc <- se(m_lc)["covered:post"]
sd_y_lc <- sd(hs4_lc[post == 0]$log_value)
sde_lc <- beta_lc / sd_y_lc
sde_se_lc <- se_lc / sd_y_lc

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states, extra-EU imports). ",
  "\\textbf{Research question:} Does the EU Carbon Border Adjustment Mechanism's product-scope boundary --- covering raw metals but exempting downstream articles --- induce differential trade responses among high-carbon-intensity exporters during the transitional reporting phase? ",
  "\\textbf{Policy mechanism:} CBAM Regulation 2023/956 imposes carbon-cost reporting on imports of raw iron/steel (HS~72) and unwrought aluminum (HS~7601--7603) from non-EU partners, while exempting processed articles from the same materials (HS~73, HS~7604--7616), creating a sharp product-scope boundary within identical material supply chains. ",
  "\\textbf{Outcome definition:} Log annual import value (USD) at HS 4-digit product level from UN Comtrade, measuring bilateral trade flows between EU-27 and non-EU partner countries. ",
  "\\textbf{Treatment:} Binary product-level coverage indicator interacted with partner carbon intensity and post-period; the triple interaction identifies differential responses by high-carbon exporters to CBAM coverage. ",
  "\\textbf{Data:} UN Comtrade HS 4-digit annual imports, 2019--2024, product-partner-year panel with 2,859 observations across 71 products and 7 partner countries. ",
  "\\textbf{Method:} Triple-difference (DDD) with product$\\times$partner, product$\\times$year, and partner$\\times$year fixed effects; standard errors clustered at product$\\times$partner level. ",
  "\\textbf{Sample:} Extra-EU imports of iron/steel and aluminum products from major non-EU exporters classified by steel production carbon intensity; Russia and Ukraine included in main specification but excluded in robustness. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\addlinespace[3pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "\\addlinespace[3pt]\n",
  sprintf("Import value (all metals) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_m4, se_m4, sd_y_m4, sde_m4, sde_se_m4, classify_sde(sde_m4)),
  sprintf("Import value (iron/steel) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_r1, se_r1, sd_y_r1, sde_r1, sde_se_r1, classify_sde(sde_r1)),
  sprintf("Import quantity & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_m5, se_m5, sd_y_m5, sde_m5, sde_se_m5, classify_sde(sde_m5)),
  sprintf("Unit value & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_r4, se_r4, sd_y_r4, sde_r4, sde_se_r4, classify_sde(sde_r4)),
  "\\addlinespace[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by partner carbon intensity)}} \\\\\n",
  "\\addlinespace[3pt]\n",
  sprintf("High-carbon partners only & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_hc, se_hc, sd_y_hc, sde_hc, sde_se_hc, classify_sde(sde_hc)),
  sprintf("Low-carbon partners only & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
          beta_lc, se_lc, sd_y_lc, sde_lc, sde_se_lc, classify_sde(sde_lc)),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Written: tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
