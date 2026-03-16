### 05_tables.R
### Kenya Interest Rate Cap and FinTech Substitution
### apep_0702

source("00_packages.R")
setwd("../data")

library(fixest)

# Resolve conflict: use fixest's pvalue and se, not scales'
pvalue <- fixest::pvalue
se     <- fixest::se

cat("=== Generating Tables ===\n")

panel_country   <- read_csv("panel_country.csv", show_col_types = FALSE)
county_long     <- read_csv("county_long.csv", show_col_types = FALSE)
finaccess_county <- read_csv("finaccess_county_clean.csv", show_col_types = FALSE)
es_coefs        <- read_csv("event_study_coefs.csv", show_col_types = FALSE)
rob_results     <- read_csv("robustness_results.csv", show_col_types = FALSE)
results_summary <- jsonlite::read_json("results_summary.json")

# Re-estimate models directly (avoid RDS deserialization issues)
df_main   <- panel_country %>% filter(!is.na(credit_gdp))
df_lend   <- panel_country %>% filter(!is.na(lending_rate))
df_branch <- panel_country %>% filter(!is.na(branches_100k))
df_npl    <- panel_country %>% filter(!is.na(npl_ratio))

m1_credit <- feols(credit_gdp ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_main, cluster = ~country_code)
m2_lend   <- feols(lending_rate ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_lend, cluster = ~country_code)
m3_branch <- feols(branches_100k ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_branch, cluster = ~country_code)
m4_npl    <- feols(npl_ratio ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_npl, cluster = ~country_code)

m5_county <- feols(digital_credit_pct ~ bank_x_cap | county + year,
                   data = county_long, cluster = ~county)

df_placebo <- panel_country %>%
  filter(year >= 2010, year <= 2015, !is.na(credit_gdp)) %>%
  mutate(fake_cap = as.integer(year >= 2013),
         treat_fake = kenya * fake_cap)
m_placebo <- feols(credit_gdp ~ treat_fake | country_code + year,
                   data = df_placebo, cluster = ~country_code)

# First-difference model
county_fd <- finaccess_county %>%
  mutate(
    delta_digital = digital_credit_2019 - digital_credit_2016,
    bank_pen_std  = scale(bank_branches_2015)[,1]
  )
m6_fd <- lm(delta_digital ~ bank_pen_std, data = county_fd)

perm_p_cap    <- results_summary$perm_p_cap
perm_p_repeal <- results_summary$perm_p_repeal

dir.create("../tables", showWarnings = FALSE)

# ===================================================
# TABLE 1: Summary Statistics
# ===================================================
cat("Generating Table 1: Summary Statistics\n")

# Compute summary stats by period and country group
kenya_data <- panel_country %>% filter(country_code == "KE")
control_data <- panel_country %>% filter(country_code != "KE")

pre_ke  <- kenya_data %>% filter(year < 2016)
cap_ke  <- kenya_data %>% filter(year >= 2017, year <= 2019)
post_ke <- kenya_data %>% filter(year >= 2020)
pre_ctl <- control_data %>% filter(year < 2016)

summarize_var <- function(df, var) {
  x <- df[[var]]
  x <- x[!is.na(x)]
  if (length(x) == 0) return(c(NA, NA, NA))
  c(mean(x), sd(x), length(x))
}

vars_for_table <- c("credit_gdp", "lending_rate", "npl_ratio", "branches_100k", "deposit_rate")
var_labels <- c("Credit/GDP (\\%)", "Lending rate (\\%)", "NPL ratio (\\%)",
                "Bank branches per 100K", "Deposit rate (\\%)")

# Build summary table
tab1_rows <- c()
for (i in seq_along(vars_for_table)) {
  v <- vars_for_table[i]
  if (!v %in% names(panel_country)) next

  pre_ke_s   <- summarize_var(pre_ke, v)
  cap_ke_s   <- summarize_var(cap_ke, v)
  post_ke_s  <- summarize_var(post_ke, v)
  pre_ctl_s  <- summarize_var(pre_ctl, v)

  row <- sprintf(
    "  %s & %.1f & %.1f & %.1f & %.1f \\\\",
    var_labels[i],
    ifelse(is.na(pre_ke_s[1]), NA, pre_ke_s[1]),
    ifelse(is.na(cap_ke_s[1]), NA, cap_ke_s[1]),
    ifelse(is.na(post_ke_s[1]), NA, post_ke_s[1]),
    ifelse(is.na(pre_ctl_s[1]), NA, pre_ctl_s[1])
  )
  tab1_rows <- c(tab1_rows, row)
}

# N row
n_ke_pre  <- nrow(pre_ke)
n_ke_cap  <- nrow(cap_ke)
n_ke_post <- nrow(post_ke)
n_ctl_pre <- nrow(pre_ctl)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Kenya} & Controls \\\\",
  "\\cmidrule(lr){2-4}",
  " Variable & Pre-cap & Cap & Post-repeal & Pre-cap \\\\",
  " & (2010--15) & (2017--19) & (2020--23) & (2010--15) \\\\",
  "\\hline",
  tab1_rows,
  "\\hline",
  sprintf("  \\textit{Observations} & %d & %d & %d & %d \\\\",
          n_ke_pre, n_ke_cap, n_ke_post, n_ctl_pre),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Means of country-level indicators from World Bank WDI. Controls are Uganda, Tanzania, and Rwanda. Pre-cap period is 2010--2015; cap period is 2017--2019 (full years under the Banking Amendment Act 2016); post-repeal is 2020--2023. NPL = non-performing loans.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Saved: tab1_summary.tex\n")

# ===================================================
# TABLE 2: Main DiD Results
# ===================================================
cat("Generating Table 2: Main DiD Results\n")

# Extract coefficients and build table manually for precision
get_coef_row <- function(model, coef_name, n_obs, label) {
  if (!coef_name %in% names(coef(model))) {
    return(list(beta=NA, se=NA, p=NA, n=NA))
  }
  list(
    beta = coef(model)[coef_name],
    se   = se(model)[coef_name],
    p    = pvalue(model)[coef_name],
    n    = nobs(model)
  )
}

# Stars
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

fmt_coef <- function(beta, se, p) {
  if (is.na(beta)) return(list("---", ""))
  list(
    sprintf("%.3f%s", beta, stars(p)),
    sprintf("(%.3f)", se)
  )
}

# Build models' results
r1_cap <- get_coef_row(m1_credit, "treat_cap_full", NA, "cap")
r1_rep <- get_coef_row(m1_credit, "treat_repeal", NA, "rep")
r2_cap <- get_coef_row(m2_lend, "treat_cap_full", NA, "cap")
r2_rep <- get_coef_row(m2_lend, "treat_repeal", NA, "rep")
r3_cap <- get_coef_row(m3_branch, "treat_cap_full", NA, "cap")
r3_rep <- get_coef_row(m3_branch, "treat_repeal", NA, "rep")
r4_cap <- get_coef_row(m4_npl, "treat_cap_full", NA, "cap")
r4_rep <- get_coef_row(m4_npl, "treat_repeal", NA, "rep")

make_coef_line <- function(r) fmt_coef(r$beta, r$se, r$p)

r1c <- make_coef_line(r1_cap); r1r <- make_coef_line(r1_rep)
r2c <- make_coef_line(r2_cap); r2r <- make_coef_line(r2_rep)
r3c <- make_coef_line(r3_cap); r3r <- make_coef_line(r3_rep)
r4c <- make_coef_line(r4_cap); r4r <- make_coef_line(r4_rep)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Interest Rate Cap and Credit Market Outcomes: Difference-in-Differences}",
  "\\label{tab:main_did}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Credit/GDP & Lending rate & Bank branches & NPL ratio \\\\",
  "\\hline",
  sprintf("  Kenya $\\times$ Cap & %s & %s & %s & %s \\\\",
          r1c[[1]], r2c[[1]], r3c[[1]], r4c[[1]]),
  sprintf("   & %s & %s & %s & %s \\\\",
          r1c[[2]], r2c[[2]], r3c[[2]], r4c[[2]]),
  sprintf("  Kenya $\\times$ Post-repeal & %s & %s & %s & %s \\\\",
          r1r[[1]], r2r[[1]], r3r[[1]], r4r[[1]]),
  sprintf("   & %s & %s & %s & %s \\\\",
          r1r[[2]], r2r[[2]], r3r[[2]], r4r[[2]]),
  "\\hline",
  "  Country FE & Yes & Yes & Yes & Yes \\\\",
  "  Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("  Observations & %d & %d & %d & %d \\\\",
          nobs(m1_credit), nobs(m2_lend), nobs(m3_branch), nobs(m4_npl)),
  "\\hline\\hline",
  paste0("\\multicolumn{5}{p{0.93\\textwidth}}{\\footnotesize \\textit{Notes:} TWFE difference-in-differences estimates. Treatment: Kenya (Banking Amendment Act 2016, capping lending rates at CBR$+$4\\%; repealed November 2019). Control countries: Uganda, Tanzania, Rwanda. Cap period: 2017--2019 (full cap years). Post-repeal: 2020--2023. All outcomes from World Bank WDI. Standard errors clustered at country level in parentheses. With only four clusters, permutation $p$-values for credit/GDP: cap $p=",
         sprintf("%.2f", perm_p_cap),
         "$, repeal $p=",
         sprintf("%.2f", perm_p_repeal),
         "$. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.}"),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main_did.tex")
cat("  Saved: tab2_main_did.tex\n")

# ===================================================
# TABLE 3: Event Study
# ===================================================
cat("Generating Table 3: Event Study\n")

# Format event study as table
es_formatted <- es_coefs %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se,
    year_label = 2016 + event_time,
    period_label = case_when(
      event_time == -1 ~ "2015 (base)",
      event_time == 0  ~ "2016 (cap intro)",
      event_time == 1  ~ "2017",
      event_time == 2  ~ "2018",
      event_time == 3  ~ "2019 (repeal yr)",
      event_time == 4  ~ "2020",
      event_time == 5  ~ "2021+",
      TRUE ~ as.character(year_label)
    )
  )

tab3_rows <- c()
for (i in 1:nrow(es_formatted)) {
  r <- es_formatted[i, ]
  if (r$event_time == -1) {
    row <- sprintf("  %s & 0 & --- & --- \\\\[2pt]", r$period_label)
  } else {
    row <- sprintf("  %s & %.3f & %.3f & [%.3f, %.3f] \\\\",
                   r$period_label, r$coef, r$se, r$ci_lo, r$ci_hi)
  }
  tab3_rows <- c(tab3_rows, row)
  # Add horizontal line after pre-period and after cap period
  if (r$event_time == -1) tab3_rows <- c(tab3_rows, "\\hline")
  if (r$event_time == 3) tab3_rows <- c(tab3_rows, "\\hdashline")
}

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Credit to Private Sector (\\% GDP) around Kenya's Interest Rate Cap}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "  Year & $\\hat{\\beta}$ (Kenya diff.) & SE & 95\\% CI \\\\",
  "\\hline",
  tab3_rows,
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.7\\textwidth}}{\\footnotesize \\textit{Notes:} Kenya--control country differential in credit/GDP (\\%), relative to 2015 baseline. Control countries: Uganda, Tanzania, Rwanda. Country and year fixed effects. Reference year is 2015 ($\\hat{\\beta}=-1$, normalized to zero). The cap was introduced in September 2016; full cap years are 2017--2019. The repeal was signed November 2019; post-repeal years begin 2020. Heteroscedasticity-robust standard errors.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_eventstudy.tex")
cat("  Saved: tab3_eventstudy.tex\n")

# ===================================================
# TABLE 4: County-Level FinTech Substitution
# ===================================================
cat("Generating Table 4: FinTech Substitution\n")

m5_county_coef <- coef(m5_county)["bank_x_cap"]
m5_county_se   <- se(m5_county)["bank_x_cap"]
m5_county_p    <- pvalue(m5_county)["bank_x_cap"]

# FD regression
# m6_fd and county_fd were already re-estimated above
m6_fd_robust <- coeftest(m6_fd, vcov = sandwich::vcovHC(m6_fd, type = "HC3"))

m6_coef <- m6_fd_robust["bank_pen_std", "Estimate"]
m6_se   <- m6_fd_robust["bank_pen_std", "Std. Error"]
m6_p    <- m6_fd_robust["bank_pen_std", "Pr(>|t|)"]

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Digital Credit Substitution: County-Level Evidence from FinAccess 2016--2019}",
  "\\label{tab:fintech}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & County FE & First-difference \\\\",
  " & (2016--2019) & ($\\Delta$ 2016--2019) \\\\",
  "\\hline",
  sprintf("  Bank pen. $\\times$ Post-2016 & %.3f%s & %.3f%s \\\\",
          m5_county_coef, stars(m5_county_p),
          m6_coef, stars(m6_p)),
  sprintf("   & (%.3f) & (%.3f) \\\\",
          m5_county_se, m6_se),
  "\\hline",
  "  County FE & Yes & --- \\\\",
  "  Year FE & Yes & --- \\\\",
  sprintf("  Counties & %d & %d \\\\",
          n_distinct(county_long$county),
          nrow(county_fd)),
  sprintf("  Observations & %d & %d \\\\",
          nobs(m5_county),
          nrow(county_fd)),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.75\\textwidth}}{\\footnotesize \\textit{Notes:} Outcome is digital credit usage rate (\\% of county adults). Treatment intensity: bank branch density per 100K adults in 2015 (pre-cap), standardized. Post-2016 indicator covers FinAccess 2019 wave (cap period). Column (1): TWFE with county and year FE, standard errors clustered at county level. Column (2): cross-section first-difference regressing $\\Delta$ digital credit (2019 minus 2016) on pre-cap bank penetration, HC3 robust SE. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_fintech.tex")
cat("  Saved: tab4_fintech.tex\n")

# ===================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ===================================================
cat("Generating Table F1: SDE\n")

# Compute SDE for each main outcome
# Binary treatment: SDE = beta / SD(Y)

classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

df_main <- panel_country %>% filter(!is.na(credit_gdp))
df_lend <- panel_country %>% filter(!is.na(lending_rate))
df_branch <- panel_country %>% filter(!is.na(branches_100k))
df_npl <- panel_country %>% filter(!is.na(npl_ratio))

outcomes_sde <- list(
  list(name="Credit/GDP", var="credit_gdp", model=m1_credit, coef_name="treat_cap_full",
       df=df_main, label="Credit/GDP (\\%)"),
  list(name="Lending rate", var="lending_rate", model=m2_lend, coef_name="treat_cap_full",
       df=df_lend, label="Lending rate (\\%)"),
  list(name="Bank branches", var="branches_100k", model=m3_branch, coef_name="treat_cap_full",
       df=df_branch, label="Bank branches per 100K"),
  list(name="NPL ratio", var="npl_ratio", model=m4_npl, coef_name="treat_cap_full",
       df=df_npl, label="NPL ratio (\\%)")
)

sde_rows <- c()
for (o in outcomes_sde) {
  if (!o$coef_name %in% names(coef(o$model))) next
  beta <- coef(o$model)[o$coef_name]
  se_b <- se(o$model)[o$coef_name]
  y_vec <- o$df[[o$var]]
  sd_y <- sd(y_vec, na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_b / sd_y
  class_sde <- classify_sde(sde)

  row <- sprintf("  %s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
                 o$label, beta, se_b, sd_y, sde, se_sde, class_sde)
  sde_rows <- c(sde_rows, row)
}

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sde_rows,
  "\\hline\\hline",
  "\\multicolumn{7}{p{\\textwidth}}{\\footnotesize",
  "\\textbf{Country:} Kenya (sub-Saharan Africa, East Africa).",
  "\\textbf{Research question:} Did Kenya's 2016 interest rate cap (Banking Amendment Act, capping commercial bank lending at CBR+4\\%, effective September 2016, repealed November 2019) reduce formal credit availability and drive substitution toward unregulated digital mobile credit?",
  "\\textbf{Policy mechanism:} The Banking (Amendment) Act No.\\ 25 of 2016 capped all 42 licensed commercial bank lending rates at the Central Bank Rate plus 4 percentage points and floored deposit rates at 70\\% of CBR. Digital credit providers (M-Shwari, Tala, Branch, KCB M-Pesa) were explicitly outside the Banking Act's regulatory perimeter and exempt from the cap. The cap was repealed in November 2019 via the Finance Act 2019.",
  "\\textbf{Outcome definitions:} Credit/GDP is domestic credit to private sector as a share of GDP (\\%). Lending rate is the commercial bank lending rate (\\% per annum). Bank branches is the count of commercial bank branches per 100,000 adults. NPL ratio is non-performing loans as a share of gross loans (\\%).",
  "\\textbf{Treatment:} Binary indicator: Kenya during cap period (2017--2019), relative to Uganda, Tanzania, and Rwanda as control countries.",
  "\\textbf{Data:} World Bank World Development Indicators (WDI). Country-year panel, 4 East African countries, 2010--2023. Estimates from TWFE difference-in-differences using cap period 2017--2019.",
  "\\textbf{Method:} Two-way fixed effects DiD with country and year FE. Standard errors clustered at country level. Permutation $p$-values reported given small cluster count.",
  "\\textbf{Sample:} East African countries (Kenya treated; Uganda, Tanzania, Rwanda as controls). Sample period 2010--2023.",
  "\\textbf{SDE classification:} Based on point estimate magnitude only, not statistical significance. Large: $|\\mathrm{SDE}|>0.15$; Moderate: $0.05<|\\mathrm{SDE}|\\leq 0.15$; Small: $0.005<|\\mathrm{SDE}|\\leq 0.05$; Null: $|\\mathrm{SDE}|\\leq 0.005$. All coefficients from TWFE cap-period (2017--2019) effect.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Saved: tabF1_sde.tex\n")

cat("\n=== Table Generation Complete ===\n")
cat("Tables written to ../tables/\n")
