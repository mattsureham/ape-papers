## 04_robustness.R — Robustness checks
## apep_0899: Finland compulsory education extension

source("00_packages.R")

load("../data/main_models.RData")

cat("Panel loaded:", nrow(panel), "obs\n")

## ============================================================
## 1. Leave-one-region-out
## ============================================================
cat("\n=== Leave-one-region-out ===\n")

regions <- unique(panel$region_name)
loo_results <- map_dfr(regions, function(r) {
  d <- filter(panel, region_name != r)
  m <- feols(employed_pct ~ vocational:intensity:post + vocational:post +
               intensity:post |
               region_id^vocational + year^vocational,
             data = d, cluster = ~region_id)
  # Extract DDD coefficient (vocational:intensity:post)
  coefs <- coef(m)
  idx <- grep("vocational.*intensity.*post", names(coefs))
  if (length(idx) == 0) return(tibble(dropped = r, coef = NA, se = NA))
  tibble(
    dropped = r,
    coef = coefs[idx],
    se = sqrt(diag(vcov(m)))[idx]
  )
})

cat("Leave-one-out range:\n")
cat("  Min coef:", min(loo_results$coef, na.rm = TRUE), "\n")
cat("  Max coef:", max(loo_results$coef, na.rm = TRUE), "\n")
cat("  Main estimate:", coef(m3)[grep("vocational.*intensity.*post", names(coef(m3)))], "\n")
print(loo_results)

## ============================================================
## 2. Binary intensity (above/below median)
## ============================================================
cat("\n=== Binary intensity ===\n")

m_binary <- feols(employed_pct ~ vocational:high_intensity:post + vocational:post +
                    high_intensity:post |
                    region_id^vocational + year^vocational,
                  data = panel, cluster = ~region_id)
cat("Binary DDD (high vs low intensity):\n")
summary(m_binary)

## ============================================================
## 3. Placebo: general education only (should show no effect)
## ============================================================
cat("\n=== Placebo: general education ===\n")

m_placebo <- feols(employed_pct ~ intensity:post |
                     region_id + year,
                   data = filter(panel, sector == "general"),
                   cluster = ~region_id)
cat("General education only (placebo):\n")
summary(m_placebo)

## ============================================================
## 4. Alternative outcome: unemployment rate
## ============================================================
cat("\n=== Unemployment DDD ===\n")

m_unemp_binary <- feols(unemployed_pct ~ vocational:high_intensity:post + vocational:post +
                           high_intensity:post |
                           region_id^vocational + year^vocational,
                         data = panel, cluster = ~region_id)
summary(m_unemp_binary)

## ============================================================
## 5. Alternative intensity: pre-reform employment rate (inverse)
## ============================================================
cat("\n=== Alternative intensity: pre-reform employment ===\n")

panel_alt <- panel %>%
  mutate(intensity_emp = 100 - pre_employed_pct)  # Low employment = high intensity

m_alt_int <- feols(employed_pct ~ vocational:intensity_emp:post + vocational:post +
                     intensity_emp:post |
                     region_id^vocational + year^vocational,
                   data = panel_alt, cluster = ~region_id)
summary(m_alt_int)

## ============================================================
## 6. Shorter pre-period (2015-2024) — avoid noisy early years
## ============================================================
cat("\n=== Shorter pre-period (2015+) ===\n")

m_short <- feols(employed_pct ~ vocational:intensity:post + vocational:post +
                   intensity:post |
                   region_id^vocational + year^vocational,
                 data = filter(panel, year >= 2015),
                 cluster = ~region_id)
summary(m_short)

## ============================================================
## Save all robustness models
## ============================================================
save(loo_results, m_binary, m_placebo, m_unemp_binary, m_alt_int, m_short,
     file = "../data/robustness_models.RData")

cat("\n=== Robustness complete ===\n")
