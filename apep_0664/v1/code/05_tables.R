## 05_tables.R — Generate all LaTeX tables
## apep_0664: Finland Competitiveness Pact

source("code/00_packages.R")

panel <- readRDS("data/panel.rds")
results <- readRDS("data/results_main.rds")
robustness <- readRDS("data/results_robustness.rds")

cat("=== Generating tables ===\n")

## ---- Table 1: Summary Statistics ----
# By country, pre/post
summ_stats <- panel %>%
  filter(year >= 2012, year <= 2019) %>%
  group_by(country, post) %>%
  summarise(
    mean_hours = mean(hours_thsd, na.rm = TRUE),
    sd_hours = sd(hours_thsd, na.rm = TRUE),
    mean_employment = mean(employment_thsd, na.rm = TRUE),
    mean_hours_pw = mean(hours_per_worker, na.rm = TRUE),
    mean_productivity = mean(productivity, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(period = ifelse(post == 0, "Pre (2012-2016)", "Post (2017-2019)"))

# Overall summary stats for the paper
overall <- panel %>%
  filter(year >= 2012, year <= 2019) %>%
  summarise(
    hours_mean = mean(ln_hours, na.rm = TRUE),
    hours_sd = sd(ln_hours, na.rm = TRUE),
    hours_pw_mean = mean(ln_hours_pw, na.rm = TRUE),
    hours_pw_sd = sd(ln_hours_pw, na.rm = TRUE),
    emp_mean = mean(ln_employment, na.rm = TRUE),
    emp_sd = sd(ln_employment, na.rm = TRUE),
    prod_mean = mean(ln_productivity, na.rm = TRUE),
    prod_sd = sd(ln_productivity, na.rm = TRUE),
    n = n()
  )

cat("Overall summary:\n")
print(overall)

# LaTeX summary table
tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics by Country and Period}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llrrrr}",
  "\\toprule",
  "Country & Period & Mean Hours (thsd) & Mean Employment (thsd) & Mean Hours/Worker & N \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summ_stats))) {
  r <- summ_stats[i, ]
  cname <- c("FI" = "Finland", "SE" = "Sweden", "DK" = "Denmark", "NO" = "Norway")[r$country]
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s & %d \\\\",
            cname, r$period,
            formatC(r$mean_hours, format = "f", digits = 0, big.mark = ","),
            formatC(r$mean_employment, format = "f", digits = 0, big.mark = ","),
            formatC(r$mean_hours_pw, format = "f", digits = 0, big.mark = ","),
            r$n))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s sector-country-year observations across %d NACE A*10 sectors (excluding totals), 4 Nordic countries (Finland, Sweden, Denmark, Norway), 2012--2019. Hours worked in thousands. Employment in thousands of persons. Hours/Worker = total hours / employment.",
          formatC(sum(summ_stats$n), big.mark = ","), length(unique(panel$sector))),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ---- Table 2: Main Results ----
# Use modelsummary
tab2_models <- list(
  "(1)" = results$m1,
  "(2)" = results$m2,
  "(3)" = results$m3,
  "(4)" = results$m4,
  "(5)" = results$m5
)

# Custom coefficient names
cm <- c(
  "treat_did" = "Finland $\\times$ Post",
  "triple_did" = "Finland $\\times$ Post $\\times$ Public"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) formatC(x, big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3)
)

## Generate Table 2 manually for compatibility
make_stars <- function(beta, se) {
  t <- abs(beta / se)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

# Extract coefficients
get_coef <- function(fit, varname) {
  b <- coef(fit)[varname]
  s <- se(fit)[varname]
  if (is.na(b)) return(list(beta = NA, se = NA, stars = ""))
  list(beta = b, se = s, stars = make_stars(b, s))
}

# Table 2
m1c <- get_coef(results$m1, "treat_did")
m2c <- get_coef(results$m2, "treat_did")
m3_did <- get_coef(results$m3, "treat_did")
m3_tri <- get_coef(results$m3, "triple_did")
m4c <- get_coef(results$m4, "treat_did")
m5c <- get_coef(results$m5, "treat_did")

fmt <- function(x, d=3) formatC(x, format="f", digits=d)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Finland's Competitiveness Pact on Hours Worked and Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Ln Hours & Ln Hours & Ln Hours & Ln Hours/Worker & Ln Employment \\\\",
  "\\midrule",
  sprintf("Finland $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
    fmt(m1c$beta), m1c$stars, fmt(m2c$beta), m2c$stars,
    fmt(m3_did$beta), m3_did$stars, fmt(m4c$beta), m4c$stars,
    fmt(m5c$beta), m5c$stars),
  sprintf("& (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
    fmt(m1c$se), fmt(m2c$se), fmt(m3_did$se), fmt(m4c$se), fmt(m5c$se)),
  "\\\\",
  sprintf("Finland $\\times$ Post $\\times$ Public & & & %s%s & & \\\\",
    fmt(m3_tri$beta), m3_tri$stars),
  sprintf("& & & (%s) & & \\\\", fmt(m3_tri$se)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
    nobs(results$m1), nobs(results$m2), nobs(results$m3),
    nobs(results$m4), nobs(results$m5)),
  "Country + Year + Sector FE & Yes & & & & \\\\",
  "Sector-Country + Year FE & & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Sample: 4 Nordic countries (FI, SE, DK, NO), 11 NACE A*10 sectors, 2008--2022. Post = 2017 onwards. Public sector = NACE O-Q (public administration, health, education). The triple-difference SE in column (3) should be interpreted with caution given only 4 country clusters.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("Table 2 written.\n")

## ---- Table 3: Robustness ----
r1c <- get_coef(robustness$pre_covid, "treat_did")
r2c <- get_coef(robustness$placebo, "treat_placebo")
r3c <- get_coef(robustness$no_norway, "treat_did")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Samples and Placebo Test}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& (1) Baseline & (2) Pre-COVID & (3) Placebo 2013 & (4) No Norway \\\\",
  "\\midrule",
  sprintf("Finland $\\times$ Post & %s%s & %s%s & & %s%s \\\\",
    fmt(m2c$beta), m2c$stars, fmt(r1c$beta), r1c$stars,
    fmt(r3c$beta), r3c$stars),
  sprintf("& (%s) & (%s) & & (%s) \\\\",
    fmt(m2c$se), fmt(r1c$se), fmt(r3c$se)),
  "\\\\",
  sprintf("Finland $\\times$ Post (Placebo) & & & %s%s & \\\\",
    fmt(r2c$beta), r2c$stars),
  sprintf("& & & (%s) & \\\\", fmt(r2c$se)),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nobs(results$m2), nobs(robustness$pre_covid),
    nobs(robustness$placebo), nobs(robustness$no_norway)),
  "Sample & 2008--2022 & 2008--2019 & 2008--2016 & 2008--2022 \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. All specifications include sector-country and year fixed effects. Dependent variable: log total hours worked. Column (3) uses a placebo treatment at 2013 on the pre-treatment sample only.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_robustness.tex")
cat("Table 3 written.\n")

## ---- Table 4: Sector-specific effects ----
sector_df <- robustness$by_sector

sector_names <- c(
  "A" = "Agriculture", "B-E" = "Industry", "C" = "Manufacturing",
  "F" = "Construction", "G-I" = "Trade/Transport/Hospitality",
  "J" = "Information/Communication", "K" = "Finance/Insurance",
  "L" = "Real Estate", "M_N" = "Professional/Admin Services",
  "O-Q" = "Public Admin/Health/Education", "R-U" = "Arts/Other Services"
)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Sector-Specific Effects of the Competitiveness Pact on Hours Worked}",
  "\\label{tab:sector}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcc}",
  "\\toprule",
  "Sector & Sector Name & $\\hat{\\beta}$ (Finland $\\times$ Post) & SE \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sector_df))) {
  r <- sector_df[i, ]
  sname <- ifelse(r$sector %in% names(sector_names), sector_names[r$sector], r$sector)
  stars <- ifelse(abs(r$beta / r$se) > 2.576, "***",
           ifelse(abs(r$beta / r$se) > 1.96, "**",
           ifelse(abs(r$beta / r$se) > 1.645, "*", "")))
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s & %s%s & (%s) \\\\",
            r$sector, sname,
            formatC(r$beta, format = "f", digits = 4), stars,
            formatC(r$se, format = "f", digits = 4)))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports a separate regression of log total hours on Finland $\\times$ Post with country and year fixed effects, restricted to one sector. Standard errors clustered at the country level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_sector.tex")
cat("Table 4 written.\n")

## ---- Table F1: SDE table (mandatory) ----
# Main outcomes: ln_hours (DiD), ln_hours_pw, ln_employment, ln_productivity
m2 <- results$m2
m4 <- results$m4
m5 <- results$m5
m_prod <- results$m_prod

# Function to compute SDE
compute_sde <- function(fit, outcome_var, data, label, spec_label) {
  beta <- coef(fit)["treat_did"]
  se_beta <- se(fit)["treat_did"]
  sd_y <- sd(data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

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

  data.frame(
    outcome = label,
    spec = spec_label,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_rows <- bind_rows(
  compute_sde(m2, "ln_hours", panel, "Log Total Hours", "Sector-Country + Year FE"),
  compute_sde(m4, "ln_hours_pw", panel, "Log Hours/Worker", "Sector-Country + Year FE"),
  compute_sde(m5, "ln_employment", panel, "Log Employment", "Sector-Country + Year FE"),
  compute_sde(m_prod, "ln_productivity",
              panel %>% filter(!is.na(ln_productivity)),
              "Log Productivity", "Sector-Country + Year FE")
)

cat("\nSDE table:\n")
print(sde_rows)

# Write LaTeX
sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  sde_lines <- c(sde_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\",
            r$outcome, r$spec,
            formatC(r$beta, format = "f", digits = 4),
            formatC(r$se, format = "f", digits = 4),
            formatC(r$sd_y, format = "f", digits = 3),
            formatC(r$sde, format = "f", digits = 4),
            formatC(r$se_sde, format = "f", digits = 4),
            r$classification))
}

n_obs <- nrow(panel %>% filter(year >= 2008, year <= 2022))

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE = $\\hat{\\beta}$ / SD($Y$)) for the main outcomes of Finland's 2017 Competitiveness Pact analysis. Treatment is binary (Finland $\\times$ Post 2017). SD($Y$) is the unconditional standard deviation from the full sample. \\textbf{Research question:} Did Finland's 2017 Competitiveness Pact---mandating 24 additional hours/year of working time---increase aggregate hours and labor productivity? \\textbf{Treatment:} Binary (Finland post-2017 vs.~Nordic peers). \\textbf{Data:} Eurostat national accounts (nama\\_10\\_a10\\_e, nama\\_10\\_a10), 2008--2022, sector-country-year panel. \\textbf{Method:} Difference-in-differences with sector-country and year fixed effects, country-clustered standard errors. \\textbf{Sample:} N = %s sector-country-year observations across 4 Nordic countries and %d NACE A*10 sectors. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
          formatC(n_obs, big.mark = ","), length(unique(panel$sector))),
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")
cat("SDE table written.\n")

cat("\nAll tables generated.\n")
