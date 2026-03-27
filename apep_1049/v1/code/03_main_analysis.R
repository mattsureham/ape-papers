# 03_main_analysis.R — Main DiD estimation
# apep_1049: EU Single-Use Plastics Directive

source("00_packages.R")

panel <- readRDS("data/analysis_panel.rds")

# ===========================================================================
# 1. Descriptive: Treatment rollout plot data
# ===========================================================================
message("=== Treatment Rollout ===")
rollout <- panel[first_treat > 0, .(first_treat = first_treat[1]), by = geo]
rollout <- rollout[order(first_treat)]
message("Treatment cohorts:")
print(rollout)

# ===========================================================================
# 2. Pre-treatment outcome paths by cohort
# ===========================================================================
message("\n=== Pre-treatment means (plastic_pc, kg/person) ===")
pre_means <- panel[year < 2020, .(
  mean_plastic_pc = mean(plastic_pc, na.rm = TRUE),
  mean_paper_pc = mean(paper_pc, na.rm = TRUE),
  sd_plastic_pc = sd(plastic_pc, na.rm = TRUE)
), by = geo]
message("Cross-country mean plastic packaging (kg/person, pre-2020): ",
        round(mean(pre_means$mean_plastic_pc, na.rm = TRUE), 1))
message("Cross-country SD: ",
        round(sd(pre_means$mean_plastic_pc, na.rm = TRUE), 1))

# ===========================================================================
# 3. Callaway-Sant'Anna: Primary outcome — Plastic packaging per capita
# ===========================================================================
message("\n=== Callaway-Sant'Anna: Plastic packaging per capita ===")

# Ensure no NA in key variables
cs_data <- panel[!is.na(plastic_pc) & !is.na(first_treat) & !is.na(country_id)]

cs_plastic <- att_gt(
  yname = "plastic_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data,
  control_group = "notyettreated",
  est_method = "dr",  # Doubly robust
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

message("ATT(g,t) estimates:")
summary(cs_plastic)

# Aggregate: simple (overall ATT)
agg_simple_plastic <- aggte(cs_plastic, type = "simple")
message("\nOverall ATT (plastic_pc):")
summary(agg_simple_plastic)

# Aggregate: dynamic (event study)
agg_dynamic_plastic <- aggte(cs_plastic, type = "dynamic")
message("\nEvent study (plastic_pc):")
summary(agg_dynamic_plastic)

# Save for tables
saveRDS(cs_plastic, "data/cs_plastic.rds")
saveRDS(agg_simple_plastic, "data/agg_simple_plastic.rds")
saveRDS(agg_dynamic_plastic, "data/agg_dynamic_plastic.rds")

# ===========================================================================
# 4. Callaway-Sant'Anna: Paper/cardboard packaging per capita (substitution)
# ===========================================================================
message("\n=== Callaway-Sant'Anna: Paper packaging per capita ===")

cs_data_paper <- panel[!is.na(paper_pc) & !is.na(first_treat) & !is.na(country_id)]

cs_paper <- att_gt(
  yname = "paper_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_paper,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_simple_paper <- aggte(cs_paper, type = "simple")
message("\nOverall ATT (paper_pc):")
summary(agg_simple_paper)

agg_dynamic_paper <- aggte(cs_paper, type = "dynamic")
saveRDS(cs_paper, "data/cs_paper.rds")
saveRDS(agg_simple_paper, "data/agg_simple_paper.rds")
saveRDS(agg_dynamic_paper, "data/agg_dynamic_paper.rds")

# ===========================================================================
# 5. Callaway-Sant'Anna: Plastic share of total (substitution ratio)
# ===========================================================================
message("\n=== Callaway-Sant'Anna: Plastic share of total ===")

cs_data_share <- panel[!is.na(plastic_share) & !is.na(first_treat) & !is.na(country_id)]

cs_share <- att_gt(
  yname = "plastic_share",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_share,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_simple_share <- aggte(cs_share, type = "simple")
message("\nOverall ATT (plastic_share):")
summary(agg_simple_share)

agg_dynamic_share <- aggte(cs_share, type = "dynamic")
saveRDS(cs_share, "data/cs_share.rds")
saveRDS(agg_simple_share, "data/agg_simple_share.rds")
saveRDS(agg_dynamic_share, "data/agg_dynamic_share.rds")

# ===========================================================================
# 6. Built-in placebos: Glass and Metal packaging (not targeted by SUP)
# ===========================================================================
message("\n=== Placebo: Glass packaging per capita ===")

cs_data_glass <- panel[!is.na(glass_pc) & !is.na(first_treat) & !is.na(country_id)]

cs_glass <- att_gt(
  yname = "glass_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_glass,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_simple_glass <- aggte(cs_glass, type = "simple")
message("Placebo ATT (glass_pc):")
summary(agg_simple_glass)

saveRDS(cs_glass, "data/cs_glass.rds")
saveRDS(agg_simple_glass, "data/agg_simple_glass.rds")

message("\n=== Placebo: Metal packaging per capita ===")

cs_data_metal <- panel[!is.na(metal_pc) & !is.na(first_treat) & !is.na(country_id)]

cs_metal <- att_gt(
  yname = "metal_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_metal,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_simple_metal <- aggte(cs_metal, type = "simple")
message("Placebo ATT (metal_pc):")
summary(agg_simple_metal)

saveRDS(cs_metal, "data/cs_metal.rds")
saveRDS(agg_simple_metal, "data/agg_simple_metal.rds")

# ===========================================================================
# 7. Total packaging per capita (net waste effect)
# ===========================================================================
message("\n=== Callaway-Sant'Anna: Total packaging per capita ===")

cs_data_total <- panel[!is.na(total_pc) & !is.na(first_treat) & !is.na(country_id)]

cs_total <- att_gt(
  yname = "total_pc",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = cs_data_total,
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

agg_simple_total <- aggte(cs_total, type = "simple")
message("Overall ATT (total_pc):")
summary(agg_simple_total)

saveRDS(cs_total, "data/cs_total.rds")
saveRDS(agg_simple_total, "data/agg_simple_total.rds")

# ===========================================================================
# 8. TWFE comparison (for reference / showing bias)
# ===========================================================================
message("\n=== TWFE comparison ===")

twfe_plastic <- feols(plastic_pc ~ treated | geo + year, data = panel,
                      cluster = ~geo)
message("TWFE plastic_pc:")
print(summary(twfe_plastic))

twfe_paper <- feols(paper_pc ~ treated | geo + year, data = panel,
                    cluster = ~geo)
message("TWFE paper_pc:")
print(summary(twfe_paper))

twfe_share <- feols(plastic_share ~ treated | geo + year, data = panel,
                    cluster = ~geo)
message("TWFE plastic_share:")
print(summary(twfe_share))

saveRDS(twfe_plastic, "data/twfe_plastic.rds")
saveRDS(twfe_paper, "data/twfe_paper.rds")
saveRDS(twfe_share, "data/twfe_share.rds")

# ===========================================================================
# 9. Write diagnostics.json
# ===========================================================================
diag <- list(
  n_treated = uniqueN(panel$geo[panel$first_treat > 0]),
  n_pre = min(panel$first_treat[panel$first_treat > 0]) - min(panel$year),
  n_obs = nrow(panel),
  n_countries = uniqueN(panel$geo),
  year_range = paste(min(panel$year), max(panel$year), sep = "-"),
  treatment_cohorts = sort(unique(panel$first_treat[panel$first_treat > 0]))
)

write_json(diag, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
message("\ndiagnostics.json written")

message("\n=== Main analysis complete ===")
