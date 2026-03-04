## 06_tables.R — Generate all LaTeX tables
## apep_0499: Action Cœur de Ville and Property Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# ==============================================================
# 1. Load data
# ==============================================================
panel <- readRDS(file.path(data_dir, "commune_year_panel.rds"))
dvf_res <- readRDS(file.path(data_dir, "dvf_residential_clean.rds"))

panel <- panel %>%
  mutate(
    post = year >= 2018,
    treat_post = treated & post,
    rel_year = year - 2018,
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4,
      rel_year >= 6 ~ 6,
      TRUE ~ rel_year
    )
  )

# ==============================================================
# 2. Table 1: Summary Statistics
# ==============================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment period statistics by group
pre_panel <- panel %>% filter(year < 2018)

tab1_data <- pre_panel %>%
  mutate(Group = if_else(treated, "ACV", "Control")) %>%
  group_by(Group) %>%
  summarise(
    `N Communes` = n_distinct(commune),
    `N Commune-Years` = n(),
    `Mean Price/m² (€)` = sprintf("%.0f", mean(mean_price_m2, na.rm = TRUE)),
    `SD Price/m²` = sprintf("%.0f", sd(mean_price_m2, na.rm = TRUE)),
    `Mean Transactions` = sprintf("%.1f", mean(n_transactions, na.rm = TRUE)),
    `Pct Apartment (\\%)` = sprintf("%.1f", 100 * mean(pct_apartment, na.rm = TRUE)),
    `Mean Area (m²)` = sprintf("%.1f", mean(mean_area, na.rm = TRUE)),
    .groups = "drop"
  )

# Create LaTeX table
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Treatment Period (2014--2017)}\n",
  "\\label{tab:summary}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & ACV Cities & Control Cities \\\\\n",
  "\\midrule\n"
)

for (col in names(tab1_data)[-1]) {
  tab1_tex <- paste0(tab1_tex,
    col, " & ", tab1_data[[col]][tab1_data$Group == "ACV"],
    " & ", tab1_data[[col]][tab1_data$Group == "Control"], " \\\\\n")
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Statistics computed over the pre-treatment period (2014--2017). ",
  "ACV Cities are the 244 communes selected for the Action C\\oe ur de Ville program. ",
  "Control Cities are randomly sampled communes from the same d\\'epartements.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ==============================================================
# 3. Table 2: Main DiD Results
# ==============================================================
cat("Generating Table 2: Main Results...\n")

# Re-estimate models
m1 <- feols(log_mean_price_m2 ~ treat_post, data = panel, cluster = ~commune)
m2 <- feols(log_mean_price_m2 ~ treat_post | commune + year, data = panel, cluster = ~commune)
m3 <- feols(log_mean_price_m2 ~ treat_post | commune + departement^year, data = panel, cluster = ~commune)
m4 <- feols(log_n_trans ~ treat_post | commune + year, data = panel, cluster = ~commune)
m5 <- feols(log_price_m2 ~ treat_post + log(area) + i(broad_type) | commune_full + year,
            data = dvf_res, cluster = ~commune_full)
m6 <- feols(log_price_m2 ~ treat_post + log(area) + i(broad_type) | commune_full + departement^year,
            data = dvf_res, cluster = ~commune_full)

# Generate LaTeX table using fixest
tab2_tex <- etable(m1, m2, m3, m4, m5, m6,
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
       se.below = TRUE,
       keep = "treat_post",
       dict = c(treat_post = "ACV $\\times$ Post",
                log_mean_price_m2 = "Log Price/m² (Panel)",
                log_n_trans = "Log Transactions",
                log_price_m2 = "Log Price/m² (Trans.)"),
       fixef_sizes = TRUE,
       tex = TRUE,
       style.tex = style.tex("aer"),
       title = "Effect of Action C\\oe ur de Ville on Property Markets",
       label = "tab:main_results",
       notes = paste("All models cluster standard errors at the commune level.",
                     "Columns (1)--(3) use the commune-year panel with log mean price per m² as the dependent variable.",
                     "Column (4) uses log number of transactions.",
                     "Columns (5)--(6) use transaction-level data with property controls (log area, property type)."))

writeLines(tab2_tex, file.path(tables_dir, "tab2_main_results.tex"))

# ==============================================================
# 4. Table 3: Heterogeneity by Property Type
# ==============================================================
cat("Generating Table 3: Heterogeneity...\n")

m_apt <- feols(log_price_m2 ~ treat_post + log(area) | commune_full + year,
               data = dvf_res %>% filter(broad_type == "Apartment"),
               cluster = ~commune_full)

m_house <- feols(log_price_m2 ~ treat_post + log(area) | commune_full + year,
                 data = dvf_res %>% filter(broad_type == "House"),
                 cluster = ~commune_full)

# Small vs large properties
dvf_res <- dvf_res %>%
  mutate(
    size_cat = case_when(
      area < 50 ~ "Small (<50m²)",
      area < 100 ~ "Medium (50-100m²)",
      TRUE ~ "Large (>100m²)"
    )
  )

m_small <- feols(log_price_m2 ~ treat_post + log(area) | commune_full + year,
                 data = dvf_res %>% filter(area < 50),
                 cluster = ~commune_full)

m_large <- feols(log_price_m2 ~ treat_post + log(area) | commune_full + year,
                 data = dvf_res %>% filter(area >= 100),
                 cluster = ~commune_full)

tab3_tex <- etable(m_apt, m_house, m_small, m_large,
       headers = c("Apartments", "Houses", "Small (<50m²)", "Large (>100m²)"),
       se.below = TRUE,
       keep = "treat_post",
       dict = c(treat_post = "ACV $\\times$ Post"),
       fixef_sizes = TRUE,
       tex = TRUE,
       style.tex = style.tex("aer"),
       title = "Heterogeneity by Property Type and Size",
       label = "tab:heterogeneity",
       notes = "All models include commune and year fixed effects with clustered standard errors at the commune level.")

writeLines(tab3_tex, file.path(tables_dir, "tab3_heterogeneity.tex"))

# ==============================================================
# 5. Table 4: Robustness (Placebo + LOO range)
# ==============================================================
cat("Generating Table 4: Robustness Summary...\n")

placebo <- tryCatch(
  read_csv(file.path(tables_dir, "placebo_fake_dates.csv"), show_col_types = FALSE),
  error = function(e) NULL
)
loo <- tryCatch(
  read_csv(file.path(tables_dir, "leave_one_region_out.csv"), show_col_types = FALSE),
  error = function(e) NULL
)

if (!is.null(placebo) && !is.null(loo)) {
  main_coef <- coef(m2)["treat_postTRUE"]
  if (is.na(main_coef)) main_coef <- coef(m2)[1]  # first coef if name differs

  rob_tex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Robustness: Placebo Tests and Leave-One-Region-Out}\n",
    "\\label{tab:robustness}\n",
    "\\begin{adjustbox}{max width=\\textwidth}\n",
    "\\begin{tabular}{lcccc}\n",
    "\\toprule\n",
    "Test & Coefficient & SE & $p$-value & N \\\\\n",
    "\\midrule\n",
    "\\multicolumn{5}{l}{\\textit{Panel A: Placebo Tests (Fake Treatment Dates)}} \\\\\n"
  )

  for (i in 1:nrow(placebo)) {
    rob_tex <- paste0(rob_tex,
      sprintf("Placebo %d & %.4f & %.4f & %.3f & --- \\\\\n",
              placebo$fake_year[i], placebo$coefficient[i],
              placebo$std_error[i], placebo$p_value[i]))
  }

  rob_tex <- paste0(rob_tex,
    "\\midrule\n",
    "\\multicolumn{5}{l}{\\textit{Panel B: Leave-One-Region-Out (Coefficient Range)}} \\\\\n",
    sprintf("Min & %.4f & --- & --- & --- \\\\\n", min(loo$coefficient)),
    sprintf("Max & %.4f & --- & --- & --- \\\\\n", max(loo$coefficient)),
    sprintf("Full Sample & %.4f & --- & --- & --- \\\\\n", main_coef),
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\end{adjustbox}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} Panel A reports DiD estimates using placebo treatment dates in the pre-treatment period (2014--2017 only). ",
    "Panel B reports the range of main coefficients when each region is dropped.\n",
    "\\end{tablenotes}\n",
    "\\end{table}\n"
  )

  writeLines(rob_tex, file.path(tables_dir, "tab4_robustness.tex"))
}

cat("\n=== ALL TABLES GENERATED ===\n")
