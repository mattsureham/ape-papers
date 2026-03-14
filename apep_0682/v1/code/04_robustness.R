## 04_robustness.R — Robustness checks and heterogeneity analysis
## apep_0682: Sewage EDM Information Revelation and House Prices

library(data.table)
library(fixest)

DATA_DIR <- "data"

## ── 1. Load panel ─────────────────────────────────────────────────────────
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, pd_id := as.integer(factor(postcode_district))]

## ── 2. Placebo: No-overflow districts ─────────────────────────────────────
cat("=== Placebo Test: No-overflow districts ===\n")
# Create fake treatment: assign random treatment years to never-treated districts
set.seed(42)
placebo_data <- panel[gname == 0]
pd_list <- unique(placebo_data$postcode_district)
fake_treat <- data.table(
  postcode_district = pd_list,
  fake_gname = sample(2018:2023, length(pd_list), replace = TRUE)
)
placebo_data <- merge(placebo_data, fake_treat, by = "postcode_district")
placebo_data[, fake_treated := as.integer(year >= fake_gname)]

m_placebo <- feols(mean_log_price ~ fake_treated | postcode_district + year,
                   data = placebo_data, cluster = ~postcode_district)
cat("Placebo (random treatment in no-overflow districts):\n")
summary(m_placebo)

## ── 3. Property type heterogeneity ───────────────────────────────────────
cat("\n=== Property Type Heterogeneity ===\n")

# High-detached vs high-flat districts
panel[, high_detached := as.integer(pct_detached > median(pct_detached, na.rm=TRUE))]
panel[, treated_x_detached := treated * high_detached]
panel[, treated_x_nondetached := treated * (1L - high_detached)]

m_prop <- feols(mean_log_price ~ treated_x_detached + treated_x_nondetached |
                  postcode_district + year,
                data = panel, cluster = ~postcode_district)
cat("Property type heterogeneity:\n")
summary(m_prop)

## ── 4. Number of overflows intensity ─────────────────────────────────────
cat("\n=== Overflow Count Intensity ===\n")

panel[, n_overflow_cat := fcase(
  n_overflows == 0, "None",
  n_overflows <= 3, "1-3",
  n_overflows <= 10, "4-10",
  default = "11+"
)]
panel[, n_overflow_cat := factor(n_overflow_cat, levels = c("None", "1-3", "4-10", "11+"))]

m_intensity <- feols(mean_log_price ~ i(n_overflow_cat, treated, ref = "None") |
                       postcode_district + year,
                     data = panel, cluster = ~postcode_district)
cat("Intensity by overflow count:\n")
summary(m_intensity)

## ── 5. Pre-trend test ────────────────────────────────────────────────────
cat("\n=== Pre-trend Test ===\n")
panel[, event_time := fifelse(gname > 0, year - gname, NA_integer_)]
pre_data <- panel[!is.na(event_time) & event_time <= 0 & event_time >= -4]
pre_data[, et_bin := event_time]

m_pretrend <- feols(mean_log_price ~ i(et_bin, ref = -1) | postcode_district + year,
                    data = pre_data, cluster = ~postcode_district)
cat("Pre-trend coefficients (should be near zero):\n")
summary(m_pretrend)

# Joint F-test for pre-treatment coefficients
pre_coefs <- coef(m_pretrend)
pre_se <- sqrt(diag(vcov(m_pretrend)))
cat("\nPre-treatment coefficients:\n")
for (k in names(pre_coefs)) {
  cat(sprintf("  %s: %.4f (%.4f)\n", k, pre_coefs[k], pre_se[k]))
}

## ── 6. Alternative control group (never-treated only) ────────────────────
cat("\n=== Never-Treated Control Group ===\n")
nt_data <- panel[gname == 0 | gname > 0]
m_nt <- feols(mean_log_price ~ treated | postcode_district + year,
              data = nt_data, cluster = ~postcode_district)
cat("Never-treated controls:\n")
summary(m_nt)

## ── 7. Excluding London ──────────────────────────────────────────────────
cat("\n=== Excluding London ===\n")
# London postcodes start with E, EC, N, NW, SE, SW, W, WC
london_prefixes <- c("E", "EC", "N", "NW", "SE", "SW", "W", "WC")
panel[, is_london := substr(postcode_district, 1, 2) %in% london_prefixes |
        substr(postcode_district, 1, 1) %in% c("E", "N", "W") &
        nchar(postcode_district) <= 2]
# More precise London detection: postcodes starting with specific patterns
panel[, is_london := postcode_district %in%
        panel[, unique(postcode_district)][
          grepl("^(E[0-9]|EC[0-9]|N[0-9]|NW[0-9]|SE[0-9]|SW[0-9]|W[0-9]|WC[0-9])",
                panel[, unique(postcode_district)])]]

m_noldn <- feols(mean_log_price ~ treated | postcode_district + year,
                 data = panel[is_london == FALSE],
                 cluster = ~postcode_district)
cat("Excluding London:\n")
summary(m_noldn)

## ── 8. Water company heterogeneity ───────────────────────────────────────
cat("\n=== Water Company Heterogeneity ===\n")
edm_pd <- fread(file.path(DATA_DIR, "edm_postcode_district.csv"))
# Load overflow data to get dominant WaSC per postcode district
edm_full <- fread(file.path(DATA_DIR, "edm_overflow_panel.csv"))
wasc_map <- edm_full[!is.na(postcode_district),
  .(dominant_wasc = names(which.max(table(water_company)))),
  by = postcode_district]
panel <- merge(panel, wasc_map, by = "postcode_district", all.x = TRUE)
panel[is.na(dominant_wasc), dominant_wasc := "None"]

# Thames Water vs others (Thames is largest and most criticized)
panel[, is_thames := as.integer(grepl("Thames", dominant_wasc, ignore.case = TRUE))]
panel[, treated_thames := treated * is_thames]
panel[, treated_other := treated * (1L - is_thames)]

m_wasc <- feols(mean_log_price ~ treated_thames + treated_other |
                  postcode_district + year,
                data = panel[dominant_wasc != "None"],
                cluster = ~postcode_district)
cat("Thames vs other WaSCs:\n")
summary(m_wasc)

## ── 9. Save results ──────────────────────────────────────────────────────
saveRDS(list(
  placebo = m_placebo,
  prop_type = m_prop,
  intensity = m_intensity,
  pretrend = m_pretrend,
  never_treated = m_nt,
  no_london = m_noldn,
  wasc = m_wasc
), file.path(DATA_DIR, "robustness_models.rds"))

cat("\n=== Robustness checks complete ===\n")
