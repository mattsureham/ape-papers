# 03_main_analysis.R — Main econometric analysis
# apep_1127: Injection well volume regulations and induced seismicity

source("00_packages.R")

cat("=== Loading panel data ===\n")
panel <- read_csv("../data/panel_ok.csv", show_col_types = FALSE)

# =============================================================================
# 1. DESCRIPTIVE: Annual earthquake counts by treatment status
# =============================================================================

cat("\n=== Descriptive statistics ===\n")

annual_by_treat <- panel |>
  group_by(year, treated_county) |>
  summarise(
    total_quakes = sum(n_quakes),
    mean_quakes = mean(n_quakes),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  )
cat("Annual earthquake counts by treatment status:\n")
print(annual_by_treat |> pivot_wider(names_from = treated_county,
                                      values_from = c(total_quakes, mean_quakes)),
      n = 20)

# =============================================================================
# 2. CALLAWAY & SANT'ANNA (2021) — Primary specification
# =============================================================================

cat("\n=== Callaway & Sant'Anna DiD ===\n")

# Filter to counties with any seismic activity OR treated status
# (removes counties with zero earthquakes in all periods that add noise)
active_counties <- panel |>
  group_by(county_fips) |>
  summarise(total = sum(n_quakes), treated = any(treated_county), .groups = "drop") |>
  filter(total > 0 | treated)

panel_active <- panel |>
  filter(county_fips %in% active_counties$county_fips)

cat(sprintf("Active panel: %d counties (%d treated, %d control)\n",
            n_distinct(panel_active$county_fips),
            sum(panel_active$treated_county[!duplicated(panel_active$county_fips)]),
            sum(!panel_active$treated_county[!duplicated(panel_active$county_fips)])))

# Quarterly aggregation for CS (reduces noise, standard in seismicity literature)
panel_q <- panel_active |>
  mutate(quarter = ceiling(month / 3),
         yq = year + (quarter - 1) / 4,
         yq_int = year * 4 + quarter) |>
  group_by(county_fips, yq_int, yq, year, quarter, treated_county, first_treat_ym) |>
  summarise(
    n_quakes = sum(n_quakes),
    n_quakes_m3 = sum(n_quakes_m3, na.rm = TRUE),
    wti_price = mean(wti_price, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    ihs_quakes = log(n_quakes + sqrt(n_quakes^2 + 1)),
    log_quakes_p1 = log(n_quakes + 1),
    # Convert first_treat_ym (months) to quarter index
    first_treat_yq = ifelse(first_treat_ym == 0, 0,
                            floor((first_treat_ym - 1) / 3) * 3 / 12 +
                            ceiling(((first_treat_ym - 1) %% 12 + 1) / 3) / 4 +
                            floor((first_treat_ym - 1) / 12))
  )

# Simpler first_treat_yq: convert month to quarter integer
panel_q <- panel_q |>
  mutate(
    first_treat_yq_int = ifelse(first_treat_ym == 0, 0,
                                 (floor((first_treat_ym - 1) / 12)) * 4 +
                                 ceiling(((first_treat_ym - 1) %% 12 + 1) / 3))
  )

# CS estimation on IHS-transformed earthquake counts
cs_out <- att_gt(
  yname = "ihs_quakes",
  tname = "yq_int",
  idname = "county_fips",
  gname = "first_treat_yq_int",
  data = panel_q |> mutate(county_fips = as.numeric(factor(county_fips))),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

cat("\nCS group-time ATTs:\n")
summary(cs_out)

# Aggregate to event-study
es_out <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 16)
cat("\nEvent study estimates:\n")
summary(es_out)

# Overall ATT
att_overall <- aggte(cs_out, type = "simple")
cat("\nOverall ATT:\n")
summary(att_overall)

# Save CS results
saveRDS(cs_out, "../data/cs_results.rds")
saveRDS(es_out, "../data/es_results.rds")
saveRDS(att_overall, "../data/att_overall.rds")

# =============================================================================
# 3. TWFE FIXED EFFECTS (for comparison and additional specifications)
# =============================================================================

cat("\n=== TWFE Regressions (fixest) ===\n")

# Monthly panel with fixest
panel_fe <- panel_active |>
  mutate(
    county_id = as.numeric(factor(county_fips)),
    post_treat = as.numeric(treat_post)
  )

# Spec 1: Basic TWFE
m1 <- feols(ihs_quakes ~ post_treat | county_fips + year_month,
            data = panel_fe, cluster = "county_fips")

# Spec 2: Add WTI oil price control
m2 <- feols(ihs_quakes ~ post_treat + wti_price | county_fips + year_month,
            data = panel_fe, cluster = "county_fips")

# Spec 3: Level count (Poisson)
m3 <- fepois(n_quakes ~ post_treat | county_fips + year_month,
             data = panel_fe, cluster = "county_fips")

# Spec 4: Log(count + 1)
m4 <- feols(log_quakes_p1 ~ post_treat | county_fips + year_month,
            data = panel_fe, cluster = "county_fips")

cat("\nTWFE results:\n")
etable(m1, m2, m3, m4,
       headers = c("IHS", "IHS+WTI", "Poisson", "Log(Y+1)"),
       se.below = TRUE)

# Save TWFE results
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4), "../data/twfe_results.rds")

# =============================================================================
# 4. EVENT STUDY (TWFE version for comparison)
# =============================================================================

cat("\n=== TWFE Event Study ===\n")

panel_fe <- panel_fe |>
  mutate(
    first_treat_date = as.Date(ifelse(first_treat_ym > 0,
                                       sprintf("%d-%02d-01",
                                               floor((first_treat_ym - 1) / 12),
                                               ((first_treat_ym - 1) %% 12) + 1),
                                       NA), origin = "1970-01-01"),
    rel_month = ifelse(first_treat_ym > 0, ym_numeric - first_treat_ym, NA)
  )

# Bin endpoints
panel_fe <- panel_fe |>
  mutate(rel_month_binned = case_when(
    is.na(rel_month) ~ NA_real_,
    rel_month < -24 ~ -24,
    rel_month > 36 ~ 36,
    TRUE ~ rel_month
  ))

# Event study with fixest sunab()
es_twfe <- feols(ihs_quakes ~ sunab(first_treat_ym, ym_numeric) | county_fips + year_month,
                 data = panel_fe |> filter(first_treat_ym > 0 | treated_county == FALSE),
                 cluster = "county_fips")

cat("\nSun-Abraham event study:\n")
summary(es_twfe)

saveRDS(es_twfe, "../data/es_twfe.rds")

# =============================================================================
# 5. DIAGNOSTICS for validator
# =============================================================================

n_treated <- n_distinct(panel_fe$county_fips[panel_fe$treated_county])
n_pre <- length(unique(panel_fe$year[panel_fe$year < 2015]))
n_obs <- nrow(panel_fe)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_distinct(panel_fe$county_fips[!panel_fe$treated_county]),
  n_months = n_distinct(panel_fe$year_month),
  att_overall = att_overall$overall.att,
  att_se = att_overall$overall.se
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

cat("\n=== Main analysis complete ===\n")
