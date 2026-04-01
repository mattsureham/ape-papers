# =============================================================================
# 04_robustness.R — Robustness checks
# apep_1244: The Upgrading Dividend
# =============================================================================

source("00_packages.R")

stacked    <- readRDS("../data/stacked.rds")
panel_1920 <- readRDS("../data/panel_1920_clean.rds")
results    <- readRDS("../data/main_results.rds")

# ---- Create state-cohort collapsed dataset for memory efficiency ------------
cat("Collapsing to state-cohort cells...\n")
state_cells <- stacked[, .(
  d_hazardous = mean(d_hazardous, na.rm = TRUE),
  d_occscore  = mean(d_occscore, na.rm = TRUE),
  mover       = mean(mover, na.rm = TRUE),
  young       = mean(young, na.rm = TRUE),
  black       = mean(black, na.rm = TRUE),
  foreign     = mean(foreign, na.rm = TRUE),
  literate    = mean(literate, na.rm = TRUE),
  farm_origin = mean(farm_origin, na.rm = TRUE),
  n           = .N
), by = .(statefip, cohort, treated, wc_year, post, did)]

cat("  State-cohort cells:", nrow(state_cells), "\n")

# Free individual-level data for robustness checks
rm(stacked); gc()

# ---- Robustness 1: Southern states only -------------------------------------
cat("\n=== Robustness 1: Southern states only ===\n")
southern_fips <- c(1L, 5L, 10L, 12L, 13L, 21L, 22L, 28L, 37L, 45L, 47L, 48L, 51L)

m_south <- feols(d_hazardous ~ did + post + treated + young + black + foreign + literate + farm_origin,
                 data = state_cells[statefip %in% southern_fips],
                 weights = ~n,
                 cluster = ~statefip)
cat("Southern only:", round(coef(m_south)["did"], 5), "SE:", round(se(m_south)["did"], 5), "\n")

# ---- Robustness 2: Exclude early adopters (1911) ----------------------------
cat("\n=== Robustness 2: Exclude 1911 adopters ===\n")
m_no1911 <- feols(d_hazardous ~ did + post + treated + young + black + foreign + literate + farm_origin,
                  data = state_cells[wc_year != 1911 | wc_year == 0],
                  weights = ~n,
                  cluster = ~statefip)
cat("Excl. 1911:", round(coef(m_no1911)["did"], 5), "SE:", round(se(m_no1911)["did"], 5), "\n")

# ---- Robustness 3: Late adopters (1915+) vs never-treated -------------------
cat("\n=== Robustness 3: Late adopters vs. never-treated ===\n")
m_late <- feols(d_hazardous ~ did + post + treated + young + black + foreign + literate + farm_origin,
                data = state_cells[wc_year >= 1915 | wc_year == 0],
                weights = ~n,
                cluster = ~statefip)
cat("Late adopters:", round(coef(m_late)["did"], 5), "SE:", round(se(m_late)["did"], 5), "\n")

# ---- Robustness 4: Mining entry (treatment period only) ---------------------
cat("\n=== Robustness 4: Mining entry (most dangerous) ===\n")
panel_1920[, `:=`(
  mining_1910 = as.integer(ind1950_1910 >= 206 & ind1950_1910 <= 299),
  mining_1920 = as.integer(ind1950_1920 >= 206 & ind1950_1920 <= 299)
)]
panel_1920[, d_mining := mining_1920 - mining_1910]

m_mining <- feols(d_mining ~ treated + young + black + foreign + literate + farm_origin,
                  data = panel_1920,
                  cluster = ~statefip_1910)
cat("Mining entry:", round(coef(m_mining)["treated"], 5), "SE:", round(se(m_mining)["treated"], 5), "\n")

# ---- Robustness 5: Leave-one-out (control states) ---------------------------
cat("\n=== Robustness 5: Leave-one-out (control states) ===\n")
control_states <- unique(state_cells[treated == 0, statefip])
loo_coefs <- numeric(length(control_states))

for (i in seq_along(control_states)) {
  m_loo <- feols(d_hazardous ~ did + post + treated,
                 data = state_cells[statefip != control_states[i]],
                 weights = ~n,
                 cluster = ~statefip)
  loo_coefs[i] <- coef(m_loo)["did"]
}
names(loo_coefs) <- as.character(control_states)

cat("LOO (dropping each control state):\n")
for (nm in names(loo_coefs)) cat("  Drop state", nm, ":", round(loo_coefs[nm], 5), "\n")
cat("  Range: [", round(min(loo_coefs), 5), ",", round(max(loo_coefs), 5), "]\n")

# ---- Robustness 6: Non-movers only (state-level) ---------------------------
cat("\n=== Robustness 6: Non-movers only ===\n")
stacked <- readRDS("../data/stacked.rds")
nonmover_cells <- stacked[mover == 0, .(
  d_hazardous = mean(d_hazardous, na.rm = TRUE),
  n = .N
), by = .(statefip, cohort, treated, post, did)]
rm(stacked); gc()

m_nonmover <- feols(d_hazardous ~ did + post + treated,
                    data = nonmover_cells,
                    weights = ~n,
                    cluster = ~statefip)
cat("Non-movers:", round(coef(m_nonmover)["did"], 5), "SE:", round(se(m_nonmover)["did"], 5), "\n")

# ---- Save -------------------------------------------------------------------
rob_results <- list(
  m_south = m_south,
  m_no1911 = m_no1911,
  m_late = m_late,
  m_mining = m_mining,
  m_nonmover = m_nonmover,
  loo_coefs = loo_coefs
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
