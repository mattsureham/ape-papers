## =============================================================================
## 06_tables.R — Generate all LaTeX tables
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

load(file.path(data_dir, "main_models.RData"))

## ---------------------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------------------

cat("=== Table 1: Summary Statistics ===\n")

rtep <- fread(file.path(data_dir, "rtep_clean.csv"))
wfp <- fread(file.path(data_dir, "wfp_clean.csv"))

# Panel A: RTEP petrol prices
sumA <- rtep[, .(
  Variable = c("PMS price (\\naira/L)", "Log PMS price", "Distance to terminal (km)",
                "Post-reform indicator"),
  N = format(c(.N, .N, .N, .N), big.mark = ","),
  Mean = round(c(mean(o_fuel_petrol_gasoline), mean(log_petrol),
                  mean(dist_nearest), mean(post)), 2),
  SD = round(c(sd(o_fuel_petrol_gasoline), sd(log_petrol),
                sd(dist_nearest), sd(post)), 2),
  Min = round(c(min(o_fuel_petrol_gasoline), min(log_petrol),
                 min(dist_nearest), min(post)), 2),
  Max = round(c(max(o_fuel_petrol_gasoline), max(log_petrol),
                 max(dist_nearest), max(post)), 2)
)]

# Panel B: WFP food prices
wfp_food <- wfp[!grepl("Fuel|Petrol|Diesel|Kerosene", commodity, ignore.case = TRUE)]
sumB <- wfp_food[!is.na(dist_nearest), .(
  Variable = c("Food price (\\naira)", "Log food price", "Distance to terminal (km)"),
  N = format(c(.N, .N, .N), big.mark = ","),
  Mean = round(c(mean(price), mean(log_price), mean(dist_nearest)), 2),
  SD = round(c(sd(price), sd(log_price), sd(dist_nearest)), 2),
  Min = round(c(min(price), min(log_price), min(dist_nearest)), 2),
  Max = round(c(max(price), max(log_price), max(dist_nearest)), 2)
)]

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & N & Mean & SD & Min & Max \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Petrol Prices (RTEP, market $\\times$ month)}} \\\\[3pt]"
)

for (i in 1:nrow(sumA)) {
  tab1_lines <- c(tab1_lines, paste0(
    sumA$Variable[i], " & ", sumA$N[i], " & ", sumA$Mean[i], " & ",
    sumA$SD[i], " & ", sumA$Min[i], " & ", sumA$Max[i], " \\\\"
  ))
}

tab1_lines <- c(tab1_lines,
  "\\\\",
  "\\multicolumn{6}{l}{\\textit{Panel B: Food Prices (WFP, market $\\times$ commodity $\\times$ month)}} \\\\[3pt]"
)

for (i in 1:nrow(sumB)) {
  tab1_lines <- c(tab1_lines, paste0(
    sumB$Variable[i], " & ", sumB$N[i], " & ", sumB$Mean[i], " & ",
    sumB$SD[i], " & ", sumB$Min[i], " & ", sumB$Max[i], " \\\\"
  ))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\small\\textit{Notes:} Panel A reports statistics for market-level monthly petrol (PMS) prices from the World Bank Real Time Energy Prices dataset. Panel B reports statistics for retail food commodity prices from the WFP Food Price Monitoring dataset. Distance is the Haversine distance from each market to the nearest of three major petroleum import terminals (Lagos/Apapa, Port Harcourt, Warri). The analysis window is January 2021 to December 2024.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tab_dir, "tab1_sumstats.tex"))

## ---------------------------------------------------------------------------
## Table 2: Main Results — Petrol Price Pass-Through
## ---------------------------------------------------------------------------

cat("=== Table 2: Main Results ===\n")

tab2 <- etable(m_a1, m_a2, m_a3, m_a4,
               dict = c(dist_post_100 = "Post $\\times$ Distance (100km)",
                        trust_petrol = "Trust Score"),
               style.tex = style.tex("aer"),
               fitstat = c("n", "r2", "ar2"),
               se.below = TRUE,
               tex = TRUE,
               file = file.path(tab_dir, "tab2_main.tex"),
               title = "Petrol Price Pass-Through: The Effect of Distance from Import Terminals",
               label = "tab:main",
               notes = c(
                 "Dependent variable: log of observed PMS price (\\naira/litre).",
                 "Column 1: OLS with main effects (Post, Distance level) and no fixed effects.",
                 "Column 2: Market and month fixed effects. Column 3: Adds state-by-year interaction fixed effects.",
                 "Column 4: Controls for RTEP model trust score.",
                 "Standard errors clustered at the state level in parentheses.",
                 "* p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01."
               ),
               replace = TRUE)

## ---------------------------------------------------------------------------
## Table 3: Food Price Pass-Through
## ---------------------------------------------------------------------------

cat("=== Table 3: Food Prices ===\n")

tab3 <- etable(m_b1, m_b2, m_b3, m_b4_cereals, m_b4_protein, m_b4_roots,
               dict = c(dist_post_100 = "Post $\\times$ Distance (100km)"),
               style.tex = style.tex("aer"),
               fitstat = c("n", "r2"),
               se.below = TRUE,
               tex = TRUE,
               headers = c("All Food", "Transport-Int.", "Non-Transport", "Cereals", "Protein", "Roots/Tubers"),
               file = file.path(tab_dir, "tab3_food.tex"),
               title = "Food Price Pass-Through by Transport Intensity and Commodity Group",
               label = "tab:food",
               notes = c(
                 "Dependent variable: log retail food price.",
                 "Columns 1--3 partition all food commodities: Transport-intensive (cereals, roots/tubers, legumes) vs.\\ Non-transport (processed goods, protein, other).",
                 "Columns 4--6 isolate subgroups: Cereals $\\subset$ Transport-Int.; Protein $\\subset$ Non-Transport; Roots/Tubers $\\subset$ Transport-Int.",
                 "All specifications include market-commodity and month fixed effects. Standard errors clustered at the state level.",
                 "* p $<$ 0.10, ** p $<$ 0.05, *** p $<$ 0.01."
               ),
               replace = TRUE)

## ---------------------------------------------------------------------------
## Table 4: Robustness — Bandwidth Sensitivity
## ---------------------------------------------------------------------------

cat("=== Table 4: Robustness ===\n")

bw_dt <- fread(file.path(data_dir, "robustness_bandwidth.csv"))
ri_result <- fread(file.path(data_dir, "robustness_ri.csv"))

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Bandwidth Sensitivity}",
  "\\label{tab:robustness_bw}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Window (months) & Estimate & SE & N \\\\",
  "\\hline"
)

for (i in 1:nrow(bw_dt)) {
  if (bw_dt$bandwidth_months[i] >= 99) {
    bw_label <- "Full sample"
  } else {
    bw_label <- paste0("$\\pm$", bw_dt$bandwidth_months[i])
  }
  tab4_lines <- c(tab4_lines, paste0(
    bw_label, " & ",
    round(bw_dt$estimate[i], 4), " & (",
    round(bw_dt$se[i], 4), ") & ",
    format(bw_dt$n[i], big.mark = ","), " \\\\"
  ))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.7\\textwidth}",
  "\\small\\textit{Notes:} Each row estimates the main specification (market and month FE, state-clustered SE) using a symmetric window centered on June 2023. ``Full sample'' uses all 3,072 observations (Jan 2021--Dec 2024). Standard errors in parentheses.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tab_dir, "tab4_robustness.tex"))

## ---------------------------------------------------------------------------
## Table F1: Standardized Effect Sizes (Appendix F)
## ---------------------------------------------------------------------------

cat("=== Table F1: Standardized Effect Sizes ===\n")

# Panel A: Petrol prices (continuous treatment)
sde_petrol <- panel_a_coef * panel_a_sd_x / panel_a_sd_y
se_sde_petrol <- panel_a_se * panel_a_sd_x / panel_a_sd_y

# Panel B: Food prices
sde_food <- panel_b_coef * panel_b_sd_x / panel_b_sd_y
se_sde_food <- panel_b_se * panel_b_sd_x / panel_b_sd_y

classify_sde <- function(x) {
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x < 0.005) return("Null")
  if (x < 0.05) return("Small positive")
  if (x < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_table <- data.table(
  Outcome = c("Log PMS price", "Log food price (all)"),
  Specification = c("Table 2, Col. 2", "Table 3, Col. 1"),
  beta = round(c(panel_a_coef, panel_b_coef), 4),
  SD_X = round(c(panel_a_sd_x, panel_b_sd_x), 2),
  SD_Y = round(c(panel_a_sd_y, panel_b_sd_y), 4),
  SDE = round(c(sde_petrol, sde_food), 4),
  SE_SDE = round(c(se_sde_petrol, se_sde_food), 4),
  Classification = c(classify_sde(sde_petrol), classify_sde(sde_food))
)

# Write LaTeX
tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccccc}",
  "\\hline\\hline",
  "Outcome & Specification & $\\hat{\\beta}$ & SD(X) & SD(Y) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(sde_table)) {
  tabF1_lines <- c(tabF1_lines, paste0(
    sde_table$Outcome[i], " & ", sde_table$Specification[i], " & ",
    sde_table$beta[i], " & ", sde_table$SD_X[i], " & ",
    sde_table$SD_Y[i], " & ", sde_table$SDE[i], " & ",
    sde_table$SE_SDE[i], " & ", sde_table$Classification[i], " \\\\"
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\small\\textit{Notes:} This table reports standardized effect sizes (SDE) for each main outcome. The treatment variable is continuous (distance from market to nearest petroleum import terminal, in 100km units), so SDE $= \\hat{\\beta} \\times$ SD(X) / SD(Y), representing the effect of a one-standard-deviation increase in distance on the outcome in standard deviation units. SE(SDE) $=$ SE($\\hat{\\beta}$) $\\times$ SD(X) / SD(Y). SD(X) and SD(Y) are unconditional standard deviations from the summary statistics. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. The research question is: does the 2023 removal of Nigeria's petrol subsidy produce heterogeneous price pass-through across markets as a function of distance from petroleum import terminals? Data: World Bank RTEP (Panel A) and WFP Food Prices (Panel B), January 2021--December 2024, at market $\\times$ month level.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tab_dir, "tabF1_sde.tex"))

## ---------------------------------------------------------------------------
## Save SDE data for verification
## ---------------------------------------------------------------------------

fwrite(sde_table, file.path(data_dir, "sde_table.csv"))

cat("\n=== All tables generated ===\n")
