# =============================================================================
# 04_robustness.R — Robustness checks
# APEP-0634: Disaster Salience and the Costs of Safety Regulation
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

# ─── 1. Binary treatment (above-median mining share) ────────────────────────
cat("=== Binary Treatment DiD ===\n")

# Define treated as counties with mining_share above median among coal counties
med_share <- median(panel$mining_share[panel$mining_share > 0], na.rm = TRUE)
cat(sprintf("Median mining share (among >0): %.4f\n", med_share))

panel <- panel |>
  mutate(
    high_mining = as.integer(mining_share > med_share),
    binary_post_miner = high_mining * post_miner,
    binary_post_ubb = high_mining * post_ubb
  )

b_emp <- feols(log_emp ~ binary_post_miner + binary_post_ubb | county_id + time_q,
               data = panel, cluster = ~state_fips)
b_earn <- feols(log_earn ~ binary_post_miner + binary_post_ubb | county_id + time_q,
                data = panel, cluster = ~state_fips)

etable(b_emp, b_earn, headers = c("Log Emp (Binary)", "Log Earn (Binary)"))

# ─── 2. Exclude West Virginia (most affected by UBB) ────────────────────────
cat("\n=== Excluding West Virginia ===\n")

panel_no_wv <- panel |> filter(state_abbr != "WV")

no_wv_emp <- feols(log_emp ~ treat_post + treat_post_ubb | county_id + time_q,
                   data = panel_no_wv, cluster = ~state_fips)
no_wv_earn <- feols(log_earn ~ treat_post + treat_post_ubb | county_id + time_q,
                    data = panel_no_wv, cluster = ~state_fips)

etable(no_wv_emp, no_wv_earn, headers = c("Excl WV: Emp", "Excl WV: Earn"))

# ─── 3. Appalachian vs Western coal states ──────────────────────────────────
cat("\n=== Appalachian vs Western Coal States ===\n")

appalachian <- c("WV", "VA", "KY", "PA", "OH", "TN", "AL", "MD")
western <- c("WY", "MT", "CO", "UT", "NM", "ND", "TX")

panel <- panel |>
  mutate(
    region = case_when(
      state_abbr %in% appalachian ~ "Appalachian",
      state_abbr %in% western ~ "Western",
      TRUE ~ "Other"
    )
  )

app_emp <- feols(log_emp ~ treat_post + treat_post_ubb | county_id + time_q,
                 data = panel |> filter(region == "Appalachian"),
                 cluster = ~state_fips)

west_emp <- feols(log_emp ~ treat_post + treat_post_ubb | county_id + time_q,
                  data = panel |> filter(region == "Western"),
                  cluster = ~state_fips)

etable(app_emp, west_emp, headers = c("Appalachian", "Western"))

# ─── 4. Placebo: Non-mining industries in mining counties ────────────────────
cat("\n=== Placebo: Non-Mining Employment ===\n")

placebo_emp <- feols(log_emp_nonmining ~ treat_post + treat_post_ubb |
                       county_id + time_q,
                     data = panel, cluster = ~state_fips)

placebo_hire <- feols(log(pmax(hire_total, 1)) ~ treat_post + treat_post_ubb |
                        county_id + time_q,
                      data = panel, cluster = ~state_fips)

etable(placebo_emp, placebo_hire,
       headers = c("Non-Mining Emp", "Hires"))

# ─── 5. Different pre-treatment share base years ─────────────────────────────
cat("\n=== Alternative Base Years for Mining Share ===\n")

# Re-compute mining share using 2003 instead of 2005
raw <- readRDS("../data/qwi_raw.rds")
coal_state_abbrs <- c("AL", "AR", "CO", "IL", "IN", "KS", "KY", "LA", "MD", "MO",
                       "MT", "MS", "ND", "NM", "OH", "OK", "PA", "TN", "TX", "UT",
                       "VA", "WA", "WV", "WY")

mining_2003 <- raw |>
  filter(industry == 212, year == 2003, state_abbr %in% coal_state_abbrs) |>
  group_by(geography) |>
  summarize(emp_m03 = mean(EmpTotal, na.rm = TRUE), .groups = "drop")

total_2003 <- raw |>
  filter(industry == 0, year == 2003, state_abbr %in% coal_state_abbrs) |>
  group_by(geography) |>
  summarize(emp_t03 = mean(EmpTotal, na.rm = TRUE), .groups = "drop")

share_2003 <- mining_2003 |>
  left_join(total_2003, by = "geography") |>
  mutate(mining_share_03 = ifelse(is.finite(emp_m03 / emp_t03), emp_m03 / emp_t03, 0))

panel_alt <- panel |>
  left_join(share_2003 |> select(geography, mining_share_03), by = "geography") |>
  mutate(
    mining_share_03 = replace_na(mining_share_03, 0),
    treat_post_03 = mining_share_03 * post_miner,
    treat_post_ubb_03 = mining_share_03 * post_ubb
  )

alt_emp <- feols(log_emp ~ treat_post_03 + treat_post_ubb_03 | county_id + time_q,
                 data = panel_alt, cluster = ~state_fips)
etable(alt_emp, headers = "2003 Base Year")

# ─── 6. Quarterly event study ───────────────────────────────────────────────
cat("\n=== Quarterly Event Study around UBB ===\n")

# Event time in quarters relative to UBB (2010Q2)
panel <- panel |>
  mutate(
    ubb_event_q = time_q - (10 * 4 + 2),  # 2010Q2 = quarter 42
    ubb_event_q = ifelse(abs(ubb_event_q) <= 12, ubb_event_q, NA)
  )

es_ubb <- feols(log_emp ~ i(ubb_event_q, mining_share, ref = -1) |
                   county_id + time_q,
                 data = panel |> filter(!is.na(ubb_event_q)),
                 cluster = ~state_fips)

cat("Quarterly event study around UBB:\n")
print(summary(es_ubb))

# ─── Save robustness models ─────────────────────────────────────────────────
saveRDS(list(
  b_emp = b_emp, b_earn = b_earn,
  no_wv_emp = no_wv_emp, no_wv_earn = no_wv_earn,
  app_emp = app_emp, west_emp = west_emp,
  placebo_emp = placebo_emp, placebo_hire = placebo_hire,
  alt_emp = alt_emp, es_ubb = es_ubb
), "../data/robustness_models.rds")

saveRDS(panel, "../data/analysis_panel.rds")  # Updated with new variables
cat("\nSaved: data/robustness_models.rds\n")
