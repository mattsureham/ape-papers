## 04_robustness.R — Robustness checks
## apep_0759: Simplified to Compete

source("00_packages.R")

data_dir <- "../data"
contracts <- readRDS(file.path(data_dir, "contracts_clean.rds"))
contracts <- contracts[band %in% c("treated", "below_control")]

## ========================================================================
## 1. ALTERNATIVE CLUSTERING: Agency only
## ========================================================================
cat("\n=== Alternative clustering (agency only) ===\n")

alt_offers <- feols(n_offers_w ~ did | fyq + naics2 + agency,
                    data = contracts, cluster = ~agency)
alt_competed <- feols(fully_competed ~ did | fyq + naics2 + agency,
                      data = contracts, cluster = ~agency)
alt_sole <- feols(not_competed ~ did | fyq + naics2 + agency,
                  data = contracts, cluster = ~agency)

cat("Alt cluster (offers):", coef(alt_offers)["did"], "(se:", se(alt_offers)["did"], ")\n")
cat("Alt cluster (competed):", coef(alt_competed)["did"], "(se:", se(alt_competed)["did"], ")\n")
cat("Alt cluster (sole source):", coef(alt_sole)["did"], "(se:", se(alt_sole)["did"], ")\n")

## ========================================================================
## 2. NO AGENCY FE (simpler specification)
## ========================================================================
cat("\n=== No agency FE ===\n")

simple_offers <- feols(n_offers_w ~ did | fyq + naics2,
                       data = contracts, cluster = ~naics2 + fyq)
simple_competed <- feols(fully_competed ~ did | fyq + naics2,
                         data = contracts, cluster = ~naics2 + fyq)
simple_sole <- feols(not_competed ~ did | fyq + naics2,
                     data = contracts, cluster = ~naics2 + fyq)
simple_sb <- feols(small_business ~ did | fyq + naics2,
                   data = contracts, cluster = ~naics2 + fyq)

cat("Simple (offers):", coef(simple_offers)["did"], "\n")
cat("Simple (competed):", coef(simple_competed)["did"], "\n")
cat("Simple (sole source):", coef(simple_sole)["did"], "\n")

## ========================================================================
## 3. PLACEBO THRESHOLD at median of below-control band
## ========================================================================
cat("\n=== Placebo Threshold (median of below-control) ===\n")

below <- contracts[band == "below_control"]
med_val <- median(below$award_amount)
below[, placebo_treated := as.integer(award_amount >= med_val)]
below[, placebo_did := placebo_treated * post]

placebo_offers <- feols(n_offers_w ~ placebo_did | fyq + naics2,
                        data = below, cluster = ~naics2 + fyq)
placebo_competed <- feols(fully_competed ~ placebo_did | fyq + naics2,
                          data = below, cluster = ~naics2 + fyq)

cat("Placebo offers:", coef(placebo_offers)["placebo_did"], "(se:", se(placebo_offers)["placebo_did"], ")\n")
cat("Placebo competed:", coef(placebo_competed)["placebo_did"], "(se:", se(placebo_competed)["placebo_did"], ")\n")

## ========================================================================
## 4. HETEROGENEITY: Defense vs civilian
## ========================================================================
cat("\n=== Heterogeneity: Defense vs Civilian ===\n")

defense_agencies <- c("DEPARTMENT OF DEFENSE", "DEPT OF THE ARMY",
                      "DEPT OF THE NAVY", "DEPT OF THE AIR FORCE",
                      "DEFENSE LOGISTICS AGENCY")
contracts[, defense := as.integer(toupper(agency) %in% defense_agencies)]

het_offers <- feols(n_offers_w ~ did * defense | fyq + naics2,
                    data = contracts, cluster = ~naics2 + fyq)
het_competed <- feols(fully_competed ~ did * defense | fyq + naics2,
                      data = contracts, cluster = ~naics2 + fyq)

cat("Defense interaction (offers):", coef(het_offers)["did:defense"], "\n")
cat("Defense interaction (competed):", coef(het_competed)["did:defense"], "\n")

## ========================================================================
## 5. HETEROGENEITY: Services vs Goods
## ========================================================================
cat("\n=== Heterogeneity: Services vs Goods ===\n")

contracts[, services := as.integer(as.numeric(naics2) >= 50)]
het_services <- feols(n_offers_w ~ did * services | fyq + naics2,
                      data = contracts[!is.na(services)], cluster = ~naics2 + fyq)

cat("Services interaction (offers):", coef(het_services)["did:services"], "\n")

## ========================================================================
## SAVE
## ========================================================================

save(alt_offers, alt_competed, alt_sole,
     simple_offers, simple_competed, simple_sole, simple_sb,
     placebo_offers, placebo_competed,
     het_offers, het_competed,
     het_services,
     file = file.path(data_dir, "robustness_models.rda"))

cat("\nRobustness checks complete.\n")
