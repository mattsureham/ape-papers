# 01_fetch_data.R — Fetch QWI from Azure + Census trade data
# apep_1079: Section 301 tariffs and racial employment effects

source("00_packages.R")

# ============================================================
# Azure connection (direct DuckDB — avoids shell escaping issues)
# ============================================================
env_lines <- readLines("../../../../.env", warn = FALSE)
cs_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)[1]
cs_val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", cs_line)
cs_val <- gsub('^["\']|["\']$', '', cs_val)

con <- dbConnect(duckdb::duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET apep_az (TYPE azure, CONNECTION_STRING '%s');", cs_val))
cat("Azure connected.\n")

# ============================================================
# Part 1: QWI race × 3-digit NAICS from Azure
# ============================================================
cat("Querying QWI manufacturing data (race × 3-digit NAICS, 2015-2019)...\n")

qwi_mfg <- dbGetQuery(con, "
  SELECT geography, CAST(industry AS VARCHAR) AS industry, race, ethnicity, year, quarter,
         Emp, EmpEnd, EmpS, EarnS, HirA, Sep
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry BETWEEN 311 AND 339
    AND race IN ('A0', 'A1', 'A2', 'A4')
    AND ethnicity = 'A0'
    AND agegrp = 'A00'
    AND sex = 0
    AND year BETWEEN 2015 AND 2019
")
cat("Manufacturing rows:", nrow(qwi_mfg), "\n")
stopifnot("No manufacturing data returned" = nrow(qwi_mfg) > 0)

# Service sectors as placebo
cat("Querying QWI service sector placebo...\n")
qwi_svc <- dbGetQuery(con, "
  SELECT geography, CAST(industry AS VARCHAR) AS industry, race, ethnicity, year, quarter,
         Emp, EmpEnd, EmpS, EarnS, HirA, Sep
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE (industry BETWEEN 541 AND 549 OR industry BETWEEN 721 AND 722)
    AND race IN ('A0', 'A1', 'A2', 'A4')
    AND ethnicity = 'A0'
    AND agegrp = 'A00'
    AND sex = 0
    AND year BETWEEN 2015 AND 2019
")
cat("Service sector rows:", nrow(qwi_svc), "\n")

dbDisconnect(con, shutdown = TRUE)

# Combine
qwi_all <- bind_rows(
  qwi_mfg %>% mutate(sector = "manufacturing"),
  qwi_svc %>% mutate(sector = "services")
)

cat("QWI total:", nrow(qwi_all), "rows\n")
cat("  Unique counties:", n_distinct(qwi_all$geography), "\n")
cat("  Unique industries:", n_distinct(qwi_all$industry), "\n")
cat("  Race values:", paste(unique(qwi_all$race), collapse = ", "), "\n")

# ============================================================
# Part 2: Chinese import penetration by NAICS (Census API)
# ============================================================
cat("\nFetching Chinese import data from Census International Trade API...\n")

census_key <- ""
for (line in env_lines) {
  if (grepl("^CENSUS_API_KEY=", line)) {
    census_key <- sub("^CENSUS_API_KEY=", "", trimws(line))
    census_key <- gsub("[\"']", "", census_key)
  }
}

fetch_census_trade <- function(year, country_code, api_key) {
  base_url <- "https://api.census.gov/data/timeseries/intltrade/imports/naics"
  params <- list(
    get = "NAICS,GEN_VAL_YR,CON_VAL_YR",
    time = as.character(year),
    CTY_CODE = as.character(country_code),
    key = api_key
  )
  resp <- httr::GET(base_url, query = params, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    cat("Census API status:", httr::status_code(resp), "\n")
    return(NULL)
  }
  raw <- jsonlite::fromJSON(httr::content(resp, "text"))
  df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
  names(df) <- raw[1, ]
  df %>%
    mutate(GEN_VAL_YR = as.numeric(GEN_VAL_YR),
           CON_VAL_YR = as.numeric(CON_VAL_YR)) %>%
    filter(!is.na(GEN_VAL_YR))
}

# China = CTY_CODE 5700
china_imports <- fetch_census_trade(2017, "5700", census_key)

if (is.null(china_imports) || nrow(china_imports) == 0) {
  stop("Census trade API failed. Cannot proceed without import data.")
}

cat("Census trade API returned", nrow(china_imports), "NAICS rows for China\n")

# Map to 3-digit NAICS manufacturing
mfg_naics <- c("311","312","313","314","315","316",
               "321","322","323","324","325","326","327",
               "331","332","333","334","335","336","337","339")

china_by_naics <- china_imports %>%
  mutate(naics3 = substr(NAICS, 1, 3)) %>%
  filter(naics3 %in% mfg_naics) %>%
  group_by(naics3) %>%
  summarize(china_import_val = sum(GEN_VAL_YR, na.rm = TRUE), .groups = "drop")

cat("China imports by NAICS:", nrow(china_by_naics), "industries\n")

# Total imports from world = CTY_CODE 0000
total_imports <- fetch_census_trade(2017, "-", census_key)

if (!is.null(total_imports) && nrow(total_imports) > 0) {
  total_by_naics <- total_imports %>%
    mutate(naics3 = substr(NAICS, 1, 3)) %>%
    filter(naics3 %in% mfg_naics) %>%
    group_by(naics3) %>%
    summarize(total_import_val = sum(GEN_VAL_YR, na.rm = TRUE), .groups = "drop")

  trade_data <- china_by_naics %>%
    left_join(total_by_naics, by = "naics3") %>%
    mutate(cip = ifelse(total_import_val > 0, china_import_val / total_import_val, 0))
} else {
  cat("Warning: Total imports query failed. Using China value rank as proxy.\n")
  trade_data <- china_by_naics %>%
    mutate(total_import_val = NA_real_,
           cip = china_import_val / max(china_import_val))
}

cat("\nTrade data:\n")
print(trade_data %>% arrange(desc(cip)))

# ============================================================
# Part 3: Section 301 tariff rates (regulatory facts from USTR)
# ============================================================
section301 <- tribble(
  ~naics3, ~list1_rate, ~list3_rate, ~list4_rate, ~list1_date, ~list3_date,
  "333", 0.25, 0.25, 0.00, "2018-07-06", "2018-09-24",
  "334", 0.25, 0.25, 0.00, "2018-07-06", "2018-09-24",
  "335", 0.25, 0.25, 0.00, "2018-07-06", "2018-09-24",
  "331", 0.00, 0.25, 0.00, NA, "2018-09-24",
  "332", 0.00, 0.25, 0.00, NA, "2018-09-24",
  "325", 0.25, 0.25, 0.00, "2018-07-06", "2018-09-24",
  "326", 0.00, 0.25, 0.00, NA, "2018-09-24",
  "327", 0.00, 0.10, 0.00, NA, "2018-09-24",
  "336", 0.00, 0.10, 0.00, NA, "2018-09-24",
  "337", 0.00, 0.25, 0.00, NA, "2018-09-24",
  "321", 0.00, 0.10, 0.00, NA, "2018-09-24",
  "322", 0.00, 0.10, 0.00, NA, "2018-09-24",
  "323", 0.00, 0.10, 0.00, NA, "2018-09-24",
  "324", 0.00, 0.00, 0.00, NA, NA,
  "311", 0.00, 0.10, 0.00, NA, "2018-09-24",
  "312", 0.00, 0.00, 0.00, NA, NA,
  "313", 0.00, 0.10, 0.15, NA, "2018-09-24",
  "314", 0.00, 0.10, 0.15, NA, "2018-09-24",
  "315", 0.00, 0.00, 0.15, NA, NA,
  "316", 0.00, 0.00, 0.15, NA, NA,
  "339", 0.00, 0.25, 0.00, NA, "2018-09-24"
) %>%
  mutate(
    tariff_max = pmax(list1_rate, list3_rate, list4_rate, na.rm = TRUE),
    early_hit = !is.na(list1_date)
  )

# Merge trade + tariff
industry_treatment <- trade_data %>%
  left_join(section301, by = "naics3") %>%
  mutate(
    tariff_exposure = ifelse(!is.na(cip) & !is.na(tariff_max), cip * tariff_max, 0)
  )

cat("\nIndustry treatment:\n")
print(industry_treatment %>% select(naics3, cip, tariff_max, tariff_exposure, early_hit) %>%
  arrange(desc(tariff_exposure)))

# ============================================================
# Save
# ============================================================
saveRDS(qwi_all, "../data/qwi_panel.rds")
saveRDS(industry_treatment, "../data/industry_treatment.rds")

cat("\nData saved.\n")
cat("  qwi_panel.rds:", nrow(qwi_all), "rows\n")
cat("  industry_treatment.rds:", nrow(industry_treatment), "rows\n")
