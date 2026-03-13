# =============================================================================
# 02_clean_data.R — Construct analysis panel
# APEP-0634: Disaster Salience and the Costs of Safety Regulation
# =============================================================================

source("00_packages.R")

raw <- readRDS("../data/qwi_raw.rds")

# ─── Coal-producing states (states with significant coal production) ─────────
# EIA top coal-producing states by tonnage: WY, WV, PA, IL, KY, MT, IN, ND,
# TX, AL, CO, OH, VA, NM, UT, AR, MS, TN, OK, KS, LA, MD, MO, WA
coal_state_abbrs <- c(
  "AL", "AR", "CO", "IL", "IN", "KS", "KY", "LA", "MD", "MO",
  "MT", "MS", "ND", "NM", "OH", "OK", "PA", "TN", "TX", "UT",
  "VA", "WA", "WV", "WY"
)

# ─── Separate total employment and mining employment ─────────────────────────
# industry = 0 is total employment; industry = 212 is mining (excl oil/gas)
total <- raw |>
  filter(industry == 0, state_abbr %in% coal_state_abbrs) |>
  select(geography, year, quarter, state_abbr,
         emp_total = EmpTotal, earn_total = EarnS,
         hire_total = HirA, sep_total = Sep,
         jbgn_total = FrmJbGn, jbls_total = FrmJbLs,
         payroll_total = Payroll)

mining <- raw |>
  filter(industry == 212, state_abbr %in% coal_state_abbrs) |>
  select(geography, year, quarter, state_abbr,
         emp_mining = EmpTotal, earn_mining = EarnS,
         hire_mining = HirA, sep_mining = Sep,
         jbgn_mining = FrmJbGn, jbls_mining = FrmJbLs)

# ─── Compute pre-MINER Act mining employment share (using 2005 annual avg) ───
mining_share_2005 <- mining |>
  filter(year == 2005) |>
  group_by(geography) |>
  summarize(emp_mining_2005 = mean(emp_mining, na.rm = TRUE), .groups = "drop")

total_share_2005 <- total |>
  filter(year == 2005) |>
  group_by(geography) |>
  summarize(emp_total_2005 = mean(emp_total, na.rm = TRUE), .groups = "drop")

mining_share <- mining_share_2005 |>
  left_join(total_share_2005, by = "geography") |>
  mutate(
    mining_share = emp_mining_2005 / emp_total_2005,
    mining_share = ifelse(is.finite(mining_share), mining_share, 0)
  )

cat("Mining share distribution (2005):\n")
print(summary(mining_share$mining_share))
cat(sprintf("Counties with mining_share > 0: %d\n", sum(mining_share$mining_share > 0)))
cat(sprintf("Counties with mining_share > 0.05: %d\n", sum(mining_share$mining_share > 0.05)))
cat(sprintf("Counties with mining_share > 0.10: %d\n", sum(mining_share$mining_share > 0.10)))
cat(sprintf("Counties with mining_share > 0.20: %d\n", sum(mining_share$mining_share > 0.20)))

# ─── Build county-quarter panel ─────────────────────────────────────────────
# Merge total employment with mining share
panel <- total |>
  left_join(mining_share |> select(geography, mining_share, emp_mining_2005),
            by = "geography") |>
  mutate(
    mining_share = replace_na(mining_share, 0),
    emp_mining_2005 = replace_na(emp_mining_2005, 0)
  )

# Also merge in quarterly mining employment for sector-specific analysis
panel <- panel |>
  left_join(mining, by = c("geography", "year", "quarter", "state_abbr"))

# ─── Create time variables ──────────────────────────────────────────────────
panel <- panel |>
  mutate(
    # Time index (quarters since 2000Q1)
    time_q = (year - 2000) * 4 + quarter,
    # Post-MINER Act indicator (June 2006 → post from 2006Q3)
    post_miner = as.integer(year > 2006 | (year == 2006 & quarter >= 3)),
    # Post-UBB indicator (April 2010 → post from 2010Q2)
    post_ubb = as.integer(year > 2010 | (year == 2010 & quarter >= 2)),
    # Event time relative to MINER Act (in years, centered on 2006)
    event_year = year - 2006,
    # State FIPS (first 2 digits of geography)
    state_fips = as.character(geography %/% 1000),
    # County identifier
    county_id = geography,
    # Log outcomes
    log_emp = log(pmax(emp_total, 1)),
    log_earn = log(pmax(earn_total, 1)),
    log_emp_mining = log(pmax(emp_mining, 1)),
    # Non-mining employment
    emp_nonmining = emp_total - replace_na(emp_mining, 0),
    log_emp_nonmining = log(pmax(emp_nonmining, 1)),
    # Treatment intensity × post
    treat_post = mining_share * post_miner,
    treat_post_ubb = mining_share * post_ubb,
    # Binary treatment (above-median mining share among coal counties)
    high_coal = as.integer(mining_share > median(mining_share[mining_share > 0],
                                                  na.rm = TRUE))
  )

# ─── Restrict to counties with complete panels ──────────────────────────────
# Need data for at least 2001-2015 (balanced-ish)
county_coverage <- panel |>
  filter(!is.na(emp_total)) |>
  group_by(county_id) |>
  summarize(
    n_quarters = n(),
    min_year = min(year),
    max_year = max(year),
    .groups = "drop"
  ) |>
  filter(n_quarters >= 40, min_year <= 2002, max_year >= 2014)

cat(sprintf("\nCounties with adequate panel coverage: %d\n", nrow(county_coverage)))

panel <- panel |>
  semi_join(county_coverage, by = "county_id")

# ─── Summary statistics ─────────────────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Counties: %d\n", n_distinct(panel$county_id)))
cat(sprintf("States: %d\n", n_distinct(panel$state_fips)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Counties with mining_share > 0: %d\n",
            n_distinct(panel$county_id[panel$mining_share > 0])))
cat(sprintf("Counties with mining_share > 0.05: %d\n",
            n_distinct(panel$county_id[panel$mining_share > 0.05])))

# ─── Save ────────────────────────────────────────────────────────────────────
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(mining_share, "../data/mining_share.rds")
cat("\nSaved: data/analysis_panel.rds, data/mining_share.rds\n")
