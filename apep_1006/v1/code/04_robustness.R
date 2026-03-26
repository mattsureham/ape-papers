# 04_robustness.R — Robustness checks and mechanism tests for APEP 1006

source("00_packages.R")

data_dir <- "../data"

cs_sample <- fread(file.path(data_dir, "cs_sample.csv"))
full_panel <- fread(file.path(data_dir, "corridor_panel.csv"))
rpw_raw <- fread(file.path(data_dir, "rpw_raw.csv"))

# Ensure corridor_num exists
cs_sample[, corridor_num := as.integer(factor(corridor_id))]
full_panel[, corridor_num := as.integer(factor(corridor_id))]

# ============================================================================
# 1. SENDING-COUNTRY PLACEBO
# ============================================================================
cat("\n=== SENDING-COUNTRY PLACEBO ===\n")
cat("If mechanism is de-risking of RECEIVING-country banks,\n")
cat("then grey-listing the SENDING country should NOT affect costs.\n\n")

twfe_send <- feols(avg_cost ~ source_grey_listed | corridor_num + time_index,
                   data = full_panel, cluster = ~source_code)
cat("Sending-country grey-listing effect:\n")
cat("  Coefficient:", round(coef(twfe_send)["source_grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_send)["source_grey_listed"], 4), "\n")
cat("  p-value:", round(pvalue(twfe_send)["source_grey_listed"], 4), "\n")

# Both sides in same regression
twfe_both <- feols(avg_cost ~ grey_listed + source_grey_listed |
                     corridor_num + time_index,
                   data = full_panel, cluster = ~destination_code + source_code)
cat("\nBoth sending and receiving grey-listing:\n")
cat("  Receiving:", round(coef(twfe_both)["grey_listed"], 4),
    "(SE:", round(se(twfe_both)["grey_listed"], 4), ")\n")
cat("  Sending:", round(coef(twfe_both)["source_grey_listed"], 4),
    "(SE:", round(se(twfe_both)["source_grey_listed"], 4), ")\n")

# ============================================================================
# 2. CHANNEL HETEROGENEITY (Bank vs MTO)
# ============================================================================
cat("\n=== CHANNEL HETEROGENEITY ===\n")

# Go back to firm-level data to split by provider type
rpw_raw[, year := as.integer(sub("_.*", "", period))]
rpw_raw[, quarter := as.integer(sub(".*_(\\d)Q", "\\1", period))]
rpw_raw[, time_index := (year - 2010) * 4 + quarter]
rpw_raw[, corridor_id := paste0(source_code, "_", destination_code)]
setnames(rpw_raw, "cc1 total cost %", "total_cost_pct", skip_absent = TRUE)
rpw_raw[, total_cost_pct := as.numeric(total_cost_pct)]

rpw_raw[, firm_type_clean := fcase(
  grepl("^Bank", firm_type, ignore.case = TRUE) &
    !grepl("Money Transfer", firm_type, ignore.case = TRUE), "Bank",
  grepl("Mobile", firm_type, ignore.case = TRUE), "Mobile",
  grepl("Post", firm_type, ignore.case = TRUE), "Post Office",
  default = "MTO"
)]

rpw_clean <- rpw_raw[!is.na(total_cost_pct) & total_cost_pct > 0 & total_cost_pct < 50]

# Aggregate by channel
bank_qt <- rpw_clean[firm_type_clean == "Bank",
  .(avg_cost = mean(total_cost_pct, na.rm = TRUE), n_obs = .N),
  by = .(corridor_id, source_code, destination_code, time_index)]

mto_qt <- rpw_clean[firm_type_clean == "MTO",
  .(avg_cost = mean(total_cost_pct, na.rm = TRUE), n_obs = .N),
  by = .(corridor_id, source_code, destination_code, time_index)]

# Merge with grey-list status
fatf <- fread(file.path(data_dir, "fatf_greylist_episodes.csv"))
all_quarters <- sort(unique(full_panel$time_index))
all_dest <- sort(unique(full_panel$destination_code))

# Reuse the grey-list panel from full_panel
grey_panel <- unique(full_panel[, .(destination_code, time_index, grey_listed)])

bank_qt <- merge(bank_qt, grey_panel, by = c("destination_code", "time_index"), all.x = TRUE)
bank_qt[is.na(grey_listed), grey_listed := 0L]
bank_qt[, corridor_num := as.integer(factor(corridor_id))]

mto_qt <- merge(mto_qt, grey_panel, by = c("destination_code", "time_index"), all.x = TRUE)
mto_qt[is.na(grey_listed), grey_listed := 0L]
mto_qt[, corridor_num := as.integer(factor(corridor_id))]

cat("Bank corridor-quarters:", nrow(bank_qt), "\n")
cat("MTO corridor-quarters:", nrow(mto_qt), "\n")

# TWFE by channel
if (nrow(bank_qt) > 100) {
  twfe_bank <- feols(avg_cost ~ grey_listed | corridor_num + time_index,
                     data = bank_qt, cluster = ~destination_code)
  cat("\nBank channel:\n")
  cat("  Mean cost:", round(mean(bank_qt$avg_cost, na.rm = TRUE), 2), "\n")
  cat("  Coefficient:", round(coef(twfe_bank)["grey_listed"], 4), "\n")
  cat("  SE:", round(se(twfe_bank)["grey_listed"], 4), "\n")
  cat("  p-value:", round(pvalue(twfe_bank)["grey_listed"], 4), "\n")
} else {
  cat("Too few bank observations for estimation\n")
  twfe_bank <- NULL
}

twfe_mto <- feols(avg_cost ~ grey_listed | corridor_num + time_index,
                  data = mto_qt, cluster = ~destination_code)
cat("\nMTO channel:\n")
cat("  Mean cost:", round(mean(mto_qt$avg_cost, na.rm = TRUE), 2), "\n")
cat("  Coefficient:", round(coef(twfe_mto)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_mto)["grey_listed"], 4), "\n")
cat("  p-value:", round(pvalue(twfe_mto)["grey_listed"], 4), "\n")

# ============================================================================
# 3. PROVIDER COUNT (EXTENSIVE MARGIN)
# ============================================================================
cat("\n=== PROVIDER COUNT (EXTENSIVE MARGIN) ===\n")

# Does grey-listing reduce the number of providers in a corridor?
twfe_providers <- feols(log(n_firms + 1) ~ grey_listed | corridor_num + time_index,
                        data = full_panel, cluster = ~destination_code)
cat("Effect on log(n_providers):\n")
cat("  Coefficient:", round(coef(twfe_providers)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_providers)["grey_listed"], 4), "\n")
cat("  p-value:", round(pvalue(twfe_providers)["grey_listed"], 4), "\n")

# Bank count specifically
bank_count_qt <- rpw_clean[, .(
  n_bank = sum(firm_type_clean == "Bank"),
  n_mto = sum(firm_type_clean == "MTO"),
  n_total = .N
), by = .(corridor_id, destination_code, time_index)]

bank_count_qt <- merge(bank_count_qt, grey_panel,
                       by = c("destination_code", "time_index"), all.x = TRUE)
bank_count_qt[is.na(grey_listed), grey_listed := 0L]
bank_count_qt[, corridor_num := as.integer(factor(corridor_id))]

twfe_bank_count <- feols(n_bank ~ grey_listed | corridor_num + time_index,
                         data = bank_count_qt, cluster = ~destination_code)
cat("\nEffect on bank provider count:\n")
cat("  Coefficient:", round(coef(twfe_bank_count)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_bank_count)["grey_listed"], 4), "\n")

twfe_mto_count <- feols(n_mto ~ grey_listed | corridor_num + time_index,
                        data = bank_count_qt, cluster = ~destination_code)
cat("\nEffect on MTO provider count:\n")
cat("  Coefficient:", round(coef(twfe_mto_count)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_mto_count)["grey_listed"], 4), "\n")

# ============================================================================
# 4. ENTRY vs EXIT ASYMMETRY
# ============================================================================
cat("\n=== ENTRY vs EXIT ASYMMETRY ===\n")

# Create treatment for delisting episodes
fatf_exits <- fatf[!is.na(exit_year)]
fatf_exits[, exit_ti := exit_qtr - 8]

# For each destination, find exits within sample
exit_events <- fatf_exits[exit_ti >= min(all_quarters) & exit_ti <= max(all_quarters) &
                          iso3 %in% all_dest]
cat("Exit events in sample:", nrow(exit_events), "\n")

if (nrow(exit_events) > 5) {
  # Create a panel around exit events
  # Use +-8 quarters window
  exit_panel_list <- list()
  for (i in seq_len(nrow(exit_events))) {
    iso <- exit_events$iso3[i]
    exit_t <- exit_events$exit_ti[i]
    window <- (exit_t - 8):(exit_t + 8)
    window <- window[window %in% all_quarters]

    corridors_to_dest <- unique(full_panel[destination_code == iso &
                                           time_index %in% window, corridor_id])
    if (length(corridors_to_dest) > 0) {
      ep <- full_panel[corridor_id %in% corridors_to_dest & time_index %in% window]
      ep[, event_time := time_index - exit_t]
      ep[, post_exit := as.integer(time_index >= exit_t)]
      ep[, exit_episode := paste0(iso, "_", exit_t)]
      exit_panel_list[[i]] <- ep
    }
  }

  if (length(exit_panel_list) > 0) {
    exit_panel <- rbindlist(exit_panel_list, fill = TRUE)
    exit_panel[, corridor_num := as.integer(factor(corridor_id))]

    twfe_exit <- feols(avg_cost ~ post_exit | corridor_num + time_index,
                       data = exit_panel, cluster = ~destination_code)
    cat("Effect of delisting on costs (post_exit):\n")
    cat("  Coefficient:", round(coef(twfe_exit)["post_exit"], 4), "\n")
    cat("  SE:", round(se(twfe_exit)["post_exit"], 4), "\n")
    cat("  p-value:", round(pvalue(twfe_exit)["post_exit"], 4), "\n")
  }
}

# ============================================================================
# 5. ALTERNATIVE CONTROL GROUPS
# ============================================================================
cat("\n=== ALTERNATIVE CONTROL GROUP ===\n")

# CS-DiD with not-yet-treated as control
cs_sample2 <- copy(cs_sample)
cs_out_nyt <- att_gt(
  yname  = "avg_cost",
  tname  = "time_index",
  idname = "corridor_num",
  gname  = "first_treat",
  data   = as.data.frame(cs_sample2),
  control_group = "notyettreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "varying"
)

agg_nyt <- aggte(cs_out_nyt, type = "simple", na.rm = TRUE)
cat("CS-DiD with not-yet-treated controls:\n")
cat("  ATT:", round(agg_nyt$overall.att, 4), "\n")
cat("  SE:", round(agg_nyt$overall.se, 4), "\n")

# ============================================================================
# 6. FX MARGIN (Alternative Outcome)
# ============================================================================
cat("\n=== FX MARGIN ===\n")
twfe_fx <- feols(avg_fx_margin ~ grey_listed | corridor_num + time_index,
                 data = full_panel[!is.na(avg_fx_margin)],
                 cluster = ~destination_code)
cat("Effect on FX margin:\n")
cat("  Coefficient:", round(coef(twfe_fx)["grey_listed"], 4), "\n")
cat("  SE:", round(se(twfe_fx)["grey_listed"], 4), "\n")

# ============================================================================
# 7. Save robustness results
# ============================================================================
robust_results <- list(
  sending_placebo_coef = as.numeric(coef(twfe_send)["source_grey_listed"]),
  sending_placebo_se = as.numeric(se(twfe_send)["source_grey_listed"]),
  sending_placebo_p = as.numeric(pvalue(twfe_send)["source_grey_listed"]),
  bank_coef = if (!is.null(twfe_bank)) as.numeric(coef(twfe_bank)["grey_listed"]) else NA,
  bank_se = if (!is.null(twfe_bank)) as.numeric(se(twfe_bank)["grey_listed"]) else NA,
  mto_coef = as.numeric(coef(twfe_mto)["grey_listed"]),
  mto_se = as.numeric(se(twfe_mto)["grey_listed"]),
  provider_coef = as.numeric(coef(twfe_providers)["grey_listed"]),
  provider_se = as.numeric(se(twfe_providers)["grey_listed"]),
  bank_count_coef = as.numeric(coef(twfe_bank_count)["grey_listed"]),
  bank_count_se = as.numeric(se(twfe_bank_count)["grey_listed"]),
  mto_count_coef = as.numeric(coef(twfe_mto_count)["grey_listed"]),
  mto_count_se = as.numeric(se(twfe_mto_count)["grey_listed"]),
  fx_coef = as.numeric(coef(twfe_fx)["grey_listed"]),
  fx_se = as.numeric(se(twfe_fx)["grey_listed"]),
  nyt_att = agg_nyt$overall.att,
  nyt_se = agg_nyt$overall.se,
  bank_mean_cost = mean(bank_qt$avg_cost, na.rm = TRUE),
  mto_mean_cost = mean(mto_qt$avg_cost, na.rm = TRUE)
)

write_json(robust_results, file.path(data_dir, "robustness_results.json"),
           auto_unbox = TRUE, pretty = TRUE)

saveRDS(list(
  twfe_send = twfe_send,
  twfe_both = twfe_both,
  twfe_bank = twfe_bank,
  twfe_mto = twfe_mto,
  twfe_providers = twfe_providers,
  twfe_bank_count = twfe_bank_count,
  twfe_mto_count = twfe_mto_count,
  twfe_fx = twfe_fx,
  robust_results = robust_results
), file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
