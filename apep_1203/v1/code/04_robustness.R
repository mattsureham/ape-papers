## 04_robustness.R — Robustness checks
## apep_1203: Argentina SAS Firm Registration Ban

source("00_packages.R")

data_dir <- "../data"
firms <- fread(file.path(data_dir, "firms_clean.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

main_types <- c("SAS", "SA", "SRL")

# ── Rebuild panel ─────────────────────────────────────────────────────────────

panel_firms <- firms[type_clean %in% main_types &
                     province_clean != "UNKNOWN" &
                     year(date_clean) >= 2017 & year(date_clean) <= 2025]

panel <- panel_firms[, .(n_firms = .N),
                     by = .(province = province_clean,
                            ym = floor_date(date_clean, "month"),
                            type = type_clean)]

all_provs <- unique(panel$province)
all_months <- seq(as.Date("2017-01-01"), as.Date("2025-12-01"), by = "month")
grid <- CJ(province = all_provs, ym = all_months, type = main_types)
panel <- merge(grid, panel, by = c("province", "ym", "type"), all.x = TRUE)
panel[is.na(n_firms), n_firms := 0]

panel[, `:=`(
  year = year(ym),
  is_sas = as.integer(type == "SAS"),
  is_caba = as.integer(province == "CABA"),
  log_firms = log(n_firms + 1),
  ban = as.integer(ym >= as.Date("2020-03-01") & ym < as.Date("2024-04-01")),
  post = as.integer(ym >= as.Date("2024-04-01"))
)]

# ── Robustness 1: Restricted pre-period (2019+) ──────────────────────────────

cat("\n=== ROBUSTNESS 1: Pre-period from 2019 only ===\n")
cat("(Avoids SAS ramp-up confound from 2017-2018)\n")

sas_restricted <- panel[type == "SAS" & ym >= as.Date("2019-01-01")]
r1 <- feols(n_firms ~ is_caba:ban + is_caba:post | province + ym,
            data = sas_restricted, cluster = ~province)
cat("SAS geographic DiD (2019+ only):\n")
print(summary(r1))

# Restricted event study (2019+ pre-period)
sas_restricted[, event_time := as.integer(round(
  as.numeric(difftime(ym, as.Date("2020-03-01"), units = "days")) / 30.44
))]
sas_restricted[event_time > 60, event_time := 60]
sas_restricted[, event_quarter := floor(event_time / 3) * 3]

es_restricted <- feols(n_firms ~ i(event_quarter, is_caba, ref = -3) |
                       province + ym,
                       data = sas_restricted, cluster = ~province)
cat("\nEvent study (2019+ only) - pre-period coefficients:\n")
es_coefs <- coeftable(es_restricted)
pre_coefs <- es_coefs[grepl(":-[0-9]", rownames(es_coefs)), ]
print(pre_coefs)

# ── Robustness 2: Province-specific linear trends ────────────────────────────

cat("\n=== ROBUSTNESS 2: Province-specific linear trends ===\n")

panel[, time_trend := as.numeric(ym - as.Date("2017-01-01")) / 365.25]

sas_trend <- panel[type == "SAS"]
r2 <- feols(n_firms ~ is_caba:ban + is_caba:post + province:time_trend |
            province + ym,
            data = sas_trend, cluster = ~province)
cat("SAS with province-specific trends:\n")
print(summary(r2))

# ── Robustness 3: Buenos Aires Province as additional treated ─────────────────

cat("\n=== ROBUSTNESS 3: Include Buenos Aires Province as treated ===\n")

# BA Province also saw SAS collapse (but later)
panel[, is_treated := as.integer(province %in% c("CABA", "BUENOS AIRES"))]

sas_ba <- panel[type == "SAS"]
r3 <- feols(n_firms ~ is_treated:ban + is_treated:post | province + ym,
            data = sas_ba, cluster = ~province)
cat("SAS geographic DiD (CABA + BA Province treated):\n")
print(summary(r3))

# ── Robustness 4: Placebo test — fake ban date ──────────────────────────────

cat("\n=== ROBUSTNESS 4: Placebo ban at March 2018 ===\n")

sas_placebo <- panel[type == "SAS" & ym < as.Date("2020-03-01")]
sas_placebo[, fake_ban := as.integer(ym >= as.Date("2018-06-01"))]

r4 <- feols(n_firms ~ is_caba:fake_ban | province + ym,
            data = sas_placebo, cluster = ~province)
cat("Placebo (fake ban June 2018):\n")
print(summary(r4))

# ── Robustness 5: Poisson specification (count data) ─────────────────────────

cat("\n=== ROBUSTNESS 5: Poisson regression ===\n")

sas_poisson <- panel[type == "SAS"]
r5 <- tryCatch({
  fepois(n_firms ~ is_caba:ban + is_caba:post | province + ym,
         data = sas_poisson, cluster = ~province)
}, error = function(e) {
  cat("Poisson failed:", conditionMessage(e), "\n")
  # Try with month FE only
  fepois(n_firms ~ is_caba:ban + is_caba:post | province + year,
         data = sas_poisson, cluster = ~province)
})
cat("Poisson model:\n")
print(summary(r5))

# ── Robustness 6: Leave-one-out (dropping each province) ────────────────────

cat("\n=== ROBUSTNESS 6: Leave-one-out (jackknife by province) ===\n")

sas_loo <- panel[type == "SAS"]
loo_coefs <- sapply(setdiff(all_provs, "CABA"), function(prov) {
  d <- sas_loo[province != prov]
  m <- feols(n_firms ~ is_caba:ban | province + ym, data = d)
  coef(m)["is_caba:ban"]
})

cat("Leave-one-out ban coefficient:\n")
cat("  Mean:", round(mean(loo_coefs), 1), "\n")
cat("  Min:", round(min(loo_coefs), 1), "\n")
cat("  Max:", round(max(loo_coefs), 1), "\n")
cat("  SD:", round(sd(loo_coefs), 1), "\n")

# ── Robustness 7: Permutation / Randomization inference ──────────────────────

cat("\n=== ROBUSTNESS 7: Randomization inference (permute treated province) ===\n")

# Permute which province is "treated" — compute the DiD coefficient each time
set.seed(42)
n_perms <- 1000
perm_coefs <- numeric(n_perms)

for (i in 1:n_perms) {
  fake_treated <- sample(all_provs, 1)  # Random province as "treated"
  sas_perm <- panel[type == "SAS"]
  sas_perm[, fake_caba := as.integer(province == fake_treated)]
  m_perm <- feols(n_firms ~ fake_caba:ban | province + ym, data = sas_perm)
  perm_coefs[i] <- coef(m_perm)["fake_caba:ban"]
}

actual_coef <- coef(results$m2_ban)["is_caba:ban"]
ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Actual coefficient:", round(actual_coef, 1), "\n")
cat("Permutation p-value:", ri_pvalue, "\n")
cat("Permutation distribution: mean =", round(mean(perm_coefs), 1),
    ", SD =", round(sd(perm_coefs), 1), "\n")

# ── Save robustness results ──────────────────────────────────────────────────

rob_results <- list(
  r1_restricted = r1,
  es_restricted = es_restricted,
  r2_trends = r2,
  r3_ba_treated = r3,
  r4_placebo = r4,
  r5_poisson = r5,
  loo_mean = mean(loo_coefs),
  loo_sd = sd(loo_coefs),
  ri_pvalue = ri_pvalue,
  perm_coefs = perm_coefs,
  actual_coef = actual_coef
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
