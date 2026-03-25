## 01_fetch_data.R — Download DGCP procurement data
## apep_0942: Dominican Republic MIPYME Procurement Set-Asides
## Source: Dirección General de Contrataciones Públicas (DGCP)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## --- Download three CSV datasets from DGCP ---

urls <- list(
  adjudicaciones = "https://www.dgcp.gob.do/new_dgcp/documentos/da/actualizados/adjudicaciones-secp.csv",
  procesos = "https://www.dgcp.gob.do/new_dgcp/documentos/da/actualizados/datos-procesos-publicados.csv",
  proveedores = "https://www.dgcp.gob.do/new_dgcp/documentos/da/actualizados/proveedores-del-estado.csv"
)

for (name in names(urls)) {
  dest <- file.path(data_dir, paste0(name, ".csv"))
  if (!file.exists(dest)) {
    cat("Downloading", name, "...\n")
    download.file(urls[[name]], dest, mode = "wb", quiet = FALSE)
  } else {
    cat(name, "already downloaded.\n")
  }
  # Verify file is not empty
  finfo <- file.info(dest)
  if (is.na(finfo$size) || finfo$size < 1000) {
    stop(paste0(name, " file is empty or missing"))
  }
  cat(name, ":", finfo$size / 1e6, "MB\n")
}

## --- Read and validate each dataset ---

cat("\n=== Reading adjudicaciones (awards) ===\n")
adj <- fread(file.path(data_dir, "adjudicaciones.csv"),
             encoding = "Latin-1", fill = TRUE)
cat("Rows:", nrow(adj), "| Cols:", ncol(adj), "\n")
cat("Columns:", paste(names(adj), collapse = ", "), "\n")

cat("\n=== Reading procesos (processes) ===\n")
proc <- fread(file.path(data_dir, "procesos.csv"),
              encoding = "Latin-1", fill = TRUE)
cat("Rows:", nrow(proc), "| Cols:", ncol(proc), "\n")
cat("Columns:", paste(names(proc), collapse = ", "), "\n")

cat("\n=== Reading proveedores (providers) ===\n")
prov <- fread(file.path(data_dir, "proveedores.csv"),
              encoding = "Latin-1", fill = TRUE)
cat("Rows:", nrow(prov), "| Cols:", ncol(prov), "\n")
cat("Columns:", paste(names(prov), collapse = ", "), "\n")

## --- Save as RDS for faster loading ---
saveRDS(adj, file.path(data_dir, "adjudicaciones.rds"))
saveRDS(proc, file.path(data_dir, "procesos.rds"))
saveRDS(prov, file.path(data_dir, "proveedores.rds"))

cat("\nAll data fetched and saved successfully.\n")
