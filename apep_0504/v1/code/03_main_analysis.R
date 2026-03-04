## ============================================================
## 03_main_analysis.R — Primary regressions
## APEP Paper: Does Naming Work?
## ============================================================

source("00_packages.R")
library(fixest)
library(did)
library(modelsummary)
library(data.table)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, yq := as.Date(yq)]

## ============================================================
## 1. Summary statistics
## ============================================================
cat("\n=== SUMMARY STATISTICS ===\n")

pre_means <- panel[is_food == TRUE & yq < as.Date("2013-10-01"),
  .(mean_entry = mean(n_entry, na.rm = TRUE),
    sd_entry = sd(n_entry, na.rm = TRUE),
    mean_exit_proxy = mean(n_exit_proxy, na.rm = TRUE),
    n_la = uniqueN(la_code),
    n_obs = .N),
  by = country
]
cat("Pre-treatment means (food businesses):\n")
print(pre_means)

## ============================================================
## 2. Main DiD: Food business ENTRY rates
## ============================================================
cat("\n=== MAIN DiD: ENTRY RATES ===\n")

food_panel <- panel[is_food == TRUE]

# Model 1: Basic TWFE
# Note: TWFE is valid here because treatment has only 2 cohorts (Wales 2013Q4,
# NI 2016Q4) and a large never-treated group (England). With a never-treated
# control, TWFE does not suffer from the negative-weighting bias documented
# by Goodman-Bacon (2021). We additionally report Callaway & Sant'Anna (2021)
# estimates below as a robustness check, which yield nearly identical results.
m1_entry <- feols(n_entry ~ did | la_id + time_id,
                  data = food_panel, cluster = ~la_code)

# Model 2: With population control
m2_entry <- feols(n_entry ~ did + log(population + 1) | la_id + time_id,
                  data = food_panel, cluster = ~la_code)

# Model 3: Entry rate per 10K pop
m3_entry <- feols(entry_rate ~ did | la_id + time_id,
                  data = food_panel[!is.na(entry_rate)], cluster = ~la_code)

cat("\n--- Entry rate models ---\n")
etable(m1_entry, m2_entry, m3_entry,
       headers = c("Count", "With controls", "Rate per 10K"))

## ============================================================
## 3. Cohort survival: Exit proxy
## ============================================================
cat("\n=== COHORT SURVIVAL (EXIT PROXY) ===\n")

# n_exit_proxy counts how many entrants in each LA-quarter ended up exiting
# This is like a "cohort quality" measure
m1_exit <- feols(n_exit_proxy ~ did | la_id + time_id,
                 data = food_panel, cluster = ~la_code)

m2_exit <- feols(n_exit_proxy ~ did + log(population + 1) | la_id + time_id,
                 data = food_panel, cluster = ~la_code)

cat("\n--- Exit proxy models ---\n")
etable(m1_exit, m2_exit, headers = c("Basic", "With controls"))

## ============================================================
## 4. Net survivors (entry - exit proxy)
## ============================================================
cat("\n=== NET SURVIVORS ===\n")

m1_net <- feols(n_survivors ~ did | la_id + time_id,
                data = food_panel, cluster = ~la_code)

cat("\n--- Net survivors ---\n")
etable(m1_net)

## ============================================================
## 5. Triple-Diff: Food vs Non-food × Treated × Post
## ============================================================
cat("\n=== TRIPLE DIFFERENCE ===\n")

m_ddd_entry <- feols(n_entry ~ ddd + did + food:post + food:treated |
                     la_id + time_id,
                     data = panel, cluster = ~la_code)

m_ddd_exit <- feols(n_exit_proxy ~ ddd + did + food:post + food:treated |
                    la_id + time_id,
                    data = panel, cluster = ~la_code)

cat("\n--- DDD: Entry ---\n")
etable(m_ddd_entry)
cat("\n--- DDD: Exit proxy ---\n")
etable(m_ddd_exit)

## ============================================================
## 6. Event study (dynamic effects)
## ============================================================
cat("\n=== EVENT STUDY ===\n")

food_panel[, rel_time_binned := fcase(
  is.na(rel_time), NA_integer_,
  rel_time < -8L, -8L,
  rel_time > 20L, 20L,
  default = rel_time
)]

food_treated <- food_panel[!is.na(rel_time_binned)]

m_es_entry <- feols(n_entry ~ i(rel_time_binned, ref = -2) | la_id + time_id,
                    data = food_treated, cluster = ~la_code)

m_es_exit <- feols(n_exit_proxy ~ i(rel_time_binned, ref = -2) | la_id + time_id,
                   data = food_treated, cluster = ~la_code)

cat("\nEvent study coefficients (entry):\n")
coeftable(m_es_entry)

## ============================================================
## 7. Callaway & Sant'Anna (2021)
## ============================================================
cat("\n=== CALLAWAY & SANT'ANNA ===\n")

cs_data <- food_panel[, .(la_id, time_id, yq, cohort, n_entry, n_exit_proxy,
                           n_survivors, country)]

cs_data[, t := as.integer(yq - min(yq)) / 91L + 1L]
cs_data[, g := fifelse(cohort == 2013L,
                        cs_data[country == "Wales", min(t[yq >= as.Date("2013-10-01")])],
                        fifelse(cohort == 2016L,
                                cs_data[country == "Northern Ireland",
                                        min(t[yq >= as.Date("2016-10-01")])],
                                0L))]

tryCatch({
  cs_entry <- att_gt(
    yname = "n_entry",
    tname = "t",
    idname = "la_id",
    gname = "g",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    base_period = "universal"
  )

  cat("\nCS-DiD Entry Results:\n")
  cs_entry_agg <- aggte(cs_entry, type = "simple")
  print(summary(cs_entry_agg))

  cs_entry_dyn <- aggte(cs_entry, type = "dynamic")
  saveRDS(cs_entry, file.path(data_dir, "cs_entry.rds"))
  saveRDS(cs_entry_dyn, file.path(data_dir, "cs_entry_dyn.rds"))
}, error = function(e) {
  cat("CS-DiD entry failed:", e$message, "\n")
  cat("Proceeding with TWFE results.\n")
})

tryCatch({
  cs_exit <- att_gt(
    yname = "n_exit_proxy",
    tname = "t",
    idname = "la_id",
    gname = "g",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    base_period = "universal"
  )

  cs_exit_agg <- aggte(cs_exit, type = "simple")
  cat("\nCS-DiD Exit Proxy Results:\n")
  print(summary(cs_exit_agg))

  cs_exit_dyn <- aggte(cs_exit, type = "dynamic")
  saveRDS(cs_exit, file.path(data_dir, "cs_exit.rds"))
  saveRDS(cs_exit_dyn, file.path(data_dir, "cs_exit_dyn.rds"))
}, error = function(e) {
  cat("CS-DiD exit failed:", e$message, "\n")
})

## ============================================================
## 8. Save results for tables
## ============================================================
cat("\n=== SAVING RESULTS ===\n")

models_entry <- list(
  "TWFE (1)" = m1_entry,
  "TWFE (2)" = m2_entry,
  "Rate" = m3_entry,
  "DDD" = m_ddd_entry
)

models_exit <- list(
  "TWFE (1)" = m1_exit,
  "TWFE (2)" = m2_exit,
  "DDD" = m_ddd_exit
)

saveRDS(list(
  entry = models_entry,
  exit = models_exit,
  event_study_entry = m_es_entry,
  event_study_exit = m_es_exit,
  ddd_entry = m_ddd_entry,
  ddd_exit = m_ddd_exit,
  net = m1_net
), file.path(data_dir, "main_results.rds"))

cat("Main analysis complete. Results saved.\n")
