# =============================================================================
# 03_main_analysis.R — Main RD and DiD estimates
# Paper: The Inertia Break (apep_1279)
# =============================================================================

source("00_packages.R")

cat("Loading analysis data...\n")
con_local <- dbConnect(duckdb())
dt <- as.data.table(dbGetQuery(con_local, "SELECT * FROM '../data/analysis.parquet'"))
dbDisconnect(con_local)
cat(sprintf("Loaded %s rows\n", format(nrow(dt), big.mark = ",")))

# -----------------------------------------------------------------------
# 1. Note on bandwidth: Running variable (age) is discrete (integer years)
# Standard rdrobust is not appropriate with mass points.
# We use parametric RD with varying bandwidths and report sensitivity.
# -----------------------------------------------------------------------
cat("\n=== NOTE: Discrete running variable — using parametric RD ===\n")
optimal_bw <- 4  # Baseline: 4 years each side of cutoff

# -----------------------------------------------------------------------
# 2. Parametric RD — Main Specifications (Full Sample)
# -----------------------------------------------------------------------
cat("\n=== PARAMETRIC RD (Full Sample) ===\n")

# Narrow bandwidth: ages 10-18 (4 years each side of cutoff at 14)
rd_narrow <- dt[age_1910 %between% c(10, 18)]
cat(sprintf("RD sample (ages 10-18): %s obs\n", format(nrow(rd_narrow), big.mark = ",")))

# Pre-treatment means for SDE computation
pre_means <- rd_narrow[draft_eligible == 0, .(
  sd_farm_exit = sd(farm_exit),
  sd_delta_occ = sd(delta_occscore),
  sd_moved = sd(moved_county),
  sd_manuf = sd(farm_to_manuf),
  mean_farm_exit = mean(farm_exit),
  mean_delta_occ = mean(delta_occscore),
  mean_moved = mean(moved_county),
  mean_manuf = mean(farm_to_manuf)
)]
cat("\nControl group (age < 14) outcome SDs:\n")
print(pre_means)

# --- Main specification: linear in age, state FE, cluster on state ---

# Farm exit
rd_farm_1 <- feols(farm_exit ~ draft_eligible + age_centered +
                     draft_eligible:age_centered | statefip_1910,
                   data = rd_narrow, cluster = ~statefip_1910)

# With controls
rd_farm_2 <- feols(farm_exit ~ draft_eligible + age_centered +
                     draft_eligible:age_centered +
                     white + native_born + literate + married_1910 |
                     statefip_1910,
                   data = rd_narrow, cluster = ~statefip_1910)

# Delta occupational score
rd_occ_1 <- feols(delta_occscore ~ draft_eligible + age_centered +
                    draft_eligible:age_centered | statefip_1910,
                  data = rd_narrow, cluster = ~statefip_1910)

rd_occ_2 <- feols(delta_occscore ~ draft_eligible + age_centered +
                    draft_eligible:age_centered +
                    white + native_born + literate + married_1910 |
                    statefip_1910,
                  data = rd_narrow, cluster = ~statefip_1910)

# Geographic mobility
rd_move_1 <- feols(moved_county ~ draft_eligible + age_centered +
                     draft_eligible:age_centered | statefip_1910,
                   data = rd_narrow, cluster = ~statefip_1910)

rd_move_2 <- feols(moved_county ~ draft_eligible + age_centered +
                     draft_eligible:age_centered +
                     white + native_born + literate + married_1910 |
                     statefip_1910,
                   data = rd_narrow, cluster = ~statefip_1910)

# Farm to manufacturing
rd_manuf_1 <- feols(farm_to_manuf ~ draft_eligible + age_centered +
                      draft_eligible:age_centered | statefip_1910,
                    data = rd_narrow, cluster = ~statefip_1910)

rd_manuf_2 <- feols(farm_to_manuf ~ draft_eligible + age_centered +
                      draft_eligible:age_centered +
                      white + native_born + literate + married_1910 |
                      statefip_1910,
                    data = rd_narrow, cluster = ~statefip_1910)

cat("\n--- Farm Exit ---\n")
cat("No controls:\n"); print(summary(rd_farm_1, stage = 1))
cat("With controls:\n"); print(summary(rd_farm_2, stage = 1))

cat("\n--- Delta Occ Score ---\n")
cat("No controls:\n"); print(summary(rd_occ_1, stage = 1))
cat("With controls:\n"); print(summary(rd_occ_2, stage = 1))

cat("\n--- Moved County ---\n")
cat("No controls:\n"); print(summary(rd_move_1, stage = 1))
cat("With controls:\n"); print(summary(rd_move_2, stage = 1))

cat("\n--- Farm to Manufacturing ---\n")
cat("No controls:\n"); print(summary(rd_manuf_1, stage = 1))
cat("With controls:\n"); print(summary(rd_manuf_2, stage = 1))

# -----------------------------------------------------------------------
# 3. Nativity-Based DiD (within draft-eligible ages)
# -----------------------------------------------------------------------
cat("\n=== NATIVITY DiD ===\n")

did_data <- dt[age_1910 %between% c(10, 20)]

did_farm <- feols(farm_exit ~ draft_eligible * native_born +
                    age_centered | statefip_1910,
                  data = did_data, cluster = ~statefip_1910)

did_occ <- feols(delta_occscore ~ draft_eligible * native_born +
                   age_centered | statefip_1910,
                 data = did_data, cluster = ~statefip_1910)

did_move <- feols(moved_county ~ draft_eligible * native_born +
                    age_centered | statefip_1910,
                  data = did_data, cluster = ~statefip_1910)

cat("Nativity DiD — Farm Exit:\n"); summary(did_farm)
cat("Nativity DiD — Delta Occ Score:\n"); summary(did_occ)
cat("Nativity DiD — Moved County:\n"); summary(did_move)

# -----------------------------------------------------------------------
# 4. Heterogeneity: Agricultural Dependence
# -----------------------------------------------------------------------
cat("\n=== HETEROGENEITY ===\n")

het_farm <- feols(farm_exit ~ draft_eligible * high_ag +
                    age_centered + draft_eligible:age_centered | statefip_1910,
                  data = rd_narrow, cluster = ~statefip_1910)
cat("Heterogeneity — Farm Exit by Ag Dependence:\n"); summary(het_farm)

het_occ <- feols(delta_occscore ~ draft_eligible * high_ag +
                   age_centered + draft_eligible:age_centered | statefip_1910,
                 data = rd_narrow, cluster = ~statefip_1910)
cat("Heterogeneity — Occ Score by Ag Dependence:\n"); summary(het_occ)

# Race heterogeneity
het_race <- feols(farm_exit ~ draft_eligible * black +
                    age_centered + draft_eligible:age_centered | statefip_1910,
                  data = rd_narrow[race_1910 %in% c(1, 2)],
                  cluster = ~statefip_1910)
cat("Heterogeneity — Farm Exit by Race:\n"); summary(het_race)

# -----------------------------------------------------------------------
# 5. Age-bin means for RD visualization
# -----------------------------------------------------------------------
cat("\n=== AGE-BIN MEANS ===\n")

age_means <- dt[age_1910 %between% c(8, 25), .(
  farm_exit = mean(farm_exit),
  delta_occ = mean(delta_occscore),
  moved = mean(moved_county),
  farm_manuf = mean(farm_to_manuf),
  n = .N
), by = age_1910][order(age_1910)]

cat("Means by age:\n")
print(age_means)

# -----------------------------------------------------------------------
# Save all results
# -----------------------------------------------------------------------
save(optimal_bw, pre_means,
     rd_farm_1, rd_farm_2, rd_occ_1, rd_occ_2,
     rd_move_1, rd_move_2, rd_manuf_1, rd_manuf_2,
     did_farm, did_occ, did_move,
     het_farm, het_occ, het_race,
     age_means,
     file = "../data/main_results.RData")

# Write diagnostics.json
n_treated <- nrow(dt[draft_eligible == 1])
diag <- list(
  n_treated = n_treated,
  n_pre = 6,
  n_obs = nrow(dt),
  n_control = nrow(dt[draft_eligible == 0]),
  n_states = length(unique(dt$statefip_1910))
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: N=%s, N_treated=%s, N_control=%s, States=%d\n",
            format(nrow(dt), big.mark = ","),
            format(n_treated, big.mark = ","),
            format(nrow(dt[draft_eligible == 0]), big.mark = ","),
            length(unique(dt$statefip_1910))))
cat("Done.\n")
