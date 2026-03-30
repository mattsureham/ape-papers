## 04_robustness.R — Robustness checks
## APEP-1133: The Tenure Shield

source("00_packages.R")

data_dir <- "../data"
acc <- readRDS(file.path(data_dir, "accidents_clean.rds"))

cat("=== Robustness Checks ===\n\n")

## ================================================================
## R1: Placebo — Job experience should matter LESS than mine experience
##     if the mechanism is site-specific knowledge
## ================================================================

cat("--- R1: Placebo test (job experience vs mine experience) ---\n")
## The idea: if the tenure shield is about mine-specific hazard knowledge,
## then job_exper (same job at any mine) should have weaker protective effects
## than mine_exper (any job at this specific mine).

## Test: interact mine_exper and job_exper with new_arrival indicator
acc <- acc %>%
  mutate(
    mine_short = as.integer(mine_exper < 3),  # short mine tenure
    job_short = as.integer(job_exper < 3)     # short job tenure
  )

r1a <- feols(log_days_lost ~ mine_short + job_short + tot_exper |
               mine_id + cal_yr + occ_cd + subunit,
             data = acc, cluster = ~mine_id)

cat("Mine-short (<3yr mine tenure):\n")
etable(r1a, keep = c("mine_short", "job_short", "tot_exper"))

## ================================================================
## R2: Alternative severity — binary indicators at different thresholds
## ================================================================

cat("\n--- R2: Alternative severity thresholds ---\n")
acc <- acc %>%
  mutate(
    days_gt7 = as.integer(days_away > 7),
    days_gt30 = as.integer(days_away > 30),
    days_gt90 = as.integer(days_away > 90)
  )

r2a <- feols(days_gt7 ~ mine_exper + tot_exper + job_exper |
               mine_id + cal_yr + occ_cd + subunit,
             data = acc, cluster = ~mine_id)

r2b <- feols(days_gt30 ~ mine_exper + tot_exper + job_exper |
               mine_id + cal_yr + occ_cd + subunit,
             data = acc, cluster = ~mine_id)

r2c <- feols(days_gt90 ~ mine_exper + tot_exper + job_exper |
               mine_id + cal_yr + occ_cd + subunit,
             data = acc, cluster = ~mine_id)

etable(r2a, r2b, r2c,
       headers = c(">7 days", ">30 days", ">90 days"),
       keep = c("mine_exper", "tot_exper", "job_exper"))

## ================================================================
## R3: Time period robustness (pre-2010 vs post-2010)
## ================================================================

cat("\n--- R3: Period robustness ---\n")
r3a <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
               mine_id + cal_yr + occ_cd + subunit,
             data = acc %>% filter(cal_yr <= 2012), cluster = ~mine_id)

r3b <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
               mine_id + cal_yr + occ_cd + subunit,
             data = acc %>% filter(cal_yr > 2012), cluster = ~mine_id)

etable(r3a, r3b,
       headers = c("2000-2012", "2013-2025"),
       keep = c("mine_exper", "tot_exper", "job_exper"))

## ================================================================
## R4: Excluding facilities (focus on actual mining operations)
## ================================================================

cat("\n--- R4: Excluding facilities ---\n")
r4 <- feols(log_days_lost ~ mine_exper + tot_exper + job_exper |
              mine_id + cal_yr + occ_cd + subunit,
            data = acc %>% filter(mine_type != "Facility"),
            cluster = ~mine_id)

etable(r4, keep = c("mine_exper", "tot_exper", "job_exper"))

## ================================================================
## R5: Nonlinear effects — quadratic mine experience
## ================================================================

cat("\n--- R5: Quadratic mine experience ---\n")
acc <- acc %>% mutate(mine_exper_sq = mine_exper^2)

r5 <- feols(log_days_lost ~ mine_exper + mine_exper_sq + tot_exper + job_exper |
              mine_id + cal_yr + occ_cd + subunit,
            data = acc, cluster = ~mine_id)

etable(r5, keep = c("mine_exper", "mine_exper_sq", "tot_exper", "job_exper"))

## ================================================================
## Save robustness results
## ================================================================
rob_results <- list(
  r1a = r1a,
  r2a = r2a, r2b = r2b, r2c = r2c,
  r3a = r3a, r3b = r3b,
  r4 = r4, r5 = r5
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
