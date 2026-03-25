# =============================================================================
# 03b_wage_analysis.R — Add 1940 wage income as cross-sectional outcome
# Paper: When the Banks Broke (apep_0916)
# Reviewer feedback: all three reviewers requested INCWAGE analysis
# =============================================================================

source("00_packages.R")

# Load env for Azure
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

# Check if 1940 census has INCWAGE
cat("Checking 1940 census for INCWAGE...\n")
schema_1940 <- dbGetQuery(con, "
  SELECT column_name FROM
  (DESCRIBE SELECT * FROM 'az://raw/ipums_fullcount/us1940b.parquet')
  WHERE column_name ILIKE '%wage%' OR column_name ILIKE '%inc%'
")
cat("Income columns:", paste(schema_1940$column_name, collapse = ", "), "\n")

# Join MLP panel to 1940 census to get INCWAGE
# Use histid_1940 from MLP → HISTID in 1940 census
cat("Joining MLP panel to 1940 census for INCWAGE...\n")

wage_stats <- dbGetQuery(con, "
  SELECT
    COUNT(*) as n_total,
    COUNT(CASE WHEN c.INCWAGE IS NOT NULL AND c.INCWAGE > 0 AND c.INCWAGE < 999998 THEN 1 END) as n_with_wage,
    AVG(CASE WHEN c.INCWAGE > 0 AND c.INCWAGE < 999998 THEN c.INCWAGE END) as mean_wage,
    STDDEV(CASE WHEN c.INCWAGE > 0 AND c.INCWAGE < 999998 THEN c.INCWAGE END) as sd_wage
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet' m
  LEFT JOIN 'az://raw/ipums_fullcount/us1940b.parquet' c
    ON m.histid_1940 = c.HISTID
  WHERE m.sex_1920 = 1
    AND m.age_1920 BETWEEN 18 AND 55
    AND m.statefip_1920 <= 56
    AND m.countyicp_1920 > 0
    AND m.occscore_1920 > 0
    AND m.occscore_1940 > 0
")
cat("Wage stats:\n")
print(wage_stats)

# Pull wage data for analysis
cat("Pulling wage data for regression...\n")
wage_df <- dbGetQuery(con, "
  SELECT
    m.statefip_1920, m.countyicp_1920,
    m.age_1920, m.race_1920, m.nativity_1920, m.marst_1920,
    m.farm_1920, m.classwkr_1920, m.occscore_1920,
    c.INCWAGE as incwage_1940
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet' m
  LEFT JOIN 'az://raw/ipums_fullcount/us1940b.parquet' c
    ON m.histid_1940 = c.HISTID
  WHERE m.sex_1920 = 1
    AND m.age_1920 BETWEEN 18 AND 55
    AND m.statefip_1920 <= 56
    AND m.countyicp_1920 > 0
    AND m.occscore_1920 > 0
    AND m.occscore_1940 > 0
    AND c.INCWAGE IS NOT NULL
    AND c.INCWAGE > 0
    AND c.INCWAGE < 999998
")
dbDisconnect(con, shutdown = TRUE)

cat("Wage observations:", nrow(wage_df), "\n")

# Construct variables
wage_df <- as.data.table(wage_df)

# Unit banking classification
unit_banking_states <- c(8, 12, 17, 19, 20, 27, 29, 30, 31, 38, 40, 48, 54, 56)
wage_df[, unit_banking := as.integer(statefip_1920 %in% unit_banking_states)]

# Merge ag shares
county_ag <- readRDS("../data/county_ag_shares.rds")
county_ag_dt <- as.data.table(county_ag)
setnames(county_ag_dt, c("statefip", "countyicp"), c("statefip_1920", "countyicp_1920"))
wage_df <- merge(wage_df, county_ag_dt[, .(statefip_1920, countyicp_1920, ag_share)],
                  by = c("statefip_1920", "countyicp_1920"), all.x = TRUE)
wage_df <- wage_df[!is.na(ag_share)]

# Controls
wage_df[, age_sq := age_1920^2]
wage_df[, white := as.integer(race_1920 == 1)]
wage_df[, foreign_born := as.integer(nativity_1920 >= 4)]
wage_df[, married_1920 := as.integer(marst_1920 <= 2)]
wage_df[, farmer_1920 := as.integer(farm_1920 == 2)]
wage_df[, region := fcase(
  statefip_1920 %in% c(9, 23, 25, 33, 34, 36, 42, 44, 50), "Northeast",
  statefip_1920 %in% c(17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55), "Midwest",
  statefip_1920 %in% c(1, 5, 10, 11, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54), "South",
  statefip_1920 %in% c(4, 6, 8, 16, 30, 32, 35, 41, 49, 53, 56), "West",
  default = "Other"
)]

# Log wage
wage_df[, log_wage := log(incwage_1940)]

# Run wage regressions
cat("\n=== WAGE REGRESSIONS ===\n")

m_wage1 <- feols(log_wage ~ unit_banking * ag_share + age_1920 + age_sq +
                   white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                   region,
                 data = wage_df, vcov = ~statefip_1920)

cat("Log wage (UB):", round(coef(m_wage1)["unit_banking"], 4),
    "se:", round(se(m_wage1)["unit_banking"], 4), "\n")
cat("Log wage (UB × Ag):", round(coef(m_wage1)["unit_banking:ag_share"], 4),
    "se:", round(se(m_wage1)["unit_banking:ag_share"], 4), "\n")

etable(m_wage1, se.below = TRUE,
       keep = c("unit_banking", "ag_share", "unit_banking:ag_share"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# Save model
saveRDS(m_wage1, "../data/wage_model.rds")
cat("Wage model saved.\n")

# Summary
cat("\nN with wages:", nrow(wage_df), "\n")
cat("Mean wage:", round(mean(wage_df$incwage_1940), 0), "\n")
cat("SD log wage:", round(sd(wage_df$log_wage), 3), "\n")
