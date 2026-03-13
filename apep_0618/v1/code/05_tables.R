## 05_tables.R — Generate all LaTeX tables including SDE appendix
library(data.table)
library(fixest)

panel <- fread("data/panel.csv.gz")

## ============================================================
## Table 1: Summary Statistics
## ============================================================
pre <- panel[post == 0]
pst <- panel[post == 1]

fmt <- function(x, d = 1) ifelse(is.na(x), "---", formatC(x, format = "f", digits = d, big.mark = ","))

tab1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Summary Statistics}\n\\label{tab:sumstats}\n",
  "\\small\n\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Pre-Reform} & \\multicolumn{2}{c}{Post-Reform} \\\\\n",
  " & \\multicolumn{2}{c}{(Jan 2010--Nov 2014)} & \\multicolumn{2}{c}{(Dec 2014--Dec 2019)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n\\hline\n",
  "Monthly transactions per LA & ", fmt(mean(pre$n_txn)), " & ", fmt(sd(pre$n_txn)), " & ",
    fmt(mean(pst$n_txn)), " & ", fmt(sd(pst$n_txn)), " \\\\\n",
  "Transactions \\pounds200k--\\pounds350k & ", fmt(mean(pre$n_txn_200_350)), " & ", fmt(sd(pre$n_txn_200_350)), " & ",
    fmt(mean(pst$n_txn_200_350)), " & ", fmt(sd(pst$n_txn_200_350)), " \\\\\n",
  "Dead zone (\\pounds250k--\\pounds260k) & ", fmt(mean(pre$n_txn_dead_zone)), " & ", fmt(sd(pre$n_txn_dead_zone)), " & ",
    fmt(mean(pst$n_txn_dead_zone)), " & ", fmt(sd(pst$n_txn_dead_zone)), " \\\\\n",
  "Below-notch (\\pounds240k--\\pounds250k) & ", fmt(mean(pre$n_txn_below_notch)), " & ", fmt(sd(pre$n_txn_below_notch)), " & ",
    fmt(mean(pst$n_txn_below_notch)), " & ", fmt(sd(pst$n_txn_below_notch)), " \\\\\n",
  "Median price (\\pounds1,000s) & ", fmt(mean(pre$median_price)/1000), " & ", fmt(sd(pre$median_price)/1000), " & ",
    fmt(mean(pst$median_price)/1000), " & ", fmt(sd(pst$median_price)/1000), " \\\\\n",
  "\\addlinespace\n",
  "Excess mass ratio & ", fmt(mean(pre$excess_mass), 2), " & ", fmt(sd(pre$excess_mass), 2), " & --- & --- \\\\\n",
  "\\hline\n",
  "LA--months & \\multicolumn{2}{c}{", format(nrow(pre), big.mark = ","), "} & ",
    "\\multicolumn{2}{c}{", format(nrow(pst), big.mark = ","), "} \\\\\n",
  "Local Authorities & \\multicolumn{4}{c}{", uniqueN(panel$district), "} \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\\vspace{0.3em}\n",
  "\\footnotesize\\textit{Notes:} Unit of observation is Local Authority $\\times$ month. ",
  "Data from HM Land Registry Price Paid Data (complete residential transactions). ",
  "Excess mass ratio measures pre-reform bunching at the \\pounds250,000 SDLT notch, computed from 2010--November 2014 data.\n",
  "\\end{minipage}\n\\end{table}\n"
)
writeLines(tab1, "tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

## ============================================================
## Table 2: Main Results (etable)
## ============================================================
m1 <- feols(ln_txn ~ post:excess_mass | la_id + ym, data = panel, cluster = ~la_id)
m2 <- feols(ln_txn_200_350 ~ post:excess_mass | la_id + ym, data = panel, cluster = ~la_id)
m3 <- feols(dead_zone_share ~ post:excess_mass | la_id + ym, data = panel, cluster = ~la_id)
m4 <- feols(log(n_txn_dead_zone + 1) ~ post:excess_mass | la_id + ym, data = panel, cluster = ~la_id)

setFixest_dict(c(
  "post:excess_mass" = "Post $\\times$ Excess Mass",
  ln_txn = "Log(All Txn)",
  ln_txn_200_350 = "Log(Txn \\pounds200--350k)",
  dead_zone_share = "Dead Zone Share",
  "log(n_txn_dead_zone + 1)" = "Log(Dead Zone)"
))

tab2_tex <- etable(m1, m2, m3, m4,
                   se.below = TRUE,
                   keep = "Post",
                   fitstat = c("n", "wr2"),
                   style.tex = style.tex("aer"),
                   tex = TRUE)

writeLines(tab2_tex, "tables/tab2_main.tex")
cat("Table 2 written.\n")

## ============================================================
## Table 3: Robustness
## ============================================================
panel_placebo <- panel[ym < 201412]
panel_placebo[, post_placebo := as.integer(ym >= 201301)]
r1 <- feols(ln_txn_200_350 ~ post_placebo:excess_mass | la_id + ym,
            data = panel_placebo, cluster = ~la_id)

london_districts <- c("CITY OF LONDON", "BARKING AND DAGENHAM", "BARNET",
  "BEXLEY", "BRENT", "BROMLEY", "CAMDEN", "CROYDON", "EALING", "ENFIELD",
  "GREENWICH", "HACKNEY", "HAMMERSMITH AND FULHAM", "HARINGEY", "HARROW",
  "HAVERING", "HILLINGDON", "HOUNSLOW", "ISLINGTON", "KENSINGTON AND CHELSEA",
  "KINGSTON UPON THAMES", "LAMBETH", "LEWISHAM", "MERTON", "NEWHAM",
  "REDBRIDGE", "RICHMOND UPON THAMES", "SOUTHWARK", "SUTTON",
  "TOWER HAMLETS", "WALTHAM FOREST", "WANDSWORTH", "WESTMINSTER")

r2 <- feols(ln_txn_200_350 ~ post:excess_mass | la_id + ym,
            data = panel[!district %in% london_districts], cluster = ~la_id)

panel[, time_idx := as.integer(as.factor(ym))]
r3 <- feols(ln_txn_200_350 ~ post:excess_mass | la_id[time_idx] + ym,
            data = panel, cluster = ~la_id)

r4 <- feols(ln_txn_200_350 ~ post:dead_zone_depth | la_id + ym,
            data = panel, cluster = ~la_id)

setFixest_dict(c(
  "post:excess_mass" = "Post $\\times$ Excess Mass",
  "post_placebo:excess_mass" = "Placebo $\\times$ Excess Mass",
  "post:dead_zone_depth" = "Post $\\times$ DZ Depth",
  ln_txn_200_350 = "Log(Txn \\pounds200--350k)"
))

tab3_tex <- etable(m2, r1, r2, r3, r4,
                   headers = c("Baseline", "Placebo 2013", "Excl.\\\\ London",
                               "LA Trends", "DZ Depth"),
                   se.below = TRUE,
                   keep = c("Post", "Placebo"),
                   fitstat = c("n", "wr2"),
                   style.tex = style.tex("aer"),
                   tex = TRUE)

writeLines(tab3_tex, "tables/tab3_robustness.tex")
cat("Table 3 written.\n")

## ============================================================
## Table F1: Standardized Effect Sizes
## ============================================================
outcomes <- list(
  list(name = "Log(All Transactions)", model = m1, var = "ln_txn"),
  list(name = "Log(Txn \\pounds200--350k)", model = m2, var = "ln_txn_200_350"),
  list(name = "Dead Zone Share", model = m3, var = "dead_zone_share"),
  list(name = "Log(Dead Zone Count)", model = m4, var = NULL)
)

sd_x <- sd(panel$excess_mass)

sde_rows <- lapply(outcomes, function(o) {
  beta <- coef(o$model)[[1]]
  se_b <- se(o$model)[[1]]
  if (!is.null(o$var)) {
    sd_y <- sd(panel[[o$var]], na.rm = TRUE)
  } else {
    sd_y <- sd(log(panel$n_txn_dead_zone + 1))
  }
  sde <- beta * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  cls <- if (sde < -0.15) "Large neg." else if (sde < -0.05) "Mod. neg." else
    if (sde < -0.005) "Small neg." else if (sde <= 0.005) "Null" else
    if (sde <= 0.05) "Small pos." else if (sde <= 0.15) "Mod. pos." else "Large pos."
  data.frame(Outcome = o$name, Beta = beta, SE = se_b, SD_Y = sd_y,
             SDE = sde, SE_SDE = se_sde, Classification = cls)
})

sde_df <- do.call(rbind, sde_rows)
f3 <- function(x) formatC(x, format = "f", digits = 3)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n",
  "\\small\n\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n"
)
for (i in 1:nrow(sde_df)) {
  tabF1 <- paste0(tabF1, sde_df$Outcome[i], " & ", f3(sde_df$Beta[i]), " & ",
    f3(sde_df$SE[i]), " & ", f3(sde_df$SD_Y[i]), " & ", f3(sde_df$SDE[i]), " & ",
    f3(sde_df$SE_SDE[i]), " & ", sde_df$Classification[i], " \\\\\n")
}
tabF1 <- paste0(tabF1,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{minipage}{0.95\\textwidth}\\vspace{0.3em}\n",
  "\\footnotesize\\textit{Notes:} ",
  "Effect of the December 2014 SDLT notch abolition on housing market outcomes. ",
  "Continuous treatment: pre-reform excess mass ratio at \\pounds250k notch. ",
  "Data: HM Land Registry Price Paid Data, 2010--2019. ",
  "Sample: ", format(nrow(panel), big.mark = ","), " LA--month observations, ",
  uniqueN(panel$district), " LAs. ",
  "SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. ",
  "Classification refers to magnitude, not statistical significance.\n",
  "\\end{minipage}\n\\end{table}\n"
)
writeLines(tabF1, "tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")
cat("All tables generated.\n")
