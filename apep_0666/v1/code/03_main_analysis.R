## 03_main_analysis.R — Main DiD analysis
## apep_0666: EU smoking bans

source("code/00_packages.R")
panel <- readRDS("data/panel.rds")

cat("=== Main Analysis ===\n")

## ---- 1. DiD on hospitality sector (G-I) ----
hosp <- panel %>% filter(sector == "G-I")

# TWFE
m1 <- feols(ln_emp ~ treat_post | country + year,
            data = hosp, cluster = ~country)
cat("M1 (TWFE, hospitality employment):\n"); print(summary(m1))

## ---- 2. CS-DiD on hospitality ----
cs_data <- hosp %>%
  group_by(country) %>%
  mutate(n_years = n()) %>%
  ungroup() %>%
  filter(n_years == max(n_years))  # Balanced panel

cs_result <- tryCatch({
  att_gt(
    yname = "ln_emp",
    tname = "year",
    idname = "country_id",
    gname = "first_treat",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_result)) {
  cat("\n--- CS-DiD group-time ATTs ---\n")
  print(summary(cs_result))

  cs_overall <- aggte(cs_result, type = "simple")
  cat("\n--- CS-DiD Overall ATT ---\n")
  print(summary(cs_overall))

  cs_event <- tryCatch(
    aggte(cs_result, type = "dynamic", min_e = -5, max_e = 10),
    error = function(e) aggte(cs_result, type = "dynamic")
  )
  cat("\n--- CS-DiD Event Study ---\n")
  print(summary(cs_event))
} else {
  cs_overall <- NULL
  cs_event <- NULL
}

## ---- 3. Triple-DiD: hospitality vs placebo sectors ----
# Compare hospitality (G-I) vs control sectors (J, K, M_N)
panel_ddd <- panel %>%
  filter(sector %in% c("G-I", "J", "K", "M_N"))

m_ddd <- feols(ln_emp ~ triple_did + treat_post | country + year + sector,
               data = panel_ddd, cluster = ~country)
cat("\n--- Triple-DiD (hospitality vs control sectors) ---\n")
print(summary(m_ddd))

## ---- 4. Placebo: Non-hospitality sectors individually ----
for (s in c("J", "K", "M_N")) {
  df_s <- panel %>% filter(sector == s)
  fit_s <- feols(ln_emp ~ treat_post | country + year,
                 data = df_s, cluster = ~country)
  cat(sprintf("\nPlacebo sector %s:\n", s))
  print(summary(fit_s))
}

## ---- 5. Employment share as outcome ----
m_share <- feols(emp_share ~ treat_post | country + year,
                 data = hosp %>% filter(!is.na(emp_share)),
                 cluster = ~country)
cat("\n--- Hospitality employment SHARE ---\n")
print(summary(m_share))

## ---- 6. Hours per worker ----
m_hours <- feols(ln_hours_pw ~ treat_post | country + year,
                 data = hosp %>% filter(!is.na(ln_hours_pw)),
                 cluster = ~country)
cat("\n--- Hours per worker (hospitality) ---\n")
print(summary(m_hours))

## ---- Save ----
results <- list(
  m1 = m1, cs_result = cs_result, cs_overall = cs_overall,
  cs_event = cs_event, m_ddd = m_ddd, m_share = m_share,
  m_hours = m_hours
)
saveRDS(results, "data/results_main.rds")

## Diagnostics
diag <- list(
  n_treated = length(unique(hosp$country[hosp$treated == 1])),
  n_pre = length(unique(hosp$year[hosp$year < 2004])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", paste(names(diag), "=", diag, collapse=", "), "\n")
