## 05_tables.R — Generate all tables for the paper
## apep_1117: Payday Depletion Cycle and Property Crime in Buenos Aires

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

daily <- fread(file.path(data_dir, "daily_panel.csv"))
daily[, date := as.Date(date)]
daily[, ym := format(date, "%Y-%m")]
daily[, dow := factor(wday(date))]
daily[, day_of_month := mday(date)]
daily[, weekend := as.integer(wday(date) %in% c(1, 7))]
daily[, log_property := log(property_crimes + 1)]
daily[, year_num := year(date)]

## Reconstruct payment variables
digit_day <- fread(file.path(data_dir, "digit_day_dsp.csv"))
digit_day[, date := as.Date(date)]

groups_paid_today <- digit_day[days_since_payment == 0, .(n_paid_today = .N), by = date]
daily <- merge(daily, groups_paid_today, by = "date", all.x = TRUE)
daily[is.na(n_paid_today), n_paid_today := 0]
daily[, payment_day := as.integer(n_paid_today > 0)]

groups_week <- digit_day[days_since_payment <= 7, .(n_paid_recent7 = .N), by = date]
daily <- merge(daily, groups_week, by = "date", all.x = TRUE)
daily[is.na(n_paid_recent7), n_paid_recent7 := 0]

all_paid <- digit_day[, .(all_paid = as.integer(all(days_since_payment > 0) & .N == 10)),
                       by = date]
daily <- merge(daily, all_paid, by = "date", all.x = TRUE)
daily[is.na(all_paid), all_paid := 0]

perm_results <- read_json(file.path(data_dir, "permutation_results.json"))

## ============================================================
## TABLE 1: Summary Statistics
## ============================================================

cat("Generating Table 1: Summary Statistics\n")

## Panel A: Daily crime counts
panel_a <- data.table(
  Variable = c("Property crimes (robbery + theft)", "Robbery (\\textit{robo})",
               "Theft (\\textit{hurto})", "Violent non-property",
               "Total crimes"),
  Mean = c(mean(daily$property_crimes), mean(daily$robbery),
           mean(daily$theft), mean(daily$violent_nonprop),
           mean(daily$total_crimes)),
  SD = c(sd(daily$property_crimes), sd(daily$robbery),
         sd(daily$theft), sd(daily$violent_nonprop),
         sd(daily$total_crimes)),
  Min = c(min(daily$property_crimes), min(daily$robbery),
          min(daily$theft), min(daily$violent_nonprop),
          min(daily$total_crimes)),
  Max = c(max(daily$property_crimes), max(daily$robbery),
          max(daily$theft), max(daily$violent_nonprop),
          max(daily$total_crimes))
)

## Panel B: Treatment variables
panel_b <- data.table(
  Variable = c("Avg. days since payment", "Payment day (indicator)",
               "Groups paid within 7 days", "Post-window (all paid)"),
  Mean = c(mean(daily$avg_days_since_payment), mean(daily$payment_day),
           mean(daily$n_paid_recent7), mean(daily$all_paid)),
  SD = c(sd(daily$avg_days_since_payment), sd(daily$payment_day),
         sd(daily$n_paid_recent7), sd(daily$all_paid)),
  Min = c(min(daily$avg_days_since_payment), 0, 0, 0),
  Max = c(max(daily$avg_days_since_payment), 1,
          max(daily$n_paid_recent7), 1)
)

## Format numbers
fmt <- function(x) sprintf("%.1f", x)
fmt0 <- function(x) sprintf("%.2f", x)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Daily Crime and Payment Variables, Buenos Aires 2019--2023}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Daily crime counts}} \\\\[3pt]"
)

for (i in 1:nrow(panel_a)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            panel_a$Variable[i], fmt(panel_a$Mean[i]), fmt(panel_a$SD[i]),
            fmt(panel_a$Min[i]), fmt(panel_a$Max[i])))
}

tab1_lines <- c(tab1_lines, "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Payment timing variables}} \\\\[3pt]")

for (i in 1:nrow(panel_b)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            panel_b$Variable[i], fmt0(panel_b$Mean[i]), fmt0(panel_b$SD[i]),
            fmt0(panel_b$Min[i]), fmt0(panel_b$Max[i])))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("\\multicolumn{5}{l}{\\footnotesize Observations: %s days. Property crimes = robbery + theft.} \\\\",
          format(nrow(daily), big.mark = ",")),
  sprintf("\\multicolumn{5}{l}{\\footnotesize Buenos Aires City Open Data \\texttt{delitos} 2019--2023; ANSES payment calendar.} \\\\",
          nrow(daily)),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

## ============================================================
## TABLE 2: Main Results — Payment Timing and Property Crime
## ============================================================

cat("Generating Table 2: Main Results\n")

m1 <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
            data = daily, vcov = ~ym)
m2 <- feols(property_crimes ~ payment_day | dow + ym,
            data = daily, vcov = ~ym)
m3 <- feols(property_crimes ~ n_paid_recent7 | dow + ym,
            data = daily, vcov = ~ym)
m4 <- feols(log_property ~ avg_days_since_payment | dow + ym,
            data = daily, vcov = ~ym)
m5 <- feols(property_crimes ~ avg_days_since_payment +
              day_of_month + I(day_of_month^2) | dow + ym,
            data = daily, vcov = ~ym)

## Extract coefficients
get_coef <- function(mod, var) {
  b <- coef(mod)[var]
  se <- sqrt(vcov(mod)[var, var])
  p <- 2 * pnorm(-abs(b / se))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}",
                  ifelse(p < 0.1, "^{*}", "")))
  list(b = b, se = se, p = p, stars = stars)
}

c1 <- get_coef(m1, "avg_days_since_payment")
c2 <- get_coef(m2, "payment_day")
c3 <- get_coef(m3, "n_paid_recent7")
c4 <- get_coef(m4, "avg_days_since_payment")
c5 <- get_coef(m5, "avg_days_since_payment")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Payment Timing and Property Crime in Buenos Aires}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Property & Property & Property & Log property & Property \\\\",
  "\\hline",
  sprintf("Avg. days since payment & %s%s & & & %s%s & %s%s \\\\",
          sprintf("%.3f", c1$b), c1$stars,
          sprintf("%.5f", c4$b), c4$stars,
          sprintf("%.3f", c5$b), c5$stars),
  sprintf(" & (%s) & & & (%s) & (%s) \\\\",
          sprintf("%.3f", c1$se), sprintf("%.5f", c4$se),
          sprintf("%.3f", c5$se)),
  sprintf("Payment day & & %s%s & & & \\\\",
          sprintf("%.3f", c2$b), c2$stars),
  sprintf(" & & (%s) & & & \\\\", sprintf("%.3f", c2$se)),
  sprintf("Groups paid (7 days) & & & %s%s & & \\\\",
          sprintf("%.3f", c3$b), c3$stars),
  sprintf(" & & & (%s) & & & \\\\", sprintf("%.3f", c3$se)),
  "Day-of-month polynomial & & & & & Yes \\\\",
  "Day-of-week FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year$\\times$month FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nrow(daily), big.mark = ","),
          format(nrow(daily), big.mark = ","),
          format(nrow(daily), big.mark = ","),
          format(nrow(daily), big.mark = ","),
          format(nrow(daily), big.mark = ",")),
  sprintf("Mean dep. var. & %.1f & %.1f & %.1f & %.2f & %.1f \\\\",
          mean(daily$property_crimes), mean(daily$property_crimes),
          mean(daily$property_crimes), mean(daily$log_property),
          mean(daily$property_crimes)),
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          r2(m1, "ar2"), r2(m2, "ar2"), r2(m3, "ar2"), r2(m4, "ar2"),
          r2(m5, "ar2")),
  "\\hline",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Heteroskedasticity-robust standard errors in parentheses. Unit of observation is city-day. Property crimes = robbery + theft. ``Avg.\\ days since payment'' is the mean across all 10 DNI digit groups of the number of days since each group's most recent ANSES pension payment. ``Payment day'' = 1 if at least one digit group receives payment. ``Groups paid (7 days)'' counts how many digit groups received payment within the past week. Column (4) uses log(property crimes + 1). Column (5) adds a quadratic day-of-month polynomial.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

## ============================================================
## TABLE 3: Crime Type Decomposition + Placebo
## ============================================================

cat("Generating Table 3: Decomposition and Placebo\n")

rob1 <- feols(robbery ~ avg_days_since_payment | dow + ym,
              data = daily, vcov = ~ym)
thf1 <- feols(theft ~ avg_days_since_payment | dow + ym,
              data = daily, vcov = ~ym)
vio1 <- feols(violent_nonprop ~ avg_days_since_payment | dow + ym,
              data = daily, vcov = ~ym)

rob2 <- feols(robbery ~ payment_day | dow + ym,
              data = daily, vcov = ~ym)
thf2 <- feols(theft ~ payment_day | dow + ym,
              data = daily, vcov = ~ym)
vio2 <- feols(violent_nonprop ~ payment_day | dow + ym,
              data = daily, vcov = ~ym)

cr1 <- get_coef(rob1, "avg_days_since_payment")
ct1 <- get_coef(thf1, "avg_days_since_payment")
cv1 <- get_coef(vio1, "avg_days_since_payment")
cr2 <- get_coef(rob2, "payment_day")
ct2 <- get_coef(thf2, "payment_day")
cv2 <- get_coef(vio2, "payment_day")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Crime Type Decomposition and Placebo Tests}",
  "\\label{tab:decomp}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Avg. days since payment} & \\multicolumn{3}{c}{Payment day} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Robbery & Theft & Violent & Robbery & Theft & Violent \\\\",
  "\\hline",
  sprintf("Treatment & %s%s & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.3f", cr1$b), cr1$stars,
          sprintf("%.3f", ct1$b), ct1$stars,
          sprintf("%.3f", cv1$b), cv1$stars,
          sprintf("%.3f", cr2$b), cr2$stars,
          sprintf("%.3f", ct2$b), ct2$stars,
          sprintf("%.3f", cv2$b), cv2$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          sprintf("%.3f", cr1$se), sprintf("%.3f", ct1$se),
          sprintf("%.3f", cv1$se), sprintf("%.3f", cr2$se),
          sprintf("%.3f", ct2$se), sprintf("%.3f", cv2$se)),
  "Day-of-week FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year$\\times$month FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & \\multicolumn{6}{c}{%s} \\\\",
          format(nrow(daily), big.mark = ",")),
  sprintf("Mean dep. var. & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(daily$robbery), mean(daily$theft),
          mean(daily$violent_nonprop), mean(daily$robbery),
          mean(daily$theft), mean(daily$violent_nonprop)),
  "\\hline",
  "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Heteroskedasticity-robust standard errors in parentheses. ``Violent'' = assault + threats (crimes not primarily motivated by economic need). Columns (1)--(3) use average days since payment as the continuous treatment variable; columns (4)--(6) use the payment day indicator. The placebo prediction is that payment timing should not affect violent non-property crime (columns 3, 6).} \\\\",
  "\\multicolumn{7}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_decomp.tex"))

## ============================================================
## TABLE 4: Robustness — Year-by-year + Permutation
## ============================================================

cat("Generating Table 4: Robustness\n")

## Year-by-year
yrs <- c(2019, 2021, 2022, 2023)
yr_results <- list()
for (yr in yrs) {
  sub <- daily[year_num == yr]
  m <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
             data = sub, vcov = ~ym)
  yr_results[[as.character(yr)]] <- get_coef(m, "avg_days_since_payment")
}

## No-COVID
daily_nc <- daily[year_num != 2020]
m_nc <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
              data = daily_nc, vcov = ~ym)
c_nc <- get_coef(m_nc, "avg_days_since_payment")

## Weekday only
daily_wk <- daily[weekend == 0]
m_wk <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
              data = daily_wk, vcov = ~ym)
c_wk <- get_coef(m_wk, "avg_days_since_payment")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Subsamples and Permutation Inference}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Dep.~var.: Property crimes} \\\\",
  "\\cmidrule(lr){2-3}",
  "Sample & Avg. DSP coef. & Obs. \\\\",
  "\\hline",
  "\\textit{Panel A: Year-by-year estimates} \\\\[3pt]"
)

for (yr in yrs) {
  r <- yr_results[[as.character(yr)]]
  sub <- daily[year_num == yr]
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad %d & %s%s & %s \\\\", yr,
            sprintf("%.3f", r$b), r$stars,
            format(nrow(sub), big.mark = ",")),
    sprintf(" & (%s) & \\\\", sprintf("%.3f", r$se)))
}

tab4_lines <- c(tab4_lines,
  "[6pt]",
  "\\textit{Panel B: Alternative samples} \\\\[3pt]",
  sprintf("\\quad Excluding 2020 (COVID) & %s%s & %s \\\\",
          sprintf("%.3f", c_nc$b), c_nc$stars,
          format(nrow(daily_nc), big.mark = ",")),
  sprintf(" & (%s) & \\\\", sprintf("%.3f", c_nc$se)),
  sprintf("\\quad Weekdays only & %s%s & %s \\\\",
          sprintf("%.3f", c_wk$b), c_wk$stars,
          format(nrow(daily_wk), big.mark = ",")),
  sprintf(" & (%s) & \\\\", sprintf("%.3f", c_wk$se)),
  "[6pt]",
  "\\textit{Panel C: Permutation inference (200 draws)} \\\\[3pt]",
  sprintf("\\quad Avg.~DSP: true $\\hat{\\beta}$ = %.3f & \\multicolumn{2}{l}{Permutation $p$ = %.3f} \\\\",
          perm_results$dsp_true_coef, perm_results$dsp_perm_p),
  sprintf("\\quad Payment day: true $\\hat{\\beta}$ = %.3f & \\multicolumn{2}{l}{Permutation $p$ = %.3f} \\\\",
          perm_results$payment_day_true_coef, perm_results$payment_day_perm_p),
  "\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} All specifications include day-of-week and year$\\times$month fixed effects with heteroskedasticity-robust standard errors. Panel C shuffles digit-group payment dates within each month 200 times and reports the two-sided permutation $p$-value: the fraction of shuffled coefficients exceeding the true coefficient in absolute value.} \\\\",
  "\\multicolumn{3}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))

## ============================================================
## TABLE F1: SDE Table (Standardized Effect Sizes) — MANDATORY APPENDIX
## ============================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

## Pre-treatment SD: use 2019 as "pre" (before COVID distortion)
pre_data <- daily[year_num == 2019]
sd_property_pre <- sd(pre_data$property_crimes)
sd_robbery_pre <- sd(pre_data$robbery)
sd_theft_pre <- sd(pre_data$theft)
sd_violent_pre <- sd(pre_data$violent_nonprop)

## Main estimates (continuous treatment: SDE = beta * SD(X) / SD(Y))
sd_dsp <- sd(daily$avg_days_since_payment)
sd_payday <- sd(daily$payment_day)

## Main model: property crimes on DSP
b_prop <- coef(m1)["avg_days_since_payment"]
se_prop <- sqrt(vcov(m1)["avg_days_since_payment", "avg_days_since_payment"])
sde_prop <- b_prop * sd_dsp / sd_property_pre
se_sde_prop <- se_prop * sd_dsp / sd_property_pre

## Property on payment day (binary: SDE = beta / SD(Y))
b_pay <- coef(m2)["payment_day"]
se_pay <- sqrt(vcov(m2)["payment_day", "payment_day"])
sde_pay <- b_pay / sd_property_pre
se_sde_pay <- se_pay / sd_property_pre

## Robbery on DSP
b_rob <- coef(rob1)["avg_days_since_payment"]
se_rob <- sqrt(vcov(rob1)["avg_days_since_payment", "avg_days_since_payment"])
sde_rob <- b_rob * sd_dsp / sd_robbery_pre
se_sde_rob <- se_rob * sd_dsp / sd_robbery_pre

## Theft on DSP
b_thf <- coef(thf1)["avg_days_since_payment"]
se_thf <- sqrt(vcov(thf1)["avg_days_since_payment", "avg_days_since_payment"])
sde_thf <- b_thf * sd_dsp / sd_theft_pre
se_sde_thf <- se_thf * sd_dsp / sd_theft_pre

## Placebo: violent on DSP
b_vio <- coef(vio1)["avg_days_since_payment"]
se_vio <- sqrt(vcov(vio1)["avg_days_since_payment", "avg_days_since_payment"])
sde_vio <- b_vio * sd_dsp / sd_violent_pre
se_sde_vio <- se_vio * sd_dsp / sd_violent_pre

## Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

## Build SDE table data
sde_data <- data.table(
  Outcome = c("Property crimes (DSP)", "Property crimes (payday)",
              "Robbery (DSP)", "Theft (DSP)", "Violent non-property (DSP)"),
  beta = c(b_prop, b_pay, b_rob, b_thf, b_vio),
  se = c(se_prop, se_pay, se_rob, se_thf, se_vio),
  sd_y = c(sd_property_pre, sd_property_pre, sd_robbery_pre,
           sd_theft_pre, sd_violent_pre),
  sde = c(sde_prop, sde_pay, sde_rob, sde_thf, sde_vio),
  se_sde = c(se_sde_prop, se_sde_pay, se_sde_rob, se_sde_thf, se_sde_vio)
)

sde_data[, classification := sapply(sde, classify_sde)]

## Heterogeneity: pre-COVID vs post-COVID
pre_sub <- daily[year_num == 2019]
post_sub <- daily[year_num %in% c(2022, 2023)]

m_pre <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
               data = pre_sub, vcov = ~ym)
m_post <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
                data = post_sub, vcov = ~ym)

b_pre <- coef(m_pre)[1]; se_pre_m <- sqrt(vcov(m_pre)[1,1])
b_post <- coef(m_post)[1]; se_post_m <- sqrt(vcov(m_post)[1,1])

sd_pre_y <- sd(pre_sub$property_crimes)
sd_post_y <- sd(post_sub$property_crimes)

sde_pre <- b_pre * sd_dsp / sd_pre_y
se_sde_pre <- se_pre_m * sd_dsp / sd_pre_y
sde_post <- b_post * sd_dsp / sd_post_y
se_sde_post <- se_post_m * sd_dsp / sd_post_y

## SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Argentina. ",
  "\\textbf{Research question:} Does welfare payment timing affect property crime through a liquidity depletion cycle in Buenos Aires? ",
  "\\textbf{Policy mechanism:} ANSES distributes monthly pension and social transfer payments to approximately 18 million beneficiaries on staggered calendar days determined by the last digit of each person's national identity document (DNI), creating quasi-random within-month variation in neighborhood-level cash availability. ",
  "\\textbf{Outcome definition:} Daily count of property crimes (robbery plus theft) recorded by Buenos Aires City's Ministry of Justice and Security. ",
  "\\textbf{Treatment:} Continuous --- average number of days since most recent ANSES payment across all 10 DNI digit groups; and binary --- indicator for whether at least one digit group received payment on a given day. ",
  "\\textbf{Data:} Buenos Aires City Open Data crime records and ANSES payment calendar, 2019--2023, city-day observations, $N$ = 1,819 days. ",
  "\\textbf{Method:} OLS with day-of-week and year$\\times$month fixed effects, heteroskedasticity-robust standard errors. ",
  "\\textbf{Sample:} All days 2019--2023 with complete payment calendar data; Panel B splits by pre-COVID (2019) and post-COVID (2022--2023) periods. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment; ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment, where SD($Y$) is the pre-treatment (2019) standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (2019--2023)}} \\\\[3pt]"
)

for (i in 1:nrow(sde_data)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
            sde_data$Outcome[i],
            sprintf("%.3f", sde_data$beta[i]),
            sprintf("%.3f", sde_data$se[i]),
            sprintf("%.1f", sde_data$sd_y[i]),
            sprintf("%.4f", sde_data$sde[i]),
            sprintf("%.4f", sde_data$se_sde[i]),
            sde_data$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (period splits)}} \\\\[3pt]",
  sprintf("Property crimes, 2019 & %s & %s & %s & %s & %s & %s \\\\",
          sprintf("%.3f", b_pre), sprintf("%.3f", se_pre_m),
          sprintf("%.1f", sd_pre_y), sprintf("%.4f", sde_pre),
          sprintf("%.4f", se_sde_pre), classify_sde(sde_pre)),
  sprintf("Property crimes, 2022--23 & %s & %s & %s & %s & %s & %s \\\\",
          sprintf("%.3f", b_post), sprintf("%.3f", se_post_m),
          sprintf("%.1f", sd_post_y), sprintf("%.4f", sde_post),
          sprintf("%.4f", se_sde_post), classify_sde(sde_post)),
  "\\hline",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\begin{itemize}[leftmargin=*,nosep]",
  sde_notes,
  "\\end{itemize}",
  "\\end{minipage}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("SDE for property crimes (DSP, continuous): %.4f (%s)\n",
            sde_prop, classify_sde(sde_prop)))
cat(sprintf("SDE for property crimes (payday, binary): %.4f (%s)\n",
            sde_pay, classify_sde(sde_pay)))
