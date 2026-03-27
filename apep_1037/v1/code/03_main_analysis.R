# 03_main_analysis.R — Main regressions for Taiwan CGT analysis
# apep_1037: The Round-Trip Tax
# Strategy: TAIEX aggregate + P/E firm panel + institutional flows

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Load data
# ============================================================================

taiex_m <- readRDS(file.path(data_dir, "taiex_monthly_panel.rds"))
taiex_q <- readRDS(file.path(data_dir, "taiex_quarterly_panel.rds"))

cat("TAIEX monthly:", nrow(taiex_m), "obs\n")
cat("TAIEX quarterly:", nrow(taiex_q), "obs\n")

# PE panel
pe_file <- file.path(data_dir, "pe_clean.rds")
pe_panel <- NULL
if (file.exists(pe_file)) {
  pe_raw <- readRDS(pe_file)
  pe_panel <- pe_raw %>%
    filter(!is.na(pe), pe > 0, pe < quantile(pe, 0.99, na.rm = TRUE)) %>%
    mutate(
      log_pe = log(pe),
      cgt_active = as.integer(yq >= 20131 & yq <= 20153),
      post_repeal = as.integer(yq >= 20154),
      event_time = (year - 2013) * 4 + quarter - 1
    )
  cat("P/E panel:", nrow(pe_panel), "obs,",
      n_distinct(pe_panel$stock_code), "stocks,",
      n_distinct(pe_panel$yq), "quarters\n")
}

# Institutional flows
inst_file <- file.path(data_dir, "institutional_flows_raw.rds")
inst_panel <- NULL
if (file.exists(inst_file)) {
  inst_raw <- readRDS(inst_file)
  clean_num <- function(x) {
    x <- gsub(",", "", x)
    suppressWarnings(as.numeric(x))
  }
  inst_panel <- inst_raw %>%
    mutate(
      stock_code = trimws(stock_code),
      foreign_net_val = clean_num(foreign_net),
      trust_buy_val = clean_num(trust_buy),
      trust_sell_val = clean_num(trust_sell),
      yq = year * 10 + quarter,
      cgt_active = as.integer(yq >= 20131 & yq <= 20153),
      post_repeal = as.integer(yq >= 20154),
      foreign_net_positive = as.integer(foreign_net_val > 0)
    ) %>%
    filter(!is.na(foreign_net_val))

  cat("Institutional panel:", nrow(inst_panel), "obs,",
      n_distinct(inst_panel$stock_code), "stocks\n")
}

# Per-stock daily sample (if available)
stock_file <- file.path(data_dir, "stock_daily_sample.rds")
stock_q <- NULL
if (file.exists(stock_file)) {
  stock_raw <- readRDS(stock_file)
  if (nrow(stock_raw) > 100) {
    stock_clean <- stock_raw %>%
      mutate(
        volume = clean_num(volume_shares),
        value = clean_num(value_twd),
        price_close = clean_num(close),
        quarter = ceiling(month / 3),
        yq = year * 10 + quarter
      ) %>%
      filter(!is.na(volume), volume > 0, !is.na(price_close), price_close > 0)

    stock_q <- stock_clean %>%
      group_by(stock_code, year, quarter, yq) %>%
      summarise(
        total_vol = sum(volume, na.rm = TRUE),
        avg_close = mean(price_close, na.rm = TRUE),
        n_days = n(),
        .groups = "drop"
      ) %>%
      mutate(
        log_vol = log(total_vol),
        cgt_active = as.integer(yq >= 20131 & yq <= 20153),
        post_repeal = as.integer(yq >= 20154)
      )

    # Size classification
    pre_size <- stock_q %>%
      filter(yq < 20122) %>%
      group_by(stock_code) %>%
      summarise(pre_mcap = mean(total_vol * avg_close, na.rm = TRUE), .groups = "drop") %>%
      mutate(
        size_quintile = ntile(pre_mcap, 5),
        small_cap = as.integer(size_quintile <= 2)
      )

    stock_q <- stock_q %>%
      left_join(pre_size %>% select(stock_code, size_quintile, small_cap), by = "stock_code")

    cat("Stock sample quarterly:", nrow(stock_q), "obs,",
        n_distinct(stock_q$stock_code), "stocks\n")
  }
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")

taiex_summ <- taiex_q %>%
  mutate(regime = case_when(
    yq < 20122 ~ "Pre-Announce",
    yq >= 20122 & yq < 20131 ~ "Announcement",
    yq >= 20131 & yq <= 20153 ~ "CGT Active",
    yq >= 20154 ~ "Post-Repeal"
  )) %>%
  group_by(regime) %>%
  summarise(
    n = n(),
    avg_daily_vol_b = mean(avg_daily_vol / 1e9, na.rm = TRUE),
    sd_daily_vol_b = sd(avg_daily_vol / 1e9, na.rm = TRUE),
    log_daily_vol = mean(log_daily_vol, na.rm = TRUE),
    .groups = "drop"
  )
print(taiex_summ)

# ============================================================================
# Main Model 1: TAIEX Monthly Log Volume
# ============================================================================

cat("\n=== Model 1: TAIEX Monthly Log Daily Volume ===\n")

taiex_reg <- taiex_m %>%
  mutate(
    cgt_active = as.integer(yq >= 20131 & yq <= 20153),
    post_repeal = as.integer(yq >= 20154),
    announce = as.integer(yq >= 20122 & yq < 20131),
    time_trend = 1:n()
  )

# Model 1a: Simple indicators
m1a <- lm(log_daily_vol ~ announce + cgt_active + post_repeal, data = taiex_reg)
nw1a <- sqrt(diag(sandwich::NeweyWest(m1a, lag = 6)))
cat("Model 1a (simple):\n")
cat(sprintf("  Announce: %.4f (NW SE: %.4f)\n", coef(m1a)["announce"], nw1a["announce"]))
cat(sprintf("  CGT: %.4f (NW SE: %.4f)\n", coef(m1a)["cgt_active"], nw1a["cgt_active"]))
cat(sprintf("  Repeal: %.4f (NW SE: %.4f)\n", coef(m1a)["post_repeal"], nw1a["post_repeal"]))

# Model 1b: With linear trend
m1b <- lm(log_daily_vol ~ announce + cgt_active + post_repeal + time_trend, data = taiex_reg)
nw1b <- sqrt(diag(sandwich::NeweyWest(m1b, lag = 6)))
cat("\nModel 1b (with trend):\n")
cat(sprintf("  Announce: %.4f (NW SE: %.4f)\n", coef(m1b)["announce"], nw1b["announce"]))
cat(sprintf("  CGT: %.4f (NW SE: %.4f)\n", coef(m1b)["cgt_active"], nw1b["cgt_active"]))
cat(sprintf("  Repeal: %.4f (NW SE: %.4f)\n", coef(m1b)["post_repeal"], nw1b["post_repeal"]))
cat(sprintf("  Trend: %.5f (NW SE: %.5f)\n", coef(m1b)["time_trend"], nw1b["time_trend"]))

# ============================================================================
# Main Model 2: P/E Panel (Firm FE)
# ============================================================================

if (!is.null(pe_panel)) {
  cat("\n=== Model 2: P/E Panel (Firm FE) ===\n")

  m2_pe <- feols(log_pe ~ cgt_active + post_repeal | stock_code,
                 data = pe_panel, cluster = ~stock_code)
  cat("P/E ratio (firm FE):\n")
  summary(m2_pe)

  # Dividend yield
  dy_panel <- pe_raw %>%
    filter(!is.na(div_yield), div_yield > 0, div_yield < quantile(div_yield, 0.99, na.rm = TRUE)) %>%
    mutate(
      cgt_active = as.integer(yq >= 20131 & yq <= 20153),
      post_repeal = as.integer(yq >= 20154)
    )

  m2_dy <- feols(div_yield ~ cgt_active + post_repeal | stock_code,
                 data = dy_panel, cluster = ~stock_code)
  cat("\nDividend yield (firm FE):\n")
  summary(m2_dy)
}

# ============================================================================
# Main Model 3: Institutional Flow (Composition Channel)
# ============================================================================

if (!is.null(inst_panel)) {
  cat("\n=== Model 3: Foreign Investor Net Purchases ===\n")

  m3_foreign <- feols(foreign_net_positive ~ cgt_active + post_repeal | stock_code,
                      data = inst_panel, cluster = ~stock_code)
  cat("Probability of positive foreign net (firm FE):\n")
  summary(m3_foreign)

  m3_foreign_net <- feols(foreign_net_val ~ cgt_active + post_repeal | stock_code,
                          data = inst_panel, cluster = ~stock_code)
  cat("\nForeign net value (firm FE):\n")
  summary(m3_foreign_net)
}

# ============================================================================
# Per-Stock Volume (if available)
# ============================================================================

if (!is.null(stock_q)) {
  cat("\n=== Model 4: Per-Stock Volume ===\n")

  m4_vol <- feols(log_vol ~ cgt_active + post_repeal | stock_code,
                  data = stock_q, cluster = ~stock_code)
  cat("Per-stock log volume (firm FE):\n")
  summary(m4_vol)

  m4_size <- feols(log_vol ~ cgt_active:small_cap + post_repeal:small_cap |
                     stock_code + yq,
                   data = stock_q %>% filter(!is.na(small_cap)),
                   cluster = ~stock_code)
  cat("\nSize DiD:\n")
  summary(m4_size)
}

# ============================================================================
# Symmetry Test (TAIEX)
# ============================================================================

cat("\n=== Symmetry Test (CGT vs Repeal) ===\n")

# From Model 1a (no trend)
beta_cgt <- coef(m1a)["cgt_active"]
beta_rep <- coef(m1a)["post_repeal"]
vcov_nw <- sandwich::NeweyWest(m1a, lag = 6)
sum_coef <- beta_cgt + beta_rep
se_sum <- sqrt(vcov_nw["cgt_active", "cgt_active"] +
                 vcov_nw["post_repeal", "post_repeal"] +
                 2 * vcov_nw["cgt_active", "post_repeal"])
t_stat <- sum_coef / se_sum
p_val <- 2 * pt(abs(t_stat), df = nrow(taiex_reg) - 5, lower.tail = FALSE)

cat(sprintf("β_CGT = %.4f, β_PostRepeal = %.4f\n", beta_cgt, beta_rep))
cat(sprintf("β_CGT + β_PostRepeal = %.4f (HAC SE = %.4f)\n", sum_coef, se_sum))
cat(sprintf("t = %.3f, p = %.4f\n", t_stat, p_val))

symmetry_test <- list(
  beta_cgt = beta_cgt, beta_repeal = beta_rep,
  sum = sum_coef, se_sum = se_sum, t_stat = t_stat, p_value = p_val
)
saveRDS(symmetry_test, file.path(data_dir, "symmetry_test.rds"))

# ============================================================================
# Save all models
# ============================================================================

models <- list(
  m1a = m1a, m1b = m1b,
  m2_pe = if (!is.null(pe_panel)) m2_pe else NULL,
  m2_dy = if (!is.null(pe_panel)) m2_dy else NULL,
  m3_foreign = if (!is.null(inst_panel)) m3_foreign else NULL,
  m3_foreign_net = if (!is.null(inst_panel)) m3_foreign_net else NULL,
  m4_vol = if (!is.null(stock_q)) m4_vol else NULL,
  m4_size = if (!is.null(stock_q)) m4_size else NULL,
  symmetry = symmetry_test,
  nw_se_1a = nw1a,
  nw_se_1b = nw1b
)
models <- models[!sapply(models, is.null)]
saveRDS(models, file.path(data_dir, "main_models.rds"))

# ============================================================================
# Diagnostics
# ============================================================================

n_pe_stocks <- if (!is.null(pe_panel)) n_distinct(pe_panel$stock_code) else 0
n_inst_stocks <- if (!is.null(inst_panel)) n_distinct(inst_panel$stock_code) else 0
n_stock_firms <- if (!is.null(stock_q)) n_distinct(stock_q$stock_code) else 0

diagnostics <- list(
  n_treated = max(n_pe_stocks, n_inst_stocks, n_stock_firms, 1),
  n_pre = sum(taiex_q$yq < 20131),
  n_obs = nrow(taiex_m) + nrow(pe_panel %||% data.frame()) + nrow(inst_panel %||% data.frame()),
  n_firms = max(n_pe_stocks, n_inst_stocks, n_stock_firms),
  n_quarters = n_distinct(taiex_q$yq),
  taiex_months = nrow(taiex_m),
  pe_panel_obs = nrow(pe_panel %||% data.frame()),
  inst_panel_obs = nrow(inst_panel %||% data.frame())
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat("Treated stocks:", diagnostics$n_treated, "\n")
cat("Pre-periods:", diagnostics$n_pre, "\n")
cat("Total obs:", diagnostics$n_obs, "\n")
cat("PE panel:", diagnostics$pe_panel_obs, "\n")
cat("Inst panel:", diagnostics$inst_panel_obs, "\n")
cat("\nAll models saved.\n")
