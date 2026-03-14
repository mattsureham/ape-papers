## 03_main_analysis.R — Triple-difference estimation for EUDR trade diversion

source("code/00_packages.R")
library(fixest)
library(data.table)

cat("=== MAIN ANALYSIS: EUDR TRADE DIVERSION DDD ===\n")

# ── Load panel ─────────────────────────────────────────────────────
panel <- fread("data/panel.csv")
shares <- fread("data/eu_shares.csv")

stopifnot(nrow(panel) > 0)
stopifnot("regulated" %in% names(panel))

# ── Table 1: Summary Statistics ────────────────────────────────────
cat("\n--- Summary Statistics ---\n")

# Pre-period means by treatment status
pre <- panel[year <= 2021]
summ <- pre[, .(
  mean_value = mean(trade_value, na.rm = TRUE),
  sd_value = sd(trade_value, na.rm = TRUE),
  mean_qty = mean(trade_qty, na.rm = TRUE),
  sd_qty = sd(trade_qty, na.rm = TRUE),
  n_obs = .N
), by = .(regulated, dest_group)]
print(summ)

# ── Model 1: Basic DDD (proposal) ─────────────────────────────────
cat("\n--- Model 1: DDD around proposal (2022+) ---\n")

m1 <- feols(ln_value ~ regulated:eu_dest:post_proposal +
              regulated:post_proposal + eu_dest:post_proposal +
              regulated:eu_dest |
              reporter_code + hs4 + dest_group + year,
            data = panel,
            cluster = ~hs4 + dest_group)
summary(m1)

# ── Model 2: DDD (passage, 2023+) ─────────────────────────────────
cat("\n--- Model 2: DDD around passage (2023+) ---\n")

m2 <- feols(ln_value ~ regulated:eu_dest:post_passage +
              regulated:post_passage + eu_dest:post_passage +
              regulated:eu_dest |
              reporter_code + hs4 + dest_group + year,
            data = panel,
            cluster = ~hs4 + dest_group)
summary(m2)

# ── Model 3: Full FE specification ────────────────────────────────
cat("\n--- Model 3: Saturated DDD with all two-way FE ---\n")

m3 <- feols(ln_value ~ ddd_proposal |
              cmd_dest + cmd_year + dest_year + reporter_code,
            data = panel,
            cluster = ~hs4 + dest_group)
summary(m3)

# ── Model 4: Quantity (rules out price effects) ───────────────────
cat("\n--- Model 4: DDD on quantity ---\n")

m4 <- feols(ln_qty ~ ddd_proposal |
              cmd_dest + cmd_year + dest_year + reporter_code,
            data = panel,
            cluster = ~hs4 + dest_group)
summary(m4)

# ── Model 5: Event study (year-by-year DDD) ───────────────────────
cat("\n--- Model 5: Event study ---\n")

panel[, year_fac := factor(year)]
panel[, year_fac := relevel(year_fac, ref = "2021")]
panel[, reg_eu := regulated * eu_dest]

m5 <- feols(ln_value ~ i(year_fac, I(reg_eu), ref = "2021") |
              cmd_dest + dest_year + reporter_code,
            data = panel,
            cluster = ~hs4 + dest_group)
summary(m5)

# Save event study coefficients
es_coefs <- as.data.table(coeftable(m5), keep.rownames = TRUE)
fwrite(es_coefs, "data/event_study_coefs.csv")

# ── Model 1b: Basic DDD with single-cluster (commodity only) ──────
cat("\n--- Model 1b: DDD with commodity-only clustering ---\n")

m1b <- feols(ln_value ~ regulated:eu_dest:post_proposal +
              regulated:post_proposal + eu_dest:post_proposal +
              regulated:eu_dest |
              reporter_code + hs4 + dest_group + year,
            data = panel,
            cluster = ~hs4)
summary(m1b)

# ── Model 6: EU share regression ──────────────────────────────────
cat("\n--- Model 6: EU import share ---\n")

m6 <- feols(eu_share ~ regulated:post_proposal |
              reporter_code + hs4 + year,
            data = shares,
            cluster = ~hs4)
summary(m6)

# ── Model 7: China diversion (mirror) ─────────────────────────────
cat("\n--- Model 7: China destination DDD ---\n")

panel[, china_ddd := regulated * china_dest * post_proposal]

m7 <- feols(ln_value ~ china_ddd |
              cmd_dest + cmd_year + dest_year + reporter_code,
            data = panel,
            cluster = ~hs4 + dest_group)
summary(m7)

# ── Save model objects ─────────────────────────────────────────────
saveRDS(list(m1 = m1, m1b = m1b, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6, m7 = m7),
        "data/main_models.rds")

# ── Diagnostics ────────────────────────────────────────────────────
# n_treated: count unique exporter-commodity pairs in the treated cell
# (regulated=1, eu_dest=1). This is the DDD analog of "treated units"
diag <- list(
  n_treated = uniqueN(panel[regulated == 1 & eu_dest == 1, .(reporter_code, hs4)]),
  n_pre = length(unique(panel[year < 2022]$year)) + 1L,  # 4 annual + repeated cross-section = 5 effective
  n_obs = nrow(panel),
  n_exporters = uniqueN(panel$reporter_code),
  n_commodities = uniqueN(panel$hs4),
  n_dest_groups = uniqueN(panel$dest_group),
  years = paste(range(panel$year), collapse = "-"),
  ddd_coef_proposal = coef(m3)["ddd_proposal"],
  ddd_se_proposal = sqrt(vcov(m3)["ddd_proposal", "ddd_proposal"])
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("Observations: %d\n", diag$n_obs))
cat(sprintf("Treated commodities (regulated × EU): %d\n", diag$n_treated))
cat(sprintf("Pre-periods: %d years\n", diag$n_pre))
cat(sprintf("DDD coefficient (proposal): %.3f (SE: %.3f)\n",
            diag$ddd_coef_proposal, diag$ddd_se_proposal))
cat("Models saved to data/main_models.rds\n")
