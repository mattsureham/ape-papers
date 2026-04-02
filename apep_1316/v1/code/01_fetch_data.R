# 01_fetch_data.R — Download and parse BVA decisions
# apep_1316: BVA Judge Leniency IV
#
# Downloads BVA decision text files from va.gov for FY2017-2018
# Parses each file to extract: VLJ name, decision outcome, RO, date, issues

source("00_packages.R")
set.seed(42)

# --- Configuration ---
DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
raw_dir <- file.path(DATA_DIR, "raw_decisions")
dir.create(raw_dir, showWarnings = FALSE)

# FY2017: 1700001-1706062, FY2018: 1800001-1806343
fy_ranges <- list(
  FY2017 = list(prefix = "17", start = 1, end = 6062,
                base_url = "https://www.va.gov/vetapp17/files1/"),
  FY2018 = list(prefix = "18", start = 1, end = 6343,
                base_url = "https://www.va.gov/vetapp18/files1/")
)

# --- Download function using curl multi ---
download_batch <- function(urls, destfiles, batch_size = 100) {
  n <- length(urls)
  downloaded <- 0
  failed <- 0

  for (i in seq(1, n, by = batch_size)) {
    batch_end <- min(i + batch_size - 1, n)
    batch_urls <- urls[i:batch_end]
    batch_dests <- destfiles[i:batch_end]

    # Skip already downloaded
    exists_mask <- file.exists(batch_dests) & file.size(batch_dests) > 100
    if (all(exists_mask)) {
      downloaded <- downloaded + sum(exists_mask)
      next
    }

    pool <- curl::new_pool(total_con = 50, host_con = 20)
    results <- list()

    for (j in seq_along(batch_urls)) {
      if (exists_mask[j]) next
      local({
        idx <- j
        dest <- batch_dests[idx]
        curl::curl_fetch_multi(
          batch_urls[idx],
          done = function(res) {
            if (res$status_code == 200) {
              writeBin(res$content, dest)
              results[[idx]] <<- TRUE
            } else {
              results[[idx]] <<- FALSE
            }
          },
          fail = function(msg) {
            results[[idx]] <<- FALSE
          },
          pool = pool
        )
      })
    }

    curl::multi_run(pool = pool)
    downloaded <- downloaded + sum(exists_mask) + sum(unlist(results), na.rm = TRUE)

    if (i %% 1000 < batch_size) {
      cat(sprintf("Progress: %d/%d files processed\n", min(batch_end, n), n))
    }
  }

  cat(sprintf("Download complete: %d files\n", downloaded))
  return(downloaded)
}

# --- Build URL lists ---
all_urls <- c()
all_dests <- c()

for (fy_name in names(fy_ranges)) {
  fy <- fy_ranges[[fy_name]]
  ids <- sprintf("%s%05d", fy$prefix, fy$start:fy$end)
  urls <- paste0(fy$base_url, ids, ".txt")
  dests <- file.path(raw_dir, paste0(ids, ".txt"))
  all_urls <- c(all_urls, urls)
  all_dests <- c(all_dests, dests)
}

cat(sprintf("Downloading %d BVA decisions for FY2017-2018...\n", length(all_urls)))
n_downloaded <- download_batch(all_urls, all_dests, batch_size = 100)

# --- Parse each decision file ---
parse_decision <- function(filepath) {
  tryCatch({
    lines <- readLines(filepath, warn = FALSE, encoding = "latin1")
    if (length(lines) < 20) return(NULL)

    text <- paste(lines, collapse = "\n")

    # Citation number
    citation <- str_extract(lines[1], "\\d+")

    # Decision date
    date_line <- str_subset(lines[1:5], "Decision Date:")
    decision_date <- if (length(date_line) > 0) {
      str_extract(date_line[1], "\\d{2}/\\d{2}/\\d{2}")
    } else NA

    # Docket number
    docket_line <- str_subset(lines[1:10], "DOCKET NO")
    docket <- if (length(docket_line) > 0) {
      str_extract(docket_line[1], "[\\d-]+\\s*\\d*[A-Z]?")
    } else NA

    # Regional Office
    ro_line <- str_subset(lines[1:20], "Regional Office in")
    ro <- if (length(ro_line) > 0) {
      str_extract(ro_line[1], "Regional Office in (.+)")
      str_replace(ro_line[1], ".*Regional Office in\\s*", "") |>
        str_trim()
    } else NA

    # VLJ name (from signature block near end)
    tail_lines <- tail(lines, 30)
    vlj_line <- str_subset(tail_lines, "Veterans Law Judge")
    vlj_name <- if (length(vlj_line) > 0) {
      # VLJ name is typically on the line before or in the same block
      vlj_idx <- which(str_detect(tail_lines, "Veterans Law Judge"))[1]
      # Check line above for the name
      name_line <- tail_lines[max(1, vlj_idx - 1)]
      name <- str_replace_all(name_line, "^_+|_+$", "") |> str_trim()
      if (nchar(name) < 2 || str_detect(name, "Veterans Law Judge")) {
        # Name is on the same line
        str_extract(vlj_line[1], "^[A-Z][A-Z.\\s]+") |> str_trim()
      } else {
        name
      }
    } else NA

    # Decision outcome: look for ORDER section and classify
    order_start <- which(str_detect(lines, "^\\s*ORDER\\s*$"))
    conclusion_start <- which(str_detect(lines, "CONCLUSIONS OF LAW"))
    remand_start <- which(str_detect(lines, "^\\s*REMAND\\s*$"))

    # Check for grants, denials, remands in the ORDER and text
    has_granted <- str_detect(text, "(?i)(is granted|claim is granted|appeal is granted|benefit sought.*granted)")
    has_denied <- str_detect(text, "(?i)(is denied|claim is denied|appeal is denied|benefit sought.*denied)")
    has_remanded <- str_detect(text, "(?i)(is remanded|REMANDED|remand)")
    has_dismissed <- str_detect(text, "(?i)(is dismissed|appeal.*dismissed)")

    # Primary classification based on ORDER section
    if (length(order_start) > 0) {
      order_text <- paste(lines[order_start[1]:min(order_start[1] + 30, length(lines))], collapse = " ")
      if (str_detect(order_text, "(?i)granted")) {
        outcome <- "granted"
      } else if (str_detect(order_text, "(?i)denied")) {
        outcome <- "denied"
      } else if (str_detect(order_text, "(?i)remand")) {
        outcome <- "remanded"
      } else if (str_detect(order_text, "(?i)dismiss")) {
        outcome <- "dismissed"
      } else {
        outcome <- "other"
      }
    } else if (has_remanded && length(remand_start) > 0) {
      outcome <- "remanded"
    } else if (has_granted) {
      outcome <- "granted"
    } else if (has_denied) {
      outcome <- "denied"
    } else {
      outcome <- "other"
    }

    # Count issues
    issues_start <- which(str_detect(lines, "THE ISSUE"))
    if (length(issues_start) > 0) {
      # Count numbered issues
      issue_section <- lines[issues_start[1]:min(issues_start[1] + 30, length(lines))]
      n_issues <- sum(str_detect(issue_section, "^\\s*\\d+\\.\\s"))
      if (n_issues == 0) n_issues <- 1
    } else {
      n_issues <- NA
    }

    # Determine primary issue category from THE ISSUES section
    issue_text <- if (length(issues_start) > 0) {
      paste(lines[issues_start[1]:min(issues_start[1] + 20, length(lines))], collapse = " ")
    } else ""

    issue_category <- case_when(
      str_detect(issue_text, "(?i)PTSD|psychiatric|mental health|depression|anxiety") ~ "mental_health",
      str_detect(issue_text, "(?i)total disability.*individual unemployability|TDIU") ~ "tdiu",
      str_detect(issue_text, "(?i)increased (rating|evaluation|disability)") ~ "increased_rating",
      str_detect(issue_text, "(?i)service connection") ~ "service_connection",
      str_detect(issue_text, "(?i)earlier effective date") ~ "effective_date",
      str_detect(issue_text, "(?i)new and material") ~ "reopen",
      TRUE ~ "other"
    )

    tibble(
      citation = citation,
      decision_date = decision_date,
      docket = docket,
      regional_office = ro,
      vlj_name = vlj_name,
      outcome = outcome,
      n_issues = n_issues,
      issue_category = issue_category,
      filename = basename(filepath)
    )
  }, error = function(e) {
    NULL
  })
}

# --- Parse all downloaded files ---
cat("Parsing downloaded decisions...\n")
files <- list.files(raw_dir, pattern = "\\.txt$", full.names = TRUE)
cat(sprintf("Found %d files to parse\n", length(files)))

# Parse in parallel-ish (vectorized with lapply)
parsed_list <- lapply(files, parse_decision)
parsed_list <- parsed_list[!sapply(parsed_list, is.null)]

decisions <- bind_rows(parsed_list)
cat(sprintf("Successfully parsed %d decisions\n", nrow(decisions)))

# --- Clean and save ---
decisions <- decisions |>
  mutate(
    # Parse decision date
    decision_date = as.Date(decision_date, format = "%m/%d/%y"),
    # Extract fiscal year
    fiscal_year = ifelse(month(decision_date) >= 10,
                         year(decision_date) + 1,
                         year(decision_date)),
    # Clean VLJ name
    vlj_name = str_trim(vlj_name),
    vlj_name = ifelse(nchar(vlj_name) < 3 | is.na(vlj_name), NA, vlj_name),
    # Clean RO
    regional_office = str_trim(regional_office)
  ) |>
  filter(!is.na(vlj_name), !is.na(outcome))

cat(sprintf("After cleaning: %d decisions with identified VLJ and outcome\n", nrow(decisions)))
cat(sprintf("Unique VLJs: %d\n", n_distinct(decisions$vlj_name)))
cat(sprintf("Outcome distribution:\n"))
print(table(decisions$outcome))

# Save parsed data
write_csv(decisions, file.path(DATA_DIR, "bva_decisions_parsed.csv"))
cat("Saved parsed decisions to data/bva_decisions_parsed.csv\n")

# Validate: fail loudly if data is insufficient
stopifnot("Insufficient decisions: need at least 1000" = nrow(decisions) >= 1000)
stopifnot("Insufficient VLJs: need at least 20" = n_distinct(decisions$vlj_name) >= 20)
