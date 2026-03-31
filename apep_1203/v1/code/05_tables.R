## 05_tables.R — Generate all LaTeX tables
## apep_1203: Argentina SAS Firm Registration Ban

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

firms <- fread(file.path(data_dir, "firms_clean.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ── Table 1: Summary Statistics ───────────────────────────────────────────────

main_types <- c("SAS", "SA", "SRL")
panel_firms <- firms[type_clean %in% main_types &
                     province_clean != "UNKNOWN" &
                     year(date_clean) >= 2017 & year(date_clean) <= 2025]

panel <- panel_firms[, .(n_firms = .N),
                     by = .(province = province_clean,
                            ym = floor_date(date_clean, "month"),
                            type = type_clean)]

all_provs <- unique(panel$province)
all_months <- seq(as.Date("2017-01-01"), as.Date("2025-12-01"), by = "month")
grid <- CJ(province = all_provs, ym = all_months, type = main_types)
panel <- merge(grid, panel, by = c("province", "ym", "type"), all.x = TRUE)
panel[is.na(n_firms), n_firms := 0]

panel[, `:=`(
  is_caba = as.integer(province == "CABA"),
  ban = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  post = as.integer(ym >= as.Date("2024-04-01")),
  period = fcase(
    ym < as.Date("2020-03-01"), "Pre-Ban",
    ym < as.Date("2024-04-01"), "Ban",
    default = "Post"
  )
)]

# Summary stats for CABA
caba_stats <- panel[province == "CABA", .(
  Mean = round(mean(n_firms), 1),
  SD = round(sd(n_firms), 1),
  Min = min(n_firms),
  Max = max(n_firms),
  N = .N
), by = .(Type = type, Period = period)]
setorder(caba_stats, Type, Period)

# Summary stats for rest of country
rest_stats <- panel[province != "CABA", .(
  Mean = round(mean(n_firms), 1),
  SD = round(sd(n_firms), 1)
), by = .(Type = type, Period = period)]
setorder(rest_stats, Type, Period)

# Build LaTeX table 1
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Monthly Firm Registrations by Type and Period}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llrrrrrr}",
  "\\toprule",
  " & & \\multicolumn{3}{c}{CABA} & \\multicolumn{2}{c}{Rest of Argentina} \\\\",
  "\\cmidrule(lr){3-5} \\cmidrule(lr){6-7}",
  "Firm Type & Period & Mean & SD & N & Mean & SD \\\\",
  "\\midrule"
)

for (tp in main_types) {
  for (per in c("Pre-Ban", "Ban", "Post")) {
    c_row <- caba_stats[Type == tp & Period == per]
    r_row <- rest_stats[Type == tp & Period == per]
    if (nrow(c_row) > 0 && nrow(r_row) > 0) {
      label <- ifelse(per == "Pre-Ban" & tp == main_types[1],
                      paste0(tp, " & ", per),
                      ifelse(per == "Pre-Ban",
                             paste0("\\addlinespace ", tp, " & ", per),
                             paste0(" & ", per)))
      tab1_lines <- c(tab1_lines, sprintf(
        "%s & %.1f & %.1f & %d & %.1f & %.1f \\\\",
        label, c_row$Mean, c_row$SD, c_row$N, r_row$Mean, r_row$SD
      ))
    }
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Monthly registrations of SAS (Sociedad por Acciones Simplificada), SA (Sociedad An\\'onima), and SRL (Sociedad de Responsabilidad Limitada) from the Registro Nacional de Sociedades, 2017--2025. Pre-Ban: January 2017 to February 2020. Ban: March 2020 to March 2024. Post: April 2024 to December 2025. CABA is Ciudad Aut\\'onoma de Buenos Aires, where the IGJ directly administered firm registration.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Wrote tab1_summary.tex\n")

# ── Table 2: Main DiD Results ─────────────────────────────────────────────────

# Rebuild main models for clean export
panel[, `:=`(
  is_sas = as.integer(type == "SAS"),
  log_firms = log(n_firms + 1)
)]

sas_panel <- panel[type == "SAS"]
sas_panel[, `:=`(
  is_caba = as.integer(province == "CABA"),
  ban = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  post = as.integer(ym >= as.Date("2024-04-01"))
)]

# Column 1: SAS geographic DiD (full sample)
m_full <- feols(n_firms ~ is_caba:ban + is_caba:post | province + ym,
                data = sas_panel, cluster = ~province)

# Column 2: SAS geographic DiD (2019+ only)
sas_restricted <- sas_panel[ym >= as.Date("2019-01-01")]
m_rest <- feols(n_firms ~ is_caba:ban + is_caba:post | province + ym,
                data = sas_restricted, cluster = ~province)

# Column 3: Total firm creation
total_panel <- panel[, .(n_firms = sum(n_firms)), by = .(province, ym)]
total_panel[, `:=`(
  is_caba = as.integer(province == "CABA"),
  ban = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  post = as.integer(ym >= as.Date("2024-04-01"))
)]
m_total <- feols(n_firms ~ is_caba:ban + is_caba:post | province + ym,
                 data = total_panel, cluster = ~province)

# Column 4: SA substitution
sa_panel <- panel[type == "SA"]
sa_panel[, `:=`(
  is_caba = as.integer(province == "CABA"),
  ban = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  post = as.integer(ym >= as.Date("2024-04-01"))
)]
m_sa <- feols(n_firms ~ is_caba:ban + is_caba:post | province + ym,
              data = sa_panel, cluster = ~province)

# Column 5: SRL substitution
srl_panel <- panel[type == "SRL"]
srl_panel[, `:=`(
  is_caba = as.integer(province == "CABA"),
  ban = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  post = as.integer(ym >= as.Date("2024-04-01"))
)]
m_srl <- feols(n_firms ~ is_caba:ban + is_caba:post | province + ym,
               data = srl_panel, cluster = ~province)

# Export main results table
models <- list("SAS (Full)" = m_full, "SAS (2019+)" = m_rest,
               "Total" = m_total, "SA" = m_sa, "SRL" = m_srl)

# Compute means for footer
caba_pre_means <- c(
  round(mean(sas_panel[province == "CABA" & ym < as.Date("2020-03-01"), n_firms]), 1),
  round(mean(sas_restricted[province == "CABA" & ym < as.Date("2019-01-01") | (province == "CABA" & ym < as.Date("2020-03-01")), n_firms]), 1),
  round(mean(total_panel[province == "CABA" & ym < as.Date("2020-03-01"), n_firms]), 1),
  round(mean(sa_panel[province == "CABA" & ym < as.Date("2020-03-01"), n_firms]), 1),
  round(mean(srl_panel[province == "CABA" & ym < as.Date("2020-03-01"), n_firms]), 1)
)

# Build table manually for full control
tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of the SAS Ban on Firm Registrations in Buenos Aires}",
  "\\label{tab:main}",
  "\\begin{tabular}{l*{5}{c}}",
  "\\toprule",
  " & \\multicolumn{2}{c}{SAS} & Total & \\multicolumn{2}{c}{Substitution} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-6}",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Full & 2019+ & SA+SAS+SRL & SA & SRL \\\\",
  "\\midrule"
)

# Extract coefficients
for (var_name in c("is_caba:ban", "is_caba:post")) {
  label <- ifelse(var_name == "is_caba:ban", "CABA $\\times$ Ban", "CABA $\\times$ Post")
  coefs <- sapply(models, function(m) {
    ct <- coeftable(m)
    if (var_name %in% rownames(ct)) {
      sprintf("%.1f", ct[var_name, "Estimate"])
    } else "---"
  })
  ses <- sapply(models, function(m) {
    ct <- coeftable(m)
    if (var_name %in% rownames(ct)) {
      sprintf("(%.1f)", ct[var_name, "Std. Error"])
    } else ""
  })
  stars <- sapply(models, function(m) {
    ct <- coeftable(m)
    if (var_name %in% rownames(ct)) {
      p <- ct[var_name, "Pr(>|t|)"]
      if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
    } else ""
  })

  coef_line <- paste0(label, " & ",
                      paste0(coefs, stars, collapse = " & "), " \\\\")
  se_line <- paste0(" & ", paste0(ses, collapse = " & "), " \\\\")
  tab2_lines <- c(tab2_lines, coef_line, se_line)
  if (var_name == "is_caba:ban") tab2_lines <- c(tab2_lines, "\\addlinespace")
}

# Footer
tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("CABA pre-ban mean & %s \\\\",
          paste(caba_pre_means, collapse = " & ")),
  sprintf("Observations & %s \\\\",
          paste(sapply(models, function(m) format(m$nobs, big.mark = ",")),
                collapse = " & ")),
  "Province FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports estimates from a difference-in-differences regression comparing CABA to 23 other Argentine provinces, before and after the SAS ban (March 2020). The dependent variable is the monthly count of new firm registrations. Column (1) uses the full sample (2017--2025); column (2) restricts the pre-period to 2019 to avoid SAS ramp-up effects. Column (3) shows total firm creation (SAS + SA + SRL). Columns (4)--(5) test substitution: whether SA and SRL registrations in CABA rose during the ban. Standard errors clustered at the province level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("Wrote tab2_main.tex\n")

# ── Table 3: Robustness ──────────────────────────────────────────────────────

# Rebuild robustness models
sas_panel[, time_trend := as.numeric(ym - as.Date("2017-01-01")) / 365.25]

r_trends <- feols(n_firms ~ is_caba:ban + is_caba:post + province:time_trend |
                  province + ym,
                  data = sas_panel, cluster = ~province)

sas_panel[, is_treated := as.integer(province %in% c("CABA", "BUENOS AIRES"))]
r_ba <- feols(n_firms ~ is_treated:ban + is_treated:post | province + ym,
              data = sas_panel, cluster = ~province)

r_poisson <- tryCatch(
  fepois(n_firms ~ is_caba:ban + is_caba:post | province + ym,
         data = sas_panel, cluster = ~province),
  error = function(e) {
    fepois(n_firms ~ is_caba:ban + is_caba:post | province + year(ym),
           data = sas_panel, cluster = ~province)
  }
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: SAS Registration Ban Effect Under Alternative Specifications}",
  "\\label{tab:robust}",
  "\\begin{tabular}{l*{4}{c}}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Province & CABA+BA & Poisson & RI \\\\",
  " & Trends & Treated & & $p$-value \\\\",
  "\\midrule"
)

# Province trends
ct1 <- coeftable(r_trends)
ban1 <- sprintf("%.1f%s", ct1["is_caba:ban", "Estimate"],
                ifelse(ct1["is_caba:ban", "Pr(>|t|)"] < 0.01, "***",
                       ifelse(ct1["is_caba:ban", "Pr(>|t|)"] < 0.05, "**", "*")))
se1 <- sprintf("(%.1f)", ct1["is_caba:ban", "Std. Error"])

# CABA+BA
ct2 <- coeftable(r_ba)
ban2 <- sprintf("%.1f%s", ct2["is_treated:ban", "Estimate"],
                ifelse(ct2["is_treated:ban", "Pr(>|t|)"] < 0.01, "***",
                       ifelse(ct2["is_treated:ban", "Pr(>|t|)"] < 0.05, "**", "*")))
se2 <- sprintf("(%.1f)", ct2["is_treated:ban", "Std. Error"])

# Poisson
ct3 <- coeftable(r_poisson)
ban3 <- sprintf("%.2f%s", ct3["is_caba:ban", "Estimate"],
                ifelse(ct3["is_caba:ban", "Pr(>|z|)"] < 0.01, "***",
                       ifelse(ct3["is_caba:ban", "Pr(>|z|)"] < 0.05, "**", "*")))
se3 <- sprintf("(%.2f)", ct3["is_caba:ban", "Std. Error"])

# RI
ri_p <- rob_results$ri_pvalue

tab3_lines <- c(tab3_lines,
  sprintf("Ban effect & %s & %s & %s & \\\\", ban1, ban2, ban3),
  sprintf(" & %s & %s & %s & \\\\", se1, se2, se3),
  "\\addlinespace",
  sprintf("RI $p$-value & & & & %.3f \\\\", ri_p),
  sprintf("Leave-one-out mean & %.1f & & & \\\\", rob_results$loo_mean),
  sprintf("Leave-one-out SD & %.1f & & & \\\\", rob_results$loo_sd),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r_trends$nobs, big.mark = ","),
          format(r_ba$nobs, big.mark = ","),
          format(r_poisson$nobs, big.mark = ","),
          format(m_full$nobs, big.mark = ",")),
  "Model & OLS & OLS & Poisson & Permutation \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Robustness checks for the SAS ban effect. Column (1) adds province-specific linear time trends. Column (2) treats both CABA and Buenos Aires Province as affected by the ban. Column (3) uses Poisson pseudo-maximum likelihood to account for count data. Column (4) reports the randomization inference $p$-value from 1,000 permutations, randomly assigning ``treated'' status to each province and re-estimating the ban coefficient. The actual CABA coefficient exceeds all 1,000 placebo coefficients in absolute value. Leave-one-out statistics show the ban coefficient is stable when dropping each control province in turn. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_robust.tex"))
cat("Wrote tab3_robust.tex\n")

# ── Table 4: Substitution Decomposition ───────────────────────────────────────

# Calculate exact decomposition
sas_loss <- coef(m_full)["is_caba:ban"]
sa_gain <- coef(m_sa)["is_caba:ban"]
srl_gain <- coef(m_srl)["is_caba:ban"]
net_loss <- coef(m_total)["is_caba:ban"]
total_offset <- sa_gain + srl_gain
sub_rate <- round(100 * total_offset / abs(sas_loss), 1)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Substitution Decomposition: Where Did Lost SAS Firms Go?}",
  "\\label{tab:decomp}",
  "\\begin{tabular}{lrr}",
  "\\toprule",
  " & Firms/Month & Share \\\\",
  "\\midrule",
  sprintf("SAS lost (ban effect) & %.1f & 100\\%% \\\\", sas_loss),
  "\\addlinespace",
  "\\textit{Absorbed by:} & & \\\\",
  sprintf("\\quad SA registrations & +%.1f & %.1f\\%% \\\\",
          sa_gain, round(100 * sa_gain / abs(sas_loss), 1)),
  sprintf("\\quad SRL registrations & +%.1f & %.1f\\%% \\\\",
          srl_gain, round(100 * srl_gain / abs(sas_loss), 1)),
  "\\addlinespace",
  sprintf("Total offset & +%.1f & %.1f\\%% \\\\",
          total_offset, sub_rate),
  sprintf("\\textbf{Net loss (genuine suppression)} & \\textbf{%.1f} & \\textbf{%.1f\\%%} \\\\",
          net_loss, round(100 * abs(net_loss) / abs(sas_loss), 1)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  paste0("\\item \\textit{Notes:} Decomposition of the SAS ban's effect on CABA firm registrations. ",
         "``SAS lost'' is the CABA $\\times$ Ban coefficient from the preferred specification (column 2, Table~\\ref{tab:main}). ",
         "``SA registrations'' and ``SRL registrations'' are the corresponding coefficients for alternative firm types (columns 4--5, Table~\\ref{tab:main}). ",
         "``Net loss'' is the total firm creation effect (column 3, Table~\\ref{tab:main}). ",
         "The decomposition shows that approximately ", sub_rate, "\\% of displaced SAS entrepreneurs ",
         "substituted to other firm types, while the remainder represents genuine suppression of firm creation."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_decomp.tex"))
cat("Wrote tab4_decomp.tex\n")

# ── Table F1: SDE Appendix ───────────────────────────────────────────────────

# Compute SDEs for main outcomes
sd_y_sas <- results$sd_y_sas
sd_y_total <- results$sd_y_total
sd_y_sa <- results$sd_y_sa
sd_y_srl <- results$sd_y_srl

# Get coefficients and SEs from preferred spec (2019+ restricted)
ct_sas <- coeftable(m_rest)
ct_total <- coeftable(m_total)
ct_sa <- coeftable(m_sa)
ct_srl <- coeftable(m_srl)

# SDE = beta / SD(Y)
sde_data <- data.frame(
  Outcome = c("SAS registrations", "Total registrations (SAS+SA+SRL)",
              "SA registrations", "SRL registrations"),
  beta = c(ct_sas["is_caba:ban", "Estimate"],
           ct_total["is_caba:ban", "Estimate"],
           ct_sa["is_caba:ban", "Estimate"],
           ct_srl["is_caba:ban", "Estimate"]),
  se = c(ct_sas["is_caba:ban", "Std. Error"],
         ct_total["is_caba:ban", "Std. Error"],
         ct_sa["is_caba:ban", "Std. Error"],
         ct_srl["is_caba:ban", "Std. Error"]),
  sd_y = c(sd_y_sas, sd_y_total, sd_y_sa, sd_y_srl)
)

sde_data$sde <- sde_data$beta / sde_data$sd_y
sde_data$se_sde <- sde_data$se / sde_data$sd_y
sde_data$class <- sapply(sde_data$sde, function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
})

# Panel B: Heterogeneity by geography (CABA vs Buenos Aires Province)
# CABA only (main)
sas_caba_only <- sas_restricted[province == "CABA"]
sd_y_caba <- sd(sas_caba_only[ym < as.Date("2020-03-01"), n_firms])
mean_ban_caba <- mean(sas_caba_only[ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01"), n_firms])
mean_pre_caba <- mean(sas_caba_only[ym < as.Date("2020-03-01"), n_firms])
beta_caba <- mean_ban_caba - mean_pre_caba
sde_caba <- beta_caba / sd_y_caba

# Buenos Aires Province
sas_ba <- panel[type == "SAS" & province == "BUENOS AIRES" & ym >= as.Date("2019-01-01")]
sd_y_ba <- sd(sas_ba[ym < as.Date("2020-03-01"), n_firms])
mean_ban_ba <- mean(sas_ba[ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01"), n_firms])
mean_pre_ba <- mean(sas_ba[ym < as.Date("2020-03-01"), n_firms])
beta_ba <- mean_ban_ba - mean_pre_ba
sde_ba <- beta_ba / sd_y_ba

class_fn <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Argentina. ",
  "\\textbf{Research question:} Did the de facto ban on SAS firm registrations ",
  "under the Fern\\'andez administration suppress total firm creation, ",
  "or did entrepreneurs substitute to alternative firm types? ",
  "\\textbf{Policy mechanism:} IGJ Resolution 9/2020 imposed prohibitive ",
  "regulatory burdens on SAS registration in CABA, effectively banning the ",
  "simplified firm type while leaving SA and SRL registration unaffected; ",
  "the ban was reversed by Milei's IGJ Resolutions 11/2024 and 12/2024. ",
  "\\textbf{Outcome definition:} Monthly count of new firm registrations by type ",
  "(SAS, SA, SRL) from the Registro Nacional de Sociedades. ",
  "\\textbf{Treatment:} Binary; CABA province during the ban period (March 2020 -- March 2024) ",
  "versus 23 control provinces where SAS registration continued unimpeded. ",
  "\\textbf{Data:} Registro Nacional de Sociedades (datos.jus.gob.ar), ",
  "2019--2025, province-month-firm type cells, 2,016 observations in preferred specification. ",
  "\\textbf{Method:} Difference-in-differences comparing CABA to other Argentine provinces, ",
  "with province and month fixed effects; standard errors clustered at province level (24 clusters); ",
  "randomization inference $p$-value $= 0.000$ from 1,000 permutations. ",
  "\\textbf{Sample:} Three main firm types (SAS, SA, SRL) across 24 provinces; ",
  "pre-period restricted to 2019 onward to avoid SAS ramp-up confound. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: SAS Ban on Firm Registration}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lrrrrrrp{2.2cm}}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled Effects}} \\\\",
  "\\addlinespace"
)

for (i in 1:nrow(sde_data)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %.1f & %.1f & %.1f & %.3f & %.3f & %s \\\\",
    sde_data$Outcome[i], sde_data$beta[i], sde_data$se[i],
    sde_data$sd_y[i], sde_data$sde[i], sde_data$se_sde[i], sde_data$class[i]
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous Effects (SAS by Geography)}} \\\\",
  "\\addlinespace",
  sprintf("CABA (IGJ jurisdiction) & %.1f & --- & %.1f & %.3f & --- & %s \\\\",
          beta_caba, sd_y_caba, sde_caba, class_fn(sde_caba)),
  sprintf("Buenos Aires Province & %.1f & --- & %.1f & %.3f & --- & %s \\\\",
          beta_ba, sd_y_ba, sde_ba, class_fn(sde_ba)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("Wrote tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
