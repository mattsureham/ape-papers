## 05_tables.R — Generate all tables for paper
source("./code/00_packages.R")

data_dir <- "./data"
tab_dir <- "./tables"

## Rebuild panel -----------------------------------------------------------
coal_pm <- fread(file.path(data_dir, "county_year_coal_pm25.csv"))
coal_pm[, fips := as.character(county_fips)]
coal_pm[, fips := fifelse(nchar(fips) == 4, paste0("0", fips), fips)]

qcew <- fread(file.path(data_dir, "qcew_county_year_full.csv"))
qcew[, fips := as.character(fips)]
qcew[, employment := as.numeric(employment)]
qcew[, wages := as.numeric(wages)]
qcew <- qcew[!is.na(employment) & employment > 0 & !is.na(wages) & wages > 0]

panel <- merge(coal_pm[year >= 2014 & year <= 2019, .(fips, year, coal_pm25)],
               qcew[, .(fips, year, employment, wages)],
               by = c("fips", "year"), all = FALSE)

panel[, wages_per_worker := wages / employment]
panel[, log_wages_pw := log(wages_per_worker)]
panel[, log_employment := log(employment)]
panel[, log_coal := log(coal_pm25 + 0.001)]
panel[, state_fips := substr(fips, 1, 2)]
panel[, state_year := paste0(state_fips, "_", year)]
panel <- panel[!state_fips %in% c("02", "15", "72") &
               !is.na(log_wages_pw) & is.finite(log_wages_pw) & coal_pm25 > 0]

# First differences
setorder(panel, fips, year)
panel[, d_log_emp := log_employment - shift(log_employment), by = fips]
panel[, d_log_coal := log_coal - shift(log_coal), by = fips]
panel[, d_log_wages := log_wages_pw - shift(log_wages_pw), by = fips]

## TABLE 1: Summary Statistics =============================================
cat("=== Table 1: Summary Statistics ===\n")
tab1_vars <- panel[, .(
  coal_pm25, wages_per_worker, employment, log_employment, log_wages_pw
)]
tab1_stats <- data.frame(
  Variable = c("Coal PM$_{2.5}$ ($\\mu$g/m$^3$)", "Wages per worker (\\$)",
               "Employment", "Log employment", "Log wages per worker"),
  Mean = sapply(tab1_vars, mean, na.rm = TRUE),
  SD = sapply(tab1_vars, sd, na.rm = TRUE),
  P10 = sapply(tab1_vars, quantile, 0.1, na.rm = TRUE),
  Median = sapply(tab1_vars, median, na.rm = TRUE),
  P90 = sapply(tab1_vars, quantile, 0.9, na.rm = TRUE)
)

tab1_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n\\caption{Summary Statistics}\n\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n\\hline\\hline\n",
  " & Mean & SD & P10 & Median & P90 \\\\\n\\hline\n"
)
for (i in 1:nrow(tab1_stats)) {
  tab1_tex <- paste0(tab1_tex, sprintf("%s & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n",
                                        tab1_stats$Variable[i],
                                        tab1_stats$Mean[i], tab1_stats$SD[i],
                                        tab1_stats$P10[i], tab1_stats$Median[i],
                                        tab1_stats$P90[i]))
}
tab1_tex <- paste0(tab1_tex,
                   "\\hline\n",
                   sprintf("Counties & \\multicolumn{5}{c}{%d} \\\\\n", uniqueN(panel$fips)),
                   sprintf("County-years & \\multicolumn{5}{c}{%s} \\\\\n",
                           format(nrow(panel), big.mark = ",")),
                   sprintf("Years & \\multicolumn{5}{c}{2014--2019} \\\\\n"),
                   "\\hline\\hline\n\\end{tabular}\n",
                   "\\begin{flushleft}\\small\n",
                   "Notes: Panel of contiguous US counties, 2014--2019. Coal PM$_{2.5}$ is the HyADS-modeled ",
                   "coal-attributable fine particulate matter concentration from Henneman et al.\\ (2023). ",
                   "Employment and wages from BLS QCEW, all industries.\n",
                   "\\end{flushleft}\n\\end{table}")
writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

## TABLE 2: Main Results ===================================================
cat("=== Table 2: Main Results ===\n")

m1 <- feols(log_employment ~ log_coal | fips + year, data = panel, cluster = ~state_fips)
m2 <- feols(log_employment ~ log_coal | fips + state_year, data = panel, cluster = ~state_fips)
m3 <- feols(d_log_emp ~ d_log_coal | year, data = panel[!is.na(d_log_emp)], cluster = ~state_fips)
m4 <- feols(log_wages_pw ~ log_coal | fips + year, data = panel, cluster = ~state_fips)
m5 <- feols(log_wages_pw ~ log_coal | fips + state_year, data = panel, cluster = ~state_fips)
m6 <- feols(d_log_wages ~ d_log_coal | year, data = panel[!is.na(d_log_wages)], cluster = ~state_fips)

# Build table manually for precise control
get_row <- function(model, label) {
  b <- coef(model)[1]
  se <- sqrt(vcov(model)[1,1])
  t <- b / se
  stars <- ifelse(abs(t) > 2.576, "^{***}", ifelse(abs(t) > 1.96, "^{**}", ifelse(abs(t) > 1.645, "^{*}", "")))
  sprintf("%s & $%.4f%s$ & $%.4f%s$ \\\\\n & $(%.4f)$ & $(%.4f)$ \\\\",
          label, b, stars, NA, "", se, NA)
}

tab2_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n\\caption{Coal PM$_{2.5}$ and County Labor Markets}\n\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Log Employment} & \\multicolumn{3}{c}{Log Wages/Worker} \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n\\hline\n"
)

models <- list(m1, m2, m3, m4, m5, m6)
# Coefficients row
coefs <- sapply(models, function(m) coef(m)[1])
ses <- sapply(models, function(m) sqrt(vcov(m)[1,1]))
ts <- coefs / ses
stars <- ifelse(abs(ts) > 2.576, "^{***}", ifelse(abs(ts) > 1.96, "^{**}", ifelse(abs(ts) > 1.645, "^{*}", "")))

tab2_tex <- paste0(tab2_tex, "Log Coal PM$_{2.5}$")
for (i in 1:6) {
  tab2_tex <- paste0(tab2_tex, sprintf(" & $%.4f%s$", coefs[i], stars[i]))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")
for (i in 1:6) {
  tab2_tex <- paste0(tab2_tex, sprintf(" & $(%.4f)$", ses[i]))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n\\hline\n")

# Fixed effects and N
tab2_tex <- paste0(tab2_tex,
  "County FE & Yes & Yes & -- & Yes & Yes & -- \\\\\n",
  "Year FE & Yes & -- & Yes & Yes & -- & Yes \\\\\n",
  "State$\\times$Year FE & -- & Yes & -- & -- & Yes & -- \\\\\n",
  "First-differenced & -- & -- & Yes & -- & -- & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          format(m1$nobs, big.mark=","), format(m2$nobs, big.mark=","),
          format(m3$nobs, big.mark=","), format(m4$nobs, big.mark=","),
          format(m5$nobs, big.mark=","), format(m6$nobs, big.mark=",")),
  {nc <- uniqueN(panel$fips); sprintf("Counties & %d & %d & %d & %d & %d & %d \\\\\n",
          nc, nc, nc, nc, nc, nc)},
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{flushleft}\\small\n",
  "Notes: Dependent variable in columns (1)--(3) is log county employment; columns (4)--(6) is log wages per worker. ",
  "Coal PM$_{2.5}$ is the HyADS atmospheric dispersion model estimate of coal-attributable PM$_{2.5}$ (Henneman et al.\\ 2023). ",
  "Columns (3) and (6) use first-differenced specifications. ",
  "Standard errors clustered at the state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{flushleft}\n\\end{table}")

writeLines(tab2_tex, file.path(tab_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

## TABLE 3: Robustness =====================================================
cat("=== Table 3: Robustness ===\n")

# Exclude host counties
high_coal <- panel[, .(max_coal = max(coal_pm25)), by = fips]
host_counties <- high_coal[max_coal > quantile(high_coal$max_coal, 0.95)]$fips
panel_nohost <- panel[!fips %in% host_counties]

med_emp <- median(panel[year == 2014]$employment)
panel[, urban := as.integer(employment > med_emp)]

r1 <- feols(log_employment ~ log_coal | fips + year, data = panel, cluster = ~state_fips)  # baseline
r2 <- feols(log_employment ~ log_coal | fips + state_year, data = panel, cluster = ~state_fips)
r3 <- feols(log_employment ~ log_coal | fips + year, data = panel_nohost, cluster = ~state_fips)
r4 <- feols(log_employment ~ log_coal | fips + year, data = panel[urban == 0], cluster = ~state_fips)
r5 <- feols(log_employment ~ log_coal | fips + year, data = panel[urban == 1], cluster = ~state_fips)

robustness_models <- list(r1, r2, r3, r4, r5)
rob_coefs <- sapply(robustness_models, function(m) coef(m)[1])
rob_ses <- sapply(robustness_models, function(m) sqrt(vcov(m)[1,1]))
rob_ts <- rob_coefs / rob_ses
rob_stars <- ifelse(abs(rob_ts) > 2.576, "^{***}", ifelse(abs(rob_ts) > 1.96, "^{**}", ifelse(abs(rob_ts) > 1.645, "^{*}", "")))
rob_n <- sapply(robustness_models, function(m) m$nobs)

tab3_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n\\caption{Robustness: Coal PM$_{2.5}$ and Employment}\n\\label{tab:robust}\n",
  "\\begin{tabular}{lccccc}\n\\hline\\hline\n",
  " & Baseline & State$\\times$Year & Excl.\\ Host & Rural & Urban \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n\\hline\n",
  "Log Coal PM$_{2.5}$"
)
for (i in 1:5) tab3_tex <- paste0(tab3_tex, sprintf(" & $%.4f%s$", rob_coefs[i], rob_stars[i]))
tab3_tex <- paste0(tab3_tex, " \\\\\n")
for (i in 1:5) tab3_tex <- paste0(tab3_tex, sprintf(" & $(%.4f)$", rob_ses[i]))
tab3_tex <- paste0(tab3_tex, " \\\\\n\\hline\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & -- & Yes & Yes & Yes \\\\\n",
  "State$\\times$Year FE & -- & Yes & -- & -- & -- \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(rob_n[1], big.mark=","), format(rob_n[2], big.mark=","),
          format(rob_n[3], big.mark=","), format(rob_n[4], big.mark=","),
          format(rob_n[5], big.mark=",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{flushleft}\\small\n",
  "Notes: Dependent variable is log county employment. Column (3) excludes counties in the top 5\\% of coal PM$_{2.5}$ exposure. ",
  "Columns (4) and (5) split by median 2014 employment. ",
  "Standard errors clustered at the state level.\n",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{flushleft}\n\\end{table}")

writeLines(tab3_tex, file.path(tab_dir, "tab3_robustness.tex"))
cat("  Saved tab3_robustness.tex\n")

## TABLE F1: SDE Appendix ==================================================
cat("=== Table F1: SDE ===\n")

# Compute SDE for main results
sde_data <- data.frame(
  Outcome = c("Log employment", "Log employment", "Log wages/worker", "Log wages/worker"),
  beta = c(coef(m1)[1], coef(m3)[1], coef(m4)[1], coef(m6)[1]),
  se_beta = c(sqrt(vcov(m1)[1,1]), sqrt(vcov(m3)[1,1]),
              sqrt(vcov(m4)[1,1]), sqrt(vcov(m6)[1,1])),
  sd_y = c(sd(panel$log_employment), sd(panel$d_log_emp, na.rm=TRUE),
           sd(panel$log_wages_pw), sd(panel$d_log_wages, na.rm=TRUE)),
  spec = c("Levels", "FD", "Levels", "FD")
)
sde_data$sde <- sde_data$beta / sde_data$sd_y
sde_data$se_sde <- sde_data$se_beta / sde_data$sd_y
sde_data$class <- ifelse(abs(sde_data$sde) > 0.15, "Large",
                  ifelse(abs(sde_data$sde) > 0.05, "Moderate",
                  ifelse(abs(sde_data$sde) > 0.005, "Small", "Null")))

tab_sde <- paste0(
  "\\begin{table}[t]\n\\centering\n\\caption{Standardized Dispositive Effect (SDE)}\n\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)
for (i in 1:nrow(sde_data)) {
  tab_sde <- paste0(tab_sde, sprintf("%s (%s) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
                                      sde_data$Outcome[i], sde_data$spec[i],
                                      sde_data$beta[i], sde_data$se_beta[i],
                                      sde_data$sd_y[i], sde_data$sde[i],
                                      sde_data$se_sde[i], sde_data$class[i]))
}

# Panel B: Heterogeneous (rural vs urban)
tab_sde <- paste0(tab_sde,
  "\\hline\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n")
for (label in c("Rural", "Urban")) {
  m <- if(label == "Rural") r4 else r5
  sub <- if(label == "Rural") panel[urban == 0] else panel[urban == 1]
  b <- coef(m)[1]; s <- sqrt(vcov(m)[1,1]); sdy <- sd(sub$log_employment)
  sde_val <- b/sdy; se_sde_val <- s/sdy
  cl <- ifelse(abs(sde_val) > 0.15, "Large", ifelse(abs(sde_val) > 0.05, "Moderate",
        ifelse(abs(sde_val) > 0.005, "Small", "Null")))
  tab_sde <- paste0(tab_sde, sprintf("Employment (%s) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
                                      label, b, s, sdy, sde_val, se_sde_val, cl))
}

tab_sde <- paste0(tab_sde,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{flushleft}\\small\n",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does coal-attributable air pollution reduce local employment? ",
  "\\textbf{Policy mechanism:} Coal plant emissions transported to downwind counties via atmospheric dispersion. ",
  "\\textbf{Outcome definition:} Log county employment (QCEW, all industries). ",
  "\\textbf{Treatment:} Log HyADS coal PM$_{2.5}$ concentration ($\\mu$g/m$^3$). ",
  "\\textbf{Data:} HyADS (Henneman et al.\\ 2023) + BLS QCEW, 2014--2019. ",
  "\\textbf{Method:} Reduced-form panel regression with county and year FE. ",
  "\\textbf{Sample:} 2,802 contiguous US counties, 6 years. ",
  "Classification refers to magnitude, not statistical significance.\n",
  "\\end{flushleft}\n\\end{table}")

writeLines(tab_sde, file.path(tab_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
