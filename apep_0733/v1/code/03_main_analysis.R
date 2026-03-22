## 03_main_analysis.R — Main specifications
## Paper: The Fortress Premium (apep_0733)

source("code/00_packages.R")

hesta <- fread("data/hesta_clean.csv")
cat(sprintf("Analysis sample: %d rows\n", nrow(hesta)))

# --- Restrict to pre-COVID sample (2005-2019) for clean identification ---
# COVID is a massive confound; main results use 2005-2019
hesta_main <- hesta[year <= 2019]
cat(sprintf("Pre-COVID sample: %d rows (%d-%d)\n", nrow(hesta_main),
    min(hesta_main$year), max(hesta_main$year)))

# --- Focus on key origin groups: Swiss domestic vs Eurozone ---
# This is the cleanest within-canton comparison
hesta_di <- hesta_main[exposure %in% c("swiss", "eurozone")]
cat(sprintf("Swiss + Eurozone subsample: %d rows\n", nrow(hesta_di)))

# Aggregate to canton × exposure group × month level for cleaner estimation
agg <- hesta_di[, .(
  nights = sum(nights, na.rm = TRUE)
), by = .(canton, canton_name, exposure, year, month, post, event_time, euro_share_2014)]

agg[, log_nights := log(pmax(nights, 1))]
agg[, ym := year * 100 + month]
agg[, ce := paste0(canton, "_", exposure)]

cat(sprintf("Aggregated panel: %d rows, %d canton-exposure units\n",
    nrow(agg), uniqueN(agg$ce)))

# ============================================================
# SPECIFICATION 1: Simple DiD (Swiss vs Eurozone within cantons)
# ============================================================
cat("\n=== Specification 1: Simple DiD ===\n")

m1 <- feols(log_nights ~ post:i(exposure, ref = "swiss") |
              ce + ym, data = agg, vcov = ~canton)

cat("\nDiD: Eurozone vs Swiss domestic, post-2015\n")
summary(m1)

# ============================================================
# SPECIFICATION 2: Event Study
# ============================================================
cat("\n=== Specification 2: Event Study ===\n")

# Create annual event time for cleaner coefficients
agg[, event_year := year - 2015]

# Aggregate to annual for event study
annual_agg <- agg[, .(
  nights = sum(nights, na.rm = TRUE)
), by = .(canton, canton_name, exposure, year, event_year, euro_share_2014)]
annual_agg[, log_nights := log(pmax(nights, 1))]
annual_agg[, ce := paste0(canton, "_", exposure)]
annual_agg[, euro := as.integer(exposure == "eurozone")]

m2 <- feols(log_nights ~ i(event_year, euro, ref = -1) |
              ce + year, data = annual_agg, vcov = ~canton)

cat("\nEvent study coefficients (Euro vs Swiss, ref = -1):\n")
summary(m2)

# ============================================================
# SPECIFICATION 3: Bartik shift-share at canton level
# ============================================================
cat("\n=== Specification 3: Bartik shift-share ===\n")

# Aggregate to canton × month level (all origins)
canton_month <- hesta_main[, .(
  nights = sum(nights, na.rm = TRUE)
), by = .(canton, canton_name, year, month, post, euro_share_2014)]
canton_month[, log_nights := log(pmax(nights, 1))]
canton_month[, ym := year * 100 + month]

# Bartik: canton-level effect scaled by pre-shock Eurozone share
m3 <- feols(log_nights ~ post:euro_share_2014 | canton + ym,
            data = canton_month, vcov = ~canton)

cat("\nBartik reduced form: post × euro_share_2014\n")
summary(m3)

# ============================================================
# SPECIFICATION 4: Triple difference (canton × exposure × post)
# with origin-level disaggregation
# ============================================================
cat("\n=== Specification 4: Origin-level DiD ===\n")

# Use the full origin-level panel
origin_panel <- hesta_main[nights > 0]
origin_panel[, co := paste0(canton, "_", origin)]

# Drop very small canton-origin pairs (< 100 annual nights in 2014)
pre_size <- origin_panel[year == 2014, .(annual = sum(nights)), by = co]
keep_pairs <- pre_size[annual >= 100]$co
origin_small <- origin_panel[co %in% keep_pairs]
cat(sprintf("Origin-level panel (>100 nights/yr): %d rows, %d pairs\n",
    nrow(origin_small), uniqueN(origin_small$co)))

m4 <- feols(log_nights ~ post:euro_exposed | co + ym,
            data = origin_small, vcov = ~canton)

cat("\nOrigin-level DiD: post × euro_exposed\n")
summary(m4)

# ============================================================
# SPECIFICATION 5: Heterogeneity by canton type
# ============================================================
cat("\n=== Specification 5: Heterogeneity ===\n")

# Classify cantons as tourism-heavy vs. urban/business
tourism_cantons <- c("18", "23", "3", "6", "7", "4")  # Graubünden, Valais, Luzern, Schwyz, Nidwalden, Uri
urban_cantons <- c("1", "25", "12", "22")  # Zürich, Genève, Basel-Stadt, Vaud

agg[, canton_type := fcase(
  canton %in% tourism_cantons, "tourism",
  canton %in% urban_cantons, "urban",
  default = "other"
)]

agg[, euro := as.integer(exposure == "eurozone")]
m5_tourism <- feols(log_nights ~ post:euro | ce + ym,
                     data = agg[canton_type == "tourism"], vcov = ~canton)
m5_urban <- feols(log_nights ~ post:euro | ce + ym,
                   data = agg[canton_type == "urban"], vcov = ~canton)
m5_other <- feols(log_nights ~ post:euro | ce + ym,
                   data = agg[canton_type == "other"], vcov = ~canton)

cat("\nHeterogeneity by canton type:\n")
cat(sprintf("  Tourism cantons: %.3f (SE: %.3f)\n", coef(m5_tourism)[1], se(m5_tourism)[1]))
cat(sprintf("  Urban cantons:   %.3f (SE: %.3f)\n", coef(m5_urban)[1], se(m5_urban)[1]))
cat(sprintf("  Other cantons:   %.3f (SE: %.3f)\n", coef(m5_other)[1], se(m5_other)[1]))

# ============================================================
# Save results
# ============================================================

# Create diagnostics.json
n_treated <- uniqueN(hesta_main[exposure == "eurozone"]$canton)
n_pre <- length(unique(hesta_main[year < 2015]$year))
n_obs <- nrow(agg)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_cantons = uniqueN(hesta_main$canton),
  n_origins = uniqueN(hesta_main$origin),
  n_months = uniqueN(hesta_main$ym),
  sample_period = "2005-2019",
  treatment_date = "2015-01-15"
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

# Save model objects for table generation
results <- list(
  m1_did = m1,
  m2_event = m2,
  m3_bartik = m3,
  m4_origin = m4,
  m5_tourism = m5_tourism,
  m5_urban = m5_urban,
  m5_other = m5_other
)
saveRDS(results, "data/main_results.rds")

cat("\nSaved diagnostics.json and main_results.rds\n")

# Print key summary statistics for paper
cat("\n=== KEY RESULTS FOR PAPER ===\n")
cat(sprintf("DiD estimate (Euro vs Swiss, post-2015): %.3f (SE: %.3f)\n",
    coef(m1)[1], se(m1)[1]))
cat(sprintf("  → Eurozone overnight stays fell %.1f%% relative to Swiss domestic\n",
    100 * (exp(coef(m1)[1]) - 1)))
cat(sprintf("Bartik estimate: %.3f (SE: %.3f)\n", coef(m3)[1], se(m3)[1]))
cat(sprintf("Origin-level DiD: %.3f (SE: %.3f)\n", coef(m4)[1], se(m4)[1]))
