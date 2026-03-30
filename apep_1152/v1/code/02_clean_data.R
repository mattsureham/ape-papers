## 02_clean_data.R — The Stranded Signal (apep_1152)
source(file.path(here::here(), "output", "apep_1152", "v1", "code", "00_packages.R"))
DATA_DIR <- file.path(here::here(), "output", "apep_1152", "v1", "data")

# Load coal generator data
coal_op <- fread(file.path(DATA_DIR, "coal_operable.csv"))
coal_ret <- fread(file.path(DATA_DIR, "coal_retired.csv"))

# CES dates
ces <- fread(file.path(DATA_DIR, "ces_enactment_dates.csv"))

cat("=== BUILDING GENERATOR-YEAR PANEL ===\n")

# Standardize column names
setnames(coal_op, "Plant Code", "plant_id", skip_absent = TRUE)
setnames(coal_op, "Generator ID", "gen_id", skip_absent = TRUE)
setnames(coal_op, "State", "state", skip_absent = TRUE)
setnames(coal_op, "Nameplate Capacity (MW)", "capacity_mw", skip_absent = TRUE)
setnames(coal_op, "Operating Year", "op_year", skip_absent = TRUE)
setnames(coal_op, "Energy Source 1", "fuel_type", skip_absent = TRUE)

setnames(coal_ret, "Plant Code", "plant_id", skip_absent = TRUE)
setnames(coal_ret, "Generator ID", "gen_id", skip_absent = TRUE)
setnames(coal_ret, "State", "state", skip_absent = TRUE)
setnames(coal_ret, "Nameplate Capacity (MW)", "capacity_mw", skip_absent = TRUE)
setnames(coal_ret, "Operating Year", "op_year", skip_absent = TRUE)
setnames(coal_ret, "Retirement Year", "ret_year", skip_absent = TRUE)
setnames(coal_ret, "Energy Source 1", "fuel_type", skip_absent = TRUE)

# Clean
coal_op[, `:=`(
  plant_id = as.integer(plant_id),
  capacity_mw = as.numeric(capacity_mw),
  op_year = as.integer(op_year),
  ret_year = NA_integer_,
  gen_key = paste(plant_id, gen_id, sep = "_")
)]

coal_ret[, `:=`(
  plant_id = as.integer(plant_id),
  capacity_mw = as.numeric(capacity_mw),
  op_year = as.integer(op_year),
  ret_year = as.integer(ret_year),
  gen_key = paste(plant_id, gen_id, sep = "_")
)]

# Combine
keep_cols <- c("gen_key", "plant_id", "gen_id", "state", "capacity_mw",
               "op_year", "ret_year", "fuel_type", "status")
coal_all <- rbind(
  coal_op[, ..keep_cols],
  coal_ret[, ..keep_cols],
  fill = TRUE
)

cat(sprintf("Total unique coal generators: %d\n", nrow(coal_all)))
cat(sprintf("  Operable: %d, Retired: %d\n",
            sum(coal_all$status == "operable"), sum(coal_all$status == "retired")))

# Merge CES dates
coal_all <- merge(coal_all, ces[, .(state, ces_year)], by = "state", all.x = TRUE)
coal_all[is.na(ces_year), ces_year := 0]  # 0 = never treated

cat(sprintf("\nGenerators in CES states: %d (%.1f%%)\n",
            sum(coal_all$ces_year > 0),
            100 * mean(coal_all$ces_year > 0)))
cat(sprintf("Generators in never-treated states: %d\n",
            sum(coal_all$ces_year == 0)))

# Show CES state coal generator counts
cat("\nCoal generators in CES states:\n")
print(coal_all[ces_year > 0, .(n_generators = .N, total_MW = sum(capacity_mw, na.rm = TRUE)),
               by = .(state, ces_year)][order(ces_year)])

# =============================================================================
# BUILD GENERATOR-YEAR PANEL (2008-2024)
# =============================================================================
cat("\nBuilding generator-year panel...\n")

years <- 2008:2024
panel_list <- list()

for (y in years) {
  # For each year, a generator is "at risk" if it was operable at start of year
  # It was operable if: op_year <= y AND (ret_year is NA or ret_year >= y)
  dt_y <- coal_all[op_year <= y & (is.na(ret_year) | ret_year >= y)]
  dt_y[, `:=`(
    year = y,
    retired_this_year = as.integer(!is.na(ret_year) & ret_year == y),
    vintage = y - op_year,
    post_ces = as.integer(ces_year > 0 & y >= ces_year),
    years_to_ces = ifelse(ces_year > 0, y - ces_year, NA_integer_)
  )]
  panel_list[[as.character(y)]] <- dt_y
}

panel <- rbindlist(panel_list, use.names = TRUE, fill = TRUE)
cat(sprintf("Panel: %d generator-year observations\n", nrow(panel)))
cat(sprintf("  Unique generators: %d\n", length(unique(panel$gen_key))))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))

# Treatment group for CS-DiD
# Group = ces_year (year of state CES adoption), 0 = never treated
panel[, g := ces_year]

# Retirement rates by CES status
cat("\n=== SMOKE TEST: RETIREMENT RATES ===\n")
ret_rates <- panel[, .(
  n_generators = .N,
  n_retired = sum(retired_this_year),
  ret_rate = mean(retired_this_year)
), by = .(year, ces_status = ifelse(ces_year > 0, "CES state", "No CES"))]

cat("Annual retirement rates by CES status:\n")
wide <- dcast(ret_rates, year ~ ces_status, value.var = c("ret_rate", "n_generators"))
print(wide)

# Pre-CES vs Post-CES comparison
cat("\n=== SMOKE TEST: PRE vs POST CES ===\n")
pre_post <- panel[ces_year > 0, .(
  ret_rate = mean(retired_this_year),
  n_obs = .N
), by = .(pre_post = ifelse(year < ces_year, "Pre-CES", "Post-CES"))]
print(pre_post)

# Save panel
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis_panel.csv (%d rows)\n", nrow(panel)))

# Diagnostics
diag <- list(
  n_treated = sum(panel$ces_year > 0 & panel$year == 2024),
  n_pre = length(unique(panel$year[panel$year < 2015])),
  n_obs = nrow(panel)
)
writeLines(toJSON(diag, auto_unbox = TRUE), file.path(DATA_DIR, "diagnostics.json"))
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
