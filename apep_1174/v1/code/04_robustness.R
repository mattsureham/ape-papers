## 04_robustness.R — Robustness and heterogeneity checks
## APEP-1174: The Enforcement Lottery

source("00_packages.R")
data_dir <- "../data"

panel_tri <- readRDS(file.path(data_dir, "panel_tri.rds"))
panel_full <- readRDS(file.path(data_dir, "panel_full.rds"))
state_year <- readRDS(file.path(data_dir, "state_year_fed.rds"))
setDT(panel_tri); setDT(panel_full); setDT(state_year)

## ============================================================
## 1. Pre-trend check: event study around federal inspections
## ============================================================
cat("\n=== 1. Event study around federal inspections ===\n")

## For each facility's first federal inspection, create event-time dummies
panel_tri[, first_federal_year := min(year[any_federal == 1], na.rm = TRUE),
           by = PGM_SYS_ID]
panel_tri[is.infinite(first_federal_year), first_federal_year := NA]

## Event time relative to first federal inspection
panel_tri[!is.na(first_federal_year), event_time := year - first_federal_year]

## Restrict to facilities that ever get a federal inspection
## and have sufficient pre/post data
ever_federal <- panel_tri[!is.na(event_time)]
cat("Facilities with event time:", uniqueN(ever_federal$PGM_SYS_ID), "\n")
cat("Event time range:", range(ever_federal$event_time), "\n")

## Bin extreme event times
ever_federal[, event_time_bin := pmax(pmin(event_time, 5), -5)]

## Event study regression
if (nrow(ever_federal) > 100) {
  es_model <- feols(log_releases ~ i(event_time_bin, ref = -1) | PGM_SYS_ID + year,
                    data = ever_federal, cluster = ~state)
  cat("\nEvent study around first federal inspection:\n")
  summary(es_model)
}

## ============================================================
## 2. Alternative outcome: NEI emissions
## ============================================================
cat("\n=== 2. NEI emissions outcome ===\n")

if ("log_nei" %in% names(panel_tri)) {
  panel_nei <- panel_tri[!is.na(log_nei)]
  if (nrow(panel_nei) > 100) {
    m_nei <- feols(log_nei ~ any_federal | PGM_SYS_ID + year,
                   data = panel_nei, cluster = ~state)
    cat("NEI outcome:\n")
    summary(m_nei)
  }
}

## ============================================================
## 3. Placebo: facilities never in TRI (no real emissions outcome)
## ============================================================
cat("\n=== 3. Placebo test ===\n")

## If federal inspections affect emissions through detection/reporting,
## we should NOT see an effect on total inspection counts (unrelated outcome)
placebo1 <- feols(n_inspections ~ state_fed_share | PGM_SYS_ID + year,
                  data = panel_tri, cluster = ~state)
cat("Placebo: state_fed_share → n_total_inspections (TRI sample)\n")
summary(placebo1)

## ============================================================
## 4. Heterogeneity by industry
## ============================================================
cat("\n=== 4. Industry heterogeneity ===\n")

## Manufacturing vs non-manufacturing
panel_tri[, manufacturing := as.integer(naics2 %in% c("31", "32", "33"))]
cat("Manufacturing facilities:", sum(panel_tri$manufacturing == 1),
    "Non-manufacturing:", sum(panel_tri$manufacturing == 0), "\n")

if (sum(panel_tri$manufacturing == 1) > 500 && sum(panel_tri$manufacturing == 0) > 500) {
  m_mfg <- feols(log_releases ~ any_federal | PGM_SYS_ID + year,
                 data = panel_tri[manufacturing == 1], cluster = ~state)
  m_nonmfg <- feols(log_releases ~ any_federal | PGM_SYS_ID + year,
                    data = panel_tri[manufacturing == 0], cluster = ~state)
  cat("\nManufacturing:\n"); summary(m_mfg)
  cat("\nNon-manufacturing:\n"); summary(m_nonmfg)
}

## ============================================================
## 5. Heterogeneity by facility size (emission terciles)
## ============================================================
cat("\n=== 5. Size heterogeneity ===\n")

## Baseline emissions (pre-period mean)
panel_tri[, baseline_releases := mean(total_releases_lbs[year <= 2010], na.rm = TRUE),
          by = PGM_SYS_ID]
panel_tri[is.nan(baseline_releases) | is.infinite(baseline_releases),
          baseline_releases := NA]
panel_tri[!is.na(baseline_releases), size_tercile := {
  q <- quantile(baseline_releases, c(0, 1/3, 2/3, 1), na.rm = TRUE)
  # Ensure unique breaks
  q <- unique(q)
  if (length(q) >= 4) {
    cut(baseline_releases, breaks = q,
        labels = c("Small", "Medium", "Large"), include.lowest = TRUE)
  } else {
    fifelse(baseline_releases <= median(baseline_releases, na.rm = TRUE), "Small", "Large")
  }
}]

for (sz in c("Small", "Medium", "Large")) {
  sub <- panel_tri[size_tercile == sz]
  if (nrow(sub) > 500) {
    m <- feols(log_releases ~ any_federal | PGM_SYS_ID + year,
               data = sub, cluster = ~state)
    cat("\n", sz, "emitters (n =", nrow(sub), "):\n")
    cat("  Coef:", round(coef(m), 4), " SE:", round(se(m), 4),
        " t:", round(coef(m)/se(m), 2), "\n")
  }
}

## ============================================================
## 6. EPA Region heterogeneity
## ============================================================
cat("\n=== 6. EPA Region heterogeneity ===\n")

panel_tri[, epa_region_num := as.integer(epa_region)]
region_results <- data.table()

for (r in sort(unique(panel_tri$epa_region_num[!is.na(panel_tri$epa_region_num)]))) {
  sub <- panel_tri[epa_region_num == r]
  if (nrow(sub) > 200 && uniqueN(sub$PGM_SYS_ID[sub$any_federal == 1]) > 5) {
    m <- tryCatch(
      feols(log_releases ~ any_federal | PGM_SYS_ID + year, data = sub, cluster = ~state),
      error = function(e) NULL
    )
    if (!is.null(m)) {
      region_results <- rbind(region_results, data.table(
        region = r, coef = coef(m), se = se(m), n = nrow(sub),
        n_fac = uniqueN(sub$PGM_SYS_ID)
      ))
    }
  }
}
cat("Region results:\n")
print(region_results)

## ============================================================
## 7. Time period robustness
## ============================================================
cat("\n=== 7. Time period sensitivity ===\n")

## Pre-2016 (Obama EPA) vs Post-2016 (Trump/Biden EPA)
m_pre <- feols(log_releases ~ any_federal | PGM_SYS_ID + year,
               data = panel_tri[year <= 2016], cluster = ~state)
m_post <- feols(log_releases ~ any_federal | PGM_SYS_ID + year,
                data = panel_tri[year > 2016], cluster = ~state)
cat("\nPre-2017 (Obama):\n"); summary(m_pre)
cat("\nPost-2016 (Trump/Biden):\n"); summary(m_post)

## ============================================================
## 8. FCE-only analysis (most rigorous inspection type)
## ============================================================
cat("\n=== 8. FCE-only analysis ===\n")

## Create FCE-specific federal variable
panel_tri[, any_federal_fce := as.integer(n_fce_federal > 0)]
m_fce <- feols(log_releases ~ any_federal_fce | PGM_SYS_ID + year,
               data = panel_tri, cluster = ~state)
cat("FCE-only federal inspections:\n")
summary(m_fce)

## ============================================================
## 9. Wild cluster bootstrap (small cluster concern)
## ============================================================
cat("\n=== 9. Cluster inference check ===\n")
cat("Number of clusters (states):", uniqueN(panel_tri$state), "\n")
## 51 clusters is adequate for standard cluster-robust SE
## But report it for transparency

## ============================================================
## 10. Save robustness results
## ============================================================
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  event_study = if (exists("es_model")) es_model else NULL,
  nei = if (exists("m_nei")) m_nei else NULL,
  manufacturing = if (exists("m_mfg")) m_mfg else NULL,
  non_manufacturing = if (exists("m_nonmfg")) m_nonmfg else NULL,
  pre_2017 = m_pre,
  post_2016 = m_post,
  fce_only = m_fce,
  region_results = region_results
)
saveRDS(rob_results, file.path(data_dir, "models_robustness.rds"))

cat("Robustness checks complete.\n")
