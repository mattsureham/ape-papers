## 05_tables.R — Generate all LaTeX tables (manual format for booktabs)
## APEP Working Paper apep_0817

source("00_packages.R")

cat("=== Generating Tables ===\n")

analysis_city <- readRDS("../data/analysis_city.rds")
analysis_disaster <- readRDS("../data/analysis_disaster.rds")
main_results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")

# Helper: format coefficient with stars
fmt_coef <- function(est, se, digits=4) {
  pval <- 2 * pnorm(-abs(est/se))
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.10, "^{*}", "")))
  sprintf("$%s%s$", formatC(est, digits=digits, format="f"), stars)
}

fmt_se <- function(se, digits=4) {
  sprintf("(%s)", formatC(se, digits=digits, format="f"))
}

fmt_n <- function(n) format(as.integer(n), big.mark=",")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

format_num <- function(x, digits=1) {
  ifelse(abs(x) >= 1000,
         format(round(x, 0), big.mark=",", scientific=FALSE),
         formatC(x, digits=digits, format="f"))
}

panel_a <- data.frame(
  Variable = c("Declaration lag (days)", "Concurrent disasters (30d window)",
               "Recent declarations (60d)", "Total registrations",
               "IHP per registrant (\\$)", "Approval rate",
               "Avg.\\ FEMA-inspected damage (\\$)", "Counties affected"),
  Mean = c(mean(analysis_disaster$declaration_lag),
           mean(analysis_disaster$concurrent_disasters),
           mean(analysis_disaster$recent_declarations),
           mean(analysis_disaster$total_registrations),
           mean(analysis_disaster$mean_ihp_per_reg, na.rm=TRUE),
           mean(analysis_disaster$mean_approval_rate, na.rm=TRUE),
           mean(analysis_disaster$mean_damage, na.rm=TRUE),
           mean(analysis_disaster$n_counties)),
  SD = c(sd(analysis_disaster$declaration_lag),
         sd(analysis_disaster$concurrent_disasters),
         sd(analysis_disaster$recent_declarations),
         sd(analysis_disaster$total_registrations),
         sd(analysis_disaster$mean_ihp_per_reg, na.rm=TRUE),
         sd(analysis_disaster$mean_approval_rate, na.rm=TRUE),
         sd(analysis_disaster$mean_damage, na.rm=TRUE),
         sd(analysis_disaster$n_counties)),
  P25 = c(quantile(analysis_disaster$declaration_lag, 0.25),
          quantile(analysis_disaster$concurrent_disasters, 0.25),
          quantile(analysis_disaster$recent_declarations, 0.25),
          quantile(analysis_disaster$total_registrations, 0.25),
          quantile(analysis_disaster$mean_ihp_per_reg, 0.25, na.rm=TRUE),
          quantile(analysis_disaster$mean_approval_rate, 0.25, na.rm=TRUE),
          quantile(analysis_disaster$mean_damage, 0.25, na.rm=TRUE),
          quantile(analysis_disaster$n_counties, 0.25)),
  P75 = c(quantile(analysis_disaster$declaration_lag, 0.75),
          quantile(analysis_disaster$concurrent_disasters, 0.75),
          quantile(analysis_disaster$recent_declarations, 0.75),
          quantile(analysis_disaster$total_registrations, 0.75),
          quantile(analysis_disaster$mean_ihp_per_reg, 0.75, na.rm=TRUE),
          quantile(analysis_disaster$mean_approval_rate, 0.75, na.rm=TRUE),
          quantile(analysis_disaster$mean_damage, 0.75, na.rm=TRUE),
          quantile(analysis_disaster$n_counties, 0.75))
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: FEMA IHP Disasters, 2010--2025}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  " & Mean & SD & P25 & P75 \\\\",
  "\\midrule",
  sprintf("\\multicolumn{5}{l}{\\textit{Panel A: Disaster level} ($N = %d$)} \\\\[3pt]",
          nrow(analysis_disaster))
)

for (i in 1:nrow(panel_a)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            panel_a$Variable[i],
            format_num(panel_a$Mean[i]),
            format_num(panel_a$SD[i]),
            format_num(panel_a$P25[i]),
            format_num(panel_a$P75[i])))
}

n_city <- nrow(analysis_city)
tab1_lines <- c(tab1_lines,
  "\\addlinespace[6pt]",
  sprintf("\\multicolumn{5}{l}{\\textit{Panel B: City--disaster level} ($N = %s$)} \\\\[3pt]",
          format(n_city, big.mark=",")),
  sprintf("IHP per registrant (\\$) & %s & %s & %s & %s \\\\",
          format_num(mean(analysis_city$ihp_per_reg, na.rm=TRUE)),
          format_num(sd(analysis_city$ihp_per_reg, na.rm=TRUE)),
          format_num(quantile(analysis_city$ihp_per_reg, 0.25, na.rm=TRUE)),
          format_num(quantile(analysis_city$ihp_per_reg, 0.75, na.rm=TRUE))),
  sprintf("Approval rate & %s & %s & %s & %s \\\\",
          format_num(mean(analysis_city$approval_rate, na.rm=TRUE), 3),
          format_num(sd(analysis_city$approval_rate, na.rm=TRUE), 3),
          format_num(quantile(analysis_city$approval_rate, 0.25, na.rm=TRUE), 3),
          format_num(quantile(analysis_city$approval_rate, 0.75, na.rm=TRUE), 3)),
  sprintf("FEMA-inspected damage (\\$) & %s & %s & %s & %s \\\\",
          format_num(mean(analysis_city$avg_fema_damage, na.rm=TRUE)),
          format_num(sd(analysis_city$avg_fema_damage, na.rm=TRUE)),
          format_num(quantile(analysis_city$avg_fema_damage, 0.25, na.rm=TRUE)),
          format_num(quantile(analysis_city$avg_fema_damage, 0.75, na.rm=TRUE))),
  sprintf("Valid registrations & %s & %s & %s & %s \\\\",
          format_num(mean(analysis_city$valid_registrations, na.rm=TRUE)),
          format_num(sd(analysis_city$valid_registrations, na.rm=TRUE)),
          format_num(quantile(analysis_city$valid_registrations, 0.25, na.rm=TRUE)),
          format_num(quantile(analysis_city$valid_registrations, 0.75, na.rm=TRUE)))
)

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from OpenFEMA Individual Assistance program, 2010--2025.",
  "Declaration lag is the number of days between incident onset and presidential disaster",
  "declaration. IHP = Individual and Households Program.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ============================================================
# TABLE 2: Main Results (OLS and IV)
# ============================================================
cat("\n--- Table 2: Main Results ---\n")

r <- main_results

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Declaration Lag and Household Assistance: OLS and IV Estimates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & OLS & IV & Alt.~IV & IV & IV \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Dep.~var.: Log IHP per registrant}} \\\\[3pt]",
  sprintf("Declaration lag & %s & %s & %s & %s & %s \\\\",
          fmt_coef(coef(r$city_ols1)["declaration_lag"], se(r$city_ols1)["declaration_lag"], 5),
          fmt_coef(coef(r$city_iv1)["fit_declaration_lag"], se(r$city_iv1)["fit_declaration_lag"], 5),
          fmt_coef(coef(robustness$alt_iv)["fit_declaration_lag"], se(robustness$alt_iv)["fit_declaration_lag"], 5),
          fmt_coef(coef(robustness$no_major)["fit_declaration_lag"], se(robustness$no_major)["fit_declaration_lag"], 5),
          fmt_coef(coef(robustness$no_covid)["fit_declaration_lag"], se(robustness$no_covid)["fit_declaration_lag"], 5)),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          fmt_se(se(r$city_ols1)["declaration_lag"], 5),
          fmt_se(se(r$city_iv1)["fit_declaration_lag"], 5),
          fmt_se(se(robustness$alt_iv)["fit_declaration_lag"], 5),
          fmt_se(se(robustness$no_major)["fit_declaration_lag"], 5),
          fmt_se(se(robustness$no_covid)["fit_declaration_lag"], 5)),
  "\\addlinespace",
  sprintf("Log FEMA damage & %s & %s & %s & %s & %s \\\\",
          fmt_coef(coef(r$city_ols1)["log_damage"], se(r$city_ols1)["log_damage"], 3),
          fmt_coef(coef(r$city_iv1)["log_damage"], se(r$city_iv1)["log_damage"], 3),
          fmt_coef(coef(robustness$alt_iv)["log_damage"], se(robustness$alt_iv)["log_damage"], 3),
          fmt_coef(coef(robustness$no_major)["log_damage"], se(robustness$no_major)["log_damage"], 3),
          fmt_coef(coef(robustness$no_covid)["log_damage"], se(robustness$no_covid)["log_damage"], 3)),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          fmt_se(se(r$city_ols1)["log_damage"], 3),
          fmt_se(se(r$city_iv1)["log_damage"], 3),
          fmt_se(se(robustness$alt_iv)["log_damage"], 3),
          fmt_se(se(robustness$no_major)["log_damage"], 3),
          fmt_se(se(robustness$no_covid)["log_damage"], 3)),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          fmt_n(r$city_ols1$nobs), fmt_n(r$city_iv1$nobs),
          fmt_n(robustness$alt_iv$nobs), fmt_n(robustness$no_major$nobs),
          fmt_n(robustness$no_covid$nobs)),
  "Instrument & --- & Concurrent & Recent & Concurrent & Concurrent \\\\",
  " & & load & decl. & load & load \\\\",
  sprintf("First-stage $F$ & --- & %.1f & %.1f & --- & --- \\\\",
          fitstat(r$city_iv1, "ivf")$ivf1$stat,
          fitstat(robustness$alt_iv, "ivf")$ivf1$stat),
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Type FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sample & Full & Full & Full & No major & No COVID \\\\",
  " & & & & hurricanes & disasters \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the disaster level in parentheses.",
  "Dependent variable is log IHP assistance per valid registrant.",
  "Column 1 reports OLS; columns 2--5 instrument declaration lag using FEMA workload.",
  "Column 4 excludes Sandy, Harvey, Irma, Maria, Michael, Laura, and Ian.",
  "Column 5 excludes biological (COVID-19) disaster declarations.",
  "$^{*} p < 0.10$, $^{**} p < 0.05$, $^{***} p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Table 2 written.\n")

# ============================================================
# TABLE 3: First Stage and Balance
# ============================================================
cat("\n--- Table 3: First Stage ---\n")

bal <- robustness$balance

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{First Stage and Instrument Balance}",
  "\\label{tab:firststage}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{First Stage} & \\multicolumn{2}{c}{Balance} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Decl.~lag & Decl.~lag & Hurricane & Log damage \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Concurrent disasters & %s & %s & %s & %s \\\\",
          fmt_coef(coef(r$fs1)["concurrent_disasters"], se(r$fs1)["concurrent_disasters"], 3),
          fmt_coef(coef(r$fs2)["concurrent_disasters"], se(r$fs2)["concurrent_disasters"], 3),
          fmt_coef(coef(bal$hurricane)["concurrent_disasters"], se(bal$hurricane)["concurrent_disasters"], 4),
          fmt_coef(coef(bal$damage)["concurrent_disasters"], se(bal$damage)["concurrent_disasters"], 3)),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(se(r$fs1)["concurrent_disasters"], 3),
          fmt_se(se(r$fs2)["concurrent_disasters"], 3),
          fmt_se(se(bal$hurricane)["concurrent_disasters"], 4),
          fmt_se(se(bal$damage)["concurrent_disasters"], 3)),
  "\\addlinespace",
  "Disaster controls & No & Yes & --- & --- \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          r$fs1$nobs, r$fs2$nobs, bal$hurricane$nobs, bal$damage$nobs),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Heteroskedasticity-robust standard errors in parentheses.",
  "Columns 1--2: first-stage regressions of declaration lag (days) on concurrent",
  "FEMA disaster load (number of IHP disasters with overlapping 30-day windows).",
  "Columns 3--4: balance tests regressing pre-determined disaster characteristics",
  "on the instrument. $N = 364$ IHP-eligible major disasters, 2010--2025.",
  "$^{*} p < 0.10$, $^{**} p < 0.05$, $^{***} p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_firststage.tex")
cat("  Table 3 written.\n")

# ============================================================
# TABLE 4: Dose-Response (Lag Quartiles)
# ============================================================
cat("\n--- Table 4: Dose-Response ---\n")

analysis_city <- analysis_city |>
  mutate(lag_quartile = ntile(declaration_lag, 4),
         lag_q = factor(lag_quartile))

q_ols1 <- feols(log_ihp_per_reg ~ lag_q + log_damage |
                  year + incidentType,
                data = analysis_city |> filter(is.finite(log_ihp_per_reg)),
                vcov = ~disasterNumber)

q_ols2 <- feols(approval_rate ~ lag_q + log_damage |
                  year + incidentType,
                data = analysis_city |> filter(is.finite(approval_rate)),
                vcov = ~disasterNumber)

# Get quartile boundaries
q_bounds <- quantile(analysis_disaster$declaration_lag, c(0.25, 0.5, 0.75))

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Dose--Response: Declaration Lag Quartiles and Household Outcomes}",
  "\\label{tab:dose}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Log IHP/reg & Approval rate \\\\",
  " & (1) & (2) \\\\",
  "\\midrule",
  sprintf("Lag Q2 (%d--%d days) & %s & %s \\\\",
          q_bounds[1] + 1, q_bounds[2],
          fmt_coef(coef(q_ols1)["lag_q2"], se(q_ols1)["lag_q2"], 3),
          fmt_coef(coef(q_ols2)["lag_q2"], se(q_ols2)["lag_q2"], 3)),
  sprintf(" & %s & %s \\\\",
          fmt_se(se(q_ols1)["lag_q2"], 3),
          fmt_se(se(q_ols2)["lag_q2"], 3)),
  "\\addlinespace",
  sprintf("Lag Q3 (%d--%d days) & %s & %s \\\\",
          q_bounds[2] + 1, q_bounds[3],
          fmt_coef(coef(q_ols1)["lag_q3"], se(q_ols1)["lag_q3"], 3),
          fmt_coef(coef(q_ols2)["lag_q3"], se(q_ols2)["lag_q3"], 3)),
  sprintf(" & %s & %s \\\\",
          fmt_se(se(q_ols1)["lag_q3"], 3),
          fmt_se(se(q_ols2)["lag_q3"], 3)),
  "\\addlinespace",
  sprintf("Lag Q4 (%d--247 days) & %s & %s \\\\",
          q_bounds[3] + 1,
          fmt_coef(coef(q_ols1)["lag_q4"], se(q_ols1)["lag_q4"], 3),
          fmt_coef(coef(q_ols2)["lag_q4"], se(q_ols2)["lag_q4"], 3)),
  sprintf(" & %s & %s \\\\",
          fmt_se(se(q_ols1)["lag_q4"], 3),
          fmt_se(se(q_ols2)["lag_q4"], 3)),
  "\\addlinespace",
  sprintf("Log FEMA damage & %s & %s \\\\",
          fmt_coef(coef(q_ols1)["log_damage"], se(q_ols1)["log_damage"], 3),
          fmt_coef(coef(q_ols2)["log_damage"], se(q_ols2)["log_damage"], 3)),
  sprintf(" & %s & %s \\\\",
          fmt_se(se(q_ols1)["log_damage"], 3),
          fmt_se(se(q_ols2)["log_damage"], 3)),
  "\\midrule",
  sprintf("Observations & %s & %s \\\\",
          fmt_n(q_ols1$nobs), fmt_n(q_ols2$nobs)),
  "Year FE & Yes & Yes \\\\",
  "Type FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} OLS estimates. Base category: Lag Q1 (1--%d days).", q_bounds[1]),
  "Standard errors clustered at the disaster level in parentheses.",
  "$^{*} p < 0.10$, $^{**} p < 0.05$, $^{***} p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_doseresponse.tex")
cat("  Table 4 written.\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE)
# ============================================================
cat("\n--- Table F1: SDE ---\n")

ols_main <- main_results$city_ols1
beta_hat <- coef(ols_main)["declaration_lag"]
se_beta <- se(ols_main)["declaration_lag"]

city_data <- analysis_city |> filter(is.finite(log_ihp_per_reg))
sd_y <- sd(city_data$log_ihp_per_reg, na.rm = TRUE)
sd_x <- sd(city_data$declaration_lag, na.rm = TRUE)

sde_ihp <- beta_hat * sd_x / sd_y
se_sde_ihp <- se_beta * sd_x / sd_y

ols_approval <- feols(approval_rate ~ declaration_lag + log_damage |
                        year + incidentType,
                      data = analysis_city |> filter(is.finite(approval_rate)),
                      vcov = ~disasterNumber)
beta_appr <- coef(ols_approval)["declaration_lag"]
se_appr <- se(ols_approval)["declaration_lag"]
sd_y_appr <- sd(analysis_city$approval_rate, na.rm = TRUE)
sde_appr <- beta_appr * sd_x / sd_y_appr
se_sde_appr <- se_appr * sd_x / sd_y_appr

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_ihp <- classify_sde(sde_ihp)
class_appr <- classify_sde(sde_appr)

cat(sprintf("  IHP/reg: beta=%.5f, SD(X)=%.1f, SD(Y)=%.3f, SDE=%.4f (%s)\n",
            beta_hat, sd_x, sd_y, sde_ihp, class_ihp))
cat(sprintf("  Approval: beta=%.6f, SD(X)=%.1f, SD(Y)=%.3f, SDE=%.4f (%s)\n",
            beta_appr, sd_x, sd_y_appr, sde_appr, class_appr))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the speed of FEMA disaster declaration ",
  "affect per-household Individual and Households Program (IHP) assistance and approval rates? ",
  "\\textbf{Policy mechanism:} A presidential disaster declaration is the legal prerequisite ",
  "for FEMA Individual Assistance to flow to affected households; until declaration, ",
  "households cannot register for rental assistance, repair grants, or other needs assistance, ",
  "creating a bureaucratic queue whose length varies from 1 to 247 days. ",
  "\\textbf{Outcome definition:} (1) Log IHP assistance per valid registrant (dollars); ",
  "(2) Share of valid registrants approved for FEMA assistance. ",
  "\\textbf{Treatment:} Continuous; declaration lag in days between incident onset and ",
  "presidential disaster declaration. ",
  "\\textbf{Data:} OpenFEMA HousingAssistanceOwners and RegistrationIntake datasets, ",
  "2010--2025, city--disaster level, ",
  sprintf("%s observations across %d IHP-eligible major disasters. ",
          fmt_n(nrow(analysis_city)), nrow(analysis_disaster)),
  "\\textbf{Method:} OLS with year and incident-type fixed effects, standard errors clustered ",
  sprintf("at the disaster level (%d clusters); IV robustness using concurrent FEMA disaster load. ",
          nrow(analysis_disaster)),
  "\\textbf{Sample:} IHP-eligible major disaster declarations (DR type) since 2010; ",
  "cities with at least one valid FEMA registration. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard ",
  "deviation of declaration lag and SD($Y$) is the standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Log IHP/registrant & %.5f & %.5f & %.3f & %.4f & %.4f & %s \\\\",
          beta_hat, se_beta, sd_y, sde_ihp, abs(se_sde_ihp), class_ihp),
  sprintf("Approval rate & %.6f & %.6f & %.3f & %.4f & %.4f & %s \\\\",
          beta_appr, se_appr, sd_y_appr, sde_appr, abs(se_sde_appr), class_appr),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
