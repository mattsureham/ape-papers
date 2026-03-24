## 05_tables.R — Generate all LaTeX tables
## apep_0866: Male-biased labor demand, sex ratios, and women's outcomes

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics\n")

make_sumrow <- function(df, sex_val, label) {
  d <- df |> filter(sex == sex_val)
  tibble(
    Sex = label,
    `Non-mining Emp` = sprintf("%.0f", mean(d$emp_nonmining, na.rm = TRUE)),
    `SD` = sprintf("(%.0f)", sd(d$emp_nonmining, na.rm = TRUE)),
    `Non-mining Earn` = sprintf("%.0f", mean(d$earnings_nonmining, na.rm = TRUE)),
    `SD Earn` = sprintf("(%.0f)", sd(d$earnings_nonmining, na.rm = TRUE)),
    `Mining Emp` = sprintf("%.0f", mean(d$emp_mining, na.rm = TRUE)),
    N = format(nrow(d), big.mark = ",")
  )
}

high <- panel |> filter(high_mining == TRUE)
low <- panel |> filter(has_mining == FALSE)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrrrrr}",
  "\\toprule",
  " & Non-mining & & Non-mining & & Mining & \\\\",
  " & Employment & (SD) & Earnings & (SD) & Employment & N \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: High-Mining Counties (Top Quartile)}} \\\\"
)

for (sx in c(1, 2)) {
  lbl <- ifelse(sx == 1, "Male", "Female")
  r <- make_sumrow(high, sx, lbl)
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                           r$Sex, r$`Non-mining Emp`, r$SD,
                           r$`Non-mining Earn`, r$`SD Earn`,
                           r$`Mining Emp`, r$N))
}

tab1 <- c(tab1, "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Non-Mining Counties}} \\\\")

for (sx in c(1, 2)) {
  lbl <- ifelse(sx == 1, "Male", "Female")
  r <- make_sumrow(low, sx, lbl)
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                           r$Sex, r$`Non-mining Emp`, r$SD,
                           r$`Non-mining Earn`, r$`SD Earn`,
                           r$`Mining Emp`, r$N))
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Employment is average Q4 count from QWI. ",
         "Earnings are average monthly in dollars. High-mining counties are top quartile ",
         "of pre-boom (2001--2005) mining employment share. Sample: 24 states, 2001--2022."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# =============================================================================
# TABLE 2: First Stage — Mining Employment by Sex
# =============================================================================
cat("Generating Table 2: First Stage\n")

etable(results$first_stage_male, results$first_stage_female,
       tex = TRUE,
       file = "../tables/tab2_first_stage.tex",
       replace = TRUE,
       title = "First Stage: Mining Employment Response by Sex",
       headers = c("Male Mining Emp (log)", "Female Mining Emp (log)"),
       label = "tab:first_stage",
       notes = "Dependent variable: log mining employment. Treatment is pre-boom (2001--2005) mining employment share (continuous). Boom = 2006--2014; Bust = 2015--2018. County and year FE. Standard errors clustered at state level.",
       depvar = FALSE,
       style.tex = style.tex("aer"))

# =============================================================================
# TABLE 3: Main Results — Triple-Difference
# =============================================================================
cat("Generating Table 3: Main Results\n")

etable(results$main_employment, results$main_earnings,
       results$continuous_employment, results$continuous_earnings,
       tex = TRUE,
       file = "../tables/tab3_main.tex",
       replace = TRUE,
       title = "The Gendered Effects of Male-Biased Labor Demand",
       headers = c("Emp (Binary)", "Earn (Binary)", "Emp (Cont.)", "Earn (Cont.)"),
       label = "tab:main",
       notes = "Dependent variables: log non-mining employment (cols 1,3) and log non-mining earnings (cols 2,4). Binary treatment: high-mining county (top quartile of pre-boom mining share). Continuous treatment: pre-boom mining share. All specifications include county and year FE. SEs clustered at state level.",
       depvar = FALSE,
       style.tex = style.tex("aer"))

# =============================================================================
# TABLE 4: Gender Earnings Gap
# =============================================================================
cat("Generating Table 4: Gender Gap\n")

etable(results$gender_gap,
       tex = TRUE,
       file = "../tables/tab4_gap.tex",
       replace = TRUE,
       title = "Gender Earnings Gap and Mining Intensity",
       headers = c("Gender Earnings Gap"),
       label = "tab:gap",
       notes = "Dependent variable: (male earnings - female earnings) / male earnings, computed from QWI at county-year level. Treatment is continuous pre-boom mining share. County and year FE. SEs clustered at state level.",
       depvar = FALSE,
       style.tex = style.tex("aer"))

# =============================================================================
# TABLE 5: Robustness — Placebo and Alternative Specifications
# =============================================================================
cat("Generating Table 5: Robustness\n")

etable(results$main_employment, rob_results$placebo_healthcare,
       rob_results$county_cluster, rob_results$construction,
       tex = TRUE,
       file = "../tables/tab5_robustness.tex",
       replace = TRUE,
       title = "Robustness: Placebo Industries and Alternative Clustering",
       headers = c("Main (Non-Mining)", "Placebo (Healthcare)", "County Clusters", "Construction"),
       label = "tab:robustness",
       notes = "Col 1 repeats the main specification. Col 2: healthcare (NAICS 62) as placebo -- female-dominated industry where demand is orthogonal to mining. Col 3: county-level clustering. Col 4: construction (NAICS 23) as a male-dominated comparison. SEs in parentheses.",
       depvar = FALSE,
       style.tex = style.tex("aer"))

# =============================================================================
# TABLE F1: SDE Appendix
# =============================================================================
cat("Generating Table F1: SDE\n")

# Extract coefficients for main triple-diff
coef_names <- names(coef(results$main_employment))
boom_idx <- grep("female.*high_mining.*boom", coef_names)
bust_idx <- grep("female.*high_mining.*bust", coef_names)

beta_emp_boom <- coef(results$main_employment)[boom_idx]
se_emp_boom <- sqrt(diag(vcov(results$main_employment)))[boom_idx]
beta_emp_bust <- coef(results$main_employment)[bust_idx]
se_emp_bust <- sqrt(diag(vcov(results$main_employment)))[bust_idx]

beta_earn_boom <- coef(results$main_earnings)[boom_idx]
se_earn_boom <- sqrt(diag(vcov(results$main_earnings)))[boom_idx]
beta_earn_bust <- coef(results$main_earnings)[bust_idx]
se_earn_bust <- sqrt(diag(vcov(results$main_earnings)))[bust_idx]

# SD(Y) pre-treatment
sd_emp <- sd(panel$log_emp_nonmining[panel$year < 2006 & panel$female == 1], na.rm = TRUE)
sd_earn <- sd(panel$log_earnings_nonmining[panel$year < 2006 & panel$female == 1], na.rm = TRUE)

# Gender gap
beta_gap <- coef(results$gender_gap)[1]
se_gap <- sqrt(diag(vcov(results$gender_gap)))[1]
sd_gap <- sd(panel$gender_earn_gap[panel$year < 2006 & panel$sex == 1], na.rm = TRUE)

classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows <- list(
  list("Female non-mining emp (boom)", beta_emp_boom, se_emp_boom, sd_emp),
  list("Female non-mining emp (bust)", beta_emp_bust, se_emp_bust, sd_emp),
  list("Female non-mining earn (boom)", beta_earn_boom, se_earn_boom, sd_earn),
  list("Gender earnings gap (boom)", beta_gap, se_gap, sd_gap)
)

# Panel B: Heterogeneous — urban vs rural
# Define urban from earliest ACS year (2009) to avoid NAs in pre-boom years
urban_class <- panel |>
  filter(!is.na(total_pop)) |>
  group_by(fips) |>
  summarise(pop_first = first(total_pop), .groups = "drop") |>
  mutate(urban = pop_first > median(pop_first, na.rm = TRUE))

panel <- panel |>
  left_join(urban_class |> select(fips, urban), by = "fips")

het_urban <- feols(log_emp_nonmining ~ female:high_mining:boom +
                     female:high_mining:bust +
                     female:boom + female:bust +
                     high_mining:boom + high_mining:bust |
                     fips + year,
                   data = panel |> filter(urban == TRUE),
                   cluster = ~state)

het_rural <- feols(log_emp_nonmining ~ female:high_mining:boom +
                     female:high_mining:bust +
                     female:boom + female:bust +
                     high_mining:boom + high_mining:bust |
                     fips + year,
                   data = panel |> filter(urban == FALSE),
                   cluster = ~state)

coef_urban <- coef(het_urban)[boom_idx]
se_urban <- sqrt(diag(vcov(het_urban)))[boom_idx]
coef_rural <- coef(het_rural)[boom_idx]
se_rural <- sqrt(diag(vcov(het_rural)))[boom_idx]

sd_urban <- sd(panel$log_emp_nonmining[panel$year < 2006 & panel$female == 1 & panel$urban == TRUE], na.rm = TRUE)
sd_rural <- sd(panel$log_emp_nonmining[panel$year < 2006 & panel$female == 1 & panel$urban == FALSE], na.rm = TRUE)

het_rows <- list(
  list("Female non-mining emp (urban)", coef_urban, se_urban, sd_urban),
  list("Female non-mining emp (rural)", coef_rural, se_rural, sd_rural)
)

# Count observations
n_treated_val <- n_distinct(panel$fips[panel$high_mining == TRUE])
n_obs_val <- nrow(panel)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does male-biased labor demand from the shale oil and gas boom reduce female non-mining employment and earnings in affected counties? ",
  "\\textbf{Policy mechanism:} The shale fracking revolution created massive mining employment that is approximately 14:1 male-to-female, generating a male-biased labor demand shock that distorted local labor markets through in-migration, cost-of-living increases, and industry composition shifts in affected counties. ",
  "\\textbf{Outcome definition:} Log average quarterly non-mining employment count for female workers from the Quarterly Workforce Indicators (QWI), and gender earnings gap computed as (male minus female non-mining earnings) divided by male earnings. ",
  "\\textbf{Treatment:} Binary indicator for counties in the top quartile of pre-boom (2001--2005) mining employment share. ",
  "\\textbf{Data:} QWI county-year-sex-industry panels from Census Bureau, 24 states, 2001--2022, ", format(n_obs_val, big.mark = ","), " county-year-sex observations covering ", n_treated_val, " treated counties. ",
  "\\textbf{Method:} Triple-difference (female $\\times$ high-mining $\\times$ boom period) with county and year fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} Counties in 24 states spanning major shale plays (Bakken, Permian, Eagle Ford, Marcellus) and comparison states; restricted to counties with non-missing QWI data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2001--2005) standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (r in sde_rows) {
  sde_val <- r[[2]] / r[[4]]
  se_sde <- r[[3]] / r[[4]]
  cls <- classify_sde(sde_val)
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r[[1]], r[[2]], r[[3]], r[[4]], sde_val, se_sde, cls
  ))
}

sde_lines <- c(sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Urban vs.\\ Rural)}} \\\\"
)

for (r in het_rows) {
  sde_val <- r[[2]] / r[[4]]
  se_sde <- r[[3]] / r[[4]]
  cls <- classify_sde(sde_val)
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    r[[1]], r[[2]], r[[3]], r[[4]], sde_val, se_sde, cls
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
