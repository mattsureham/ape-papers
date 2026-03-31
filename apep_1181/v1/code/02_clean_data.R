# 02_clean_data.R — Identify negative-price episodes, classify by duration, merge flows
# Key: EEG § 51 clawback triggers when day-ahead price < 0 for N+ consecutive hours
# Thresholds: >=6h (pre-2021), >=4h (2021-2023), >=3h (2024+)

source("00_packages.R")

data_dir <- "../data"
prices <- fread(file.path(data_dir, "prices_de.csv"))
flows <- fread(file.path(data_dir, "flows_hourly.csv"))

# ============================================================
# 1. Identify consecutive negative-price episodes
# ============================================================
cat("=== Identifying negative-price episodes ===\n")

prices <- prices[order(datetime)]
prices[, negative := price_eur_mwh < 0]

# Run-length encoding to identify consecutive negative-price blocks
rle_neg <- rle(prices$negative)
prices[, episode_id := rep(seq_along(rle_neg$lengths), rle_neg$lengths)]

# Keep only negative episodes
neg_hours <- prices[negative == TRUE]
neg_hours[, episode_duration := .N, by = episode_id]

episodes <- neg_hours[, .(
  start_datetime = min(datetime),
  end_datetime   = max(datetime),
  start_date     = min(date),
  duration_hours = .N,
  mean_price     = mean(price_eur_mwh),
  min_price      = min(price_eur_mwh),
  year           = year(min(datetime)),
  month          = month(min(datetime)),
  yearmonth      = year(min(datetime)) * 100 + month(min(datetime)),
  day_of_week    = data.table::wday(min(datetime))
), by = episode_id]

cat(sprintf("Total negative-price episodes: %d\n", nrow(episodes)))
cat("Episodes by duration:\n")
print(episodes[, .N, by = duration_hours][order(duration_hours)])

# ============================================================
# 2. Classify episodes by clawback regime and treatment status
# ============================================================
cat("\n=== Classifying episodes ===\n")

# Policy regimes
episodes[, regime := fcase(
  year < 2021,  "6h_rule",
  year < 2024,  "4h_rule",
  year >= 2024, "3h_rule"
)]

# Treatment status for the 2021 reform (6h → 4h)
# Treated: episodes of 4-5 hours (newly subject to clawback after 2021)
# Control: episodes of 1-3 hours (never subject to clawback)
# Always-treated: episodes of 6+ hours (always subject to clawback)
episodes[, treat_2021 := fcase(
  duration_hours >= 4 & duration_hours <= 5, "treated",
  duration_hours >= 1 & duration_hours <= 3, "control",
  duration_hours >= 6, "always_treated",
  default = NA_character_
)]

# Treatment status for the 2024 reform (4h → 3h)
# Treated: episodes of exactly 3 hours (newly subject to clawback after 2024)
# Control: episodes of 1-2 hours (never subject to clawback)
episodes[, treat_2024 := fcase(
  duration_hours == 3, "treated",
  duration_hours >= 1 & duration_hours <= 2, "control",
  duration_hours >= 4, "always_treated",
  default = NA_character_
)]

# Binary treatment indicators
episodes[, treated_2021 := as.integer(treat_2021 == "treated")]
episodes[, treated_2024 := as.integer(treat_2024 == "treated")]
episodes[, post_2021 := as.integer(year >= 2021)]
episodes[, post_2024 := as.integer(year >= 2024)]

cat("Regime distribution:\n")
print(episodes[, .N, by = regime])

cat("\n2021 reform classification:\n")
print(episodes[, .N, by = .(treat_2021, regime)])

cat("\n2024 reform classification:\n")
print(episodes[, .N, by = .(treat_2024, regime)])

# ============================================================
# 3. Merge episodes with bilateral flows
# ============================================================
cat("\n=== Merging episodes with bilateral flows ===\n")

# For each episode, get the flows during that episode's hours
neg_hours_slim <- neg_hours[, .(episode_id, date, hour)]

# Merge flows to negative-price hours
flow_ep <- merge(flows, neg_hours_slim,
                 by = c("date", "hour"),
                 allow.cartesian = FALSE)

# Aggregate to episode × neighbor level: mean flow during episode
ep_flows <- flow_ep[, .(
  mean_export_mw = mean(export_mw, na.rm = TRUE),
  total_export_mwh = sum(export_mw, na.rm = TRUE),
  n_hours = .N
), by = .(episode_id, neighbor)]

# Merge episode metadata
panel <- merge(ep_flows, episodes, by = "episode_id")

cat(sprintf("Episode-neighbor observations: %d\n", nrow(panel)))
cat(sprintf("Unique episodes with flow data: %d\n", uniqueN(panel$episode_id)))
cat(sprintf("Unique neighbors: %d\n", uniqueN(panel$neighbor)))

# ============================================================
# 4. Summary statistics
# ============================================================
cat("\n=== Summary statistics ===\n")

cat("\nMean export (MW) during negative-price episodes by regime:\n")
print(panel[, .(mean_export = round(mean(mean_export_mw), 0),
                sd_export = round(sd(mean_export_mw), 0),
                n_episodes = uniqueN(episode_id),
                n_obs = .N),
            by = regime][order(regime)])

cat("\nMean export by treatment status (2021 reform):\n")
print(panel[!is.na(treat_2021) & treat_2021 != "always_treated",
            .(mean_export = round(mean(mean_export_mw), 0),
              n_obs = .N),
            by = .(treat_2021, post_2021)])

cat("\nMean export by treatment status (2024 reform):\n")
print(panel[!is.na(treat_2024) & treat_2024 != "always_treated",
            .(mean_export = round(mean(mean_export_mw), 0),
              n_obs = .N),
            by = .(treat_2024, post_2024)])

# ============================================================
# 5. Save analysis-ready panel
# ============================================================
fwrite(panel, file.path(data_dir, "panel_episode_neighbor.csv"))
fwrite(episodes, file.path(data_dir, "episodes.csv"))

cat("\nSaved panel_episode_neighbor.csv and episodes.csv\n")
cat("=== Data cleaning complete ===\n")
