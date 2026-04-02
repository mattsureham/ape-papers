## ============================================================================
## 03_main_analysis.R — Main regressions for apep_1327
## Static DiD + binned event study + Rite Aid IV
## ============================================================================

source("00_packages.R")

DATA <- "../data"
panel <- readRDS(file.path(DATA, "panel_clean.rds"))

cat(sprintf("Panel: %s rows, %s ZIPs (treated=%d, control=%d)\n",
            format(nrow(panel), big.mark = ","),
            format(uniqueN(panel$zip5), big.mark = ","),
            uniqueN(panel[ever_treated == TRUE]$zip5),
            uniqueN(panel[control == TRUE]$zip5)))

## ---- 1. Summary statistics ----
sumstats_treated <- panel[ever_treated == TRUE, .(
  pharmacy_claims_mean = mean(pharmacy_claims), pharmacy_claims_sd = sd(pharmacy_claims),
  ed_claims_mean = mean(ed_claims), ed_claims_sd = sd(ed_claims),
  pharmacy_beneficiaries_mean = mean(pharmacy_beneficiaries),
  pharmacy_beneficiaries_sd = sd(pharmacy_beneficiaries),
  pharmacy_paid_mean = mean(pharmacy_paid), pharmacy_paid_sd = sd(pharmacy_paid),
  n_obs = .N, n_zips = uniqueN(zip5)
)]
sumstats_control <- panel[control == TRUE, .(
  pharmacy_claims_mean = mean(pharmacy_claims), pharmacy_claims_sd = sd(pharmacy_claims),
  ed_claims_mean = mean(ed_claims), ed_claims_sd = sd(ed_claims),
  pharmacy_beneficiaries_mean = mean(pharmacy_beneficiaries),
  pharmacy_beneficiaries_sd = sd(pharmacy_beneficiaries),
  pharmacy_paid_mean = mean(pharmacy_paid), pharmacy_paid_sd = sd(pharmacy_paid),
  n_obs = .N, n_zips = uniqueN(zip5)
)]
saveRDS(list(treated = sumstats_treated, control = sumstats_control),
        file.path(DATA, "sumstats.rds"))

## ---- 2. Static DiD ----
cat("\n=== Static DiD ===\n")
m1_pharmacy <- feols(log_pharmacy_claims ~ post | zip5 + ym, data = panel, cluster = ~zip5)
m2_beneficiaries <- feols(log_pharmacy_beneficiaries ~ post | zip5 + ym, data = panel, cluster = ~zip5)
m3_ed <- feols(log_ed_claims ~ post | zip5 + ym, data = panel, cluster = ~zip5)
m4_paid <- feols(log_pharmacy_paid ~ post | zip5 + ym, data = panel, cluster = ~zip5)

etable(m1_pharmacy, m2_beneficiaries, m3_ed, m4_paid,
       headers = c("Pharm Claims", "Beneficiaries", "ED Visits", "Pharm Spending"))

## ---- 3. Binned Event Study (efficient — no Sun-Abraham) ----
cat("\n=== Binned Event Study ===\n")

# Create event-time bins: <-12, -12 to -7, -6 to -1 (ref), 0 to 5, 6 to 11, 12+
panel[, et_bin := fcase(
  is.na(event_time) | control, NA_character_,
  event_time < -12, "pre_12plus",
  event_time >= -12 & event_time < -6, "pre_12_to_7",
  event_time >= -6 & event_time < 0, "ref",
  event_time >= 0 & event_time < 6, "post_0_to_5",
  event_time >= 6 & event_time < 12, "post_6_to_11",
  event_time >= 12, "post_12plus"
)]

# Make factor with ref as reference
panel[, et_bin := factor(et_bin, levels = c("ref", "pre_12plus", "pre_12_to_7",
                                             "post_0_to_5", "post_6_to_11", "post_12plus"))]

es_pharmacy <- feols(log_pharmacy_claims ~ et_bin | zip5 + ym,
                     data = panel[!is.na(et_bin) | control],
                     cluster = ~zip5)

es_ed <- feols(log_ed_claims ~ et_bin | zip5 + ym,
               data = panel[!is.na(et_bin) | control],
               cluster = ~zip5)

cat("Event study — pharmacy:\n")
summary(es_pharmacy)
cat("\nEvent study — ED:\n")
summary(es_ed)

## ---- 4. Rite Aid IV ----
cat("\n=== Rite Aid Bankruptcy IV ===\n")

# Check Rite Aid ZIP count
n_rite_aid <- uniqueN(panel[has_rite_aid == TRUE]$zip5)
cat(sprintf("Rite Aid ZIPs: %d\n", n_rite_aid))

if (n_rite_aid >= 30) {
  fs <- feols(post ~ rite_aid_iv | zip5 + ym, data = panel, cluster = ~zip5)
  f_stat_val <- fitstat(fs, "ivf")$ivf[[1]]
  cat(sprintf("First stage F: %.1f\n", f_stat_val))

  iv_pharmacy <- feols(log_pharmacy_claims ~ 1 | zip5 + ym | post ~ rite_aid_iv,
                       data = panel, cluster = ~zip5)
  iv_ed <- feols(log_ed_claims ~ 1 | zip5 + ym | post ~ rite_aid_iv,
                 data = panel, cluster = ~zip5)
  cat("IV pharmacy:\n"); summary(iv_pharmacy)
  cat("IV ED:\n"); summary(iv_ed)
} else {
  cat("Too few Rite Aid ZIPs for IV. Using chain-wide corporate distress discussion instead.\n")
  f_stat_val <- NA_real_
  fs <- NULL
  iv_pharmacy <- NULL
  iv_ed <- NULL
}

## ---- 5. Heterogeneity: Last Pharmacy Standing ----
cat("\n=== Heterogeneity ===\n")

m_last <- feols(log_pharmacy_claims ~ post | zip5 + ym,
                data = panel[last_pharm == TRUE | control], cluster = ~zip5)
m_not_last <- feols(log_pharmacy_claims ~ post | zip5 + ym,
                    data = panel[(ever_treated & !last_pharm) | control], cluster = ~zip5)

cat("Last pharmacy:\n"); summary(m_last)
cat("Other chains remain:\n"); summary(m_not_last)

# ED heterogeneity
m_ed_last <- feols(log_ed_claims ~ post | zip5 + ym,
                   data = panel[last_pharm == TRUE | control], cluster = ~zip5)
m_ed_notlast <- feols(log_ed_claims ~ post | zip5 + ym,
                      data = panel[(ever_treated & !last_pharm) | control], cluster = ~zip5)

cat("ED — last pharmacy:\n"); summary(m_ed_last)
cat("ED — other chains remain:\n"); summary(m_ed_notlast)

## ---- 6. Save ----
models <- list(
  static_pharmacy = m1_pharmacy,
  static_beneficiaries = m2_beneficiaries,
  static_ed = m3_ed,
  static_paid = m4_paid,
  es_pharmacy = es_pharmacy,
  es_ed = es_ed,
  iv_pharmacy = iv_pharmacy,
  iv_ed = iv_ed,
  first_stage = fs,
  het_last = m_last,
  het_not_last = m_not_last,
  het_ed_last = m_ed_last,
  het_ed_notlast = m_ed_notlast
)
saveRDS(models, file.path(DATA, "models.rds"))

## ---- 7. diagnostics.json ----
diagnostics <- list(
  n_treated = uniqueN(panel[ever_treated == TRUE]$zip5),
  n_pre = length(unique(panel[ever_treated == TRUE & pre_treatment == TRUE]$month_date)),
  n_obs = nrow(panel),
  n_control = uniqueN(panel[control == TRUE]$zip5),
  n_months = uniqueN(panel$month_date),
  first_stage_f = ifelse(is.na(f_stat_val), 0, f_stat_val)
)
write_json(diagnostics, file.path(DATA, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\n=== Complete. n_treated=%d, n_obs=%s ===\n",
            diagnostics$n_treated, format(diagnostics$n_obs, big.mark = ",")))
