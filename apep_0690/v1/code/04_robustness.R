## 04_robustness.R — Robustness checks and additional specifications
## Paper: apep_0690 — UK Office-to-Residential PD Rights

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

load("regression_results.RData")
cat("Results loaded. Panel:", nrow(panel), "rows\n")

# ============================================================
# 1. First Stage: Does office share predict PD conversions?
# ============================================================
cat("\n=== First Stage: Office Share → PD Conversions ===\n")

# Subset to years with PD data (2015+)
pdr_panel <- panel[!is.na(pdr_office)]
cat("PDR panel:", nrow(pdr_panel), "rows,", uniqueN(pdr_panel$year), "years\n")

m_fs1 <- feols(pdr_office ~ office_share | year,
               data = pdr_panel, cluster = "ons_code")

# office_share is time-invariant, so cannot include LA FE
# Instead, show cross-sectional relationship with year FE only
m_fs2 <- feols(log(pmax(pdr_office, 1)) ~ office_share | year,
               data = pdr_panel, cluster = "ons_code")

# Cross-sectional: cumulative PD by LA
pdr_cumulative <- pdr_panel[, .(total_pdr = sum(pdr_office, na.rm = TRUE),
                                 mean_pdr = mean(pdr_office, na.rm = TRUE)),
                             by = .(ons_code, office_share)]

m_fs_cross <- lm(total_pdr ~ office_share, data = pdr_cumulative)
cat("Cross-sectional first stage:\n")
cat(sprintf("  β = %.1f (SE = %.1f), R² = %.3f\n",
            coef(m_fs_cross)["office_share"],
            summary(m_fs_cross)$coefficients["office_share", "Std. Error"],
            summary(m_fs_cross)$r.squared))

cat("\nFirst stage (panel):\n")
etable(m_fs1, m_fs2, headers = c("Pooled OLS", "LA + Year FE"),
       se.below = TRUE)

# ============================================================
# 2. Composition: PD share of total additions
# ============================================================
cat("\n=== Composition Analysis ===\n")

# New build share vs. conversion share
pdr_panel[, new_build_share := new_build / pmax(net_additions, 1)]
pdr_panel[, pdr_share := pdr_office / pmax(net_additions, 1)]
pdr_panel[, pdr_total_share := pdr_total_residential / pmax(net_additions, 1)]

m_comp1 <- feols(pdr_share ~ office_share | year,
                 data = pdr_panel, cluster = "ons_code")

m_comp2 <- feols(new_build_share ~ office_share | year,
                 data = pdr_panel, cluster = "ons_code")

cat("Composition regressions (pooled OLS with year FE):\n")
etable(m_comp1, m_comp2, headers = c("PDR Office Share", "New Build Share"),
       se.below = TRUE)

# ============================================================
# 3. Quartile Heterogeneity
# ============================================================
cat("\n=== Quartile Heterogeneity ===\n")

# Create quartile dummies
q_breaks <- quantile(panel$office_share, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
panel[, office_q := cut(office_share, breaks = q_breaks,
                         labels = c("Q1", "Q2", "Q3", "Q4"),
                         include.lowest = TRUE)]

# Interact quartiles with post
panel[, q2_post := as.integer(office_q == "Q2") * post]
panel[, q3_post := as.integer(office_q == "Q3") * post]
panel[, q4_post := as.integer(office_q == "Q4") * post]

# Housing supply by quartile
m_q_supply <- feols(additions_pc ~ q2_post + q3_post + q4_post | ons_code + year,
                    data = panel[!is.na(additions_pc)], cluster = "ons_code")

cat("Quartile effects on additions per 1K pop (ref = Q1):\n")
etable(m_q_supply, se.below = TRUE)

# Prices by quartile
if ("log_FlatPrice" %in% names(panel)) {
  m_q_flat <- feols(log_FlatPrice ~ q2_post + q3_post + q4_post | ons_code + year,
                    data = panel[!is.na(FlatPrice) & FlatPrice > 0], cluster = "ons_code")

  m_q_avg <- feols(log_AveragePrice ~ q2_post + q3_post + q4_post | ons_code + year,
                   data = panel[!is.na(AveragePrice) & AveragePrice > 0], cluster = "ons_code")

  cat("\nQuartile effects on prices:\n")
  etable(m_q_avg, m_q_flat, headers = c("Log Avg Price", "Log Flat Price"),
         se.below = TRUE)
}

# ============================================================
# 4. London vs Non-London
# ============================================================
cat("\n=== London vs Non-London ===\n")

panel[, london := as.integer(grepl("^E09", ons_code))]

m_london <- feols(additions_pc ~ office_x_post | ons_code + year,
                  data = panel[london == 1 & !is.na(additions_pc)], cluster = "ons_code")

m_nonlondon <- feols(additions_pc ~ office_x_post | ons_code + year,
                     data = panel[london == 0 & !is.na(additions_pc)], cluster = "ons_code")

cat("London vs non-London:\n")
etable(m_london, m_nonlondon, headers = c("London", "Non-London"),
       se.below = TRUE)

# ============================================================
# 5. Flat vs. Non-Flat Price Gap (composition channel)
# ============================================================
cat("\n=== Flat-House Price Gap ===\n")

if (all(c("FlatPrice", "DetachedPrice") %in% names(panel))) {
  panel[, flat_premium := log(pmax(FlatPrice, 1)) - log(pmax(DetachedPrice, 1))]
  panel[, flat_terraced_gap := log(pmax(FlatPrice, 1)) - log(pmax(TerracedPrice, 1))]

  m_gap1 <- feols(flat_premium ~ office_x_post | ons_code + year,
                  data = panel[!is.na(flat_premium)], cluster = "ons_code")

  m_gap2 <- feols(flat_terraced_gap ~ office_x_post | ons_code + year,
                  data = panel[!is.na(flat_terraced_gap)], cluster = "ons_code")

  cat("Price gap regressions:\n")
  etable(m_gap1, m_gap2,
         headers = c("Flat-Detached Gap", "Flat-Terraced Gap"),
         se.below = TRUE)
}

# ============================================================
# 6. Placebo: Detached house prices (shouldn't be affected by flats)
# ============================================================
cat("\n=== Placebo Tests ===\n")

# New build should NOT respond to office share (it's driven by land availability)
m_placebo_nb <- feols(new_build ~ office_x_post | ons_code + year,
                      data = panel, cluster = "ons_code")

cat("Placebo - new build:\n")
etable(m_placebo_nb, se.below = TRUE)

# ============================================================
# Save robustness results
# ============================================================
save(m_fs1, m_fs2, m_fs_cross, pdr_cumulative,
     m_comp1, m_comp2, m_q_supply, m_placebo_nb, panel,
     file = "robustness_results.RData")

if (exists("m_q_flat")) {
  save(m_q_avg, m_q_flat, m_gap1, m_gap2,
       file = "price_robustness.RData")
}

cat("\nRobustness results saved.\n")
