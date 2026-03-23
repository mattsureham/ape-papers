## 04_robustness.R — Robustness checks
source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- fread("../data/sector_panel.csv")
panel[, sector_id := as.integer(factor(sector))]
panel[, rel_year := year - 2008]

## ---- 1. Alternative pre-period (2003-2007) ----
cat("\n=== 1. Alternative pre-period shares (2003-2007) ===\n")

pre_alt <- panel[year %in% 2003:2007, .(
  ven_share_alt = mean(ven_share, na.rm = TRUE)
), by = sector]
panel_alt <- merge(panel, pre_alt, by = "sector")

fit_alt <- feols(log_world ~ ven_share_alt:post | sector_id + year,
                 data = panel_alt, cluster = ~sector_id)
cat("Alt pre-period: b=", round(coef(fit_alt), 3), " SE=", round(se(fit_alt), 3),
    " p=", round(fixest::pvalue(fit_alt), 4), "\n")

## ---- 2. Exclude fuels (commodity price confound) ----
cat("\n=== 2. Exclude Fuels ===\n")

panel_nofuel <- panel[sector != "27-27_Fuels"]
fit_nofuel <- feols(log_world ~ ven_share_pre:post | sector_id + year,
                    data = panel_nofuel, cluster = ~sector_id)
cat("No fuels: b=", round(coef(fit_nofuel), 3), " SE=", round(se(fit_nofuel), 3),
    " p=", round(fixest::pvalue(fit_nofuel), 4), "\n")

## ---- 3. Exclude top sector (leave-one-out) ----
cat("\n=== 3. Leave-one-out (drop top Venezuela sector) ===\n")

## Drop Animal (73% Venezuela share)
panel_nomax <- panel[sector != "01-05_Animal"]
fit_nomax <- feols(log_world ~ ven_share_pre:post | sector_id + year,
                   data = panel_nomax, cluster = ~sector_id)
cat("No animals: b=", round(coef(fit_nomax), 3), " SE=", round(se(fit_nomax), 3),
    " p=", round(fixest::pvalue(fit_nomax), 4), "\n")

## ---- 4. Border closure as sharp shock (post = 2015+) ----
cat("\n=== 4. Border Closure (2015+) ===\n")

panel[, post_2015 := as.integer(year >= 2015)]
fit_border <- feols(log_world ~ ven_share_pre:post_2015 | sector_id + year,
                    data = panel, cluster = ~sector_id)
cat("Border 2015: b=", round(coef(fit_border), 3), " SE=", round(se(fit_border), 3),
    " p=", round(fixest::pvalue(fit_border), 4), "\n")

## ---- 5. Pre-trend test: placebo post = 2005 ----
cat("\n=== 5. Placebo (post = 2005) ===\n")

panel_pre <- panel[year <= 2008]
panel_pre[, placebo_post := as.integer(year >= 2005)]
fit_placebo <- feols(log_world ~ ven_share_pre:placebo_post | sector_id + year,
                     data = panel_pre, cluster = ~sector_id)
cat("Placebo 2005: b=", round(coef(fit_placebo), 3), " SE=", round(se(fit_placebo), 3),
    " p=", round(fixest::pvalue(fit_placebo), 4), "\n")

## ---- 6. Level outcome instead of log ----
cat("\n=== 6. Level specification ===\n")

panel[, world_m := world_exports / 1000]  # millions USD
fit_level <- feols(world_m ~ ven_share_pre:post | sector_id + year,
                   data = panel, cluster = ~sector_id)
cat("Level (M USD): b=", round(coef(fit_level), 1), " SE=", round(se(fit_level), 1),
    " p=", round(fixest::pvalue(fit_level), 4), "\n")

## ---- 7. Non-Venezuela exports (diversification) — all specs ----
cat("\n=== 7. Diversification robustness ===\n")

fit_div_nofuel <- feols(log_nonven ~ ven_share_pre:post | sector_id + year,
                        data = panel_nofuel, cluster = ~sector_id)
cat("Non-Ven no fuel: b=", round(coef(fit_div_nofuel), 3), " SE=", round(se(fit_div_nofuel), 3),
    " p=", round(fixest::pvalue(fit_div_nofuel), 4), "\n")

fit_div_border <- feols(log_nonven ~ ven_share_pre:post_2015 | sector_id + year,
                        data = panel, cluster = ~sector_id)
cat("Non-Ven 2015: b=", round(coef(fit_div_border), 3), " SE=", round(se(fit_div_border), 3),
    " p=", round(fixest::pvalue(fit_div_border), 4), "\n")

## Save
rob_results <- list(
  fit_alt = fit_alt, fit_nofuel = fit_nofuel, fit_nomax = fit_nomax,
  fit_border = fit_border, fit_placebo = fit_placebo,
  fit_level = fit_level, fit_div_nofuel = fit_div_nofuel, fit_div_border = fit_div_border
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness complete ===\n")
