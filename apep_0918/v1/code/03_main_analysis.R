## 03_main_analysis.R — Main DiD estimation for ULEZ expansion effect on NO2
## APEP paper apep_0918: ULEZ expansion and NO2

source("code/00_packages.R")

panel <- fread("data/panel_clean.csv")
panel[, site_code := as.character(site_code)]
panel[, year_month := as.character(year_month)]

cat("=== Main Analysis ===\n")
cat(sprintf("  Observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Stations: %d (treated: %d, control: %d)\n",
            uniqueN(panel$site_code),
            uniqueN(panel[treat == 1]$site_code),
            uniqueN(panel[treat == 0]$site_code)))

## ---- 1. Two-way fixed effects DiD ----
cat("\n--- Model 1: TWFE DiD (NO2 levels) ---\n")
m1 <- feols(no2_mean ~ treat_post | site_code + year_month,
            data = panel, cluster = ~site_code)
print(summary(m1))

cat("\n--- Model 2: TWFE DiD (log NO2) ---\n")
m2 <- feols(ln_no2 ~ treat_post | site_code + year_month,
            data = panel, cluster = ~site_code)
print(summary(m2))

## ---- 2. Event study (fixest sunab-style with manual leads/lags) ----
cat("\n--- Model 3: Event study ---\n")

## Create relative time variable
## Treatment month = Nov 2021 = time_index 47
panel[, rel_time := time_index - 47L]

## Bin endpoints: lump <=-12 and >=12
panel[, rel_time_bin := pmax(-12L, pmin(12L, rel_time))]

## Reference period: t = -1
panel[treat == 1, event_treat := factor(rel_time_bin, levels = c(-1, setdiff(-12:12, -1)))]
panel[treat == 0, event_treat := factor(NA)]  # controls don't have events

## Event study with i() in fixest
m3 <- feols(no2_mean ~ i(rel_time_bin, treat, ref = -1) | site_code + year_month,
            data = panel, cluster = ~site_code)
print(summary(m3))

## ---- 3. Callaway-Sant'Anna DiD ----
cat("\n--- Model 4: Callaway-Sant'Anna ---\n")

## CS requires: yname, tname, idname, gname
## first_treat = 47 for inner London, 0 for never-treated
cs_data <- copy(panel)
cs_data[, id_num := as.integer(factor(site_code))]

cs_out <- tryCatch({
  att_gt(
    yname = "no2_mean",
    tname = "time_index",
    idname = "id_num",
    gname = "first_treat",
    data = as.data.frame(cs_data),
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("  CS estimation failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "simple")
  cat(sprintf("  CS ATT: %.3f (SE: %.3f)\n", cs_agg$overall.att, cs_agg$overall.se))

  cs_dynamic <- aggte(cs_out, type = "dynamic")
  cat("  Dynamic effects:\n")
  print(data.table(
    rel_time = cs_dynamic$egt,
    att = round(cs_dynamic$att.egt, 3),
    se = round(cs_dynamic$se.egt, 3)
  ))
}

## ---- 4. Dose-response by distance from boundary ----
cat("\n--- Model 5: Distance heterogeneity ---\n")

## Split inner stations by distance from boundary
panel[treat == 1, dist_cat := cut(abs(dist_boundary_km),
                                   breaks = c(0, 2, 4, Inf),
                                   labels = c("0-2km", "2-4km", ">4km"))]
panel[treat == 0, dist_cat := "Control"]

m5_near <- feols(no2_mean ~ treat_post | site_code + year_month,
                 data = panel[dist_cat %in% c("0-2km", "Control")],
                 cluster = ~site_code)
m5_mid <- feols(no2_mean ~ treat_post | site_code + year_month,
                data = panel[dist_cat %in% c("2-4km", "Control")],
                cluster = ~site_code)
m5_far <- feols(no2_mean ~ treat_post | site_code + year_month,
                data = panel[dist_cat %in% c(">4km", "Control")],
                cluster = ~site_code)

cat(sprintf("  Near boundary (0-2km): %.3f (%.3f)\n", coef(m5_near)["treat_post"], se(m5_near)["treat_post"]))
cat(sprintf("  Mid distance (2-4km): %.3f (%.3f)\n", coef(m5_mid)["treat_post"], se(m5_mid)["treat_post"]))
cat(sprintf("  Far from boundary (>4km): %.3f (%.3f)\n", coef(m5_far)["treat_post"], se(m5_far)["treat_post"]))

## ---- 5. By site type (roadside vs background) ----
cat("\n--- Model 6: Site type heterogeneity ---\n")

m6_road <- feols(no2_mean ~ treat_post | site_code + year_month,
                 data = panel[roadside == 1],
                 cluster = ~site_code)
m6_bg <- feols(no2_mean ~ treat_post | site_code + year_month,
               data = panel[roadside == 0],
               cluster = ~site_code)

cat(sprintf("  Roadside stations: %.3f (%.3f)\n", coef(m6_road)["treat_post"], se(m6_road)["treat_post"]))
cat(sprintf("  Background stations: %.3f (%.3f)\n", coef(m6_bg)["treat_post"], se(m6_bg)["treat_post"]))

## ---- 6. Save results ----
results <- list(
  twfe_level = m1,
  twfe_log = m2,
  event_study = m3,
  cs = cs_out,
  cs_agg = if (!is.null(cs_out)) cs_agg else NULL,
  cs_dynamic = if (!is.null(cs_out)) cs_dynamic else NULL,
  dist_near = m5_near,
  dist_mid = m5_mid,
  dist_far = m5_far,
  roadside = m6_road,
  background = m6_bg
)

saveRDS(results, "data/main_results.rds")

## Write diagnostics.json for validator
n_treated <- uniqueN(panel[treat == 1]$site_code)
n_pre <- uniqueN(panel[post == 0]$time_index)
n_obs <- nrow(panel)

write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n=== Results saved. n_treated=%d, n_pre=%d, n_obs=%d ===\n",
            n_treated, n_pre, n_obs))
