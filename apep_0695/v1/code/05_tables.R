# 05_tables.R — Generate all tables including SDE
# apep_0695: Dominican Republic TC/0168 Denationalization

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
results <- readRDS(file.path(data_dir, "all_results.rds"))
provinces <- readRDS(file.path(data_dir, "province_treatment.rds"))
national <- readRDS(file.path(data_dir, "national_panel.rds"))

its <- results$its
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

nat_clean <- national %>% filter(year >= 2005, year <= 2023)

# Build sumstats
vars <- list(
  list("Vulnerable employment (\\%)", nat_clean$vuln_employment),
  list("Self-employment (\\%)", nat_clean$self_employment),
  list("Wage workers (\\%)", nat_clean$wage_workers),
  list("Unemployment rate (\\%)", nat_clean$unemployment_rate),
  list("Labor force participation (\\%)", nat_clean$lfp_rate),
  list("Youth unemployment 15--24 (\\%)", nat_clean$youth_unemp_rate),
  list("Secondary enrollment (\\%)", nat_clean$school_secondary),
  list("GDP per capita (2015 USD)", nat_clean$gdp_per_capita)
)

sumrows <- sapply(vars, function(v) {
  x <- na.omit(v[[2]])
  paste(v[[1]], "&", length(x), "&", fmt(mean(x)), "&", fmt(sd(x)),
        "&", fmt(min(x)), "&", fmt(max(x)), "\\\\")
})

# Province stats
prov_rows <- c(
  paste("Haitian-born share &", nrow(provinces), "&",
        fmt(mean(provinces$haitian_share), 3), "&",
        fmt(sd(provinces$haitian_share), 3), "&",
        fmt(min(provinces$haitian_share), 3), "&",
        fmt(max(provinces$haitian_share), 3), "\\\\"),
  paste("Border province (indicator) &", nrow(provinces), "&",
        fmt(mean(provinces$border), 2), "&",
        fmt(sd(provinces$border), 2), "&", "0.00 & 1.00 \\\\")
)

tab1_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n\\toprule\n",
  "Variable & N & Mean & SD & Min & Max \\\\\n\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: National Labor Market Indicators (2005--2023)}} \\\\\n",
  paste(sumrows, collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Province-Level Treatment Intensity (2010 Census)}} \\\\\n",
  paste(prov_rows, collapse = "\n"), "\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Panel A reports annual national indicators from the ILO SDMX API ",
  "and World Bank WDI API. Vulnerable employment includes own-account and contributing family ",
  "workers (ILO definition). Panel B reports province-level treatment variables from the ",
  "Dominican Republic 2010 Census (ONE). Haitian-born share is the fraction of province ",
  "population born in Haiti. Border provinces: Dajab\\'{o}n, Monte Cristi, El\\'{i}as Pi\\~{n}a, ",
  "Independencia, and Pedernales.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:summary}\n\\end{table}\n"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main ITS Results
# ============================================================================
cat("Generating Table 2: ITS Results...\n")

tab2_models <- list(
  "(1)" = its$vuln,
  "(2)" = its$self,
  "(3)" = its$wage,
  "(4)" = its$unemp,
  "(5)" = its$lfp,
  "(6)" = its$school
)

modelsummary(
  tab2_models,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "post_2013" = "Post TC/0168",
    "trend" = "Linear trend",
    "I(trend * post_2013)" = "Post $\\times$ Trend"
  ),
  gof_map = c("nobs", "r.squared"),
  output = file.path(tables_dir, "tab2_its.tex"),
  title = "Interrupted Time Series: National Labor Market Outcomes Around TC/0168",
  notes = list(
    "Newey-West standard errors in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
    "Dependent variables: (1) Vulnerable employment share, (2) Self-employment share,",
    "(3) Wage worker share, (4) Unemployment rate, (5) LFP rate, (6) Secondary enrollment.",
    "Post TC/0168 = 1 for 2014--2023; trend centered at 2013. Data: ILO and World Bank, 2005--2023."
  ),
  escape = FALSE
)

# ============================================================================
# Table 3: Gender, Youth, and Sector Heterogeneity
# ============================================================================
cat("Generating Table 3: Heterogeneity...\n")

tab3_models <- list(
  "(1)" = results$its_lfp_m,
  "(2)" = results$its_lfp_f,
  "(3)" = results$its_youth,
  "(4)" = results$its_agri,
  "(5)" = results$its_serv
)

modelsummary(
  tab3_models,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "post_2013" = "Post TC/0168",
    "trend" = "Linear trend",
    "I(trend * post_2013)" = "Post $\\times$ Trend"
  ),
  gof_map = c("nobs", "r.squared"),
  output = file.path(tables_dir, "tab3_heterogeneity.tex"),
  title = "Heterogeneity: Gender, Youth, and Sector Composition",
  notes = list(
    "Newey-West standard errors in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
    "Outcomes: (1) Male LFP, (2) Female LFP, (3) Youth unemployment 15--24,",
    "(4) Agricultural employment share, (5) Services employment share.",
    "Data: ILO SDMX API, 2005--2023."
  ),
  escape = FALSE
)

# ============================================================================
# Table 4: Two-Shock Design + Placebo
# ============================================================================
cat("Generating Table 4: Two-Shock and Placebo...\n")

tab4_models <- list(
  "(1)" = results$two_shock_vuln,
  "(2)" = results$two_shock_self,
  "(3)" = results$placebo_vuln,
  "(4)" = results$placebo_self
)

modelsummary(
  tab4_models,
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "post_2010" = "Post 2010 Amendment",
    "post_2013" = "Post TC/0168 (2013)",
    "trend" = "Linear trend",
    "fake_post" = "Post Placebo (2008)",
    "fake_trend" = "Placebo trend",
    "fake_int" = "Placebo Post $\\times$ Trend"
  ),
  gof_map = c("nobs", "r.squared"),
  add_rows = tibble(
    term = "Sample",
    `(1)` = "Full", `(2)` = "Full",
    `(3)` = "Pre-2014", `(4)` = "Pre-2014"
  ),
  output = file.path(tables_dir, "tab4_twoshock_placebo.tex"),
  title = "Two-Shock Design and Placebo Tests",
  notes = list(
    "Newey-West standard errors in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
    "Columns (1)--(2): Two-shock design separating 2010 amendment from 2013 TC/0168.",
    "Columns (3)--(4): Placebo test with fake treatment at 2008, estimated on pre-period only.",
    "Dependent variables: (1,3) Vulnerable employment, (2,4) Self-employment."
  ),
  escape = FALSE
)

# ============================================================================
# Table 5: Province Treatment Intensity (Descriptive)
# ============================================================================
cat("Generating Table 5: Province Treatment Intensity...\n")

# Show top and bottom provinces by Haitian-born share
top_prov <- provinces %>%
  arrange(desc(haitian_share)) %>%
  head(10) %>%
  mutate(
    pop_fmt = formatC(total_pop_2010, format = "d", big.mark = ","),
    haitian_fmt = formatC(haitian_born_2010, format = "d", big.mark = ","),
    share_fmt = fmt(haitian_share * 100, 1),
    border_str = ifelse(border, "Yes", "No")
  )

bot_prov <- provinces %>%
  arrange(haitian_share) %>%
  head(5) %>%
  mutate(
    pop_fmt = formatC(total_pop_2010, format = "d", big.mark = ","),
    haitian_fmt = formatC(haitian_born_2010, format = "d", big.mark = ","),
    share_fmt = fmt(haitian_share * 100, 1),
    border_str = ifelse(border, "Yes", "No")
  )

show_prov <- bind_rows(top_prov, bot_prov)
prov_rows <- apply(show_prov, 1, function(r) {
  paste(r["province"], "&", r["pop_fmt"], "&", r["haitian_fmt"],
        "&", r["share_fmt"], "&", r["border_str"], "\\\\")
})

tab5_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Province-Level Treatment Intensity: Haitian-Born Population Shares}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrl}\n\\toprule\n",
  "Province & Total Pop. & Haitian-Born & Share (\\%) & Border \\\\\n\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Highest Exposure (Top 10)}} \\\\\n",
  paste(prov_rows[1:10], collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Lowest Exposure (Bottom 5)}} \\\\\n",
  paste(prov_rows[11:15], collapse = "\n"), "\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Population counts from the Dominican Republic 2010 Census (ONE). ",
  "Haitian-born share measures the fraction of province residents born in Haiti. ",
  "Border provinces share a land border with Haiti. ",
  "The five border provinces and sugar/agricultural centers (San Pedro de Macor\\'{i}s, ",
  "La Romana, La Altagracia) have the highest concentrations of Haitian-descent populations ",
  "and thus the greatest exposure to TC/0168.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:provinces}\n\\end{table}\n"
)
writeLines(tab5_tex, file.path(tables_dir, "tab5_provinces.tex"))

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("Generating SDE Table...\n")

nat_data <- national %>% filter(year >= 2005, year <= 2023)

# Classification function
classify_sde <- function(s) {
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

# Extract from ITS models (binary treatment: pre/post)
make_sde_row <- function(model, outcome_name, outcome_vec) {
  b <- coef(model)["post_2013"]
  s <- se(model)["post_2013"]
  sd_y <- sd(outcome_vec, na.rm = TRUE)
  sde <- b / sd_y
  se_sde <- s / sd_y
  tibble(
    Outcome = outcome_name,
    beta = b, se_beta = s, sd_x = "---",
    sd_y = sd_y, sde = sde, se_sde = se_sde,
    classification = classify_sde(sde)
  )
}

sde_table <- bind_rows(
  make_sde_row(its$vuln, "Vulnerable employment", nat_data$vuln_employment),
  make_sde_row(its$self, "Self-employment", nat_data$self_employment),
  make_sde_row(its$wage, "Wage workers", nat_data$wage_workers),
  make_sde_row(its$unemp, "Unemployment rate", nat_data$unemployment_rate),
  make_sde_row(its$lfp, "Labor force participation", nat_data$lfp_rate),
  make_sde_row(its$school, "Secondary enrollment", nat_data$school_secondary)
)

sde_body <- sde_table %>%
  mutate(row = paste(Outcome, "&", fmt(beta, 3), "&", fmt(se_beta, 3),
                     "&", sd_x, "&", fmt(sd_y, 3), "&", fmt(sde, 3),
                     "&", fmt(se_sde, 3), "&", classification, "\\\\")) %>%
  pull(row)

sde_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  paste(sde_body, collapse = "\n"), "\n",
  "\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) ",
  "to facilitate cross-study comparison of treatment effect magnitudes. ",
  "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) ",
  "column is marked ``---''. ",
  "SD($Y$) is the unconditional standard deviation from the full sample (Table~\\ref{tab:summary}).\n\n",
  "\\textbf{Country:} Dominican Republic.\n",
  "\\textbf{Research question:} Whether mass denationalization of Haitian-descent Dominicans ",
  "via the 2013 TC/0168 constitutional court ruling produced detectable changes in national ",
  "labor market aggregates including informality, unemployment, labor force participation, ",
  "and school enrollment.\n",
  "\\textbf{Policy mechanism:} The ruling retroactively stripped citizenship from an estimated ",
  "210,000 Dominican-born persons of Haitian descent by reinterpreting the ``in transit'' clause to 1929, ",
  "barring affected individuals from formal employment, public education, electoral participation, ",
  "and health services. Affected individuals constituted approximately 2\\% of the total population.\n",
  "\\textbf{Outcome definition:} Vulnerable employment is the ILO/World Bank share of total ",
  "employment classified as own-account or contributing family workers; self-employment is the ",
  "share working for own account; wage workers is the share in salaried employment; unemployment ",
  "and LFP are standard ILO definitions for the 15+ population; secondary enrollment is the net ",
  "enrollment ratio.\n",
  "\\textbf{Treatment:} Binary (pre/post September 2013 ruling). Post defined as 2014--2023.\n",
  "\\textbf{Data:} ILO SDMX API and World Bank WDI API, 2005--2023. 19 annual observations per indicator.\n",
  "\\textbf{Method:} Interrupted time series with linear trend and trend break, Newey-West standard errors.\n",
  "\\textbf{Sample:} National-level annual indicators for the Dominican Republic, 2005--2023.\n\n",
  "Classification thresholds (7 categories): ",
  "large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), ",
  "small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), ",
  "small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), ",
  "large positive ($> 0.15$). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
