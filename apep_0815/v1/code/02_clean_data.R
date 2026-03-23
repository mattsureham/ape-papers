## 02_clean_data.R — Construct analysis panel
source("code/00_packages.R")

qwi_raw <- readRDS("data/qwi_raw.rds")
abawd <- readRDS("data/abawd_status.rds")

# ── Merge enforcement status ────────────────────────────────────
df <- merge(qwi_raw, abawd[, c("state_fips", "enforcement", "state_name")],
            by = "state_fips", all.x = TRUE)

# Drop states with no enforcement classification (shouldn't happen)
stopifnot("Missing enforcement for some states" = sum(is.na(df$enforcement)) == 0)

# ── Construct treatment variables ────────────────────────────────
# FRA Phase 1: September 1, 2023 → 2023 Q3
# FRA Phase 2: October 1, 2023 → 2023 Q4
# FRA Phase 3: October 1, 2024 → 2024 Q4

df <- df |>
  mutate(
    # Calendar quarter index (for FE)
    yq = paste0(year, "Q", quarter),

    # Post-FRA indicator (first treatment = 2023 Q3)
    post = as.integer(year > 2023 | (year == 2023 & quarter >= 3)),

    # Young age group (45-54, contains newly treated 50-54)
    young = as.integer(age_group == "45-54"),

    # Full enforcement state
    enforce = as.integer(enforcement == "full"),

    # Waiver state (for cleaner DDD contrast)
    waiver = as.integer(enforcement == "waiver"),

    # DDD interaction
    ddd = post * young * enforce,

    # Two-way interactions
    post_young = post * young,
    post_enforce = post * enforce,
    young_enforce = young * enforce,

    # State-age cell identifier
    state_age = paste(state_fips, age_group, sep = "_"),

    # Quarter numeric (for event study)
    qtr_num = (year - 2018) * 4 + quarter,

    # Relative time: quarters since 2023 Q3 (= quarter 22)
    # 2023Q3 is the 22nd quarter from 2018Q1
    rel_qtr = qtr_num - 22,

    # Log employment (main outcome)
    log_emp = log(Emp),

    # Log hires
    log_hires = log(pmax(HirA, 1)),

    # Log separations
    log_sep = log(pmax(Sep, 1)),

    # Log earnings
    log_earn = log(pmax(EarnS, 1))
  )

# ── Summary statistics ───────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(df), "\n")
cat("States:", n_distinct(df$state_fips), "\n")
cat("Quarters:", n_distinct(df$yq), "\n")
cat("State-age cells:", n_distinct(df$state_age), "\n")

cat("\n--- By enforcement status ---\n")
df |>
  filter(enforcement != "partial") |>
  group_by(enforcement, age_group) |>
  summarise(
    n_states = n_distinct(state_fips),
    mean_emp = mean(Emp, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

cat("\n--- Pre/Post balance (full enforcement + waiver only) ---\n")
df |>
  filter(enforcement %in% c("full", "waiver")) |>
  group_by(post, young) |>
  summarise(
    mean_emp = mean(Emp, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) |>
  print()

# ── Save analysis dataset ────────────────────────────────────────
# Main sample: full enforcement vs statewide waiver (cleanest contrast)
df_main <- df |>
  filter(enforcement %in% c("full", "waiver"))

cat("\nMain sample (full vs waiver):", nrow(df_main), "rows\n")
cat("  Full enforcement states:", n_distinct(df_main$state_fips[df_main$enforce == 1]), "\n")
cat("  Waiver states:", n_distinct(df_main$state_fips[df_main$waiver == 1]), "\n")

saveRDS(df, "data/panel_full.rds")
saveRDS(df_main, "data/panel_main.rds")
cat("\nSaved data/panel_main.rds and data/panel_full.rds\n")
