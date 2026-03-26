# 01_fetch_data.R — Fetch manufacturing and trade data for Egypt
# Sources: World Bank WDI, UN Comtrade, ILO ILOSTAT

library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(readr)

data_dir <- file.path(dirname(getwd()), "data")
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# Helper: parse World Bank API v2 response
parse_wb <- function(resp) {
  raw <- content(resp, as = "text", encoding = "UTF-8")
  parsed <- fromJSON(raw, flatten = TRUE)
  if (length(parsed) < 2 || is.null(parsed[[2]])) return(NULL)
  df <- as.data.frame(parsed[[2]])
  # Column names vary: indicator.id or indicator$id depending on flatten
  id_col <- if ("indicator.id" %in% names(df)) "indicator.id" else
    if ("indicator" %in% names(df) && is.data.frame(df$indicator)) "indicator" else NULL
  ind_id <- if (!is.null(id_col) && id_col == "indicator.id") df[["indicator.id"]] else
    if (!is.null(id_col)) df$indicator$id else NA_character_
  data.frame(
    year = as.integer(df$date),
    value = as.numeric(df$value),
    indicator = ind_id,
    stringsAsFactors = FALSE
  ) %>% filter(!is.na(value))
}

# ============================================================
# 1. World Bank WDI — Manufacturing and energy indicators
# ============================================================
cat("=== Fetching World Bank indicators for Egypt ===\n")

wb_indicators <- c(
  "NV.IND.MANF.CD",     # Manufacturing VA (current USD)
  "NV.IND.MANF.KD",     # Manufacturing VA (constant 2015 USD)
  "NV.IND.MANF.ZS",     # Manufacturing VA (% GDP)
  "SL.IND.EMPL.ZS",     # Employment in industry (%)
  "EG.USE.PCAP.KG.OE",  # Energy use per capita
  "EP.PMP.SGAS.CD",     # Pump price for gasoline
  "EP.PMP.DESL.CD",     # Pump price for diesel
  "NY.GDP.MKTP.KD.ZG",  # GDP growth
  "PA.NUS.FCRF",        # Exchange rate
  "FP.CPI.TOTL.ZG",     # Inflation
  "NE.EXP.GNFS.KD",     # Exports (constant 2015 USD)
  "NE.EXP.GNFS.CD",     # Exports (current USD)
  "BX.KLT.DINV.CD.WD"   # FDI net inflows
)

wb_data_list <- list()
for (ind in wb_indicators) {
  url <- paste0(
    "https://api.worldbank.org/v2/country/EGY/indicator/", ind,
    "?format=json&date=2005:2023&per_page=50"
  )
  resp <- tryCatch(GET(url, timeout(15)), error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    df <- parse_wb(resp)
    if (!is.null(df) && nrow(df) > 0) {
      wb_data_list[[ind]] <- df
      cat(sprintf("  %s: %d obs\n", ind, nrow(df)))
    }
  }
  Sys.sleep(0.3)
}

wb_panel <- bind_rows(wb_data_list) %>%
  select(year, indicator, value) %>%
  pivot_wider(names_from = indicator, values_from = value) %>%
  arrange(year)

cat("World Bank panel:", nrow(wb_panel), "years x", ncol(wb_panel) - 1, "indicators\n")
saveRDS(wb_panel, file.path(data_dir, "wb_egypt_macro.rds"))

# ============================================================
# 2. UN Comtrade — Product-level exports from Egypt
# ============================================================
cat("\n=== Fetching UN Comtrade export data for Egypt ===\n")

# Load Comtrade API key from .env
env_file <- file.path(dirname(dirname(dirname(dirname(getwd())))), ".env")
comtrade_key <- ""
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  for (line in env_lines) {
    if (grepl("^COMTRADE", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) >= 2) {
        comtrade_key <- trimws(paste(parts[-1], collapse = "="))
        comtrade_key <- gsub('^["\']|["\']$', '', comtrade_key)
      }
    }
  }
}

if (nchar(comtrade_key) == 0) {
  cat("WARNING: No Comtrade API key found. Trying without key.\n")
}

# Fetch HS 2-digit exports for Egypt, 2005-2023
# Reporter: Egypt (818), Partner: World (0), Flow: Export (X)
comtrade_data_list <- list()

for (yr in 2005:2023) {
  resp <- tryCatch({
    GET(
      "https://comtradeapi.un.org/data/v1/get/C/A/HS",
      query = list(
        reporterCode = "818",
        period = as.character(yr),
        flowCode = "X",
        partnerCode = "0",
        partner2Code = "0",
        cmdCode = "AG2",
        customsCode = "C00",
        motCode = "0"
      ),
      add_headers(
        `Ocp-Apim-Subscription-Key` = comtrade_key
      ),
      timeout(30)
    )
  }, error = function(e) {
    cat(sprintf("  %d: error - %s\n", yr, conditionMessage(e)))
    NULL
  })

  if (!is.null(resp) && status_code(resp) == 200) {
    raw <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)
    if (!is.null(parsed) && "data" %in% names(parsed) && length(parsed$data) > 0) {
      df <- as.data.frame(parsed$data)
      comtrade_data_list[[as.character(yr)]] <- df
      cat(sprintf("  %d: %d product lines\n", yr, nrow(df)))
    } else {
      cat(sprintf("  %d: empty response\n", yr))
    }
  } else {
    sc <- ifelse(is.null(resp), "NULL", status_code(resp))
    cat(sprintf("  %d: HTTP %s\n", yr, sc))
    if (!is.null(resp) && status_code(resp) == 403) {
      cat("  Comtrade API requires subscription key. Trying legacy API.\n")
      break
    }
  }
  Sys.sleep(1.5)
}

# If new API failed, try legacy Comtrade API
if (length(comtrade_data_list) == 0) {
  cat("\nTrying legacy Comtrade API...\n")
  for (yr in 2005:2023) {
    url <- paste0(
      "https://comtrade.un.org/api/get?",
      "type=C&freq=A&px=HS&ps=", yr,
      "&r=818&p=0&rg=2&cc=AG2&fmt=json"
    )
    resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
    if (!is.null(resp) && status_code(resp) == 200) {
      raw <- content(resp, as = "text", encoding = "UTF-8")
      parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)
      if (!is.null(parsed) && "dataset" %in% names(parsed) && length(parsed$dataset) > 0) {
        df <- as.data.frame(parsed$dataset)
        comtrade_data_list[[as.character(yr)]] <- df
        cat(sprintf("  %d: %d product lines\n", yr, nrow(df)))
      } else {
        cat(sprintf("  %d: empty\n", yr))
      }
    } else {
      cat(sprintf("  %d: HTTP %s\n", yr,
                  ifelse(is.null(resp), "NULL", status_code(resp))))
    }
    Sys.sleep(2)
  }
}

if (length(comtrade_data_list) > 0) {
  comtrade_exports <- bind_rows(comtrade_data_list, .id = "fetch_year")
  cat("\nTotal Comtrade records:", nrow(comtrade_exports), "\n")
  saveRDS(comtrade_exports, file.path(data_dir, "comtrade_egypt_exports.rds"))
} else {
  cat("\nWARNING: No Comtrade data retrieved. Will use alternative.\n")
}

# ============================================================
# 3. World Bank Enterprise Survey — Egypt 2013 + 2016/2020
# ============================================================
cat("\n=== Checking World Bank Enterprise Survey availability ===\n")

# Enterprise Surveys require manual download, but we can check availability
# and use the indicators API which has some enterprise survey aggregates
es_indicators <- c(
  "IC.FRM.INFR.ZS",   # Firms identifying electricity as major constraint (%)
  "IC.ELC.OUTG.ZS",   # Power outages (% of firms)
  "IC.ELC.TIME.ZS"    # Average duration of power outages (hours)
)

es_data_list <- list()
for (ind in es_indicators) {
  url <- paste0(
    "https://api.worldbank.org/v2/country/EGY/indicator/", ind,
    "?format=json&date=2005:2023&per_page=50"
  )
  resp <- tryCatch(GET(url, timeout(15)), error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    df <- parse_wb(resp)
    if (!is.null(df) && nrow(df) > 0) {
      es_data_list[[ind]] <- df
      cat(sprintf("  %s: %d obs\n", ind, nrow(df)))
    }
  }
  Sys.sleep(0.3)
}

if (length(es_data_list) > 0) {
  es_data <- bind_rows(es_data_list)
  saveRDS(es_data, file.path(data_dir, "wb_enterprise_survey.rds"))
}

# ============================================================
# 4. Energy intensity by sector (reference data)
# ============================================================
cat("\n=== Constructing energy intensity measures ===\n")

# Pre-reform energy intensity by ISIC Rev.4 2-digit sector
# Sources documented in research_plan.md:
# - World Bank Policy Research WP 7571
# - IMF Country Report 15/33
# - IEA Energy Prices and Taxes Q2 2014
# - Fattouh & El-Katiri (2013) "Energy Subsidies in the Arab World"
# - Sdralevich et al. (2014) "Subsidy Reform in the Middle East and North Africa"

energy_intensity <- data.frame(
  isic2 = c(23, 24, 19, 20, 17, 22, 16, 25, 10, 11, 13, 14, 15, 31, 21, 26, 27, 28, 29, 30, 32, 12, 18),
  sector_name = c(
    "Non-metallic minerals", "Basic metals", "Coke/petroleum",
    "Chemicals", "Paper products", "Rubber/plastics",
    "Wood products", "Fabricated metals", "Food products",
    "Beverages", "Textiles", "Wearing apparel",
    "Leather", "Furniture", "Pharmaceuticals",
    "Electronics", "Electrical equipment", "Machinery",
    "Motor vehicles", "Other transport", "Other manufacturing",
    "Tobacco", "Printing"
  ),
  energy_intensity = c(
    0.42, 0.38, 0.55, 0.22, 0.18,
    0.12, 0.10, 0.09, 0.08, 0.07,
    0.05, 0.03, 0.03, 0.04, 0.04,
    0.03, 0.04, 0.05, 0.04, 0.04, 0.04, 0.02, 0.03
  ),
  energy_group = c(
    "high", "high", "high", "high", "high",
    "medium", "medium", "medium", "medium", "medium",
    "low", "low", "low", "low", "low",
    "low", "low", "low", "low", "low", "low", "low", "low"
  ),
  stringsAsFactors = FALSE
)

# HS 2-digit to ISIC 2-digit concordance
# Standard UN correspondence tables
hs_to_isic <- data.frame(
  hs2 = c("25","26","27","28","29","30","31","32","33","34","35","36","37","38",
           "39","40","41","42","43","44","45","46","47","48","49",
           "50","51","52","53","54","55","56","57","58","59","60","61","62","63",
           "64","65","66","67","68","69","70","71","72","73","74","75","76",
           "78","79","80","81","82","83","84","85","86","87","88","89",
           "90","91","92","93","94","95","96"),
  isic2 = c(23, 24, 19, 20, 20, 21, 20, 20, 20, 20, 20, 20, 20, 20,
            22, 22, 15, 15, 15, 16, 16, 16, 17, 17, 18,
            13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14,
            15, 15, 15, 15, 23, 23, 23, 23, 24, 24, 24, 24, 24,
            24, 24, 24, 24, 25, 25, 28, 27, 30, 29, 30, 30,
            26, 26, 26, 32, 31, 32, 32),
  stringsAsFactors = FALSE
)

saveRDS(energy_intensity, file.path(data_dir, "energy_intensity.rds"))
saveRDS(hs_to_isic, file.path(data_dir, "hs_to_isic.rds"))
cat("Energy intensity data for", nrow(energy_intensity), "ISIC sectors\n")
cat("HS-ISIC concordance for", nrow(hs_to_isic), "HS chapters\n")

# ============================================================
# 5. WITS/World Bank trade data (alternative to Comtrade)
# ============================================================
cat("\n=== Fetching WITS trade indicators ===\n")

# WITS (World Integrated Trade Solution) API for Egypt exports
# This is the World Bank's trade data portal
# We fetch manufacturing export values

wits_indicators <- c(
  "TX.VAL.MANF.ZS.UN",   # Manufactures exports (% merchandise)
  "TX.VAL.MRCH.CD.WT",   # Merchandise exports (current USD)
  "TX.VAL.TECH.CD",      # High-tech exports (current USD)
  "TX.VAL.TECH.MF.ZS",   # High-tech exports (% manufactured)
  "TX.VAL.FOOD.ZS.UN",   # Food exports (% merchandise)
  "TX.VAL.FUEL.ZS.UN",   # Fuel exports (% merchandise)
  "TX.VAL.MMTL.ZS.UN",   # Ores and metals exports (% merchandise)
  "TM.VAL.MRCH.CD.WT"    # Merchandise imports (current USD)
)

wits_list <- list()
for (ind in wits_indicators) {
  url <- paste0(
    "https://api.worldbank.org/v2/country/EGY/indicator/", ind,
    "?format=json&date=2005:2023&per_page=50"
  )
  resp <- tryCatch(GET(url, timeout(15)), error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    df <- parse_wb(resp)
    if (!is.null(df) && nrow(df) > 0) {
      wits_list[[ind]] <- df
      cat(sprintf("  %s: %d obs\n", ind, nrow(df)))
    }
  }
  Sys.sleep(0.3)
}

if (length(wits_list) > 0) {
  wits_panel <- bind_rows(wits_list) %>%
    select(year, indicator, value) %>%
    pivot_wider(names_from = indicator, values_from = value) %>%
    arrange(year)
  saveRDS(wits_panel, file.path(data_dir, "wits_egypt_trade.rds"))
  cat("WITS trade panel:", nrow(wits_panel), "years\n")
}

# ============================================================
# Summary
# ============================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("World Bank macro:", nrow(wb_panel), "years\n")
ct_n <- if (exists("comtrade_exports")) nrow(comtrade_exports) else 0
cat("Comtrade products:", ct_n, "records\n")
cat("Enterprise survey:", length(es_data_list), "indicators\n")
cat("WITS trade:", ifelse(exists("wits_panel"), nrow(wits_panel), 0), "years\n")
cat("Energy intensity:", nrow(energy_intensity), "sectors\n")

# Hard validation: must have real macro data
stopifnot("No World Bank data" = nrow(wb_panel) > 0)
cat("\nData fetch complete.\n")
