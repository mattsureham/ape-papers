# =============================================================================
# 04_robustness.R — Robustness checks for E-Verify DDD
# =============================================================================

source("00_packages.R")

county_panel <- readRDS("../data/county_panel.rds")
border_treatment <- readRDS("../data/border_treatment.rds")
everify_states <- readRDS("../data/everify_states.rds")

# ── 1. Distance decay ────────────────────────────────────────────────────────
cat("=== Distance Decay ===\n")

county_adj_full <- readRDS("../data/county_adjacency.rds")
county_adj_full[, state_fips := as.integer(substr(fips, 1, 2))]
county_adj_full[, neighbor_state_fips := as.integer(substr(neighbor_fips, 1, 2))]
ev_fips <- everify_states$state_fips

# Ring 1: directly adjacent to E-Verify county
ring1 <- county_adj_full[
  !(state_fips %in% ev_fips) & neighbor_state_fips %in% ev_fips,
  unique(fips)
]

# Ring 2: adjacent to ring 1 but not ring 1 and not in E-Verify state
ring1_neighbors <- county_adj_full[fips %in% ring1, unique(neighbor_fips)]
ring2 <- setdiff(ring1_neighbors, ring1)
ring2 <- ring2[as.integer(substr(ring2, 1, 2)) %in%
  setdiff(unique(county_panel$statefip), ev_fips)]

cat("Ring 1 counties:", length(ring1), "\n")
cat("Ring 2 counties:", length(ring2), "\n")

# Assign ring + merge treatment timing from nearest E-Verify border
county_panel[, ring := fifelse(
  county_fips %in% ring1, 1L,
  fifelse(county_fips %in% ring2, 2L, 0L)
)]

# For ring 2, assign same mandate timing as nearest ring 1 county
ring2_links <- county_adj_full[
  fips %in% ring2 & neighbor_fips %in% ring1
]
# Get ring 1 treatment timing
ring1_timing <- unique(county_panel[ring == 1 & border == TRUE,
  .(county_fips, ev_mandate_yq)])
ring2_timing <- merge(
  ring2_links[, .(ring2_fips = fips, ring1_fips = neighbor_fips)],
  ring1_timing,
  by.x = "ring1_fips", by.y = "county_fips"
)[, .(ev_mandate_yq_r2 = min(ev_mandate_yq)), by = ring2_fips]

county_panel <- merge(county_panel, ring2_timing,
  by.x = "county_fips", by.y = "ring2_fips", all.x = TRUE)
county_panel[ring == 2, post_r2 := fifelse(yq >= ev_mandate_yq_r2, 1L, 0L)]
county_panel[is.na(post_r2), post_r2 := 0L]

# Ring 1 effect
m_ring1 <- feols(log_emp ~ post:hispanic + post |
                   county_eth + time_id^hispanic,
                 data = county_panel[ring %in% c(0, 1)],
                 cluster = ~statefip)

# Ring 2 effect
m_ring2 <- feols(log_emp ~ post_r2:hispanic + post_r2 |
                   county_eth + time_id^hispanic,
                 data = county_panel[ring %in% c(0, 2)],
                 cluster = ~statefip)

cat("Ring 1 (adjacent) DDD:\n")
print(coeftable(m_ring1))
cat("\nRing 2 (second ring) DDD:\n")
print(coeftable(m_ring2))

saveRDS(list(ring1 = m_ring1, ring2 = m_ring2), "../data/ring_results.rds")

# ── 2. Pre-period placebo ────────────────────────────────────────────────────
cat("\n=== Pre-Period Placebo ===\n")

# Only pre-2008 data (before ANY E-Verify mandate)
# Assign fake "post" at 2006Q1 for border counties
placebo_data <- county_panel[year <= 2007]
placebo_data[, fake_post := fifelse(border == TRUE & yq >= 2006.0, 1L, 0L)]

m_placebo <- feols(log_emp ~ fake_post:hispanic + fake_post |
                     county_eth + time_id^hispanic,
                   data = placebo_data,
                   cluster = ~statefip)

cat("Placebo DDD (should be insignificant):\n")
print(coeftable(m_placebo))
saveRDS(m_placebo, "../data/placebo_results.rds")

# ── 3. Pre-2020 sample (exclude COVID + late adopters) ───────────────────────
cat("\n=== Pre-2020 Sample ===\n")

m_early <- feols(log_emp ~ post:hispanic + post |
                   county_eth + time_id^hispanic,
                 data = county_panel[year <= 2019],
                 cluster = ~statefip)

cat("Pre-2020 DDD:\n")
print(coeftable(m_early))
saveRDS(m_early, "../data/early_results.rds")

# ── 4. Alternative clustering ────────────────────────────────────────────────
cat("\n=== Alternative Clustering ===\n")

# County-level clustering
m_county_cl <- feols(log_emp ~ post:hispanic + post |
                       county_eth + time_id^hispanic,
                     data = county_panel,
                     cluster = ~county_fips)

# Two-way clustering (state × quarter)
m_twoway <- feols(log_emp ~ post:hispanic + post |
                    county_eth + time_id^hispanic,
                  data = county_panel,
                  cluster = ~statefip + time_id)

cat("County clustering:\n")
print(coeftable(m_county_cl))
cat("\nTwo-way clustering (state + quarter):\n")
print(coeftable(m_twoway))

saveRDS(list(county = m_county_cl, twoway = m_twoway),
        "../data/alt_clustering.rds")

# ── 5. HonestDiD sensitivity (if feasible) ──────────────────────────────────
cat("\n=== HonestDiD Sensitivity ===\n")
tryCatch({
  m_es <- readRDS("../data/event_study.rds")
  betahat <- coef(m_es)
  sigma <- vcov(m_es)

  # Get Hispanic interaction coefficients
  hisp_idx <- grep("^rel_time::.*:hispanic$", names(betahat))
  hisp_names <- names(betahat)[hisp_idx]

  # Split pre and post
  pre_names <- hisp_names[grep("::-[2-8]:", hisp_names)]
  post_names <- hisp_names[grep("::[0-9]", hisp_names)]

  if (length(pre_names) >= 2 && length(post_names) >= 1) {
    all_idx <- match(c(pre_names, post_names), names(betahat))
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = betahat[all_idx],
      sigma = sigma[all_idx, all_idx],
      numPrePeriods = length(pre_names),
      numPostPeriods = length(post_names),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("HonestDiD bounds:\n")
    print(honest_result)
    saveRDS(honest_result, "../data/honest_did.rds")
  }
}, error = function(e) {
  cat("HonestDiD:", e$message, "\n")
})

cat("\nRobustness checks complete.\n")
