## 04_robustness.R — Robustness checks for Panic of 1907 occupational scarring
## NOTE: Memory-aware design. Run one model at a time and save coefficients.
source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_data.rds"))

cat("=== Robustness checks ===\n")
cat("Panel:", formatC(nrow(panel), big.mark = ","), "observations\n")

# Helper: extract and store key coefficients to avoid holding large model objects
extract_coefs <- function(mod, label = "") {
  cfs <- data.table(
    variable = names(coef(mod)),
    estimate = coef(mod),
    se = se(mod),
    pvalue = pvalue(mod)
  )
  cfs[, label := label]
  cfs
}

all_coefs <- list()

# ============================================================================
# 1. Exclude New York (cross-state)
# ============================================================================
cat("\n=== Robustness 1: Exclude New York ===\n")

panel_no_ny <- panel[statefip_1900 != 36]
cat("Observations without NY:", formatC(nrow(panel_no_ny), big.mark = ","), "\n")

r1_no_ny_xs <- feols(delta_occscore ~ panic_severity + age_1900 + age_1900_sq +
                       white + foreign_born + literate_1900 + married_1900 + occscore_1900,
                     data = panel_no_ny, cluster = ~statefip_1900)
cat("Exclude NY (cross-state):\n")
cat("  panic_severity:", round(coef(r1_no_ny_xs)["panic_severity"], 4),
    "(SE:", round(se(r1_no_ny_xs)["panic_severity"], 4), ")\n")
all_coefs[["r1_no_ny_xs"]] <- extract_coefs(r1_no_ny_xs, "Excl. NY (XS)")

# DDD without NY — use lean=TRUE and smaller data
gc()
r1_no_ny_ddd <- feols(delta_occscore ~ panic_severity * banking_dependent +
                        age_1900 + age_1900_sq + white + foreign_born +
                        literate_1900 + married_1900 + occscore_1900 |
                        statefip_1900,
                      data = panel_no_ny, cluster = ~statefip_1900, lean = TRUE)
cat("Exclude NY (DDD interaction):",
    round(coef(r1_no_ny_ddd)["panic_severity:banking_dependentTRUE"], 4),
    "(SE:", round(se(r1_no_ny_ddd)["panic_severity:banking_dependentTRUE"], 4), ")\n")
all_coefs[["r1_no_ny_ddd"]] <- extract_coefs(r1_no_ny_ddd, "Excl. NY (DDD)")
rm(panel_no_ny); gc()

# ============================================================================
# 2. Binary treatment: Core panic vs rest
# ============================================================================
cat("\n=== Robustness 2: Binary treatment (core panic vs rest) ===\n")

r2_binary_xs <- feols(delta_occscore ~ core_panic + age_1900 + age_1900_sq +
                        white + foreign_born + literate_1900 + married_1900 + occscore_1900,
                      data = panel, cluster = ~statefip_1900)
cat("Binary treatment (cross-state):",
    round(coef(r2_binary_xs)["core_panic"], 4),
    "(SE:", round(se(r2_binary_xs)["core_panic"], 4), ")\n")
all_coefs[["r2_binary_xs"]] <- extract_coefs(r2_binary_xs, "Binary (XS)")

gc()
r2_binary_ddd <- feols(delta_occscore ~ core_panic * banking_dependent +
                         age_1900 + age_1900_sq + white + foreign_born +
                         literate_1900 + married_1900 + occscore_1900 |
                         statefip_1900,
                       data = panel, cluster = ~statefip_1900, lean = TRUE)
cat("Binary DDD interaction:",
    round(coef(r2_binary_ddd)["core_panic:banking_dependentTRUE"], 4),
    "(SE:", round(se(r2_binary_ddd)["core_panic:banking_dependentTRUE"], 4), ")\n")
all_coefs[["r2_binary_ddd"]] <- extract_coefs(r2_binary_ddd, "Binary (DDD)")
gc()

# ============================================================================
# 3. Control for county-level urbanization (farm share)
# ============================================================================
cat("\n=== Robustness 3: County urbanization control ===\n")

r3_urban_xs <- feols(delta_occscore ~ panic_severity + county_farm_share +
                       age_1900 + age_1900_sq + white + foreign_born +
                       literate_1900 + married_1900 + occscore_1900,
                     data = panel, cluster = ~statefip_1900)
cat("With county farm share (cross-state):",
    round(coef(r3_urban_xs)["panic_severity"], 4),
    "(SE:", round(se(r3_urban_xs)["panic_severity"], 4), ")\n")
all_coefs[["r3_urban_xs"]] <- extract_coefs(r3_urban_xs, "+Farm share (XS)")

gc()
r3_urban_ddd <- feols(delta_occscore ~ panic_severity * banking_dependent +
                        county_farm_share +
                        age_1900 + age_1900_sq + white + foreign_born +
                        literate_1900 + married_1900 + occscore_1900 |
                        statefip_1900,
                      data = panel, cluster = ~statefip_1900, lean = TRUE)
cat("DDD with county farm share:",
    round(coef(r3_urban_ddd)["panic_severity:banking_dependentTRUE"], 4),
    "(SE:", round(se(r3_urban_ddd)["panic_severity:banking_dependentTRUE"], 4), ")\n")
all_coefs[["r3_urban_ddd"]] <- extract_coefs(r3_urban_ddd, "+Farm share (DDD)")
gc()

# ============================================================================
# 4. Placebo: Literacy change
# ============================================================================
cat("\n=== Robustness 4: Placebo — literacy change ===\n")

r4_placebo_xs <- feols(delta_literate ~ panic_severity + age_1900 + age_1900_sq +
                         white + foreign_born + literate_1900 + married_1900 + occscore_1900,
                       data = panel, cluster = ~statefip_1900)
cat("Placebo — literacy (cross-state):",
    round(coef(r4_placebo_xs)["panic_severity"], 5),
    "(SE:", round(se(r4_placebo_xs)["panic_severity"], 5), ")\n")
all_coefs[["r4_placebo_xs"]] <- extract_coefs(r4_placebo_xs, "Placebo: Lit (XS)")

gc()
r4_placebo_ddd <- feols(delta_literate ~ panic_severity * banking_dependent +
                          age_1900 + age_1900_sq + white + foreign_born +
                          literate_1900 + married_1900 + occscore_1900 |
                          statefip_1900,
                        data = panel, cluster = ~statefip_1900, lean = TRUE)
pl_cn <- grep("panic.*banking", names(coef(r4_placebo_ddd)), value = TRUE)
pl_cn <- pl_cn[grepl(":", pl_cn)]
if (length(pl_cn) > 0) {
  cat("Placebo DDD:", round(coef(r4_placebo_ddd)[pl_cn[1]], 5),
      "(SE:", round(se(r4_placebo_ddd)[pl_cn[1]], 5), ")\n")
}
all_coefs[["r4_placebo_ddd"]] <- extract_coefs(r4_placebo_ddd, "Placebo: Lit (DDD)")
gc()

# ============================================================================
# 5. Additional sample restrictions (cross-state only — DDD too memory-heavy)
# ============================================================================
cat("\n=== Robustness 5: Sample restrictions ===\n")

# 5a. Workers with nonzero occscore
panel_workers <- panel[occscore_1900 > 0 & occscore_1910 > 0]
r5a_xs <- feols(delta_occscore ~ panic_severity + age_1900 + age_1900_sq +
                  white + foreign_born + literate_1900 + married_1900 + occscore_1900,
                data = panel_workers, cluster = ~statefip_1900)
cat("Workers only:", formatC(nrow(panel_workers), big.mark = ","), "obs\n")
cat("  panic_severity:", round(coef(r5a_xs)["panic_severity"], 4),
    "(SE:", round(se(r5a_xs)["panic_severity"], 4), ")\n")
all_coefs[["r5a_workers_xs"]] <- extract_coefs(r5a_xs, "Workers only")
rm(panel_workers); gc()

# 5b. Non-movers (same state)
panel_stayers <- panel[statefip_1900 == statefip_1910]
r5b_xs <- feols(delta_occscore ~ panic_severity + age_1900 + age_1900_sq +
                  white + foreign_born + literate_1900 + married_1900 + occscore_1900,
                data = panel_stayers, cluster = ~statefip_1900)
cat("Stayers only:", formatC(nrow(panel_stayers), big.mark = ","), "obs\n")
cat("  panic_severity:", round(coef(r5b_xs)["panic_severity"], 4),
    "(SE:", round(se(r5b_xs)["panic_severity"], 4), ")\n")
all_coefs[["r5b_stayers_xs"]] <- extract_coefs(r5b_xs, "Stayers only")
rm(panel_stayers); gc()

# 5c. Native-born whites only
panel_nw <- panel[white == 1 & foreign_born == 0]
r5c_xs <- feols(delta_occscore ~ panic_severity + age_1900 + age_1900_sq +
                  literate_1900 + married_1900 + occscore_1900,
                data = panel_nw, cluster = ~statefip_1900)
cat("Native-born whites:", formatC(nrow(panel_nw), big.mark = ","), "obs\n")
cat("  panic_severity:", round(coef(r5c_xs)["panic_severity"], 4),
    "(SE:", round(se(r5c_xs)["panic_severity"], 4), ")\n")
all_coefs[["r5c_nw_xs"]] <- extract_coefs(r5c_xs, "Native-born whites")
rm(panel_nw); gc()

# ============================================================================
# 6. Save robustness results
# ============================================================================
# Store model objects (only the small ones without lean=TRUE)
robustness <- list(
  r1_no_ny_xs = r1_no_ny_xs,
  r1_no_ny_ddd = r1_no_ny_ddd,
  r2_binary_xs = r2_binary_xs,
  r2_binary_ddd = r2_binary_ddd,
  r3_urban_xs = r3_urban_xs,
  r3_urban_ddd = r3_urban_ddd,
  r4_placebo_xs = r4_placebo_xs,
  r4_placebo_ddd = r4_placebo_ddd,
  r5a_workers_xs = r5a_xs,
  r5b_stayers_xs = r5b_xs,
  r5c_nw_xs = r5c_xs,
  all_coefs = rbindlist(all_coefs)
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness summary ===\n")
cat("Cross-state coefficients:\n")
for (nm in c("r1_no_ny_xs", "r3_urban_xs", "r5a_workers_xs",
             "r5b_stayers_xs", "r5c_nw_xs")) {
  mod <- robustness[[nm]]
  b <- coef(mod)["panic_severity"]
  s <- se(mod)["panic_severity"]
  p <- pvalue(mod)["panic_severity"]
  cat(sprintf("  %-18s: %7.4f (%6.4f) [p=%.4f]\n", nm, b, s, p))
}

cat("\nBinary treatment:")
cat(sprintf(" %7.4f (%6.4f)\n",
            coef(r2_binary_xs)["core_panic"], se(r2_binary_xs)["core_panic"]))

cat("\nDDD interactions:\n")
for (nm in c("r1_no_ny_ddd", "r2_binary_ddd", "r3_urban_ddd")) {
  mod <- robustness[[nm]]
  cn <- grep("panic.*banking|core.*banking", names(coef(mod)), value = TRUE)
  cn <- cn[grepl(":", cn)]
  if (length(cn) > 0) {
    cat(sprintf("  %-18s: %7.4f (%6.4f) [p=%.6f]\n",
                nm, coef(mod)[cn[1]], se(mod)[cn[1]], pvalue(mod)[cn[1]]))
  }
}

cat("\nPlacebo (literacy):\n")
cat("  Cross-state:", round(coef(r4_placebo_xs)["panic_severity"], 5),
    " (SE:", round(se(r4_placebo_xs)["panic_severity"], 5), ")\n")
if (length(pl_cn) > 0) {
  cat("  DDD:", round(coef(r4_placebo_ddd)[pl_cn[1]], 5),
      " (SE:", round(se(r4_placebo_ddd)[pl_cn[1]], 5), ")\n")
}

cat("\nRobustness checks complete.\n")
