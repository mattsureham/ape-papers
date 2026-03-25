## 04_robustness.R — Robustness checks and mechanism tests
## apep_0905: Argentina Aviation Deregulation

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel <- fread(file.path(data_dir, "route_month_panel.csv"))
panel_nocovid <- panel[covid == 0]

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ============================================================
## 1. Route x calendar-month FE (absorb seasonality)
## ============================================================

panel_nocovid[, cal_month := month(ym)]
panel_nocovid[, route_season := paste(route_id, cal_month, sep = "_")]

cat("--- 1. Route x Calendar-Month FE ---\n")
r1 <- feols(log_pax ~ monopoly:post | route_id + month_id + route_id[cal_month],
            data = panel_nocovid, cluster = ~route)
print(summary(r1))

r1_hhi <- feols(log_pax ~ hhi_norm:post | route_id + month_id + route_id[cal_month],
                data = panel_nocovid, cluster = ~route)
cat("\nContinuous HHI with route x season FE:\n")
print(summary(r1_hhi))

## ============================================================
## 2. Including COVID period
## ============================================================

cat("\n--- 2. Full sample (including COVID) ---\n")
r2 <- feols(log_pax ~ monopoly:post | route_id + month_id,
            data = panel, cluster = ~route)
print(summary(r2))

r2_hhi <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
                data = panel, cluster = ~route)
cat("\nContinuous HHI (full sample):\n")
print(summary(r2_hhi))

## ============================================================
## 3. Placebo: pseudo-treatment at July 2022
## ============================================================

cat("\n--- 3. Placebo at July 2022 ---\n")
panel_placebo <- panel_nocovid[ym < as.Date("2024-07-01")]
panel_placebo[, post_placebo := as.integer(ym >= as.Date("2022-07-01"))]

r3 <- feols(log_pax ~ monopoly:post_placebo | route_id + month_id,
            data = panel_placebo, cluster = ~route)
print(summary(r3))

r3_hhi <- feols(log_pax ~ hhi_norm:post_placebo | route_id + month_id,
                data = panel_placebo, cluster = ~route)
cat("\nPlacebo HHI:\n")
print(summary(r3_hhi))

## ============================================================
## 4. Exclude Buenos Aires hub routes
## ============================================================

cat("\n--- 4. Exclude BA hub routes ---\n")
ba_cities <- c("Buenos Aires", "Ciudad Autónoma de Buenos Aires")
panel_nocovid[, route_parts := strsplit(route, " - ")]
panel_nocovid[, is_ba := sapply(route_parts, function(x) any(x %in% ba_cities))]
panel_nocovid[, route_parts := NULL]

r4 <- feols(log_pax ~ monopoly:post | route_id + month_id,
            data = panel_nocovid[is_ba == FALSE], cluster = ~route)
cat("Non-BA routes:\n")
print(summary(r4))

r4_hhi <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
                data = panel_nocovid[is_ba == FALSE], cluster = ~route)
cat("\nNon-BA HHI:\n")
print(summary(r4_hhi))

## ============================================================
## 5. Heterogeneity by route size
## ============================================================

cat("\n--- 5. Heterogeneity by route size ---\n")
panel_nocovid[, large_route := as.integer(annual_pax > median(annual_pax, na.rm = TRUE))]

r5_large <- feols(log_pax ~ monopoly:post | route_id + month_id,
                  data = panel_nocovid[large_route == 1], cluster = ~route)
r5_small <- feols(log_pax ~ monopoly:post | route_id + month_id,
                  data = panel_nocovid[large_route == 0], cluster = ~route)

cat("Large routes:\n")
print(summary(r5_large))
cat("\nSmall routes:\n")
print(summary(r5_small))

## ============================================================
## 6. Outcomes: seats and flights (with route x season FE)
## ============================================================

cat("\n--- 6. Additional outcomes with route x season FE ---\n")

r6_seats <- feols(log_seats ~ monopoly:post | route_id + month_id + route_id[cal_month],
                  data = panel_nocovid, cluster = ~route)
r6_flights <- feols(log_flights ~ monopoly:post | route_id + month_id + route_id[cal_month],
                    data = panel_nocovid, cluster = ~route)
r6_airlines <- feols(n_airlines ~ monopoly:post | route_id + month_id + route_id[cal_month],
                     data = panel_nocovid, cluster = ~route)
r6_lf <- feols(load_factor ~ monopoly:post | route_id + month_id + route_id[cal_month],
               data = panel_nocovid[seats > 0], cluster = ~route)

etable(r6_seats, r6_flights, r6_airlines, r6_lf,
       headers = c("Log Seats", "Log Flights", "N Airlines", "Load Factor"),
       se.below = TRUE)

## ============================================================
## 7. Event study with route x season FE
## ============================================================

cat("\n--- 7. Event study with route x season FE ---\n")
panel_es <- panel_nocovid[event_month >= -36 & event_month <= 18]
panel_es[, cal_month := month(ym)]

es_season <- feols(log_pax ~ i(event_month, monopoly, ref = -1) |
                     route_id + month_id + route_id[cal_month],
                   data = panel_es, cluster = ~route)

# Extract coefficients for table
es_coefs <- as.data.table(broom::tidy(es_season))
es_coefs <- es_coefs[grep("event_month", term)]
es_coefs[, event_t := as.integer(gsub("event_month::(-?\\d+):monopoly", "\\1", term))]
es_coefs <- es_coefs[order(event_t)]

cat("\nEvent study coefficients (with route x season FE):\n")
print(es_coefs[, .(event_t, estimate, std.error, p.value)])

# Check pre-trend significance
pre_coefs <- es_coefs[event_t < -1]
cat("\nPre-treatment coefficients significantly different from zero (p<0.05):",
    sum(pre_coefs$p.value < 0.05), "out of", nrow(pre_coefs), "\n")

## ============================================================
## 8. Randomization inference (permute HHI across routes)
## ============================================================

cat("\n--- 8. Randomization inference ---\n")
set.seed(12345)
n_perms <- 500

actual_coef <- coef(feols(log_pax ~ hhi_norm:post | route_id + month_id,
                          data = panel_nocovid, cluster = ~route))[1]

route_hhi <- unique(panel_nocovid[, .(route, hhi_norm)])

ri_coefs <- numeric(n_perms)
for (i in 1:n_perms) {
  perm_hhi <- data.table(route = route_hhi$route,
                          hhi_norm_perm = sample(route_hhi$hhi_norm))
  panel_perm <- merge(panel_nocovid, perm_hhi, by = "route")

  ri_coefs[i] <- tryCatch({
    coef(feols(log_pax ~ hhi_norm_perm:post | route_id + month_id,
               data = panel_perm))[1]
  }, error = function(e) NA_real_)

  if (i %% 100 == 0) cat("RI iteration", i, "\n")
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("\nActual coefficient:", actual_coef, "\n")
cat("RI p-value (two-sided):", ri_pvalue, "\n")
cat("RI distribution: mean =", mean(ri_coefs, na.rm = TRUE),
    ", sd =", sd(ri_coefs, na.rm = TRUE), "\n")

## ============================================================
## 9. Save all robustness results
## ============================================================

robustness <- list(
  r1_season = r1, r1_hhi_season = r1_hhi,
  r2_full = r2, r2_hhi_full = r2_hhi,
  r3_placebo = r3, r3_hhi_placebo = r3_hhi,
  r4_noba = r4, r4_hhi_noba = r4_hhi,
  r5_large = r5_large, r5_small = r5_small,
  r6_seats = r6_seats, r6_flights = r6_flights,
  r6_airlines = r6_airlines, r6_lf = r6_lf,
  es_season = es_season, es_coefs = es_coefs,
  ri_pvalue = ri_pvalue, ri_coefs = ri_coefs,
  actual_coef = actual_coef
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n04_robustness.R complete.\n")
