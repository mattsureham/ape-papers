## 01c_fetch_romania.R — Fetch Romania-specific data for turnover distributions
source("00_packages.R")

# ---- 1. Try Romania INS TEMPO Online API ----
# The TEMPO database has enterprise statistics by turnover size class
# http://statistici.insse.ro:8077/tempo-online/
# API endpoint: http://statistici.insse.ro:8077/tempo-ins/

cat("=== Attempting Romania INS TEMPO API ===\n")

# INT101B: Active enterprises by turnover size class
# Try the API endpoint
tempo_url <- "http://statistici.insse.ro:8077/tempo-ins/matrix/INT101B"
cat("Trying TEMPO API:", tempo_url, "\n")

resp <- tryCatch({
  httr_resp <- httr::GET(tempo_url, httr::timeout(30))
  cat("Status:", httr::status_code(httr_resp), "\n")
  httr::content(httr_resp, as = "text", encoding = "UTF-8")
}, error = function(e) {
  cat("TEMPO API error:", e$message, "\n")
  NULL
})

if (!is.null(resp)) {
  cat("Response length:", nchar(resp), "\n")
  cat("First 500 chars:", substr(resp, 1, 500), "\n")
}

# ---- 2. Try alternative TEMPO endpoint ----
cat("\n=== Trying TEMPO SDMX/JSON endpoint ===\n")
tempo_json_url <- "http://statistici.insse.ro:8077/tempo-ins/matrix/INT101B?lang=en"
resp2 <- tryCatch({
  httr_resp <- httr::GET(tempo_json_url, httr::timeout(30))
  cat("Status:", httr::status_code(httr_resp), "\n")
  httr::content(httr_resp, as = "text", encoding = "UTF-8")
}, error = function(e) {
  cat("TEMPO JSON error:", e$message, "\n")
  NULL
})

if (!is.null(resp2)) {
  cat("First 1000 chars:\n", substr(resp2, 1, 1000), "\n")
}

# ---- 3. Try data.gov.ro for ANAF financial data ----
cat("\n=== Trying data.gov.ro CKAN API ===\n")

# Search for enterprise/firm datasets
ckan_search <- "https://data.gov.ro/api/3/action/package_search?q=intreprinderi+cifra+afaceri&rows=10"
resp3 <- tryCatch({
  httr_resp <- httr::GET(ckan_search, httr::timeout(30))
  parsed <- jsonlite::fromJSON(httr::content(httr_resp, as = "text", encoding = "UTF-8"))
  cat("Found", parsed$result$count, "datasets\n")
  if (parsed$result$count > 0) {
    for (i in seq_len(min(5, nrow(parsed$result$results)))) {
      cat("\n  Dataset:", parsed$result$results$title[i], "\n")
      cat("  Name:", parsed$result$results$name[i], "\n")
      cat("  Org:", parsed$result$results$organization$title[i], "\n")
      # Check resources
      resources <- parsed$result$results$resources[[i]]
      if (!is.null(resources) && nrow(resources) > 0) {
        for (j in seq_len(min(3, nrow(resources)))) {
          cat("  Resource:", resources$name[j], "->", resources$url[j], "\n")
        }
      }
    }
  }
  parsed
}, error = function(e) {
  cat("data.gov.ro error:", e$message, "\n")
  NULL
})

# Also search for ANAF datasets
cat("\n=== Searching data.gov.ro for ANAF data ===\n")
ckan_anaf <- "https://data.gov.ro/api/3/action/package_search?q=ANAF+situatii+financiare&rows=10"
resp4 <- tryCatch({
  httr_resp <- httr::GET(ckan_anaf, httr::timeout(30))
  parsed <- jsonlite::fromJSON(httr::content(httr_resp, as = "text", encoding = "UTF-8"))
  cat("Found", parsed$result$count, "datasets\n")
  if (parsed$result$count > 0) {
    for (i in seq_len(min(5, nrow(parsed$result$results)))) {
      cat("\n  Dataset:", parsed$result$results$title[i], "\n")
      cat("  Name:", parsed$result$results$name[i], "\n")
    }
  }
  parsed
}, error = function(e) {
  cat("ANAF search error:", e$message, "\n")
  NULL
})

# ---- 4. Try Eurostat newer SBS framework (2021+) ----
cat("\n=== Fetching Eurostat sbs_sc_ovw (2021+ data) for all countries ===\n")
sbs_new <- tryCatch({
  get_eurostat("sbs_sc_ovw", time_format = "num")
}, error = function(e) {
  cat("sbs_sc_ovw all countries error:", e$message, "\n")
  NULL
})

if (!is.null(sbs_new)) {
  cat("New SBS data: ", nrow(sbs_new), " rows\n")
  cat("Variables: ", paste(names(sbs_new), collapse = ", "), "\n")
  for (v in names(sbs_new)) {
    uv <- unique(sbs_new[[v]])
    if (length(uv) < 60) {
      cat(v, ": ", paste(head(sort(as.character(uv)), 30), collapse = ", "), "\n")
    } else {
      cat(v, ": ", length(uv), " unique values\n")
    }
  }
  saveRDS(sbs_new, "../data/sbs_new.rds")
  cat("Saved sbs_new.rds\n")
}

# ---- 5. Eurostat SME performance review ----
cat("\n=== Trying tin00145 (SME indicators) ===\n")
sme <- tryCatch({
  get_eurostat("tin00145", time_format = "num")
}, error = function(e) {
  cat("tin00145 error:", e$message, "\n")
  NULL
})

if (!is.null(sme)) {
  cat("SME data: ", nrow(sme), " rows\n")
  cat("Variables: ", paste(names(sme), collapse = ", "), "\n")
  saveRDS(sme, "../data/sme_raw.rds")
}

cat("\n=== Data exploration complete ===\n")
