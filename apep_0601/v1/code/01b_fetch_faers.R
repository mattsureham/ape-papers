## 01b_fetch_faers.R — Fetch FAERS adverse event data for PDUFA standard-review drugs
## APEP-0601: PDUFA Deadline Bunching and Drug Safety

source("code/00_packages.R")

cat("=== Fetching FAERS data for PDUFA standard-review drugs ===\n")

pdufa_std <- readRDS("data/pdufa_standard.rds")
nda_list <- unique(pdufa_std$Application.Number.1.)
cat("Total drugs to query:", length(nda_list), "\n")

# Helper: query openFDA with rate limiting
query_openfda <- function(endpoint, search_term, max_retries = 3) {
  base_url <- paste0("https://api.fda.gov/drug/", endpoint, ".json")

  for (attempt in 1:max_retries) {
    result <- tryCatch({
      resp <- httr2::request(base_url) |>
        httr2::req_url_query(search = search_term, limit = 1) |>
        httr2::req_timeout(30) |>
        httr2::req_perform()
      httr2::resp_body_json(resp)
    }, error = function(e) {
      if (attempt < max_retries) Sys.sleep(2)
      NULL
    })
    if (!is.null(result)) return(result)
  }
  return(NULL)
}

get_count <- function(result) {
  if (!is.null(result) && !is.null(result$meta$results$total)) {
    return(as.integer(result$meta$results$total))
  }
  return(NA_integer_)
}

# Load cache if exists
cache_file <- "data/faers_pdufa_cache.rds"
if (file.exists(cache_file)) {
  ae_data <- readRDS(cache_file)
  cat("Loaded cache with", nrow(ae_data), "drugs\n")
} else {
  ae_data <- data.frame(
    nda_number = character(),
    total_ae = integer(),
    serious_ae = integer(),
    death_ae = integer(),
    hospitalization_ae = integer(),
    recall_count = integer(),
    label_count = integer(),
    has_boxed_warning = logical(),
    stringsAsFactors = FALSE
  )
}

# Determine which NDAs still need querying
done <- ae_data$nda_number
remaining <- setdiff(as.character(nda_list), done)
cat("Remaining to query:", length(remaining), "\n\n")

for (i in seq_along(remaining)) {
  nda <- remaining[i]
  nda_clean <- sprintf("%06d", as.integer(nda))

  # Total AEs
  r1 <- query_openfda("event",
    paste0('patient.drug.openfda.application_number:"NDA', nda_clean, '"'))
  Sys.sleep(0.25)

  # Serious AEs
  r2 <- query_openfda("event",
    paste0('patient.drug.openfda.application_number:"NDA', nda_clean,
           '" AND serious:1'))
  Sys.sleep(0.25)

  # Death AEs
  r3 <- query_openfda("event",
    paste0('patient.drug.openfda.application_number:"NDA', nda_clean,
           '" AND seriousnessdeath:1'))
  Sys.sleep(0.25)

  # Hospitalization AEs
  r4 <- query_openfda("event",
    paste0('patient.drug.openfda.application_number:"NDA', nda_clean,
           '" AND seriousnesshospitalization:1'))
  Sys.sleep(0.25)

  # Recalls
  r5 <- query_openfda("enforcement",
    paste0('openfda.application_number:"NDA', nda_clean, '"'))
  Sys.sleep(0.25)

  # Label changes
  r6 <- query_openfda("label",
    paste0('openfda.application_number:"NDA', nda_clean, '"'))

  # Check for boxed warning
  has_boxed <- FALSE
  if (!is.null(r6) && length(r6$results) > 0) {
    if (!is.null(r6$results[[1]]$boxed_warning)) has_boxed <- TRUE
  }
  Sys.sleep(0.25)

  ae_data <- bind_rows(ae_data, tibble(
    nda_number = as.character(nda),
    total_ae = get_count(r1),
    serious_ae = get_count(r2),
    death_ae = get_count(r3),
    hospitalization_ae = get_count(r4),
    recall_count = get_count(r5),
    label_count = get_count(r6),
    has_boxed_warning = has_boxed
  ))

  # Progress + periodic save
  if (i %% 25 == 0 || i == length(remaining)) {
    cat(sprintf("  %d/%d done (latest: NDA%s, total_ae=%s, serious=%s, death=%s)\n",
                i, length(remaining), nda_clean,
                ifelse(is.na(get_count(r1)), "NA", as.character(get_count(r1))),
                ifelse(is.na(get_count(r2)), "NA", as.character(get_count(r2))),
                ifelse(is.na(get_count(r3)), "NA", as.character(get_count(r3)))))
    saveRDS(ae_data, cache_file)
  }
}

saveRDS(ae_data, cache_file)
cat("\n=== FAERS query complete ===\n")
cat("Total drugs queried:", nrow(ae_data), "\n")
cat("Drugs with AE data:", sum(!is.na(ae_data$total_ae)), "\n")
cat("Drugs with serious AEs:", sum(!is.na(ae_data$serious_ae) & ae_data$serious_ae > 0), "\n")
cat("Drugs with death reports:", sum(!is.na(ae_data$death_ae) & ae_data$death_ae > 0), "\n")
cat("Drugs with recalls:", sum(!is.na(ae_data$recall_count) & ae_data$recall_count > 0), "\n")
cat("Drugs with boxed warnings:", sum(ae_data$has_boxed_warning, na.rm = TRUE), "\n")
