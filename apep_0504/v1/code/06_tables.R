## ============================================================
## 06_tables.R — All table generation
## APEP Paper: Does Naming Work?
## ============================================================

source("00_packages.R")
library(fixest)
library(modelsummary)
library(kableExtra)
library(data.table)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, yq := as.Date(yq)]
food_panel <- panel[is_food == TRUE]
results <- readRDS(file.path(data_dir, "main_results.rds"))

## ============================================================
## Table 1: Summary statistics
## ============================================================
cat("Creating Table 1: Summary statistics...\n")

pre_stats <- food_panel[yq < as.Date("2013-10-01"),
  .(
    `Mean entries/quarter` = round(mean(n_entry, na.rm = TRUE), 2),
    `SD entries/quarter` = round(sd(n_entry, na.rm = TRUE), 2),
    `Mean exit proxy` = round(mean(n_exit_proxy, na.rm = TRUE), 2),
    `N (LA x quarters)` = .N,
    `N LAs` = uniqueN(la_code)
  ),
  by = country
]

pre_kable <- kbl(pre_stats, format = "latex", booktabs = TRUE,
                  caption = "Pre-Treatment Summary Statistics (2008Q1--2013Q3)",
                  label = "summary") |>
  kable_styling(latex_options = c("hold_position"))

writeLines(pre_kable, file.path(tables_dir, "tab1_summary.tex"))

## ============================================================
## Table 2: Main DiD results
## ============================================================
cat("Creating Table 2: Main results...\n")

main_models <- list(
  "Entry (1)" = results$entry[["TWFE (1)"]],
  "Entry (2)" = results$entry[["TWFE (2)"]],
  "Entry Rate" = results$entry[["Rate"]],
  "Exit Proxy" = results$exit[["TWFE (1)"]],
  "Net" = results$net
)

etable(main_models,
  file = file.path(tables_dir, "tab2_main_results.tex"),
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2", "ar2"),
  dict = c(did = "Mandatory Display",
           `log(population + 1)` = "Log Population"),
  title = "Effect of Mandatory Food Hygiene Rating Display on Food Business Dynamics",
  label = "tab:main",
  notes = "All specifications include LA and quarter-year fixed effects. Standard errors clustered at the LA level in parentheses.",
  replace = TRUE
)

## ============================================================
## Table 3: Triple-diff (DDD) results
## ============================================================
cat("Creating Table 3: Triple-diff...\n")

ddd_models <- list(
  "Entry DDD" = results$ddd_entry,
  "Exit Proxy DDD" = results$ddd_exit
)

etable(ddd_models,
  file = file.path(tables_dir, "tab3_ddd.tex"),
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  dict = c(ddd = "Mandatory $\\times$ Post $\\times$ Food",
           did = "Mandatory $\\times$ Post",
           `food:post` = "Food $\\times$ Post",
           `food:treated` = "Food $\\times$ Treated"),
  title = "Triple-Difference: Food vs.\\ Non-Food Businesses",
  label = "tab:ddd",
  notes = "The coefficient of interest is the triple interaction (Mandatory $\\times$ Post $\\times$ Food). Non-food businesses serve as within-LA placebo group.",
  replace = TRUE
)

## ============================================================
## Table 4: Robustness checks
## ============================================================
cat("Creating Table 4: Robustness...\n")

rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

rob_models <- list(
  "Wales only" = rob$wales_only,
  "NI only" = rob$ni_only,
  "Excl. COVID" = rob$no_covid,
  "Short run" = rob$short_run,
  "Full sample" = rob$long_run
)

if (!is.null(rob$border)) {
  rob_models[["Border LAs"]] <- rob$border
}

etable(rob_models,
  file = file.path(tables_dir, "tab4_robustness.tex"),
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  dict = c(did = "Mandatory Display"),
  title = "Robustness: Food Business Entries Under Alternative Specifications",
  label = "tab:robust",
  notes = "Dependent variable: quarterly food business entry count. All specifications include LA and quarter-year fixed effects. Standard errors clustered at the LA level.",
  replace = TRUE
)

## ============================================================
## Table 5: Placebo test
## ============================================================
cat("Creating Table 5: Placebo...\n")

placebo_models <- list(
  "Food Entry" = results$entry[["TWFE (1)"]],
  "Non-food Entry" = rob$placebo_entry,
  "Food Exit Proxy" = results$exit[["TWFE (1)"]],
  "Non-food Exit Proxy" = rob$placebo_exit
)

etable(placebo_models,
  file = file.path(tables_dir, "tab5_placebo.tex"),
  style.tex = style.tex("aer"),
  fitstat = c("n", "r2"),
  dict = c(did = "Mandatory Display"),
  title = "Placebo Test: Food vs.\\ Non-Food Businesses",
  label = "tab:placebo",
  notes = "Non-food businesses (professional services, IT) should not respond to food hygiene rating display mandates.",
  replace = TRUE
)

## ============================================================
## Table 6: FHRS quality distribution
## ============================================================
cat("Creating Table 6: Quality distribution...\n")

fhrs_quality <- fread(file.path(data_dir, "fhrs_quality_by_la.csv"))
quality_summary <- fhrs_quality[,
  .(
    `Mean rating` = round(mean(mean_rating, na.rm = TRUE), 2),
    `\\% Low (0--2)` = round(mean(pct_low, na.rm = TRUE), 1),
    `\\% High (4--5)` = round(mean(pct_high, na.rm = TRUE), 1),
    `N establishments` = format(sum(n_establishments), big.mark = ","),
    `N LAs` = .N
  ),
  by = country
]

quality_kable <- kbl(quality_summary, format = "latex", booktabs = TRUE,
                      escape = FALSE,
                      caption = "Food Hygiene Rating Quality by Country (Current Snapshot)",
                      label = "quality") |>
  kable_styling(latex_options = c("hold_position"))

writeLines(quality_kable, file.path(tables_dir, "tab6_quality.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Tables saved to:", tables_dir, "\n")
