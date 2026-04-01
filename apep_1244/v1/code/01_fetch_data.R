# =============================================================================
# 01_fetch_data.R — Fetch MLP linked panels from Azure
# apep_1244: The Upgrading Dividend
# =============================================================================

source("00_packages.R")

# Manual Azure connection (bypass .env semicolon truncation)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
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

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
stopifnot(nchar(conn_str) > 50)
DBI::dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure.\n")

# ---- Workers' Compensation adoption dates (Fishback & Kantor 2000) ----------
# Sources: Fishback & Kantor (2000), Table 1; Berkowitz & Berkowitz (1985)
wc_dates <- data.table(
  statefip = c(
    # 1911 (10): WI, CA, IL, KS, MA, NE, NV, NH, NJ, WA
    55L, 6L, 17L, 20L, 25L, 31L, 32L, 33L, 34L, 53L,
    # 1912 (3): AZ, MI, MD
    4L, 26L, 24L,
    # 1913 (8): CT, IA, IN, MN, NY, OH, OR, TX
    9L, 19L, 18L, 27L, 36L, 39L, 41L, 48L,
    # 1914 (3): CO, LA, ME
    8L, 22L, 23L,
    # 1915 (8): HI, ID, MT, OK, PA, RI, VT, WY
    15L, 16L, 30L, 40L, 42L, 44L, 50L, 56L,
    # 1917 (7): AL, DE, GA, KY, MO, SD, UT
    1L, 10L, 13L, 21L, 29L, 46L, 49L,
    # 1918 (2): ND, NM
    38L, 35L,
    # 1919 (2): TN, VA
    47L, 51L,
    # Never-treated by 1920 (5): AR, FL, MS, NC, SC
    5L, 12L, 28L, 37L, 45L
  ),
  wc_year = c(
    rep(1911L, 10), rep(1912L, 3), rep(1913L, 8), rep(1914L, 3),
    rep(1915L, 8), rep(1917L, 7), rep(1918L, 2), rep(1919L, 2),
    rep(0L, 5)  # 0 = never treated
  )
)

wc_dates <- unique(wc_dates, by = "statefip")
stopifnot(nrow(wc_dates[wc_year == 0]) == 5)
cat("WC adoption dates loaded:", nrow(wc_dates), "states\n")
cat("Never-treated:", paste(wc_dates[wc_year == 0, statefip], collapse = ", "), "\n")

# ---- Fetch MLP 1910-1920 panel (treatment period) --------------------------
cat("Fetching MLP 1910-1920 panel from Azure...\n")

panel_1920 <- DBI::dbGetQuery(con, "
  SELECT
    histid_1910 as histid,
    statefip_1910,
    statefip_1920,
    age_1910,
    race_1910,
    nativity_1910,
    occ1950_1910,
    occ1950_1920,
    ind1950_1910,
    ind1950_1920,
    occscore_1910,
    occscore_1920,
    classwkr_1910,
    classwkr_1920,
    lit_1910,
    farm_1910,
    farm_1920,
    mover
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE sex_1910 = 1
    AND age_1910 BETWEEN 18 AND 50
    AND classwkr_1910 = 2
")

panel_1920 <- as.data.table(panel_1920)
cat("1910-1920 panel:", format(nrow(panel_1920), big.mark = ","), "wage-employed men aged 18-50\n")
stopifnot(nrow(panel_1920) > 100000)

# ---- Fetch MLP 1900-1910 panel (pre-period / placebo) ----------------------
cat("Fetching MLP 1900-1910 panel from Azure...\n")

# Note: 1900-1910 panel lacks classwkr, so we filter on sex and age only
panel_1910 <- DBI::dbGetQuery(con, "
  SELECT
    histid_1900 as histid,
    statefip_1900,
    statefip_1910,
    age_1900,
    race_1900,
    nativity_1900,
    occ1950_1900,
    occ1950_1910,
    ind1950_1900,
    ind1950_1910,
    occscore_1900,
    occscore_1910,
    lit_1900,
    farm_1900,
    farm_1910,
    mover
  FROM 'az://derived/mlp_panel/linked_1900_1910.parquet'
  WHERE sex_1900 = 1
    AND age_1900 BETWEEN 18 AND 50
")

panel_1910 <- as.data.table(panel_1910)
cat("1900-1910 panel:", format(nrow(panel_1910), big.mark = ","), "men aged 18-50\n")
stopifnot(nrow(panel_1910) > 100000)

# ---- Save locally -----------------------------------------------------------
saveRDS(panel_1920, "../data/panel_1910_1920.rds")
saveRDS(panel_1910, "../data/panel_1900_1910.rds")
saveRDS(wc_dates, "../data/wc_dates.rds")

DBI::dbDisconnect(con, shutdown = TRUE)

cat("\nData fetch complete.\n")
cat("Treatment panel (1910-1920):", format(nrow(panel_1920), big.mark = ","), "observations\n")
cat("Pre-period panel (1900-1910):", format(nrow(panel_1910), big.mark = ","), "observations\n")
