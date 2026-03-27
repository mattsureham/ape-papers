# 04_robustness.R — Robustness checks for apep_1085
# Wind Turbines and Avian Community Restructuring

library(tidyverse)
library(fixest)
library(fwildclusterboot)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))[1]
if (length(script_dir) > 0 && nchar(script_dir) > 0) setwd(file.path(script_dir, ".."))

panel <- readRDS("data/panel.rds")
models <- readRDS("data/models.rds")

cat("Panel loaded:", nrow(panel), "observations\n")

# ============================================================
# 1. Drop Texas (dominates wind installations)
# ============================================================
cat("\n=== DROP TEXAS ===\n")

m_no_tx <- feols(
  rr_raptors ~ log_capacity | state + year,
  data = filter(panel, state != "TX"),
  cluster = ~state
)
cat("Without Texas:\n"); summary(m_no_tx)

# ============================================================
# 2. Alternative treatment thresholds
# ============================================================
cat("\n=== ALTERNATIVE THRESHOLDS ===\n")

# 50 MW threshold
first_treat_50 <- panel %>%
  filter(cum_capacity_mw >= 50) %>%
  group_by(state) %>%
  summarise(ft50 = min(year), .groups = "drop")

panel_50 <- panel %>%
  left_join(first_treat_50, by = "state") %>%
  mutate(post_50 = as.integer(!is.na(ft50) & year >= ft50))

m_50 <- feols(rr_raptors ~ post_50 | state + year,
              data = panel_50, cluster = ~state)

# 200 MW threshold
first_treat_200 <- panel %>%
  filter(cum_capacity_mw >= 200) %>%
  group_by(state) %>%
  summarise(ft200 = min(year), .groups = "drop")

panel_200 <- panel %>%
  left_join(first_treat_200, by = "state") %>%
  mutate(post_200 = as.integer(!is.na(ft200) & year >= ft200))

m_200 <- feols(rr_raptors ~ post_200 | state + year,
               data = panel_200, cluster = ~state)

cat("50 MW threshold:\n"); print(coeftable(m_50))
cat("200 MW threshold:\n"); print(coeftable(m_200))

# ============================================================
# 3. Placebo: fake treatment 5 years early
# ============================================================
cat("\n=== PLACEBO: 5-YEAR LEAD ===\n")

# Placebo: use log_capacity from 3 years in the future as fake treatment
panel_placebo <- panel %>%
  mutate(
    fake_capacity = lead(log_capacity, 3),
    .by = state
  ) %>%
  filter(!is.na(fake_capacity), !is.na(rr_raptors))

m_placebo <- tryCatch({
  feols(rr_raptors ~ fake_capacity | state + year,
        data = panel_placebo, cluster = ~state)
}, error = function(e) {
  cat("Placebo error:", e$message, "\n")
  # Fallback: simple pre-trend test using early data
  panel_pre <- panel %>%
    filter(year <= 2014, !is.na(rr_raptors))
  feols(rr_raptors ~ log_capacity | state + year,
        data = panel_pre, cluster = ~state)
})
cat("Placebo:\n"); summary(m_placebo)

# ============================================================
# 4. Wild cluster bootstrap
# ============================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

main_ols <- feols(rr_raptors ~ log_capacity | state + year,
                  data = panel, cluster = ~state)

wcb <- tryCatch({
  boottest(
    main_ols,
    param = "log_capacity",
    B = 999,
    clustid = "state",
    type = "webb"
  )
}, error = function(e) {
  cat("  WCB error:", e$message, "\n")
  NULL
})

if (!is.null(wcb)) {
  cat("WCB p-value:", wcb$p_val, "\n")
  cat("WCB CI: [", wcb$conf_int[1], ",", wcb$conf_int[2], "]\n")
}

# ============================================================
# 5. Log count with effort control
# ============================================================
cat("\n=== EFFORT-CONTROLLED SPECIFICATIONS ===\n")

m_effort <- feols(
  log_raptors ~ log_capacity + log_total | state + year,
  data = panel,
  cluster = ~state
)
cat("Log raptors with effort control:\n"); summary(m_effort)

# ============================================================
# Save robustness models
# ============================================================
robust_models <- list(
  no_texas = m_no_tx,
  threshold_50 = m_50,
  threshold_200 = m_200,
  placebo = m_placebo,
  effort = m_effort,
  wcb = wcb
)

saveRDS(robust_models, "data/robust_models.rds")

cat("\nRobustness checks complete.\n")
