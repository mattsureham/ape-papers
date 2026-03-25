# 03_main_analysis.R — Triple-diff and main regressions
# apep_0842: The Safe Country Lottery

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

cat("=== Panel summary ===\n")
cat(sprintf("  N = %d observations\n", nrow(panel)))
cat(sprintf("  Treated cells: %d\n", sum(panel$sco == 1)))
cat(sprintf("  Unique destinations: %d\n", n_distinct(panel$destination)))
cat(sprintf("  Unique origins: %d\n", n_distinct(panel$origin)))

# ============================================================
# 1. Triple-Difference: Recognition Rate
# ============================================================

cat("\n=== Model 1: Baseline (pair + year FE) ===\n")
m1 <- feols(recog_rate ~ sco | pair_id + year,
            data = panel, cluster = ~destination)
summary(m1)

cat("\n=== Model 2: Triple-diff (pair + origin-year + destination-year FE) ===\n")
m2 <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
            data = panel, cluster = ~destination)
summary(m2)

cat("\n=== Model 3: Triple-diff weighted by total decisions ===\n")
m3 <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
            data = panel, cluster = ~destination,
            weights = ~total_decisions)
summary(m3)

# ============================================================
# 2. Deterrence channel: Applications
# ============================================================

cat("\n=== Model 4: Applications (log) ===\n")
panel_apps <- panel %>% filter(!is.na(applications) & applications > 0)

m4 <- feols(log_apps ~ sco | pair_id + origin_year + dest_year,
            data = panel_apps, cluster = ~destination)
summary(m4)

# ============================================================
# 3. Diversion channel: Do applications shift to neighbors?
# ============================================================

cat("\n=== Model 5: Neighbor-destination spillover ===\n")
# For each origin-destination-year cell where sco==0, compute the share of
# OTHER destinations that designate this origin as safe.
# This is a leave-own-out measure: excludes destination j from the share.
panel_spill <- panel %>%
  filter(!is.na(applications) & applications > 0) %>%
  group_by(origin, year) %>%
  mutate(
    total_sco = sum(sco, na.rm = TRUE),
    n_dests = n(),
    # Leave-own-out share: (total SCO in other destinations) / (n other destinations)
    share_sco_others = (total_sco - sco) / (n_dests - 1)
  ) %>%
  ungroup() %>%
  filter(sco == 0)  # Only look at non-designated cells

# Use pair + dest_year FE (not origin_year, which absorbs the variation)
m5 <- feols(log_apps ~ share_sco_others | pair_id + dest_year,
            data = panel_spill, cluster = ~destination)
summary(m5)

# ============================================================
# 4. Event Study — Pre-trends validation
# ============================================================

cat("\n=== Event Study ===\n")

# Create event time relative to designation year
sco_timing <- panel %>%
  filter(sco == 1 | !is.na(recog_rate)) %>%
  left_join(
    readRDS("../data/sco_events.rds") %>%
      select(destination, origin, year_designated) %>%
      distinct(),
    by = c("origin", "destination")
  ) %>%
  filter(!is.na(year_designated)) %>%
  mutate(
    event_time = year - year_designated,
    event_time_binned = case_when(
      event_time <= -4 ~ -4L,
      event_time >= 5 ~ 5L,
      TRUE ~ as.integer(event_time)
    )
  ) %>%
  # Reference period: t = -1
  mutate(event_time_binned = relevel(factor(event_time_binned), ref = "-1"))

m_es <- feols(recog_rate ~ i(event_time_binned) | pair_id + dest_year,
              data = sco_timing, cluster = ~destination)
summary(m_es)

# ============================================================
# 5. Heterogeneity: Balkans vs. other origins
# ============================================================

cat("\n=== Heterogeneity: Balkans vs. Others ===\n")
balkan_origins <- c("AL", "XK", "RS", "BA", "ME", "MK")

panel <- panel %>%
  mutate(balkan = ifelse(origin %in% balkan_origins, 1L, 0L))

m6_balkan <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
                   data = filter(panel, balkan == 1), cluster = ~destination)
m6_other <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
                  data = filter(panel, balkan == 0), cluster = ~destination)

cat("Balkans:\n")
summary(m6_balkan)
cat("\nOther origins:\n")
summary(m6_other)

# ============================================================
# 6. Heterogeneity: High vs. low baseline recognition
# ============================================================

cat("\n=== Heterogeneity: Large vs. Small destination countries ===\n")

# Split by total asylum volume: DE, FR, AT, IT, SE, NL = large receivers
large_dests <- c("DE", "FR", "AT", "IT", "SE", "NL")
panel <- panel %>%
  mutate(large_dest = ifelse(destination %in% large_dests, 1L, 0L))

m7_large <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
                  data = filter(panel, large_dest == 1), cluster = ~destination)
m7_small <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
                  data = filter(panel, large_dest == 0), cluster = ~destination)

cat("Large destination countries:\n")
summary(m7_large)
cat("\nSmaller destination countries:\n")
summary(m7_small)

# ============================================================
# 7. Decision-type decomposition: Geneva vs. subsidiary/humanitarian
# ============================================================

cat("\n=== Decision-type decomposition ===\n")

# Geneva Convention recognition rate
panel_geneva <- panel %>% filter(!is.na(geneva_rate))
if (nrow(panel_geneva) > 100) {
  m_geneva <- feols(geneva_rate ~ sco | pair_id + origin_year + dest_year,
                    data = panel_geneva, cluster = ~destination)
  cat("Geneva Convention rate:\n")
  summary(m_geneva)
} else {
  m_geneva <- NULL
  cat("  Insufficient data for Geneva rate decomposition\n")
}

# Subsidiary/humanitarian protection rate
panel_sub <- panel %>% filter(!is.na(subsidiary_rate))
if (nrow(panel_sub) > 100) {
  m_subsidiary <- feols(subsidiary_rate ~ sco | pair_id + origin_year + dest_year,
                        data = panel_sub, cluster = ~destination)
  cat("Subsidiary/humanitarian rate:\n")
  summary(m_subsidiary)
} else {
  m_subsidiary <- NULL
  cat("  Insufficient data for subsidiary rate decomposition\n")
}

# ============================================================
# Save results
# ============================================================

results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  m_es = m_es,
  m6_balkan = m6_balkan, m6_other = m6_other,
  m7_large = m7_large, m7_small = m7_small,
  m_geneva = m_geneva, m_subsidiary = m_subsidiary
)
saveRDS(results, "../data/main_results.rds")

# Write diagnostics
n_treated_pairs <- panel %>% filter(sco == 1) %>% pull(pair_id) %>% n_distinct()
n_pre <- sco_timing %>% filter(event_time < 0) %>% pull(year) %>% n_distinct()

diagnostics <- list(
  n_treated = n_treated_pairs,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_destinations = n_distinct(panel$destination),
  n_origins = n_distinct(panel$origin),
  n_pairs = n_distinct(panel$pair_id),
  beta_main = coef(m2)["sco"],
  se_main = se(m2)["sco"],
  sd_y = sd(panel$recog_rate, na.rm = TRUE)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Results and diagnostics saved ===\n")
cat(sprintf("  Main effect (β): %.4f (SE: %.4f)\n", coef(m2)["sco"], se(m2)["sco"]))
cat(sprintf("  SD(Y): %.4f\n", sd(panel$recog_rate, na.rm = TRUE)))
cat(sprintf("  SDE: %.4f\n", coef(m2)["sco"] / sd(panel$recog_rate, na.rm = TRUE)))

# Save panel for robustness
saveRDS(panel, "../data/analysis_panel_final.rds")
saveRDS(sco_timing, "../data/event_study_panel.rds")
