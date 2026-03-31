# 05_tables.R — Generate all LaTeX tables including SDE appendix

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
panel <- fread("../data/analysis_panel.csv")
asian_share <- fread("../data/state_asian_share.csv")

dir.create("../tables", showWarnings = FALSE)

# ════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ════════════════════════════════════════════════════════════

pre <- panel[yrqtr < 2020]
post <- panel[yrqtr >= 2020]

groups <- CJ(race = c("A1", "A4"), sector_type = c("customer_facing", "knowledge"))
groups[, label := paste0(
  fifelse(race == "A4", "Asian", "White"), ", ",
  fifelse(sector_type == "customer_facing", "Customer-facing", "Knowledge")
)]

build_row <- function(dt, grp) {
  sub <- dt[race == grp$race & sector_type == grp$sector_type]
  list(
    mean_emp = mean(sub$emp, na.rm = TRUE),
    sd_emp = sd(sub$emp, na.rm = TRUE),
    mean_earn = mean(sub$avg_earnings, na.rm = TRUE),
    n = nrow(sub)
  )
}

sink("../tables/tab1_summary.tex")
cat("\\begin{table}[t]\n\\centering\n\\caption{Summary Statistics: Employment by Race and Sector}\n\\label{tab:summary}\n\\small\n")
cat("\\begin{threeparttable}\n\\begin{tabular}{lrrrr}\n\\toprule\n")
cat("Group & Mean Emp & SD Emp & Mean Earn (\\$) & N \\\\\n\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Pre-COVID (2016Q1--2019Q4)}} \\\\\n")
for (i in 1:nrow(groups)) {
  r <- build_row(pre, groups[i])
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              groups[i]$label,
              format(round(r$mean_emp), big.mark = ","),
              format(round(r$sd_emp), big.mark = ","),
              format(round(r$mean_earn), big.mark = ","),
              format(r$n, big.mark = ",")))
}
cat("\\midrule\n\\multicolumn{5}{l}{\\textit{Panel B: Post-COVID (2020Q1--2024Q4)}} \\\\\n")
for (i in 1:nrow(groups)) {
  r <- build_row(post, groups[i])
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              groups[i]$label,
              format(round(r$mean_emp), big.mark = ","),
              format(round(r$sd_emp), big.mark = ","),
              format(round(r$mean_earn), big.mark = ","),
              format(r$n, big.mark = ",")))
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n\\item \\textit{Notes:} QWI data from Census Bureau, 2016--2024. Customer-facing: NAICS 72 (Accommodation \\& Food Services) and 44--45 (Retail). Knowledge: NAICS 54 (Professional Services) and 51 (Information). Employment is quarterly state-level totals. Earnings are average quarterly earnings for full-quarter (stable) workers.\n\\end{tablenotes}\n")
cat("\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 1 written.\n")

# ════════════════════════════════════════════════════════════
# TABLE 2: Main DDD Results
# ════════════════════════════════════════════════════════════

get_coef <- function(m, pattern = NULL) {
  ct <- coeftable(m)
  if (!is.null(pattern)) {
    idx <- grep(pattern, rownames(ct))[1]
  } else {
    idx <- 1
  }
  list(est = ct[idx, 1], se = ct[idx, 2], pval = ct[idx, 4],
       stars = ifelse(ct[idx, 4] < 0.01, "***", ifelse(ct[idx, 4] < 0.05, "**",
                      ifelse(ct[idx, 4] < 0.1, "*", ""))),
       n = nobs(m))
}

m1c <- get_coef(results$m1)
m2c <- get_coef(results$m2)
m3c <- get_coef(results$m3)
m4c <- get_coef(results$m4)
m5c <- get_coef(results$m5)

sink("../tables/tab2_ddd.tex")
cat("\\begin{table}[t]\n\\centering\n\\caption{Anti-Asian Sentiment and Sectoral Employment: Triple-Difference Results}\n\\label{tab:ddd}\n\\small\n")
cat("\\begin{threeparttable}\n\\begin{tabular}{lcccc}\n\\toprule\n")
cat(" & \\multicolumn{4}{c}{Dependent variable} \\\\\n\\cmidrule(lr){2-5}\n")
cat(" & Log Emp & Log Hires & Log Sep & Log Earnings \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n\\midrule\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Binary DDD}} \\\\\n")
cat(sprintf("Asian $\\times$ CF $\\times$ Post & %.3f%s & & & \\\\\n", m1c$est, m1c$stars))
cat(sprintf(" & (%.3f) & & & \\\\\n", m1c$se))
cat("\\midrule\n\\multicolumn{5}{l}{\\textit{Panel B: Continuous DDD (Asian pop.\\ share)}} \\\\\n")
cat(sprintf("Asian $\\times$ CF $\\times$ Post $\\times$ Share & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            m2c$est, m2c$stars, m3c$est, m3c$stars, m4c$est, m4c$stars, m5c$est, m5c$stars))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            m2c$se, m3c$se, m4c$se, m5c$se))
cat("\\midrule\n")
cat("State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Race $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\\n")
cat("State $\\times$ Sector FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Race $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(m2c$n, big.mark = ","), format(m3c$n, big.mark = ","),
            format(m4c$n, big.mark = ","), format(m5c$n, big.mark = ",")))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Panel A reports the triple-difference coefficient: Asian (vs.\\ White) $\\times$ customer-facing (vs.\\ knowledge) sectors $\\times$ post-COVID (2020Q1+). Panel B adds a fourth interaction with standardized pre-COVID Asian population share (2019 ACS 5-Year). Standard errors clustered at the state level in parentheses. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, and 10\\%.\n\\end{tablenotes}\n")
cat("\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 2 written.\n")

# ════════════════════════════════════════════════════════════
# TABLE 3: Event Study
# ════════════════════════════════════════════════════════════

es <- results$es_coefs[order(event_time)]
# Select key quarters for display
key_ets <- c(-12, -8, -4, -2, -1, 0, 1, 2, 4, 8, 12, 16, 19)
es_disp <- es[event_time %in% key_ets]

# Convert event_time to calendar quarter label
et_to_cal <- function(et) {
  yr <- 2020 + (et %/% 4)
  q <- (et %% 4) + 1
  if (et < 0) {
    yr <- 2020 + floor(et / 4)
    q <- ((et %% 4) + 4) %% 4 + 1
  }
  sprintf("%dQ%d", yr, q)
}

sink("../tables/tab3_eventstudy.tex")
cat("\\begin{table}[t]\n\\centering\n\\caption{Event Study: DDD Coefficients for Log Employment}\n\\label{tab:event_study}\n\\small\n")
cat("\\begin{threeparttable}\n\\begin{tabular}{lccl}\n\\toprule\n")
cat("Event Time & Coefficient & SE & Calendar \\\\\n\\midrule\n")
for (i in 1:nrow(es_disp)) {
  r <- es_disp[i]
  stars <- ifelse(r$pval < 0.01, "***", ifelse(r$pval < 0.05, "**", ifelse(r$pval < 0.1, "*", "")))
  cal <- et_to_cal(r$event_time)
  if (r$event_time == -1) {
    cat(sprintf("$t = %+d$ & \\multicolumn{2}{c}{(reference)} & %s \\\\\n", r$event_time, cal))
  } else {
    cat(sprintf("$t = %+d$ & %s%s & (%s) & %s \\\\\n",
                r$event_time, sprintf("%.3f", r$estimate), stars, sprintf("%.3f", r$se), cal))
  }
  if (r$event_time == -1) cat("\\midrule\n")
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Each coefficient is the interaction of event-time dummies with Asian $\\times$ customer-facing, from a specification with state$\\times$quarter, race$\\times$sector, state$\\times$sector, and race$\\times$quarter fixed effects. Reference period: 2019Q4 ($t = -1$). Standard errors clustered at the state level. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, and 10\\%.\n\\end{tablenotes}\n")
cat("\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 3 written.\n")

# ════════════════════════════════════════════════════════════
# TABLE 4: Robustness
# ════════════════════════════════════════════════════════════

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[t]\n\\centering\n\\caption{Robustness Checks}\n\\label{tab:robustness}\n\\small\n")
cat("\\begin{threeparttable}\n\\begin{tabular}{lccc}\n\\toprule\n")
cat("Specification & Coefficient & SE & N \\\\\n\\midrule\n")

# Main
cat(sprintf("Main (binary DDD) & %.3f%s & (%.3f) & %s \\\\\n",
            m1c$est, m1c$stars, m1c$se, format(m1c$n, big.mark = ",")))

# Placebo
pc <- get_coef(rob_results$m_placebo)
cat(sprintf("Placebo (2018Q1, pre-COVID only) & %.3f%s & (%.3f) & %s \\\\\n",
            pc$est, pc$stars, pc$se, format(pc$n, big.mark = ",")))

# Exclude
ec <- get_coef(rob_results$m_excl)
cat(sprintf("Excl.\\ CA, NY, HI & %.3f%s & (%.3f) & %s \\\\\n",
            ec$est, ec$stars, ec$se, format(ec$n, big.mark = ",")))

# Level
lc <- get_coef(rob_results$m_level)
cat(sprintf("Level specification & %s%s & (%s) & %s \\\\\n",
            format(round(lc$est), big.mark = ","), lc$stars,
            format(round(lc$se), big.mark = ","),
            format(lc$n, big.mark = ",")))

# Persistence
ct_per <- coeftable(rob_results$m_persist)
for (j in 1:nrow(ct_per)) {
  nm <- ifelse(j == 1, "Early post (2020--2021)", "Late post (2022--2024)")
  stars <- ifelse(ct_per[j, 4] < 0.01, "***", ifelse(ct_per[j, 4] < 0.05, "**",
                  ifelse(ct_per[j, 4] < 0.1, "*", "")))
  cat(sprintf("%s & %.3f%s & (%.3f) & %s \\\\\n",
              nm, ct_per[j, 1], stars, ct_per[j, 2],
              format(nobs(rob_results$m_persist), big.mark = ",")))
}

cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n\\item \\textit{Notes:} Each row reports the triple-interaction coefficient from a variant of the main DDD specification. ``Placebo'' uses only pre-COVID data (2016--2019) with a fake treatment at 2018Q1. ``Excl.\\ CA, NY, HI'' drops the three largest-Asian-population states. ``Level'' uses employment counts rather than logs. ``Early/Late post'' splits the post-treatment period. Standard errors clustered at the state level. $^{***}$, $^{**}$, $^{*}$ denote significance at 1\\%, 5\\%, and 10\\%.\n\\end{tablenotes}\n")
cat("\\end{threeparttable}\n\\end{table}\n")
sink()
cat("Table 4 written.\n")

# ════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Sizes (SDE)
# ════════════════════════════════════════════════════════════

pre_panel <- panel[yrqtr < 2020]
panel[, asian_cf := as.integer(race == "A4") * as.integer(sector_type == "customer_facing")]

classify_sde <- function(x) {
  if (abs(x) < 0.005) return("Null")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x > 0.15) return("Large positive")
  if (x > 0.05) return("Moderate positive")
  return("Small positive")
}

compute_sde <- function(model, outcome_var) {
  ct <- coeftable(model)
  idx <- 1
  beta <- ct[idx, 1]
  se_beta <- ct[idx, 2]
  sd_y <- sd(pre_panel[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  list(beta = beta, se = se_beta, sd_y = sd_y, sde = sde,
       se_sde = se_sde, class = classify_sde(sde))
}

# Panel A: Pooled (use binary DDD model for employment, continuous for others)
sde_emp <- compute_sde(results$m1, "log_emp")

# Hires and separations — need binary DDD versions
m_hires_bin <- feols(log_hires ~ asian_cf:post_covid |
                       state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                     data = panel, cluster = ~state_fips)
m_sep_bin <- feols(log_sep ~ asian_cf:post_covid |
                     state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                   data = panel, cluster = ~state_fips)
m_earn_bin <- feols(log_earn ~ asian_cf:post_covid |
                      state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                    data = panel, cluster = ~state_fips)

sde_hires <- compute_sde(m_hires_bin, "log_hires")
sde_sep <- compute_sde(m_sep_bin, "log_sep")
sde_earn <- compute_sde(m_earn_bin, "log_earn")

# Panel B: Heterogeneous by period
m_early <- feols(log_emp ~ asian_cf:post_covid |
                   state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                 data = panel[yrqtr < 2022], cluster = ~state_fips)
m_late <- feols(log_emp ~ asian_cf:post_covid |
                  state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                data = panel[yrqtr >= 2018], cluster = ~state_fips)

sde_early <- compute_sde(m_early, "log_emp")
sde_late <- compute_sde(m_late, "log_emp")

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did COVID-era conditions disproportionately reduce Asian American employment in customer-facing sectors relative to knowledge-economy sectors and relative to White workers in the same sectors? ",
  "\\textbf{Policy mechanism:} The onset of the COVID-19 pandemic in early 2020 created an abrupt negative shock to customer-facing industries, and the concurrent surge in anti-Asian incidents created hostile conditions disproportionately affecting Asian workers in roles requiring interpersonal contact with the public, potentially accelerating their reallocation to non-customer-facing sectors. ",
  "\\textbf{Outcome definition:} Quarterly state-level employment (Emp), hires (HirA), separations (Sep), and average earnings for stable workers (EarnS) from the Census Bureau Quarterly Workforce Indicators, disaggregated by race and NAICS sector. ",
  "\\textbf{Treatment:} Binary; post-COVID indicator (2020Q1 onward) interacted with Asian race and customer-facing sector indicators. ",
  "\\textbf{Data:} Census QWI (2016--2024); unit of observation is state $\\times$ race $\\times$ sector type $\\times$ quarter; ",
  format(nrow(panel), big.mark = ","), " observations across 51 states. ",
  "\\textbf{Method:} Triple-difference (DDD) with state$\\times$quarter, race$\\times$sector, state$\\times$sector, and race$\\times$quarter fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All 50 states plus DC with non-suppressed QWI employment data for Asian (A4) and White (A1) workers in customer-facing (NAICS 72, 44--45) and knowledge (NAICS 54, 51) sectors. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[t]\n\\centering\n\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n\\small\n")
cat("\\begin{threeparttable}\n\\begin{tabular}{lcccccc}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (s in list(list(sde_emp, "Employment (log)"), list(sde_hires, "Hires (log)"),
               list(sde_sep, "Separations (log)"), list(sde_earn, "Earnings (log)"))) {
  d <- s[[1]]; nm <- s[[2]]
  cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
              nm, d$beta, d$se, d$sd_y, d$sde, d$se_sde, d$class))
}
cat("\\midrule\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by period)}} \\\\\n")
cat(sprintf("Emp: Pandemic (2016--2021) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            sde_early$beta, sde_early$se, sde_early$sd_y, sde_early$sde, sde_early$se_sde, sde_early$class))
cat(sprintf("Emp: Post-pandemic (2018--2024) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            sde_late$beta, sde_late$se, sde_late$sd_y, sde_late$sde, sde_late$se_sde, sde_late$class))
cat("\\bottomrule\n\\end{tabular}\n")
cat(sprintf("\\begin{tablenotes}\\small\n%s\n\\end{tablenotes}\n", sde_notes))
cat("\\end{threeparttable}\n\\end{table}\n")
sink()
cat("SDE table written.\n")

cat("\n=== ALL TABLES GENERATED ===\n")
