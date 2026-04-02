# 01b_fetch_late_integrado.R — Fetch later Integrado records (2018-2021)
source("00_packages.R")

BASE_URL <- "https://www.datos.gov.co/resource"
INTEGRADO_ID <- "rpmr-utcd"
BATCH_SIZE <- 50000

fetch_socrata_simple <- function(dataset_id, soql_select, soql_where,
                                  soql_order = NULL, max_records = 5000000) {
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
    if (status_code(resp) != 200) break
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

cat("=== Fetching Integrado 2018-2021 ===\n")
late_raw <- fetch_socrata_simple(
  INTEGRADO_ID,
  soql_select = paste0(
    "codigo_entidad_en_secop, nombre_de_la_entidad, ",
    "departamento_entidad, origen, ",
    "modalidad_de_contrataci_n, ",
    "fecha_de_firma_del_contrato, valor_contrato"
  ),
  soql_where = paste0(
    "fecha_de_firma_del_contrato >= '2018-01-01' ",
    "AND fecha_de_firma_del_contrato < '2022-01-01' ",
    "AND fecha_de_firma_del_contrato IS NOT NULL ",
    "AND codigo_entidad_en_secop IS NOT NULL"
  ),
  soql_order = "fecha_de_firma_del_contrato",
  max_records = 5000000
)

cat("Late Integrado rows:", nrow(late_raw), "\n")

# Combine with early data
dir.create("data", showWarnings = FALSE)
early_raw <- readRDS("data/integrado_raw.rds")
combined <- bind_rows(early_raw, late_raw)
cat("Combined Integrado rows:", nrow(combined), "\n")
saveRDS(combined, "data/integrado_raw.rds")
cat("Saved combined data.\n")
