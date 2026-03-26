# =============================================================================
# 04_robustness.R — Robustness checks
# =============================================================================

source("00_packages.R")

cat("Reading clean panel...\n")
con <- DBI::dbConnect(duckdb::duckdb())
panel <- DBI::dbGetQuery(con, "SELECT * FROM '../data/clean_panel.parquet'")
DBI::dbDisconnect(con, shutdown = TRUE)
setDT(panel)

models <- readRDS("../data/model_objects.rds")

cat("\n=== ROBUSTNESS CHECKS ===\n")

# A. Employed men only
cat("A. Employed only...\n")
rob_employed <- feols(occscore ~ treated | histid + year,
                      data = panel[in_labor_force == 1], cluster = ~statefip_origin)
gc()

# B. White men only
cat("B. White only...\n")
rob_white <- feols(occscore ~ treated | histid + year,
                   data = panel[white == 1], cluster = ~statefip_origin)
gc()

# C. Ages 30-45 in 1920
panel[, age_1920_base := age[year == 1920L], by = histid]
cat("C. Prime age 30-45...\n")
rob_prime <- feols(occscore ~ treated | histid + year,
                   data = panel[age_1920_base >= 30 & age_1920_base <= 45],
                   cluster = ~statefip_origin)
gc()

# D. Weighted
cat("D. Weighted...\n")
rob_weighted <- feols(occscore ~ treated | histid + year,
                      data = panel, weights = ~perwt, cluster = ~statefip_origin)
gc()

# E. Placebo: Homeownership
cat("E. Placebo: Homeowner...\n")
rob_homeown <- feols(homeowner ~ treated | histid + year,
                     data = panel, cluster = ~statefip_origin)
gc()

# F. Placebo: Marriage
cat("F. Placebo: Married...\n")
panel[, married := as.integer(marst %in% c(1L, 2L))]
rob_married <- feols(married ~ treated | histid + year,
                     data = panel, cluster = ~statefip_origin)
gc()

# G. Farm exit robustness: employed only
cat("G. Farm exit, employed only...\n")
rob_farm_emp <- feols(farm_binary ~ treated | histid + year,
                      data = panel[in_labor_force == 1], cluster = ~statefip_origin)
gc()

# H. Farm exit: white only
cat("H. Farm exit, white only...\n")
rob_farm_white <- feols(farm_binary ~ treated | histid + year,
                        data = panel[white == 1], cluster = ~statefip_origin)
gc()

# Print results
cat("\n--- Robustness Results ---\n")
for (nm in c("rob_employed", "rob_white", "rob_prime", "rob_weighted",
             "rob_homeown", "rob_married", "rob_farm_emp", "rob_farm_white")) {
  m <- get(nm)
  cat(nm, ": ", round(coef(m)["treated"], 4),
      " (", round(se(m)["treated"], 4), ") p=",
      round(pvalue(m)["treated"], 4), "\n")
}

# I. Callaway-Sant'Anna (state-level aggregated)
cat("\nI. Callaway-Sant'Anna (state-year aggregated)...\n")
state_panel <- panel[, .(
  occscore = mean(occscore),
  sei = mean(sei),
  farm_binary = mean(farm_binary)
), by = .(statefip_origin, year, first_treat)]

tryCatch({
  cs_occ <- att_gt(
    yname = "occscore", tname = "year",
    idname = "statefip_origin", gname = "first_treat",
    data = as.data.frame(state_panel),
    control_group = "nevertreated"
  )
  cs_agg_occ <- aggte(cs_occ, type = "simple")
  cat("CS occscore ATT:", cs_agg_occ$overall.att,
      "SE:", cs_agg_occ$overall.se, "\n")

  cs_farm <- att_gt(
    yname = "farm_binary", tname = "year",
    idname = "statefip_origin", gname = "first_treat",
    data = as.data.frame(state_panel),
    control_group = "nevertreated"
  )
  cs_agg_farm <- aggte(cs_farm, type = "simple")
  cat("CS farm ATT:", cs_agg_farm$overall.att,
      "SE:", cs_agg_farm$overall.se, "\n")

  models$cs_occ <- cs_occ
  models$cs_farm <- cs_farm
}, error = function(e) cat("CS-DiD error:", e$message, "\n"))

# Save
models$rob_employed <- rob_employed
models$rob_white <- rob_white
models$rob_prime <- rob_prime
models$rob_weighted <- rob_weighted
models$rob_homeown <- rob_homeown
models$rob_married <- rob_married
models$rob_farm_emp <- rob_farm_emp
models$rob_farm_white <- rob_farm_white

saveRDS(models, "../data/model_objects.rds")
cat("\nDone.\n")
