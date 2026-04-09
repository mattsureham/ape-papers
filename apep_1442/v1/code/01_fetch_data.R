# 01_fetch_data.R — Data acquisition for apep_1442
# Scrapes PINS appeal cases and downloads MHCLG housing statistics

source("00_packages.R")

set.seed(20260409)

# =============================================================================
# PART 1: Scrape PINS Appeal Case Portal
# =============================================================================

cat("=== PART 1: Scraping PINS Appeal Case Portal ===\n")

base_url <- "https://acp.planninginspectorate.gov.uk/ViewCase.aspx?caseid="

# Sample 3500 IDs from focused range (2019-2023 decisions)
sample_ids <- sort(sample(3220000:3360000, 3500))

scrape_case <- function(case_id) {
  url <- paste0(base_url, case_id)
  tryCatch({
    resp <- httr::GET(url, httr::timeout(10))
    if (httr::status_code(resp) != 200) return(NULL)

    page <- rvest::read_html(httr::content(resp, as = "text", encoding = "UTF-8"))

    lpa <- rvest::html_text(rvest::html_element(page, "#cphMainContent_labLPAName"), trim = TRUE)
    case_type <- rvest::html_text(rvest::html_element(page, "#cphMainContent_labCaseTypeName"), trim = TRUE)
    start_date <- rvest::html_text(rvest::html_element(page, "#cphMainContent_labStartDate"), trim = TRUE)
    outcome <- rvest::html_text(rvest::html_element(page, "#cphMainContent_labOutcome"), trim = TRUE)
    decision_date <- rvest::html_text(rvest::html_element(page, "#cphMainContent_labDecisionDate"), trim = TRUE)

    decision_link <- rvest::html_attr(
      rvest::html_element(page, "#cphMainContent_labDecisionLink a"),
      "href"
    )

    # Only keep cases with actual decisions
    if (is.na(lpa) || lpa == "" || is.na(outcome) || outcome == "" ||
        outcome == "Not yet decided") return(NULL)

    data.table(
      case_id = case_id,
      lpa = lpa,
      case_type = case_type,
      start_date = start_date,
      outcome = outcome,
      decision_date = decision_date,
      decision_link = ifelse(is.null(decision_link) || is.na(decision_link),
                             NA_character_, decision_link)
    )
  }, error = function(e) NULL)
}

cat("Scraping", length(sample_ids), "case IDs...\n")
cases_list <- list()

for (i in seq_along(sample_ids)) {
  result <- scrape_case(sample_ids[i])
  if (!is.null(result)) cases_list[[length(cases_list) + 1]] <- result
  Sys.sleep(0.3)

  if (i %% 500 == 0) {
    cat(sprintf("  %d/%d scraped. Valid: %d\n", i, length(sample_ids), length(cases_list)))
  }

  # Early stop at 2500 valid cases
  if (length(cases_list) >= 2500) {
    cat("  Reached 2500 valid cases. Stopping.\n")
    break
  }
}

cases_dt <- rbindlist(cases_list)
cat(sprintf("Scraped %d valid cases.\n", nrow(cases_dt)))

if (nrow(cases_dt) < 200) {
  stop("FATAL: Fewer than 200 valid cases. Cannot proceed.")
}

# =============================================================================
# PART 2: Extract Inspector Names from Decision Letter PDFs
# =============================================================================

cat("\n=== PART 2: Extracting inspector names ===\n")

cases_with_pdf <- cases_dt[!is.na(decision_link)]

# Sample up to 2000 for PDF extraction
if (nrow(cases_with_pdf) > 2000) {
  cases_for_pdf <- cases_with_pdf[sample(.N, 2000)]
} else {
  cases_for_pdf <- copy(cases_with_pdf)
}

extract_inspector <- function(decision_link_path) {
  tryCatch({
    pdf_url <- paste0("https://acp.planninginspectorate.gov.uk/", decision_link_path)
    tmp <- tempfile(fileext = ".pdf")
    on.exit(unlink(tmp))
    resp <- httr::GET(pdf_url, httr::write_disk(tmp, overwrite = TRUE), httr::timeout(15))
    if (httr::status_code(resp) != 200) return(NA_character_)

    txt <- pdftools::pdf_text(tmp)[1]

    # Primary pattern: "by [Name with Credentials]"
    match <- stringr::str_match(
      txt,
      "by\\s+([A-Z][A-Za-z\\s,.'()]+(?:MA|BA|BSc|LLB|MRICS|FRICS|MRTPI|FRTPI|DipTP|DipArch|PhD|MSc|MPhil|RIBA|FCIArb|MCIL|Hons)[A-Za-z\\s,.'()]*)"
    )

    if (is.na(match[1, 2])) {
      # Fallback: "by Mr/Mrs/Ms/Dr Name"
      match <- stringr::str_match(txt, "by\\s+((?:Mr|Mrs|Ms|Miss|Dr)\\s+[A-Z][A-Za-z\\s,.'()-]+?)\\s*\\n")
    }

    if (is.na(match[1, 2])) {
      # Broadest: "by" then capitalized words until newline
      match <- stringr::str_match(txt, "by\\s+([A-Z][a-z]+(?:\\s+[A-Z][A-Za-z.'()-]+)+?)\\s*\\n")
    }

    if (!is.na(match[1, 2])) {
      full <- trimws(match[1, 2])
      # Standardize: extract name before credential abbreviations
      name <- stringr::str_extract(full, "^(?:Mr|Mrs|Ms|Miss|Dr)?\\s*[A-Z][a-z]+(?:\\s+[A-Z][a-z]+){1,3}")
      if (!is.na(name)) return(trimws(name))
      return(full)
    }
    NA_character_
  }, error = function(e) NA_character_)
}

cat("Extracting inspector names from", nrow(cases_for_pdf), "PDFs...\n")
inspector_names <- character(nrow(cases_for_pdf))

for (i in seq_len(nrow(cases_for_pdf))) {
  inspector_names[i] <- extract_inspector(cases_for_pdf$decision_link[i])
  Sys.sleep(0.3)

  if (i %% 300 == 0) {
    n_found <- sum(!is.na(inspector_names[1:i]))
    cat(sprintf("  %d/%d PDFs. Inspectors found: %d (%.0f%%)\n",
                i, nrow(cases_for_pdf), n_found, 100 * n_found / i))
  }
}

cases_for_pdf[, inspector := inspector_names]
cases_dt <- merge(cases_dt, cases_for_pdf[, .(case_id, inspector)], by = "case_id", all.x = TRUE)

cat(sprintf("\nInspectors extracted: %d / %d (%.0f%%)\n",
            sum(!is.na(cases_dt$inspector)), nrow(cases_dt),
            100 * mean(!is.na(cases_dt$inspector))))
cat(sprintf("Unique inspectors: %d\n", uniqueN(cases_dt$inspector[!is.na(cases_dt$inspector)])))

# SAVE IMMEDIATELY after scraping (prevent data loss)
fwrite(cases_dt, "../data/pins_cases_raw.csv")
cat(sprintf("Saved %d cases to data/pins_cases_raw.csv\n", nrow(cases_dt)))

# =============================================================================
# PART 3: Download MHCLG Housing Statistics (Live Table 253)
# =============================================================================

cat("\n=== PART 3: MHCLG housing completions ===\n")

tryCatch({
  mhclg_url <- "https://assets.publishing.service.gov.uk/media/67c8b9cbfbe4c8a65c556b43/LiveTable253.ods"
  tmp_mhclg <- tempfile(fileext = ".ods")
  resp <- httr::GET(mhclg_url, httr::write_disk(tmp_mhclg, overwrite = TRUE), httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    file.copy(tmp_mhclg, "../data/mhclg_lt253.ods", overwrite = TRUE)
    cat("Downloaded MHCLG Live Table 253.\n")
  } else {
    cat("WARNING: MHCLG LT253 not available (status", httr::status_code(resp), ").\n")
  }
  unlink(tmp_mhclg)
}, error = function(e) {
  cat("WARNING: MHCLG download failed:", conditionMessage(e), "\n")
  cat("Proceeding without MHCLG data.\n")
})

# =============================================================================
# PART 4: Download Land Registry Price Paid Data (recent years)
# =============================================================================

cat("\n=== PART 4: Land Registry Price Paid Data ===\n")

tryCatch({
  lr_base <- "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"
  lr_years <- 2019:2024
  lr_all <- list()

  for (yr in lr_years) {
    tryCatch({
      lr_url <- sprintf("%s/pp-%d.csv", lr_base, yr)
      tmp_lr <- tempfile(fileext = ".csv")
      resp <- httr::GET(lr_url, httr::write_disk(tmp_lr, overwrite = TRUE), httr::timeout(120))
      if (httr::status_code(resp) == 200) {
        dt <- fread(tmp_lr, header = FALSE, col.names = c(
          "txn_id", "price", "date", "postcode", "property_type", "new_build",
          "tenure", "paon", "saon", "street", "locality", "town", "district",
          "county", "ppd_cat", "record_status"
        ))
        lr_all[[as.character(yr)]] <- dt
        cat(sprintf("  %d: %s transactions\n", yr, formatC(nrow(dt), big.mark = ",")))
      } else {
        cat(sprintf("  %d: FAILED (status %d)\n", yr, httr::status_code(resp)))
      }
      unlink(tmp_lr)
    }, error = function(e) {
      cat(sprintf("  %d: ERROR: %s\n", yr, conditionMessage(e)))
    })
  }

  if (length(lr_all) > 0) {
    lr_dt <- rbindlist(lr_all)
    fwrite(lr_dt, "../data/land_registry_ppd.csv")
    cat(sprintf("Total Land Registry transactions: %s\n", formatC(nrow(lr_dt), big.mark = ",")))
  } else {
    cat("WARNING: No Land Registry data downloaded.\n")
  }
}, error = function(e) {
  cat("WARNING: Land Registry download failed:", conditionMessage(e), "\n")
})

# =============================================================================
# Final summary (PINS data already saved above)
# =============================================================================

cat(sprintf("\n=== FINAL: %d PINS cases in data/pins_cases_raw.csv ===\n", nrow(cases_dt)))
cat(sprintf("Unique inspectors: %d\n", uniqueN(cases_dt$inspector[!is.na(cases_dt$inspector)])))
cat(sprintf("Unique LPAs: %d\n", uniqueN(cases_dt$lpa)))
cat("\nOutcome distribution:\n")
print(table(cases_dt$outcome))
