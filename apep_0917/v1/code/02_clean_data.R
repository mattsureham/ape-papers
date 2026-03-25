# 02_clean_data.R — Construct agency-year panel with state reform coding
# APEP Working Paper apep_0917

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "esac_panel_raw.rds"))

# ============================================================
# State Civil Asset Forfeiture Reform Coding
# ============================================================
# Sources: Institute for Justice "Policing for Profit" 4th Edition (2024),
#   NCSL Civil Asset Forfeiture Reform database, state legislation.
# Reform types:
#   abolish    = civil forfeiture abolished (conviction required for ALL)
#   conviction = criminal conviction required for most/all forfeitures
#   burden     = raised standard of proof / enhanced procedural protections
#   reporting  = transparency/reporting requirements only
# Anti-circumvention: explicit state law prohibiting federal adoption workaround

reform_coding <- data.table(
  state = c(
    # === Abolished / Conviction Required (strongest reforms) ===
    "NM",  # 2015: HB 560 — abolished civil forfeiture entirely
    "NE",  # 2016: LB 1106 — abolished civil forfeiture
    "NC",  # 2014: already required conviction pre-period (since 2002)
    "MT",  # 2015: HB 463 — conviction required for most
    "MN",  # 2014: SF 874 — conviction required, raised burden
    "CT",  # 2017: PA 17-142 — conviction required for most
    "AZ",  # 2017: HB 2477 — conviction required + anti-circumvention
    "MI",  # 2019: HB 4001 package — conviction required
    "IN",  # 2019: HB 1141 — conviction required
    "KS",  # 2019: HB 2274 — conviction required for most
    "ND",  # 2019: HB 1286 — conviction required
    "ID",  # 2017: HB 202 — conviction required
    "KY",  # 2021: HB 202 — conviction required

    # === Burden of Proof Raised / Enhanced Protections ===
    "FL",  # 2016: SB 1044 — raised to beyond reasonable doubt
    "CA",  # 2017: SB 443 — conviction for seizures under $40K (eff. 2017)
    "CO",  # 2017: SB 17-060 — raised burden + anti-circumvention
    "PA",  # 2017: SB 8 — raised burden, innocent owner protections
    "OH",  # 2017: SB 316 — raised burden, procedural reform
    "GA",  # 2015: SB 160 — raised burden for some, added reporting
    "MD",  # 2016: HB 336 — raised value thresholds, added protections
    "WY",  # 2016: HB 137 — raised burden to clear and convincing
    "SD",  # 2016: SB 85 — raised burden
    "MO",  # 2019: HB 820 — raised burden, added protections
    "NH",  # 2016: HB 636 — conviction required for most (enhanced)
    "VA",  # 2017: HB 1578 — raised burden, added protections
    "UT",  # 2018: SB 170 — raised burden
    "IL",  # 2018: SB 1578 — added protections
    "OK",  # 2016: SQ 790 implications + SB 838 — enhanced protections
    "WI",  # 2018: Act 208 — raised burden to clear and convincing
    "NV",  # 2017: AB 420 — raised burden to clear and convincing

    # === Reporting / Transparency Only ===
    "TN",  # 2015: SB 650 — reporting requirements
    "WV",  # 2016: SB 534 — reporting requirements
    "TX",  # 2017: SB 1913 — enhanced reporting
    "HI",  # 2019: HB 748 — reporting requirements
    "IA",  # 2017: SF 446 — reporting requirements
    "OR",  # 2018: HB 2714 — reporting (eff. 2018)
    "SC",  # 2019: S 2 — reporting + minor protections
    "AR"   # 2019: SB 308 — reporting requirements
  ),
  reform_year = c(
    # Abolished/Conviction
    2015, 2016, 2014, 2015, 2014, 2017, 2017, 2019, 2019, 2019, 2019, 2017, 2021,
    # Burden/Enhanced
    2016, 2017, 2017, 2017, 2017, 2015, 2016, 2016, 2016, 2019, 2016, 2017, 2018, 2018, 2016, 2018, 2017,
    # Reporting
    2015, 2016, 2017, 2019, 2017, 2018, 2019, 2019
  ),
  reform_type = c(
    # Abolished/Conviction
    "abolish", "abolish", "conviction", "conviction", "conviction",
    "conviction", "conviction", "conviction", "conviction", "conviction",
    "conviction", "conviction", "conviction",
    # Burden/Enhanced
    "burden", "burden", "burden", "burden", "burden", "burden", "burden",
    "burden", "burden", "burden", "burden", "burden", "burden", "burden",
    "burden", "burden", "burden",
    # Reporting
    "reporting", "reporting", "reporting", "reporting", "reporting",
    "reporting", "reporting", "reporting"
  ),
  anti_circumvention = c(
    # Abolished/Conviction (NM, NE have implicit anti-circ; AZ explicit)
    TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE,
    # Burden/Enhanced (CO has explicit anti-circ)
    FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
    FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
    # Reporting
    FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE
  )
)

# Validate: correct number of entries
stopifnot(nrow(reform_coding) == length(unique(reform_coding$state)))
cat("Reform coding: ", nrow(reform_coding), "states\n")
cat("  Abolish:", sum(reform_coding$reform_type == "abolish"), "\n")
cat("  Conviction:", sum(reform_coding$reform_type == "conviction"), "\n")
cat("  Burden:", sum(reform_coding$reform_type == "burden"), "\n")
cat("  Reporting:", sum(reform_coding$reform_type == "reporting"), "\n")
cat("  Anti-circumvention:", sum(reform_coding$anti_circumvention), "\n")

# Reform strength: numeric intensity
reform_coding[, reform_strength := fcase(
  reform_type == "abolish", 4L,
  reform_type == "conviction", 3L,
  reform_type == "burden", 2L,
  reform_type == "reporting", 1L
)]

# Strong reform indicator (abolish or conviction required)
reform_coding[, strong_reform := reform_type %in% c("abolish", "conviction")]

# ============================================================
# Merge reform coding onto panel
# ============================================================
panel <- merge(panel, reform_coding, by.x = "NCIC_ST", by.y = "state", all.x = TRUE)

# Never-reformed states: reform_year = Inf (or 0 for CS-DiD "never treated")
panel[is.na(reform_year), reform_year := 0L]
panel[is.na(reform_type), reform_type := "none"]
panel[is.na(reform_strength), reform_strength := 0L]
panel[is.na(anti_circumvention), anti_circumvention := FALSE]
panel[is.na(strong_reform), strong_reform := FALSE]

# Post-reform indicator
panel[, post_reform := fifelse(reform_year > 0 & FORM_FY >= reform_year, 1L, 0L)]

# ============================================================
# Sample restrictions
# ============================================================
# Keep FY 2016-2024 for balanced-ish panel (2016 is first year with broad coverage)
panel <- panel[FORM_FY >= 2016 & FORM_FY <= 2024]
cat("\nAfter FY 2016-2024 restriction:", nrow(panel), "obs\n")

# Create agency numeric ID for CS-DiD
panel[, agency_id := as.integer(as.factor(NCIC_CD))]

# ============================================================
# Outcome variables
# ============================================================
# Inverse hyperbolic sine (handles zeros better than log(x+1))
panel[, asinh_es_revenue := asinh(es_total_revenue)]
panel[, log_es_revenue := log(es_total_revenue + 1)]

# Binary: any ES revenue
panel[, has_es_revenue := as.integer(es_total_revenue > 0)]

# Per-capita would require population data; skip for V1

# ============================================================
# Balance and coverage
# ============================================================
cat("\n=== PANEL STRUCTURE ===\n")
cat("Agency-years:", nrow(panel), "\n")
cat("Unique agencies:", length(unique(panel$NCIC_CD)), "\n")
cat("FY range:", range(panel$FORM_FY), "\n")

# Treatment status
state_reform <- unique(panel[, .(NCIC_ST, reform_year, reform_type, reform_strength,
                                  anti_circumvention, strong_reform)])
cat("\nReform states:", sum(state_reform$reform_year > 0), "\n")
cat("Never-reformed states:", sum(state_reform$reform_year == 0), "\n")
cat("Never-reformed:", paste(sort(state_reform[reform_year == 0, NCIC_ST]), collapse=", "), "\n")

# Cohort distribution (for reformed states only)
cat("\nCohort distribution (reform year):\n")
print(table(state_reform[reform_year > 0, reform_year]))

# Reform type distribution
cat("\nReform type:\n")
print(table(state_reform$reform_type))

# Summary stats by treatment status
cat("\nMean ES revenue by reform status:\n")
print(panel[, .(mean_revenue = mean(es_total_revenue),
                median_revenue = median(es_total_revenue),
                pct_positive = mean(has_es_revenue),
                n_obs = .N),
            by = .(reformed = reform_year > 0)])

cat("\nMean ES revenue by FY and reform status:\n")
summ <- panel[, .(mean_revenue = mean(es_total_revenue)),
              by = .(FORM_FY, reformed = reform_year > 0)]
print(dcast(summ, FORM_FY ~ reformed, value.var = "mean_revenue"))

# ============================================================
# Save
# ============================================================
saveRDS(panel, file.path(data_dir, "panel_clean.rds"))
cat("\nSaved cleaned panel:", nrow(panel), "rows\n")
cat("CLEAN COMPLETE\n")
