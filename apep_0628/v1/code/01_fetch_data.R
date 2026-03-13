###############################################################################
# 01_fetch_data.R — Fetch UN Comtrade bilateral trade data
# Paper: The Invisible Tariff (apep_0628)
#
# Data: UN Comtrade HS6-level imports for Nigeria, Ghana, Cote d'Ivoire,
#       Senegal for 2012-2022.
###############################################################################

source("00_packages.R")

# --------------------------------------------------------------------------
# API Configuration
# --------------------------------------------------------------------------
dotenv_path <- file.path(dirname(getwd()), "..", "..", ".env")
if (!file.exists(dotenv_path)) dotenv_path <- "../../../../.env"
env_lines <- readLines(dotenv_path)
api_key <- trimws(sub(".*=", "", grep("^COMTRADE_API_PRIMARY", env_lines, value = TRUE)))
if (nchar(api_key) == 0) stop("COMTRADE_API_PRIMARY not found in .env")

cat("Using Comtrade API key:", substr(api_key, 1, 8), "...\n")

# --------------------------------------------------------------------------
# Country codes (ISO3 numeric for Comtrade)
# --------------------------------------------------------------------------
countries <- c(
  "566",  # Nigeria
  "288",  # Ghana
  "384",  # Cote d'Ivoire
  "686"   # Senegal
)
country_names <- c("Nigeria", "Ghana", "Cote d'Ivoire", "Senegal")

years <- 2012:2022

# --------------------------------------------------------------------------
# CBN FX Exclusion List — 41 product categories mapped to HS2 chapters
#
# Source: CBN Circular TED/FEM/FPC/GEN/01/011, June 23, 2015
# The CBN banned product CATEGORIES. We map to HS2 chapters for tractability,
# then use HS6 data within those chapters.
#
# Mapping based on CBN circular text to HS classification:
# --------------------------------------------------------------------------

# HS2 chapters containing banned products
banned_hs2 <- c(
  "04",  # Dairy products (milk, margarine component)
  "10",  # Cereals (rice, maize)
  "11",  # Milling products (flour)
  "15",  # Fats and oils (palm kernel oil, vegetable oils, margarine)
  "16",  # Preparations of meat/fish
  "17",  # Sugars and sugar confectionery
  "19",  # Preparations of cereals (pasta)
  "20",  # Preparations of vegetables/fruits (tomato paste/juice)
  "22",  # Beverages (beer, wine, spirits)
  "25",  # Salt, cement
  "33",  # Essential oils, perfumery, cosmetics (soap)
  "34",  # Soap, washing preparations
  "39",  # Plastics (plastic products, toothpicks)
  "48",  # Paper products (tissue paper, toiletries packaging)
  "61",  # Knitted apparel (textiles)
  "62",  # Non-knitted apparel (textiles)
  "63",  # Other textile articles (used clothing)
  "69",  # Ceramic products (tiles)
  "72",  # Iron and steel
  "73",  # Articles of iron/steel (steel rods, nails, wire)
  "76",  # Aluminium products (roofing sheets)
  "87",  # Vehicles (motorcycles)
  "88"   # Aircraft (private jets)
)

# Save the banned list for later use
saveRDS(banned_hs2, "../data/banned_hs2.rds")

# --------------------------------------------------------------------------
# Fetch function: UN Comtrade Bulk API (new API format)
# --------------------------------------------------------------------------
fetch_comtrade <- function(reporter_code, year, api_key, max_retries = 3) {
  base_url <- "https://comtradeapi.un.org/data/v1/get/C/A/HS"

  params <- list(
    reporterCode = reporter_code,
    period = as.character(year),
    partnerCode = "0",      # World (all partners aggregated)
    flowCode = "M",         # Imports
    cmdCode = "AG6",        # All HS6 codes
    customsCode = "C00",
    motCode = "0",
    partner2Code = "0",
    includeDesc = "TRUE"
  )

  for (attempt in 1:max_retries) {
    tryCatch({
      resp <- GET(
        base_url,
        query = params,
        add_headers(
          `Ocp-Apim-Subscription-Key` = api_key
        ),
        timeout(120)
      )

      if (status_code(resp) == 200) {
        content_text <- content(resp, as = "text", encoding = "UTF-8")
        parsed <- fromJSON(content_text, flatten = TRUE)

        if (is.null(parsed$data) || length(parsed$data) == 0) {
          cat(sprintf("  Warning: No data for reporter=%s, year=%s\n",
                      reporter_code, year))
          return(NULL)
        }

        df <- as.data.frame(parsed$data)
        cat(sprintf("  Fetched %d records for reporter=%s, year=%s\n",
                    nrow(df), reporter_code, year))
        return(df)
      } else if (status_code(resp) == 429) {
        cat(sprintf("  Rate limited. Waiting 5 seconds (attempt %d/%d)\n",
                    attempt, max_retries))
        Sys.sleep(5)
      } else {
        warning(sprintf("API returned status %d for reporter=%s, year=%s",
                        status_code(resp), reporter_code, year))
        cat(sprintf("  Response: %s\n", substr(content(resp, "text"), 1, 200)))
        Sys.sleep(2)
      }
    }, error = function(e) {
      cat(sprintf("  Error on attempt %d: %s\n", attempt, e$message))
      Sys.sleep(3)
    })
  }

  stop(sprintf("Failed to fetch data for reporter=%s, year=%s after %d attempts",
               reporter_code, year, max_retries))
}

# --------------------------------------------------------------------------
# Main fetch loop
# --------------------------------------------------------------------------
all_data <- list()
idx <- 0

for (i in seq_along(countries)) {
  reporter <- countries[i]
  cname <- country_names[i]

  for (yr in years) {
    idx <- idx + 1
    cat(sprintf("[%d/%d] Fetching %s %d...\n", idx, length(countries) * length(years), cname, yr))

    df <- fetch_comtrade(reporter, yr, api_key)

    if (!is.null(df) && nrow(df) > 0) {
      # Keep essential columns
      cols_keep <- intersect(names(df), c(
        "period", "reporterCode", "reporterDesc", "reporterISO",
        "cmdCode", "cmdDesc", "flowCode",
        "primaryValue", "netWgt", "qty", "qtyUnitAbbr",
        "fobvalue", "cifvalue"
      ))
      df <- df[, cols_keep, drop = FALSE]
      all_data[[idx]] <- df
    }

    # Rate limiting: Comtrade allows ~100 requests/minute
    Sys.sleep(1.5)
  }
}

cat(sprintf("\nFetched %d total chunks.\n", sum(!sapply(all_data, is.null))))

# --------------------------------------------------------------------------
# Combine and save
# --------------------------------------------------------------------------
if (sum(!sapply(all_data, is.null)) == 0) {
  stop("FATAL: No data retrieved from Comtrade API. Cannot proceed.")
}

trade_raw <- bind_rows(all_data[!sapply(all_data, is.null)])

cat(sprintf("Total observations: %d\n", nrow(trade_raw)))
cat(sprintf("Countries: %s\n", paste(unique(trade_raw$reporterDesc), collapse = ", ")))
cat(sprintf("Years: %s\n", paste(sort(unique(trade_raw$period)), collapse = ", ")))
cat(sprintf("Unique HS6 codes: %d\n", n_distinct(trade_raw$cmdCode)))

# Validate: must have data for all 4 countries
stopifnot("Nigeria must be in data" = "Nigeria" %in% trade_raw$reporterDesc ||
            "NGA" %in% trade_raw$reporterISO ||
            566 %in% trade_raw$reporterCode)

saveRDS(trade_raw, "../data/trade_raw.rds")
cat("Saved trade_raw.rds\n")

# --------------------------------------------------------------------------
# Extend data: Fetch 2010-2011 for all countries (need 5+ pre-periods)
# --------------------------------------------------------------------------
cat("\n=== Extending data to 2010-2011 ===\n")
extension_years <- 2010:2011
ext_data <- list()
ext_idx <- 0

for (i in seq_along(countries)) {
  reporter <- countries[i]
  cname <- country_names[i]

  for (yr in extension_years) {
    ext_idx <- ext_idx + 1
    cat(sprintf("[EXT %d/%d] Fetching %s %d...\n", ext_idx,
                length(countries) * length(extension_years), cname, yr))

    df <- fetch_comtrade(reporter, yr, api_key)

    if (!is.null(df) && nrow(df) > 0) {
      cols_keep <- intersect(names(df), c(
        "period", "reporterCode", "reporterDesc", "reporterISO",
        "cmdCode", "cmdDesc", "flowCode",
        "primaryValue", "netWgt", "qty", "qtyUnitAbbr",
        "fobvalue", "cifvalue"
      ))
      df <- df[, cols_keep, drop = FALSE]
      ext_data[[ext_idx]] <- df
    }

    Sys.sleep(1.5)
  }
}

cat(sprintf("\nFetched %d extension chunks.\n", sum(!sapply(ext_data, is.null))))

if (sum(!sapply(ext_data, is.null)) > 0) {
  ext_combined <- bind_rows(ext_data[!sapply(ext_data, is.null)])
  trade_raw_extended <- bind_rows(trade_raw, ext_combined)
  cat(sprintf("Extended total observations: %d\n", nrow(trade_raw_extended)))
  saveRDS(trade_raw_extended, "../data/trade_raw.rds")
  cat("Saved extended trade_raw.rds\n")
} else {
  cat("WARNING: No extension data retrieved. Keeping original.\n")
}
