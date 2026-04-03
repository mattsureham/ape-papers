## 04_robustness.R — Robustness checks and placebo tests
## apep_1338: Brexit Rules of Origin and Trade Disintegration

source("code/00_packages.R")

analysis <- readRDS("data/analysis_panel.rds")
imports <- analysis |> filter(flowCode == "M")

## ── 1. Placebo: Pre-period only (2017-2019), fake treatment at 2019 ─────────

pre_only <- imports |>
  filter(year <= 2019) |>
  mutate(
    placebo_post = as.integer(year >= 2019)
  )

m_placebo <- feols(
  log_trade ~ I(placebo_post * eu * roo_ri) | hs4_eu + hs4^year + eu^year,
  data = pre_only,
  cluster = ~hs2
)

cat("--- Placebo test (fake treatment at 2019) ---\n")
summary(m_placebo)

## ── 2. Alternative clustering: HS-4 level ───────────────────────────────────

m_hs4_cluster <- feols(
  log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
  data = imports,
  cluster = ~hs4
)

cat("\n--- Alternative clustering: HS-4 ---\n")
summary(m_hs4_cluster)

## ── 3. Alternative clustering: two-way (HS-2 + year) ───────────────────────

m_twoway <- feols(
  log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
  data = imports,
  cluster = ~hs2 + year
)

cat("\n--- Two-way clustering: HS-2 + year ---\n")
summary(m_twoway)

## ── 4. Excluding smallest products (bottom 10% by pre-period trade) ─────────

pre_trade <- imports |>
  filter(post == 0) |>
  group_by(hs4) |>
  summarize(mean_trade = mean(trade_value, na.rm = TRUE), .groups = "drop")

q10 <- quantile(pre_trade$mean_trade, 0.10, na.rm = TRUE)

large_products <- pre_trade |>
  filter(mean_trade >= q10) |>
  pull(hs4)

m_large <- feols(
  log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
  data = imports |> filter(hs4 %in% large_products),
  cluster = ~hs2
)

cat("\n--- Excluding bottom 10% products ---\n")
summary(m_large)

## ── 5. Sector-by-sector heterogeneity ───────────────────────────────────────

sectors <- unique(imports$sector)

sector_results <- lapply(sectors, function(s) {
  sub <- imports |> filter(sector == s)
  if (nrow(sub) < 50 || n_distinct(sub$hs2) < 2) return(NULL)

  tryCatch({
    m <- feols(
      log_trade ~ post_eu_roo | hs4_eu + hs4^year + eu^year,
      data = sub,
      cluster = ~hs2
    )
    data.frame(
      sector = s,
      beta_ddd = coef(m)["post_eu_roo"],
      se_ddd = se(m)["post_eu_roo"],
      n = nrow(sub),
      mean_roo = mean(sub$roo_ri)
    )
  }, error = function(e) NULL)
})

sector_df <- bind_rows(sector_results)
cat("\n--- Sector heterogeneity ---\n")
print(sector_df |> arrange(beta_ddd))

## ── 6. Drop individual control partners one at a time ───────────────────────

control_partners <- c("842", "124", "392", "410", "36")
partner_names <- c("US", "Canada", "Japan", "South Korea", "Australia")

# Need partner info — re-merge from raw
raw <- readRDS("data/comtrade_uk_hs4_raw.rds")

for (i in seq_along(control_partners)) {
  sub <- imports  # Already aggregated, so this won't work directly
  # Instead, note this as a limitation for V1 — partner-level LOO requires

  # re-aggregation from raw data
}

cat("\nNote: Leave-one-partner-out analysis requires raw partner-level data.\n")
cat("Flagged for V2 extension.\n")

## ── 7. Save robustness results ──────────────────────────────────────────────

saveRDS(
  list(
    m_placebo = m_placebo,
    m_hs4_cluster = m_hs4_cluster,
    m_twoway = m_twoway,
    m_large = m_large,
    sector_df = sector_df
  ),
  "data/robustness_objects.rds"
)

cat("\nSaved data/robustness_objects.rds\n")
