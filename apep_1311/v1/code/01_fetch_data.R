# 01_fetch_data.R — Fetch SECOP data from Colombia datos.gov.co Socrata API
# Strategy: Focus on SECOP II process-level data (bidder counts) plus
# entity adoption dates from Integrado. Use simple filter queries, aggregate locally.
source("00_packages.R")

INTEGRADO_ID <- "rpmr-utcd"
SECOPII_ID   <- "p6dx-8zbt"
BASE_URL     <- "https://www.datos.gov.co/resource"
BATCH_SIZE   <- 50000

fetch_socrata_simple <- function(dataset_id, soql_select, soql_where,
                                  soql_order = NULL, max_records = 2000000) {
  url <- paste0(BASE_URL, "/", dataset_id, ".json")
  all_data <- list()
  offset <- 0

  repeat {
    params <- list(
      `$select` = soql_select,
      `$where`  = soql_where,
      `$limit`  = as.character(BATCH_SIZE),
      `$offset` = format(offset, scientific = FALSE)
    )
    if (!is.null(soql_order)) params[["$order"]] <- soql_order

    resp <- GET(url, query = params, timeout(300))
    if (status_code(resp) != 200) {
      cat("API error at offset", offset, ":", status_code(resp), "\n")
      cat(substr(content(resp, "text"), 1, 300), "\n")
      break
    }
    batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    if (length(batch) == 0 || nrow(batch) == 0) break
    all_data[[length(all_data) + 1]] <- batch
    offset <- offset + BATCH_SIZE
    cat("  Fetched", format(offset, big.mark = ","), "records\n")
    if (offset >= max_records) break
    Sys.sleep(0.2)
  }

  bind_rows(all_data)
}

# ============================================================
# STEP 1: SECOP II Process-level data (main analysis dataset)
# ============================================================
cat("=== Step 1: Fetching SECOP II competitive processes ===\n")

secopii_raw <- fetch_socrata_simple(
  SECOPII_ID,
  soql_select = paste0(
    "codigo_entidad, entidad, departamento_entidad, ",
    "modalidad_de_contratacion, ",
    "fecha_de_publicacion_del, fecha_adjudicacion, ",
    "precio_base, valor_total_adjudicacion, ",
    "respuestas_al_procedimiento, proveedores_unicos_con, ",
    "estado_del_procedimiento"
  ),
  soql_where = paste0(
    "fecha_de_publicacion_del >= '2015-01-01' ",
    "AND fecha_de_publicacion_del < '2023-01-01' ",
    "AND estado_del_procedimiento = 'Seleccionado'"
  ),
  soql_order = "fecha_de_publicacion_del",
  max_records = 2000000
)

cat("SECOP II total rows:", nrow(secopii_raw), "\n")
stopifnot("No SECOP II data" = nrow(secopii_raw) > 0)

# ============================================================
# STEP 2: Integrado — lightweight entity contract counts
# ============================================================
cat("\n=== Step 2: Fetching Integrado contract records (lightweight) ===\n")

# Fetch just key columns: entity, date, origen, modality, value
# Filter to 2012-2022 to limit volume
integrado_raw <- fetch_socrata_simple(
  INTEGRADO_ID,
  soql_select = paste0(
    "codigo_entidad_en_secop, nombre_de_la_entidad, ",
    "departamento_entidad, origen, ",
    "modalidad_de_contrataci_n, ",
    "fecha_de_firma_del_contrato, valor_contrato"
  ),
  soql_where = paste0(
    "fecha_de_firma_del_contrato >= '2015-01-01' ",
    "AND fecha_de_firma_del_contrato < '2022-01-01' ",
    "AND fecha_de_firma_del_contrato IS NOT NULL ",
    "AND codigo_entidad_en_secop IS NOT NULL"
  ),
  soql_order = "fecha_de_firma_del_contrato",
  max_records = 5000000
)

cat("Integrado rows:", nrow(integrado_raw), "\n")
stopifnot("No Integrado data" = nrow(integrado_raw) > 0)

# ============================================================
# STEP 3: Save raw data
# ============================================================
dir.create("data", showWarnings = FALSE)
saveRDS(secopii_raw, "data/secopii_raw.rds")
saveRDS(integrado_raw, "data/integrado_raw.rds")

cat("\n=== Data fetch summary ===\n")
cat("SECOP II process rows:", nrow(secopii_raw), "\n")
cat("Integrado rows:", nrow(integrado_raw), "\n")
cat("Data saved to data/\n")
