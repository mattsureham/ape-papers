## 05b_sector_table.R — Generate sector heterogeneity table

source("code/00_packages.R")

sector_res <- readRDS("data/sector_results.rds")
sr <- sector_res$sector_results

pstars <- function(p) {
  case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.1 ~ "*", TRUE ~ "")
}

fmt_coef <- function(b, s, p) paste0(sprintf("%.4f", b), pstars(p))
fmt_se   <- function(s) paste0("(", sprintf("%.4f", s), ")")

## Build table row by row
rows <- apply(sr, 1, function(r) {
  b <- as.numeric(r["beta"])
  s <- as.numeric(r["se"])
  p <- as.numeric(r["p"])
  lab <- r["label"]
  paste0(lab, " & ", fmt_coef(b, s, p), " & ", fmt_se(s), " \\\\\n")
})

## N obs per sector
bds_sp <- sector_res$bds_sector_panel
n_obs_51 <- nrow(bds_sp %>% filter(naics_sector=="51"))
n_obs_54 <- nrow(bds_sp %>% filter(naics_sector=="54"))
n_obs_23 <- nrow(bds_sp %>% filter(naics_sector=="23"))
n_obs_tot <- sum(n_obs_51, n_obs_54, n_obs_23)

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Sector Heterogeneity: Effect of Preemption by Industry (TWFE)}\n",
  "\\label{tab:sector}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\\small\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Sector & \\textit{Preempted} & SE \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Broadband-Intensive Sectors (Mechanism)}} \\\\\n",
  rows[1],
  rows[2],
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Non-Digital Sector (Placebo)}} \\\\\n",
  rows[3],
  "\\hline\n",
  "State FE, Year FE & \\checkmark & \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Notes:} Each row reports a separate TWFE regression of log firm birth rate on an indicator for preemption.}\\\\\n",
  "\\multicolumn{3}{l}{SEs clustered at state level. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.}\\\\\n",
  "\\multicolumn{3}{l}{N = ", n_obs_51, " (NAICS 51), ",
  n_obs_54, " (NAICS 54), ", n_obs_23, " (NAICS 23). Data: Census BDS 2004--2023.}\\\\\n",
  "\\hline\n",
  "\\end{tabular}\\end{adjustbox}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, "tables/tab5_sector.tex")
cat("Table 5 (sector heterogeneity) written.\n")
