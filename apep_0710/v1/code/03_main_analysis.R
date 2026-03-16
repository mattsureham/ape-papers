# 03_main_analysis.R — Main RD and diff-in-disc estimation
# apep_0710: Ukraine ProZorro Procurement Thresholds

source("00_packages.R")

df <- readRDS("../data/prozorro_clean.rds")

cat("\n=== MAIN ANALYSIS ===\n")

# ══════════════════════════════════════════════════════════════════
# Part 1: Peacetime RD (2017-2021)
# ══════════════════════════════════════════════════════════════════

df_pre <- df %>% filter(post == 0)
cat("\nPeacetime sample:", nrow(df_pre), "observations\n")

# ── 1a. RD: Price Savings ─────────────────────────────────────────
# Only tenders with valid savings
df_savings_pre <- df_pre %>% filter(!is.na(savings_pct))
cat("With savings data:", nrow(df_savings_pre), "\n")

if (nrow(df_savings_pre) > 200) {
  rd_savings_pre <- rdrobust(
    y = df_savings_pre$savings_pct,
    x = df_savings_pre$running,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\n--- Peacetime RD: Price Savings (%) ---\n")
  summary(rd_savings_pre)
} else {
  cat("Insufficient savings data for RD. Using OLS.\n")
  rd_savings_pre <- NULL
}

# ── 1b. RD: Number of Bids ───────────────────────────────────────
df_bids_pre <- df_pre %>% filter(!is.na(n_bids))

if (nrow(df_bids_pre) > 200) {
  rd_bids_pre <- rdrobust(
    y = df_bids_pre$n_bids,
    x = df_bids_pre$running,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\n--- Peacetime RD: Number of Bids ---\n")
  summary(rd_bids_pre)
} else {
  rd_bids_pre <- NULL
}

# ── 1c. RD: Competitive Procedure ────────────────────────────────
if (nrow(df_pre) > 200) {
  rd_comp_pre <- rdrobust(
    y = df_pre$is_competitive,
    x = df_pre$running,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\n--- Peacetime RD: Competitive Procedure ---\n")
  summary(rd_comp_pre)
} else {
  rd_comp_pre <- NULL
}

# ══════════════════════════════════════════════════════════════════
# Part 2: Wartime RD (2022-2024)
# ══════════════════════════════════════════════════════════════════

df_post <- df %>% filter(post == 1)
cat("\nWartime sample:", nrow(df_post), "observations\n")

df_savings_post <- df_post %>% filter(!is.na(savings_pct))

if (nrow(df_savings_post) > 200) {
  rd_savings_post <- rdrobust(
    y = df_savings_post$savings_pct,
    x = df_savings_post$running,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\n--- Wartime RD: Price Savings (%) ---\n")
  summary(rd_savings_post)
} else {
  rd_savings_post <- NULL
}

if (nrow(df_post) > 200) {
  rd_bids_post <- rdrobust(
    y = df_post$n_bids,
    x = df_post$running,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\n--- Wartime RD: Number of Bids ---\n")
  summary(rd_bids_post)

  rd_comp_post <- rdrobust(
    y = df_post$is_competitive,
    x = df_post$running,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\n--- Wartime RD: Competitive Procedure ---\n")
  summary(rd_comp_post)
} else {
  rd_bids_post <- NULL
  rd_comp_post <- NULL
}

# ══════════════════════════════════════════════════════════════════
# Part 3: Diff-in-Disc (parametric)
# ══════════════════════════════════════════════════════════════════

cat("\n=== DIFF-IN-DISCONTINUITIES ===\n")

# Bandwidth: restrict to tenders within optimal bandwidth of threshold
# Use a reasonable parametric bandwidth (e.g., 100K UAH = 50% of threshold)
bw <- 100000
df_bw <- df %>% filter(abs(running) <= bw)
cat("Observations within bandwidth (±", bw/1000, "K UAH):", nrow(df_bw), "\n")

# ── 3a. Diff-in-disc: Savings ────────────────────────────────────
df_bw_sav <- df_bw %>% filter(!is.na(savings_pct))

if (nrow(df_bw_sav) > 100) {
  # Main spec: linear in running variable, allow different slopes
  did_savings <- feols(
    savings_pct ~ above * post + running + running:above |
      region_en + year,
    data = df_bw_sav,
    vcov = ~region_en
  )
  cat("\n--- Diff-in-Disc: Savings ---\n")
  summary(did_savings)
} else {
  did_savings <- NULL
}

# ── 3b. Diff-in-disc: Bids ──────────────────────────────────────
if (nrow(df_bw) > 100) {
  did_bids <- feols(
    n_bids ~ above * post + running + running:above |
      region_en + year,
    data = df_bw,
    vcov = ~region_en
  )
  cat("\n--- Diff-in-Disc: Bids ---\n")
  summary(did_bids)
} else {
  did_bids <- NULL
}

# ── 3c. Diff-in-disc: Competitive Procedure ─────────────────────
if (nrow(df_bw) > 100) {
  did_comp <- feols(
    is_competitive ~ above * post + running + running:above |
      region_en + year,
    data = df_bw,
    vcov = ~region_en
  )
  cat("\n--- Diff-in-Disc: Competitive ---\n")
  summary(did_comp)
} else {
  did_comp <- NULL
}

# ══════════════════════════════════════════════════════════════════
# Part 4: Triple Difference (frontline heterogeneity)
# ══════════════════════════════════════════════════════════════════

cat("\n=== TRIPLE DIFFERENCE ===\n")

if (nrow(df_bw) > 100 && sum(df_bw$frontline) > 50) {
  # Triple-diff: Above × Post × Frontline
  ddd_savings <- feols(
    savings_pct ~ above * post * frontline + running + running:above |
      region_en + year,
    data = df_bw %>% filter(!is.na(savings_pct)),
    vcov = ~region_en
  )
  cat("\n--- Triple-Diff: Savings ---\n")
  summary(ddd_savings)

  ddd_bids <- feols(
    n_bids ~ above * post * frontline + running + running:above |
      region_en + year,
    data = df_bw,
    vcov = ~region_en
  )
  cat("\n--- Triple-Diff: Bids ---\n")
  summary(ddd_bids)

  ddd_comp <- feols(
    is_competitive ~ above * post * frontline + running + running:above |
      region_en + year,
    data = df_bw,
    vcov = ~region_en
  )
  cat("\n--- Triple-Diff: Competitive ---\n")
  summary(ddd_comp)
} else {
  cat("Insufficient frontline observations for DDD.\n")
  ddd_savings <- ddd_bids <- ddd_comp <- NULL
}

# ══════════════════════════════════════════════════════════════════
# Save results and diagnostics
# ══════════════════════════════════════════════════════════════════

# Diagnostics for validation
n_treated <- sum(df$above == 1)
n_pre <- length(unique(df$year[df$post == 0]))
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_oblasts = length(unique(df$region_en)),
  n_prewar = sum(df$post == 0),
  n_postwar = sum(df$post == 1),
  n_frontline = sum(df$frontline == 1),
  bw_used = bw,
  n_within_bw = nrow(df_bw)
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save model objects
save(
  rd_savings_pre, rd_bids_pre, rd_comp_pre,
  rd_savings_post, rd_bids_post, rd_comp_post,
  did_savings, did_bids, did_comp,
  ddd_savings, ddd_bids, ddd_comp,
  file = "../data/models.RData"
)
cat("Model objects saved.\n")
