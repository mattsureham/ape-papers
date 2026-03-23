# 02_clean_data.R — Construct analysis variables for NFA reform study
# apep_0813/v1

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- readRDS("data/panel.rds")
cat(sprintf("Loaded panel: %d obs (%d cantons × %d years)\n",
            nrow(panel), uniqueN(panel$canton_id), uniqueN(panel$year)))

# -------------------------------------------------------------------
# Additional variable construction
# -------------------------------------------------------------------

# Log population (for growth regressions)
panel[, log_pop := log(population)]

# Population growth rate (%)
panel[order(canton_id, year), pop_growth := (population / shift(population) - 1) * 100,
      by = canton_id]

# Lagged population (for rates)
panel[order(canton_id, year), lag_pop := shift(population), by = canton_id]

# Interaction term: NFA intensity × post
panel[, intensity_post := nfa_intensity * post]

# Binary treatment (recipient = 1, payer = 0, excluding near-zero)
panel[, recipient := as.integer(nfa_group == "recipient")]

# Demeaned intensity (for cleaner event-study plots)
panel[, nfa_intensity_dm := nfa_intensity - mean(nfa_intensity)]

# Create event-time dummies for event study
# Relative to 2007 (last pre-NFA year)
panel[, event_time := year - 2008]

# Winsorize extreme values (Zug has RI=246.7, outlier)
# Create version without Zug for robustness
panel[, excl_zug := canton != "ZG"]

# -------------------------------------------------------------------
# Summary statistics
# -------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# Overall
cat("\nFull sample:\n")
print(panel[, .(
  N = .N,
  mean_net_mig_rate = round(mean(net_migration_rate, na.rm = TRUE), 2),
  sd_net_mig_rate = round(sd(net_migration_rate, na.rm = TRUE), 2),
  mean_in_mig_rate = round(mean(in_migration_rate, na.rm = TRUE), 2),
  sd_in_mig_rate = round(sd(in_migration_rate, na.rm = TRUE), 2),
  mean_pop = round(mean(population)),
  mean_nfa_intensity = round(mean(nfa_intensity), 3)
)])

# By group × period
cat("\nBy NFA group and period:\n")
print(panel[nfa_group != "near_zero", .(
  n_cantons = uniqueN(canton_id),
  mean_net_mig_rate = round(mean(net_migration_rate, na.rm = TRUE), 2),
  sd_net_mig_rate = round(sd(net_migration_rate, na.rm = TRUE), 2),
  mean_in_mig_rate = round(mean(in_migration_rate, na.rm = TRUE), 2),
  mean_pop_growth = round(mean(pop_growth, na.rm = TRUE), 2)
), by = .(nfa_group, period = fifelse(year < 2008, "pre", "post"))])

# Save for summary statistics table
sumstats <- panel[, .(
  Variable = "Net migration rate (per 1000)",
  N = .N,
  Mean = round(mean(net_migration_rate, na.rm = TRUE), 2),
  SD = round(sd(net_migration_rate, na.rm = TRUE), 2),
  Min = round(min(net_migration_rate, na.rm = TRUE), 2),
  Max = round(max(net_migration_rate, na.rm = TRUE), 2)
)]

sumstats <- rbind(sumstats, panel[, .(
  Variable = "In-migration rate (per 1000)",
  N = .N,
  Mean = round(mean(in_migration_rate, na.rm = TRUE), 2),
  SD = round(sd(in_migration_rate, na.rm = TRUE), 2),
  Min = round(min(in_migration_rate, na.rm = TRUE), 2),
  Max = round(max(in_migration_rate, na.rm = TRUE), 2)
)])

sumstats <- rbind(sumstats, panel[, .(
  Variable = "Out-migration rate (per 1000)",
  N = .N,
  Mean = round(mean(out_migration_rate, na.rm = TRUE), 2),
  SD = round(sd(out_migration_rate, na.rm = TRUE), 2),
  Min = round(min(out_migration_rate, na.rm = TRUE), 2),
  Max = round(max(out_migration_rate, na.rm = TRUE), 2)
)])

sumstats <- rbind(sumstats, panel[, .(
  Variable = "Population (thousands)",
  N = .N,
  Mean = round(mean(population / 1000)),
  SD = round(sd(population / 1000)),
  Min = round(min(population / 1000)),
  Max = round(max(population / 1000))
)])

sumstats <- rbind(sumstats, panel[, .(
  Variable = "Population growth (\\%)",
  N = sum(!is.na(pop_growth)),
  Mean = round(mean(pop_growth, na.rm = TRUE), 2),
  SD = round(sd(pop_growth, na.rm = TRUE), 2),
  Min = round(min(pop_growth, na.rm = TRUE), 2),
  Max = round(max(pop_growth, na.rm = TRUE), 2)
)])

sumstats <- rbind(sumstats, panel[, .(
  Variable = "NFA intensity (100 - RI)/100",
  N = .N,
  Mean = round(mean(nfa_intensity), 3),
  SD = round(sd(nfa_intensity), 3),
  Min = round(min(nfa_intensity), 3),
  Max = round(max(nfa_intensity), 3)
)])

cat("\nSummary statistics table:\n")
print(sumstats)

saveRDS(sumstats, "data/sumstats.rds")

# Save cleaned panel
saveRDS(panel, "data/panel_clean.rds")
cat("\nSaved data/panel_clean.rds and data/sumstats.rds\n")
