## 04_robustness.R — Robustness checks
## apep_0986: Forced EPCI Mergers and RN Voting

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel <- panel[!is.na(treated)]
panel[, turnout := exprimes / inscrits * 100]

## ============================================================================
## 1. Alternative clustering: EPCI-level (post-reform) and commune level
## ============================================================================
cat("\n=== Robustness: Alternative clustering ===\n")

## Cluster at EPCI level (post-reform EPCI boundaries)
m_epci_cluster <- feols(fn_share ~ treat_post | code_commune + year,
                        data = panel, cluster = ~epci_2017)
cat("Clustered at EPCI level:\n")
summary(m_epci_cluster)

## Heteroskedasticity-robust SE (no clustering)
m_robust <- feols(fn_share ~ treat_post | code_commune + year,
                  data = panel, vcov = "hetero")
cat("\nHeteroskedasticity-robust:\n")
summary(m_robust)

## ============================================================================
## 2. Excluding overseas départements (DOM-TOM)
## ============================================================================
cat("\n=== Robustness: Excluding DOM-TOM ===\n")

panel_metro <- panel[as.integer(substr(dep, 1, 2)) < 97 | is.na(as.integer(substr(dep, 1, 2)))]
m_metro <- feols(fn_share ~ treat_post | code_commune + year,
                 data = panel_metro, cluster = ~dep)
cat("Metropolitan France only:\n")
summary(m_metro)

## ============================================================================
## 3. Balanced panel only (communes present in all 4 elections)
## ============================================================================
cat("\n=== Robustness: Balanced panel ===\n")

balanced_communes <- panel[, .N, by = code_commune][N == 4, code_commune]
panel_balanced <- panel[code_commune %in% balanced_communes]
cat(sprintf("Balanced panel: %d communes\n", length(balanced_communes)))

m_balanced <- feols(fn_share ~ treat_post | code_commune + year,
                    data = panel_balanced, cluster = ~dep)
cat("Balanced panel result:\n")
summary(m_balanced)

## ============================================================================
## 4. Wild cluster bootstrap (for inference with ~96 clusters)
## ============================================================================
cat("\n=== Robustness: Wild cluster bootstrap ===\n")

## Use fwildclusterboot for proper small-cluster inference
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_result <- tryCatch({
    boottest(m_balanced, param = "treat_post", B = 999,
             clustid = "dep", type = "rademacher")
  }, error = function(e) {
    cat("Wild bootstrap error:", e$message, "\n")
    NULL
  })
  if (!is.null(boot_result)) {
    cat("Wild cluster bootstrap:\n")
    print(summary(boot_result))
  }
} else {
  cat("fwildclusterboot not installed, skipping\n")
}

## ============================================================================
## 5. Heterogeneity: Small vs large mergers
## ============================================================================
cat("\n=== Heterogeneity: Merger size ===\n")

## Split treated communes by merger intensity at median
median_intensity <- median(panel[treated == 1 & post == 0, merger_intensity], na.rm = TRUE)
panel[, large_merger := as.integer(merger_intensity > median_intensity)]

m_hetero <- feols(fn_share ~ i(large_merger, post, ref = 0) | code_commune + year,
                  data = panel[treated == 1], cluster = ~dep)
cat(sprintf("Heterogeneity (median intensity = %.2f):\n", median_intensity))
summary(m_hetero)

## ============================================================================
## 6. Heterogeneity: Rural vs urban communes
## ============================================================================
cat("\n=== Heterogeneity: Rural vs urban ===\n")

## Use population as proxy (< 2000 = rural)
panel[, rural := as.integer(pop_commune < 2000)]

m_rural <- feols(fn_share ~ treat_post:i(rural) | code_commune + year,
                 data = panel, cluster = ~dep)
cat("Rural vs urban:\n")
summary(m_rural)

## ============================================================================
## 7. Save robustness model objects
## ============================================================================
save(m_epci_cluster, m_robust, m_metro, m_balanced,
     m_hetero, m_rural,
     file = file.path(data_dir, "robustness_objects.RData"))
cat("\nRobustness objects saved.\n")
