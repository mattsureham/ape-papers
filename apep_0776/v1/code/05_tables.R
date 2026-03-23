# ==============================================================================
# 05_tables.R — Generate All Tables
# Paper: Working Themselves to Death? (apep_0776)
# ==============================================================================

source("00_packages.R")

results     <- readRDS("../data/main_results.rds")
robustness  <- readRDS("../data/robustness_results.rds")
panel       <- readRDS("../data/panel.rds")
fornero     <- readRDS("../data/fornero_bite.rds")

dir.create("../tables", showWarnings = FALSE)

# Helper: format coefficient with stars
fmt_coef <- function(fit, var = 1) {
  b <- coef(fit)[var]
  se <- sqrt(vcov(fit)[var, var])
  p <- fixest::pvalue(fit)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.4f%s", b, stars), se = sprintf("(%.4f)", se),
       b = b, se_val = se, p = p)
}

# ===== TABLE 1: Summary Statistics =====
cat("Generating Table 1: Summary Statistics...\n")

pre_data <- panel %>% filter(year <= 2011)

summ_by_sex <- pre_data %>%
  group_by(sex) %>%
  summarise(
    n_regions = n_distinct(geo),
    mean_death_rate = mean(death_rate, na.rm = TRUE),
    sd_death_rate = sd(death_rate, na.rm = TRUE),
    mean_fbite = mean(fbite, na.rm = TRUE),
    sd_fbite = sd(fbite, na.rm = TRUE),
    .groups = "drop"
  )

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Italian NUTS2 Regions, Pre-Reform (2000--2011)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Male} & \\multicolumn{2}{c}{Female} \\\\",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline"
)

m <- summ_by_sex %>% filter(sex == "M")
f <- summ_by_sex %>% filter(sex == "F")

tab1 <- c(tab1,
  sprintf("Death Rate (per 100K, ages 55--64) & %.1f & %.1f & %.1f & %.1f \\\\",
          m$mean_death_rate, m$sd_death_rate, f$mean_death_rate, f$sd_death_rate),
  sprintf("Fornero Bite (pp $\\Delta$ emp. rate) & %.1f & %.1f & %.1f & %.1f \\\\",
          m$mean_fbite, m$sd_fbite, f$mean_fbite, f$sd_fbite),
  sprintf("NUTS2 Regions & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          m$n_regions, f$n_regions),
  sprintf("Region $\\times$ Year Obs. & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          sum(pre_data$sex == "M"), sum(pre_data$sex == "F")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Death rates computed from Eurostat \\texttt{demo\\_r\\_magec3} (deaths by",
  "single year of age) and \\texttt{demo\\_r\\_pjangroup} (population denominators). Fornero bite",
  "is the change in employment rate among 55--64 year-olds from 2010 to 2014 (Eurostat",
  "\\texttt{lfst\\_r\\_lfe2emprt}), measuring the reform's differential impact on regional",
  "labor force retention. 21 Italian NUTS2 regions, 2000--2011.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ===== TABLE 2: Main Results =====
cat("Generating Table 2: Main Results...\n")

r_pool <- fmt_coef(results$main)
r_male <- fmt_coef(results$male)
r_fem  <- fmt_coef(results$female)
r_ddd  <- fmt_coef(results$ddd, var = "treat:female")
r_plac <- fmt_coef(results$placebo)

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Fornero Bite on Log Mortality Rate (Ages 55--64)}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Pooled & Male & Female & DDD & Placebo \\\\",
  " & & & & (Female $\\times$) & (45--54) \\\\",
  "\\hline",
  sprintf("Bite $\\times$ Post & %s & %s & %s & & %s \\\\",
          r_pool$coef, r_male$coef, r_fem$coef, r_plac$coef),
  sprintf(" & %s & %s & %s & & %s \\\\",
          r_pool$se, r_male$se, r_fem$se, r_plac$se),
  sprintf("Female $\\times$ Bite $\\times$ Post & & & & %s & \\\\",
          r_ddd$coef),
  sprintf(" & & & & %s & \\\\", r_ddd$se),
  "\\hline",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          formatC(nobs(results$main), big.mark = ","),
          formatC(nobs(results$male), big.mark = ","),
          formatC(nobs(results$female), big.mark = ","),
          formatC(nobs(results$ddd), big.mark = ","),
          formatC(nobs(results$placebo), big.mark = ",")),
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Sex FE & & & & Yes & \\\\",
  "Age Group & 55--64 & 55--64 & 55--64 & 55--64 & 45--54 \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is log death rate per 100,000 population.",
  "``Bite'' is the Fornero reform intensity (change in employment rate among 55--64",
  "year-olds from 2010 to 2014). Column 4 adds the interaction with a female indicator.",
  "Column 5 uses ages 45--54 as a placebo (unaffected by pension reform).",
  "Standard errors clustered at NUTS2 region level.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ===== TABLE 3: Robustness =====
cat("Generating Table 3: Robustness...\n")

rob_fits <- list(
  robustness$levels,
  robustness$trends,
  robustness$no_extreme,
  robustness$short_pre,
  robustness$female_only
)
rob_labels <- c("Levels", "Region\\\\Trends", "No Extreme\\\\Regions",
                "Short Pre\\\\(2005+)", "Female\\\\Only")

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  paste0(" & \\shortstack{", paste(rob_labels, collapse = "} & \\shortstack{"), "} \\\\"),
  "\\hline"
)

rob_coefs <- sapply(rob_fits, function(f) {
  r <- fmt_coef(f)
  r$coef
})
rob_ses <- sapply(rob_fits, function(f) {
  r <- fmt_coef(f)
  r$se
})
rob_n <- sapply(rob_fits, function(f) formatC(nobs(f), big.mark = ","))

tab3 <- c(tab3,
  paste0("Treatment & ", paste(rob_coefs, collapse = " & "), " \\\\"),
  paste0(" & ", paste(rob_ses, collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Observations & ", paste(rob_n, collapse = " & "), " \\\\"),
  "Region FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Column 1 uses death rate in levels (per 100K) instead of logs.",
  "Column 2 adds region-specific linear time trends. Column 3 drops the two regions",
  "with the highest and lowest Fornero bite. Column 4 restricts the pre-period to",
  "2005--2011. Column 5 uses female subsample only (highest reform dose).",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# ===== TABLE F1: SDE =====
cat("Generating SDE Table...\n")

# Pre-treatment SD of log death rate
pre_sd <- panel %>%
  filter(year <= 2011) %>%
  summarise(
    sd_log_dr = sd(log_death_rate, na.rm = TRUE),
    sd_dr = sd(death_rate, na.rm = TRUE)
  )

sde_rows <- list()

# Pooled
b <- coef(results$main)[1]
se_b <- sqrt(vcov(results$main)[1,1])
sd_y <- pre_sd$sd_log_dr
sde_rows[["pooled"]] <- c("All-cause mortality (55--64)", b, se_b, sd_y, b/sd_y, se_b/sd_y)

# Male
b <- coef(results$male)[1]
se_b <- sqrt(vcov(results$male)[1,1])
sd_y_m <- panel %>% filter(year <= 2011, sex == "M") %>% pull(log_death_rate) %>% sd(na.rm = TRUE)
sde_rows[["male"]] <- c("Male mortality (55--64)", b, se_b, sd_y_m, b/sd_y_m, se_b/sd_y_m)

# Female
b <- coef(results$female)[1]
se_b <- sqrt(vcov(results$female)[1,1])
sd_y_f <- panel %>% filter(year <= 2011, sex == "F") %>% pull(log_death_rate) %>% sd(na.rm = TRUE)
sde_rows[["female"]] <- c("Female mortality (55--64)", b, se_b, sd_y_f, b/sd_y_f, se_b/sd_y_f)

# Placebo
b <- coef(results$placebo)[1]
se_b <- sqrt(vcov(results$placebo)[1,1])
sd_y_p <- panel %>% filter(year <= 2011) %>% pull(log_death_rate) %>% sd(na.rm = TRUE)
sde_rows[["placebo"]] <- c("Placebo mortality (45--54)", b, se_b, sd_y_p, b/sd_y_p, se_b/sd_y_p)

classify_sde <- function(s) {
  s <- as.numeric(s)
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_tab <- do.call(rbind, lapply(sde_rows, function(r) {
  data.frame(
    Outcome = r[1],
    Beta = sprintf("%.5f", as.numeric(r[2])),
    SE = sprintf("%.5f", as.numeric(r[3])),
    SD_Y = sprintf("%.3f", as.numeric(r[4])),
    SDE = sprintf("%.4f", as.numeric(r[5])),
    SE_SDE = sprintf("%.4f", as.numeric(r[6])),
    Classification = classify_sde(r[5]),
    stringsAsFactors = FALSE
  )
}))

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Italy. ",
  "\\textbf{Research question:} Did Italy's 2011 Fornero pension reform---which suddenly raised retirement ages, disproportionately affecting women and trapping approximately 350,000 workers without pension or employment---increase age-specific mortality among 55--64 year-olds? ",
  "\\textbf{Policy mechanism:} The Monti-Fornero reform (Law 214/2011) raised old-age retirement from 60 to 67 for women (up to 7-year increase) and 65 to 67 for men (up to 2-year increase), abolishing seniority pensions and creating cross-regional variation in forced labor retention among older workers. ",
  "\\textbf{Outcome definition:} Log death rate per 100,000 population ages 55--64, constructed from Eurostat single-year-of-age death counts and population denominators at the NUTS2 level. ",
  "\\textbf{Treatment:} Continuous---Fornero bite (percentage point change in 55--64 employment rate from 2010 to 2014) interacted with post-reform indicator. ",
  "\\textbf{Data:} Eurostat \\texttt{demo\\_r\\_magec3} (deaths), \\texttt{demo\\_r\\_pjangroup} (population), \\texttt{lfst\\_r\\_lfe2emprt} (employment); 21 Italian NUTS2 regions, 2000--2020. ",
  "\\textbf{Method:} Two-way fixed effects (region + year) with continuous treatment intensity; gender dose-response (DDD); age-group placebo (45--54). Standard errors clustered at NUTS2 level. ",
  "\\textbf{Sample:} All 21 Italian NUTS2 regions, both sexes, 2000--2020 (12-year pre-period, 9-year post-period). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(sde_tab)) {
  sde_tex <- c(sde_tex, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_tab$Outcome[i], sde_tab$Beta[i], sde_tab$SE[i],
    sde_tab$SD_Y[i], sde_tab$SDE[i], sde_tab$SE_SDE[i],
    sde_tab$Classification[i]
  ))
}

sde_tex <- c(sde_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
