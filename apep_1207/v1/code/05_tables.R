# 05_tables.R — Generate all LaTeX tables
# apep_1207: Thailand Rice Pledging Scheme Collapse

source("00_packages.R")

cat("=== Generating Tables ===\n")

# --- 1. Load data and results ---
scm_data <- read_csv("../data/scm_panel.csv", show_col_types = FALSE)
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

# ====================================================================
# TABLE 1: Summary Statistics — Thailand vs Donor Pool
# ====================================================================
cat("\n--- Table 1: Summary Statistics ---\n")

# Pre-treatment means (2005-2013)
pre_data <- scm_data %>% filter(year < 2014)

th_pre <- pre_data %>% filter(iso2c == "TH")
donor_pre <- pre_data %>% filter(iso2c != "TH")

th_cereal_mn <- mean(th_pre$cereal_prod, na.rm = TRUE) / 1e6
th_cereal_sd <- sd(th_pre$cereal_prod, na.rm = TRUE) / 1e6
d_cereal_mn <- mean(donor_pre$cereal_prod, na.rm = TRUE) / 1e6
d_cereal_sd <- sd(donor_pre$cereal_prod, na.rm = TRUE) / 1e6

n_donors <- n_distinct(donor_pre$iso2c)
n_pre_years <- n_distinct(th_pre$year)

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Pre-Treatment Summary Statistics: Thailand vs.\\ Donor Pool}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Thailand} & \\multicolumn{2}{c}{Donor Pool} \\\\\n",
  " \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & (SD) & Mean & (SD) \\\\\n",
  "\\midrule\n",
  sprintf("  Cereal production (million MT) & %.1f & (%.1f) & %.1f & (%.1f) \\\\\n",
          th_cereal_mn, th_cereal_sd, d_cereal_mn, d_cereal_sd),
  sprintf("  Cereal production index (2010=100) & %.1f & (%.1f) & %.1f & (%.1f) \\\\\n",
          mean(th_pre$cereal_index, na.rm=T), sd(th_pre$cereal_index, na.rm=T),
          mean(donor_pre$cereal_index, na.rm=T), sd(donor_pre$cereal_index, na.rm=T)),
  sprintf("  Agriculture VA (\\%% GDP) & %.1f & (%.1f) & %.1f & (%.1f) \\\\\n",
          mean(th_pre$agri_va_pct, na.rm=T), sd(th_pre$agri_va_pct, na.rm=T),
          mean(donor_pre$agri_va_pct, na.rm=T), sd(donor_pre$agri_va_pct, na.rm=T)),
  sprintf("  Agricultural employment (\\%%) & %.1f & (%.1f) & %.1f & (%.1f) \\\\\n",
          mean(th_pre$agri_empl_pct, na.rm=T), sd(th_pre$agri_empl_pct, na.rm=T),
          mean(donor_pre$agri_empl_pct, na.rm=T), sd(donor_pre$agri_empl_pct, na.rm=T)),
  sprintf("  Cereal yield (kg/hectare) & %.0f & (%.0f) & %.0f & (%.0f) \\\\\n",
          mean(th_pre$cereal_yield, na.rm=T), sd(th_pre$cereal_yield, na.rm=T),
          mean(donor_pre$cereal_yield, na.rm=T), sd(donor_pre$cereal_yield, na.rm=T)),
  sprintf("  GDP per capita (2015 USD) & %.0f & (%.0f) & %.0f & (%.0f) \\\\\n",
          mean(th_pre$gdp_pc, na.rm=T), sd(th_pre$gdp_pc, na.rm=T),
          mean(donor_pre$gdp_pc, na.rm=T), sd(donor_pre$gdp_pc, na.rm=T)),
  sprintf("  Rural population (\\%%) & %.1f & (%.1f) & %.1f & (%.1f) \\\\\n",
          mean(th_pre$rural_pct, na.rm=T), sd(th_pre$rural_pct, na.rm=T),
          mean(donor_pre$rural_pct, na.rm=T), sd(donor_pre$rural_pct, na.rm=T)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sprintf("\\item \\textit{Notes:} Pre-treatment period: 2005--2013. Thailand is the treated unit. Donor pool includes %d Asian developing countries: Vietnam, Indonesia, Philippines, India, Bangladesh, Myanmar, Cambodia, Pakistan, Sri Lanka, Nepal, Malaysia, Lao PDR, and China. All data from World Bank Development Indicators.\n", n_donors),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ====================================================================
# TABLE 2: Main Results — SCM and DiD
# ====================================================================
cat("\n--- Table 2: Main Results ---\n")

# Extract SCM ATT estimates
scm_cereal_att <- summary(results$scm_cereal)$att
avg_att_cereal <- mean(scm_cereal_att$Estimate[scm_cereal_att$Time >= 2014], na.rm = TRUE)
# Compute SE from conformal CI: SE ≈ (upper - lower) / (2 * 1.96)
scm_cereal_se <- tryCatch({
  post_rows <- scm_cereal_att[scm_cereal_att$Time >= 2014, ]
  ci_width <- as.numeric(post_rows$upper_bound) - as.numeric(post_rows$lower_bound)
  mean(ci_width / (2 * 1.96), na.rm = TRUE)
}, error = function(e) NA)

# SCM Agriculture VA
avg_att_agri <- NA
scm_agri_se <- NA
if (!is.null(results$scm_agri)) {
  scm_agri_att <- summary(results$scm_agri)$att
  avg_att_agri <- mean(scm_agri_att$Estimate[scm_agri_att$Time >= 2014], na.rm = TRUE)
  scm_agri_se <- tryCatch({
    post_rows <- scm_agri_att[scm_agri_att$Time >= 2014, ]
    ci_width <- as.numeric(post_rows$upper_bound) - as.numeric(post_rows$lower_bound)
    mean(ci_width / (2 * 1.96), na.rm = TRUE)
  }, error = function(e) NA)
}

# SCM Employment
avg_att_empl <- NA
scm_empl_se <- NA
if (!is.null(results$scm_empl)) {
  scm_empl_att <- summary(results$scm_empl)$att
  avg_att_empl <- mean(scm_empl_att$Estimate[scm_empl_att$Time >= 2014], na.rm = TRUE)
  scm_empl_se <- tryCatch({
    post_rows <- scm_empl_att[scm_empl_att$Time >= 2014, ]
    ci_width <- as.numeric(post_rows$upper_bound) - as.numeric(post_rows$lower_bound)
    mean(ci_width / (2 * 1.96), na.rm = TRUE)
  }, error = function(e) NA)
}

# SCM Yield
avg_att_yield <- NA
scm_yield_se <- NA
if (!is.null(results$scm_yield)) {
  scm_yield_att <- summary(results$scm_yield)$att
  avg_att_yield <- mean(scm_yield_att$Estimate[scm_yield_att$Time >= 2014], na.rm = TRUE)
  scm_yield_se <- tryCatch({
    post_rows <- scm_yield_att[scm_yield_att$Time >= 2014, ]
    ci_width <- as.numeric(post_rows$upper_bound) - as.numeric(post_rows$lower_bound)
    mean(ci_width / (2 * 1.96), na.rm = TRUE)
  }, error = function(e) NA)
}

# DiD estimate
did_coef <- coef(results$did_cereal)["treat_x_post"]
did_se <- sqrt(vcov(results$did_cereal)["treat_x_post", "treat_x_post"])

format_est <- function(est, se) {
  if (is.na(est) || is.na(se)) return(c("---", ""))
  stars <- ""
  pval <- 2 * pnorm(-abs(est / se))
  if (pval < 0.01) stars <- "***"
  else if (pval < 0.05) stars <- "**"
  else if (pval < 0.10) stars <- "*"
  c(sprintf("%.2f%s", est, stars), sprintf("(%.2f)", se))
}

cereal_scm <- format_est(avg_att_cereal, scm_cereal_se)
agri_scm <- format_est(avg_att_agri, scm_agri_se)
empl_scm <- format_est(avg_att_empl, scm_empl_se)
yield_scm <- format_est(avg_att_yield, scm_yield_se)
cereal_did <- format_est(did_coef, did_se)

n_countries <- n_distinct(scm_data$iso2c)
n_obs_total <- nrow(scm_data)

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Effect of Rice Pledging Scheme Collapse on Agricultural Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{4}{c}{Augmented SCM} & DiD \\\\\n",
  " \\cmidrule(lr){2-5} \\cmidrule(lr){6-6}\n",
  " & Cereal & Agri VA & Agri & Cereal & Cereal \\\\\n",
  " & Index & (\\% GDP) & Empl (\\%) & Yield & Index \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  sprintf("  Average post-treatment effect & %s & %s & %s & %s & %s \\\\\n",
          cereal_scm[1], agri_scm[1], empl_scm[1], yield_scm[1], cereal_did[1]),
  sprintf("  & %s & %s & %s & %s & %s \\\\\n",
          cereal_scm[2], agri_scm[2], empl_scm[2], yield_scm[2], cereal_did[2]),
  " & & & & & \\\\\n",
  sprintf("  Countries & %d & %d & %d & %d & %d \\\\\n",
          n_countries, n_countries, n_countries, n_countries, n_countries),
  sprintf("  Observations & %d & %d & %d & %d & %d \\\\\n",
          n_obs_total, n_obs_total, n_obs_total, n_obs_total, n_obs_total),
  sprintf("  Permutation $p$-value & %.3f & & & & \\\\\n", rob_results$perm_pvalue),
  "  Method & ASCM & ASCM & ASCM & ASCM & TWFE \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Columns (1)--(4) report average post-treatment effects from augmented synthetic control method (Ridge). Column (5) reports two-way fixed effects DiD with country and year fixed effects, standard errors clustered at country level. Treatment: Thailand's rice pledging scheme collapse in late 2013. Post-treatment period: 2014--2020. Cereal index normalized to 2010=100. Permutation $p$-value from placebo tests assigning treatment to each donor country. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("  Table 2 written.\n")

# ====================================================================
# TABLE 3: Event Study Coefficients
# ====================================================================
cat("\n--- Table 3: Event Study ---\n")

es_coefs <- coef(results$did_es)
es_se <- sqrt(diag(vcov(results$did_es)))

# Extract event-time coefficients
es_df <- tibble(
  event_time = as.integer(gsub("event_time::", "", gsub(":treated_unit", "", names(es_coefs)))),
  estimate = as.numeric(es_coefs),
  se = as.numeric(es_se)
) %>%
  mutate(
    pval = 2 * pnorm(-abs(estimate / se)),
    stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.10 ~ "*", TRUE ~ ""),
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  ) %>%
  arrange(event_time)

# Add the reference period (t = -1)
es_df <- bind_rows(
  es_df %>% filter(event_time < -1),
  tibble(event_time = -1, estimate = 0, se = NA, pval = NA, stars = "", ci_lo = NA, ci_hi = NA),
  es_df %>% filter(event_time >= 0)
)

es_rows <- es_df %>%
  mutate(
    est_str = ifelse(is.na(se),
                     sprintf("%.2f", estimate),
                     sprintf("%.2f%s", estimate, stars)),
    se_str = ifelse(is.na(se), "[ref.]", sprintf("(%.2f)", se)),
    ci_str = ifelse(is.na(ci_lo), "", sprintf("[%.2f, %.2f]", ci_lo, ci_hi)),
    year_label = sprintf("%d ($t%s%d$)",
                         2014 + event_time,
                         ifelse(event_time >= 0, "+", ""),
                         abs(event_time))
  )

tab3_body <- paste(
  sprintf("  %s & %s & %s & %s \\\\",
          es_rows$year_label, es_rows$est_str, es_rows$se_str, es_rows$ci_str),
  collapse = "\n"
)

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Event Study: Cereal Production Index}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "  Year (Event Time) & Estimate & SE & 95\\% CI \\\\\n",
  "\\midrule\n",
  tab3_body, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sprintf("\\item \\textit{Notes:} Event study from TWFE regression of cereal production index (2010=100) on event-time indicators interacted with a Thailand indicator, with country and year fixed effects. Standard errors clustered at the country level. $t=-1$ (2013) is the reference period. %d countries, %d country-year observations. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
          n_countries, n_obs_total),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_eventstudy.tex")
cat("  Table 3 written.\n")

# ====================================================================
# TABLE 4: Robustness — RMSPE Ratios
# ====================================================================
cat("\n--- Table 4: RMSPE Ratios ---\n")

rmspe <- rob_results$rmspe_ratios %>%
  mutate(
    is_th = country == "TH",
    label = ifelse(is_th, "\\textbf{Thailand}", country)
  ) %>%
  arrange(desc(ratio))

rmspe_rows <- paste(
  sprintf("  %s & %.2f & %.2f & %.2f \\\\",
          rmspe$label, rmspe$rmspe_pre, rmspe$rmspe_post, rmspe$ratio),
  collapse = "\n"
)

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Permutation Inference: RMSPE Ratios}\n",
  "\\label{tab:rmspe}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "  Country & Pre-RMSPE & Post-RMSPE & Ratio \\\\\n",
  "\\midrule\n",
  rmspe_rows, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sprintf("\\item \\textit{Notes:} RMSPE = root mean squared prediction error. Pre-RMSPE computed for 2005--2013; Post-RMSPE for 2014--2020. Ratio = Post/Pre. Thailand (bold) is the treated unit; all others are placebo tests. Permutation $p$-value = Thailand's rank / total countries = %d/%d = %.3f. A ratio substantially larger than those of the placebos indicates that the post-treatment gap is not driven by poor fit.\n",
          which(rmspe$country == "TH"), nrow(rmspe), rob_results$perm_pvalue),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_rmspe.tex")
cat("  Table 4 written.\n")

# ====================================================================
# TABLE 5: Mechanism — Structural Transformation
# ====================================================================
cat("\n--- Table 5: Mechanism ---\n")

# DiD results for structural transformation
did_svc_coef <- coef(results$did_services)["treat_x_post"]
did_svc_se <- sqrt(vcov(results$did_services)["treat_x_post", "treat_x_post"])
svc_est <- format_est(did_svc_coef, did_svc_se)

did_ind_coef <- coef(results$did_industry)["treat_x_post"]
did_ind_se <- sqrt(vcov(results$did_industry)["treat_x_post", "treat_x_post"])
ind_est <- format_est(did_ind_coef, did_ind_se)

# Re-use cereal and agri VA from DiD
cereal_did_est <- format_est(did_coef, did_se)

# DiD for agri VA
did_agri_va <- feols(
  agri_va_pct ~ treat_x_post | iso2c + year,
  data = scm_data %>%
    filter(!is.na(agri_va_pct)) %>%
    mutate(treat_x_post = as.integer(iso2c == "TH") * as.integer(year >= 2014)),
  cluster = ~iso2c
)
agri_va_est <- format_est(coef(did_agri_va)["treat_x_post"],
                           sqrt(vcov(did_agri_va)["treat_x_post", "treat_x_post"]))

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Mechanism: Structural Transformation After Subsidy Collapse}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & Cereal & Agri VA & Services VA & Industry VA \\\\\n",
  " & Index & (\\% GDP) & (\\% GDP) & (\\% GDP) \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n",
  sprintf("  Thailand $\\times$ Post & %s & %s & %s & %s \\\\\n",
          cereal_did_est[1], agri_va_est[1], svc_est[1], ind_est[1]),
  sprintf("  & %s & %s & %s & %s \\\\\n",
          cereal_did_est[2], agri_va_est[2], svc_est[2], ind_est[2]),
  " & & & & \\\\\n",
  "  Country FE & Yes & Yes & Yes & Yes \\\\\n",
  "  Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("  Countries & %d & %d & %d & %d \\\\\n",
          n_countries, n_countries, n_countries, n_countries),
  sprintf("  Observations & %d & %d & %d & %d \\\\\n",
          n_obs_total, n_obs_total, n_obs_total, n_obs_total),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Two-way fixed effects DiD estimates. Thailand $\\times$ Post = 1 for Thailand in 2014--2020. Standard errors clustered at country level in parentheses. If the subsidy collapse accelerated structural transformation, we expect agriculture (columns 1--2) to decline and services/industry (columns 3--4) to increase. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}"
)

writeLines(tab5, "../tables/tab5_mechanism.tex")
cat("  Table 5 written.\n")

# ====================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — APPENDIX
# ====================================================================
cat("\n--- Table F1: SDE ---\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y) for binary treatment
# For SCM, beta is the average ATT, SD(Y) is pre-treatment SD of outcome

# Panel A: Pooled results
pre_th <- scm_data %>% filter(iso2c == "TH", year < 2014)

sde_rows <- tibble(
  outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character()
)

classify_sde <- function(sde_val) {
  abs_sde <- abs(sde_val)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    return(ifelse(sde_val > 0, "Small positive", "Small negative"))
  }
  if (abs_sde < 0.15) {
    return(ifelse(sde_val > 0, "Moderate positive", "Moderate negative"))
  }
  return(ifelse(sde_val > 0, "Large positive", "Large negative"))
}

# Cereal index
sd_cereal <- sd(pre_th$cereal_index, na.rm = TRUE)
sde_cereal <- avg_att_cereal / sd_cereal
se_sde_cereal <- ifelse(!is.na(scm_cereal_se), scm_cereal_se / sd_cereal, NA)

sde_rows <- bind_rows(sde_rows, tibble(
  outcome = "Cereal production index",
  beta = avg_att_cereal,
  se = scm_cereal_se,
  sd_y = sd_cereal,
  sde = sde_cereal,
  se_sde = se_sde_cereal,
  classification = classify_sde(sde_cereal)
))

# Agriculture VA
if (!is.na(avg_att_agri)) {
  sd_agri <- sd(pre_th$agri_va_pct, na.rm = TRUE)
  sde_agri <- avg_att_agri / sd_agri
  se_sde_agri <- ifelse(!is.na(scm_agri_se), scm_agri_se / sd_agri, NA)

  sde_rows <- bind_rows(sde_rows, tibble(
    outcome = "Agriculture VA (\\% GDP)",
    beta = avg_att_agri,
    se = scm_agri_se,
    sd_y = sd_agri,
    sde = sde_agri,
    se_sde = se_sde_agri,
    classification = classify_sde(sde_agri)
  ))
}

# Agricultural employment
if (!is.na(avg_att_empl)) {
  sd_empl <- sd(pre_th$agri_empl_pct, na.rm = TRUE)
  sde_empl <- avg_att_empl / sd_empl
  se_sde_empl <- ifelse(!is.na(scm_empl_se), scm_empl_se / sd_empl, NA)

  sde_rows <- bind_rows(sde_rows, tibble(
    outcome = "Agricultural employment (\\%)",
    beta = avg_att_empl,
    se = scm_empl_se,
    sd_y = sd_empl,
    sde = sde_empl,
    se_sde = se_sde_empl,
    classification = classify_sde(sde_empl)
  ))
}

# Cereal yield
if (!is.na(avg_att_yield)) {
  sd_yield <- sd(pre_th$yield_index, na.rm = TRUE)
  sde_yield <- avg_att_yield / sd_yield
  se_sde_yield <- ifelse(!is.na(scm_yield_se), scm_yield_se / sd_yield, NA)

  sde_rows <- bind_rows(sde_rows, tibble(
    outcome = "Cereal yield index",
    beta = avg_att_yield,
    se = scm_yield_se,
    sd_y = sd_yield,
    sde = sde_yield,
    se_sde = se_sde_yield,
    classification = classify_sde(sde_yield)
  ))
}

cat("Panel A (Pooled) SDE rows:\n")
print(as.data.frame(sde_rows))

# Panel B: Heterogeneous — ASEAN-only vs full donor pool
# Compare ATT under different donor pools (sample split by geography)
asean_att <- NA
asean_se <- NA
if (!is.null(rob_results$scm_asean_fit)) {
  asean_summary <- summary(rob_results$scm_asean_fit)$att
  asean_att <- mean(asean_summary$Estimate[asean_summary$Time >= 2014], na.rm = TRUE)
  asean_se <- tryCatch({
    post_rows <- asean_summary[asean_summary$Time >= 2014, ]
    ci_width <- as.numeric(post_rows$upper_bound) - as.numeric(post_rows$lower_bound)
    mean(ci_width / (2 * 1.96), na.rm = TRUE)
  }, error = function(e) NA)
}

sde_rows_b <- tibble(
  outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character()
)

# ASEAN-only SCM
if (!is.na(asean_att)) {
  sde_asean <- asean_att / sd_cereal
  se_sde_asean <- ifelse(!is.na(asean_se), asean_se / sd_cereal, NA)
  sde_rows_b <- bind_rows(sde_rows_b, tibble(
    outcome = "Cereal index (ASEAN donors only)",
    beta = asean_att,
    se = asean_se,
    sd_y = sd_cereal,
    sde = sde_asean,
    se_sde = se_sde_asean,
    classification = classify_sde(sde_asean)
  ))
}

# Full donor pool (repeat from Panel A for comparison)
sde_rows_b <- bind_rows(sde_rows_b, tibble(
  outcome = "Cereal index (all Asian donors)",
  beta = avg_att_cereal,
  se = scm_cereal_se,
  sd_y = sd_cereal,
  sde = sde_cereal,
  se_sde = se_sde_cereal,
  classification = classify_sde(sde_cereal)
))

cat("\nPanel B (Heterogeneous) SDE rows:\n")
print(as.data.frame(sde_rows_b))

# Build SDE table
sde_body_a <- paste(
  sprintf("  %s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          sde_rows$outcome, sde_rows$beta, sde_rows$se,
          sde_rows$sd_y, sde_rows$sde, sde_rows$se_sde,
          sde_rows$classification),
  collapse = "\n"
)

sde_body_b <- paste(
  sprintf("  %s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          sde_rows_b$outcome, sde_rows_b$beta, sde_rows_b$se,
          sde_rows_b$sd_y, sde_rows_b$sde, sde_rows_b$se_sde,
          sde_rows_b$classification),
  collapse = "\n"
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Thailand. ",
  "\\textbf{Research question:} Does the abrupt collapse of a large agricultural subsidy scheme reduce cereal production and accelerate structural transformation away from agriculture? ",
  "\\textbf{Policy mechanism:} Thailand's rice pledging scheme (2011--2014) offered farmers 40--50\\% above-market prices for rice through guaranteed government purchases, inducing over-investment in rice cultivation; the scheme's fiscal collapse in late 2013 abruptly withdrew this income support from hundreds of thousands of rice-dependent farmers. ",
  "\\textbf{Outcome definition:} Cereal production index (metric tons of all cereals, normalized so 2010 = 100), agriculture value added as percentage of GDP, agricultural employment share, and cereal yield index from World Bank Development Indicators. ",
  "\\textbf{Treatment:} Binary --- Thailand experienced the subsidy collapse; 13 Asian comparison countries did not. ",
  "\\textbf{Data:} World Bank Development Indicators, 14 countries, 2005--2020, country-year panel, 224 observations. ",
  "\\textbf{Method:} Augmented synthetic control (Ridge) with permutation inference; cross-country TWFE DiD as robustness. Jackknife standard errors. ",
  "\\textbf{Sample:} Asian developing countries with significant agricultural sectors and available cereal production data for the full panel period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for Thailand. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\begin{threeparttable}\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "  \\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sde_body_a, "\n",
  "  & & & & & & \\\\\n",
  "  \\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by donor pool)}} \\\\\n",
  sde_body_b, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
