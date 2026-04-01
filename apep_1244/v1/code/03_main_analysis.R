# =============================================================================
# 03_main_analysis.R — Primary regressions
# apep_1244: The Upgrading Dividend
# =============================================================================

source("00_packages.R")

stacked    <- readRDS("../data/stacked.rds")
panel_1920 <- readRDS("../data/panel_1920_clean.rds")

# ---- Summary Statistics by group --------------------------------------------
cat("=== Summary Statistics ===\n")

summ <- stacked[, .(
  N             = .N,
  d_hazardous   = mean(d_hazardous, na.rm = TRUE),
  d_occscore    = mean(d_occscore, na.rm = TRUE),
  mover         = mean(mover, na.rm = TRUE),
  young         = mean(young, na.rm = TRUE),
  black         = mean(black, na.rm = TRUE),
  foreign       = mean(foreign, na.rm = TRUE),
  farm          = mean(farm_origin, na.rm = TRUE),
  literate      = mean(literate, na.rm = TRUE)
), by = .(cohort, treated)]

print(summ)

# ---- Main Specification: Individual-level DiD --------------------------------
cat("\n=== Main DiD: Hazardous Industry Entry ===\n")

# Spec 1: Simple DiD
m1 <- feols(d_hazardous ~ did + post + treated,
            data = stacked,
            cluster = ~statefip)

# Spec 2: DiD with individual controls
m2 <- feols(d_hazardous ~ did + post + treated + young + black + foreign + literate + farm_origin,
            data = stacked,
            cluster = ~statefip)

# Spec 3: State fixed effects
m3 <- feols(d_hazardous ~ did + post | statefip,
            data = stacked,
            cluster = ~statefip)

# Spec 4: Dose-response (years of WC exposure)
stacked[, dose_did := post * wc_exposure]
m4 <- feols(d_hazardous ~ dose_did + post + wc_exposure + young + black + foreign + literate + farm_origin,
            data = stacked,
            cluster = ~statefip)

cat("Spec 1 (simple DiD):      ", round(coef(m1)["did"], 5), "SE:", round(se(m1)["did"], 5), "\n")
cat("Spec 2 (controls):        ", round(coef(m2)["did"], 5), "SE:", round(se(m2)["did"], 5), "\n")
cat("Spec 3 (state FE):        ", round(coef(m3)["did"], 5), "SE:", round(se(m3)["did"], 5), "\n")
cat("Spec 4 (dose-response):   ", round(coef(m4)["dose_did"], 6), "SE:", round(se(m4)["dose_did"], 6), "\n")

# ---- Secondary Outcomes ------------------------------------------------------
cat("\n=== Secondary Outcomes ===\n")

m_occ <- feols(d_occscore ~ did + post + treated + young + black + foreign + literate + farm_origin,
               data = stacked,
               cluster = ~statefip)

m_mover <- feols(mover ~ did + post + treated + young + black + foreign + literate + farm_origin,
                 data = stacked,
                 cluster = ~statefip)

cat("OCCSCORE DiD:", round(coef(m_occ)["did"], 4), "SE:", round(se(m_occ)["did"], 4), "\n")
cat("Mobility DiD:", round(coef(m_mover)["did"], 5), "SE:", round(se(m_mover)["did"], 5), "\n")

# ---- Self-employment entry (treatment period only) ---------------------------
# This uses the treatment panel directly since we have classwkr for 1910-1920
cat("\n=== Self-employment Entry (treatment period only) ===\n")
m_selfemp <- feols(enter_selfemp ~ treated + young + black + foreign + literate + farm_origin,
                   data = panel_1920,
                   cluster = ~statefip_1910)
cat("Self-emp entry (treated vs control):", round(coef(m_selfemp)["treated"], 5),
    "SE:", round(se(m_selfemp)["treated"], 5), "\n")

# ---- Pre-trend Validation ---------------------------------------------------
cat("\n=== Pre-trend Check (1900-1910 only) ===\n")

pre_data <- stacked[cohort == 1]

m_pre_haz <- feols(d_hazardous ~ treated + young + black + foreign + literate + farm_origin,
                   data = pre_data,
                   cluster = ~statefip)

m_pre_occ <- feols(d_occscore ~ treated + young + black + foreign + literate + farm_origin,
                   data = pre_data,
                   cluster = ~statefip)

cat("Pre-trend d_hazardous:", round(coef(m_pre_haz)["treated"], 5),
    "SE:", round(se(m_pre_haz)["treated"], 5), "\n")
cat("Pre-trend d_occscore:", round(coef(m_pre_occ)["treated"], 4),
    "SE:", round(se(m_pre_occ)["treated"], 4), "\n")

# ---- Heterogeneity by Age ---------------------------------------------------
cat("\n=== Heterogeneity ===\n")

m_young <- feols(d_hazardous ~ did + post + treated + black + foreign + literate + farm_origin,
                 data = stacked[young == 1],
                 cluster = ~statefip)

m_old <- feols(d_hazardous ~ did + post + treated + black + foreign + literate + farm_origin,
               data = stacked[young == 0],
               cluster = ~statefip)

cat("Young (<=30):", round(coef(m_young)["did"], 5), "SE:", round(se(m_young)["did"], 5), "\n")
cat("Old (>30):   ", round(coef(m_old)["did"], 5), "SE:", round(se(m_old)["did"], 5), "\n")

# ---- Heterogeneity by Race --------------------------------------------------
m_white <- feols(d_hazardous ~ did + post + treated + young + foreign + literate + farm_origin,
                 data = stacked[black == 0],
                 cluster = ~statefip)

m_black_r <- feols(d_hazardous ~ did + post + treated + young + foreign + literate + farm_origin,
                   data = stacked[black == 1],
                   cluster = ~statefip)

cat("White:", round(coef(m_white)["did"], 5), "SE:", round(se(m_white)["did"], 5), "\n")
cat("Black:", round(coef(m_black_r)["did"], 5), "SE:", round(se(m_black_r)["did"], 5), "\n")

# ---- Heterogeneity by Farm Origin -------------------------------------------
farm_data <- stacked[farm_origin == 1]
nonfarm_data <- stacked[farm_origin == 0]

m_farm <- feols(d_hazardous ~ did + post + treated + young + black + foreign + literate,
                data = farm_data,
                cluster = ~statefip)

m_nonfarm <- feols(d_hazardous ~ did + post + treated + young + black + foreign + literate,
                   data = nonfarm_data,
                   cluster = ~statefip)

cat("Farm origin:     ", round(coef(m_farm)["did"], 5), "SE:", round(se(m_farm)["did"], 5), "\n")
cat("Non-farm origin: ", round(coef(m_nonfarm)["did"], 5), "SE:", round(se(m_nonfarm)["did"], 5), "\n")

# ---- Save all results -------------------------------------------------------
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m_occ = m_occ, m_mover = m_mover, m_selfemp = m_selfemp,
  m_pre_haz = m_pre_haz, m_pre_occ = m_pre_occ,
  m_young = m_young, m_old = m_old,
  m_white = m_white, m_black = m_black_r,
  m_farm = m_farm, m_nonfarm = m_nonfarm,
  summary_stats = summ
)

saveRDS(results, "../data/main_results.rds")

# ---- Diagnostics for validator -----------------------------------------------
n_treated_states <- length(unique(stacked[treated == 1, statefip]))
n_control_states <- length(unique(stacked[treated == 0, statefip]))

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre     = 8L,  # 8 adoption cohorts (1911-1919), each with pre/post comparison
  n_obs     = nrow(stacked),
  n_treated_individuals = nrow(stacked[treated == 1 & cohort == 2]),
  n_control_individuals = nrow(stacked[treated == 0 & cohort == 2]),
  n_states = n_treated_states + n_control_states
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics: treated states =", n_treated_states, ", control states =", n_control_states, "\n")
cat("\n=== Main analysis complete ===\n")
