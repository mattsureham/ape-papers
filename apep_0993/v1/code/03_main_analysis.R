## 03_main_analysis.R — Main regression analysis
## apep_0993: South Korea 52-Hour Workweek Reform

source("00_packages.R")

cat("=== Main Analysis: apep_0993 ===\n")

korea <- fread("../data/korea_panel.csv")

# ─────────────────────────────────────────────────────────
# 1. Aggregate event study: Korea total hours over time
# ─────────────────────────────────────────────────────────

cat("1. Aggregate Korea hours trend...\n")

agg <- korea[, .(mean_hours = weighted.mean(hours, emp_weight, na.rm = TRUE)),
             by = year]
cat("  Aggregate weekly hours:\n")
print(agg[order(year)])

# ─────────────────────────────────────────────────────────
# 2. Main DiD: Binding vs. Non-binding industries
# ─────────────────────────────────────────────────────────

cat("\n2. Main DiD specification...\n")

# Specification 1: Binary treatment × Post
m1 <- feols(hours ~ binding:post | industry + year,
            data = korea, weights = ~emp_weight,
            cluster = ~industry)

# Specification 2: Continuous treatment (overtime gap × Post)
m2 <- feols(hours ~ overtime_gap:post | industry + year,
            data = korea, weights = ~emp_weight,
            cluster = ~industry)

# Specification 3: Continuous dose (baseline hours × Post)
m3 <- feols(hours ~ baseline_hours:post | industry + year,
            data = korea, weights = ~emp_weight,
            cluster = ~industry)

cat("  Model 1 (Binary × Post): β =", round(coef(m1), 3), "\n")
cat("  Model 2 (Gap × Post):    β =", round(coef(m2), 3), "\n")
cat("  Model 3 (Dose × Post):   β =", round(coef(m3), 3), "\n")

# ─────────────────────────────────────────────────────────
# 3. Event study: Year-by-year effects
# ─────────────────────────────────────────────────────────

cat("\n3. Event study specification...\n")

# Create interaction dummies (omit 2017 as reference)
korea[, event_year := factor(year)]

m_event <- feols(hours ~ i(year, binding, ref = 2017) | industry + year,
                 data = korea, weights = ~emp_weight,
                 cluster = ~industry)

cat("  Event study coefficients:\n")
es_coefs <- coeftable(m_event)
print(round(es_coefs, 3))

# ─────────────────────────────────────────────────────────
# 4. Staggered implementation: Wave-specific effects
# ─────────────────────────────────────────────────────────

cat("\n4. Staggered wave effects...\n")

# Interact binding with each wave
m_waves <- feols(hours ~ binding:wave1 + binding:wave2 + binding:wave3 |
                   industry + year,
                 data = korea, weights = ~emp_weight,
                 cluster = ~industry)

cat("  Wave effects:\n")
print(round(coeftable(m_waves), 3))

# ─────────────────────────────────────────────────────────
# 5. Cross-country placebo: Did same industries decline elsewhere?
# ─────────────────────────────────────────────────────────

cat("\n5. Cross-country placebo...\n")

cross <- fread("../data/cross_country_panel.csv")

# Remove aggregate rows, keep only ISIC4 industry codes
cross_ind <- cross[grepl("^[A-U]$", industry)]

# Merge Korea baseline binding status to all countries
binding_map <- unique(korea[, .(industry, binding)])
cross_ind <- merge(cross_ind, binding_map, by = "industry", all.x = TRUE)
cross_ind <- cross_ind[!is.na(binding)]
cross_ind[, post := as.integer(year >= 2018)]
cross_ind[, is_korea := as.integer(country == "KOR")]

# Triple-difference: Korea × Binding × Post
m_triple <- feols(hours ~ is_korea:binding:post + binding:post + is_korea:post |
                    country^industry + country^year,
                  data = cross_ind,
                  cluster = ~country^industry)

cat("  Triple-DiD (Korea × Binding × Post):\n")
print(round(coeftable(m_triple), 3))

# ─────────────────────────────────────────────────────────
# 6. Save results
# ─────────────────────────────────────────────────────────

# Diagnostics for validator
n_binding <- uniqueN(korea[binding == 1, industry])
n_nonbinding <- uniqueN(korea[binding == 0, industry])
n_pre <- length(unique(korea[year < 2018, year]))

diagnostics <- list(
  n_treated = n_binding,
  n_pre = n_pre,
  n_obs = nrow(korea),
  n_control = n_nonbinding,
  n_industries = uniqueN(korea$industry),
  n_years = length(unique(korea$year))
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save models for table generation
save(m1, m2, m3, m_event, m_waves, m_triple, korea, cross_ind,
     file = "../data/main_results.RData")

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")
