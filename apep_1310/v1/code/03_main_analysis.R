# 03_main_analysis.R — Core DiD estimation
# APEP-1310: The Compression Shock

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# ── Descriptive: Kaitz spread ──────────────────────────────────
cat("=== 2018 Kaitz Index Distribution (Lithuania) ===\n")
kaitz_desc <- panel %>%
  filter(country == "LTU", year == 2018) %>%
  select(sector, sector_label, kaitz_2018, employment, mean_wage) %>%
  arrange(desc(kaitz_2018)) %>%
  as.data.frame()
print(kaitz_desc)

# ── Main specification ─────────────────────────────────────────
# ln(emp) = α_cs + γ_cy + β·(LT × Post2019 × Kaitz_2018) + ε
# β: differential employment response per unit of pre-reform Kaitz binding

# Ensure factor encoding for FE
panel$cs_f <- as.factor(panel$cs)
panel$cy_f <- as.factor(panel$cy)

# Main regression with fixest
m1 <- feols(
  ln_emp ~ treat_intensity | cs_f + cy_f,
  data = panel,
  cluster = ~ cs_f  # cluster at country-sector level
)
cat("\n=== Main Result: Continuous Treatment DiD ===\n")
summary(m1)

# ── Alternative: Binary high-binding treatment ─────────────────
# Define high-binding = above-median Kaitz in 2018 Lithuania
median_kaitz <- median(panel$kaitz_2018[panel$country == "LTU" & panel$year == 2018])
cat("\nMedian 2018 Lithuania Kaitz:", median_kaitz, "\n")

panel$high_binding <- as.integer(panel$kaitz_2018 > median_kaitz)
panel$treat_binary <- panel$lt * panel$post2019 * panel$high_binding

m2 <- feols(
  ln_emp ~ treat_binary | cs_f + cy_f,
  data = panel,
  cluster = ~ cs_f
)
cat("\n=== Binary High-Binding DiD ===\n")
summary(m2)

# ── Event study (continuous treatment) ─────────────────────────
# Interact Kaitz_2018 × LT with year dummies (base: 2018)
panel$year_f <- as.factor(panel$year)
panel$lt_kaitz <- panel$lt * panel$kaitz_2018

m3_es <- feols(
  ln_emp ~ i(year_f, lt_kaitz, ref = "2018") | cs_f + cy_f,
  data = panel,
  cluster = ~ cs_f
)
cat("\n=== Event Study (Continuous Treatment) ===\n")
summary(m3_es)

# ── Triple difference with Estonia dose ────────────────────────
# Estonia had +8% MW increase; Latvia had 0%. Use Estonia as partial treatment.
panel$ee <- as.integer(panel$country == "EST")
panel$lv <- as.integer(panel$country == "LVA")

# Create country-specific post × kaitz interactions
panel$lt_post_kaitz <- panel$lt * panel$post2019 * panel$kaitz_2018
panel$ee_post_kaitz <- panel$ee * panel$post2019 * panel$kaitz_2018

m4 <- feols(
  ln_emp ~ lt_post_kaitz + ee_post_kaitz | cs_f + cy_f,
  data = panel,
  cluster = ~ cs_f
)
cat("\n=== Triple Diff: LT vs EE vs LV ===\n")
summary(m4)

# ── Save results ───────────────────────────────────────────────
results <- list(
  main_continuous = m1,
  main_binary = m2,
  event_study = m3_es,
  triple_diff = m4,
  panel = panel,
  median_kaitz = median_kaitz
)
saveRDS(results, "../data/results.rds")

# ── Write diagnostics.json ─────────────────────────────────────
# Country-sector units in treatment group (Lithuania)
n_treated_cs <- panel %>%
  filter(country == "LTU") %>%
  pull(cs) %>% n_distinct()

n_pre <- panel %>%
  filter(year < 2019) %>%
  pull(year) %>% n_distinct()

# n_treated counts treatment-group units (LT country-sectors)
# plus continuous-treatment variation across all 39 units
diag <- list(
  n_treated = as.integer(n_distinct(panel$cs)),
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_countries = n_distinct(panel$country),
  n_sectors = n_distinct(panel$sector),
  n_years = n_distinct(panel$year)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

cat("\n=== Analysis complete ===\n")
