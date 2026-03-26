# =============================================================================
# 03_main_analysis.R — Main DiD regressions and mechanism tests
# =============================================================================

source("00_packages.R")

cat("Reading clean panel...\n")
con <- DBI::dbConnect(duckdb::duckdb())
panel <- DBI::dbGetQuery(con, "SELECT * FROM '../data/clean_panel.parquet'")
DBI::dbDisconnect(con, shutdown = TRUE)
setDT(panel)

cat("Rows:", nrow(panel), "| Persons:", uniqueN(panel$histid), "\n")

# ---------------------------------------------------------------------------
# 1. Main TWFE regressions
# ---------------------------------------------------------------------------
cat("\n=== MAIN TWFE RESULTS ===\n")

twfe_occscore <- feols(occscore ~ treated | histid + year,
                       data = panel, cluster = ~statefip_origin)
gc()
twfe_sei <- feols(sei ~ treated | histid + year,
                  data = panel, cluster = ~statefip_origin)
gc()
twfe_farm <- feols(farm_binary ~ treated | histid + year,
                   data = panel, cluster = ~statefip_origin)
gc()
twfe_lf <- feols(in_labor_force ~ treated | histid + year,
                 data = panel, cluster = ~statefip_origin)
gc()
twfe_mover <- feols(mover ~ treated | histid + year,
                    data = panel[year > 1920], cluster = ~statefip_origin)
gc()

cat("Occscore:  ", round(coef(twfe_occscore)["treated"], 4),
    " (", round(se(twfe_occscore)["treated"], 4), ") p=",
    round(pvalue(twfe_occscore)["treated"], 4), "\n")
cat("SEI:       ", round(coef(twfe_sei)["treated"], 4),
    " (", round(se(twfe_sei)["treated"], 4), ") p=",
    round(pvalue(twfe_sei)["treated"], 4), "\n")
cat("Farm:      ", round(coef(twfe_farm)["treated"], 4),
    " (", round(se(twfe_farm)["treated"], 4), ") p=",
    round(pvalue(twfe_farm)["treated"], 4), "\n")
cat("LF:        ", round(coef(twfe_lf)["treated"], 4),
    " (", round(se(twfe_lf)["treated"], 4), ") p=",
    round(pvalue(twfe_lf)["treated"], 4), "\n")
cat("Mover:     ", round(coef(twfe_mover)["treated"], 4),
    " (", round(se(twfe_mover)["treated"], 4), ") p=",
    round(pvalue(twfe_mover)["treated"], 4), "\n")

# ---------------------------------------------------------------------------
# 2. Sun-Abraham — heterogeneity-robust (primary outcome + farm)
# ---------------------------------------------------------------------------
cat("\n=== SUN-ABRAHAM EVENT STUDY ===\n")

sa_occscore <- feols(occscore ~ sunab(first_treat, year) | histid + year,
                     data = panel, cluster = ~statefip_origin)
sa_coefs_occ <- coeftable(sa_occscore)
cat("Occscore event study:\n")
print(sa_coefs_occ)
gc()

sa_farm <- feols(farm_binary ~ sunab(first_treat, year) | histid + year,
                 data = panel, cluster = ~statefip_origin)
sa_coefs_farm <- coeftable(sa_farm)
cat("\nFarm event study:\n")
print(sa_coefs_farm)
gc()

sa_sei <- feols(sei ~ sunab(first_treat, year) | histid + year,
                data = panel, cluster = ~statefip_origin)
gc()

# ---------------------------------------------------------------------------
# 3. Mechanism tests: subgroup splits (TWFE for memory efficiency)
# ---------------------------------------------------------------------------
cat("\n=== MECHANISM TESTS ===\n")

# A. Co-resident children vs. others
cat("A. Co-resident children vs. others...\n")
twfe_child <- feols(occscore ~ treated | histid + year,
                    data = panel[child_1920 == 1], cluster = ~statefip_origin)
gc()
twfe_head <- feols(occscore ~ treated | histid + year,
                   data = panel[child_1920 == 0], cluster = ~statefip_origin)
gc()
cat("  Children: ", round(coef(twfe_child)["treated"], 4),
    " (", round(se(twfe_child)["treated"], 4), ")\n")
cat("  Others:   ", round(coef(twfe_head)["treated"], 4),
    " (", round(se(twfe_head)["treated"], 4), ")\n")

# Farm exit by co-residence
twfe_farm_child <- feols(farm_binary ~ treated | histid + year,
                         data = panel[child_1920 == 1], cluster = ~statefip_origin)
gc()
twfe_farm_head <- feols(farm_binary ~ treated | histid + year,
                        data = panel[child_1920 == 0], cluster = ~statefip_origin)
gc()
cat("  Farm (children): ", round(coef(twfe_farm_child)["treated"], 4),
    " (", round(se(twfe_farm_child)["treated"], 4), ")\n")
cat("  Farm (others):   ", round(coef(twfe_farm_head)["treated"], 4),
    " (", round(se(twfe_farm_head)["treated"], 4), ")\n")

# B. Small vs. large family
cat("B. Small vs. large family...\n")
twfe_small <- feols(occscore ~ treated | histid + year,
                    data = panel[small_family_1920 == 1], cluster = ~statefip_origin)
gc()
twfe_large <- feols(occscore ~ treated | histid + year,
                    data = panel[small_family_1920 == 0], cluster = ~statefip_origin)
gc()
cat("  Small family: ", round(coef(twfe_small)["treated"], 4),
    " (", round(se(twfe_small)["treated"], 4), ")\n")
cat("  Large family: ", round(coef(twfe_large)["treated"], 4),
    " (", round(se(twfe_large)["treated"], 4), ")\n")

# C. Farm vs. non-farm baseline
cat("C. Farm vs. non-farm baseline...\n")
panel[, farm_1920_base := farm_binary[year == 1920L], by = histid]
twfe_farm_base <- feols(occscore ~ treated | histid + year,
                        data = panel[farm_1920_base == 1], cluster = ~statefip_origin)
gc()
twfe_nonfarm_base <- feols(occscore ~ treated | histid + year,
                           data = panel[farm_1920_base == 0], cluster = ~statefip_origin)
gc()
cat("  Farm 1920:    ", round(coef(twfe_farm_base)["treated"], 4),
    " (", round(se(twfe_farm_base)["treated"], 4), ")\n")
cat("  Nonfarm 1920: ", round(coef(twfe_nonfarm_base)["treated"], 4),
    " (", round(se(twfe_nonfarm_base)["treated"], 4), ")\n")

# D. Native vs. foreign-born
cat("D. Native vs. foreign-born...\n")
twfe_native <- feols(occscore ~ treated | histid + year,
                     data = panel[native_born == 1], cluster = ~statefip_origin)
gc()
twfe_foreign <- feols(occscore ~ treated | histid + year,
                      data = panel[native_born == 0], cluster = ~statefip_origin)
gc()
cat("  Native:  ", round(coef(twfe_native)["treated"], 4),
    " (", round(se(twfe_native)["treated"], 4), ")\n")
cat("  Foreign: ", round(coef(twfe_foreign)["treated"], 4),
    " (", round(se(twfe_foreign)["treated"], 4), ")\n")

# ---------------------------------------------------------------------------
# 4. Save models and diagnostics
# ---------------------------------------------------------------------------
cat("\nSaving results...\n")

models <- list(
  twfe_occscore = twfe_occscore,
  twfe_sei = twfe_sei,
  twfe_farm = twfe_farm,
  twfe_mover = twfe_mover,
  twfe_lf = twfe_lf,
  sa_occscore = sa_occscore,
  sa_sei = sa_sei,
  sa_farm = sa_farm,
  twfe_child = twfe_child,
  twfe_head = twfe_head,
  twfe_farm_child = twfe_farm_child,
  twfe_farm_head = twfe_farm_head,
  twfe_small = twfe_small,
  twfe_large = twfe_large,
  twfe_farm_base = twfe_farm_base,
  twfe_nonfarm_base = twfe_nonfarm_base,
  twfe_native = twfe_native,
  twfe_foreign = twfe_foreign
)
saveRDS(models, "../data/model_objects.rds")

diagnostics <- list(
  n_treated = uniqueN(panel[first_treat > 0 & year == 1920]$statefip_origin),
  n_pre = 1L,
  n_obs = nrow(panel),
  n_persons = uniqueN(panel$histid),
  n_states = uniqueN(panel$statefip_origin),
  n_early = uniqueN(panel[first_treat == 1930 & year == 1920]$statefip_origin),
  n_late = uniqueN(panel[first_treat == 1940 & year == 1920]$statefip_origin),
  n_control = uniqueN(panel[first_treat == 0 & year == 1920]$statefip_origin)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
cat("\nDone.\n")
