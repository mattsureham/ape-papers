# 02_clean_data.R — apep_1239: Swiss NFA Reform
# Merge datasets, construct treatment variables, build analysis panel

source("00_packages.R")

data_dir <- "../data/"

# Load data
demog <- readRDS(paste0(data_dir, "demog_panel.rds"))
nfa   <- readRDS(paste0(data_dir, "nfa_transfers.rds"))

cat("Loaded:\n")
cat(sprintf("  Demographic panel: %d obs (%d cantons x %d years)\n",
            nrow(demog), n_distinct(demog$canton_code), n_distinct(demog$year)))
cat(sprintf("  NFA cantons: %d\n", nrow(nfa)))

# ============================================================
# MERGE: canton-year panel with NFA treatment intensity
# ============================================================

panel <- demog %>%
  left_join(nfa %>% select(canton_code, resource_index_2008, nfa_status, transfer_intensity),
            by = "canton_code") %>%
  mutate(
    post = as.integer(year >= 2008),
    # Continuous treatment: transfer intensity * post
    treat_cont = transfer_intensity * post,
    # Binary treatment indicators
    is_recipient = as.integer(nfa_status == "recipient"),
    is_payer = as.integer(nfa_status == "payer"),
    # Event study: years relative to 2008
    event_time = year - 2008,
    # Log population
    log_pop = log(population),
    # Canton factor for FE
    canton_f = factor(canton_code),
    year_f = factor(year)
  )

# Verify merge
stopifnot("Merge produced NAs" = sum(is.na(panel$transfer_intensity)) == 0)
stopifnot("Wrong panel size" = nrow(panel) == 26 * 24)

cat("\n=== ANALYSIS PANEL ===\n")
cat(sprintf("Panel: %d canton-years\n", nrow(panel)))
cat(sprintf("Pre-period (2000-2007): %d obs\n", sum(panel$year < 2008)))
cat(sprintf("Post-period (2008-2023): %d obs\n", sum(panel$year >= 2008)))
cat(sprintf("Recipients: %d cantons\n", sum(nfa$nfa_status == "recipient")))
cat(sprintf("Payers: %d cantons\n", sum(nfa$nfa_status == "payer")))
cat(sprintf("Near-zero: %d cantons\n", sum(nfa$nfa_status == "near_zero")))

# Summary statistics by NFA status
cat("\nPre-period summary by NFA status:\n")
pre_summary <- panel %>%
  filter(year < 2008) %>%
  group_by(nfa_status) %>%
  summarise(
    n_cantons = n_distinct(canton_code),
    mean_pop = mean(population, na.rm = TRUE),
    mean_in_mig_rate = mean(in_migration_rate, na.rm = TRUE),
    mean_net_mig_rate = mean(net_migration_rate, na.rm = TRUE),
    mean_resource_idx = mean(resource_index_2008),
    .groups = "drop"
  )
print(pre_summary)

# Summary statistics for the paper
cat("\nFull-sample summary statistics:\n")
summ_stats <- panel %>%
  summarise(
    across(c(population, in_migration, out_migration, net_migration,
             net_migration_rate, in_migration_rate, transfer_intensity),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  )

# Print key stats
vars_to_show <- c("population", "in_migration", "net_migration",
                   "net_migration_rate", "transfer_intensity")
for (v in vars_to_show) {
  m <- summ_stats[[paste0(v, "_mean")]]
  s <- summ_stats[[paste0(v, "_sd")]]
  cat(sprintf("  %s: mean=%.1f, sd=%.1f\n", v, m, s))
}

saveRDS(panel, paste0(data_dir, "analysis_panel.rds"))
cat(sprintf("\nSaved analysis panel: %s\n", paste0(data_dir, "analysis_panel.rds")))
