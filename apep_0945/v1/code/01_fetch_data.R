## 01_fetch_data.R — Fetch rulemaking data from Regulations.gov API
## Fetches: (1) docket-level agency priority composition, (2) all NPRM + Final Rule documents 2010-2024
source("00_packages.R")

# Null-coalesce operator for older R versions
`%||%` <- function(x, y) if (is.null(x)) y else x

API_KEY <- Sys.getenv("REGULATIONS_GOV_API_KEY")
if (nchar(API_KEY) == 0) {
  # Try loading from .env
  env_file <- normalizePath("../../../../.env", mustWork = FALSE)
  if (file.exists(env_file)) {
    lines <- readLines(env_file, warn = FALSE)
    for (l in lines) {
      if (grepl("^REGULATIONS_GOV_API_KEY=", l)) {
        API_KEY <- sub("^REGULATIONS_GOV_API_KEY=", "", l)
        break
      }
    }
  }
}
stopifnot("REGULATIONS_GOV_API_KEY not found" = nchar(API_KEY) > 0)

BASE_URL <- "https://api.regulations.gov/v4"

## Helper: make one API call with retry
api_get <- function(endpoint, params = list()) {
  params$api_key <- API_KEY
  url <- paste0(BASE_URL, "/", endpoint)

  for (attempt in 1:3) {
    Sys.sleep(0.8)  # respect rate limit (~1000/hr)
    resp <- tryCatch({
      req <- request(url)
      for (nm in names(params)) {
        req <- req_url_query(req, !!nm := params[[nm]])
      }
      req |> req_timeout(30) |> req_perform()
    }, error = function(e) NULL)

    if (!is.null(resp) && resp_status(resp) == 200) {
      return(resp_body_json(resp))
    }
    if (!is.null(resp) && resp_status(resp) == 429) {
      cat("Rate limited, waiting 60s...\n")
      Sys.sleep(60)
    }
  }
  stop("API call failed after 3 attempts: ", url)
}

## ---- Part 1: Agency-level priority composition (for treatment intensity) ----
cat("=== Fetching agency priority compositions ===\n")

# Get top agencies from aggregation
top_agencies <- c("FAA", "EPA", "USCG", "NOAA", "FCC", "FDA", "IRS", "FMCSA",
                   "FWS", "CMS", "AMS", "DARS", "FAR", "FEMA", "BIS", "NHTSA",
                   "OSHA", "PHMSA", "HUD", "DOE", "CPSC", "MSHA", "FTC", "ATF",
                   "APHIS", "CBP", "SEC", "TTB", "NRC", "USDA")

agency_priority <- data.table()
for (ag in top_agencies) {
  cat("  Agency:", ag, "...")
  result <- api_get("dockets", list(
    `filter[docketType]` = "Rulemaking",
    `filter[agencyId]` = ag,
    `page[size]` = "5"
  ))

  total <- result$meta$totalElements
  prio_agg <- result$meta$aggregations$priorityCategory

  if (length(prio_agg) > 0 && total > 0) {
    prio_dt <- data.table(
      agency = ag,
      total_dockets = as.integer(total),
      category = as.character(sapply(prio_agg, `[[`, "label")),
      count = as.integer(sapply(prio_agg, `[[`, "docCount"))
    )
    agency_priority <- rbind(agency_priority, prio_dt, fill = TRUE)
  }
  cat(" total=", total, "\n")
}

fwrite(agency_priority, "../data/agency_priority.csv")
cat("Saved agency_priority.csv\n")

## ---- Part 2: Fetch all documents (NPRMs + Final Rules) 2010-2024 ----
fetch_documents <- function(doc_type, year_start, year_end) {
  all_docs <- list()

  for (yr in year_start:year_end) {
    for (half in 1:2) {
      if (half == 1) {
        date_ge <- paste0(yr, "-01-01")
        date_le <- paste0(yr, "-06-30")
      } else {
        date_ge <- paste0(yr, "-07-01")
        date_le <- paste0(yr, "-12-31")
      }

      page_num <- 1
      total_fetched <- 0

      repeat {
        result <- api_get("documents", list(
          `filter[documentType]` = doc_type,
          `filter[postedDate][ge]` = date_ge,
          `filter[postedDate][le]` = date_le,
          `page[size]` = "250",
          `page[number]` = as.character(page_num)
        ))

        items <- result$data
        if (length(items) == 0) break

        batch <- rbindlist(lapply(items, function(x) {
          w <- x$attributes$withdrawn
          if (is.null(w)) w <- FALSE
          data.table(
            doc_id = as.character(x$id),
            doc_type = as.character(x$attributes$documentType %||% ""),
            agency_id = as.character(x$attributes$agencyId %||% ""),
            posted_date = as.character(x$attributes$postedDate %||% ""),
            docket_id = as.character(x$attributes$docketId %||% ""),
            withdrawn = as.logical(w),
            title = as.character(x$attributes$title %||% "")
          )
        }), fill = TRUE)

        all_docs[[length(all_docs) + 1]] <- batch
        total_fetched <- total_fetched + nrow(batch)

        hn <- result$meta$hasNextPage
        has_next <- if (is.null(hn)) FALSE else as.logical(hn)
        if (!has_next || page_num >= 20) break
        page_num <- page_num + 1
      }

      cat(sprintf("  %s %d-H%d: %d documents\n", doc_type, yr, half, total_fetched))
    }
  }

  rbindlist(all_docs, fill = TRUE)
}

cat("\n=== Fetching NPRMs 2010-2024 ===\n")
nprms <- fetch_documents("Proposed Rule", 2010, 2024)
cat(sprintf("Total NPRMs: %d\n", nrow(nprms)))

cat("\n=== Fetching Final Rules 2010-2024 ===\n")
rules <- fetch_documents("Rule", 2010, 2024)
cat(sprintf("Total Final Rules: %d\n", nrow(rules)))

fwrite(nprms, "../data/nprms_2010_2024.csv")
fwrite(rules, "../data/rules_2010_2024.csv")
cat("\nData saved to data/nprms_2010_2024.csv and data/rules_2010_2024.csv\n")

## ---- Part 3: Fetch EO 13771 designation data ----
cat("\n=== Fetching EO 13771 designations ===\n")
eo_designations <- c("Deregulatory", "Regulatory")

eo_data <- data.table()
for (ag in top_agencies) {
  for (desig in eo_designations) {
    result <- api_get("dockets", list(
      `filter[docketType]` = "Rulemaking",
      `filter[agencyId]` = ag,
      `filter[eo13771Designation]` = desig,
      `page[size]` = "5"
    ))
    total <- result$meta$totalElements
    eo_data <- rbind(eo_data, data.table(
      agency = ag, designation = desig, count = total
    ))
  }
  cat("  ", ag, "\n")
}

fwrite(eo_data, "../data/eo13771_designations.csv")
cat("Saved eo13771_designations.csv\n")
cat("\n=== Data fetch complete ===\n")
