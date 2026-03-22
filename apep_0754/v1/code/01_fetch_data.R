## 01_fetch_data.R — Load SNAP Retailer Historical Database + construct treatment panel
## APEP Working Paper apep_0754

source("00_packages.R")

## ---- 1. SNAP Retailer Historical Database ----
cat("Loading SNAP Retailer Historical Database...\n")
retailers <- fread("../data/snap_retailers.csv", encoding = "UTF-8")
cat(sprintf("  Loaded %s retailers\n", format(nrow(retailers), big.mark = ",")))

# Clean column names
setnames(retailers, names(retailers), gsub(" ", "_", trimws(names(retailers))))
# Handle BOM in column names
old_names <- names(retailers)
old_names[1] <- sub("^\xEF\xBB\xBF", "", old_names[1])
old_names[1] <- sub("^\uFEFF", "", old_names[1])
old_names[1] <- gsub("[^[:print:]]", "", old_names[1])
setnames(retailers, names(retailers), old_names)

# Parse dates
retailers[, auth_date := as.Date(Authorization_Date, format = "%m/%d/%Y")]
retailers[, end_date  := as.Date(End_Date, format = "%m/%d/%Y")]

# Validate dates
stopifnot("Authorization dates must parse" = sum(!is.na(retailers$auth_date)) > 600000)
cat(sprintf("  Parsed dates: %s auth, %s end\n",
    format(sum(!is.na(retailers$auth_date)), big.mark = ","),
    format(sum(!is.na(retailers$end_date)), big.mark = ",")))

# Add year-quarter for authorization and end
retailers[, auth_yq := paste0(year(auth_date), "Q", quarter(auth_date))]
retailers[, end_yq  := ifelse(is.na(end_date), NA_character_,
                              paste0(year(end_date), "Q", quarter(end_date)))]

## ---- 2. Store type classification ----
retailers[, store_group := case_when(
  Store_Type == "Convenience Store" ~ "convenience",
  Store_Type %in% c("Supermarket", "Super Store", "Large Grocery Store") ~ "supermarket",
  Store_Type %in% c("Medium Grocery Store", "Small Grocery Store",
                     "Combination Grocery/Other") ~ "other_grocery",
  TRUE ~ "specialty"
)]

cat("Store groups:\n")
print(retailers[, .N, by = store_group][order(-N)])

## ---- 3. SNAP Online Purchasing Pilot treatment dates ----
## Source: Jones (2024), "Evaluating the Early Impacts of the SNAP Online Purchasing Pilot"
## PhD Dissertation, University of Kentucky, Tables 2.1 and 3.1
pilot_dates <- data.table(
  state = c("NY","WA","AL","IA","OR","NE","FL",
            "CA","KY","AZ","ID","NC",
            "DC","MO","TX",
            "NM","VT","WV",
            "WI",
            "CO","MD","MN","NJ","MA","MI","VA","GA","IL","TN","CT","IN","OH",
            "NV","OK","PA","RI","WY",
            "NH","SD",
            "DE",
            "SC","UT","ND","KS",
            "MS",
            "AR",
            "ME"),
  pilot_date = as.Date(c(
    "2019-04-18","2020-01-15","2020-03-01","2020-03-01","2020-03-01","2020-04-01","2020-04-01",
    "2020-04-23","2020-04-23","2020-04-23","2020-04-23","2020-04-23",
    "2020-05-07","2020-05-07","2020-05-07",
    "2020-05-14","2020-05-14","2020-05-14",
    "2020-05-21",
    "2020-05-28","2020-05-28","2020-05-28","2020-05-28","2020-05-28","2020-05-28",
    "2020-05-28","2020-05-28","2020-05-28","2020-05-28","2020-05-28","2020-05-28","2020-05-28",
    "2020-06-04","2020-06-04","2020-06-04","2020-06-04","2020-06-04",
    "2020-06-25","2020-06-25",
    "2020-07-02",
    "2020-08-01","2020-08-01","2020-08-01","2020-08-01",
    "2020-08-15",
    "2020-10-01",
    "2021-03-15"))
)

# Treatment quarter
pilot_dates[, treat_yq := paste0(year(pilot_date), "Q", quarter(pilot_date))]
pilot_dates[, treat_year := year(pilot_date)]
pilot_dates[, treat_quarter := quarter(pilot_date)]

# Never-treated states through 2020
never_treated <- c("AK", "HI", "LA", "MT")
cat(sprintf("\nTreated states: %d, Never-treated: %s\n",
    nrow(pilot_dates), paste(never_treated, collapse = ", ")))

## ---- 4. Download FNS state-monthly SNAP participation ----
cat("\nDownloading FNS state-monthly SNAP data...\n")

# FNS provides yearly files. Download 2017-2024 for pre/post coverage.
fns_base <- "https://fns-prod.azureedge.us/sites/default/files/resource-files"
fns_years <- 2017:2024
fns_list <- list()

for (yr in fns_years) {
  url <- sprintf("%s/snap_persons_%d.csv", fns_base, yr)
  tryCatch({
    tmp <- fread(url, fill = TRUE)
    tmp$source_year <- yr
    fns_list[[as.character(yr)]] <- tmp
    cat(sprintf("  Downloaded FY%d: %d rows\n", yr, nrow(tmp)))
  }, error = function(e) {
    # Try alternative URL patterns
    url2 <- sprintf("%s/SNAPsummary%d.csv", fns_base, yr)
    tryCatch({
      tmp <- fread(url2, fill = TRUE)
      tmp$source_year <- yr
      fns_list[[as.character(yr)]] <<- tmp
      cat(sprintf("  Downloaded FY%d (alt): %d rows\n", yr, nrow(tmp)))
    }, error = function(e2) {
      cat(sprintf("  WARNING: Could not download FY%d: %s\n", yr, e2$message))
    })
  })
}

if (length(fns_list) > 0) {
  fns_data <- rbindlist(fns_list, fill = TRUE)
  cat(sprintf("FNS data: %d total rows across %d years\n", nrow(fns_data), length(fns_list)))
} else {
  cat("WARNING: No FNS data downloaded. Proceeding without participation controls.\n")
  fns_data <- NULL
}

## ---- 5. Save processed data ----
saveRDS(retailers, "../data/retailers_clean.rds")
saveRDS(pilot_dates, "../data/pilot_dates.rds")
if (!is.null(fns_data)) saveRDS(fns_data, "../data/fns_monthly.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Retailers: %s rows\n", format(nrow(retailers), big.mark = ",")))
cat(sprintf("Pilot dates: %d states\n", nrow(pilot_dates)))
cat(sprintf("Store types: %s\n", paste(unique(retailers$store_group), collapse = ", ")))
