## 03_main_analysis.R — Continuous-treatment DiD
source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- fread("../data/sector_panel.csv")
wb <- fread("../data/wb_wide.csv")

## Create sector numeric ID
panel[, sector_id := as.integer(factor(sector))]

## ---- MAIN RESULT: Effect of Venezuela dependence on total exports ----
cat("\n=== Panel A: Effect on Total Sector Exports ===\n")

## Continuous-treatment DiD:
## log(WorldExports_{st}) = α_s + δ_t + β × (VenSharePre_s × Post_t) + ε_{st}

twfe_world <- feols(log_world ~ ven_share_pre:post | sector_id + year,
                    data = panel, cluster = ~sector_id)
cat("Total exports (TWFE):\n")
summary(twfe_world)

## ---- Effect on Venezuela-specific exports ----
cat("\n=== Panel B: Venezuela Exports ===\n")

twfe_ven <- feols(log_ven ~ ven_share_pre:post | sector_id + year,
                  data = panel, cluster = ~sector_id)
cat("Venezuela exports:\n")
summary(twfe_ven)

## ---- Effect on non-Venezuela exports (diversification) ----
cat("\n=== Panel C: Non-Venezuela Exports (Diversification) ===\n")

twfe_nonven <- feols(log_nonven ~ ven_share_pre:post | sector_id + year,
                     data = panel, cluster = ~sector_id)
cat("Non-Venezuela exports:\n")
summary(twfe_nonven)

## ---- Event study specification ----
cat("\n=== Event Study ===\n")

## Create relative year indicators (reference: 2008)
panel[, rel_year := year - 2008]

## Interact ven_share_pre with year dummies (reference: 2008, i.e. rel_year=0)
es_world <- feols(log_world ~ i(rel_year, ven_share_pre, ref = 0) | sector_id + year,
                  data = panel, cluster = ~sector_id)
cat("Event study (total exports):\n")
summary(es_world)

## ---- Destination HHI (concentration of export markets) ----
cat("\n=== Panel D: Export Destination Concentration ===\n")

## Higher HHI = more concentrated = less diversified
twfe_hhi <- feols(dest_hhi ~ ven_share_pre:post | sector_id + year,
                  data = panel[!is.na(dest_hhi)], cluster = ~sector_id)
cat("Destination HHI:\n")
summary(twfe_hhi)

## ---- Growth relative to 2008 ----
cat("\n=== Growth Analysis ===\n")

twfe_growth <- feols(growth_world ~ ven_share_pre:post | sector_id + year,
                     data = panel[year >= 2002], cluster = ~sector_id)
cat("Growth (total, relative to 2008):\n")
summary(twfe_growth)

## ---- Save results ----
results <- list(
  twfe_world = twfe_world,
  twfe_ven = twfe_ven,
  twfe_nonven = twfe_nonven,
  twfe_hhi = twfe_hhi,
  twfe_growth = twfe_growth,
  es_world = es_world,
  panel = panel
)
saveRDS(results, "../data/main_results.rds")

## Diagnostics for validator
diagnostics <- list(
  n_treated = uniqueN(panel[ven_share_pre > 0.10]$sector_id),
  n_pre = length(unique(panel[year < 2009]$year)),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:", paste(names(diagnostics), diagnostics, sep = "=", collapse = ", "), "\n")

## ---- Key results summary ----
cat("\n=== KEY RESULTS ===\n")
cat("Total exports:     b=", round(coef(twfe_world), 3), " SE=", round(se(twfe_world), 3),
    " p=", round(fixest::pvalue(twfe_world), 4), "\n")
cat("Venezuela exports: b=", round(coef(twfe_ven), 3), " SE=", round(se(twfe_ven), 3),
    " p=", round(fixest::pvalue(twfe_ven), 4), "\n")
cat("Non-Ven exports:   b=", round(coef(twfe_nonven), 3), " SE=", round(se(twfe_nonven), 3),
    " p=", round(fixest::pvalue(twfe_nonven), 4), "\n")
cat("Dest HHI:          b=", round(coef(twfe_hhi), 3), " SE=", round(se(twfe_hhi), 3),
    " p=", round(fixest::pvalue(twfe_hhi), 4), "\n")

cat("\n=== Main analysis complete ===\n")
