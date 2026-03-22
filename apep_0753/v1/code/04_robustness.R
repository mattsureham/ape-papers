# ============================================================
# 04_robustness.R — Robustness checks
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

source("00_packages.R")

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Load data
# ----------------------------------------------------------
cat("=== Loading data ===\n")

panel <- readRDS(file.path(data_dir, "panel_by_type.rds"))

# Re-create state_id mapping
state_map <- data.table(state = sort(unique(panel$state)),
                        state_id = seq_along(sort(unique(panel$state))))
panel <- merge(panel, state_map, by = "state")

conv <- panel[store_type == "convenience"]

# ----------------------------------------------------------
# 2. Bacon decomposition
# ----------------------------------------------------------
cat("\n=== Bacon Decomposition ===\n")

bacon_data <- as.data.frame(conv[, .(state_id, time_id, exit_rate, treated)])

bacon_out <- bacon(exit_rate ~ treated,
                   data = bacon_data,
                   id_var = "state_id",
                   time_var = "time_id")

cat("  Bacon decomposition:\n")
print(summary(bacon_out))

# Breakdown by type
bacon_summary <- bacon_out %>%
  group_by(type) %>%
  summarise(
    n_comparisons = n(),
    avg_weight = mean(weight),
    total_weight = sum(weight),
    avg_estimate = weighted.mean(estimate, weight),
    .groups = "drop"
  )
cat("\n  By comparison type:\n")
print(as.data.frame(bacon_summary))

saveRDS(bacon_out, file.path(data_dir, "bacon_results.rds"))
saveRDS(bacon_summary, file.path(data_dir, "bacon_summary.rds"))

# ----------------------------------------------------------
# 3. Heterogeneity: Early opt-out vs late
# ----------------------------------------------------------
cat("\n=== Heterogeneity: Early vs Late Opt-Out ===\n")

# Early opt-outs (treated 2021-2022)
early_states <- conv[early_optout == TRUE, unique(state)]
late_states <- conv[early_optout == FALSE, unique(state)]

cat("  Early opt-out states:", length(early_states), "\n")
cat("  Late/universal states:", length(late_states), "\n")

# TWFE for early opt-out states only (staggered variation)
twfe_early <- feols(exit_rate ~ treated | state + time_id,
                    data = conv[state %in% c(early_states)],
                    cluster = ~state)
cat("  Early opt-out TWFE:\n")
print(summary(twfe_early))

# For late states: all treated at same time, so use simple pre-post interaction
# with early opt-out states as comparison
conv[, early := as.integer(early_optout)]
twfe_hetero <- feols(exit_rate ~ treated * early | state + time_id,
                     data = conv, cluster = ~state)
cat("  Heterogeneity (treated × early opt-out):\n")
print(summary(twfe_hetero))

saveRDS(twfe_early, file.path(data_dir, "twfe_early.rds"))
saveRDS(twfe_hetero, file.path(data_dir, "twfe_hetero.rds"))

# ----------------------------------------------------------
# 4. Placebo: Entry rate as alternative outcome
# ----------------------------------------------------------
cat("\n=== Placebo: New authorization rate ===\n")

# Compute new authorization rate (stores entering per 1,000 active)
# We need to count new authorizations per state-quarter
retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"),
                   showProgress = FALSE)
setnames(retailers, gsub(" ", "_", names(retailers)))
retailers[, auth_date := as.Date(Authorization_Date, format = "%m/%d/%Y")]
retailers[, store_cat := fcase(
  Store_Type %in% c("Convenience Store"), "convenience",
  default = "other"
)]

# Count new convenience store authorizations by state-quarter
quarters <- readRDS(file.path(data_dir, "quarters.rds"))

entry_list <- list()
for (i in seq_len(nrow(quarters))) {
  q_start <- quarters$qtr_date[i]
  q_end <- q_start %m+% months(3) - 1

  state_entries <- retailers[store_cat == "convenience" &
                               State %in% unique(conv$state) &
                               auth_date >= q_start & auth_date <= q_end,
                             .N, by = State]

  for (s in unique(conv$state)) {
    n_new <- state_entries[State == s, N]
    if (length(n_new) == 0) n_new <- 0L

    entry_list[[length(entry_list) + 1]] <- data.table(
      state = s,
      time_id = quarters$time_id[i],
      n_new_auth = n_new
    )
  }
}

entry_panel <- rbindlist(entry_list)
conv_entry <- merge(conv, entry_panel, by = c("state", "time_id"))
conv_entry[, entry_rate := ifelse(n_active > 0,
                                   (n_new_auth / n_active) * 1000,
                                   NA_real_)]

twfe_entry <- feols(entry_rate ~ treated | state + time_id,
                    data = conv_entry, cluster = ~state)
cat("  Entry rate TWFE:\n")
print(summary(twfe_entry))

saveRDS(twfe_entry, file.path(data_dir, "twfe_entry.rds"))

# ----------------------------------------------------------
# 5. Alternative outcome: Net change rate
# ----------------------------------------------------------
cat("\n=== Net change rate ===\n")

conv_entry[, net_rate := entry_rate - exit_rate]

twfe_net <- feols(net_rate ~ treated | state + time_id,
                  data = conv_entry, cluster = ~state)
cat("  Net rate TWFE:\n")
print(summary(twfe_net))

saveRDS(twfe_net, file.path(data_dir, "twfe_net.rds"))

# ----------------------------------------------------------
# 6. Level outcome: Number of exits
# ----------------------------------------------------------
cat("\n=== Level outcome: Number of exits ===\n")

twfe_level <- feols(n_exits ~ treated | state + time_id,
                    data = conv, cluster = ~state)
cat("  N exits TWFE:\n")
print(summary(twfe_level))

saveRDS(twfe_level, file.path(data_dir, "twfe_level.rds"))

# ----------------------------------------------------------
# 7. Save all robustness results for tables
# ----------------------------------------------------------
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  bacon = bacon_summary,
  twfe_early = twfe_early,
  twfe_hetero = twfe_hetero,
  twfe_entry = twfe_entry,
  twfe_net = twfe_net,
  twfe_level = twfe_level
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("=== Robustness checks complete ===\n")
