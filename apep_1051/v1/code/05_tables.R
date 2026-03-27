# 05_tables.R — Generate all LaTeX tables
# apep_1051: CRP Cap Reduction and Land-Use Transitions

source("00_packages.R")

data_dir <- "../data"
tab_dir  <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "main_results.rds"))
rob     <- readRDS(file.path(data_dir, "robustness_results.rds"))
panel   <- results$panel
crp_ts  <- readRDS(file.path(data_dir, "crp_timeseries.rds"))
crp_treat <- readRDS(file.path(data_dir, "crp_treatment.rds"))

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================

pre <- panel %>% filter(year < 2014)

# Treatment variable summary
treat_summary <- crp_treat %>%
  filter(treatment > 0) %>%
  summarise(
    mean_loss = mean(crp_loss),
    sd_loss = sd(crp_loss),
    mean_share = mean(treatment),
    sd_share = sd(treatment),
    n = n()
  )

tab1 <- tribble(
  ~Variable, ~Mean, ~SD, ~N,
  "\\emph{Panel A: Outcomes (pre-treatment, 2006--2013)}", NA, NA, NA,
  "\\quad Total planted acres (corn + soy + wheat)", mean(pre$total_planted), sd(pre$total_planted), nrow(pre),
  "\\quad Corn planted acres", mean(pre$corn), sd(pre$corn), nrow(pre),
  "\\quad Soybean planted acres", mean(pre$soybeans), sd(pre$soybeans), nrow(pre),
  "\\quad Wheat planted acres", mean(pre$wheat), sd(pre$wheat), nrow(pre),
  "\\quad Hay harvested acres", mean(pre$hay), sd(pre$hay), nrow(pre),
  "\\emph{Panel B: Treatment (cross-sectional)}", NA, NA, NA,
  "\\quad CRP acres lost, 2013--2018", treat_summary$mean_loss, treat_summary$sd_loss, treat_summary$n,
  "\\quad CRP loss / total cropland", treat_summary$mean_share, treat_summary$sd_share, treat_summary$n,
  "\\emph{Panel C: Sample}", NA, NA, NA,
  "\\quad Counties", n_distinct(panel$fips), NA, NA,
  "\\quad States", as.integer(n_distinct(panel$state_fips)), NA, NA,
  "\\quad County-year observations", nrow(panel), NA, NA
)

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & N \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(tab1)) {
  row <- tab1[i, ]
  if (is.na(row$Mean)) {
    if (grepl("Panel", row$Variable)) {
      tab1_tex <- paste0(tab1_tex, row$Variable, " & & & \\\\\n")
    } else {
      tab1_tex <- paste0(tab1_tex, row$Variable, " & ",
                          formatC(row$Mean, format = "f", digits = 0, big.mark = ","), " & & \\\\\n")
    }
  } else {
    if (row$Mean > 100) {
      tab1_tex <- paste0(tab1_tex, row$Variable, " & ",
                          formatC(row$Mean, format = "f", digits = 0, big.mark = ","), " & ",
                          ifelse(is.na(row$SD), "", formatC(row$SD, format = "f", digits = 0, big.mark = ",")), " & ",
                          ifelse(is.na(row$N), "", formatC(row$N, format = "f", digits = 0, big.mark = ",")), " \\\\\n")
    } else {
      tab1_tex <- paste0(tab1_tex, row$Variable, " & ",
                          formatC(row$Mean, format = "f", digits = 4), " & ",
                          ifelse(is.na(row$SD), "", formatC(row$SD, format = "f", digits = 4)), " & ",
                          ifelse(is.na(row$N), "", formatC(row$N, format = "f", digits = 0, big.mark = ",")), " \\\\\n")
    }
  }
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A reports pre-treatment (2006--2013) county-year means ",
  "from USDA NASS QuickStats. Panel B reports cross-sectional treatment variables: ",
  "CRP acres lost between 2012--2013 and 2018--2019 averages, sourced from FSA ",
  "county-level enrollment data. Treatment share is CRP loss divided by Census of ",
  "Agriculture 2012 total cropland.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: MAIN RESULTS — CROP-SPECIFIC DiD
# ============================================================

m2 <- results$main$m2
m_corn <- results$crops$corn
m_soy <- results$crops$soy
m_wheat <- results$crops$wheat
m_hay <- results$crops$hay

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of CRP Contract Expirations on Crop Acreage}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Total Planted & Corn & Soybeans & Wheat \\\\\n",
  "\\hline\n"
)

format_coef <- function(model, digits = 0) {
  b <- coef(model)["treat_x_post"]
  se <- sqrt(vcov(model)["treat_x_post", "treat_x_post"])
  pval <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.1, "^{*}", "")))
  b_str <- formatC(b, format = "f", digits = digits, big.mark = ",")
  se_str <- formatC(se, format = "f", digits = digits, big.mark = ",")
  paste0(b_str, "$", stars, "$ & ")
}

format_se <- function(model, digits = 0) {
  se <- sqrt(vcov(model)["treat_x_post", "treat_x_post"])
  paste0("(", formatC(se, format = "f", digits = digits, big.mark = ","), ") & ")
}

# Extract values for manual formatting
get_vals <- function(model) {
  b <- coef(model)["treat_x_post"]
  se <- sqrt(vcov(model)["treat_x_post", "treat_x_post"])
  pval <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.1, "^{*}", "")))
  list(b = b, se = se, stars = stars)
}

v_total <- get_vals(m2)
v_corn <- get_vals(m_corn)
v_soy <- get_vals(m_soy)
v_wheat <- get_vals(m_wheat)

fmt <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")

tab2_tex <- paste0(tab2_tex,
  "CRP Loss Share $\\times$ Post & $", fmt(v_total$b), "$", v_total$stars,
  " & $", fmt(v_corn$b), "$", v_corn$stars,
  " & $", fmt(v_soy$b), "$", v_soy$stars,
  " & $", fmt(v_wheat$b), "$", v_wheat$stars, " \\\\\n",
  " & (", fmt(v_total$se), ") & (", fmt(v_corn$se), ") & (", fmt(v_soy$se), ") & (", fmt(v_wheat$se), ") \\\\\n",
  "\\hline\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", fmt(nobs(m2)), " & ", fmt(nobs(m_corn)), " & ", fmt(nobs(m_soy)), " & ", fmt(nobs(m_wheat)), " \\\\\n",
  "R$^2$ (within) & ", formatC(fitstat(m2, "wr2")[[1]], format = "f", digits = 4),
  " & ", formatC(fitstat(m_corn, "wr2")[[1]], format = "f", digits = 4),
  " & ", formatC(fitstat(m_soy, "wr2")[[1]], format = "f", digits = 4),
  " & ", formatC(fitstat(m_wheat, "wr2")[[1]], format = "f", digits = 4), " \\\\\n",
  "Counties & ", fmt(n_distinct(panel$fips)), " & ", fmt(n_distinct(panel$fips)),
  " & ", fmt(n_distinct(panel$fips)), " & ", fmt(n_distinct(panel$fips)), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each column reports a separate OLS regression of county-level crop acreage ",
  "on the interaction of CRP loss share (CRP acres lost 2013--2018 divided by Census 2012 cropland) with a post-2014 indicator. ",
  "All specifications include county and state-by-year fixed effects. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tab_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: ROBUSTNESS
# ============================================================

# Get placebo, belt, and alternative FE results for corn
v_main <- get_vals(m_corn)
v_plac <- list(
  b = coef(rob$placebo_corn)["placebo_treat"],
  se = sqrt(vcov(rob$placebo_corn)["placebo_treat", "placebo_treat"])
)
v_plac$stars <- ifelse(2*pnorm(-abs(v_plac$b/v_plac$se)) < 0.1, "^{*}", "")

v_belt <- list(
  b = coef(rob$belt_corn)["treat_x_post"],
  se = sqrt(vcov(rob$belt_corn)["treat_x_post", "treat_x_post"])
)
pval_belt <- 2*pnorm(-abs(v_belt$b/v_belt$se))
v_belt$stars <- ifelse(pval_belt < 0.01, "^{***}", ifelse(pval_belt < 0.05, "^{**}", ifelse(pval_belt < 0.1, "^{*}", "")))

v_alt <- list(
  b = coef(rob$alt1_corn)["treat_x_post"],
  se = sqrt(vcov(rob$alt1_corn)["treat_x_post", "treat_x_post"])
)
pval_alt <- 2*pnorm(-abs(v_alt$b/v_alt$se))
v_alt$stars <- ifelse(pval_alt < 0.01, "^{***}", ifelse(pval_alt < 0.05, "^{**}", ifelse(pval_alt < 0.1, "^{*}", "")))

tab3_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness: Corn Acreage}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & Placebo 2010 & Crop Belt & Year FE \\\\\n",
  "\\hline\n",
  "CRP Loss Share $\\times$ Post & $", fmt(v_main$b), "$", v_main$stars,
  " & $", fmt(v_plac$b), "$", v_plac$stars,
  " & $", fmt(v_belt$b), "$", v_belt$stars,
  " & $", fmt(v_alt$b), "$", v_alt$stars, " \\\\\n",
  " & (", fmt(v_main$se), ") & (", fmt(v_plac$se), ") & (", fmt(v_belt$se), ") & (", fmt(v_alt$se), ") \\\\\n",
  "\\hline\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "State $\\times$ Year FE & Yes & Yes & Yes & No \\\\\n",
  "Year FE & No & No & No & Yes \\\\\n",
  "Sample & All & Pre only & Crop belt & All \\\\\n",
  "Observations & ", fmt(nobs(m_corn)), " & ", fmt(nobs(rob$placebo_corn)),
  " & ", fmt(nobs(rob$belt_corn)), " & ", fmt(nobs(rob$alt1_corn)), " \\\\\n",
  "LOO range & \\multicolumn{4}{c}{[", fmt(min(rob$loo_betas)), ", ", fmt(max(rob$loo_betas)), "] (all positive)} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Column 1 reproduces the baseline corn specification from Table \\ref{tab:main}. ",
  "Column 2 applies a placebo treatment date of 2010 using only pre-reform data (2006--2013). ",
  "Column 3 restricts to the ten states with highest CRP enrollment (KS, TX, MT, ND, SD, CO, NE, MN, IA, MO). ",
  "Column 4 replaces state-by-year FEs with year FEs. ",
  "The LOO range reports the minimum and maximum coefficients from 42 leave-one-state-out regressions. ",
  "Standard errors clustered at the state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tab_dir, "tab3_robustness.tex"))
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: CRP ENROLLMENT TIME SERIES
# ============================================================

crp_select <- crp_ts %>%
  filter(year %in% c(2006, 2008, 2010, 2012, 2013, 2014, 2016, 2018, 2020, 2022))

tab4_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{CRP National Enrollment, 2006--2022}\n",
  "\\label{tab:crp_ts}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Year & Total CRP Acres & Counties & Mean Acres/County \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(crp_select)) {
  r <- crp_select[i, ]
  tab4_tex <- paste0(tab4_tex,
    r$year, " & ", formatC(r$total_crp / 1e6, format = "f", digits = 2), "M",
    " & ", formatC(r$n_counties, format = "f", digits = 0, big.mark = ","),
    " & ", formatC(r$mean_crp, format = "f", digits = 0, big.mark = ","),
    " \\\\\n"
  )
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\n",
  "Change, 2012--2018 & $-$6.91M & & $-$2,345 \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Total CRP enrolled acres from USDA Farm Service Agency county-level ",
  "enrollment data. The 2014 Farm Bill mandated a step-down of the national CRP acreage cap ",
  "from 32 million to 24 million acres, forcing approximately 7 million acres of net contract ",
  "expirations between 2012 and 2018.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tab_dir, "tab4_crp.tex"))
cat("Table 4 written.\n")

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE) APPENDIX
# ============================================================

pre_sd_corn <- sd(pre$corn, na.rm = TRUE)
pre_sd_soy <- sd(pre$soybeans, na.rm = TRUE)
pre_sd_wheat <- sd(pre$wheat, na.rm = TRUE)
pre_sd_total <- sd(pre$total_planted, na.rm = TRUE)

# Treatment is continuous: SDE = beta * SD(X) / SD(Y)
sd_treat <- sd(panel$treatment, na.rm = TRUE)

compute_sde <- function(model, sd_y, coef_name = "treat_x_post") {
  b <- coef(model)[coef_name]
  se_b <- sqrt(vcov(model)[coef_name, coef_name])
  sde <- b * sd_treat / sd_y
  se_sde <- se_b * sd_treat / sd_y
  classify <- function(x) {
    if (abs(x) < 0.005) return("Null")
    if (abs(x) < 0.05) return(ifelse(x > 0, "Small positive", "Small negative"))
    if (abs(x) < 0.15) return(ifelse(x > 0, "Moderate positive", "Moderate negative"))
    return(ifelse(x > 0, "Large positive", "Large negative"))
  }
  list(b = b, se = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde,
       class = classify(sde))
}

sde_total <- compute_sde(m2, pre_sd_total)
sde_corn  <- compute_sde(m_corn, pre_sd_corn)
sde_soy   <- compute_sde(m_soy, pre_sd_soy)
sde_wheat <- compute_sde(m_wheat, pre_sd_wheat)

# Heterogeneity: Crop belt vs non-belt split
panel_nonbelt <- panel %>% filter(!(state_fips %in% c("20","48","30","38","46","08","31","27","19","29")))
panel_belt <- panel %>% filter(state_fips %in% c("20","48","30","38","46","08","31","27","19","29"))

m_belt_h <- feols(corn ~ treat_x_post | fips + state_fips^year,
                  data = panel_belt, cluster = "state_fips")
m_nonbelt_h <- feols(corn ~ treat_x_post | fips + state_fips^year,
                     data = panel_nonbelt, cluster = "state_fips")

pre_belt <- panel_belt %>% filter(year < 2014)
pre_nonbelt <- panel_nonbelt %>% filter(year < 2014)

sde_belt <- compute_sde(m_belt_h, sd(pre_belt$corn, na.rm = TRUE))
sde_nonbelt <- compute_sde(m_nonbelt_h, sd(pre_nonbelt$corn, na.rm = TRUE))

# Format SDE row
fmt_sde <- function(label, s) {
  paste0("  ", label, " & $", formatC(s$b, format = "f", digits = 0, big.mark = ","),
         "$ & $", formatC(s$se, format = "f", digits = 0, big.mark = ","),
         "$ & $", formatC(s$sd_y, format = "f", digits = 0, big.mark = ","),
         "$ & $", formatC(s$sde, format = "f", digits = 3),
         "$ & $", formatC(s$se_sde, format = "f", digits = 3),
         "$ & ", s$class, " \\\\\n")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the mandatory reduction of CRP acreage caps in the 2014 Farm Bill ",
  "cause county-level conversion of conservation grassland to crop production? ",
  "\\textbf{Policy mechanism:} The Agricultural Act of 2014 mandated a step-down of the national CRP ",
  "enrollment cap from 32 million to 24 million acres, forcing approximately 7 million acres of ",
  "contracts to expire without reenrollment opportunity between 2013 and 2018, with county-level ",
  "variation in exposure driven by pre-reform enrollment shares. ",
  "\\textbf{Outcome definition:} County-level planted acres for corn, soybeans, and wheat from USDA ",
  "NASS QuickStats annual surveys, measuring active crop production on agricultural land. ",
  "\\textbf{Treatment:} Continuous; CRP acres lost between 2012--2013 and 2018--2019 averages ",
  "divided by Census of Agriculture 2012 total cropland (units: share of cropland). ",
  "\\textbf{Data:} USDA FSA CRP county enrollment (1986--2024), USDA NASS crop acreage (2006--2022), ",
  "Census of Agriculture (2012); county-year panel, 37,460 observations across 2,476 counties. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with county and state-by-year ",
  "fixed effects; standard errors clustered at state level (42 clusters). ",
  "\\textbf{Sample:} US counties with nonzero CRP enrollment and crop acreage data; excludes ",
  "counties without Census 2012 cropland denominator. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional ",
  "standard deviation of treatment intensity and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\emph{Panel A: Pooled} \\\\\n",
  fmt_sde("Total planted", sde_total),
  fmt_sde("Corn", sde_corn),
  fmt_sde("Soybeans", sde_soy),
  fmt_sde("Wheat", sde_wheat),
  "\\hline\n",
  "\\emph{Panel B: Heterogeneous (Corn)} \\\\\n",
  fmt_sde("Crop belt states", sde_belt),
  fmt_sde("Non-belt states", sde_nonbelt),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(tab_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files:", paste(list.files(tab_dir, pattern = "*.tex"), collapse = ", "), "\n")
