## 02_clean_data.R — Construct analysis variables
## APEP-1032: The Deterrence Gap

source("00_packages.R")

raw <- readRDS("../data/fdic_raw.rds")
cat("Loaded:", nrow(raw), "bank-quarters\n")

# ── Parse dates ──────────────────────────────────────────────────────────────
df <- raw %>%
  mutate(
    date = as.Date(REPDTE, format = "%Y%m%d"),
    year = as.integer(format(date, "%Y")),
    quarter = as.integer(format(date, "%m")) %/% 3,
    # Create a numeric quarter variable (1 = 2014Q1, ...)
    yq = year + (quarter - 1) / 4,
    yq_label = paste0(year, "Q", quarter)
  )

# Numeric time index (quarters since 2014Q1)
df <- df %>%
  mutate(
    time_q = (year - 2014) * 4 + quarter
  )

# ── Define treatment and control groups ──────────────────────────────────────
# Treatment: $1B–$3B (in thousands: 1,000,000–3,000,000)
# Control: $3B–$10B (in thousands: 3,000,000–10,000,000)
# Buffer zone below: $500M–$1B (for placebo tests)

# Use 2018Q2 (pre-treatment) asset size to assign groups
# This avoids endogenous sorting into treatment based on post-policy growth
pre_assets <- df %>%
  filter(REPDTE == "20180630") %>%
  select(CERT, ASSET_PRE = ASSET)

cat("Banks with 2018Q2 data:", nrow(pre_assets), "\n")

df <- df %>%
  left_join(pre_assets, by = "CERT")

# Drop banks without 2018Q2 data (can't assign treatment)
df <- df %>% filter(!is.na(ASSET_PRE))
cat("After requiring 2018Q2 anchor:", n_distinct(df$CERT), "banks\n")

# Assign groups based on PRE-treatment assets
df <- df %>%
  mutate(
    group = case_when(
      ASSET_PRE >= 500000 & ASSET_PRE < 1000000 ~ "placebo",
      ASSET_PRE >= 1000000 & ASSET_PRE < 3000000 ~ "treated",
      ASSET_PRE >= 3000000 & ASSET_PRE <= 10000000 ~ "control",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(group))

cat("Group sizes (unique banks):\n")
df %>% distinct(CERT, group) %>% count(group) %>% print()

# ── Construct outcome variables ──────────────────────────────────────────────
df <- df %>%
  mutate(
    # Noncurrent loan ratio (primary outcome)
    ncl_ratio = ifelse(LNLSGR > 0, NCLNLS / LNLSGR * 100, NA_real_),

    # Net charge-off ratio
    nco_ratio = ifelse(LNLSGR > 0, NTLNLS / LNLSGR * 100, NA_real_),

    # Loan composition shares
    cre_share = ifelse(LNLSGR > 0, LNRE / LNLSGR * 100, NA_real_),
    ci_share  = ifelse(LNLSGR > 0, LNCI / LNLSGR * 100, NA_real_),
    con_share = ifelse(LNLSGR > 0, LNCON / LNLSGR * 100, NA_real_),

    # Asset growth (log assets)
    log_asset = log(ASSET),

    # Tier 1 capital ratio
    tier1_ratio = IDT1CER,

    # Return on assets
    roa = ROA,

    # Treatment indicators
    treat = as.integer(group == "treated"),
    post = as.integer(date >= as.Date("2018-07-01")),
    treat_post = treat * post,

    # Event time (quarters relative to 2018Q3 = time 0)
    # 2018Q3 is time_q = 19 (when 2014Q1 = 1)
    event_time = time_q - 19
  )

# ── Restrict to analysis sample ─────────────────────────────────────────────
# Main sample: treatment + control (exclude placebo for main analysis)
analysis <- df %>%
  filter(group %in% c("treated", "control")) %>%
  # Require 2016Q1–2023Q4 (drop 2014-2015 for balanced-ish panel)
  filter(year >= 2016 & year <= 2023)

cat("\nAnalysis sample:\n")
cat("  Bank-quarters:", nrow(analysis), "\n")
cat("  Unique banks:", n_distinct(analysis$CERT), "\n")
cat("  Treated:", sum(analysis$treat == 1 & analysis$REPDTE == "20180630"), "\n")
cat("  Control:", sum(analysis$treat == 0 & analysis$REPDTE == "20180630"), "\n")
cat("  Date range:", min(analysis$REPDTE), "to", max(analysis$REPDTE), "\n")

# ── Summary statistics ───────────────────────────────────────────────────────
pre_summary <- analysis %>%
  filter(post == 0) %>%
  group_by(group) %>%
  summarise(
    n_banks = n_distinct(CERT),
    mean_assets = mean(ASSET / 1e6, na.rm = TRUE),  # in billions
    mean_ncl = mean(ncl_ratio, na.rm = TRUE),
    sd_ncl = sd(ncl_ratio, na.rm = TRUE),
    mean_nco = mean(nco_ratio, na.rm = TRUE),
    mean_tier1 = mean(tier1_ratio, na.rm = TRUE),
    mean_roa = mean(roa, na.rm = TRUE),
    mean_cre = mean(cre_share, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment summary (2016-2018Q2):\n")
print(pre_summary)

# Save
saveRDS(df, "../data/fdic_full.rds")
saveRDS(analysis, "../data/fdic_analysis.rds")

# Also save placebo sample
placebo <- df %>%
  filter(group %in% c("placebo", "control")) %>%
  filter(year >= 2016 & year <= 2023) %>%
  mutate(
    treat = as.integer(group == "placebo"),
    treat_post = treat * post
  )
saveRDS(placebo, "../data/fdic_placebo.rds")

cat("\n✓ Data cleaning complete.\n")
cat("  Analysis sample saved: data/fdic_analysis.rds\n")
cat("  Placebo sample saved: data/fdic_placebo.rds\n")
