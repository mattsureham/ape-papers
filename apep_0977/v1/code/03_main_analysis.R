## 03_main_analysis.R — Main DDD estimation and event study
## apep_0977: Korea-Japan boycott trade hysteresis

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
stopifnot("Analysis panel is empty" = nrow(df) > 0)

## ── 1. Main Triple-Difference ──────────────────────────────────────────────
## Y = log(trade) on Consumer × Korea × Post with three-way FEs
## product×destination + destination×month + product×month

cat("=== Main DDD Specification ===\n")

m1_ddd <- feols(
  log_trade ~ treat_ddd |
    pd_id + dest^period + hs2^period,
  data = df,
  cluster = ~pd_id
)
summary(m1_ddd)

## ── 2. Decomposed DDD: Consumer × Korea, Korea × Post, Consumer × Post ───
cat("\n=== Decomposed DDD ===\n")

m2_decomp <- feols(
  log_trade ~ consumer:korea:post + consumer:korea + korea:post + consumer:post |
    hs2 + dest + period,
  data = df,
  cluster = ~pd_id
)
summary(m2_decomp)

## ── 3. Event Study ─────────────────────────────────────────────────────────
## Interact Consumer × Korea with monthly dummies, omit t = -1 (Jun 2019)

cat("\n=== Event Study ===\n")

# Trim to balanced window: -18 to +54 months
df_es <- df |>
  filter(event_time >= -18, event_time <= 54) |>
  mutate(
    event_time_factor = factor(event_time),
    treat_es = consumer * korea
  )

# Omit t = 0 (Jun 2019 = last pre-treatment month)
m3_es <- feols(
  log_trade ~ i(event_time, treat_es, ref = 0) |
    pd_id + dest^period + hs2^period,
  data = df_es,
  cluster = ~pd_id
)
summary(m3_es)

## ── 4. Product-level heterogeneity ─────────────────────────────────────────
## Run product-specific DID: Korea × Post for each consumer product

cat("\n=== Product-Level DID (Consumer Products Only) ===\n")

consumer_products <- df |>
  filter(consumer == 1) |>
  distinct(hs2, cmd_desc) |>
  arrange(hs2)

product_did <- list()
for (i in seq_len(nrow(consumer_products))) {
  hs <- consumer_products$hs2[i]
  sub <- df |> filter(hs2 == hs)

  if (nrow(sub) < 20) next

  mod <- tryCatch(
    feols(log_trade ~ korea:post | dest + period, data = sub, vcov = "HC1"),
    error = function(e) NULL
  )

  if (!is.null(mod)) {
    product_did[[hs]] <- tibble(
      hs2       = hs,
      desc      = consumer_products$cmd_desc[i],
      coef      = coef(mod)["korea:post"],
      se        = se(mod)["korea:post"],
      n_obs     = nobs(mod)
    )
  }
}

product_results <- bind_rows(product_did) |>
  arrange(coef)

cat("\nProduct-level Korea×Post effects (consumer goods):\n")
print(product_results |> mutate(across(c(coef, se), ~round(., 3))))

## ── 5. Mechanism: Differentiated vs. Homogeneous ───────────────────────────
cat("\n=== Rauch Classification Heterogeneity ===\n")

# Within consumer goods only
df_cons <- df |> filter(consumer == 1)

m5_rauch <- feols(
  log_trade ~ differentiated:korea:post + i(differentiated, 0):korea:post |
    pd_id + dest^period + hs2^period,
  data = df_cons,
  cluster = ~pd_id
)
summary(m5_rauch)

## ── 6. Mechanism: Visibility ───────────────────────────────────────────────
cat("\n=== Visibility Heterogeneity ===\n")

m6_vis <- feols(
  log_trade ~ visible:korea:post + i(visible, 0):korea:post |
    pd_id + dest^period + hs2^period,
  data = df_cons,
  cluster = ~pd_id
)
summary(m6_vis)

## ── 7. Recovery dynamics: early post vs. late post ─────────────────────────
cat("\n=== Recovery Dynamics ===\n")

df <- df |>
  mutate(
    early_post = as.integer(date >= as.Date("2019-07-01") & date < as.Date("2021-01-01")),
    late_post  = as.integer(date >= as.Date("2021-01-01"))
  )

m7_recovery <- feols(
  log_trade ~ consumer:korea:early_post + consumer:korea:late_post |
    pd_id + dest^period + hs2^period,
  data = df,
  cluster = ~pd_id
)
summary(m7_recovery)

## ── Save results ───────────────────────────────────────────────────────────
saveRDS(list(
  m1_ddd       = m1_ddd,
  m2_decomp    = m2_decomp,
  m3_es        = m3_es,
  product_did  = product_results,
  m5_rauch     = m5_rauch,
  m6_vis       = m6_vis,
  m7_recovery  = m7_recovery
), "../data/main_results.rds")

## ── Write diagnostics.json for validator ───────────────────────────────────
n_treated_products <- n_distinct(df$hs2[df$consumer == 1 & df$korea == 1])
n_pre_months <- n_distinct(df$period[df$post == 0])
n_total <- nrow(df)

jsonlite::write_json(
  list(
    n_treated = n_treated_products,
    n_pre = n_pre_months,
    n_obs = n_total
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_products, n_pre_months, n_total))
cat("Results saved to data/main_results.rds\n")
