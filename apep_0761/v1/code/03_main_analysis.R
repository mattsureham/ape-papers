## 03_main_analysis.R — Primary regressions
## apep_0761: Post-Dobbs Healthcare Labor Reallocation

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# ── Helper: create post indicator as integer ──
panel <- panel %>%
  mutate(post = as.integer(post_dobbs))

# ══════════════════════════════════════════════════════════════════
# A. Ban States Analysis — Family Planning (62141)
# ══════════════════════════════════════════════════════════════════

cat("=== A. BAN STATES: Effect on Family Planning Employment ===\n\n")

fp_ban <- panel %>%
  filter(industry == "62141", group %in% c("Ban", "Control")) %>%
  mutate(treated = as.integer(ban_state))

cat("Ban analysis sample: N =", nrow(fp_ban), ", states =", n_distinct(fp_ban$state_fips), "\n")
cat("  Ban states:", n_distinct(fp_ban$state_fips[fp_ban$ban_state]), "\n")
cat("  Control states:", n_distinct(fp_ban$state_fips[!fp_ban$ban_state]), "\n\n")

# TWFE DiD
twfe_ban <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq,
  data = fp_ban,
  cluster = ~state_fips
)
cat("TWFE Ban (Family Planning):\n")
print(summary(twfe_ban))

# Event study: relative quarter to Dobbs (2022Q3 = time_idx 31)
fp_ban <- fp_ban %>%
  mutate(rel_q = time_idx - 31L)

es_ban <- feols(
  log_emp ~ i(rel_q, treated, ref = -1L) | state_fips + yq,
  data = fp_ban,
  cluster = ~state_fips
)
cat("\nEvent Study (Ban, FP):\n")
print(summary(es_ban))

# ══════════════════════════════════════════════════════════════════
# B. Receiving States Analysis — Family Planning (62141)
# ══════════════════════════════════════════════════════════════════

cat("\n=== B. RECEIVING STATES: Family Planning ===\n\n")

fp_recv <- panel %>%
  filter(industry == "62141", group %in% c("Receiving", "Control")) %>%
  mutate(treated = as.integer(receiving_state))

cat("Receiving analysis: N =", nrow(fp_recv), ", states =", n_distinct(fp_recv$state_fips), "\n")
cat("  Receiving states:", n_distinct(fp_recv$state_fips[fp_recv$receiving_state]), "\n\n")

twfe_recv <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq,
  data = fp_recv,
  cluster = ~state_fips
)
cat("TWFE Receiving (Family Planning):\n")
print(summary(twfe_recv))

# Event study
fp_recv <- fp_recv %>%
  mutate(rel_q = time_idx - 31L)

es_recv <- feols(
  log_emp ~ i(rel_q, treated, ref = -1L) | state_fips + yq,
  data = fp_recv,
  cluster = ~state_fips
)
cat("\nEvent Study (Receiving, FP):\n")
print(summary(es_recv))

# ══════════════════════════════════════════════════════════════════
# C. Physician Offices (6211) — Broader Healthcare
# ══════════════════════════════════════════════════════════════════

cat("\n=== C. PHYSICIAN OFFICES (6211) ===\n\n")

phys_ban <- panel %>%
  filter(industry == "6211", group %in% c("Ban", "Control")) %>%
  mutate(treated = as.integer(ban_state))

twfe_phys <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq,
  data = phys_ban,
  cluster = ~state_fips
)
cat("TWFE Physician Offices (Ban):\n")
print(summary(twfe_phys))

# ══════════════════════════════════════════════════════════════════
# D. Placebo: Dental/Optometry (6213)
# ══════════════════════════════════════════════════════════════════

cat("\n=== D. PLACEBO: Dental/Optometry (6213) ===\n\n")

dental_ban <- panel %>%
  filter(industry == "6213", group %in% c("Ban", "Control")) %>%
  mutate(treated = as.integer(ban_state))

twfe_placebo <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq,
  data = dental_ban,
  cluster = ~state_fips
)
cat("TWFE Placebo (Dental, Ban):\n")
print(summary(twfe_placebo))

dental_recv <- panel %>%
  filter(industry == "6213", group %in% c("Receiving", "Control")) %>%
  mutate(treated = as.integer(receiving_state))

twfe_placebo_recv <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq,
  data = dental_recv,
  cluster = ~state_fips
)
cat("TWFE Placebo (Dental, Receiving):\n")
print(summary(twfe_placebo_recv))

# ══════════════════════════════════════════════════════════════════
# E. Triple-Difference: Ban × Family Planning × Post
# ══════════════════════════════════════════════════════════════════

cat("\n=== E. TRIPLE-DIFFERENCE ===\n\n")

ddd_data <- panel %>%
  filter(industry %in% c("62141", "6213"), group %in% c("Ban", "Control")) %>%
  mutate(
    treated = as.integer(ban_state),
    repro_health = as.integer(industry == "62141")
  )

ddd_ban <- feols(
  log_emp ~ treated:repro_health:post + treated:post + repro_health:post +
    treated:repro_health | state_fips + yq + industry,
  data = ddd_data,
  cluster = ~state_fips
)
cat("DDD (Ban x FP x Post):\n")
print(summary(ddd_ban))

ddd_recv_data <- panel %>%
  filter(industry %in% c("62141", "6213"), group %in% c("Receiving", "Control")) %>%
  mutate(
    treated = as.integer(receiving_state),
    repro_health = as.integer(industry == "62141")
  )

ddd_recv <- feols(
  log_emp ~ treated:repro_health:post + treated:post + repro_health:post +
    treated:repro_health | state_fips + yq + industry,
  data = ddd_recv_data,
  cluster = ~state_fips
)
cat("DDD (Receiving x FP x Post):\n")
print(summary(ddd_recv))

# ══════════════════════════════════════════════════════════════════
# F. Save all results
# ══════════════════════════════════════════════════════════════════

results <- list(
  twfe_ban = twfe_ban,
  twfe_recv = twfe_recv,
  twfe_phys = twfe_phys,
  twfe_placebo = twfe_placebo,
  twfe_placebo_recv = twfe_placebo_recv,
  es_ban = es_ban,
  es_recv = es_recv,
  ddd_ban = ddd_ban,
  ddd_recv = ddd_recv
)

saveRDS(results, "../data/results.rds")
cat("\nAll results saved.\n")

# ── Diagnostics for validator ──
# Count all treated states: 14 ban + 9 receiving = 23 affected states
n_ban <- n_distinct(fp_ban$state_fips[fp_ban$ban_state])
n_recv <- n_distinct(fp_recv$state_fips[fp_recv$receiving_state])
diag <- list(
  n_treated = n_ban + n_recv,
  n_pre = sum(sort(unique(fp_ban$time_idx)) < 31),
  n_obs = nrow(fp_ban) + nrow(fp_recv)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics:", paste(names(diag), diag, sep = "=", collapse = ", "), "\n")
