# =============================================================================
# 02_clean_data.R — Construct analysis dataset for E-Verify DDD
# =============================================================================

source("00_packages.R")

qwi_dt <- readRDS("../data/qwi_rh_ns.rds")
county_adj <- readRDS("../data/county_adjacency.rds")
everify_states <- readRDS("../data/everify_states.rds")

# ── 1. Create state FIPS from county FIPS ────────────────────────────────────
qwi_dt[, statefip := as.integer(geography) %/% 1000L]
cat("States in data:", length(unique(qwi_dt$statefip)), "\n")

# ── 2. Classify states as E-Verify mandated or not ───────────────────────────
qwi_dt[, everify_state := statefip %in% everify_states$state_fips]
cat("E-Verify states:", sum(unique(qwi_dt[everify_state == TRUE]$statefip) %in% everify_states$state_fips), "\n")
cat("Non-E-Verify states:", length(unique(qwi_dt[everify_state == FALSE]$statefip)), "\n")

# ── 3. Classify counties as border or interior ───────────────────────────────
# Border county = county in a NON-E-Verify state that is adjacent to
# a county in an E-Verify state

# Add state FIPS to adjacency
county_adj[, state_fips := as.integer(substr(fips, 1, 2))]
county_adj[, neighbor_state_fips := as.integer(substr(neighbor_fips, 1, 2))]

# Find cross-state-border adjacencies where one side is E-Verify
cross_border <- county_adj[
  state_fips != neighbor_state_fips &
  (state_fips %in% everify_states$state_fips | neighbor_state_fips %in% everify_states$state_fips)
]

# Border counties of NON-E-Verify states adjacent to E-Verify states
border_counties_non_ev <- cross_border[
  !(state_fips %in% everify_states$state_fips) &
  neighbor_state_fips %in% everify_states$state_fips,
  .(fips = unique(fips))
]

# Also track which E-Verify state they border (for treatment timing)
border_links <- cross_border[
  !(state_fips %in% everify_states$state_fips) &
  neighbor_state_fips %in% everify_states$state_fips,
  .(county_fips = fips, ev_state_fips = neighbor_state_fips)
]
# Merge to get mandate date for the adjacent E-Verify state
border_links <- merge(border_links,
  everify_states[, .(state_fips, mandate_date, mandate_year, mandate_quarter, mandate_yq)],
  by.x = "ev_state_fips", by.y = "state_fips"
)
# If a county borders multiple E-Verify states, use the earliest mandate
border_treatment <- border_links[, .(
  mandate_date = min(mandate_date),
  mandate_year = min(mandate_year),
  mandate_quarter = mandate_quarter[which.min(mandate_date)],
  mandate_yq = min(mandate_yq)
), by = county_fips]

cat("Border counties in non-E-Verify states:", nrow(border_counties_non_ev), "\n")

# ── 4. Create analysis sample: non-E-Verify states only ─────────────────────
# We study spillovers to untreated states, not the direct effect in treated states
analysis <- qwi_dt[everify_state == FALSE]
cat("Rows in non-E-Verify states:", format(nrow(analysis), big.mark = ","), "\n")

# Classify as border or interior
analysis[, county_fips := sprintf("%05d", as.integer(geography))]
analysis[, border := county_fips %in% border_counties_non_ev$fips]
cat("Border county observations:", format(sum(analysis$border), big.mark = ","), "\n")
cat("Interior county observations:", format(sum(!analysis$border), big.mark = ","), "\n")

# ── 5. Merge treatment timing (when adjacent E-Verify state adopted) ────────
analysis <- merge(analysis,
  border_treatment[, .(county_fips, ev_mandate_yq = mandate_yq,
                       ev_mandate_year = mandate_year, ev_mandate_quarter = mandate_quarter)],
  by = "county_fips", all.x = TRUE
)

# Interior counties have no adjacent E-Verify state — they serve as controls
# For event study, we assign them "never treated"
analysis[is.na(ev_mandate_yq), ev_mandate_yq := Inf]

# Create time variable
analysis[, yq := year + (quarter - 1) / 4]

# Create post indicator (only for border counties)
analysis[, post := fifelse(border & yq >= ev_mandate_yq, 1L, 0L)]

# Create Hispanic indicator
analysis[, hispanic := fifelse(ethnicity == "A2", 1L, 0L)]

# ── 6. Aggregate to county × quarter × ethnicity (across industries) ────────
# Main analysis: total employment across all industries
county_panel <- analysis[industry == "00", .(
  Emp = sum(Emp, na.rm = TRUE),
  EmpEnd = sum(EmpEnd, na.rm = TRUE),
  HirA = sum(HirA, na.rm = TRUE),
  Sep = sum(Sep, na.rm = TRUE),
  EarnS_wtd = weighted.mean(EarnS, EmpS, na.rm = TRUE)
), by = .(county_fips, statefip, year, quarter, yq, ethnicity, hispanic,
          border, post, ev_mandate_yq)]

# Log transform (adding 1 for zeros)
county_panel[, log_emp := log(Emp + 1)]
county_panel[, log_earn := log(EarnS_wtd + 1)]
county_panel[, log_hir := log(HirA + 1)]

# Create county-ethnicity ID for fixed effects
county_panel[, county_eth := paste0(county_fips, "_", ethnicity)]

# Create quarter ID for time fixed effects
county_panel[, time_id := year * 10 + quarter]

cat("\nCounty panel dimensions:", format(nrow(county_panel), big.mark = ","), "rows\n")
cat("Unique counties:", length(unique(county_panel$county_fips)), "\n")
cat("Border counties:", length(unique(county_panel[border == TRUE]$county_fips)), "\n")
cat("Interior counties:", length(unique(county_panel[border == FALSE]$county_fips)), "\n")

# ── 7. Industry-specific panels ──────────────────────────────────────────────
# Construction (NAICS 23), Accommodation/Food (72), Agriculture (11)
# These are high-Hispanic-share industries
ind_panel <- analysis[industry %in% c("23", "72", "11", "31-33", "44-45", "54"), .(
  Emp = sum(Emp, na.rm = TRUE),
  HirA = sum(HirA, na.rm = TRUE)
), by = .(county_fips, statefip, year, quarter, yq, ethnicity, hispanic,
          border, post, ev_mandate_yq, industry)]

ind_panel[, log_emp := log(Emp + 1)]
cat("Industry panel rows:", format(nrow(ind_panel), big.mark = ","), "\n")

# ── 8. Save ──────────────────────────────────────────────────────────────────
saveRDS(county_panel, "../data/county_panel.rds")
saveRDS(ind_panel, "../data/ind_panel.rds")
saveRDS(border_treatment, "../data/border_treatment.rds")

cat("\nCleaning complete.\n")
cat("Summary:\n")
cat("  Counties:", length(unique(county_panel$county_fips)), "\n")
cat("  Border:", length(unique(county_panel[border == TRUE]$county_fips)), "\n")
cat("  Interior:", length(unique(county_panel[border == FALSE]$county_fips)), "\n")
cat("  Year range:", range(county_panel$year), "\n")
cat("  Quarters:", length(unique(county_panel$time_id)), "\n")
