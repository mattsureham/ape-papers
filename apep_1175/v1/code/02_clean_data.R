# =============================================================================
# 02_clean_data.R — Merge instrument, QWI, and population; construct analysis panel
# =============================================================================

source("00_packages.R")

# ─────────────────────────────────────────────────────────────────────────────
# 1. Load data
# ─────────────────────────────────────────────────────────────────────────────
instrument <- fread("../data/arcos_instrument.csv")
qwi <- fread("../data/qwi_annual.csv")
county_pop <- fread("../data/county_pop.csv")

message(sprintf("Instrument: %d counties", nrow(instrument)))
message(sprintf("QWI: %d rows", nrow(qwi)))
message(sprintf("Population: %d rows", nrow(county_pop)))

# ─────────────────────────────────────────────────────────────────────────────
# 2. Normalize instrument: pills per capita using 2009 population
# ─────────────────────────────────────────────────────────────────────────────
pop_2009 <- county_pop[year == 2009, .(fips, pop_2009 = pop)]

instrument <- merge(instrument, pop_2009, by = "fips", all.x = TRUE)
instrument <- instrument[!is.na(pop_2009) & pop_2009 > 0]

# Total oxycodone pills per capita (2006-2009 cumulative)
instrument[, total_oxy_pc := oxy_pills / pop_2009]
# Total pills per capita (all opioids)
instrument[, total_pills_pc := total_pills / pop_2009]

# ─────────────────────────────────────────────────────────────────────────────
# 3. Construct age groups matching QWI
# ─────────────────────────────────────────────────────────────────────────────
# QWI age groups: A00=All, A01=14-18, A02=19-21, A03=22-24, A04=25-34,
#                 A05=35-44, A06=45-54, A07=55-64, A08=65+

# Define prime-age (25-44) and older (55-64) for main and placebo analyses
qwi[, age_group := fcase(
  agegrp == "A00", "all",
  agegrp %in% c("A04", "A05"), "prime_age",  # 25-44
  agegrp %in% c("A01", "A02", "A03"), "young",  # 14-24
  agegrp %in% c("A06", "A07"), "older",  # 45-64
  agegrp == "A08", "elderly",  # 65+
  default = NA_character_
)]

# Aggregate by our age categories
qwi_agg <- qwi[!is.na(age_group), .(
  Emp = sum(Emp, na.rm = TRUE),
  EarnS = weighted.mean(EarnS, Emp, na.rm = TRUE),
  HirA = sum(HirA, na.rm = TRUE),
  Sep = sum(Sep, na.rm = TRUE)
), by = .(fips, year, age_group)]

# ─────────────────────────────────────────────────────────────────────────────
# 4. Merge everything into analysis panel
# ─────────────────────────────────────────────────────────────────────────────
panel <- merge(qwi_agg, instrument[, .(fips, oxy_share, total_oxy_pc, total_pills_pc, pop_2009)],
               by = "fips", all.x = FALSE)

# Add population for each year (for weighting)
panel <- merge(panel, county_pop[, .(fips, year, pop)], by = c("fips", "year"), all.x = TRUE)

# Log outcomes
panel[Emp > 0, log_emp := log(Emp)]
panel[EarnS > 0, log_earn := log(EarnS)]
panel[, hire_rate := HirA / fifelse(Emp > 0, Emp, NA_real_)]
panel[, sep_rate := Sep / fifelse(Emp > 0, Emp, NA_real_)]

# Create state FIPS for clustering
panel[, state_fips := substr(fips, 1, 2)]

# Post-reform indicator
panel[, post := as.integer(year >= 2010)]

# Event time (relative to 2010)
panel[, event_time := year - 2010]

# Interaction: instrument × post
panel[, oxy_share_post := oxy_share * post]

# ─────────────────────────────────────────────────────────────────────────────
# 5. Sample restrictions
# ─────────────────────────────────────────────────────────────────────────────
# Drop tiny counties (< 1000 pop)
panel <- panel[pop_2009 >= 1000]

# Drop counties with zero oxycodone (no variation in instrument)
panel <- panel[total_oxy_pc > 0]

# Require complete panel 2005-2019
county_year_counts <- panel[age_group == "all", .N, by = fips]
complete_counties <- county_year_counts[N >= 13, fips]  # at least 13 of 15 years
panel <- panel[fips %in% complete_counties]

message(sprintf("Analysis panel: %d rows, %d counties, years %d-%d",
                nrow(panel), uniqueN(panel$fips), min(panel$year), max(panel$year)))

# ─────────────────────────────────────────────────────────────────────────────
# 6. Quartile indicators for instrument
# ─────────────────────────────────────────────────────────────────────────────
breaks <- quantile(instrument[fips %in% complete_counties]$oxy_share, c(0, 0.25, 0.5, 0.75, 1))
panel[, oxy_quartile := cut(oxy_share, breaks = breaks, include.lowest = TRUE, labels = FALSE)]

# ─────────────────────────────────────────────────────────────────────────────
# 7. Summary statistics
# ─────────────────────────────────────────────────────────────────────────────
sumstats <- panel[age_group == "all" & year == 2009, .(
  n_counties = .N,
  mean_oxy_share = mean(oxy_share),
  sd_oxy_share = sd(oxy_share),
  p10_oxy_share = quantile(oxy_share, 0.10),
  p90_oxy_share = quantile(oxy_share, 0.90),
  mean_emp = mean(Emp, na.rm = TRUE),
  mean_earn = mean(EarnS, na.rm = TRUE),
  mean_pop = mean(pop_2009)
)]
print(sumstats)

# ─────────────────────────────────────────────────────────────────────────────
# 8. Save
# ─────────────────────────────────────────────────────────────────────────────
fwrite(panel, "../data/analysis_panel.csv")
message("Saved analysis panel to data/analysis_panel.csv")
