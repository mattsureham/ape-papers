## 03_main_analysis.R — DDD estimation: Post × EU × ROO-RI
## apep_1338: Brexit Rules of Origin and Trade Disintegration

source("code/00_packages.R")

analysis <- readRDS("data/analysis_panel.rds")

## ── 1. Focus on imports (primary specification) ─────────────────────────────
## Imports capture the compliance burden most directly: UK importers must
## prove origin to use TCA preferences, or pay MFN tariff.

imports <- analysis |> filter(flowCode == "M")
exports <- analysis |> filter(flowCode == "X")

cat("Import panel: ", nrow(imports), " rows\n")
cat("Export panel: ", nrow(exports), " rows\n")

## ── 2. Main DDD specification ───────────────────────────────────────────────
## log(Trade_pct) = β(Post × EU × ROO-RI) + FE(hs4×eu) + FE(hs4×year) + FE(eu×year) + ε
## Cluster: HS-2 chapter level

# Specification 1: Simple DD (Post × EU) — without eu×year FE to avoid collinearity
# (With only 2 partner types, eu×year absorbs post_eu entirely)
m1 <- feols(
  log_trade ~ post_eu | hs4_eu + hs4^year + year,
  data = imports,
  cluster = ~hs2
)

# Specification 2: DDD (Post × EU × ROO-RI, continuous)
# post_eu, post_roo, eu_roo are absorbed by the three-way FE structure
# Only post_eu_roo has within-cell variation
m2 <- feols(
  log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
  data = imports,
  cluster = ~hs2
)

# Specification 3: DDD with high-ROO indicator (binary split)
imports <- imports |>
  mutate(post_eu_high = post * eu * high_roo)
m3 <- feols(
  log_trade ~ post_eu_high | hs4_eu + hs4^year + eu^year,
  data = imports,
  cluster = ~hs2
)

# Specification 4: Same as m2 but for exports
m4 <- feols(
  log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
  data = exports,
  cluster = ~hs2
)

# Specification 5: Both imports and exports pooled
both <- bind_rows(imports, exports) |>
  mutate(is_import = as.integer(flowCode == "M"))

m5 <- feols(
  log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
  data = both,
  cluster = ~hs2
)

## ── 3. Display results ──────────────────────────────────────────────────────

cat("\n=== MAIN RESULTS ===\n\n")

cat("--- Model 1: Simple DD (Post × EU) on Imports ---\n")
summary(m1)

cat("\n--- Model 2: DDD (Post × EU × ROO-RI) on Imports [PRIMARY] ---\n")
summary(m2)

cat("\n--- Model 3: DDD with High-ROO Indicator on Imports ---\n")
summary(m3)

cat("\n--- Model 4: DDD on Exports ---\n")
summary(m4)

cat("\n--- Model 5: DDD on Pooled Trade ---\n")
summary(m5)

## ── 4. Event study: year-by-year effects ────────────────────────────────────

imports_es <- imports |>
  mutate(
    rel_year = year - 2021,
    # Reference: 2019 (rel_year = -2)
    rel_year_f = factor(rel_year)
  )

# Event study: interact rel_year with eu × roo_ri
# Use product + partner×year FE (not product×year, which would absorb too much)
imports_es <- imports_es |>
  mutate(eu_roo_int = eu * roo_ri)

m_es <- feols(
  log_trade ~ i(rel_year_f, eu_roo_int, ref = "-2") | hs4 + eu^year + hs4_eu,
  data = imports_es,
  cluster = ~hs2
)

cat("\n--- Event Study: Year-by-Year DDD Coefficients ---\n")
summary(m_es)

## ── 5. Save model objects and diagnostics ───────────────────────────────────

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m_es = m_es),
        "data/model_objects.rds")

# Diagnostics for validate_v1
n_treated <- imports |>
  filter(post == 1, eu == 1) |>
  pull(hs4) |>
  n_distinct()

n_pre <- imports |>
  filter(post == 0) |>
  pull(year) |>
  unique() |>
  length()

n_obs <- nrow(imports)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs
  ),
  "data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\nDiagnostics:\n")
cat("  Treated HS4 products (post × EU):", n_treated, "\n")
cat("  Pre-treatment years:", n_pre, "\n")
cat("  Total observations:", n_obs, "\n")
cat("\nSaved data/model_objects.rds and data/diagnostics.json\n")
