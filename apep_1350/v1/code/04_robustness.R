## 04_robustness.R — Robustness checks and placebo tests
## apep_1350: The Segregation Dividend

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
bw_cs <- results$bw_cs
race_panel <- results$race_panel
yq_to_int <- results$yq_to_int

bw_sector <- arrow::read_parquet("../data/analysis_panel_sector.parquet") |> as_tibble()
bw <- results$bw

# Restrict sector data to same window
bw_sector <- bw_sector |> filter(year >= 2005, year <= 2023)

# ── 1. Placebo: Health Care sector (NAICS 62) ──
cat("── Placebo: NAICS 62 (Health Care) ──\n")

bw_62 <- bw_sector |>
  filter(industry == "62", !is.na(bw_earn_ratio), is.finite(bw_earn_ratio)) |>
  mutate(
    time_id = as.integer(yq_to_int[as.character(yq)]),
    first_treat_id = if_else(
      first_treat_yq > 0,
      as.integer(yq_to_int[as.character(first_treat_yq)]),
      0L
    )
  ) |>
  filter(!is.na(time_id), !is.na(first_treat_id))

cs_62 <- att_gt(
  yname = "bw_earn_ratio",
  tname = "time_id",
  idname = "state_fips",
  gname = "first_treat_id",
  data = bw_62,
  control_group = "nevertreated",
  base_period = "universal"
)
cs_62_agg <- aggte(cs_62, type = "simple", na.rm = TRUE)
cat("CS ATT (NAICS 62 placebo, B/W ratio):\n")
print(summary(cs_62_agg))

# ── 2. Placebo: Accommodation/Food (NAICS 72) ──
cat("\n── Placebo: NAICS 72 (Accommodation/Food) ──\n")

bw_72 <- bw_sector |>
  filter(industry == "72", !is.na(bw_earn_ratio), is.finite(bw_earn_ratio)) |>
  mutate(
    time_id = as.integer(yq_to_int[as.character(yq)]),
    first_treat_id = if_else(
      first_treat_yq > 0,
      as.integer(yq_to_int[as.character(first_treat_yq)]),
      0L
    )
  ) |>
  filter(!is.na(time_id), !is.na(first_treat_id))

cs_72 <- att_gt(
  yname = "bw_earn_ratio",
  tname = "time_id",
  idname = "state_fips",
  gname = "first_treat_id",
  data = bw_72,
  control_group = "nevertreated",
  base_period = "universal"
)
cs_72_agg <- aggte(cs_72, type = "simple", na.rm = TRUE)
cat("CS ATT (NAICS 72 placebo, B/W ratio):\n")
print(summary(cs_72_agg))

# ── 3. Placebo: Pre-period false treatment (2010) ──
cat("\n── Placebo: False treatment date (2010Q1) ──\n")

bw_placebo <- results$bw_cs |>
  filter(yq < 2014) |>
  mutate(
    fake_post = yq >= 2010,
    fake_treat = expanded & yq >= 2010
  )

twfe_placebo <- feols(
  bw_earn_ratio ~ fake_treat | state_fips + time_id,
  data = bw_placebo,
  cluster = ~state_fips
)
cat("TWFE placebo (fake treatment 2010Q1):\n")
print(summary(twfe_placebo))

# ── 4. Event study for employment share ──
cat("\n── CS event study: Black employment share ──\n")
cs_share_es <- results$cs_share_es
cat("Dynamic ATT estimates (employment share):\n")
es_df <- data.frame(
  event_time = cs_share_es$egt,
  att = cs_share_es$att.egt,
  se = cs_share_es$se.egt
) |>
  mutate(
    ci_lower = att - 1.96 * se,
    ci_upper = att + 1.96 * se
  )
print(es_df |> filter(abs(event_time) <= 12))

# ── 5. Decomposition: Within vs Between ──
cat("\n── Decomposition: Within-state vs between-state ──\n")

# Check if the earnings gap is driven by:
# (a) within-state: Black earnings falling relative to White within same state
# (b) between-state: Black workers shifting to lower-paying states

bw_decomp <- bw_cs |>
  group_by(expanded, period = if_else(yq < 2014, "pre", "post")) |>
  summarise(
    mean_ratio = weighted.mean(bw_earn_ratio, w = total_emp, na.rm = TRUE),
    mean_black_share = weighted.mean(black_emp_share, w = total_emp, na.rm = TRUE),
    mean_earn_black = weighted.mean(EarnS_A2, w = Emp_A2, na.rm = TRUE),
    mean_earn_white = weighted.mean(EarnS_A1, w = Emp_A1, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

cat("Means by expansion status and period:\n")
print(bw_decomp)

# ── 6. Save robustness results ──
robust <- list(
  cs_62_agg = cs_62_agg,
  cs_72_agg = cs_72_agg,
  twfe_placebo = twfe_placebo,
  es_df = es_df,
  bw_decomp = bw_decomp
)
saveRDS(robust, "../data/robustness_results.rds")

cat("\n04_robustness.R complete.\n")
