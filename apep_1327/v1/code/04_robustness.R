## ============================================================================
## 04_robustness.R — Robustness checks for apep_1327
## ============================================================================

source("00_packages.R")

DATA <- "../data"
panel <- readRDS(file.path(DATA, "panel_clean.rds"))
models <- readRDS(file.path(DATA, "models.rds"))

cat("=== Robustness Checks ===\n")

## ---- 1. Placebo: ED visits should not respond mechanically ----
# ED visits at non-chain providers in the same ZIP should not decline
# when a chain pharmacy closes (unless through health deterioration)
cat("\n--- Asinh specifications ---\n")
m_asinh_pharmacy <- feols(
  asinh_pharmacy_claims ~ post | zip5 + ym,
  data = panel,
  cluster = ~zip5
)

m_asinh_ed <- feols(
  asinh_ed_claims ~ post | zip5 + ym,
  data = panel,
  cluster = ~zip5
)

cat("Asinh pharmacy:\n")
summary(m_asinh_pharmacy)
cat("Asinh ED:\n")
summary(m_asinh_ed)

## ---- 2. Leave-one-chain-out ----
cat("\n--- Leave-one-chain-out ---\n")
npi_span <- readRDS(file.path(DATA, "npi_span.rds"))

# Identify which ZIPs had closures from each chain
for (chain_exclude in c("CVS", "WALGREENS", "RITE_AID")) {
  # Find ZIPs where the ONLY closure was from this chain
  zip_chain_closures <- npi_span[closed == TRUE, .(
    chains_closed = paste(unique(chain), collapse = ","),
    only_this_chain = all(chain == chain_exclude)
  ), by = zip5]

  # Exclude ZIPs where closure was ONLY from this chain
  exclude_zips <- zip_chain_closures[only_this_chain == TRUE]$zip5
  sample_loo <- panel[!(zip5 %in% exclude_zips & ever_treated)]

  m_loo <- feols(
    log_pharmacy_claims ~ post | zip5 + ym,
    data = sample_loo,
    cluster = ~zip5
  )
  cat(sprintf("Excluding %s-only ZIPs (%d excluded): coef=%.4f, se=%.4f\n",
              chain_exclude, length(exclude_zips),
              coef(m_loo)["postTRUE"], se(m_loo)["postTRUE"]))
}

## ---- 3. Pre-2020 subsample (pre-COVID) ----
cat("\n--- Pre-COVID subsample (2018-2019) ---\n")
m_precovid <- feols(
  log_pharmacy_claims ~ post | zip5 + ym,
  data = panel[month_date < as.Date("2020-03-01")],
  cluster = ~zip5
)
cat("Pre-COVID:\n")
summary(m_precovid)

## ---- 4. Post-2021 subsample (post-COVID recovery) ----
cat("\n--- Post-COVID subsample (2021-2024) ---\n")
m_postcovid <- feols(
  log_pharmacy_claims ~ post | zip5 + ym,
  data = panel[month_date >= as.Date("2021-01-01")],
  cluster = ~zip5
)
cat("Post-COVID:\n")
summary(m_postcovid)

## ---- 5. Save ----
robust_models <- list(
  asinh_pharmacy = m_asinh_pharmacy,
  asinh_ed = m_asinh_ed,
  precovid = m_precovid,
  postcovid = m_postcovid
)
saveRDS(robust_models, file.path(DATA, "robust_models.rds"))

cat("\n=== Robustness complete ===\n")
