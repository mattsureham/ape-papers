# 04_robustness.R — Robustness checks and placebo tests
# apep_0946: EECC transposition and consumer telecom prices

source("00_packages.R")

# ===========================================================================
# 1. Load data
# ===========================================================================

panel <- fread("../data/panel_main.csv")
food <- fread("../data/panel_placebo_food.csv")
transport <- fread("../data/panel_placebo_transport.csv")
housing <- fread("../data/panel_placebo_housing.csv")
bb_panel <- fread("../data/panel_broadband.csv")

# ===========================================================================
# 2. Placebo tests — EECC should NOT affect non-telecom prices
# ===========================================================================

cat("=== Placebo Tests ===\n\n")

placebo_results <- list()

# Food prices (CP011)
cat("--- Food (CP011) ---\n")
cs_food <- att_gt(
  yname = "cp_food",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(food),
  control_group = "nevertreated",
  base_period = "universal"
)
overall_food <- aggte(cs_food, type = "simple")
cat("ATT:", round(overall_food$overall.att, 3),
    "SE:", round(overall_food$overall.se, 3), "\n")
placebo_results$food <- list(att = overall_food$overall.att,
                              se = overall_food$overall.se)

# Transport prices (CP07)
cat("\n--- Transport (CP07) ---\n")
cs_transport <- att_gt(
  yname = "cp_transport",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(transport),
  control_group = "nevertreated",
  base_period = "universal"
)
overall_transport <- aggte(cs_transport, type = "simple")
cat("ATT:", round(overall_transport$overall.att, 3),
    "SE:", round(overall_transport$overall.se, 3), "\n")
placebo_results$transport <- list(att = overall_transport$overall.att,
                                   se = overall_transport$overall.se)

# Housing prices (CP04)
cat("\n--- Housing (CP04) ---\n")
cs_housing <- att_gt(
  yname = "cp_housing",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(housing),
  control_group = "nevertreated",
  base_period = "universal"
)
overall_housing <- aggte(cs_housing, type = "simple")
cat("ATT:", round(overall_housing$overall.att, 3),
    "SE:", round(overall_housing$overall.se, 3), "\n")
placebo_results$housing <- list(att = overall_housing$overall.att,
                                 se = overall_housing$overall.se)

# ===========================================================================
# 3. Secondary outcome: Broadband subscriptions
# ===========================================================================

cat("\n=== Secondary Outcome: Broadband ===\n")

cs_bb <- att_gt(
  yname = "broadband",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(bb_panel[!is.na(broadband)]),
  control_group = "nevertreated",
  base_period = "universal"
)
overall_bb <- aggte(cs_bb, type = "simple")
cat("ATT:", round(overall_bb$overall.att, 3),
    "SE:", round(overall_bb$overall.se, 3), "\n")

# ===========================================================================
# 4. Not-yet-treated as comparison group
# ===========================================================================

cat("\n=== Robustness: Not-yet-treated comparison ===\n")

cs_nyt <- att_gt(
  yname = "cp08",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal"
)
overall_nyt <- aggte(cs_nyt, type = "simple")
cat("ATT (not-yet-treated):", round(overall_nyt$overall.att, 3),
    "SE:", round(overall_nyt$overall.se, 3), "\n")

es_nyt <- aggte(cs_nyt, type = "dynamic", min_e = -6, max_e = 4)

# ===========================================================================
# 5. Leave-one-cohort-out
# ===========================================================================

cat("\n=== Leave-One-Cohort-Out ===\n")

cohorts <- unique(panel[first_treat > 0]$first_treat)
loco_results <- list()

for (g in sort(cohorts)) {
  panel_loco <- panel[first_treat != g | first_treat == 0]
  panel_loco[, country_id := as.integer(factor(geo))]
  if (uniqueN(panel_loco[first_treat > 0]$first_treat) < 2) next

  tryCatch({
    cs_loco <- att_gt(
      yname = "cp08",
      tname = "year",
      idname = "country_id",
      gname = "first_treat",
      data = as.data.frame(panel_loco),
      control_group = "notyettreated",
      base_period = "universal"
    )
    overall_loco <- aggte(cs_loco, type = "simple")
    cat("Excluding cohort", g, ": ATT =", round(overall_loco$overall.att, 3),
        "SE =", round(overall_loco$overall.se, 3), "\n")
    loco_results[[as.character(g)]] <- list(
      cohort_excluded = g,
      att = overall_loco$overall.att,
      se = overall_loco$overall.se
    )
  }, error = function(e) {
    cat("Excluding cohort", g, ": FAILED (", e$message, ")\n")
  })
}

# ===========================================================================
# 6. Save results
# ===========================================================================

saveRDS(placebo_results, "../data/placebo_results.rds")
saveRDS(cs_bb, "../data/cs_broadband.rds")
saveRDS(overall_bb, "../data/overall_broadband.rds")
saveRDS(cs_nyt, "../data/cs_nyt.rds")
saveRDS(overall_nyt, "../data/overall_nyt.rds")
saveRDS(es_nyt, "../data/es_nyt.rds")
saveRDS(loco_results, "../data/loco_results.rds")

cat("\nAll robustness results saved.\n")
