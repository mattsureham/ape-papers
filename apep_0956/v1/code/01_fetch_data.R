# 01_fetch_data.R — Fetch CPI data from Statistics Denmark and Eurostat
# APEP Paper apep_0956: Rockets and Feathers in Food Taxation

source("00_packages.R")

# =============================================================================
# 1. Statistics Denmark PRIS6: Monthly CPI by product group
# =============================================================================
cat("Fetching Statistics Denmark PRIS6 data...\n")

# First, discover available product categories
meta_url <- "https://api.statbank.dk/v1/tableinfo/PRIS6"
meta_resp <- GET(meta_url)
stopifnot("Statistics Denmark metadata API failed" = status_code(meta_resp) == 200)
meta <- fromJSON(content(meta_resp, as = "text", encoding = "UTF-8"))

# Extract VAREGR (product group) variable info
varegr_df <- meta$variables
varegr_row <- varegr_df[varegr_df$id == "VAREGR", ]
# values is a data frame nested inside
vals <- varegr_row$values[[1]]
all_codes <- vals$id
all_labels <- vals$text
cat("Available product groups:", length(all_codes), "\n")

# Define our target categories (COICOP 4-5 digit food categories)
# Treated (high saturated fat): butter/oils, meat, cheese
# Control (low/no saturated fat): fish, bread/cereals, fruit, vegetables
target_codes <- c(
  # Treated products
  "011500",  # Butter, oils, margarine
  "011440",  # Cheese
  "011430",  # Other dairy (cream, yogurt)
  "011410",  # Milk
  "011200",  # Meat (aggregate)
  # Control products
  "011100",  # Bread and cereals
  "011300",  # Fish
  "011450",  # Eggs
  "011600",  # Fruit
  "011700",  # Vegetables
  "011710",  # Fresh vegetables
  "011720",  # Potatoes
  "011735",  # Frozen vegetables
  "011800",  # Sugar/sweets
  "011900",  # Other food
  "012100",  # Coffee/tea/cocoa
  "012200"   # Soda/juice
)

# Filter to codes that exist in the table
available_targets <- intersect(target_codes, all_codes)
cat("Target codes found:", paste(available_targets, collapse = ", "), "\n")

# Also check for finer subcategories of treated products
fine_codes <- all_codes[grepl("^0115|^01144|^0112[0-9]", all_codes)]
cat("Fine subcategories available:", paste(fine_codes, collapse = ", "), "\n")

# Include fine codes if available
fetch_codes <- unique(c(available_targets, fine_codes))

# Fetch data via POST API (handles large requests better)
data_url <- "https://api.statbank.dk/v1/data"
body <- list(
  table = "PRIS6",
  format = "CSV",
  delimiter = "Semicolon",
  variables = list(
    list(code = "VAREGR", values = as.list(fetch_codes)),
    list(code = "ENHED", values = list("100")),  # Indeks (Index)
    list(code = "Tid", values = list("*"))  # All time periods
  )
)

cat("POST body:\n", toJSON(body, auto_unbox = TRUE, pretty = TRUE), "\n")
resp <- POST(data_url,
             body = toJSON(body, auto_unbox = TRUE),
             content_type_json(),
             timeout(120))
cat("Response status:", status_code(resp), "\n")
if (status_code(resp) != 200) {
  cat("Response body:\n", content(resp, as = "text", encoding = "UTF-8"), "\n")
}
stopifnot("Statistics Denmark data API failed" = status_code(resp) == 200)

raw_text <- content(resp, as = "text", encoding = "UTF-8")
dk_cpi <- read.csv2(text = raw_text, stringsAsFactors = FALSE)

cat("Raw Denmark CPI data:", nrow(dk_cpi), "rows\n")
cat("Columns:", paste(names(dk_cpi), collapse = ", "), "\n")

# Clean column names and parse
names(dk_cpi) <- tolower(names(dk_cpi))
# The CSV uses semicolons; numeric values may use comma as decimal
# Rename to standard names
if ("indhold" %in% names(dk_cpi)) {
  dk_cpi <- dk_cpi %>%
    rename(product_code = varegr, time = tid, cpi = indhold) %>%
    select(product_code, time, cpi)
} else {
  # Alternative column naming
  dk_cpi <- dk_cpi %>%
    rename_with(~ c("product_code", "unit", "time", "cpi")[seq_along(.)]) %>%
    select(product_code, time, cpi)
}

# Trim whitespace from all character columns
dk_cpi <- dk_cpi %>% mutate(across(where(is.character), trimws))

# Parse CPI values (may use comma as decimal separator)
dk_cpi$cpi <- as.numeric(gsub(",", ".", dk_cpi$cpi))

# The product_code column contains text like "01.1.5 Smør, spiseolie og margarine"
# Extract the COICOP code prefix and convert to 6-digit numeric code
dk_cpi <- dk_cpi %>%
  mutate(
    product_label = product_code,  # Save full text as label
    coicop_prefix = str_extract(product_code, "^[0-9]+(\\.[0-9]+)+"),
    # Convert "01.1.5" -> "011500", "01.1.4.4" -> "011440"
    product_code = sapply(coicop_prefix, function(x) {
      parts <- unlist(strsplit(x, "\\."))
      # Pad to 6 digits: first 2 + groups of 1
      code <- paste0(parts, collapse = "")
      # Pad with zeros to 6 chars
      formatC(as.integer(paste0(code, strrep("0", max(0, 6 - nchar(code))))),
              width = 6, flag = "0")
    })
  )

cat("Product code mapping:\n")
print(dk_cpi %>% distinct(product_code, product_label) %>% arrange(product_code))

# Parse time: format is "2011M09"
dk_cpi <- dk_cpi %>%
  mutate(
    year = as.integer(substr(time, 1, 4)),
    month = as.integer(gsub("M", "", substr(time, 5, 7))),
    date = as.Date(paste(year, month, "01", sep = "-"))
  ) %>%
  filter(!is.na(cpi))

cat("Parsed Denmark CPI:", nrow(dk_cpi), "rows,",
    n_distinct(dk_cpi$product_code), "product groups\n")
cat("  Date range:", as.character(min(dk_cpi$date)), "to", as.character(max(dk_cpi$date)), "\n")

# Validate: check the key Oct 2011 and Jan 2013 transitions
validation <- dk_cpi %>%
  filter(product_code %in% c("011500", "011200", "011440", "011300"),
         time %in% c("2011M09", "2011M10", "2012M12", "2013M01")) %>%
  arrange(product_code, time)
cat("\nValidation — key transitions:\n")
print(validation %>% select(product_code, product_label, time, cpi))

# =============================================================================
# 2. Eurostat HICP: Monthly harmonized CPI for Denmark and Sweden
# =============================================================================
cat("\nFetching Eurostat HICP data...\n")

# HICP monthly index (2015=100)
hicp <- get_eurostat("prc_hicp_midx",
                     filters = list(
                       geo = c("DK", "SE"),
                       unit = "I15",  # Index 2015=100
                       coicop = c("CP0111", "CP0112", "CP0113", "CP0114",
                                  "CP0115", "CP0116", "CP0117")
                     ),
                     time_format = "date")

stopifnot("Eurostat HICP fetch returned no data" = nrow(hicp) > 0)

hicp_clean <- hicp %>%
  rename(country = geo, coicop = coicop, hicp = values, date = time) %>%
  mutate(
    year = year(date),
    month = month(date),
    country = as.character(country),
    coicop = as.character(coicop)
  ) %>%
  select(country, coicop, date, year, month, hicp) %>%
  filter(!is.na(hicp))

cat("Eurostat HICP:", nrow(hicp_clean), "rows,",
    n_distinct(hicp_clean$country), "countries,",
    n_distinct(hicp_clean$coicop), "COICOP categories\n")

# =============================================================================
# 3. Save
# =============================================================================
saveRDS(dk_cpi, "../data/dk_cpi_pris6.rds")
saveRDS(hicp_clean, "../data/eurostat_hicp.rds")

cat("\nData saved successfully.\n")
cat("  dk_cpi_pris6.rds:", nrow(dk_cpi), "rows\n")
cat("  eurostat_hicp.rds:", nrow(hicp_clean), "rows\n")
