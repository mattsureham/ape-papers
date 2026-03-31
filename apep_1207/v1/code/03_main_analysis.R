# 03_main_analysis.R — Synthetic Control + DiD estimation
# apep_1207: Thailand Rice Pledging Scheme Collapse

source("00_packages.R")
library(fixest)
library(augsynth)

cat("=== Main Analysis ===\n")

# --- 1. Load data ---
scm_data <- read_csv("../data/scm_panel.csv", show_col_types = FALSE)
panel_clean <- read_csv("../data/panel_clean.csv", show_col_types = FALSE)

# --- 2. Augmented Synthetic Control: Cereal Production Index ---
cat("\n--- Specification 1: Augmented SCM — Cereal Production Index ---\n")

scm_cereal <- augsynth(
  cereal_index ~ treated,
  unit = iso2c,
  time = year,
  data = scm_data,
  t_int = 2014,
  progfunc = "Ridge",
  scm = TRUE
)

cat("SCM cereal production results:\n")
scm_cereal_summary <- summary(scm_cereal)
print(scm_cereal_summary)

# Extract ATT estimate
att_cereal <- scm_cereal_summary$att
cat(sprintf("\nATT (cereal index): %.2f\n", att_cereal$Estimate[1]))

# Get year-by-year effects for event study
scm_cereal_effects <- scm_cereal_summary$att
cat("\nYear-by-year effects:\n")
print(scm_cereal_effects)

# --- 3. Augmented SCM: Agriculture VA (% GDP) ---
cat("\n--- Specification 2: Augmented SCM — Agriculture VA (% GDP) ---\n")

scm_agri <- tryCatch({
  augsynth(
    agri_va_pct ~ treated,
    unit = iso2c,
    time = year,
    data = scm_data %>% filter(!is.na(agri_va_pct)),
    t_int = 2014,
    progfunc = "Ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat(sprintf("  SCM agri VA error: %s\n", e$message))
  NULL
})

if (!is.null(scm_agri)) {
  scm_agri_summary <- summary(scm_agri)
  cat("SCM agriculture VA results:\n")
  print(scm_agri_summary)
}

# --- 4. Augmented SCM: Agricultural Employment (%) ---
cat("\n--- Specification 3: Augmented SCM — Agricultural Employment ---\n")

scm_empl <- tryCatch({
  augsynth(
    agri_empl_pct ~ treated,
    unit = iso2c,
    time = year,
    data = scm_data %>% filter(!is.na(agri_empl_pct)),
    t_int = 2014,
    progfunc = "Ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat(sprintf("  SCM agri empl error: %s\n", e$message))
  NULL
})

if (!is.null(scm_empl)) {
  scm_empl_summary <- summary(scm_empl)
  cat("SCM agricultural employment results:\n")
  print(scm_empl_summary)
}

# --- 5. Augmented SCM: Cereal Yield ---
cat("\n--- Specification 4: Augmented SCM — Cereal Yield ---\n")

scm_yield <- tryCatch({
  augsynth(
    yield_index ~ treated,
    unit = iso2c,
    time = year,
    data = scm_data %>% filter(!is.na(yield_index)),
    t_int = 2014,
    progfunc = "Ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat(sprintf("  SCM yield error: %s\n", e$message))
  NULL
})

if (!is.null(scm_yield)) {
  scm_yield_summary <- summary(scm_yield)
  cat("SCM cereal yield results:\n")
  print(scm_yield_summary)
}

# --- 6. Cross-country DiD (complementary specification) ---
cat("\n--- Specification 5: Cross-country DiD ---\n")

# TWFE DiD: Thailand vs all donors
did_cereal <- feols(
  cereal_index ~ treat_x_post | iso2c + year,
  data = scm_data %>% mutate(treat_x_post = as.integer(iso2c == "TH") * as.integer(year >= 2014)),
  cluster = ~iso2c
)

cat("DiD cereal index:\n")
print(summary(did_cereal))

# Event study
scm_data_es <- scm_data %>%
  mutate(
    treated_unit = as.integer(iso2c == "TH"),
    event_time = year - 2014
  )

did_es <- feols(
  cereal_index ~ i(event_time, treated_unit, ref = -1) | iso2c + year,
  data = scm_data_es,
  cluster = ~iso2c
)

cat("\nEvent study coefficients:\n")
print(summary(did_es))

# --- 7. Mechanism: Structural transformation ---
cat("\n--- Mechanism: Structural transformation ---\n")

# Did agriculture shrink AND industry/services grow?
did_services <- feols(
  services_va_pct ~ treat_x_post | iso2c + year,
  data = scm_data %>%
    filter(!is.na(services_va_pct)) %>%
    mutate(treat_x_post = as.integer(iso2c == "TH") * as.integer(year >= 2014)),
  cluster = ~iso2c
)

cat("DiD services VA (%):\n")
print(summary(did_services))

did_industry <- feols(
  industry_va_pct ~ treat_x_post | iso2c + year,
  data = scm_data %>%
    filter(!is.na(industry_va_pct)) %>%
    mutate(treat_x_post = as.integer(iso2c == "TH") * as.integer(year >= 2014)),
  cluster = ~iso2c
)

cat("DiD industry VA (%):\n")
print(summary(did_industry))

# --- 8. Save results ---
results <- list(
  scm_cereal = scm_cereal,
  scm_agri = scm_agri,
  scm_empl = scm_empl,
  scm_yield = scm_yield,
  did_cereal = did_cereal,
  did_es = did_es,
  did_services = did_services,
  did_industry = did_industry
)

saveRDS(results, "../data/main_results.rds")

# --- 9. Diagnostics for validator ---
n_treated <- 1  # Thailand
n_donors <- n_distinct(scm_data$iso2c) - 1
n_pre <- sum(unique(scm_data$year) < 2014)
n_post <- sum(unique(scm_data$year) >= 2014)
n_obs <- nrow(scm_data)

diagnostics <- list(
  n_treated = n_treated,
  n_donors = n_donors,
  n_pre = n_pre,
  n_post = n_post,
  n_obs = n_obs,
  method = "Augmented Synthetic Control + Cross-country DiD",
  treatment_onset = 2014,
  outcome = "Cereal production index (2010=100)"
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("  Treated unit: Thailand\n"))
cat(sprintf("  Donor countries: %d\n", n_donors))
cat(sprintf("  Pre-treatment periods: %d (2005-2013)\n", n_pre))
cat(sprintf("  Post-treatment periods: %d (2014-2020)\n", n_post))
cat(sprintf("  Total observations: %d\n", n_obs))
