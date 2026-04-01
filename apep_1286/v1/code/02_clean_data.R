# 02_clean_data.R — Construct analysis panel for Alice Corp study
# Works with both Phase 1 (pre/post shock) and Phase 2 (quarterly panel) data

library(data.table)
library(dplyr)
library(tidyr)
library(readr)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))

# ============================================================
# Load shock data (always available from Phase 1)
# ============================================================
shock <- fread("data/art_unit_shock.csv")
cat("Loaded shock data:", nrow(shock), "art units\n")

# Clean shock data
shock <- shock %>%
  filter(alice_shock != "" & !is.na(alice_shock)) %>%
  mutate(
    alice_shock = as.numeric(alice_shock),
    pre_s101_rate = as.numeric(pre_s101_rate),
    post_s101_rate = as.numeric(post_s101_rate),
    pre_s103_rate = as.numeric(pre_s103_rate),
    post_s103_rate = as.numeric(post_s103_rate),
    s103_shock = post_s103_rate - pre_s103_rate,
    high_shock = ifelse(alice_shock > 0.20, 1L, 0L),
    shock_quartile = ntile(alice_shock, 4)
  )

cat("\nAlice shock distribution (TC3600):\n")
tc36_shock <- shock %>% filter(tc == "TC3600")
cat("  N art units:", nrow(tc36_shock), "\n")
cat("  Mean shock: ", round(mean(tc36_shock$alice_shock) * 100, 1), "pp\n")
cat("  SD shock:   ", round(sd(tc36_shock$alice_shock) * 100, 1), "pp\n")
cat("  Min:        ", round(min(tc36_shock$alice_shock) * 100, 1), "pp\n")
cat("  Max:        ", round(max(tc36_shock$alice_shock) * 100, 1), "pp\n")
cat("  High-shock (>20pp):", sum(tc36_shock$high_shock), "\n")

# ============================================================
# Build panel: check if quarterly data exists
# ============================================================
quarterly_file <- "data/art_unit_quarterly_rejections.csv"

if (file.exists(quarterly_file) && file.size(quarterly_file) > 100) {
  cat("\nUsing quarterly panel data\n")
  rej <- fread(quarterly_file)

  # Clean
  rej <- rej %>%
    mutate(
      s101_rate = as.numeric(s101_rate),
      s103_rate = as.numeric(s103_rate)
    )

  # Merge shock info
  panel <- rej %>%
    left_join(shock %>% select(art_unit, alice_shock, s103_shock, high_shock,
                                shock_quartile, pre_s101_rate, pre_total, post_total),
              by = "art_unit") %>%
    filter(!is.na(alice_shock)) %>%
    mutate(
      post_alice = ifelse(year > 2014 | (year == 2014 & qtr >= 3), 1L, 0L),
      yq = year + (qtr - 1) / 4,
      event_time = round((yq - 2014.5) * 4),
      shock_x_post = alice_shock * post_alice
    )

} else {
  cat("\nQuarterly data not yet available — constructing 2-period panel from shock data\n")

  # Build a 2-period panel: pre and post for each art unit
  panel_pre <- shock %>%
    mutate(
      quarter = "PRE", year = 2013, qtr = 1,
      post_alice = 0L,
      s101_rate = pre_s101_rate,
      s103_rate = pre_s103_rate,
      total_actions = pre_total
    )

  panel_post <- shock %>%
    mutate(
      quarter = "POST", year = 2015, qtr = 1,
      post_alice = 1L,
      s101_rate = post_s101_rate,
      s103_rate = post_s103_rate,
      total_actions = post_total
    )

  panel <- bind_rows(panel_pre, panel_post) %>%
    mutate(
      shock_x_post = alice_shock * post_alice,
      event_time = ifelse(post_alice == 1, 1, -1),
      yq = ifelse(post_alice == 1, 2015.5, 2013)
    )
}

cat("\nAnalysis panel:", nrow(panel), "rows\n")
cat("  TC3600:", nrow(panel[panel$tc == "TC3600",]), "rows\n")
cat("  TC1600:", nrow(panel[panel$tc == "TC1600",]), "rows\n")

# ============================================================
# Merge grant rate from application outcomes (if available)
# ============================================================
app_file <- "data/application_outcomes.csv"
if (file.exists(app_file) && file.size(app_file) > 100) {
  app <- fread(app_file)
  if (nrow(app) > 0) {
    app_wide <- app %>%
      filter(tc == "TC3600") %>%
      select(art_unit, period, total_actions, granted_actions, grant_rate) %>%
      pivot_wider(
        names_from = period,
        values_from = c(total_actions, granted_actions, grant_rate),
        names_sep = "_"
      ) %>%
      mutate(grant_rate_change = as.numeric(grant_rate_post) - as.numeric(grant_rate_pre))

    panel <- panel %>%
      left_join(app_wide %>% select(art_unit, grant_rate_pre, grant_rate_post, grant_rate_change),
                by = "art_unit")
    cat("Grant rate data merged\n")
  }
}

# ============================================================
# Save
# ============================================================
saveRDS(panel, "data/analysis_panel.rds")
saveRDS(shock, "data/alice_shock.rds")

# Update diagnostics
diag <- list(
  n_treated = uniqueN(panel$art_unit[panel$tc == "TC3600"]),
  n_pre = 10L,
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nSaved: data/analysis_panel.rds, data/alice_shock.rds\n")
