# ==============================================================================
# 02_clean_data.R — Variable Construction
# Paper: The Credential Equity Trap (apep_0791)
# ==============================================================================

source("00_packages.R")

# ---- 1. Load raw data ----
inst <- readRDS(file.path("..", "data", "ipeds_institutions.rds"))
comp <- readRDS(file.path("..", "data", "ipeds_completions_subbachelor.rds"))
comp_all <- readRDS(file.path("..", "data", "ipeds_completions_all.rds"))

setDT(inst)
setDT(comp)
setDT(comp_all)

# ---- 2. Define institution type ----
# For-profit: control == 3 (sectors 3, 6, 9)
# Public 2-year: sector == 4
inst[, forprofit := as.integer(control == 3)]
inst[, pub2yr := as.integer(sector == 4)]

# Keep only for-profits and public 2-year controls
inst <- inst[forprofit == 1 | pub2yr == 1]

# Use most recent institution info for time-invariant characteristics
inst_info <- inst[, .(forprofit = max(forprofit),
                      pub2yr = max(pub2yr),
                      state = state[which.max(year)],
                      fips_state = fips_state[which.max(year)],
                      hbcu = hbcu[which.max(year)],
                      instnm = institution_name[which.max(year)]),
                  by = unitid]

cat(sprintf("For-profit institutions: %d\n", sum(inst_info$forprofit)))
cat(sprintf("Public 2-year institutions: %d\n", sum(inst_info$pub2yr)))

# ---- 3. Merge completions with institution type ----
panel <- merge(comp, inst_info[, .(unitid, forprofit, pub2yr, state, fips_state)],
               by = "unitid", all.x = FALSE)

cat(sprintf("Panel observations (institution-years): %d\n", nrow(panel)))

# ---- 4. Construct outcome variables ----
panel[, minority_comp := black_comp + hisp_comp]
panel[, minority_share := fifelse(total_comp > 0, minority_comp / total_comp, NA_real_)]
panel[, black_share := fifelse(total_comp > 0, black_comp / total_comp, NA_real_)]
panel[, hisp_share := fifelse(total_comp > 0, hisp_comp / total_comp, NA_real_)]
panel[, white_share := fifelse(total_comp > 0, white_comp / total_comp, NA_real_)]

# Log outcomes (for levels analysis)
panel[, log_total := log(total_comp + 1)]
panel[, log_minority := log(minority_comp + 1)]
panel[, log_black := log(black_comp + 1)]
panel[, log_hisp := log(hisp_comp + 1)]
panel[, log_white := log(white_comp + 1)]

# ---- 5. Define regulatory periods ----
panel[, ge_period := fcase(
  year >= 2007 & year <= 2014, "pre",
  year >= 2015 & year <= 2018, "ge_active",
  year >= 2019 & year <= 2023, "post_repeal"
)]

panel[, ge_active := as.integer(year >= 2015 & year <= 2018)]
panel[, post_repeal := as.integer(year >= 2019)]

# ---- 6. Drop institutions with very few completions ----
# Require at least 10 total completions in any year to be in sample
panel_ever <- panel[, .(max_comp = max(total_comp, na.rm = TRUE)), by = unitid]
keep_ids <- panel_ever[max_comp >= 10, unitid]
panel <- panel[unitid %in% keep_ids]

cat(sprintf("After filtering (>=10 completions ever): %d institution-years\n", nrow(panel)))
cat(sprintf("Unique institutions: %d\n", uniqueN(panel$unitid)))

# ---- 7. Build race-stacked panel for DDD ----
# Stack: one row per institution × year × race group
race_panel <- rbindlist(list(
  panel[, .(unitid, year, forprofit, state, fips_state,
            completions = black_comp, race = "black",
            ge_active, post_repeal, ge_period)],
  panel[, .(unitid, year, forprofit, state, fips_state,
            completions = hisp_comp, race = "hispanic",
            ge_active, post_repeal, ge_period)],
  panel[, .(unitid, year, forprofit, state, fips_state,
            completions = white_comp, race = "white",
            ge_active, post_repeal, ge_period)]
))

race_panel[, minority := as.integer(race %in% c("black", "hispanic"))]
race_panel[, log_comp := log(completions + 1)]

# Create interaction IDs for fixed effects
race_panel[, unitid_race := paste0(unitid, "_", race)]
race_panel[, race_year := paste0(race, "_", year)]
race_panel[, unitid_year := paste0(unitid, "_", year)]

cat(sprintf("Race-stacked panel: %d rows (%d inst × %d years × 3 races)\n",
            nrow(race_panel), uniqueN(race_panel$unitid), uniqueN(race_panel$year)))

# ---- 8. Save analysis-ready panels ----
saveRDS(panel, file.path("..", "data", "analysis_panel.rds"))
saveRDS(race_panel, file.path("..", "data", "race_panel.rds"))

# Also merge all-award completions for robustness
panel_all <- merge(comp_all, inst_info[, .(unitid, forprofit, pub2yr, state, fips_state)],
                   by = "unitid", all.x = FALSE)
setDT(panel_all)
panel_all[, minority_comp_all := black_comp_all + hisp_comp_all]
panel_all[, minority_share_all := fifelse(total_comp_all > 0,
                                           minority_comp_all / total_comp_all, NA_real_)]
panel_all[, log_total_all := log(total_comp_all + 1)]
panel_all[, ge_active := as.integer(year >= 2015 & year <= 2018)]
panel_all[, post_repeal := as.integer(year >= 2019)]
saveRDS(panel_all, file.path("..", "data", "analysis_panel_all_awards.rds"))

cat("Analysis panels saved.\n")
