# 01_fetch_data.R — Fetch QWI data from Azure
# apep_1077: Child Labor Law Rollbacks DDD

source("00_packages.R")

# --- Azure connection ---
env_file <- "../../../../.env"
stopifnot("Cannot find .env" = file.exists(env_file))
lines <- readLines(env_file, warn = FALSE)
conn_str <- NULL
for (l in lines) {
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", l)) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", l)
  }
}
stopifnot("AZURE_STORAGE_CONNECTION_STRING not found" = !is.null(conn_str))

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, "SET azure_transport_option_type = 'curl'")
dbExecute(con, sprintf("CREATE SECRET (TYPE AZURE, CONNECTION_STRING '%s')", conn_str))

cat("Connected to Azure.\n")

# --- Query QWI: teen & young adult employment in food/retail/professional ---
# Industries: 72 (Food Services), 44-45 (Retail), 54 (Professional — placebo)
# Age groups: A01 (14-18), A02 (19-21)
# Sex: 0 (Both)
# Owner: A05 (Private sector)
# Geo level: C (County)
# Years: 2018-2025 (pre/post rollbacks)

cat("Fetching QWI data from Azure... this may take a few minutes.\n")

qwi <- dbGetQuery(con, "
  SELECT geography AS fips,
         industry,
         agegrp,
         year,
         quarter,
         Emp AS emp,
         HirA AS hires,
         Sep AS separations,
         EarnS AS earnings
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE geo_level = 'C'
    AND ownercode = 'A05'
    AND sex = '0'
    AND agegrp IN ('A01', 'A02')
    AND industry IN ('72', '44-45', '54')
    AND year >= 2018
    AND periodicity = 'Q'
    AND seasonadj = 'U'
")

dbDisconnect(con)

cat(sprintf("Fetched %s rows from QWI.\n", format(nrow(qwi), big.mark = ",")))

# --- Validate data ---
stopifnot("No data returned from Azure" = nrow(qwi) > 0)
stopifnot("Missing required columns" = all(c("fips", "industry", "agegrp", "year", "quarter", "emp") %in% names(qwi)))

# Basic summary
cat("\n--- Data Summary ---\n")
cat(sprintf("Counties: %d\n", length(unique(qwi$fips))))
cat(sprintf("Industries: %s\n", paste(unique(qwi$industry), collapse = ", ")))
cat(sprintf("Age groups: %s\n", paste(unique(qwi$agegrp), collapse = ", ")))
cat(sprintf("Year range: %d-%d\n", min(qwi$year), max(qwi$year)))
cat(sprintf("Rows: %s\n", format(nrow(qwi), big.mark = ",")))

# --- Save ---
dt <- as.data.table(qwi)
fwrite(dt, "../data/qwi_raw.csv")
cat("Saved to data/qwi_raw.csv\n")
