## 01c_fast_faers.R — Fast FAERS fetch (minimal API calls)
## APEP-0601

library(httr2)
library(jsonlite)
library(dplyr)

cat("=== Fast FAERS fetch ===\n")

pdufa_std <- readRDS("data/pdufa_standard.rds")
nda_list <- unique(pdufa_std$Application.Number.1.)
cat("Total drugs:", length(nda_list), "\n")

# Load existing cache
cache_file <- "data/faers_pdufa_cache.rds"
if (file.exists(cache_file)) {
  existing <- readRDS(cache_file)
  # Only keep complete rows (all non-NA)
  complete <- existing %>%
    filter(!is.na(total_ae), !is.na(serious_ae))
  cat("Loaded cache:", nrow(complete), "complete records\n")
} else {
  complete <- data.frame()
}

remaining <- setdiff(as.character(nda_list),
                     if (nrow(complete) > 0) complete$nda_number else character(0))
cat("Remaining:", length(remaining), "\n\n")

get_fda_count <- function(endpoint, search) {
  tryCatch({
    url <- paste0("https://api.fda.gov/drug/", endpoint, ".json")
    resp <- request(url) |>
      req_url_query(search = search, limit = 1) |>
      req_timeout(20) |>
      req_perform()
    result <- resp_body_json(resp)
    as.integer(result$meta$results$total)
  }, error = function(e) NA_integer_)
}

results_list <- list()
for (i in seq_along(remaining)) {
  nda <- remaining[i]
  nda_fmt <- sprintf("%06d", as.integer(nda))
  base_search <- paste0('patient.drug.openfda.application_number:"NDA', nda_fmt, '"')

  total <- get_fda_count("event", base_search)
  serious <- get_fda_count("event", paste0(base_search, ' AND serious:1'))
  death <- get_fda_count("event", paste0(base_search, ' AND seriousnessdeath:1'))
  hosp <- get_fda_count("event", paste0(base_search, ' AND seriousnesshospitalization:1'))
  recalls <- get_fda_count("enforcement",
    paste0('openfda.application_number:"NDA', nda_fmt, '"'))

  # Boxed warning check
  boxed <- FALSE
  tryCatch({
    url <- "https://api.fda.gov/drug/label.json"
    resp <- request(url) |>
      req_url_query(search = paste0('openfda.application_number:"NDA', nda_fmt, '"'),
                    limit = 1) |>
      req_timeout(20) |>
      req_perform()
    result <- resp_body_json(resp)
    label_count <- as.integer(result$meta$results$total)
    if (length(result$results) > 0 && !is.null(result$results[[1]]$boxed_warning)) {
      boxed <- TRUE
    }
  }, error = function(e) {
    label_count <<- NA_integer_
  })

  results_list[[i]] <- data.frame(
    nda_number = as.character(nda),
    total_ae = total,
    serious_ae = serious,
    death_ae = death,
    hospitalization_ae = hosp,
    recall_count = recalls,
    label_count = if (exists("label_count")) label_count else NA_integer_,
    has_boxed_warning = boxed,
    stringsAsFactors = FALSE
  )

  if (i %% 10 == 0 || i == length(remaining)) {
    cat(sprintf("  %d/%d (NDA%s: total=%s serious=%s death=%s)\n",
                i, length(remaining), nda_fmt,
                ifelse(is.na(total), "NA", as.character(total)),
                ifelse(is.na(serious), "NA", as.character(serious)),
                ifelse(is.na(death), "NA", as.character(death))))
    # Save progress
    partial <- bind_rows(complete, bind_rows(results_list))
    saveRDS(partial, cache_file)
  }

  Sys.sleep(0.15)  # ~6 queries/drug * 0.15s = ~1s per drug
}

# Final save
final <- bind_rows(complete, bind_rows(results_list))
saveRDS(final, cache_file)
cat("\n=== Done ===\n")
cat("Total records:", nrow(final), "\n")
cat("With AE data:", sum(!is.na(final$total_ae)), "\n")
cat("With serious AEs:", sum(!is.na(final$serious_ae) & final$serious_ae > 0), "\n")
cat("With death reports:", sum(!is.na(final$death_ae) & final$death_ae > 0), "\n")
