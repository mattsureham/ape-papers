## 03_main_analysis.R — Primary regressions
## APEP-1133: The Tenure Shield

source("00_packages.R")

data_dir <- "../data"

acc  <- readRDS(file.path(data_dir, "accidents_clean.rds"))
## Panel loaded later to save memory

cat("=== Individual-level analysis ===\n")
cat("Sample:", nrow(acc), "injuries at", n_distinct(acc$mine_id), "mines\n\n")

## ================================================================
## PART A: Individual-level severity decomposition
## ================================================================

## --- A1: Baseline OLS — Days lost on experience dimensions ---
## Key: mine_exper coefficient with tot_exper controlled
m1 <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
              mine_id + cal_yr,
            data = acc, cluster = ~mine_id)

## --- A2: Add occupation and subunit FEs ---
m2 <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
              mine_id + cal_yr + occ_cd + subunit,
            data = acc, cluster = ~mine_id)

## --- A3: Binary extensive margin (any days lost) ---
m3 <- feols(any_days_lost ~ mine_exper + tot_exper + job_exper |
              mine_id + cal_yr + occ_cd + subunit,
            data = acc, cluster = ~mine_id)

## --- A4: High severity (fatality, perm disability, days away, restricted) ---
## high_severity already constructed in 02_clean_data.R
m4 <- feols(high_severity ~ mine_exper + tot_exper + job_exper |
              mine_id + cal_yr + occ_cd + subunit,
            data = acc, cluster = ~mine_id)

## --- A5: Days away (levels) ---
m5 <- feols(days_away ~ mine_exper + tot_exper + job_exper |
              mine_id + cal_yr + occ_cd + subunit,
            data = acc, cluster = ~mine_id)

cat("\n--- Table 1: Experience Decomposition ---\n")
etable(m1, m2, m3, m4, m5,
       headers = c("log(days+1)", "log(days+1)", "Any days lost",
                    "High severity", "Days away"),
       keep = c("mine_exper", "tot_exper", "job_exper"))

## ================================================================
## PART B: Nonlinear tenure effects (spline)
## ================================================================

## Natural cubic spline with knots at 1, 3, 5, 10 years
acc <- acc %>%
  mutate(
    mine_sp1 = pmin(mine_exper, 1),
    mine_sp2 = pmax(pmin(mine_exper, 3) - 1, 0),
    mine_sp3 = pmax(pmin(mine_exper, 5) - 3, 0),
    mine_sp4 = pmax(pmin(mine_exper, 10) - 5, 0),
    mine_sp5 = pmax(mine_exper - 10, 0)
  )

m_spline <- feols(log_days_lost ~ mine_sp1 + mine_sp2 + mine_sp3 + mine_sp4 + mine_sp5 +
                    tot_exper + job_exper |
                    mine_id + cal_yr + occ_cd + subunit,
                  data = acc, cluster = ~mine_id)

cat("\n--- Spline results (mine tenure) ---\n")
etable(m_spline, keep = "mine_sp")

## ================================================================
## PART C: Mine-quarter panel — New arrivals and injury rates
## ================================================================

## ================================================================
## PART C: Mine-year panel — Load panel data now
## ================================================================
cat("\n=== Mine-year panel analysis ===\n")

## Save individual-level results before freeing memory
indiv_results <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m_spline = m_spline)
saveRDS(indiv_results, file.path(data_dir, "indiv_results.rds"))

## Free individual-level model objects to reclaim memory
rm(m1, m2, m3, m4, m5, m_spline, indiv_results)
gc()

panel <- readRDS(file.path(data_dir, "mine_panel.rds"))

## Build mine-year panel via data.table
panel_dt <- as.data.table(panel)
panel_yr <- panel_dt[, .(
  avg_emp = mean(avg_emp, na.rm = TRUE),
  hours = sum(hours, na.rm = TRUE),
  n_injuries = sum(n_injuries, na.rm = TRUE)
), by = .(mine_id, cal_yr)]
rm(panel_dt, panel)
gc()

panel_yr <- panel_yr[hours > 0 & avg_emp > 0]
panel_yr[, injury_rate := n_injuries / hours * 200000]

acc_dt <- as.data.table(acc)
mine_yr_arr <- acc_dt[, .(
  frac_new = mean(new_arrival, na.rm = TRUE),
  n_acc = .N
), by = .(mine_id, cal_yr)]
rm(acc_dt)

panel_yr <- merge(panel_yr, mine_yr_arr, by = c("mine_id", "cal_yr"), all.x = TRUE)
panel_yr[is.na(frac_new), frac_new := 0]

mines_with_acc <- unique(mine_yr_arr$mine_id)
panel_active <- panel_yr[mine_id %in% mines_with_acc]
cat("Active mines panel:", nrow(panel_active), "obs,",
    uniqueN(panel_active$mine_id), "mines\n")

m_panel1 <- feols(injury_rate ~ frac_new |
                    mine_id + cal_yr,
                  data = panel_active, cluster = ~mine_id)

m_panel2 <- feols(injury_rate ~ frac_new + log(avg_emp) |
                    mine_id + cal_yr,
                  data = panel_active, cluster = ~mine_id)

cat("\n--- Table 3: Mine-Year Panel ---\n")
etable(m_panel1, m_panel2,
       headers = c("Injury rate", "Injury rate + controls"),
       keep = c("frac_new", "log"))

## ================================================================
## PART D: Heterogeneity — Underground vs Surface
## ================================================================

cat("\n=== Heterogeneity: Underground vs Surface ===\n")

## Merge mine type to individual data
m_under <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
                   mine_id + cal_yr + occ_cd,
                 data = acc %>% filter(mine_type == "Underground"),
                 cluster = ~mine_id)

m_surface <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
                     mine_id + cal_yr + occ_cd,
                   data = acc %>% filter(mine_type == "Surface"),
                   cluster = ~mine_id)

cat("\n--- Underground vs Surface ---\n")
etable(m_under, m_surface,
       headers = c("Underground", "Surface"),
       keep = c("mine_exper", "tot_exper", "job_exper"))

## ================================================================
## PART E: Heterogeneity — Coal vs Metal/NonMetal
## ================================================================

m_coal <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
                  mine_id + cal_yr + occ_cd,
                data = acc %>% filter(coal_metal == "C"),
                cluster = ~mine_id)

m_metal <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
                   mine_id + cal_yr + occ_cd,
                 data = acc %>% filter(coal_metal == "M"),
                 cluster = ~mine_id)

cat("\n--- Coal vs Metal/NonMetal ---\n")
etable(m_coal, m_metal,
       headers = c("Coal", "Metal/NonMetal"),
       keep = c("mine_exper", "tot_exper", "job_exper"))

## ================================================================
## Save results for tables
## ================================================================

## Reload individual results and combine
indiv_results <- readRDS(file.path(data_dir, "indiv_results.rds"))
results <- c(indiv_results, list(
  m_panel1 = m_panel1, m_panel2 = m_panel2,
  m_under = m_under, m_surface = m_surface,
  m_coal = m_coal, m_metal = m_metal
))

saveRDS(results, file.path(data_dir, "main_results.rds"))

## ================================================================
## Diagnostics for validator
## ================================================================
diag <- list(
  n_treated = n_distinct(acc$mine_id[acc$new_arrival == 1]),
  n_pre = length(unique(acc$cal_yr[acc$cal_yr < 2010])),  # pre-period years
  n_obs = nrow(acc)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics written: n_treated =", diag$n_treated,
    ", n_obs =", diag$n_obs, "\n")

## ================================================================
## Compute key numbers for the paper
## ================================================================
cat("\n=== Key numbers for paper text ===\n")
m2 <- results$m2
cat("mine_exper coef (preferred, m2):", round(coef(m2)["mine_exper"], 4), "\n")
cat("tot_exper coef (preferred, m2):", round(coef(m2)["tot_exper"], 4), "\n")
cat("job_exper coef (preferred, m2):", round(coef(m2)["job_exper"], 4), "\n")
cat("mine_exper SE:", round(se(m2)["mine_exper"], 4), "\n")

## SD of log_days_lost for SDE computation
cat("SD(log_days_lost):", round(sd(acc$log_days_lost), 4), "\n")
cat("SD(days_away):", round(sd(acc$days_away), 4), "\n")
cat("SD(mine_exper):", round(sd(acc$mine_exper), 4), "\n")

## Effect interpretation
beta_mine <- coef(m2)["mine_exper"]
cat("\nInterpretation: One additional year of mine-specific tenure\n")
cat("  reduces log(days_lost+1) by", round(abs(beta_mine), 4), "\n")
cat("  ≈", round(abs(beta_mine) * 100, 2), "% reduction in days lost\n")
