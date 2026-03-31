# 01b_fix_pxweb.R — Debug PXWeb API and fetch population data
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

source("00_packages.R")

cat("=== Fixing BFS PXWeb API Calls ===\n")

pxweb_base <- "https://www.pxweb.bfs.admin.ch/api/v1/en"

# ---------------------------------------------------------------
# 1. Get table metadata to understand variable structure
# ---------------------------------------------------------------

cat("\n--- Getting table metadata ---\n")

# Municipal population table
table_url <- paste0(pxweb_base, "/px-x-0102020000_201/px-x-0102020000_201.px")

meta_resp <- GET(table_url, timeout(60))
cat("Metadata status:", status_code(meta_resp), "\n")

if (status_code(meta_resp) == 200) {
  meta <- content(meta_resp, as = "parsed")
  cat("Table title:", meta$title, "\n")

  for (v in meta$variables) {
    cat("\n  Variable:", v$code, "\n")
    cat("    Text:", v$text, "\n")
    cat("    Values (first 5):", paste(head(v$values, 5), collapse = ", "), "\n")
    cat("    Value texts (first 5):", paste(head(v$valueTexts, 5), collapse = ", "), "\n")
    cat("    Total values:", length(v$values), "\n")
  }
}

# ---------------------------------------------------------------
# 2. Try alternative population data table
# ---------------------------------------------------------------

cat("\n--- Trying STATPOP table (permanent resident population) ---\n")

# Try the STATPOP municipality data
# BFS table for permanent resident population by municipality
alt_tables <- c(
  "px-x-0102010000_101/px-x-0102010000_101.px",  # Pop by municipality
  "px-x-0102020000_201/px-x-0102020000_201.px",  # Pop movements
  "px-x-0102010000_102/px-x-0102010000_102.px"   # Pop by nationality
)

for (tbl in alt_tables) {
  tbl_url <- paste0(pxweb_base, "/", tbl)
  cat("  Checking:", tbl, "\n")

  resp <- tryCatch(GET(tbl_url, timeout(30)), error = function(e) NULL)

  if (!is.null(resp) && status_code(resp) == 200) {
    tbl_meta <- content(resp, as = "parsed")
    cat("    ✓ Title:", tbl_meta$title, "\n")

    for (v in tbl_meta$variables) {
      cat("      →", v$code, ":", v$text, "(", length(v$values), "values)\n")
    }
  } else {
    cat("    ✗ Not available\n")
  }
}

# ---------------------------------------------------------------
# 3. Search opendata.swiss for cross-border worker datasets
# ---------------------------------------------------------------

cat("\n--- Searching opendata.swiss for cross-border worker data ---\n")

# Search with German terms (more likely to find Swiss data)
search_terms <- c("Grenzgaenger", "grenzgaenger", "cross-border", "frontaliers")

for (term in search_terms) {
  cat("  Searching:", term, "\n")
  resp <- GET(
    "https://ckan.opendata.swiss/api/3/action/package_search",
    query = list(q = term, rows = 5),
    timeout(30)
  )

  if (status_code(resp) == 200) {
    results <- content(resp, as = "parsed")
    cat("    Results:", results$result$count, "\n")

    for (r in results$result$results) {
      title <- r$title$en %||% r$title$de %||% r$name
      cat("    -", title, "\n")

      # Show downloadable resources
      for (res in r$resources) {
        fmt <- res$format %||% "unknown"
        if (grepl("csv|px|xlsx|json", fmt, ignore.case = TRUE)) {
          cat("      [", fmt, "]", substr(res$url %||% "", 1, 100), "\n")
        }
      }
    }
  }
}

# ---------------------------------------------------------------
# 4. Direct BFS STAT-TAB search for GGS
# ---------------------------------------------------------------

cat("\n--- BFS STAT-TAB: Looking for GGS tables ---\n")

# Try known GGS PXWeb table paths
ggs_candidates <- c(
  "px-x-0302000000_106",  # Cross-border by canton
  "px-x-0302000000_107",  # Cross-border by activity
  "px-x-0302030000_106",  # Alt path
  "px-x-0302000000_101",  # Labor market base
  "px-x-0302000000_102",  # Labor market detail
  "px-x-0302010000_106"   # Another path
)

for (tbl_base in ggs_candidates) {
  tbl_url <- paste0(pxweb_base, "/", tbl_base, "/", tbl_base, ".px")
  resp <- tryCatch(GET(tbl_url, timeout(15)), error = function(e) NULL)

  if (!is.null(resp) && status_code(resp) == 200) {
    tbl_meta <- content(resp, as = "parsed")
    cat("  ✓", tbl_base, ":", tbl_meta$title, "\n")
  }
}

# ---------------------------------------------------------------
# 5. List available tables in the employment section
# ---------------------------------------------------------------

cat("\n--- Listing BFS employment tables ---\n")

# PXWeb navigation: list tables in section 03 (employment)
nav_url <- paste0(pxweb_base, "/px-x-0302000000_106")
nav_resp <- tryCatch(GET(nav_url, timeout(30)), error = function(e) NULL)

if (!is.null(nav_resp) && status_code(nav_resp) == 200) {
  nav_data <- content(nav_resp, as = "parsed")
  cat("  Section contents:\n")
  if (is.list(nav_data)) {
    for (item in nav_data) {
      cat("    -", item$id %||% item$text %||% "unknown", "\n")
    }
  }
}

cat("\n=== Debug complete ===\n")
