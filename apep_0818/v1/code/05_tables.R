## 05_tables.R — Generate all LaTeX tables including SDE
## apep_0818: Zombie Nonprofits

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
diagnostics <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

panel_pre <- panel %>% filter(year < 2011)
panel_post <- panel %>% filter(year >= 2011)

make_sumstat_row <- function(var, label, data_pre, data_post) {
  pre_vals <- data_pre[[var]]
  post_vals <- data_post[[var]]
  pre_vals <- pre_vals[!is.na(pre_vals)]
  post_vals <- post_vals[!is.na(post_vals)]

  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %s \\\\",
          label,
          mean(pre_vals), sd(pre_vals),
          mean(post_vals), sd(post_vals),
          format(length(pre_vals) + length(post_vals), big.mark = ","))
}

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-Period} & \\multicolumn{2}{c}{Post-Period} & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Variable & Mean & SD & Mean & SD & N \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel A: Treatment}} \\\\",
  "\\addlinespace",
  make_sumstat_row("revocation_intensity", "Revocation intensity", panel_pre, panel_post),
  make_sumstat_row("total_revocations", "Total revocations (county)", panel_pre, panel_post),
  make_sumstat_row("n_nonprofits_pre2010", "Pre-2010 nonprofits", panel_pre, panel_post),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Outcomes}} \\\\",
  "\\addlinespace",
  make_sumstat_row("formations_per_10k", "New formations per 10K pop.", panel_pre, panel_post),
  make_sumstat_row("new_formations", "New formations (count)", panel_pre, panel_post)
)

# Add charitable giving row if data exists
if (any(!is.na(panel$charitable_per_return))) {
  tab1_lines <- c(tab1_lines,
    make_sumstat_row("charitable_per_return", "Charitable deductions/return (\\$K)", panel_pre, panel_post))
}

# Add employment row if data exists
if (any(!is.na(panel$np_employment))) {
  tab1_lines <- c(tab1_lines,
    make_sumstat_row("np_employment", "Nonprofit employment (NAICS 813)", panel_pre, panel_post))
}

tab1_lines <- c(tab1_lines,
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel C: Controls}} \\\\",
  "\\addlinespace",
  make_sumstat_row("population", "Population", panel_pre, panel_post),
  "\\hline\\hline",
  "\\end{tabular}",
  paste0("\\begin{tablenotes}[flushleft]\\small"),
  paste0("\\item \\textit{Notes:} County-year panel, 2006--2020. ",
         "Revocation intensity is the share of pre-2010 registered nonprofits auto-revoked by the IRS in 2010--2012. ",
         "Counties with fewer than 10 pre-2010 nonprofits are excluded. ",
         "N = ", format(nrow(panel), big.mark = ","), " county-year observations ",
         "across ", format(n_distinct(panel$county_fips), big.mark = ","), " counties."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================================
# Table 2: Main Results — Formations
# ============================================================================
cat("=== Table 2: Main Results (Formations) ===\n")

tab2 <- etable(
  models$m1_form, models$m2_form, models$m3_form,
  headers = list("(1)", "(2)", "(3)"),
  dict = c(
    intensity_x_post = "Revocation Intensity $\\times$ Post",
    "log(population)" = "Log(Population)"
  ),
  fixef.group = list(
    "County FE" = "county_fips",
    "Year FE" = "^year$",
    "County Trends" = "county_fips\\[year\\]"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  style.tex = style.tex("aer"),
  fitstat = ~ n + r2,
  tex = TRUE,
  file = file.path(tables_dir, "tab2_formations.tex"),
  replace = TRUE,
  title = "Effect of Nonprofit Revocations on New Formations",
  label = "tab:formations"
)

cat("Table 2 written.\n")

# ============================================================================
# Table 3: Main Results — Charitable Giving and Employment
# ============================================================================
cat("=== Table 3: Charitable Giving and Employment ===\n")

tab3 <- etable(
  models$m1_charity, models$m2_charity,
  models$m1_emp, models$m2_emp,
  headers = list(
    ":_:" = c("Charitable Deductions/Return" = 2, "Log(NP Employment)" = 2)
  ),
  dict = c(
    intensity_x_post = "Revocation Intensity $\\times$ Post",
    "log(population)" = "Log(Population)"
  ),
  fixef.group = list(
    "County FE" = "county_fips",
    "Year FE" = "^year$"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  style.tex = style.tex("aer"),
  fitstat = ~ n + r2,
  tex = TRUE,
  file = file.path(tables_dir, "tab3_giving_employment.tex"),
  replace = TRUE,
  title = "Effect of Nonprofit Revocations on Charitable Giving and Employment",
  label = "tab:giving_employment"
)

cat("Table 3 written.\n")

# ============================================================================
# Table 4: Event Study Coefficients
# ============================================================================
cat("=== Table 4: Event Study ===\n")

es_coefs <- readRDS(file.path(data_dir, "event_study_coefs.rds"))

# Format event study table
es_tab <- es_coefs %>%
  arrange(rel_year) %>%
  mutate(
    stars = case_when(
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.10 ~ "*",
      TRUE ~ ""
    ),
    coef_str = sprintf("%.3f%s", Estimate, stars),
    se_str = sprintf("(%.3f)", `Std. Error`),
    year_label = ifelse(rel_year == -1, "$-1$ (ref.)", as.character(rel_year))
  )

es_tab_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Revocation Intensity and New Formations}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Year Relative to 2011 & Coefficient & Std. Error \\\\",
  "\\hline",
  "\\addlinespace"
)

for (i in seq_len(nrow(es_tab))) {
  if (es_tab$rel_year[i] == -1) {
    es_tab_lines <- c(es_tab_lines, paste0(es_tab$year_label[i], " & --- & --- \\\\"))
  } else {
    es_tab_lines <- c(es_tab_lines, paste0(es_tab$year_label[i], " & ",
                                             es_tab$coef_str[i], " & ",
                                             es_tab$se_str[i], " \\\\"))
  }
}

es_tab_lines <- c(es_tab_lines,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  paste0("\\item \\textit{Notes:} Event study coefficients from regressing new nonprofit formations per 10,000 population ",
         "on interactions of county revocation intensity with year dummies. ",
         "Year $-1$ (2010) is the reference period. ",
         "County and year fixed effects included. Standard errors clustered by county. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.1$."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(es_tab_lines, file.path(tables_dir, "tab4_event_study.tex"))
cat("Table 4 written.\n")

# ============================================================================
# Table 5: Robustness
# ============================================================================
cat("=== Table 5: Robustness ===\n")

tab5 <- etable(
  rob_models$placebo_form,
  rob_models$trimmed_form,
  rob_models$binary_form,
  rob_models$controlled_form,
  headers = list("Placebo", "Trimmed", "Binary Treat.", "Add. Controls"),
  dict = c(
    placebo_intensity_x_post = "Placebo Intensity $\\times$ Post",
    intensity_x_post = "Revocation Intensity $\\times$ Post",
    high_x_post = "High Revocation $\\times$ Post",
    pre_form_x_post = "Pre-Mean Formations $\\times$ Post",
    "log(population)" = "Log(Population)"
  ),
  fixef.group = list(
    "County FE" = "county_fips",
    "Year FE" = "^year$"
  ),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  style.tex = style.tex("aer"),
  fitstat = ~ n + r2,
  tex = TRUE,
  file = file.path(tables_dir, "tab5_robustness.tex"),
  replace = TRUE,
  title = "Robustness Checks: New Nonprofit Formations",
  label = "tab:robustness"
)

cat("Table 5 written.\n")

# ============================================================================
# SDE Table (Appendix F1)
# ============================================================================
cat("=== SDE Table ===\n")

# Compute SDEs for causal outcomes only (formations and employment)
# Charitable giving excluded: only post-period data available (no DiD possible)
sd_form_pre <- sd(panel$formations_per_10k[panel$year < 2011], na.rm = TRUE)

panel_qwi <- panel %>% filter(!is.na(np_employment), np_employment > 0)
sd_emp_pre <- sd(log(panel_qwi$np_employment[panel_qwi$year < 2011]), na.rm = TRUE)

# Also compute earnings SDE
panel_earn <- panel %>% filter(!is.na(np_earnings), np_earnings > 0)
sd_earn_pre <- sd(log(panel_earn$np_earnings[panel_earn$year < 2011]), na.rm = TRUE)

# Treatment is continuous: SDE = beta * SD(X) / SD(Y)
sd_intensity <- sd(panel$revocation_intensity, na.rm = TRUE)

# Extract coefficients
beta_form <- coef(models$m1_form)["intensity_x_post"]
se_form <- se(models$m1_form)["intensity_x_post"]

beta_emp <- coef(models$m1_emp)["intensity_x_post"]
se_emp <- se(models$m1_emp)["intensity_x_post"]

rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))
beta_earn <- coef(rob_models$earn_model)["intensity_x_post"]
se_earn <- se(rob_models$earn_model)["intensity_x_post"]

# SDE = beta * SD(X) / SD(Y) for continuous treatment
sde_form <- beta_form * sd_intensity / sd_form_pre
se_sde_form <- se_form * sd_intensity / sd_form_pre

sde_emp <- beta_emp * sd_intensity / sd_emp_pre
se_sde_emp <- se_emp * sd_intensity / sd_emp_pre

sde_earn <- beta_earn * sd_intensity / sd_earn_pre
se_sde_earn <- se_earn * sd_intensity / sd_earn_pre

# Classify SDE
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_rows <- tibble(
  outcome = c("New formations per 10K pop.", "Log(NP employment)", "Log(NP earnings per worker)"),
  beta = c(beta_form, beta_emp, beta_earn),
  se = c(se_form, se_emp, se_earn),
  sd_y = c(sd_form_pre, sd_emp_pre, sd_earn_pre),
  sde = c(sde_form, sde_emp, sde_earn),
  se_sde = c(se_sde_form, se_sde_emp, se_sde_earn),
  classification = classify_sde(c(sde_form, sde_emp, sde_earn))
)

cat("SDE results:\n")
print(sde_rows)

# Generate LaTeX SDE table
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace"
)

for (i in seq_len(nrow(sde_rows))) {
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
            sde_rows$classification[i])
  )
}

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does mass auto-revocation of tax-exempt status for non-filing ",
  "nonprofits create creative destruction (new entry) or collateral damage (reduced giving and employment) ",
  "in local charitable ecosystems? ",
  "\\textbf{Policy mechanism:} The Pension Protection Act of 2006 required all IRS-registered ",
  "tax-exempt organizations to file annual returns; three consecutive years of non-filing triggers automatic ",
  "revocation of tax-exempt status, removing the organization from the IRS Exempt Organizations registry ",
  "and eliminating donor tax-deductibility. The first major enforcement wave revoked approximately 275,000 ",
  "organizations in June 2011. ",
  "\\textbf{Outcome definition:} (1) New nonprofit formations per 10,000 county population, measured by ",
  "IRS ruling dates for newly recognized exempt organizations; (2) Log quarterly nonprofit employment from Census QWI ",
  "NAICS 813 (Religious, Grantmaking, Civic, Professional, and Similar Organizations); ",
  "(3) Log quarterly earnings per worker from Census QWI NAICS 813. ",
  "\\textbf{Treatment:} Continuous---county-level revocation intensity, defined as the share of pre-2010 ",
  "registered nonprofits that were auto-revoked between 2010 and 2012. ",
  "\\textbf{Data:} IRS Auto-Revocation List, Exempt Organizations Business Master File, SOI County Income Data, ",
  "and Census QWI; county-year panel 2006--2020; ", format(n_distinct(panel$county_fips), big.mark = ","),
  " counties with at least 10 pre-2010 nonprofits. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with county and year fixed effects; ",
  "standard errors clustered at the county level. ",
  "\\textbf{Sample:} US counties with at least 10 registered nonprofits as of 2010; excludes counties ",
  "with missing QWI or SOI data for employment and giving outcomes. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of ",
  "revocation intensity and SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(sde_lines,
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table written.\n")

cat("\n=== All tables generated ===\n")
