# 01b_fetch_pop.R — Fetch population data from CBS
# Try multiple CBS population tables

source("00_packages.R")
library(cbsodataR)

# Try table 37230NED (Kerncijfers wijken en buurten - population by municipality)
# Or 70072NED (Regionale kerncijfers Nederland)
cat("Trying CBS population table 70072NED (Regionale kerncijfers)...\n")

pop_raw <- tryCatch({
  cbs_get_data("70072NED",
               select = c("RegioS", "Perioden", "TotaleBevolking_1"))
}, error = function(e) {
  cat("70072NED failed:", conditionMessage(e), "\n")
  cat("Trying 37296NED...\n")
  tryCatch({
    cbs_get_data("37296NED",
                 select = c("RegioS", "Perioden", "TotaleBevolking_1"))
  }, error = function(e2) {
    cat("37296NED failed:", conditionMessage(e2), "\n")
    NULL
  })
})

if (is.null(pop_raw) || nrow(pop_raw) == 0) {
  # Alternative: use CBS Statline directly via HTTP
  cat("Trying CBS OData v4 directly for population...\n")
  library(httr)

  # CBS v4 population table
  url <- "https://datasets.cbs.nl/odata/v4/CBS/03759NED/Observations?$select=RegioS,Perioden,TotaleBevolking_1"
  resp <- GET(url, timeout(120))

  if (status_code(resp) == 200) {
    parsed <- content(resp, "parsed", simplifyVector = TRUE)
    pop_raw <- parsed$value
    # Handle pagination
    next_link <- parsed[["@odata.nextLink"]]
    while (!is.null(next_link)) {
      resp <- GET(next_link, timeout(120))
      parsed <- content(resp, "parsed", simplifyVector = TRUE)
      pop_raw <- bind_rows(pop_raw, parsed$value)
      next_link <- parsed[["@odata.nextLink"]]
      Sys.sleep(0.3)
    }
  } else {
    stop("All population data fetch attempts failed. Status: ", status_code(resp))
  }
}

cat(sprintf("Fetched %d population records.\n", nrow(pop_raw)))
stopifnot(nrow(pop_raw) > 0)

saveRDS(pop_raw, "../data/pop_raw.rds")
cat("Population data saved.\n")
