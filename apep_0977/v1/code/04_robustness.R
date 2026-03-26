## 04_robustness.R — Robustness checks
## apep_0977: Korea-Japan boycott trade hysteresis

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

## ── 1. Exclude COVID period (Jan 2020 – Jun 2021) ─────────────────────────
cat("=== Robustness 1: Excluding COVID ===\n")

df_nocovid <- df |>
  filter(!(date >= as.Date("2020-01-01") & date <= as.Date("2021-06-30")))

r1_nocovid <- feols(
  log_trade ~ treat_ddd |
    pd_id + dest^period + hs2^period,
  data = df_nocovid,
  cluster = ~pd_id
)
summary(r1_nocovid)

## ── 2. Industrial goods placebo ────────────────────────────────────────────
## Use a DD specification within industrial goods: Korea vs China, pre vs post
## Simpler FEs to avoid collinearity
cat("\n=== Robustness 2: Industrial Goods Placebo ===\n")

df_ind <- df |> filter(industrial == 1)

r2_placebo <- feols(
  log_trade ~ korea:post |
    pd_id + period,
  data = df_ind,
  cluster = ~pd_id
)
summary(r2_placebo)
cat(sprintf("Industrial placebo coefficient: %.4f (se=%.4f)\n",
            coef(r2_placebo)["korea:post"], se(r2_placebo)["korea:post"]))

## ── 3. Levels instead of logs ──────────────────────────────────────────────
cat("\n=== Robustness 3: Trade Value in Levels ===\n")

r3_levels <- feols(
  trade_value ~ treat_ddd |
    pd_id + dest^period + hs2^period,
  data = df,
  cluster = ~pd_id
)
summary(r3_levels)

## ── 4. Pre-trend test: consumer × korea × linear trend (pre-period only) ──
cat("\n=== Robustness 4: Pre-Trend Test ===\n")

df_pre <- df |> filter(post == 0)

r4_pretrend <- feols(
  log_trade ~ consumer:korea:I(ym) |
    pd_id + dest^period + hs2^period,
  data = df_pre,
  cluster = ~pd_id
)
summary(r4_pretrend)

## ── 5. Permutation test: randomly reassign consumer/industrial labels ──────
cat("\n=== Robustness 5: Permutation Test ===\n")

main_model <- feols(
  log_trade ~ treat_ddd |
    pd_id + dest^period + hs2^period,
  data = df,
  cluster = ~pd_id
)

set.seed(20190701)  # Seed = boycott start date
n_perms <- 500
actual_coef <- coef(main_model)["treat_ddd"]

perm_coefs <- numeric(n_perms)
unique_products <- unique(df$hs2)
n_consumer <- sum(unique_products %in% df$hs2[df$consumer == 1])

for (i in seq_len(n_perms)) {
  fake_consumer <- sample(unique_products, n_consumer)
  df_perm <- df |>
    mutate(
      fake_consumer = as.integer(hs2 %in% fake_consumer),
      fake_treat = fake_consumer * korea * post
    )
  m_perm <- tryCatch(
    feols(log_trade ~ fake_treat | pd_id + dest^period + hs2^period,
          data = df_perm, cluster = ~pd_id),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["fake_treat"]
  } else {
    perm_coefs[i] <- NA
  }
  if (i %% 100 == 0) cat(sprintf("  Permutation %d/%d\n", i, n_perms))
}

perm_p <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat(sprintf("\nPermutation p-value (two-sided): %.4f\n", perm_p))
cat(sprintf("Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("Mean permutation coefficient: %.4f\n", mean(perm_coefs, na.rm = TRUE)))

## ── Save robustness results ────────────────────────────────────────────────
saveRDS(list(
  r1_nocovid = r1_nocovid,
  r2_placebo = r2_placebo,
  r3_levels  = r3_levels,
  r4_pretrend = r4_pretrend,
  perm_p      = perm_p,
  perm_coefs  = perm_coefs,
  actual_coef = actual_coef
), "../data/robustness_results.rds")

cat("\nRobustness results saved.\n")
