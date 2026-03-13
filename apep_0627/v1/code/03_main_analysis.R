## 03_main_analysis.R — Main DiD analysis
## APEP paper apep_0627: Wales 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "la_month_panel.csv"))

# Ensure factors
panel[, `:=`(
  la_factor = factor(la_code),
  ym        = factor(paste0(year, "-", sprintf("%02d", month)))
)]

## ------------------------------------------------------------------
## 1. Main DiD: Welsh × Post
## ------------------------------------------------------------------
cat("\n=== MAIN DiD RESULTS ===\n")

# (1) Total collisions
m1_total <- feols(
  n_collisions ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)
cat("\n--- Total Collisions ---\n")
print(summary(m1_total))

# (2) KSI (killed or seriously injured)
m1_ksi <- feols(
  n_ksi ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)
cat("\n--- KSI ---\n")
print(summary(m1_ksi))

# (3) Pedestrian KSI
m1_ped <- feols(
  n_ped_ksi ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)
cat("\n--- Pedestrian KSI ---\n")
print(summary(m1_ped))

# (4) Restricted road collisions only
m1_restricted <- feols(
  n_restricted ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)
cat("\n--- Restricted Road Collisions ---\n")
print(summary(m1_restricted))

# (5) High-speed road collisions (placebo — should be null)
m1_highspeed <- feols(
  n_highspeed ~ welsh:post | la_factor + ym,
  data = panel,
  cluster = ~la_code
)
cat("\n--- High-Speed Road Collisions (Placebo) ---\n")
print(summary(m1_highspeed))

## ------------------------------------------------------------------
## 2. Event study
## ------------------------------------------------------------------
cat("\n=== EVENT STUDY ===\n")

# Create relative time indicators (omit t = -1, i.e., August 2023)
# Cap at -12 and +12 for readability
panel[, rel_month_capped := pmax(pmin(rel_month, 15), -24)]

# Event study for KSI
es_ksi <- feols(
  n_ksi ~ i(rel_month_capped, welsh, ref = -1) | la_factor + ym,
  data = panel,
  cluster = ~la_code
)
cat("\n--- Event Study: KSI ---\n")
print(summary(es_ksi))

# Event study for total collisions
es_total <- feols(
  n_collisions ~ i(rel_month_capped, welsh, ref = -1) | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

# Event study for pedestrian KSI
es_ped <- feols(
  n_ped_ksi ~ i(rel_month_capped, welsh, ref = -1) | la_factor + ym,
  data = panel,
  cluster = ~la_code
)

## ------------------------------------------------------------------
## 3. Compute effect sizes and percentages
## ------------------------------------------------------------------
cat("\n=== EFFECT SIZE INTERPRETATION ===\n")

# Pre-treatment Welsh means
welsh_pre_means <- panel[welsh == 1 & post == 0, .(
  mean_collisions = mean(n_collisions),
  mean_ksi        = mean(n_ksi),
  mean_ped_ksi    = mean(n_ped_ksi),
  mean_restricted = mean(n_restricted),
  sd_collisions   = sd(n_collisions),
  sd_ksi          = sd(n_ksi),
  sd_ped_ksi      = sd(n_ped_ksi)
)]

cat("Welsh pre-treatment monthly means per LA:\n")
print(welsh_pre_means)

# Percentage effects
beta_total <- coef(m1_total)["welsh:post"]
beta_ksi <- coef(m1_ksi)["welsh:post"]
beta_ped <- coef(m1_ped)["welsh:post"]

pct_total <- 100 * beta_total / welsh_pre_means$mean_collisions
pct_ksi <- 100 * beta_ksi / welsh_pre_means$mean_ksi
pct_ped <- 100 * beta_ped / welsh_pre_means$mean_ped_ksi

cat("\nPercentage effects (relative to Welsh pre-treatment mean):\n")
cat("  Total collisions:", round(pct_total, 1), "%\n")
cat("  KSI:", round(pct_ksi, 1), "%\n")
cat("  Pedestrian KSI:", round(pct_ped, 1), "%\n")

## ------------------------------------------------------------------
## 4. Save results
## ------------------------------------------------------------------

# Save main models for table generation
save(
  m1_total, m1_ksi, m1_ped, m1_restricted, m1_highspeed,
  es_ksi, es_total, es_ped,
  welsh_pre_means,
  file = file.path(data_dir, "main_results.RData")
)

# Write diagnostics.json for validator
n_welsh_las <- uniqueN(panel[welsh == 1]$la_code)
n_pre_months <- uniqueN(panel[post == 0]$ym)

diagnostics <- list(
  n_treated = n_welsh_las,
  n_pre     = n_pre_months,
  n_obs     = nrow(panel)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics written:", toJSON(diagnostics, auto_unbox = TRUE), "\n")

cat("\nMain analysis complete.\n")
