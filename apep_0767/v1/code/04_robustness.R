## 04_robustness.R — Robustness checks
source("00_packages.R")

cat("=== Robustness Checks ===\n")

results <- readRDS("../data/main_results.rds")
panel_low_agg <- results$panel_low_agg
panel_annual <- results$panel_annual

## ---- 1. Education subgroups separately ----
cat("\n=== 1. Education Subgroups ===\n")

panel_full <- fread("../data/panel_full.csv")
state_map <- data.table(state = unique(panel_full$state),
                        state_id = seq_along(unique(panel_full$state)))
panel_full <- merge(panel_full, state_map, by = "state")
panel_full <- panel_full[Emp > 0]
panel_full[, hire_rate := HirA / Emp]
panel_full[, sep_rate := Sep / Emp]
panel_full[, treated := as.integer(year >= adopt_year & adopt_year < 9999)]

for (ed in c("E1", "E2", "E3", "E4")) {
  sub <- panel_full[education == ed]
  sc <- sub[, .N, by = state_id]
  sub <- sub[state_id %in% sc[N >= floor(max(sc$N) * 0.9)]$state_id]
  fit <- feols(TurnOvrS ~ treated | state_id + time_idx, data = sub, cluster = ~state_id)
  cat(ed, ": b=", round(coef(fit), 5), " SE=", round(se(fit), 5),
      " p=", round(fixest::pvalue(fit), 4), " N=", nrow(sub), "\n")
}

## ---- 2. Exclude early adopters (2001) ----
cat("\n=== 2. Exclude Early Adopters (2001) ===\n")

panel_no_early <- panel_low_agg[adopt_year > 2001 | adopt_year == 9999]
fit_no_early <- feols(TurnOvrS ~ treated | state_id + time_idx, data = panel_no_early,
                      cluster = ~state_id)
cat("Excl 2001: b=", round(coef(fit_no_early), 5), " SE=", round(se(fit_no_early), 5),
    " p=", round(fixest::pvalue(fit_no_early), 4), "\n")

## ---- 3. Exclude Great Recession (2007-2009) ----
cat("\n=== 3. Exclude 2007-2009 ===\n")

panel_no_gr <- panel_low_agg[year < 2007 | year > 2009]
fit_no_gr <- feols(TurnOvrS ~ treated | state_id + time_idx, data = panel_no_gr,
                   cluster = ~state_id)
cat("Excl 2007-09: b=", round(coef(fit_no_gr), 5), " SE=", round(se(fit_no_gr), 5),
    " p=", round(fixest::pvalue(fit_no_gr), 4), "\n")

## ---- 4. State-specific linear trends ----
cat("\n=== 4. State-Specific Linear Trends ===\n")

panel_low_agg[, state_trend := state_id * time_idx]
fit_trends <- feols(TurnOvrS ~ treated | state_id[time_idx], data = panel_low_agg,
                    cluster = ~state_id)
cat("State trends: b=", round(coef(fit_trends), 5), " SE=", round(se(fit_trends), 5),
    " p=", round(fixest::pvalue(fit_trends), 4), "\n")

## ---- 5. Separate by adoption wave ----
cat("\n=== 5. By Adoption Wave ===\n")

panel_low_agg[, wave := fcase(
  adopt_year <= 2002, "Early (2001-2002)",
  adopt_year <= 2004, "Middle (2003-2004)",
  adopt_year <= 2009, "Late (2005-2009)",
  adopt_year >= 9999, "Never"
)]

for (w in c("Early (2001-2002)", "Middle (2003-2004)", "Late (2005-2009)")) {
  sub <- panel_low_agg[wave == w | wave == "Never" | (wave != w & treated == 0)]
  sub_w <- sub[wave == w | wave == "Never"]  # treated wave + never-treated
  if (nrow(sub_w) > 50) {
    fit_w <- feols(TurnOvrS ~ treated | state_id + time_idx, data = sub_w,
                   cluster = ~state_id)
    cat(w, ": b=", round(coef(fit_w), 5), " SE=", round(se(fit_w), 5),
        " p=", round(fixest::pvalue(fit_w), 4), "\n")
  }
}

## ---- 6. TWFE with year FE instead of quarter FE ----
cat("\n=== 6. Annual Specification ===\n")

fit_annual <- feols(TurnOvrS ~ treated | state_id + year, data = panel_annual,
                    cluster = ~state_id)
cat("Annual TWFE: b=", round(coef(fit_annual), 5), " SE=", round(se(fit_annual), 5),
    " p=", round(fixest::pvalue(fit_annual), 4), "\n")

## ---- 7. Industry heterogeneity (requires industry-level QWI) ----
## Not available in current data (would need industry-specific QWI pulls)
## Skip and note as limitation

## ---- Save robustness results ----
rob_results <- list(
  fit_no_early = fit_no_early,
  fit_no_gr = fit_no_gr,
  fit_trends = fit_trends,
  fit_annual = fit_annual
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
