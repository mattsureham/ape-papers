# 05_tables.R — SDE table for apep_0661
# UK Asylum Dispersal and Local Crime

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, log_crime := log(crime_rate + 0.01)]
cat("Panel loaded:", nrow(panel), "obs\n")

# =============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# =============================================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Main OLS results (since IV has weak first stage, report OLS as primary)
ols_crime <- feols(crime_rate ~ dispersal_rate | csp_id + time_id,
                   cluster = ~csp_id, data = panel)
ols_violence <- feols(violence_rate ~ dispersal_rate | csp_id + time_id,
                      cluster = ~csp_id, data = panel)
ols_theft <- feols(theft_rate ~ dispersal_rate | csp_id + time_id,
                   cluster = ~csp_id, data = panel)
ols_drugs <- feols(drugs_rate ~ dispersal_rate | csp_id + time_id,
                   cluster = ~csp_id, data = panel)
ols_pubord <- feols(public_order_rate ~ dispersal_rate | csp_id + time_id,
                    cluster = ~csp_id, data = panel)

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_x <- sd(panel$dispersal_rate, na.rm = TRUE)

sde_table <- data.table(
  outcome = c("Total crime rate", "Violence rate", "Theft rate",
              "Drug offence rate", "Public order rate"),
  beta = c(coef(ols_crime)["dispersal_rate"],
           coef(ols_violence)["dispersal_rate"],
           coef(ols_theft)["dispersal_rate"],
           coef(ols_drugs)["dispersal_rate"],
           coef(ols_pubord)["dispersal_rate"]),
  se_beta = c(se(ols_crime)["dispersal_rate"],
              se(ols_violence)["dispersal_rate"],
              se(ols_theft)["dispersal_rate"],
              se(ols_drugs)["dispersal_rate"],
              se(ols_pubord)["dispersal_rate"]),
  sd_y = c(sd(panel$crime_rate, na.rm = TRUE),
           sd(panel$violence_rate, na.rm = TRUE),
           sd(panel$theft_rate, na.rm = TRUE),
           sd(panel$drugs_rate, na.rm = TRUE),
           sd(panel$public_order_rate, na.rm = TRUE))
)

sde_table[, sde := beta * sd_x / sd_y]
sde_table[, se_sde := se_beta * sd_x / sd_y]

# Classification
sde_table[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  default = "Large positive"
)]

cat("SDE results:\n")
print(sde_table)

# Generate LaTeX table
make_tex_row <- function(...) paste(c(...), collapse = " & ") |> paste0(" \\\\")

sde_rows <- character()
for (i in seq_len(nrow(sde_table))) {
  sde_rows <- c(sde_rows, make_tex_row(
    sde_table$outcome[i],
    sprintf("%.3f", sde_table$beta[i]),
    sprintf("(%.3f)", sde_table$se_beta[i]),
    sprintf("%.3f", sde_table$sd_y[i]),
    sprintf("%.4f", sde_table$sde[i]),
    sprintf("(%.4f)", sde_table$se_sde[i]),
    sde_table$classification[i]
  ))
}

tabF1 <- c(
  "\\begin{table}[t]", "\\centering",
  "\\caption{Standardized Effect Sizes}", "\\label{tab:sde}", "\\small",
  "\\begin{tabular}{lcccccc}", "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\", "\\hline",
  sde_rows,
  "\\hline\\hline", "\\end{tabular}",
  "\\begin{tablenotes}\\small",
  paste0("\\item \\textit{Notes:} SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, ",
         "where $X$ is dispersal rate (per 1,000 pop., SD=", sprintf("%.3f", sd_x), "). ",
         "Classification based on SDE magnitude: Large ($|$SDE$|>0.15$), ",
         "Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($<0.005$). ",
         "Classification refers to effect magnitude, not statistical significance. ",
         "Research question: Does asylum seeker dispersal causally affect local crime rates? ",
         "Method: two-way FE (CSP + quarter) OLS. ",
         "Data: Home Office asylum support by LA and Police Recorded Crime by CSP, 2016Q2--2024Q4, ",
         "England and Wales. N=", format(nrow(panel), big.mark = ","), ". ",
         "Treatment: continuous (dispersal rate per 1,000 population)."),
  "\\end{tablenotes}", "\\end{table}")
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) saved.\n")
