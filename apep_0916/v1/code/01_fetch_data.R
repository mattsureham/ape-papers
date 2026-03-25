# =============================================================================
# 01_fetch_data.R — Fetch MLP linked panel + construct treatment variables
# Paper: When the Banks Broke (apep_0916)
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# ─────────────────────────────────────────────────────────────────────────────
# Override: manually load the full connection string from .env
# (The default loader truncates at the first semicolon in some configs)
# ─────────────────────────────────────────────────────────────────────────────
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export ", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\'"]$', "\\1", val)
    if (key == "AZURE_STORAGE_CONNECTION_STRING") {
      Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    }
  }
}

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure.\n")

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Unit Banking Law Classification (as of 1929)
# Source: Calomiris & Haber (2014), Wheelock (1995), Mitchener (2005)
# States that prohibited ALL branching ("unit banking" states)
# ─────────────────────────────────────────────────────────────────────────────
# FIPS codes for strict unit banking states (no branching permitted, ~1929)
unit_banking_states <- c(
  8,   # Colorado
  12,  # Florida
  17,  # Illinois
  19,  # Iowa
  20,  # Kansas
  27,  # Minnesota
  29,  # Missouri
  30,  # Montana
  31,  # Nebraska
  38,  # North Dakota
  40,  # Oklahoma
  48,  # Texas
  54,  # West Virginia
  56   # Wyoming
)
# Additional states with very limited branching (county-only or de facto unit)
limited_branching <- c(
  5,   # Arkansas
  18,  # Indiana
  21   # Kentucky
)

cat("Unit banking states (strict):", length(unit_banking_states), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Query MLP panel — select needed columns, filter to working-age men
# ─────────────────────────────────────────────────────────────────────────────
cat("Querying MLP 1920-1930-1940 panel from Azure...\n")

# First get the total count and basic stats
stats <- dbGetQuery(con, "
  SELECT
    COUNT(*) as n_total,
    COUNT(CASE WHEN age_1920 BETWEEN 18 AND 55 THEN 1 END) as n_working_age,
    COUNT(CASE WHEN sex_1920 = 1 AND age_1920 BETWEEN 18 AND 55 THEN 1 END) as n_men_working_age,
    AVG(occscore_1920) as mean_occscore_1920,
    AVG(occscore_1940) as mean_occscore_1940,
    COUNT(DISTINCT statefip_1920) as n_states,
    COUNT(DISTINCT countyicp_1920) as n_counties
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
")
cat("Total rows:", stats$n_total, "\n")
cat("Working-age men (18-55 in 1920):", stats$n_men_working_age, "\n")
cat("Mean occscore 1920:", round(stats$mean_occscore_1920, 2), "\n")
cat("Mean occscore 1940:", round(stats$mean_occscore_1940, 2), "\n")
cat("Distinct states:", stats$n_states, "\n")
cat("Distinct counties (ICP):", stats$n_counties, "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Compute county-level agricultural share from 1920 census
# (county = statefip × countyicp combination)
# ─────────────────────────────────────────────────────────────────────────────
cat("\nComputing county-level agricultural shares from 1920...\n")

county_ag <- dbGetQuery(con, "
  SELECT
    statefip_1920 as statefip,
    countyicp_1920 as countyicp,
    COUNT(*) as n_pop,
    SUM(CASE WHEN farm_1920 = 2 THEN 1 ELSE 0 END) as n_farm,
    AVG(CASE WHEN farm_1920 = 2 THEN 1.0 ELSE 0.0 END) as ag_share,
    AVG(occscore_1920) as mean_occscore_1920
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE statefip_1920 IS NOT NULL
    AND countyicp_1920 IS NOT NULL
    AND countyicp_1920 > 0
  GROUP BY statefip_1920, countyicp_1920
  HAVING COUNT(*) >= 50
")
cat("Counties with >= 50 individuals:", nrow(county_ag), "\n")
cat("Mean agricultural share:", round(mean(county_ag$ag_share), 3), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Pull individual-level analysis dataset
# Working-age men (18-55 in 1920), in states with valid FIPS
# ─────────────────────────────────────────────────────────────────────────────
cat("\nPulling individual-level analysis dataset...\n")

df <- dbGetQuery(con, "
  SELECT
    histid_1920,
    statefip_1920, countyicp_1920,
    statefip_1930, countyicp_1930,
    statefip_1940, countyicp_1940,
    age_1920, race_1920, bpl_1920, nativity_1920, marst_1920,
    farm_1920, classwkr_1920, occ1950_1920, ind1950_1920,
    occscore_1920, occscore_1930, occscore_1940,
    sei_1920, sei_1930, sei_1940,
    ownershp_1920, ownershp_1930, ownershp_1940,
    farm_1930, farm_1940,
    mover_20_30, mover_30_40, mover_20_40
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE sex_1920 = 1
    AND age_1920 BETWEEN 18 AND 55
    AND statefip_1920 IS NOT NULL
    AND statefip_1920 <= 56
    AND countyicp_1920 IS NOT NULL
    AND countyicp_1920 > 0
    AND occscore_1920 > 0
    AND occscore_1940 > 0
")
cat("Individual dataset rows:", nrow(df), "\n")
cat("Columns:", ncol(df), "\n")

dbDisconnect(con, shutdown = TRUE)

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Add treatment variables
# ─────────────────────────────────────────────────────────────────────────────
df <- as.data.table(df)

# Unit banking law indicator (based on 1920 state of residence)
df[, unit_banking := as.integer(statefip_1920 %in% unit_banking_states)]
df[, unit_banking_broad := as.integer(statefip_1920 %in% c(unit_banking_states, limited_branching))]

# Merge county-level agricultural share
county_ag_dt <- as.data.table(county_ag)
setnames(county_ag_dt, c("statefip", "countyicp"), c("statefip_1920", "countyicp_1920"))
df <- merge(df, county_ag_dt[, .(statefip_1920, countyicp_1920, ag_share)],
            by = c("statefip_1920", "countyicp_1920"), all.x = TRUE)

# Interaction: unit banking × agricultural share
df[, ub_x_ag := unit_banking * ag_share]

# ─────────────────────────────────────────────────────────────────────────────
# Step 6: Construct outcome variables
# ─────────────────────────────────────────────────────────────────────────────

# Long difference in occupational income score (1920 → 1940)
df[, delta_occscore_20_40 := occscore_1940 - occscore_1920]
df[, delta_occscore_20_30 := occscore_1930 - occscore_1920]
df[, delta_occscore_30_40 := occscore_1940 - occscore_1930]

# Long difference in SEI
df[, delta_sei_20_40 := sei_1940 - sei_1920]

# Occupational downgrading indicator
df[, occ_downgrade := as.integer(occscore_1940 < occscore_1920)]

# Homeownership transitions (IPUMS: 1=owned, 2=rented)
df[, homeowner_1920 := as.integer(ownershp_1920 == 1)]
df[, homeowner_1940 := as.integer(ownershp_1940 == 1)]
df[, lost_home := as.integer(homeowner_1920 == 1 & homeowner_1940 == 0)]

# Farm exit
df[, farm_1920_ind := as.integer(farm_1920 == 2)]
df[, farm_1940_ind := as.integer(farm_1940 == 2)]
df[, farm_exit := as.integer(farm_1920_ind == 1 & farm_1940_ind == 0)]

# Migration (already in panel: mover_20_40)
df[, migrated := as.integer(mover_20_40 == 1)]

# ─────────────────────────────────────────────────────────────────────────────
# Step 7: Construct control variables
# ─────────────────────────────────────────────────────────────────────────────
df[, age_sq := age_1920^2]
df[, white := as.integer(race_1920 == 1)]
df[, foreign_born := as.integer(nativity_1920 >= 4)]  # IPUMS: 4,5 = foreign born
df[, married_1920 := as.integer(marst_1920 <= 2)]     # IPUMS: 1,2 = married

# Census region (for region FE)
df[, region := fcase(
  statefip_1920 %in% c(9, 23, 25, 33, 34, 36, 42, 44, 50), "Northeast",
  statefip_1920 %in% c(17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55), "Midwest",
  statefip_1920 %in% c(1, 5, 10, 11, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54), "South",
  statefip_1920 %in% c(4, 6, 8, 16, 30, 32, 35, 41, 49, 53, 56), "West",
  default = "Other"
)]

# ─────────────────────────────────────────────────────────────────────────────
# Step 8: Save analysis dataset
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Final Analysis Dataset ===\n")
cat("Observations:", nrow(df), "\n")
cat("Unit banking states:", sum(df$unit_banking == 1), "(", round(mean(df$unit_banking)*100, 1), "%)\n")
cat("Mean ag share:", round(mean(df$ag_share, na.rm = TRUE), 3), "\n")
cat("Mean delta occscore (1920-1940):", round(mean(df$delta_occscore_20_40), 3), "\n")
cat("Share downgraded:", round(mean(df$occ_downgrade), 3), "\n")
cat("Share migrated:", round(mean(df$migrated), 3), "\n")
cat("Share lost home:", round(mean(df$lost_home, na.rm = TRUE), 3), "\n")

# State-level summary
state_summary <- df[, .(
  n = .N,
  unit_banking = mean(unit_banking),
  ag_share = mean(ag_share, na.rm = TRUE),
  mean_delta_occ = mean(delta_occscore_20_40),
  pct_downgrade = mean(occ_downgrade)
), by = statefip_1920][order(statefip_1920)]
cat("\nState-level summary (first 20):\n")
print(head(state_summary, 20))

# Save
fwrite(df, "../data/analysis_panel.csv")
saveRDS(county_ag, "../data/county_ag_shares.rds")
cat("\nSaved analysis_panel.csv (", nrow(df), "rows ) and county_ag_shares.rds\n")
