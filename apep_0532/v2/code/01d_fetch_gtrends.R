# ==============================================================================
# 01d_fetch_gtrends.R — Google Trends SUBSTITUTION terms
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# In v2, Google Trends is NOT the primary outcome. Instead we use it to show
# WHERE attention goes during heat shocks: agricultural vs climate terms.
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
india_states <- fread(file.path(data_dir, "india_states.csv"))

# ==============================================================================
# GOOGLE TRENDS — Substitution analysis terms
# ==============================================================================
cat("=== Fetching Google Trends substitution terms ===\n")

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

# Climate terms (original)
climate_terms <- c("global warming", "climate change")

# SUBSTITUTION terms — what do people search for instead during heat shocks?
# These are agricultural/livelihood-related terms
ag_terms <- c("crop damage", "rain forecast", "crop insurance", "mandi price")

# Placebo terms
placebo_terms <- c("cricket", "Bollywood")

all_terms <- c(climate_terms, ag_terms, placebo_terms)

# Fetch national level first
cat("Fetching national Google Trends...\n")
gt_national_list <- list()
for (term in all_terms) {
  cat("  ", term, "\n")
  res <- fetch_gtrends(term, "IN")
  if (!is.null(res)) gt_national_list[[term]] <- res
}
gt_national <- rbindlist(gt_national_list, fill = TRUE)
fwrite(gt_national, file.path(data_dir, "google_trends_national.csv"))
cat("National trends:", nrow(gt_national), "rows\n")

# Fetch state level
cat("\nFetching state-level Google Trends...\n")
gt_state_list <- list()
for (i in 1:nrow(india_states)) {
  sname <- india_states$state[i]
  # Use state ISO code for Google Trends
  geo <- paste0("IN-", switch(sname,
    "Andhra Pradesh" = "AP", "Assam" = "AS", "Bihar" = "BR",
    "Chhattisgarh" = "CT", "Delhi" = "DL", "Goa" = "GA",
    "Gujarat" = "GJ", "Haryana" = "HR", "Himachal Pradesh" = "HP",
    "Jharkhand" = "JH", "Karnataka" = "KA", "Kerala" = "KL",
    "Madhya Pradesh" = "MP", "Maharashtra" = "MH", "Odisha" = "OR",
    "Punjab" = "PB", "Rajasthan" = "RJ", "Tamil Nadu" = "TN",
    "Telangana" = "TG", "Uttar Pradesh" = "UP", "Uttarakhand" = "UT",
    "West Bengal" = "WB", "XX"))

  cat("  ", sname, "(", geo, ")...\n")
  for (term in all_terms) {
    res <- fetch_gtrends(term, geo)
    if (!is.null(res)) {
      res[, state := sname]
      gt_state_list[[paste(geo, term)]] <- res
    }
  }
}
gt_state <- rbindlist(gt_state_list, fill = TRUE)
fwrite(gt_state, file.path(data_dir, "google_trends_state_v2.csv"))

cat("\nGoogle Trends saved:", nrow(gt_state), "rows\n")
cat("Terms:", paste(unique(gt_state$keyword), collapse = ", "), "\n")

cat("\n=== Google Trends substitution fetch complete ===\n")
