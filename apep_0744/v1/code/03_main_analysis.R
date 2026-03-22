# 03_main_analysis.R — DiD estimation: Wales 20mph and road safety
# apep_0744

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# Load panels
# ============================================================================

panel <- fread(file.path(data_dir, "panel_la_quarter_speedcat.csv"))
panel_total <- fread(file.path(data_dir, "panel_la_quarter_total.csv"))

cat(sprintf("Panel (speed cat): %s rows, %d LAs, %d quarters\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$la_code), uniqueN(panel$year_quarter)))

# ============================================================================
# 1. MAIN RESULT: Effect on low-speed (20+30mph) road collisions
# ============================================================================

# Low-speed roads are the treatment-relevant category
# Before reform: these were mostly 30mph in Wales
# After reform: these are mostly 20mph in Wales
low <- panel[speed_cat == "low_speed"]

cat("\n=== Main Result: Low-speed road collisions (DiD) ===\n")

# Specification 1: TWFE on collision counts
m1 <- feols(n_collisions ~ treat | la_code + year_quarter, data = low, cluster = ~la_code)
cat("\nModel 1: TWFE — collision count\n")
summary(m1)

# Specification 2: Log(collisions + 1)
low[, ln_collisions := log(n_collisions + 1)]
m2 <- feols(ln_collisions ~ treat | la_code + year_quarter, data = low, cluster = ~la_code)
cat("\nModel 2: TWFE — log(collisions + 1)\n")
summary(m2)

# Specification 3: KSI (killed or seriously injured) count
m3 <- feols(n_ksi ~ treat | la_code + year_quarter, data = low, cluster = ~la_code)
cat("\nModel 3: TWFE — KSI count\n")
summary(m3)

# Specification 4: Fatal collisions
m4 <- feols(n_fatal ~ treat | la_code + year_quarter, data = low, cluster = ~la_code)
cat("\nModel 4: TWFE — fatal collisions\n")
summary(m4)

# ============================================================================
# 2. PLACEBO: Effect on high-speed (40+mph) road collisions
# ============================================================================

high <- panel[speed_cat == "high_speed"]

cat("\n=== Placebo: High-speed road collisions ===\n")

m_placebo <- feols(n_collisions ~ treat | la_code + year_quarter, data = high, cluster = ~la_code)
cat("\nPlacebo model: high-speed collision count\n")
summary(m_placebo)

m_placebo_ksi <- feols(n_ksi ~ treat | la_code + year_quarter, data = high, cluster = ~la_code)
cat("\nPlacebo model: high-speed KSI count\n")
summary(m_placebo_ksi)

# ============================================================================
# 3. EVENT STUDY
# ============================================================================

cat("\n=== Event Study: Low-speed collisions ===\n")

# Drop the period just before treatment (event_time == -1) as reference
low[, event_time_f := factor(event_time)]
low[, event_time_f := relevel(event_time_f, ref = as.character(-1))]

m_es <- feols(n_collisions ~ i(event_time, welsh, ref = -1) | la_code + year_quarter,
              data = low, cluster = ~la_code)
cat("\nEvent study model:\n")
summary(m_es)

# ============================================================================
# 4. RANDOMIZATION INFERENCE (few-cluster inference)
# ============================================================================

cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_ri <- 2000
true_b1 <- coef(m1)["treat"]
true_b3 <- coef(m3)["treat"]

all_las <- unique(low$la_code)
n_welsh <- uniqueN(low[welsh == 1, la_code])

ri_coefs_m1 <- numeric(n_ri)
ri_coefs_m3 <- numeric(n_ri)

for (i in seq_len(n_ri)) {
  fake_welsh <- sample(all_las, n_welsh)
  low[, ri_welsh := as.integer(la_code %in% fake_welsh)]
  low[, ri_treat := ri_welsh * post]
  ri_fit1 <- feols(n_collisions ~ ri_treat | la_code + year_quarter, data = low)
  ri_fit3 <- feols(n_ksi ~ ri_treat | la_code + year_quarter, data = low)
  ri_coefs_m1[i] <- coef(ri_fit1)["ri_treat"]
  ri_coefs_m3[i] <- coef(ri_fit3)["ri_treat"]
}

ri_pval_m1 <- mean(abs(ri_coefs_m1) >= abs(true_b1))
ri_pval_m3 <- mean(abs(ri_coefs_m3) >= abs(true_b3))

cat(sprintf("\nRI for collisions: p-value = %.4f\n", ri_pval_m1))
cat(sprintf("RI for KSI: p-value = %.4f\n", ri_pval_m3))

low[, c("ri_welsh", "ri_treat") := NULL]

# ============================================================================
# 5. BORDER SUBSAMPLE
# ============================================================================

cat("\n=== Border Subsample ===\n")

low_border <- low[border == 1]
cat(sprintf("Border LAs: %d\n", uniqueN(low_border$la_code)))

m_border <- feols(n_collisions ~ treat | la_code + year_quarter,
                  data = low_border, cluster = ~la_code)
cat("\nBorder subsample: collision count\n")
summary(m_border)

m_border_ksi <- feols(n_ksi ~ treat | la_code + year_quarter,
                      data = low_border, cluster = ~la_code)
cat("\nBorder subsample: KSI count\n")
summary(m_border_ksi)

# ============================================================================
# 6. TOTAL COLLISIONS (all road types)
# ============================================================================

cat("\n=== Total collisions (all road types) ===\n")

m_total <- feols(n_collisions ~ treat | la_code + year_quarter,
                 data = panel_total, cluster = ~la_code)
summary(m_total)

# ============================================================================
# 7. SEVERITY SHARE (KSI / total collisions)
# ============================================================================

cat("\n=== Severity share ===\n")

low[, ksi_share := fifelse(n_collisions > 0, n_ksi / n_collisions, 0)]
m_severity <- feols(ksi_share ~ treat | la_code + year_quarter,
                    data = low, cluster = ~la_code)
cat("\nSeverity share model:\n")
summary(m_severity)

# ============================================================================
# Save key model objects for table generation
# ============================================================================

save(m1, m2, m3, m4, m_placebo, m_placebo_ksi,
     m_es, m_border, m_border_ksi, m_total, m_severity,
     ri_pval_m1, ri_pval_m3,
     file = file.path(data_dir, "models.RData"))

# ============================================================================
# Write diagnostics.json for validate_v1.py
# ============================================================================

n_treated <- uniqueN(low[welsh == 1, la_code])
n_pre <- uniqueN(low[post == 0, year_quarter])
n_obs <- nrow(low)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

cat("\n=== Analysis complete ===\n")
