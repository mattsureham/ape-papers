## ============================================================================
## 01_fetch_data.R — apep_1256
## Fetch Colombian election, campaign finance, and procurement data
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## --------------------------------------------------------------------------
## Helper: Socrata SODA API paginated fetch
## --------------------------------------------------------------------------
fetch_socrata <- function(domain, dataset_id, where_clause = NULL,
                          select = NULL, group = NULL,
                          limit_per_page = 50000) {
  base_url <- sprintf("https://%s/resource/%s.json", domain, dataset_id)
  all_rows <- list()
  offset <- 0

  repeat {
    params <- list(`$limit` = limit_per_page, `$offset` = offset)
    if (!is.null(where_clause)) params[["$where"]] <- where_clause
    if (!is.null(select)) params[["$select"]] <- select
    if (!is.null(group)) params[["$group"]] <- group

    resp <- GET(base_url, query = params,
                add_headers(`Accept` = "application/json"))
    if (status_code(resp) != 200) {
      msg <- content(resp, "text", encoding = "UTF-8")
      stop(sprintf("Socrata API error %d: %s", status_code(resp), msg))
    }

    chunk <- fromJSON(content(resp, "text", encoding = "UTF-8"), flatten = TRUE)
    if (length(chunk) == 0 || (is.data.frame(chunk) && nrow(chunk) == 0)) break

    all_rows[[length(all_rows) + 1]] <- as.data.table(chunk)
    offset <- offset + limit_per_page
    cat(sprintf("  Fetched %d rows (offset %d)\n", nrow(chunk), offset))

    if (nrow(chunk) < limit_per_page) break
    Sys.sleep(0.3)
  }

  if (length(all_rows) == 0) stop("No data returned from Socrata query")
  rbindlist(all_rows, fill = TRUE)
}

## --------------------------------------------------------------------------
## 1. ELECTION RESULTS — 2019 Alcaldía from CEDAE S3
## --------------------------------------------------------------------------
cat("=== Fetching 2019 election results ===\n")

election_url <- "https://s3.amazonaws.com/cedae.dskt.ch/resultados/Alcaldia/2019_alcaldia.dta.csv"
election_file <- paste0(data_dir, "election_2019_raw.csv")

download.file(election_url, election_file, mode = "wb", quiet = FALSE)
election_raw <- fread(election_file)

cat(sprintf("Election data: %d rows, %d municipalities\n",
            nrow(election_raw), uniqueN(election_raw$codmpio)))
stopifnot(nrow(election_raw) > 1000)
stopifnot("codmpio" %in% names(election_raw))
stopifnot("votos" %in% names(election_raw))

cat("Saved election_2019_raw.csv\n")

## --------------------------------------------------------------------------
## 2. CAMPAIGN FINANCE — Cuentas Claras 2019 (Alcaldía only)
## Dataset: jgra-rz2t
## --------------------------------------------------------------------------
cat("\n=== Fetching campaign finance data (Cuentas Claras 2019) ===\n")

finance_raw <- fetch_socrata(
  "www.datos.gov.co",
  "jgra-rz2t",
  where_clause = "cnd_nombre='Alcaldía'"
)

cat(sprintf("Campaign finance data: %d rows, %d candidates\n",
            nrow(finance_raw), uniqueN(finance_raw$can_identificacion)))
stopifnot(nrow(finance_raw) > 1000)

fwrite(finance_raw, paste0(data_dir, "finance_2019_raw.csv"))
cat("Saved finance_2019_raw.csv\n")

## --------------------------------------------------------------------------
## 3. SECOP II — Territorial procurement 2019-2022
## Dataset: jbjy-vk9h
## Server-side aggregation by entity, modality, year-month
## --------------------------------------------------------------------------
cat("\n=== Fetching SECOP II procurement data (2019-2022) ===\n")

# Fetch aggregated data: count and sum of contract values by entity,
# modality, and year-month. This keeps the download manageable.
secop_agg <- fetch_socrata(
  "www.datos.gov.co",
  "jbjy-vk9h",
  select = paste0(
    "departamento, ciudad, ",
    "modalidad_de_contratacion, ",
    "date_extract_y(fecha_de_firma) as yr, ",
    "date_extract_m(fecha_de_firma) as mo, ",
    "count(*) as n_contracts, ",
    "sum(valor_del_contrato) as total_value"
  ),
  where_clause = paste0(
    "fecha_de_firma >= '2018-01-01' AND fecha_de_firma < '2023-01-01' ",
    "AND orden='Territorial'"
  ),
  group = paste0(
    "departamento, ciudad, ",
    "modalidad_de_contratacion, ",
    "date_extract_y(fecha_de_firma), date_extract_m(fecha_de_firma)"
  )
)

cat(sprintf("SECOP II aggregated: %d rows\n", nrow(secop_agg)))
stopifnot(nrow(secop_agg) > 1000)

fwrite(secop_agg, paste0(data_dir, "secop_2019_2022_agg.csv"))
cat("Saved secop_2019_2022_agg.csv\n")

cat("\n=== All data fetched successfully ===\n")
