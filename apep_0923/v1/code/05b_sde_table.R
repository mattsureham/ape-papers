## 05b_sde_table.R — Generate SDE table with eventually-treated spec
source("00_packages.R")
panel <- fread("../data/analysis_panel.csv")
et_panel <- panel[wave > 0]

m_et <- feols(log_deposits ~ aeoi_active | country_id + time_id,
              data = et_panel, cluster = ~cp_country)
sd_y <- sd(panel$log_deposits, na.rm = TRUE)
beta <- coef(m_et)["aeoi_active"]
se_b <- se(m_et)["aeoi_active"]
sde <- beta / sd_y
se_sde <- se_b / sd_y

# Wave 1 vs later waves
m_w1 <- feols(log_deposits ~ aeoi_active | country_id + time_id,
              data = et_panel[wave == 1 | wave >= 3], cluster = ~cp_country)
m_late <- feols(log_deposits ~ aeoi_active | country_id + time_id,
                data = et_panel[wave >= 2], cluster = ~cp_country)

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland (reporting country); counterparty countries worldwide. ",
  "\\textbf{Research question:} Does the adoption of automatic tax information exchange (AEOI/CRS) between Switzerland and partner countries affect bilateral cross-border bank liabilities? ",
  "\\textbf{Policy mechanism:} AEOI requires Swiss banks to automatically report account balances, interest, dividends, and other financial income of foreign account holders to the tax authority of the account holder's country of residence, eliminating the possibility of holding undeclared offshore wealth. ",
  "\\textbf{Outcome definition:} Natural log of quarterly bilateral Swiss bank cross-border liabilities to each counterparty country, measured in millions of US dollars, from BIS Locational Banking Statistics. ",
  "\\textbf{Treatment:} Binary; equals one from the quarter that Switzerland's bilateral AEOI agreement with the counterparty country entered into force. ",
  "\\textbf{Data:} BIS Locational Banking Statistics, quarterly, 2010Q1--2023Q4, country-quarter panel, 4,088 observations across 73 eventually-treated counterparty countries. ",
  "\\textbf{Method:} Two-way fixed effects (country and quarter), standard errors clustered by counterparty country; eventually-treated countries only (preferred specification). ",
  "\\textbf{Sample:} Countries that activated AEOI with Switzerland between 2017 and 2020; never-treated countries excluded to avoid compositional bias. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log liabilities. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (eventually-treated only)}} \\\\",
  sprintf("Log liabilities & TWFE & %s & %s & %s & %s & %s \\\\",
          fmt(beta), fmt(sd_y), fmt(sde), fmt(se_sde), classify(sde)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Wave 1 vs.\\\\ Waves 2--4)}} \\\\",
  sprintf("Log liabilities & Wave 1 + late ctrl & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m_w1)["aeoi_active"]), fmt(sd_y),
          fmt(coef(m_w1)["aeoi_active"] / sd_y), fmt(se(m_w1)["aeoi_active"] / sd_y),
          classify(coef(m_w1)["aeoi_active"] / sd_y)),
  sprintf("Log liabilities & Waves 2--4 only & %s & %s & %s & %s & %s \\\\",
          fmt(coef(m_late)["aeoi_active"]), fmt(sd_y),
          fmt(coef(m_late)["aeoi_active"] / sd_y), fmt(se(m_late)["aeoi_active"] / sd_y),
          classify(coef(m_late)["aeoi_active"] / sd_y)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")
cat("Pooled SDE:", round(sde, 4), "->", classify(sde), "\n")
