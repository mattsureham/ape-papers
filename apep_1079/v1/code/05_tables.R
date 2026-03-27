# 05_tables.R — Generate all LaTeX tables
# apep_1079: Section 301 tariffs and racial employment effects

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
df <- readRDS("../data/analysis_panel_final.rds")
asian_shares <- readRDS("../data/asian_industry_shares.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================
# Table 1: Summary Statistics (hand-built LaTeX)
# ============================================================
cat("Generating Table 1...\n")

# Compute stats
stats_list <- list()
for (r in c("White", "Black", "Asian")) {
  sub <- df %>% filter(race_label == r)
  stats_list[[r]] <- tibble(
    race = r,
    N = nrow(sub),
    mean_emp = mean(sub$Emp, na.rm = TRUE),
    sd_emp = sd(sub$Emp, na.rm = TRUE),
    mean_log = mean(sub$log_emp, na.rm = TRUE),
    sd_log = sd(sub$log_emp, na.rm = TRUE),
    mean_earn = mean(sub$EarnS, na.rm = TRUE),
    mean_tariff = mean(sub$tariff_max, na.rm = TRUE)
  )
}
stats <- bind_rows(stats_list)

fmt_n <- function(x) formatC(x, format = "d", big.mark = ",")
fmt3 <- function(x) sprintf("%.3f", x)
fmt0 <- function(x) formatC(round(x), format = "d", big.mark = ",")

tab1_rows <- stats %>%
  mutate(row = paste0(
    race, " & ", fmt_n(N), " & ", fmt0(mean_emp), " & ",
    fmt0(sd_emp), " & ", fmt3(mean_log), " & ", fmt3(sd_log),
    " & ", fmt0(mean_earn), " & ", fmt3(mean_tariff), " \\\\"
  )) %>% pull(row)

tab1 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics: Manufacturing Employment by Race}\n",
  "\\label{tab:summary}\n\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrrr}\n\\toprule\n",
  "Race & N & Mean Emp & SD Emp & Mean $\\ln$(Emp) & SD $\\ln$(Emp) & Mean Earn & Mean Tariff \\\\\n",
  "\\midrule\n",
  paste(tab1_rows, collapse = "\n"), "\n",
  "\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Unit of observation is county $\\times$ 3-digit NAICS $\\times$ race ",
  "$\\times$ quarter. Sample: U.S.\\ manufacturing (NAICS 31--33), 2015Q1--2019Q4. ",
  "Emp is beginning-of-quarter employment from the QWI. Earn is average monthly ",
  "earnings for stable workers. Mean Tariff is the maximum Section 301 rate (0--25\\%).\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Asian concentration and tariff exposure
# ============================================================
cat("Generating Table 2...\n")

tab2_data <- asian_shares %>%
  filter(!is.na(tariff_max)) %>%
  arrange(desc(asian_share)) %>%
  head(12) %>%
  mutate(
    label = case_when(
      naics3 == "334" ~ "334: Computer \\& Electronic",
      naics3 == "315" ~ "315: Apparel",
      naics3 == "339" ~ "339: Misc.\\ Manufacturing",
      naics3 == "325" ~ "325: Chemicals",
      naics3 == "335" ~ "335: Electrical Equipment",
      naics3 == "311" ~ "311: Food",
      naics3 == "316" ~ "316: Leather",
      naics3 == "314" ~ "314: Textile Products",
      naics3 == "336" ~ "336: Transportation",
      naics3 == "333" ~ "333: Machinery",
      naics3 == "313" ~ "313: Textile Mills",
      naics3 == "332" ~ "332: Fabricated Metals",
      TRUE ~ paste0(naics3, ": Other")
    ),
    row = paste0(
      label, " & ", fmt_n(total), " & ",
      sprintf("%.1f", asian_share * 100), " & ",
      sprintf("%.1f", white_share * 100), " & ",
      sprintf("%.1f", black_share * 100), " & ",
      sprintf("%.0f", tariff_max * 100), "\\% & ",
      sprintf("%.2f", cip), " \\\\"
    )
  )

tab2 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Asian Worker Concentration and Tariff Exposure by Industry}\n",
  "\\label{tab:concentration}\n\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrr}\n\\toprule\n",
  "Industry & Total Emp & Asian \\% & White \\% & Black \\% & Tariff & CIP \\\\\n",
  "\\midrule\n",
  paste(tab2_data$row, collapse = "\n"), "\n",
  "\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Employment from QWI 2017Q2 (pre-treatment baseline). ",
  "Tariff is the maximum Section 301 rate. CIP is Chinese Import Penetration ",
  "(2017 Chinese imports / total imports). Industries sorted by Asian worker share.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_concentration.tex")

# ============================================================
# Table 3: Main results (hand-built)
# ============================================================
cat("Generating Table 3...\n")

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

make_row <- function(model, coef_name, label) {
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  p <- pvalue(model)[coef_name]
  if (is.na(b)) return(c(paste0(label, " & & \\\\"), ""))
  st <- stars(p)
  c(
    paste0(label, " & ", sprintf("%.4f", b), st, " \\\\"),
    paste0(" & (", sprintf("%.4f", s), ") \\\\")
  )
}

# Models for table: m3 (Bartik preferred), m4 (industry), m5 (industry+region), m6 (binary)
m3 <- results$m3
m4 <- results$m4
m5 <- results$m5
m_earn <- results$m_earn

# Build multi-column table
build_multi_row <- function(models, coef_name, label) {
  entries <- sapply(models, function(m) {
    b <- coef(m)[coef_name]
    s <- se(m)[coef_name]
    p <- pvalue(m)[coef_name]
    if (is.na(b)) return(c("", ""))
    st <- stars(p)
    c(paste0(sprintf("%.4f", b), st), paste0("(", sprintf("%.4f", s), ")"))
  })
  row1 <- paste0(label, " & ", paste(entries[1,], collapse = " & "), " \\\\")
  row2 <- paste0(" & ", paste(entries[2,], collapse = " & "), " \\\\[3pt]")
  paste(row1, row2, sep = "\n")
}

models_main <- list(m3, m4, m5, m_earn)

# Different coefficient names across models
# m3: bartik_tariff:post, bartik_tariff:post:is_asian, bartik_tariff:post:is_black
# m4/m5: tariff_max:post, tariff_max:post:is_asian, tariff_max:post:is_black
# m_earn: bartik_tariff:post, ...

# Build separate rows for each model type
build_row_multi <- function(label, coefs_by_model) {
  entries <- mapply(function(m, cn) {
    b <- coef(m)[cn]
    s <- se(m)[cn]
    p <- pvalue(m)[cn]
    if (is.na(b)) return(c("", ""))
    st <- stars(p)
    c(paste0(sprintf("%.4f", b), st), paste0("(", sprintf("%.4f", s), ")"))
  }, models_main, coefs_by_model, SIMPLIFY = TRUE)
  row1 <- paste0(label, " & ", paste(entries[1,], collapse = " & "), " \\\\")
  row2 <- paste0(" & ", paste(entries[2,], collapse = " & "), " \\\\[3pt]")
  paste(row1, row2, sep = "\n")
}

r1 <- build_row_multi("Exposure $\\times$ Post",
  c("bartik_tariff:post", "tariff_max:post", "tariff_max:post", "bartik_tariff:post"))
r2 <- build_row_multi("Exposure $\\times$ Post $\\times$ Asian",
  c("bartik_tariff:post:is_asian", "tariff_max:post:is_asian",
    "tariff_max:post:is_asian", "bartik_tariff:post:is_asian"))
r3 <- build_row_multi("Exposure $\\times$ Post $\\times$ Black",
  c("bartik_tariff:post:is_black", "tariff_max:post:is_black",
    "tariff_max:post:is_black", "bartik_tariff:post:is_black"))

n_vals <- sapply(models_main, function(m) fmt_n(nobs(m)))

tab3 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Effect of Section 301 Tariffs on Manufacturing Employment by Race}\n",
  "\\label{tab:main}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Bartik & Industry & Ind.+Region & Earnings \\\\\n",
  "\\midrule\n",
  r1, "\n", r2, "\n", r3, "\n",
  "\\midrule\n",
  "County$\\times$Race FE & \\checkmark & & & \\checkmark \\\\\n",
  "Cell FE & & \\checkmark & \\checkmark & \\\\\n",
  "Industry$\\times$Quarter FE & \\checkmark & & & \\checkmark \\\\\n",
  "Race$\\times$Quarter FE & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\\n",
  "Region$\\times$Quarter FE & & & \\checkmark & \\\\\n",
  "N & ", paste(n_vals, collapse = " & "), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Dependent variable: log(employment) in columns (1)--(3), log(earnings) in column (4). ",
  "Column (1): Bartik county-level tariff exposure (employment-weighted industry tariff rates). ",
  "Columns (2)--(3): industry-level maximum Section 301 tariff rate. ",
  "Post $=$ 2018Q3 onward. White workers are the reference group for race interactions.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_main.tex")

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Generating Table 4...\n")

m_ddd <- robust$m_ddd
m_pla <- robust$m_placebo
m_hir <- robust$m_hires
m_sep <- robust$m_sep

rob_models <- list(m_ddd, m_pla, m_hir, m_sep)

build_rob_row <- function(label, coefs) {
  entries <- mapply(function(m, cn) {
    b <- coef(m)[cn]
    s <- se(m)[cn]
    p <- pvalue(m)[cn]
    if (is.na(b)) return(c("", ""))
    st <- stars(p)
    c(paste0(sprintf("%.4f", b), st), paste0("(", sprintf("%.4f", s), ")"))
  }, rob_models, coefs, SIMPLIFY = TRUE)
  row1 <- paste0(label, " & ", paste(entries[1,], collapse = " & "), " \\\\")
  row2 <- paste0(" & ", paste(entries[2,], collapse = " & "), " \\\\[3pt]")
  paste(row1, row2, sep = "\n")
}

rr1 <- build_rob_row("Treatment $\\times$ Post",
  c("is_mfg:post", "tariff_max:fake_post", "tariff_max:post", "tariff_max:post"))
rr2 <- build_rob_row("Treatment $\\times$ Post $\\times$ Asian",
  c("is_mfg:post:is_asian", "tariff_max:fake_post:is_asian",
    "tariff_max:post:is_asian", "tariff_max:post:is_asian"))
rr3 <- build_rob_row("Treatment $\\times$ Post $\\times$ Black",
  c("is_mfg:post:is_black", "tariff_max:fake_post:is_black",
    "tariff_max:post:is_black", "tariff_max:post:is_black"))

n_rob <- sapply(rob_models, function(m) fmt_n(nobs(m)))

tab4 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Robustness: DDD, Placebo Timing, and Labor Market Margins}\n",
  "\\label{tab:robustness}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & DDD & Placebo & Hires & Separations \\\\\n",
  "\\midrule\n",
  rr1, "\n", rr2, "\n", rr3, "\n",
  "\\midrule\n",
  "N & ", paste(n_rob, collapse = " & "), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Col.\\ (1): DDD stacking manufacturing vs.\\ services. ",
  "Col.\\ (2): pre-period placebo with fake treatment at 2017Q1. ",
  "Cols.\\ (3)--(4): log hires and log separations as outcomes.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ============================================================
# Table F1: Standardized Effect Sizes
# ============================================================
cat("Generating SDE table...\n")

sd_y <- results$sd_log_emp_pre
sd_y_earn <- sd(df$log_earn[df$post == 0], na.rm = TRUE)

# Panel A: Pooled (using Bartik preferred spec m3)
sde_compute <- function(beta, se_beta, sd_y) {
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  cls <- case_when(
    sde < -0.15  ~ "Large negative",
    sde < -0.05  ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <  0.005 ~ "Null",
    sde <  0.05  ~ "Small positive",
    sde <  0.15  ~ "Moderate positive",
    TRUE         ~ "Large positive"
  )
  list(sde = sde, se_sde = se_sde, cls = cls)
}

m3 <- results$m3
m_earn_mod <- results$m_earn

# Bartik base effect
b1 <- coef(m3)["bartik_tariff:post"]
s1 <- se(m3)["bartik_tariff:post"]
r1 <- sde_compute(b1, s1, sd_y)

# Bartik Asian interaction
b2 <- coef(m3)["bartik_tariff:post:is_asian"]
s2 <- se(m3)["bartik_tariff:post:is_asian"]
r2 <- sde_compute(b2, s2, sd_y)

# Earnings base
b3 <- coef(m_earn_mod)["bartik_tariff:post"]
s3 <- se(m_earn_mod)["bartik_tariff:post"]
r3 <- sde_compute(b3, s3, sd_y_earn)

fn <- function(x, d = 4) sprintf(paste0("%.", d, "f"), x)

# Panel B: Heterogeneous — split by high vs low Asian concentration industries
high_asian <- df %>% filter(naics3 %in% c("334", "315", "339", "325", "335"))
low_asian <- df %>% filter(!naics3 %in% c("334", "315", "339", "325", "335"))

m_high <- feols(
  log_emp ~ bartik_tariff:post + bartik_tariff:post:is_asian +
    bartik_tariff:post:is_black | county_race + ind_qtr + race_qtr,
  data = high_asian, cluster = ~state
)
m_low <- feols(
  log_emp ~ bartik_tariff:post + bartik_tariff:post:is_asian +
    bartik_tariff:post:is_black | county_race + ind_qtr + race_qtr,
  data = low_asian, cluster = ~state
)

sd_h <- sd(high_asian$log_emp[high_asian$post == 0], na.rm = TRUE)
sd_l <- sd(low_asian$log_emp[low_asian$post == 0], na.rm = TRUE)

bh <- coef(m_high)["bartik_tariff:post:is_asian"]
sh <- se(m_high)["bartik_tariff:post:is_asian"]
rh <- sde_compute(bh, sh, sd_h)

bl <- coef(m_low)["bartik_tariff:post:is_asian"]
sl <- se(m_low)["bartik_tariff:post:is_asian"]
rl <- sde_compute(bl, sl, sd_l)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether the 2018--2019 Section 301 tariffs on Chinese imports produced ",
  "racially heterogeneous manufacturing employment effects, given the 4:1 overrepresentation of Asian workers ",
  "in tariff-targeted electronics manufacturing. ",
  "\\textbf{Policy mechanism:} Section 301 tariffs imposed ad valorem duties of 10--25\\% on Chinese imports ",
  "across manufacturing industries, raising input costs and reducing demand for import-competing products, ",
  "with the heaviest rates on electronics (NAICS 334) and machinery (NAICS 333) where Asian workers are ",
  "disproportionately employed. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter county-industry-race employment (Emp) from the QWI, ",
  "and log average monthly stable earnings (EarnS). ",
  "\\textbf{Treatment:} Continuous---Bartik county-level tariff exposure constructed as the employment-weighted ",
  "sum of industry-level Section 301 tariff rates using 2017Q2 baseline shares. ",
  "\\textbf{Data:} QWI race $\\times$ 3-digit NAICS $\\times$ county $\\times$ quarter panels (Census Bureau), ",
  "2015Q1--2019Q4; Chinese import penetration from Census International Trade; Section 301 rates from USTR. ",
  "\\textbf{Method:} OLS with county$\\times$race, industry$\\times$quarter, and race$\\times$quarter fixed effects; ",
  "SEs clustered at the state level. ",
  "\\textbf{Sample:} U.S.\\ manufacturing industries (NAICS 31--33), county-industry-race-quarter cells ",
  "with positive employment; three race groups (White, Black, Asian). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabf1 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Employment (all races) & ", fn(b1), " & ", fn(s1), " & ", fn(sd_y, 3), " & ",
    fn(r1$sde), " & ", fn(r1$se_sde), " & ", r1$cls, " \\\\\n",
  "Employment (Asian interaction) & ", fn(b2), " & ", fn(s2), " & ", fn(sd_y, 3), " & ",
    fn(r2$sde), " & ", fn(r2$se_sde), " & ", r2$cls, " \\\\\n",
  "Earnings (all races) & ", fn(b3), " & ", fn(s3), " & ", fn(sd_y_earn, 3), " & ",
    fn(r3$sde), " & ", fn(r3$se_sde), " & ", r3$cls, " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Asian interaction)}} \\\\\n",
  "High-Asian-share industries & ", fn(bh), " & ", fn(sh), " & ", fn(sd_h, 3), " & ",
    fn(rh$sde), " & ", fn(rh$se_sde), " & ", rh$cls, " \\\\\n",
  "Low-Asian-share industries & ", fn(bl), " & ", fn(sl), " & ", fn(sd_l, 3), " & ",
    fn(rl$sde), " & ", fn(rl$se_sde), " & ", rl$cls, " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tabf1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
