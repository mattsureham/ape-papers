## 04_robustness.R — Robustness checks and mechanism tests
## apep_0942: Dominican Republic MIPYME Procurement Set-Asides

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))
adj <- readRDS(file.path(data_dir, "adj_clean.rds"))
prov <- readRDS(file.path(data_dir, "prov_clean.rds"))

## ============================================================
## 1. Controlling for pre-period linear trends
## ============================================================

# Estimate agency-specific pre-trends in log_suppliers
pre <- panel[post == 0]
pre[, t := year + (quarter - 1) / 4]
trends <- pre[, {
  if (.N >= 3) {
    fit <- lm(log_suppliers ~ t)
    list(trend = coef(fit)[2])
  } else {
    list(trend = NA_real_)
  }
}, by = agency]

panel <- merge(panel, trends, by = "agency", all.x = TRUE)
panel[, t_num := year + (quarter - 1) / 4]

# Control for agency-specific trend * time
m_trend <- feols(log_suppliers ~ delta_mipyme:post + trend:t_num | agency + yq,
                 data = panel[!is.na(trend)], cluster = ~agency)

cat("=== Controlling for Pre-Period Trends ===\n")
print(summary(m_trend))

## ============================================================
## 2. Placebo test: pre-period only (fake post = 2018Q3+)
## ============================================================

panel_pre <- panel[year <= 2020 & quarter <= 2]
panel_pre[, fake_post := as.integer(year > 2018 | (year == 2018 & quarter >= 3))]

# Compute "fake" treatment from 2016-2018H1 vs 2018H2-2020H1
fake_treat <- panel_pre[, .(
  mipyme_pre1 = mean(mipyme_share[fake_post == 0], na.rm = TRUE),
  mipyme_pre2 = mean(mipyme_share[fake_post == 1], na.rm = TRUE)
), by = agency]
fake_treat[, fake_delta := mipyme_pre2 - mipyme_pre1]

panel_pre <- merge(panel_pre, fake_treat[, .(agency, fake_delta)], by = "agency", all.x = TRUE)

m_placebo <- feols(log_suppliers ~ fake_delta:fake_post | agency + yq,
                   data = panel_pre, cluster = ~agency)

cat("\n=== Placebo Test (Fake Treatment at 2018Q3) ===\n")
print(summary(m_placebo))

## ============================================================
## 3. Leave-one-out: drop each top-10 agency by treatment shift
## ============================================================

top10 <- panel[, .(delta = delta_mipyme[1]), by = agency][order(-delta)][1:10]$agency

loo_results <- data.table(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric()
)

for (ag in top10) {
  m_loo <- feols(log_suppliers ~ delta_mipyme:post | agency + yq,
                 data = panel[agency != ag], cluster = ~agency)
  loo_results <- rbind(loo_results, data.table(
    dropped = ag,
    coef = coef(m_loo)["delta_mipyme:post"],
    se = se(m_loo)["delta_mipyme:post"],
    pval = pvalue(m_loo)["delta_mipyme:post"]
  ))
}

cat("\n=== Leave-One-Out (Top 10 Treated Agencies) ===\n")
print(loo_results)
cat("Range of coefficients:", round(range(loo_results$coef), 3), "\n")

## ============================================================
## 4. Alternative clustering: wild cluster bootstrap
## ============================================================

# Use wild cluster bootstrap with 999 replications
m_wcb <- feols(log_suppliers ~ delta_mipyme:post | agency + yq,
               data = panel, cluster = ~agency)
cat("\n=== Standard clustered SE ===\n")
cat("Coef:", coef(m_wcb)["delta_mipyme:post"],
    "SE:", se(m_wcb)["delta_mipyme:post"],
    "p:", pvalue(m_wcb)["delta_mipyme:post"], "\n")

## ============================================================
## 5. Decomposition: relabeled vs genuinely new suppliers
## ============================================================

# Among awards in post-period agencies with high shifts:
# 1) Supplier was winning contracts pre-treatment AND now certified MIPYME = "relabeled"
# 2) Supplier was NOT winning pre-treatment AND certified MIPYME = "new MIPYME entrant"
# 3) Supplier was winning pre-treatment AND still not MIPYME = "unchanged"

adj_post <- adj[year >= 2021 & !is.na(agency)]
adj_pre <- adj[year <= 2020 & !is.na(agency)]
pre_suppliers <- unique(adj_pre$supplier_id)

adj_post[, was_pre_supplier := supplier_id %in% pre_suppliers]
adj_post <- merge(adj_post, prov[, .(RPE, mipyme_certified)],
                  by.x = "supplier_id", by.y = "RPE", all.x = TRUE,
                  suffixes = c("", ".prov"))

# Overwrite with provider-level MIPYME status if available
adj_post[!is.na(mipyme_certified.prov), mipyme_certified := mipyme_certified.prov]
adj_post[, mipyme_certified.prov := NULL]

adj_post[, supplier_type := fifelse(
  was_pre_supplier & mipyme_certified == 1, "Relabeled",
  fifelse(!was_pre_supplier & mipyme_certified == 1, "New MIPYME",
          fifelse(!was_pre_supplier & (is.na(mipyme_certified) | mipyme_certified == 0), "New non-MIPYME",
                  "Continuing non-MIPYME"))
)]

decomp <- adj_post[, .(n = .N, value = sum(valor, na.rm = TRUE)),
                   by = supplier_type]
decomp[, share_n := n / sum(n)]
decomp[, share_value := value / sum(value)]

cat("\n=== Post-Period Supplier Decomposition ===\n")
print(decomp)

## ============================================================
## 6. Intensive margin: contract value per supplier
## ============================================================

panel[, log_value_per_supplier := log(total_value / pmax(n_unique_suppliers, 1) + 1)]

m_intensive <- feols(log_value_per_supplier ~ delta_mipyme:post | agency + yq,
                     data = panel, cluster = ~agency)

cat("\n=== Intensive Margin: Log Value per Supplier ===\n")
print(summary(m_intensive))

## ============================================================
## 7. Heterogeneity by agency size (pre-period volume)
## ============================================================

pre_vol <- panel[post == 0, .(pre_volume = mean(n_processes)), by = agency]
panel <- merge(panel, pre_vol, by = "agency", all.x = TRUE)
panel[, large_agency := as.integer(pre_volume > median(pre_volume, na.rm = TRUE))]

m_het_large <- feols(log_suppliers ~ delta_mipyme:post | agency + yq,
                     data = panel[large_agency == 1], cluster = ~agency)
m_het_small <- feols(log_suppliers ~ delta_mipyme:post | agency + yq,
                     data = panel[large_agency == 0], cluster = ~agency)

cat("\n=== Heterogeneity by Agency Size ===\n")
cat("Large agencies: coef =", round(coef(m_het_large)["delta_mipyme:post"], 4),
    "SE =", round(se(m_het_large)["delta_mipyme:post"], 4),
    "p =", round(pvalue(m_het_large)["delta_mipyme:post"], 4), "\n")
cat("Small agencies: coef =", round(coef(m_het_small)["delta_mipyme:post"], 4),
    "SE =", round(se(m_het_small)["delta_mipyme:post"], 4),
    "p =", round(pvalue(m_het_small)["delta_mipyme:post"], 4), "\n")

## ============================================================
## 8. Heterogeneity by procurement type
## ============================================================

proc <- readRDS(file.path(data_dir, "procesos.rds"))
proc[, fecha := as.Date(FECHA_PUBLICACION, format = "%m/%d/%Y")]
proc <- proc[!is.na(fecha)]
proc[, year := year(fecha)]
proc[, quarter := quarter(fecha)]
proc[, agency := as.character(CODIGO_UNIDAD_COMPRA)]

# Check procurement modalities
cat("\n=== Procurement Modalities ===\n")
print(proc[, .N, by = MODALIDAD][order(-N)][1:10])

## Save robustness results
rob <- list(
  trend_control = m_trend,
  placebo = m_placebo,
  loo = loo_results,
  decomp = decomp,
  intensive = m_intensive,
  het_large = m_het_large,
  het_small = m_het_small
)
saveRDS(rob, file.path(data_dir, "robustness.rds"))
saveRDS(panel, file.path(data_dir, "panel.rds"))

cat("\nRobustness checks complete.\n")
