## 03_main_analysis.R — Main DiD analysis: VRU effects + spillover decomposition
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

knife <- fread(file.path(data_dir, "knife_panel_clean.csv"))
firearm <- fread(file.path(data_dir, "firearm_panel_clean.csv"))

cat("=== Main Analysis ===\n")
cat("Knife panel:", nrow(knife), "rows,", uniqueN(knife$force_std), "forces,",
    uniqueN(knife$year_end), "years\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1. TWFE: Direct effect of VRUs on knife crime
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- TWFE: Direct VRU Effect ---\n")

twfe_knife <- feols(knife_rate ~ vru_post | force_id + year_end,
                    data = knife, cluster = ~force_id)
cat("TWFE (knife crime):\n")
summary(twfe_knife)

## ─────────────────────────────────────────────────────────────────────────────
## 2. Callaway-Sant'Anna: Heterogeneity-robust DiD
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Callaway-Sant'Anna ---\n")

cs_knife <- att_gt(
  yname = "knife_rate",
  tname = "year_end",
  idname = "force_id",
  gname = "first_treat",
  data = as.data.frame(knife),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

cat("Group-Time ATTs:\n")
summary(cs_knife)

## Aggregate to simple ATT
att_knife <- aggte(cs_knife, type = "simple")
cat("\nSimple ATT:\n")
summary(att_knife)

## Event study
es_knife <- aggte(cs_knife, type = "dynamic", min_e = -8, max_e = 5)
cat("\nEvent Study:\n")
summary(es_knife)

saveRDS(cs_knife, file.path(data_dir, "cs_knife.rds"))
saveRDS(att_knife, file.path(data_dir, "att_knife.rds"))
saveRDS(es_knife, file.path(data_dir, "es_knife.rds"))
saveRDS(twfe_knife, file.path(data_dir, "twfe_knife.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 3. Spillover Analysis
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Spillover Analysis ---\n")

## Panel A: Direct + spillover (all forces)
knife[, boundary_post := as.integer(boundary == 1 & post == 1)]
net_mod <- feols(knife_rate ~ vru_post + boundary_post | force_id + year_end,
                 data = knife, cluster = ~force_id)
cat("Net effect model (direct + spillover):\n")
summary(net_mod)

## Panel B: Spillover only (untreated forces)
untreated_knife <- knife[vru == 0]
spill_mod <- feols(knife_rate ~ boundary_post | force_id + year_end,
                   data = untreated_knife, cluster = ~force_id)
cat("\nSpillover (untreated forces only):\n")
summary(spill_mod)

saveRDS(net_mod, file.path(data_dir, "net_effect_model.rds"))
saveRDS(spill_mod, file.path(data_dir, "spillover_model.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 4. Firearm offences (secondary outcome)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Firearm Offences ---\n")

twfe_firearm <- feols(firearm_rate ~ vru_post | force_id + year_end,
                      data = firearm, cluster = ~force_id)
cat("TWFE (firearm offences):\n")
summary(twfe_firearm)

saveRDS(twfe_firearm, file.path(data_dir, "twfe_firearm.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 5. Pre-COVID only (year_end <= 2020 means April 2019-March 2020)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Pre-COVID Robustness ---\n")

knife_precovid <- knife[year_end <= 2020]
twfe_precovid <- feols(knife_rate ~ vru_post | force_id + year_end,
                       data = knife_precovid, cluster = ~force_id)
cat("Pre-COVID TWFE (to FY2019/20):\n")
summary(twfe_precovid)

saveRDS(twfe_precovid, file.path(data_dir, "twfe_precovid.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 6. Sun-Abraham event study via fixest
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Sun-Abraham Event Study ---\n")

## Only use cohort 1 (2019) forces and never-treated
sa_data <- knife[first_treat %in% c(0, 2020)]
es_fixest <- feols(knife_rate ~ sunab(first_treat, year_end) | force_id + year_end,
                   data = sa_data, cluster = ~force_id)
cat("Sun-Abraham event study:\n")
summary(es_fixest)

saveRDS(es_fixest, file.path(data_dir, "es_fixest.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 7. Excluding Metropolitan Police
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Excluding Metropolitan Police ---\n")

knife_nomet <- knife[force_std != "Metropolitan Police"]
twfe_nomet <- feols(knife_rate ~ vru_post | force_id + year_end,
                    data = knife_nomet, cluster = ~force_id)
cat("Without Met Police:\n")
summary(twfe_nomet)

saveRDS(twfe_nomet, file.path(data_dir, "twfe_nomet.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 8. Log specification
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Log Specification ---\n")

knife[, log_rate := log(knife_rate + 1)]
twfe_log <- feols(log_rate ~ vru_post | force_id + year_end,
                  data = knife, cluster = ~force_id)
cat("Log specification:\n")
summary(twfe_log)

saveRDS(twfe_log, file.path(data_dir, "twfe_log.rds"))

## ─────────────────────────────────────────────────────────────────────────────
## 9. Population-weighted net effect
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Population Shares ---\n")

pop_shares <- knife[year_end == 2019,
                    .(total_pop = sum(population, na.rm = TRUE)),
                    by = force_type]
pop_shares[, share := total_pop / sum(total_pop)]
cat("Population by force type:\n")
print(pop_shares)

## ─────────────────────────────────────────────────────────────────────────────
## 10. Write diagnostics.json
## ─────────────────────────────────────────────────────────────────────────────
diagnostics <- list(
  n_treated = uniqueN(knife[vru == 1, force_std]),
  n_pre = length(unique(knife[year_end < 2020, year_end])),
  n_obs = nrow(knife),
  n_forces = uniqueN(knife$force_std),
  n_years = uniqueN(knife$year_end),
  pre_period = "2011-2019",
  post_period = "2020-2025"
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

cat("\n=== Main analysis complete ===\n")
