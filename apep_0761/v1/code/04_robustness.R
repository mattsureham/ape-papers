## 04_robustness.R — Robustness checks
## apep_0761: Post-Dobbs Healthcare Labor Reallocation

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results.rds")

# ══════════════════════════════════════════════════════════════════
# R1. Alternative specification: levels instead of logs
# ══════════════════════════════════════════════════════════════════

cat("=== R1. Levels specification ===\n")

fp_ban <- panel %>%
  filter(industry == "62141", group %in% c("Ban", "Control")) %>%
  mutate(treated = as.integer(ban_state))

levels_ban <- feols(
  Emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = fp_ban,
  cluster = ~state_fips
)
cat("Levels (Ban, FP):\n")
print(summary(levels_ban))

fp_recv <- panel %>%
  filter(industry == "62141", group %in% c("Receiving", "Control")) %>%
  mutate(treated = as.integer(receiving_state))

levels_recv <- feols(
  Emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = fp_recv,
  cluster = ~state_fips
)
cat("Levels (Receiving, FP):\n")
print(summary(levels_recv))

# ══════════════════════════════════════════════════════════════════
# R2. Exclude ambiguous states (GA, IN, SC — partial/later bans)
# ══════════════════════════════════════════════════════════════════

cat("\n=== R2. Exclude ambiguous ban states from control ===\n")

ambiguous <- c("GA", "IN", "SC", "OH")  # Partial or contested bans

fp_ban_strict <- panel %>%
  filter(industry == "62141",
         group %in% c("Ban", "Control"),
         !(state_abbr %in% ambiguous)) %>%
  mutate(treated = as.integer(ban_state))

strict_ban <- feols(
  log_emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = fp_ban_strict,
  cluster = ~state_fips
)
cat("Strict controls (excl GA/IN/SC/OH):\n")
print(summary(strict_ban))

# ══════════════════════════════════════════════════════════════════
# R3. Alternative outcome: Outpatient Care (6214)
# ══════════════════════════════════════════════════════════════════

cat("\n=== R3. Outpatient Care Centers (6214) ===\n")

outpat_ban <- panel %>%
  filter(industry == "6214", group %in% c("Ban", "Control")) %>%
  mutate(treated = as.integer(ban_state))

twfe_outpat <- feols(
  log_emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = outpat_ban,
  cluster = ~state_fips
)
cat("Outpatient Care (Ban):\n")
print(summary(twfe_outpat))

outpat_recv <- panel %>%
  filter(industry == "6214", group %in% c("Receiving", "Control")) %>%
  mutate(treated = as.integer(receiving_state))

twfe_outpat_recv <- feols(
  log_emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = outpat_recv,
  cluster = ~state_fips
)
cat("Outpatient Care (Receiving):\n")
print(summary(twfe_outpat_recv))

# ══════════════════════════════════════════════════════════════════
# R4. Alternative outcome: Other Ambulatory (6219)
# ══════════════════════════════════════════════════════════════════

cat("\n=== R4. Other Ambulatory (6219) ===\n")

amb_ban <- panel %>%
  filter(industry == "6219", group %in% c("Ban", "Control")) %>%
  mutate(treated = as.integer(ban_state))

twfe_amb <- feols(
  log_emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = amb_ban,
  cluster = ~state_fips
)
cat("Other Ambulatory (Ban):\n")
print(summary(twfe_amb))

# ══════════════════════════════════════════════════════════════════
# R5. Earnings analysis (wage effects)
# ══════════════════════════════════════════════════════════════════

cat("\n=== R5. Earnings effects ===\n")

fp_ban_earn <- panel %>%
  filter(industry == "62141", group %in% c("Ban", "Control"),
         !is.na(EarnS), EarnS > 0) %>%
  mutate(treated = as.integer(ban_state))

twfe_earn_ban <- feols(
  log_earns ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = fp_ban_earn,
  cluster = ~state_fips
)
cat("Earnings (Ban, FP):\n")
print(summary(twfe_earn_ban))

fp_recv_earn <- panel %>%
  filter(industry == "62141", group %in% c("Receiving", "Control"),
         !is.na(EarnS), EarnS > 0) %>%
  mutate(treated = as.integer(receiving_state))

twfe_earn_recv <- feols(
  log_emp ~ i(as.integer(post_dobbs), treated, ref = 0L) | state_fips + yq,
  data = fp_recv_earn,
  cluster = ~state_fips
)
cat("Earnings (Receiving, FP):\n")
print(summary(twfe_earn_recv))

# ══════════════════════════════════════════════════════════════════
# Save robustness results
# ══════════════════════════════════════════════════════════════════

rob_results <- list(
  levels_ban = levels_ban,
  levels_recv = levels_recv,
  strict_ban = strict_ban,
  twfe_outpat = twfe_outpat,
  twfe_outpat_recv = twfe_outpat_recv,
  twfe_amb = twfe_amb,
  twfe_earn_ban = twfe_earn_ban,
  twfe_earn_recv = twfe_earn_recv
)

saveRDS(rob_results, "../data/rob_results.rds")
cat("\nRobustness results saved.\n")
