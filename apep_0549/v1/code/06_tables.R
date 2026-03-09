## =============================================================================
## 06_tables.R — All tables for the paper
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
tab_dir  <- "../tables/"
dir.create(tab_dir, showWarnings = FALSE)

## -----------------------------------------------------------------------------
## Table 1: Summary Statistics
## -----------------------------------------------------------------------------

cat("Table 1: Summary statistics...\n")

state_year <- fread(file.path(data_dir, "state_year_panel.csv"))

# Panel A: Full sample
panelA <- state_year[, .(
  mean_val = c(mean(alcohol_crashes), mean(non_alc_crashes),
               mean(alc_rate), mean(non_alc_rate),
               mean(sunday_alc), mean(nfl_sun_alc),
               mean(night_alc), mean(pop / 1e6)),
  sd_val = c(sd(alcohol_crashes), sd(non_alc_crashes),
             sd(alc_rate), sd(non_alc_rate),
             sd(sunday_alc), sd(nfl_sun_alc),
             sd(night_alc), sd(pop / 1e6)),
  variable = c("Alcohol-involved fatal crashes", "Non-alcohol fatal crashes",
                "Alcohol crash rate (per 100K)", "Non-alcohol crash rate (per 100K)",
                "Sunday alcohol crashes", "NFL Sunday alcohol crashes",
                "Nighttime alcohol crashes (8PM-3AM)", "Population (millions)")
)]

# Panel B: By treatment status
panelB_treat <- state_year[ever_treated == 1, .(
  mean_val = c(mean(alc_rate), mean(non_alc_rate)),
  sd_val = c(sd(alc_rate), sd(non_alc_rate)),
  variable = c("Alcohol crash rate (per 100K)", "Non-alcohol crash rate (per 100K)")
)]
panelB_treat[, group := "Treated states"]

panelB_ctrl <- state_year[ever_treated == 0, .(
  mean_val = c(mean(alc_rate), mean(non_alc_rate)),
  sd_val = c(sd(alc_rate), sd(non_alc_rate)),
  variable = c("Alcohol crash rate (per 100K)", "Non-alcohol crash rate (per 100K)")
)]
panelB_ctrl[, group := "Control states"]

sumstats_out <- rbind(
  panelA[, .(variable, mean = round(mean_val, 2), sd = round(sd_val, 2))],
  fill = TRUE
)

fwrite(sumstats_out, file.path(tab_dir, "table1_sumstats.csv"))

# LaTeX output
sink(file.path(tab_dir, "table1_sumstats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:sumstats}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("Variable & Mean & SD \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(sumstats_out)) {
  cat(sprintf("%s & %.2f & %.2f \\\\\n",
              sumstats_out$variable[i], sumstats_out$mean[i], sumstats_out$sd[i]))
}
cat("\\midrule\n")
cat(sprintf("State-years & \\multicolumn{2}{c}{%d} \\\\\n", nrow(state_year)))
cat(sprintf("States & \\multicolumn{2}{c}{%d} \\\\\n",
            uniqueN(state_year$state_fips)))
cat(sprintf("Years & \\multicolumn{2}{c}{%d---%d} \\\\\n",
            min(state_year$YEAR), max(state_year$YEAR)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\end{table}\n")
sink()

## -----------------------------------------------------------------------------
## Table 2: Main Results (DDD and DiD)
## -----------------------------------------------------------------------------

cat("Table 2: Main results...\n")

load(file.path(data_dir, "main_models.RData"))

# Use modelsummary for clean regression table
models_main <- list(
  "(1) DDD" = ddd1,
  "(2) Placebo" = ddd_placebo,
  "(3) Night" = ddd_night,
  "(4) DD" = dd1,
  "(5) TWFE-M" = twfe_monthly,
  "(6) TWFE-Y" = twfe_annual
)

cm <- c(
  "legal_x_sunday_x_nfl" = "Legal $\\times$ Sunday $\\times$ NFL",
  "legal_x_sunday" = "Legal $\\times$ Sunday",
  "treated" = "Legal (post)"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3)
)

# Generate table
tryCatch({
  modelsummary(
    models_main,
    coef_map = cm,
    gof_map = gm,
    stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
    output = file.path(tab_dir, "table2_main.tex"),
    escape = FALSE
  )
  cat("  Table 2 saved as LaTeX\n")
}, error = function(e) {
  cat("  modelsummary failed:", e$message, "\n")
  cat("  Writing manual table instead...\n")

  main_results <- fread(file.path(data_dir, "main_results.csv"))

  sink(file.path(tab_dir, "table2_main.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Main Results: Online Sports Betting and Alcohol-Involved Fatal Crashes}\n")
  cat("\\label{tab:main}\n")
  cat("\\begin{adjustbox}{max width=\\textwidth}\n")
  cat("\\begin{tabular}{lcccc}\n")
  cat("\\toprule\n")
  cat(" & DDD & Placebo & DD & TWFE \\\\\n")
  cat(" & (1) & (2) & (3) & (4) \\\\\n")
  cat("\\midrule\n")
  for (i in 1:nrow(main_results)) {
    cat(sprintf("%s & %.4f%s \\\\\n",
                main_results$model[i], main_results$coef[i], main_results$stars[i]))
    cat(sprintf(" & (%.4f) \\\\\n", main_results$se[i]))
  }
  cat("\\bottomrule\n")
  cat("\\end{tabular}\n")
  cat("\\end{adjustbox}\n")
  cat("\\end{table}\n")
  sink()
})

## -----------------------------------------------------------------------------
## Table 3: Mechanism Tests
## -----------------------------------------------------------------------------

cat("Table 3: Mechanism tests...\n")

load(file.path(data_dir, "robustness_models.RData"))

models_mech <- list(
  "(1) NFL Season" = dd_nfl,
  "(2) Off-Season" = dd_offseason,
  "(3) Night" = ddd_night,
  "(4) Day" = ddd_day,
  "(5) No COVID" = ddd_nocovid
)

tryCatch({
  modelsummary(
    models_mech,
    coef_map = cm,
    gof_map = gm,
    stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
    output = file.path(tab_dir, "table3_mechanism.tex"),
    escape = FALSE
  )
  cat("  Table 3 saved as LaTeX\n")
}, error = function(e) {
  cat("  Table 3 modelsummary failed:", e$message, "; writing CSV fallback\n")
  robust_summary <- fread(file.path(data_dir, "robustness_summary.csv"))
  fwrite(robust_summary, file.path(tab_dir, "table3_mechanism.csv"))
})

## -----------------------------------------------------------------------------
## Table 4: Treatment dates
## -----------------------------------------------------------------------------

cat("Table 4: Treatment dates...\n")

fars <- fread(file.path(data_dir, "fars_panel.csv"))
treat_states <- unique(fars[ever_treated == 1, .(state_fips, treat_date)])
treat_states[, treat_date := as.Date(treat_date)]

state_names <- data.table(
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  state_name = c("Alabama", "Alaska", "Arizona", "Arkansas", "California",
                 "Colorado", "Connecticut", "Delaware", "DC", "Florida",
                 "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
                 "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
                 "Maryland", "Massachusetts", "Michigan", "Minnesota",
                 "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada",
                 "New Hampshire", "New Jersey", "New Mexico", "New York",
                 "North Carolina", "North Dakota", "Ohio", "Oklahoma",
                 "Oregon", "Pennsylvania", "Rhode Island",
                 "South Carolina", "South Dakota", "Tennessee", "Texas",
                 "Utah", "Vermont", "Virginia", "Washington", "West Virginia",
                 "Wisconsin", "Wyoming")
)

treat_states[, state_fips := as.character(state_fips)]
state_names[, state_fips := as.character(state_fips)]
treat_states <- merge(treat_states, state_names, by = "state_fips", all.x = TRUE)
setorder(treat_states, treat_date)

sink(file.path(tab_dir, "table4_treatment_dates.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Online Sports Betting Legalization Dates}\n")
cat("\\label{tab:treatment_dates}\n")
cat("\\begin{tabular}{llc}\n")
cat("\\toprule\n")
cat("State & Launch Date & Months in Sample \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(treat_states)) {
  months_post <- as.integer(difftime(as.Date("2023-12-31"),
                                      treat_states$treat_date[i],
                                      units = "days") / 30.44)
  months_post <- max(0, months_post)
  nm <- ifelse(is.na(treat_states$state_name[i]),
               treat_states$state_fips[i],
               treat_states$state_name[i])
  cat(sprintf("%s & %s & %d \\\\\n",
              nm, format(treat_states$treat_date[i], "%B %Y"), months_post))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables saved to tables/\n")
cat(sprintf("  %d files generated\n",
            length(list.files(tab_dir))))
