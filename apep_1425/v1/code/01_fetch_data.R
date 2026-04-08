## 01_fetch_data.R — apep_1425
## Fetch labor court case data from DataJud API
## Focus: TRT2 (São Paulo, largest), TRT15 (Campinas), TRT4 (Rio Grande do Sul)
## Three TRTs: ~10.6M total records; fetching G1 cases with sorteio + verdicts

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))
WORK_DIR <- file.path(dirname(sys.frame(1)$ofile), "..")

API_KEY <- "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="
BASE_URL <- "https://api-publica.datajud.cnj.jus.br"

# Target TRTs (3 largest with geographic diversity)
TRTS <- c("trt2", "trt4", "trt15")

# Verdict codes: 219=Procedência, 220=Improcedência, 221=Procedência em Parte
# Distribution code: 26=Distribuição (with complemento sorteio)
# We also want 385=Acordo (settlement) for settlement analysis

fetch_trt_page <- function(trt, search_after = NULL, page_size = 10000L) {
  url <- sprintf("%s/api_publica_%s/_search", BASE_URL, trt)

  query <- list(
    size = page_size,
    query = list(
      bool = list(
        must = list(
          list(match = list(grau = "G1")),
          list(match = list(movimentos.complementosTabelados.nome = "sorteio"))
        )
      )
    ),
    `_source` = list(
      "numeroProcesso", "grau", "orgaoJulgador", "dataAjuizamento",
      "classe", "assuntos", "movimentos"
    ),
    sort = list(
      list(dataAjuizamento = "asc"),
      list(`_id` = "asc")
    )
  )

  if (!is.null(search_after)) {
    query$search_after <- search_after
  }

  resp <- request(url) |>
    req_headers(
      Authorization = paste0("ApiKey ", API_KEY),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(query, auto_unbox = TRUE) |>
    req_timeout(120) |>
    req_retry(max_tries = 5, backoff = ~ 10) |>
    req_perform()

  content <- resp_body_json(resp)
  return(content)
}

extract_case_data <- function(hit) {
  src <- hit[["_source"]]
  movs <- src[["movimentos"]]

  # Find distribution movement with sorteio
  dist_vara <- NA_character_
  dist_date <- NA_character_

  # Find verdict movements
  verdict_code <- NA_integer_
  verdict_name <- NA_character_
  verdict_date <- NA_character_
  verdict_vara <- NA_character_

  # Find settlement
  has_settlement <- FALSE
  settlement_date <- NA_character_

  for (m in movs) {
    code <- m[["codigo"]]

    # Distribution (code 26) with sorteio
    if (!is.null(code) && code == 26) {
      comps <- m[["complementosTabelados"]]
      if (!is.null(comps)) {
        for (c in comps) {
          if (!is.null(c[["nome"]]) && c[["nome"]] == "sorteio") {
            oj <- m[["orgaoJulgador"]]
            if (!is.null(oj)) dist_vara <- as.character(oj[["codigo"]])
            dist_date <- m[["dataHora"]]
          }
        }
      }
    }

    # Verdicts
    if (!is.null(code) && code %in% c(219L, 220L, 221L)) {
      verdict_code <- as.integer(code)
      verdict_name <- m[["nome"]]
      verdict_date <- m[["dataHora"]]
      oj <- m[["orgaoJulgador"]]
      if (!is.null(oj)) verdict_vara <- as.character(oj[["codigo"]])
    }

    # Settlement (various codes — 385 is Acordo)
    if (!is.null(code) && code == 385L) {
      has_settlement <- TRUE
      settlement_date <- m[["dataHora"]]
    }
  }

  # Extract subject codes (assuntos)
  assuntos <- src[["assuntos"]]
  subject_codes <- paste(sapply(assuntos, function(a) a[["codigo"]]), collapse = ";")
  subject_names <- paste(sapply(assuntos, function(a) a[["nome"]]), collapse = ";")

  # Class
  classe_nome <- if (!is.null(src[["classe"]])) src[["classe"]][["nome"]] else NA_character_

  # Org julgador top-level
  oj_top <- src[["orgaoJulgador"]]
  vara_code <- if (!is.null(oj_top)) as.character(oj_top[["codigo"]]) else NA_character_
  vara_name <- if (!is.null(oj_top)) oj_top[["nome"]] else NA_character_
  muni_ibge <- if (!is.null(oj_top)) oj_top[["codigoMunicipioIBGE"]] else NA_integer_

  data.table(
    case_id = src[["numeroProcesso"]],
    filing_date = src[["dataAjuizamento"]],
    classe = classe_nome,
    subject_codes = subject_codes,
    subject_names = subject_names,
    vara_code = vara_code,
    vara_name = vara_name,
    muni_ibge = as.integer(muni_ibge),
    dist_vara = dist_vara,
    dist_date = dist_date,
    verdict_code = verdict_code,
    verdict_name = verdict_name,
    verdict_date = verdict_date,
    verdict_vara = verdict_vara,
    has_settlement = has_settlement,
    settlement_date = settlement_date
  )
}

# Main fetch loop
for (trt in TRTS) {
  cat(sprintf("\n=== Fetching %s ===\n", toupper(trt)))
  outfile <- file.path(WORK_DIR, "data", sprintf("%s_cases.csv", trt))

  if (file.exists(outfile)) {
    cat("  Already fetched, skipping.\n")
    next
  }

  all_cases <- list()
  search_after <- NULL
  page <- 0L
  total_fetched <- 0L
  max_records <- 500000L  # Cap at 500K per TRT for V1 (sample, not universe)

  repeat {
    page <- page + 1L
    cat(sprintf("  Page %d (total fetched: %d)...\n", page, total_fetched))

    result <- tryCatch(
      fetch_trt_page(trt, search_after = search_after),
      error = function(e) {
        cat(sprintf("  ERROR on page %d: %s\n", page, e$message))
        NULL
      }
    )

    if (is.null(result)) {
      cat("  Fetch failed, stopping this TRT.\n")
      break
    }

    hits <- result[["hits"]][["hits"]]
    if (length(hits) == 0) {
      cat("  No more hits.\n")
      break
    }

    # Extract case data
    page_data <- rbindlist(lapply(hits, extract_case_data), fill = TRUE)
    all_cases[[page]] <- page_data
    total_fetched <- total_fetched + nrow(page_data)

    # Get search_after from last hit
    last_hit <- hits[[length(hits)]]
    search_after <- last_hit[["sort"]]

    cat(sprintf("  Got %d cases (total: %d)\n", nrow(page_data), total_fetched))

    if (total_fetched >= max_records) {
      cat(sprintf("  Reached %dK cap.\n", max_records / 1000L))
      break
    }

    # Rate limiting
    Sys.sleep(0.5)
  }

  if (length(all_cases) > 0) {
    dt <- rbindlist(all_cases, fill = TRUE)
    cat(sprintf("  Total %s cases: %d\n", toupper(trt), nrow(dt)))

    # Save as parquet
    fwrite(dt, outfile)
    cat(sprintf("  Saved to %s\n", outfile))
  } else {
    cat(sprintf("  No data fetched for %s\n", toupper(trt)))
    stop(sprintf("FATAL: No data from %s. Cannot proceed.", toupper(trt)))
  }
}

cat("\n=== Data fetch complete ===\n")

# Combine all TRTs
all_files <- list.files(file.path(WORK_DIR, "data"), pattern = "trt.*_cases\\.csv$",
                         full.names = TRUE)
stopifnot(length(all_files) >= 3)

combined <- rbindlist(lapply(all_files, fread), fill = TRUE)
cat(sprintf("Combined dataset: %d cases across %d TRTs\n", nrow(combined), length(all_files)))
cat(sprintf("Unique varas: %d\n", uniqueN(combined$vara_code)))
cat(sprintf("Date range: %s to %s\n",
            min(combined$filing_date, na.rm = TRUE),
            max(combined$filing_date, na.rm = TRUE)))

# Save combined
fwrite(combined, file.path(WORK_DIR, "data", "all_cases.csv"))
cat("Saved combined dataset.\n")
