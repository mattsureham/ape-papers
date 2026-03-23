# 02_clean_data.R — Construct state-month panel for SDID analysis
# apep_0801: California School Start Time Mandate and Teen Traffic Fatalities

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load raw data
# ============================================================
fars <- fread(file.path(data_dir, "fars_fatal_2015_2023.csv"))
pop <- fread(file.path(data_dir, "state_population_2015_2023.csv"))

cat(sprintf("FARS records loaded: %d\n", nrow(fars)))
cat(sprintf("Population records loaded: %d\n", nrow(pop)))

# ============================================================
# 2. Define age groups and hour blocks
# ============================================================
# Filter to valid hours (0-23; FARS codes 99 = unknown)
fars <- fars[HOUR >= 0 & HOUR <= 23]

# Age groups
fars[, age_group := fcase(
  AGE >= 15 & AGE <= 19, "teen",
  AGE >= 25 & AGE <= 54, "adult",
  default = "other"
)]

# Hour blocks — morning (6-8am) and evening control (6-8pm)
# Using 6:00-8:59 for morning (school commute) and 18:00-20:59 for evening
fars[, hour_block := fcase(
  HOUR >= 6 & HOUR <= 8, "morning",
  HOUR >= 18 & HOUR <= 20, "evening",
  default = "other"
)]

# Treatment indicator for California
fars[, ca := as.integer(STATE == 6)]

# ============================================================
# 3. Construct state × month × age_group × hour_block panel
# ============================================================
# Count fatalities by cell
cell_counts <- fars[age_group %in% c("teen", "adult") & hour_block %in% c("morning", "evening"),
  .(fatalities = .N),
  by = .(STATE, YEAR, MONTH, age_group, hour_block)
]

# Create full grid (all cells, including zeros)
states <- sort(unique(fars$STATE))
months <- 1:12
age_groups <- c("teen", "adult")
hour_blocks <- c("morning", "evening")

grid <- CJ(
  STATE = states,
  YEAR = years <- 2015:2023,
  MONTH = months,
  age_group = age_groups,
  hour_block = hour_blocks
)

# Merge counts onto grid
panel <- merge(grid, cell_counts, by = c("STATE", "YEAR", "MONTH", "age_group", "hour_block"), all.x = TRUE)
panel[is.na(fatalities), fatalities := 0]

# ============================================================
# 4. Merge population denominators
# ============================================================
panel <- merge(panel, pop[, .(STATE, YEAR, pop_teen, pop_adult)],
               by = c("STATE", "YEAR"), all.x = TRUE)

# Compute fatality rate per 100,000
panel[, population := fifelse(age_group == "teen", pop_teen, pop_adult)]
panel[, fatality_rate := fatalities / population * 100000]

# ============================================================
# 5. Create time variables
# ============================================================
# Year-month as numeric (for fixed effects and time trends)
panel[, ym := YEAR + (MONTH - 1) / 12]
panel[, year_month := sprintf("%d-%02d", YEAR, MONTH)]

# Calendar month for panel ID
panel[, t := (YEAR - 2015) * 12 + MONTH]

# Treatment indicator: CA × post July 2022
# SB 328 effective July 1, 2022 (2022-23 school year)
panel[, post := as.integer(YEAR > 2022 | (YEAR == 2022 & MONTH >= 7))]
panel[, ca := as.integer(STATE == 6)]
panel[, treat := ca * post]

# Academic year indicator (Aug-Jun)
panel[, acad_year := fifelse(MONTH >= 8, YEAR, YEAR - 1L)]
# School in session (roughly Sep-May, exclude summer)
panel[, school_session := as.integer(MONTH >= 9 | MONTH <= 5)]

# ============================================================
# 6. Create SDID-formatted data
# ============================================================
# For SDID: need state × time panel for teen morning fatalities
sdid_data <- panel[age_group == "teen" & hour_block == "morning",
  .(STATE, t, fatality_rate, fatalities, population, ca, post, YEAR, MONTH)
]

# ============================================================
# 7. Create hour-of-day distribution data
# ============================================================
# For distribution shift test: teen fatalities by hour
hour_dist <- fars[age_group == "teen",
  .(fatalities = .N),
  by = .(STATE, YEAR, HOUR, ca = as.integer(STATE == 6))
]

# Pre vs post
hour_dist[, post := as.integer(YEAR >= 2022)]
# Restrict to school year months (Sep-May)
hour_dist_school <- fars[age_group == "teen" & (MONTH >= 9 | MONTH <= 5),
  .(fatalities = .N),
  by = .(STATE, YEAR, HOUR, ca = as.integer(STATE == 6))
]
hour_dist_school[, post := as.integer(YEAR >= 2022)]

# ============================================================
# 8. Summary statistics and validation
# ============================================================
cat("\n=== Panel Summary ===\n")
cat(sprintf("Panel dimensions: %d rows\n", nrow(panel)))
cat(sprintf("States: %d\n", uniqueN(panel$STATE)))
cat(sprintf("Time periods: %d months\n", uniqueN(panel$t)))

# CA teen morning fatalities
ca_teen_morn <- panel[ca == 1 & age_group == "teen" & hour_block == "morning"]
cat(sprintf("\nCA teen morning fatalities per year:\n"))
print(ca_teen_morn[, .(total_fatalities = sum(fatalities)), by = YEAR])

# Pre-treatment mean
pre_mean <- ca_teen_morn[post == 0, mean(fatalities)]
post_mean <- ca_teen_morn[post == 1, mean(fatalities)]
cat(sprintf("\nCA teen morning fatalities/month: pre=%.2f, post=%.2f\n", pre_mean, post_mean))

# Check sample sizes for diagnostics
n_treated_states <- 1  # California only
n_pre <- uniqueN(panel[post == 0]$t)
n_post <- uniqueN(panel[post == 1]$t)
n_obs <- nrow(sdid_data)

cat(sprintf("\nDiagnostics: n_treated=%d states, n_pre=%d months, n_post=%d months, n_obs=%d\n",
            n_treated_states, n_pre, n_post, n_obs))

# ============================================================
# 9. Save processed data
# ============================================================
fwrite(panel, file.path(data_dir, "panel_state_month.csv"))
fwrite(sdid_data, file.path(data_dir, "sdid_teen_morning.csv"))
fwrite(hour_dist, file.path(data_dir, "hour_distribution_teen.csv"))
fwrite(hour_dist_school, file.path(data_dir, "hour_distribution_teen_school.csv"))

cat("\n=== Clean data saved ===\n")
