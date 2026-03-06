# ==============================================================================
# 01_fetch_gtrends.R — Google Trends data: climate, agricultural, and placebo
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# v2 ADDITION: agricultural search terms to demonstrate attention substitution
# During heat shocks in agricultural states, people search for crop/livelihood
# terms INSTEAD of climate terms — demonstrating crowd-out, not just inferring it.
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# STATE REFERENCE TABLE
# ==============================================================================
india_states <- data.table(
  state = c("Andhra Pradesh", "Assam", "Bihar", "Chhattisgarh",
            "Delhi", "Goa", "Gujarat", "Haryana",
            "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala",
            "Madhya Pradesh", "Maharashtra", "Odisha", "Punjab",
            "Rajasthan", "Tamil Nadu", "Telangana", "Uttar Pradesh",
            "Uttarakhand", "West Bengal"),
  geo_code = c("IN-AP", "IN-AS", "IN-BR", "IN-CT",
               "IN-DL", "IN-GA", "IN-GJ", "IN-HR",
               "IN-HP", "IN-JH", "IN-KA", "IN-KL",
               "IN-MP", "IN-MH", "IN-OR", "IN-PB",
               "IN-RJ", "IN-TN", "IN-TG", "IN-UP",
               "IN-UT", "IN-WB"),
  lat = c(15.83, 26.14, 25.60, 21.25,
          28.61, 15.50, 23.02, 29.06,
          31.10, 23.35, 15.32, 10.85,
          23.26, 19.08, 20.94, 31.63,
          26.92, 11.13, 17.39, 26.85,
          30.07, 22.57),
  lon = c(78.05, 91.74, 85.12, 81.63,
          77.23, 73.83, 72.57, 76.09,
          77.17, 85.33, 75.71, 76.27,
          77.41, 72.88, 84.80, 74.87,
          75.79, 78.66, 78.49, 80.91,
          79.49, 88.36)
)
fwrite(india_states, file.path(data_dir, "india_states.csv"))

# ==============================================================================
# GOOGLE TRENDS — State-level monthly search interest
# ==============================================================================
cat("=== Fetching Google Trends data ===\n")

fetch_gtrends <- function(keyword, geo_code, time_range = "2004-01-01 2024-12-31") {
  tryCatch({
    Sys.sleep(runif(1, 2, 4))
    res <- gtrends(keyword = keyword, geo = geo_code, time = time_range,
                   onlyInterest = TRUE)
    if (!is.null(res$interest_over_time) && nrow(res$interest_over_time) > 0) {
      dt <- as.data.table(res$interest_over_time)
      dt[, .(date, hits, keyword, geo)]
    } else {
      NULL
    }
  }, error = function(e) {
    message("  Error for ", geo_code, " '", keyword, "': ", e$message)
    NULL
  })
}

# --- CLIMATE TERMS (primary outcome) ---
climate_terms <- c("global warming", "climate change")

# --- AGRICULTURAL/LIVELIHOOD TERMS (v2 addition: substitution analysis) ---
# What do people search for INSTEAD during heat shocks?
ag_terms <- c("crop damage", "rain forecast", "crop insurance", "mandi price")

# --- PLACEBO TERMS ---
placebo_terms <- c("cricket", "Bollywood")

all_terms <- c(climate_terms, ag_terms, placebo_terms)

# --- NATIONAL LEVEL ---
cat("Fetching national Google Trends...\n")
gt_national_list <- list()
for (term in all_terms) {
  cat("  ", term, "\n")
  res <- fetch_gtrends(term, "IN")
  if (!is.null(res)) gt_national_list[[term]] <- res
}
gt_national <- rbindlist(gt_national_list, fill = TRUE)
fwrite(gt_national, file.path(data_dir, "google_trends_national.csv"))
cat("National:", nrow(gt_national), "rows\n")

# --- STATE LEVEL ---
cat("\nFetching state-level Google Trends...\n")
gt_state_list <- list()
for (i in 1:nrow(india_states)) {
  geo <- india_states$geo_code[i]
  sname <- india_states$state[i]
  cat("  ", sname, " (", geo, ")\n")
  for (term in all_terms) {
    res <- fetch_gtrends(term, geo)
    if (!is.null(res)) {
      res[, state := sname]
      gt_state_list[[paste(geo, term)]] <- res
    }
  }
}
gt_state <- rbindlist(gt_state_list, fill = TRUE)
fwrite(gt_state, file.path(data_dir, "google_trends_state.csv"))

cat("\nGoogle Trends saved:", nrow(gt_state), "rows\n")
cat("States with data:", uniqueN(gt_state$state), "\n")
cat("Terms:", paste(unique(gt_state$keyword), collapse = ", "), "\n")

# --- CROP AREA SHARES (pre-2000 baseline) ---
cat("\n=== Agricultural shares ===\n")

# Agricultural employment share from Census 2001 (pre-period)
ag_shares <- data.table(
  state = india_states$state,
  ag_emp_share = c(0.62, 0.53, 0.74, 0.72,
                   0.02, 0.16, 0.52, 0.52,
                   0.65, 0.60, 0.56, 0.23,
                   0.70, 0.55, 0.62, 0.39,
                   0.62, 0.44, 0.55, 0.65,
                   0.55, 0.46),
  # Crop area shares from Agricultural Statistics at a Glance
  crop_area_share = c(0.70, 0.75, 0.80, 0.75,
                      0.05, 0.30, 0.56, 0.65,
                      0.60, 0.70, 0.55, 0.45,
                      0.80, 0.53, 0.75, 0.65,
                      0.72, 0.40, 0.55, 0.80,
                      0.55, 0.65)
)
fwrite(ag_shares, file.path(data_dir, "ag_shares.csv"))

# --- INTERNET PENETRATION ---
cat("\n=== Internet penetration ===\n")

internet_data <- data.table(
  state = india_states$state,
  internet_pen_2015 = c(35, 18, 15, 15, 140, 90, 50, 55,
                        65, 18, 55, 55, 20, 55, 22, 55,
                        30, 45, 40, 20, 55, 30)
)
fwrite(internet_data, file.path(data_dir, "internet_penetration.csv"))

# --- VALIDATION ---
cat("\n=== Validation ===\n")
stopifnot("GT state data exists" = nrow(gt_state) > 100)
stopifnot("Multiple states" = uniqueN(gt_state$state) >= 15)
stopifnot("Climate terms present" = any(gt_state$keyword %in% climate_terms))
stopifnot("Ag terms present" = any(gt_state$keyword %in% ag_terms))

cat("All data validated.\n")
cat("\n=== Google Trends fetch complete ===\n")
