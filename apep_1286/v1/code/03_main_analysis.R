# 03_main_analysis.R — Main regression analysis for Alice Corp study
# Continuous-treatment DiD: alice_shock × post within TC 3600

library(data.table)
library(fixest)
library(dplyr)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))

panel <- readRDS("data/analysis_panel.rds")
shock <- readRDS("data/alice_shock.rds")

# Focus on TC3600 for within-TC analysis
tc36 <- panel %>% filter(tc == "TC3600", total_actions > 0)
cat("TC3600 panel: ", nrow(tc36), " obs, ", uniqueN(tc36$art_unit), " art units\n")

# ============================================================
# Table 1: Summary Statistics (will be formatted in 05_tables.R)
# ============================================================
sumstats <- tc36 %>%
  summarise(
    n = n(),
    n_au = n_distinct(art_unit),
    mean_total = mean(total_actions),
    sd_total = sd(total_actions),
    mean_s101_rate = mean(s101_rate, na.rm = TRUE),
    sd_s101_rate = sd(s101_rate, na.rm = TRUE),
    mean_s103_rate = mean(s103_rate, na.rm = TRUE),
    sd_s103_rate = sd(s103_rate, na.rm = TRUE),
    mean_shock = mean(alice_shock),
    sd_shock = sd(alice_shock),
    min_shock = min(alice_shock),
    max_shock = max(alice_shock)
  )
cat("\nSummary:\n")
print(sumstats)

# SD of outcome for SDE calculation
sd_s101 <- sd(tc36$s101_rate, na.rm = TRUE)
sd_total <- sd(tc36$total_actions, na.rm = TRUE)
cat("\nSD(§101 rate):", round(sd_s101, 4), "\n")
cat("SD(total actions):", round(sd_total, 1), "\n")

# ============================================================
# Main specification: Continuous-treatment DiD
# ============================================================
# Y_{a,t} = α_a + γ_t + β(AliceShock_a × Post_t) + ε_{a,t}

# Model 1: §101 rejection rate (first stage / mechanical check)
m1 <- feols(s101_rate ~ shock_x_post | art_unit + quarter, data = tc36,
            cluster = ~art_unit)

# Model 2: Add §103 shock × post as placebo control
m2 <- feols(s101_rate ~ shock_x_post + I(s103_shock * post_alice) | art_unit + quarter,
            data = tc36, cluster = ~art_unit)

# Model 3: Total actions (log) as outcome — volume effect
tc36$log_total <- log(tc36$total_actions + 1)
m3 <- feols(log_total ~ shock_x_post | art_unit + quarter, data = tc36,
            cluster = ~art_unit)

# Model 4: §103 rate as placebo outcome (should NOT respond to Alice shock)
m4 <- feols(s103_rate ~ shock_x_post | art_unit + quarter, data = tc36,
            cluster = ~art_unit)

cat("\n=== MAIN RESULTS ===\n")
etable(m1, m2, m3, m4,
       headers = c("§101 rate", "§101 + §103", "Log actions", "§103 placebo"),
       se.below = TRUE)

# ============================================================
# Event study specification
# ============================================================
# Omit period -1 (2014Q2, one quarter before Alice)
tc36$event_factor <- factor(tc36$event_time)
# Relevel to omit -1
tc36$event_factor <- relevel(tc36$event_factor, ref = "-1")

# Event study: §101 rate
es1 <- feols(s101_rate ~ i(event_time, alice_shock, ref = -1) | art_unit + quarter,
             data = tc36, cluster = ~art_unit)

# Event study: log total actions
es2 <- feols(log_total ~ i(event_time, alice_shock, ref = -1) | art_unit + quarter,
             data = tc36, cluster = ~art_unit)

# Event study: §103 rate (placebo)
es3 <- feols(s103_rate ~ i(event_time, alice_shock, ref = -1) | art_unit + quarter,
             data = tc36, cluster = ~art_unit)

cat("\n=== EVENT STUDY: §101 rate ===\n")
summary(es1)

# ============================================================
# Cross-TC analysis: TC3600 (treated) vs TC1600 (control)
# ============================================================
# Use full panel with both TCs
full_panel <- panel %>% filter(total_actions > 0) %>%
  mutate(
    tc36 = ifelse(tc == "TC3600", 1L, 0L),
    tc36_x_post = tc36 * post_alice,
    log_total = log(total_actions + 1)
  )

m5 <- feols(s101_rate ~ tc36_x_post | art_unit + quarter, data = full_panel,
            cluster = ~art_unit)

cat("\n=== CROSS-TC DiD ===\n")
etable(m5, se.below = TRUE)

# ============================================================
# Grant rate analysis (if data available)
# ============================================================
# Use cross-sectional regression: grant_rate_change ~ alice_shock
if ("grant_rate_change" %in% names(tc36)) {
  grant_cs <- tc36 %>%
    filter(quarter == "2012Q1") %>%  # one obs per art unit
    filter(!is.na(grant_rate_change))

  if (nrow(grant_cs) > 5) {
    m6 <- lm(grant_rate_change ~ alice_shock, data = grant_cs)
    cat("\n=== GRANT RATE CROSS-SECTION ===\n")
    print(summary(m6))

    sd_grant <- sd(grant_cs$grant_rate_change, na.rm = TRUE)
  }
}

# ============================================================
# Save results for tables
# ============================================================
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m5 = m5,
  es1 = es1, es2 = es2, es3 = es3,
  sumstats = sumstats,
  sd_s101 = sd_s101,
  sd_total = sd_total,
  n_au_tc36 = uniqueN(tc36$art_unit),
  n_obs_tc36 = nrow(tc36)
)
if (exists("m6")) {
  results$m6 <- m6
  results$sd_grant <- sd_grant
}
saveRDS(results, "data/results.rds")

cat("\nSaved results to data/results.rds\n")
