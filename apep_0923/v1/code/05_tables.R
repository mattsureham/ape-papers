## 05_tables.R — Generate all LaTeX tables
## APEP-0923: The End of Banking Secrecy

source("00_packages.R")

objs <- readRDS("../data/model_objects.rds")
rob <- readRDS("../data/robustness_objects.rds")
panel <- objs$panel

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("=== Generating Table 1: Summary Statistics ===\n")

make_row <- function(var_name, x) {
  data.table(Variable = var_name, N = sum(!is.na(x)),
             Mean = mean(x, na.rm = TRUE), SD = sd(x, na.rm = TRUE),
             Min = min(x, na.rm = TRUE), Max = max(x, na.rm = TRUE))
}

all_sum <- rbind(
  make_row("Deposits (USD mn)", panel$deposits_usd_mn),
  make_row("Log deposits", panel$log_deposits),
  make_row("Deposit share", panel$deposit_share),
  make_row("AEOI active", panel$aeoi_active)
)

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrr}",
  "\\toprule",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (i in 1:nrow(all_sum)) {
  row <- all_sum[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s \\\\",
    row$Variable,
    formatC(row$N, format = "d", big.mark = ","),
    formatC(row$Mean, format = "f", digits = 2, big.mark = ","),
    formatC(row$SD, format = "f", digits = 2, big.mark = ","),
    formatC(row$Min, format = "f", digits = 2, big.mark = ","),
    formatC(row$Max, format = "f", digits = 2, big.mark = ",")
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s country-quarter observations across %d counterparty countries and %d quarters (2010--2023). Deposits are Swiss bank cross-border liabilities to each counterparty country in millions of US dollars, from BIS Locational Banking Statistics. AEOI active equals one from the quarter that Switzerland's Automatic Exchange of Information agreement with the counterparty country entered into force.",
          formatC(nrow(panel), big.mark = ","),
          uniqueN(panel$cp_country),
          uniqueN(panel$time_id)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 saved.\n")

# ---------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------
cat("=== Generating Table 2: Main Results ===\n")

# Extract CS-DiD aggregate
cs_att <- if (!is.null(objs$cs_result)) {
  cs_agg <- aggte(objs$cs_result, type = "simple")
  list(att = cs_agg$overall.att, se = cs_agg$overall.se)
} else {
  list(att = NA, se = NA)
}

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of AEOI Activation on Swiss Bank Bilateral Liabilities}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) \\\\",
  "& Log deposits & Deposits (USD mn) & Deposit share & CS-DiD \\\\",
  "\\midrule",
  sprintf("AEOI active & %s%s & %s%s & %s%s & %s%s \\\\",
          fmt(coef(objs$m1)["aeoi_active"]),
          stars(pvalue(objs$m1)["aeoi_active"]),
          fmt(coef(objs$m2)["aeoi_active"], 1),
          stars(pvalue(objs$m2)["aeoi_active"]),
          fmt(coef(objs$m3)["aeoi_active"], 4),
          stars(pvalue(objs$m3)["aeoi_active"]),
          fmt(cs_att$att),
          ifelse(!is.na(cs_att$att) && abs(cs_att$att / cs_att$se) > 2.576, "***",
                 ifelse(!is.na(cs_att$att) && abs(cs_att$att / cs_att$se) > 1.96, "**",
                        ifelse(!is.na(cs_att$att) && abs(cs_att$att / cs_att$se) > 1.645, "*", "")))),
  sprintf("& (%s) & (%s) & (%s) & (%s) \\\\",
          fmt(se(objs$m1)["aeoi_active"]),
          fmt(se(objs$m2)["aeoi_active"], 1),
          fmt(se(objs$m3)["aeoi_active"], 4),
          fmt(cs_att$se)),
  "\\\\",
  sprintf("Country FE & Yes & Yes & Yes & --- \\\\"),
  sprintf("Quarter FE & Yes & Yes & Yes & --- \\\\"),
  sprintf("Estimator & TWFE & TWFE & TWFE & CS (2021) \\\\"),
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(objs$m1), big.mark = ","),
          formatC(nobs(objs$m2), big.mark = ","),
          formatC(nobs(objs$m3), big.mark = ","),
          formatC(nobs(objs$m1), big.mark = ",")),
  sprintf("Countries & %d & %d & %d & %d \\\\",
          uniqueN(panel$cp_country),
          uniqueN(panel$cp_country),
          uniqueN(panel$cp_country),
          uniqueN(panel$cp_country)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered by counterparty country in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Column (4) reports the Callaway and Sant'Anna (2021) aggregate ATT with bootstrap standard errors (1,000 iterations). The outcome in column (1) is the natural log of bilateral Swiss bank liabilities (in USD millions) to each counterparty country. The sample spans 2010Q1--2023Q4.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 saved.\n")

# ---------------------------------------------------------------
# Table 3: Heterogeneity
# ---------------------------------------------------------------
cat("=== Generating Table 3: Heterogeneity ===\n")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneous Effects of AEOI by Counterparty Characteristics}",
  "\\label{tab:hetero}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "& (1) & (2) & (3) \\\\",
  "& Tax haven & EU member & Large depositor \\\\",
  "\\midrule"
)

# Tax haven
ct_haven <- coeftable(objs$m_haven)
tab3_lines <- c(tab3_lines,
  sprintf("AEOI active & %s%s & %s%s & %s%s \\\\",
          fmt(ct_haven["aeoi_active", 1]),
          stars(ct_haven["aeoi_active", 4]),
          fmt(coeftable(objs$m_eu)["aeoi_active", 1]),
          stars(coeftable(objs$m_eu)["aeoi_active", 4]),
          fmt(coeftable(objs$m_size)["aeoi_active", 1]),
          stars(coeftable(objs$m_size)["aeoi_active", 4])),
  sprintf("& (%s) & (%s) & (%s) \\\\",
          fmt(ct_haven["aeoi_active", 2]),
          fmt(coeftable(objs$m_eu)["aeoi_active", 2]),
          fmt(coeftable(objs$m_size)["aeoi_active", 2])),
  sprintf("AEOI $\\times$ Subgroup & %s%s & %s%s & %s%s \\\\",
          fmt(ct_haven["aeoi_active:tax_haven", 1]),
          stars(ct_haven["aeoi_active:tax_haven", 4]),
          fmt(coeftable(objs$m_eu)["aeoi_active:eu_member", 1]),
          stars(coeftable(objs$m_eu)["aeoi_active:eu_member", 4]),
          fmt(coeftable(objs$m_size)["aeoi_active:large_depositor", 1]),
          stars(coeftable(objs$m_size)["aeoi_active:large_depositor", 4])),
  sprintf("& (%s) & (%s) & (%s) \\\\",
          fmt(ct_haven["aeoi_active:tax_haven", 2]),
          fmt(coeftable(objs$m_eu)["aeoi_active:eu_member", 2]),
          fmt(coeftable(objs$m_size)["aeoi_active:large_depositor", 2])),
  "\\\\",
  sprintf("Country FE & Yes & Yes & Yes \\\\"),
  sprintf("Quarter FE & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %s & %s & %s \\\\",
          formatC(nobs(objs$m_haven), big.mark = ","),
          formatC(nobs(objs$m_eu), big.mark = ","),
          formatC(nobs(objs$m_size), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered by counterparty country in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Tax haven defined using common classification (Luxembourg, Liechtenstein, Guernsey, Jersey, Isle of Man, Panama, Singapore, Hong Kong, UAE, etc.). EU member indicates European Union membership. Large depositor indicates above-median pre-AEOI bilateral deposits (2014--2016 average). Column (3) restricts to AEOI-treated countries only.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_heterogeneity.tex")
cat("Table 3 saved.\n")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("=== Generating Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Coefficient & SE \\\\",
  "\\midrule",
  sprintf("Baseline (TWFE, log deposits) & %s%s & (%s) \\\\",
          fmt(coef(objs$m1)["aeoi_active"]),
          stars(pvalue(objs$m1)["aeoi_active"]),
          fmt(se(objs$m1)["aeoi_active"])),
  sprintf("Placebo (2 years early) & %s & (%s) \\\\",
          fmt(coef(rob$m_placebo)),
          fmt(se(rob$m_placebo))),
  sprintf("Pre-COVID (2010--2019) & %s%s & (%s) \\\\",
          fmt(coef(rob$m_precovid)),
          stars(pvalue(rob$m_precovid)),
          fmt(se(rob$m_precovid))),
  sprintf("Asinh(deposits) & %s%s & (%s) \\\\",
          fmt(coef(rob$m_asinh)),
          stars(pvalue(rob$m_asinh)),
          fmt(se(rob$m_asinh))),
  sprintf("Deposit growth rate & %s%s & (%s) \\\\",
          fmt(coef(rob$m_growth)),
          stars(pvalue(rob$m_growth)),
          fmt(se(rob$m_growth))),
  sprintf("Double clustering (country + time) & %s%s & (%s) \\\\",
          fmt(coef(rob$m_double)),
          stars(pvalue(rob$m_double)),
          fmt(se(rob$m_double)))
)

# Add leave-one-cohort-out
tab4_lines <- c(tab4_lines, "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Leave-one-cohort-out}} \\\\")
for (i in 1:nrow(rob$loco_dt)) {
  w <- rob$loco_dt[i]
  tab4_lines <- c(tab4_lines, sprintf(
    "\\quad Drop Wave %d (%d) & %s & (%s) \\\\",
    w$dropped_wave, 2016 + w$dropped_wave,
    fmt(w$coef), fmt(w$se)
  ))
}

# Wild bootstrap
if (!is.null(rob$wcb_result)) {
  tab4_lines <- c(tab4_lines, "\\midrule",
    sprintf("Wild cluster bootstrap $p$-value & \\multicolumn{2}{c}{%s} \\\\",
            fmt(rob$wcb_result$p_val)),
    sprintf("Wild cluster bootstrap 95\\%% CI & \\multicolumn{2}{c}{[%s, %s]} \\\\",
            fmt(rob$wcb_result$conf_int[1]),
            fmt(rob$wcb_result$conf_int[2])))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include country and quarter fixed effects. Standard errors clustered by counterparty country unless otherwise noted. The placebo specification assigns fake AEOI activation dates two years before actual activation and restricts to the pre-actual-treatment period. Wild cluster bootstrap uses the Webb (2023) six-point distribution with 999 iterations.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("Table 4 saved.\n")

# ---------------------------------------------------------------
# Table 5: Wave-Specific Effects
# ---------------------------------------------------------------
cat("=== Generating Table 5: Wave-Specific ===\n")

m_waves <- rob$m_waves
ct_waves <- coeftable(m_waves)

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Wave-Specific Treatment Effects}",
  "\\label{tab:waves}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Treatment wave & Coefficient & SE \\\\",
  "\\midrule",
  sprintf("Wave 1 (2017, EU + OECD, $N = 37$) & %s%s & (%s) \\\\",
          fmt(ct_waves["aeoi_w1", 1]),
          stars(ct_waves["aeoi_w1", 4]),
          fmt(ct_waves["aeoi_w1", 2])),
  sprintf("Wave 2 (2018, emerging, $N = 22$) & %s%s & (%s) \\\\",
          fmt(ct_waves["aeoi_w2", 1]),
          stars(ct_waves["aeoi_w2", 4]),
          fmt(ct_waves["aeoi_w2", 2])),
  sprintf("Wave 3 (2019, Africa/Asia, $N = 10$) & %s%s & (%s) \\\\",
          fmt(ct_waves["aeoi_w3", 1]),
          stars(ct_waves["aeoi_w3", 4]),
          fmt(ct_waves["aeoi_w3", 2])),
  sprintf("Wave 4 (2020, late adopters, $N = 4$) & %s%s & (%s) \\\\",
          fmt(ct_waves["aeoi_w4", 1]),
          stars(ct_waves["aeoi_w4", 4]),
          fmt(ct_waves["aeoi_w4", 2])),
  "\\\\",
  sprintf("Country FE & \\multicolumn{2}{c}{Yes} \\\\"),
  sprintf("Quarter FE & \\multicolumn{2}{c}{Yes} \\\\"),
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nobs(m_waves), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered by counterparty country in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Each wave indicator equals one from the quarter that the corresponding bilateral AEOI agreement entered into force. $N$ denotes the number of counterparty countries in each wave. The omitted category is never-treated countries.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_waves.tex")
cat("Table 5 saved.\n")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE)
# ---------------------------------------------------------------
cat("=== Generating SDE Table ===\n")

# Pooled SDE
beta_pooled <- coef(objs$m1)["aeoi_active"]
se_pooled <- se(objs$m1)["aeoi_active"]
sd_y <- sd(panel$log_deposits, na.rm = TRUE)

sde_pooled <- beta_pooled / sd_y
se_sde_pooled <- se_pooled / sd_y

# Heterogeneous SDEs — EU vs non-EU sample splits (include never-treated as controls)
panel_eu <- panel[eu_member == 1 | wave == 0]
panel_noneu <- panel[eu_member == 0]

m_eu_split <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                    data = panel_eu, cluster = ~cp_country)
m_noneu_split <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                       data = panel_noneu, cluster = ~cp_country)

sde_eu <- coef(m_eu_split)["aeoi_active"] / sd_y
se_sde_eu <- se(m_eu_split)["aeoi_active"] / sd_y
sde_noneu <- coef(m_noneu_split)["aeoi_active"] / sd_y
se_sde_noneu <- se(m_noneu_split)["aeoi_active"] / sd_y

# Classification function
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

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland (reporting country); counterparty countries worldwide. ",
  "\\textbf{Research question:} Does the adoption of automatic tax information exchange (AEOI/CRS) between Switzerland and partner countries affect bilateral cross-border bank deposits? ",
  "\\textbf{Policy mechanism:} AEOI requires Swiss banks to automatically report account balances, interest, dividends, and other financial income of foreign account holders to the tax authority of the account holder's country of residence, eliminating the possibility of holding undeclared offshore wealth. ",
  "\\textbf{Outcome definition:} Natural log of quarterly bilateral Swiss bank cross-border liabilities to each counterparty country, measured in millions of US dollars, from BIS Locational Banking Statistics. ",
  "\\textbf{Treatment:} Binary; equals one from the quarter that Switzerland's bilateral AEOI agreement with the counterparty country entered into force. ",
  "\\textbf{Data:} BIS Locational Banking Statistics, quarterly, 2010Q1--2023Q4, country-quarter panel, ",
  formatC(nrow(panel), big.mark = ","), " observations across ", uniqueN(panel$cp_country), " counterparty countries. ",
  "\\textbf{Method:} Two-way fixed effects (country and quarter), standard errors clustered by counterparty country. ",
  "\\textbf{Sample:} Countries with at least 20 observed quarters in the BIS data; aggregates and unallocated categories excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log deposits. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log deposits & TWFE & %s & %s & %s & %s & %s \\\\",
          fmt(beta_pooled), fmt(sd_y), fmt(sde_pooled), fmt(se_sde_pooled),
          classify(sde_pooled)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (EU vs.\\ non-EU)}} \\\\",
  sprintf("Log deposits & EU members & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m_eu_split)["aeoi_active"]), fmt(sd_y),
          fmt(sde_eu), fmt(se_sde_eu), classify(sde_eu)),
  sprintf("Log deposits & Non-EU & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m_noneu_split)["aeoi_active"]), fmt(sd_y),
          fmt(sde_noneu), fmt(se_sde_noneu), classify(sde_noneu)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("SDE table saved.\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(list.files("../tables/"), collapse = "\n"), "\n")
