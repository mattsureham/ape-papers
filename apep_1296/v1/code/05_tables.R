## 05_tables.R — Generate all LaTeX tables for Lithuania i.SAF study
## apep_1296

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cp <- fread(file.path(DATA_DIR, "country_panel.csv"))
sp <- fread(file.path(DATA_DIR, "sector_panel.csv"))
vg <- fread(file.path(DATA_DIR, "vat_gap.csv"))
load(file.path(DATA_DIR, "regression_results.RData"))
load(file.path(DATA_DIR, "robustness_results.RData"))

# ═══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 1: Summary Statistics\n")

# Panel A: Country-level
cp[, log_vat := log(vat_meur)]
sumstats_country <- cp[, .(
  `VAT Revenue (EUR mn)` = sprintf("%.0f", mean(vat_meur)),
  `GDP (EUR mn)` = sprintf("%.0f", mean(gdp_meur)),
  `VAT/GDP (\\%%)` = sprintf("%.2f", mean(vat_gdp)),
  Years = sprintf("%d--%d", min(year), max(year)),
  N = as.character(.N)
), by = .(Country = geo)]

# Panel B: VAT gap by period
vg_lt <- vg[geo == "LT"]
vg_lv <- vg[geo == "LV"]
vg_ee <- vg[geo == "EE"]
vg_eu <- vg[geo == "EU27"]

# Panel C: Sector panel descriptives
sumstats_sector <- data.table(
  Statistic = c("Observations", "Countries", "Sectors", "Years",
                "Mean log GVA", "SD log GVA",
                "Mean B2B intensity", "SD B2B intensity"),
  Value = c(
    as.character(nrow(sp)),
    as.character(uniqueN(sp$geo)),
    as.character(uniqueN(sp$nace_r2)),
    sprintf("%d--%d", min(sp$year), max(sp$year)),
    sprintf("%.3f", mean(sp$log_gva, na.rm = TRUE)),
    sprintf("%.3f", sd(sp$log_gva, na.rm = TRUE)),
    sprintf("%.3f", mean(sp$invoice_intensity, na.rm = TRUE)),
    sprintf("%.3f", sd(sp$invoice_intensity, na.rm = TRUE))
  )
)

# Write Table 1
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Country-level VAT data, 2010--2022}} \\\\[3pt]",
  "Country & VAT (EUR mn) & GDP (EUR mn) & VAT/GDP (\\%) & Years & N \\\\",
  "\\hline"
)

country_names <- c(LT = "Lithuania", LV = "Latvia", EE = "Estonia",
                    FI = "Finland", PL = "Poland")
for (i in seq_len(nrow(sumstats_country))) {
  r <- sumstats_country[i]
  cname <- country_names[r$Country]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s & %s \\\\",
            cname, r$`VAT Revenue (EUR mn)`, r$`GDP (EUR mn)`,
            r$`VAT/GDP (\\%%)`, r$Years, r$N))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel B: VAT gap (\\% of VTTL), 2013--2022}} \\\\[3pt]",
  " & Pre-2017 & Post-2016 & $\\Delta$ & & \\\\",
  "\\hline"
)

for (g in c("LT", "LV", "EE", "EU27")) {
  pre_val <- vg[geo == g & year <= 2016, mean(vat_gap_pct)]
  post_val <- vg[geo == g & year >= 2017, mean(vat_gap_pct)]
  delta <- post_val - pre_val
  gname <- c(LT = "Lithuania", LV = "Latvia", EE = "Estonia", EU27 = "EU average")[g]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.1f & %.1f & %.1f & & \\\\", gname, pre_val, post_val, delta))
}

tab1_lines <- c(tab1_lines,
  sprintf("DiD (LT vs Baltic) & & & %.1f & & \\\\", did_vat_gap),
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel C: Sector-country-year panel}} \\\\[3pt]"
)

for (i in seq_len(nrow(sumstats_sector))) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & \\multicolumn{5}{c}{%s} \\\\",
            sumstats_sector$Statistic[i], sumstats_sector$Value[i]))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports mean values over 2010--2022. VAT revenue is Eurostat \\texttt{gov\\_10a\\_taxag} (D211). GDP is \\texttt{nama\\_10\\_gdp} (B1GQ). Panel B reports VAT gap estimates from the European Commission/CASE VAT Gap Study Reports (2014--2023 editions). The DiD estimate is Lithuania's pre-post change minus the average of Latvia's and Estonia's pre-post changes. Panel C describes the sector-country-year panel used in the continuous-treatment specification.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(TABLE_DIR, "tab1_sumstats.tex"))
cat("  Table 1 written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 2: Main DiD Results (country-level and sector-level)
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 2: Main Results\n")

# Use modelsummary for clean output
models_main <- list(
  "(1)" = m1_simple,
  "(2)" = m1_baltic,
  "(3)" = m_logvat,
  "(4)" = m2_base,
  "(5)" = m2_full
)

# Create custom labels
cm <- c(
  "treat" = "Lithuania $\\times$ Post-2016",
  "treat_intensity" = "Lithuania $\\times$ Post $\\times$ B2B Intensity"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = 0),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: geo", "clean" = "Country FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: nace_r2", "clean" = "Sector FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: nace_r2^geo", "clean" = "Sector $\\times$ Country FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

# Build Table 2 manually for full LaTeX control
tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of i.SAF Mandate on VAT Revenue and Sector Output}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & VAT/GDP & VAT/GDP & log VAT & log GVA & log GVA \\\\",
  " & All & Baltic & All & Base & Sector$\\times$Country \\\\",
  "\\hline"
)

# Row 1: Lithuania x Post coefficient
tab2_lines <- c(tab2_lines,
  sprintf("Lithuania $\\times$ Post-2016 & %.3f & %.3f%s & %.3f & & \\\\",
          coef(m1_simple)["treat"],
          coef(m1_baltic)["treat"],
          ifelse(pvalue(m1_baltic)["treat"] < 0.05, "**",
                 ifelse(pvalue(m1_baltic)["treat"] < 0.1, "*", "")),
          coef(m_logvat)["treat"]),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & & \\\\",
          se(m1_simple)["treat"],
          se(m1_baltic)["treat"],
          se(m_logvat)["treat"]),
  sprintf("LT $\\times$ Post $\\times$ B2B Intensity & & & & %.3f%s & %.3f%s \\\\",
          coef(m2_base)["treat_intensity"],
          ifelse(pvalue(m2_base)["treat_intensity"] < 0.05, "**",
                 ifelse(pvalue(m2_base)["treat_intensity"] < 0.1, "*", "")),
          coef(m2_full)["treat_intensity"],
          ifelse(pvalue(m2_full)["treat_intensity"] < 0.05, "**",
                 ifelse(pvalue(m2_full)["treat_intensity"] < 0.1, "*", ""))),
  sprintf(" & & & & (%.3f) & (%.3f) \\\\",
          se(m2_base)["treat_intensity"],
          se(m2_full)["treat_intensity"]),
  "\\hline",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1_simple), nobs(m1_baltic), nobs(m_logvat),
          nobs(m2_base), nobs(m2_full)),
  sprintf("Within $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1_simple, "wr2")[[1]], fitstat(m1_baltic, "wr2")[[1]], fitstat(m_logvat, "wr2")[[1]],
          fitstat(m2_base, "wr2")[[1]], fitstat(m2_full, "wr2")[[1]]),
  "Country FE & Yes & Yes & Yes & Yes & -- \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sector FE & -- & -- & -- & Yes & -- \\\\",
  "Sector $\\times$ Country FE & -- & -- & -- & -- & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. Columns (1)--(3): country-year panel (5 countries, 2010--2022). Column (1): VAT/GDP ratio, all controls. Column (2): VAT/GDP ratio, Baltic controls only (Latvia, Estonia). Column (3): log VAT revenue (EUR millions), all controls. Columns (4)--(5): sector-country-year panel (19 sectors, 5 countries, 2010--2022). B2B intensity is the sector's share of intermediate inputs from domestic firms, from Eurostat input-output tables (\\texttt{naio\\_10\\_cp1700}). $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(TABLE_DIR, "tab2_main.tex"))
cat("  Table 2 written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 3: VAT Gap Decline — Year-by-Year
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 3: VAT Gap\n")

vg_wide <- dcast(vg, year ~ geo, value.var = "vat_gap_pct")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{VAT Gap by Country, 2013--2022 (\\% of VTTL)}",
  "\\label{tab:vatgap}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Year & Lithuania & Latvia & Estonia & EU Average \\\\",
  "\\hline"
)

for (yr in 2013:2022) {
  row <- vg_wide[year == yr]
  marker <- ifelse(yr == 2017, " $\\leftarrow$ \\textit{i.SAF}", "")
  tab3_lines <- c(tab3_lines,
    sprintf("%d & %.1f & %.1f & %.1f & %.1f%s \\\\",
            yr,
            ifelse(length(row$LT) > 0, row$LT, NA),
            ifelse(length(row$LV) > 0, row$LV, NA),
            ifelse(length(row$EE) > 0, row$EE, NA),
            ifelse(length(row$EU27) > 0, row$EU27, NA),
            marker))
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  sprintf("Pre--2017 mean & %.1f & %.1f & %.1f & %.1f \\\\",
          vg[geo == "LT" & year <= 2016, mean(vat_gap_pct)],
          vg[geo == "LV" & year <= 2016, mean(vat_gap_pct)],
          vg[geo == "EE" & year <= 2016, mean(vat_gap_pct)],
          vg[geo == "EU27" & year <= 2016, mean(vat_gap_pct)]),
  sprintf("Post--2016 mean & %.1f & %.1f & %.1f & %.1f \\\\",
          vg[geo == "LT" & year >= 2017, mean(vat_gap_pct)],
          vg[geo == "LV" & year >= 2017, mean(vat_gap_pct)],
          vg[geo == "EE" & year >= 2017, mean(vat_gap_pct)],
          vg[geo == "EU27" & year >= 2017, mean(vat_gap_pct)]),
  sprintf("$\\Delta$ & $%.1f$ & $%.1f$ & $%.1f$ & $%.1f$ \\\\",
          vg[geo == "LT" & year >= 2017, mean(vat_gap_pct)] - vg[geo == "LT" & year <= 2016, mean(vat_gap_pct)],
          vg[geo == "LV" & year >= 2017, mean(vat_gap_pct)] - vg[geo == "LV" & year <= 2016, mean(vat_gap_pct)],
          vg[geo == "EE" & year >= 2017, mean(vat_gap_pct)] - vg[geo == "EE" & year <= 2016, mean(vat_gap_pct)],
          vg[geo == "EU27" & year >= 2017, mean(vat_gap_pct)] - vg[geo == "EU27" & year <= 2016, mean(vat_gap_pct)]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} VAT gap as a percentage of VAT Total Tax Liability (VTTL), from the European Commission/CASE VAT Gap Study Reports (2014--2023 editions). Lithuania's i.SAF mandatory invoice reporting became effective October 1, 2016. The arrow marks the first full post-treatment year.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(TABLE_DIR, "tab3_vatgap.tex"))
cat("  Table 3 written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE 4: Robustness and Placebo Tests
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table 4: Robustness\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Coefficient & SE & $p$-value & N \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Placebo treatment dates (pre-2016 only, sector panel)}} \\\\[3pt]"
)

for (i in seq_len(nrow(placebo_results))) {
  pr <- placebo_results[i]
  tab4_lines <- c(tab4_lines,
    sprintf("Fake treatment: %d & %.3f & %.3f & %.3f & %d \\\\",
            pr$fake_year, pr$coef, pr$se, pr$pval,
            nrow(sp[year <= 2016])))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel B: Leave-one-country-out (sector panel)}} \\\\[3pt]"
)

for (i in seq_len(nrow(loo_results))) {
  lr <- loo_results[i]
  cname <- c(EE = "Estonia", LV = "Latvia", PL = "Poland", FI = "Finland")[lr$dropped]
  tab4_lines <- c(tab4_lines,
    sprintf("Drop %s & %.3f & %.3f & %.3f & %d \\\\",
            cname, lr$coef, lr$se, lr$pval,
            nrow(sp[geo != lr$dropped])))
}

tab4_lines <- c(tab4_lines,
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel C: Sector-type placebo}} \\\\[3pt]",
  sprintf("VAT-exempt sectors & %.3f & %.3f & %.3f & %d \\\\",
          coef(feols(log_gva ~ treat_binary | nace_r2 + year + geo,
                      data = sp[nace_r2 %in% c("O-Q", "L", "K")],
                      cluster = ~geo))["treat_binary"],
          se(feols(log_gva ~ treat_binary | nace_r2 + year + geo,
                    data = sp[nace_r2 %in% c("O-Q", "L", "K")],
                    cluster = ~geo))["treat_binary"],
          pvalue(feols(log_gva ~ treat_binary | nace_r2 + year + geo,
                        data = sp[nace_r2 %in% c("O-Q", "L", "K")],
                        cluster = ~geo))["treat_binary"],
          nrow(sp[nace_r2 %in% c("O-Q", "L", "K")])),
  sprintf("VAT-liable sectors & %.3f & %.3f & %.3f & %d \\\\",
          coef(m_nonexempt)["treat_intensity"],
          se(m_nonexempt)["treat_intensity"],
          pvalue(m_nonexempt)["treat_intensity"],
          nrow(sp[!nace_r2 %in% c("O-Q", "L", "K")])),
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel D: Randomization inference (permute treated country)}} \\\\[3pt]",
  sprintf("Actual estimate & \\multicolumn{2}{c}{%.3f} & \\multicolumn{2}{c}{} \\\\", actual_coef),
  sprintf("RI $p$-value (2-sided) & \\multicolumn{2}{c}{} & \\multicolumn{2}{c}{%.3f} \\\\", ri_pvalue),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports coefficients from the sector-level continuous-treatment specification using only pre-2016 data with placebo treatment dates. Panel B drops one control country at a time from the sector-level specification. Panel C compares the treatment effect for VAT-exempt sectors (public administration, real estate, finance) against VAT-liable sectors. Panel D permutes the treated-country assignment across all five countries; with only five permutations, the RI $p$-value has limited power. All standard errors clustered at the country level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(TABLE_DIR, "tab4_robustness.tex"))
cat("  Table 4 written.\n")

# ═══════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ═══════════════════════════════════════════════════════════════════════

cat("Generating Table F1: SDE\n")

# Compute SDEs
# Primary outcome: VAT/GDP ratio (country-level)
sd_vat_gdp_pre <- cp[year < 2017 & geo == "LT", sd(vat_gdp)]
beta_country <- coef(m1_baltic)["treat"]
se_country <- se(m1_baltic)["treat"]
sde_country <- beta_country / sd_vat_gdp_pre
se_sde_country <- se_country / sd_vat_gdp_pre

# Secondary: log GVA (sector-level, continuous treatment)
# For continuous treatment, SDE = beta * SD(X) / SD(Y)
sd_treat_int <- sp[lithuania == 1 & year < 2017, sd(invoice_intensity)]
sd_loggva_pre <- sp[year < 2017, sd(log_gva)]
beta_sector <- coef(m2_base)["treat_intensity"]
se_sector <- se(m2_base)["treat_intensity"]
sde_sector <- beta_sector * sd_treat_int / sd_loggva_pre
se_sde_sector <- se_sector * sd_treat_int / sd_loggva_pre

# VAT gap (descriptive)
vat_gap_change_lt <- vg[geo == "LT" & year == 2022, vat_gap_pct] -
                     vg[geo == "LT" & year == 2015, vat_gap_pct]
sd_vat_gap_pre <- vg[geo %in% c("LT", "LV", "EE") & year <= 2016, sd(vat_gap_pct)]
sde_vatgap <- did_vat_gap / sd_vat_gap_pre
se_sde_vatgap <- NA  # Descriptive, no SE

# Log GDP (placebo)
sd_loggdp_pre <- cp[year < 2017, sd(log(gdp_meur))]
beta_gdp <- coef(m_loggdp)["treat"]
se_gdp <- se(m_loggdp)["treat"]
sde_gdp <- beta_gdp / sd_loggdp_pre
se_sde_gdp <- se_gdp / sd_loggdp_pre

# Classification function
classify_sde <- function(s) {
  if (is.na(s)) return("--")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s < 0.005) return("Null")
  if (s < 0.05) return("Small positive")
  if (s < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows_a <- data.table(
  Outcome = c("VAT/GDP ratio", "VAT gap (DiD)", "Sector log GVA"),
  beta_hat = c(beta_country, did_vat_gap, beta_sector),
  SE = c(se_country, NA, se_sector),
  SD_Y = c(sd_vat_gdp_pre, sd_vat_gap_pre, sd_loggva_pre),
  SDE = c(sde_country, sde_vatgap, sde_sector),
  SE_SDE = c(se_sde_country, NA, se_sde_sector)
)
sde_rows_a[, Classification := sapply(SDE, classify_sde)]

# Panel B: Heterogeneous — high vs low B2B intensity
sp_high <- sp[invoice_intensity > median(invoice_intensity)]
sp_low <- sp[invoice_intensity <= median(invoice_intensity)]

m_high <- feols(log_gva ~ treat_binary | nace_r2 + year + geo,
                 data = sp_high, cluster = ~geo)
m_low <- feols(log_gva ~ treat_binary | nace_r2 + year + geo,
                data = sp_low, cluster = ~geo)

sd_high_pre <- sp_high[year < 2017, sd(log_gva)]
sd_low_pre <- sp_low[year < 2017, sd(log_gva)]

sde_high <- coef(m_high)["treat_binary"] / sd_high_pre
se_sde_high <- se(m_high)["treat_binary"] / sd_high_pre
sde_low <- coef(m_low)["treat_binary"] / sd_low_pre
se_sde_low <- se(m_low)["treat_binary"] / sd_low_pre

sde_rows_b <- data.table(
  Outcome = c("Sector GVA (high B2B)", "Sector GVA (low B2B)"),
  beta_hat = c(coef(m_high)["treat_binary"], coef(m_low)["treat_binary"]),
  SE = c(se(m_high)["treat_binary"], se(m_low)["treat_binary"]),
  SD_Y = c(sd_high_pre, sd_low_pre),
  SDE = c(sde_high, sde_low),
  SE_SDE = c(se_sde_high, se_sde_low)
)
sde_rows_b[, Classification := sapply(SDE, classify_sde)]

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Lithuania. ",
  "\\textbf{Research question:} Does mandatory real-time B2B invoice reporting (i.SAF) reduce the VAT compliance gap and increase reported sector output? ",
  "\\textbf{Policy mechanism:} The i.SAF system requires all VAT-registered firms to submit monthly XML ledgers of every issued and received invoice; the tax authority automatically cross-matches buyer-seller records and flags discrepancies for audit. ",
  "\\textbf{Outcome definition:} Panel A row 1: VAT revenue as a share of GDP (Eurostat gov\\_10a\\_taxag D211 / nama\\_10\\_gdp B1GQ); row 2: VAT gap as percentage of VAT Total Tax Liability (European Commission/CASE reports); row 3: log gross value added by NACE sector (Eurostat nama\\_10\\_a64 B1G). ",
  "\\textbf{Treatment:} Binary (Lithuania post-October 2016 vs. Baltic/Nordic controls); continuous treatment intensity in sector specifications equals sector-level B2B invoice share from Eurostat input-output tables. ",
  "\\textbf{Data:} Eurostat country-year and sector-country-year panels, 2010--2022, 5 countries (Lithuania, Latvia, Estonia, Finland, Poland), 19 NACE sectors, 1,235 sector-country-year observations. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with continuous treatment intensity; standard errors clustered at the country level; wild cluster bootstrap and randomization inference for few-cluster robustness. ",
  "\\textbf{Sample:} EU member states in the Baltic/Nordic region with comparable pre-treatment VAT gaps; sector panel restricted to NACE divisions with non-missing GVA across all five countries. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment; SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_rows_a))) {
  r <- sde_rows_a[i]
  se_str <- ifelse(is.na(r$SE), "--", sprintf("%.3f", r$SE))
  se_sde_str <- ifelse(is.na(r$SE_SDE), "--", sprintf("%.3f", r$SE_SDE))
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %s & %.3f & %.3f & %s & %s \\\\",
            r$Outcome, r$beta_hat, se_str, r$SD_Y, r$SDE, se_sde_str, r$Classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits by B2B intensity)}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_rows_b))) {
  r <- sde_rows_b[i]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            r$Outcome, r$beta_hat, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  Table F1 (SDE) written.\n")

# ═══════════════════════════════════════════════════════════════════════
# Verify all tables
# ═══════════════════════════════════════════════════════════════════════

cat("\n=== Tables generated ===\n")
for (f in list.files(TABLE_DIR, pattern = "\\.tex$")) {
  sz <- file.info(file.path(TABLE_DIR, f))$size
  cat(sprintf("  %s: %.1f KB\n", f, sz / 1024))
}
cat("Done.\n")
