source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

base_url <- "https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/datosabiertos"

build_enoe_url <- function(year, trim) {
  if (year <= 2020 & trim == 1) {
    sprintf("%s/%d/conjunto_de_datos_enoe_%d_%dt_csv.zip", base_url, year, year, trim)
  } else if (year == 2019) {
    sprintf("%s/%d/conjunto_de_datos_enoe_%d_%dt_csv.zip", base_url, year, year, trim)
  } else if (year >= 2023) {
    sprintf("%s/%d/conjunto_de_datos_enoe_%d_%dt_csv.zip", base_url, year, year, trim)
  } else {
    sprintf("%s/%d/conjunto_de_datos_enoen_%d_%dt_csv.zip", base_url, year, year, trim)
  }
}

quarters <- data.frame(
  year = c(rep(2019, 4), 2020, rep(2020, 2), rep(2021, 4), rep(2022, 4), rep(2023, 4), rep(2024, 4)),
  trim = c(1:4, 1, 3, 4, 1:4, 1:4, 1:4, 1:4)
)

all_data <- list()
cat("Downloading ENOE quarterly data (22 quarters)...\n\n")

for (i in seq_len(nrow(quarters))) {
  yr <- quarters$year[i]
  tr <- quarters$trim[i]
  qlab <- sprintf("%dQ%d", yr, tr)

  rds_file <- file.path(data_dir, sprintf("enoe_%s.rds", qlab))
  if (file.exists(rds_file)) {
    cat(sprintf("  %s: already processed, loading\n", qlab))
    all_data[[qlab]] <- readRDS(rds_file)
    next
  }

  zip_file <- file.path(data_dir, sprintf("enoe_%s.zip", qlab))
  extract_dir <- file.path(data_dir, sprintf("enoe_%s", qlab))
  url <- build_enoe_url(yr, tr)
  cat(sprintf("  %s: downloading from %s\n", qlab, url))

  dl_ok <- tryCatch({
    curl::curl_download(url, zip_file, quiet = TRUE)
    file.info(zip_file)$size > 10000
  }, error = function(e) {
    cat(sprintf("  ERROR downloading %s: %s\n", qlab, e$message))
    FALSE
  })

  if (!dl_ok) {
    stop(sprintf("FATAL: Failed to download ENOE data for %s. Cannot proceed.", qlab))
  }

  fsize <- file.info(zip_file)$size / 1048576
  cat(sprintf("  %s: downloaded %.1fMB, extracting...\n", qlab, fsize))

  dir.create(extract_dir, showWarnings = FALSE)
  unzip(zip_file, exdir = extract_dir)

  csv_files <- list.files(extract_dir, pattern = "\\.csv$|\\.CSV$",
                          recursive = TRUE, full.names = TRUE)

  data_csvs <- csv_files[grepl("conjunto_de_datos/conjunto_de_datos_", csv_files)]
  if (length(data_csvs) == 0) data_csvs <- csv_files

  sdem_file <- data_csvs[grepl("sdem", data_csvs, ignore.case = TRUE)]
  coe1_file <- data_csvs[grepl("coe1", data_csvs, ignore.case = TRUE)]
  coe2_file <- data_csvs[grepl("coe2", data_csvs, ignore.case = TRUE)]

  if (length(sdem_file) == 0) {
    cat(sprintf("  %s: CSV files found: %s\n", qlab, paste(basename(csv_files), collapse = ", ")))
    stop(sprintf("FATAL: No SDEM file found for %s", qlab))
  }

  cat(sprintf("  %s: reading SDEM (%s)\n", qlab, basename(sdem_file[1])))
  sdem <- fread(sdem_file[1])
  setnames(sdem, tolower(names(sdem)))

  id_cols <- intersect(c("cd_a", "ent", "con", "v_sel", "n_hog", "h_mud", "n_ren"),
                       names(sdem))

  keep <- intersect(c(id_cols, "sex", "eda", "niv_ins", "cs_p13_1",
                       "clase1", "clase2", "clase3",
                       "pos_ocu", "seg_soc", "tip_con", "rama_est1",
                       "rama_est2", "hrsocup", "ingocup", "dur9c",
                       "emp_ppal", "sub_o", "tpg_p8a",
                       "per", "ca", "t_loc", "fac"),
                    names(sdem))

  dt <- sdem[, ..keep]
  rm(sdem)
  gc(verbose = FALSE)

  if (length(coe1_file) > 0) {
    cat(sprintf("  %s: reading COE1\n", qlab))
    coe1 <- fread(coe1_file[1])
    setnames(coe1, tolower(names(coe1)))
    mcols <- intersect(id_cols, names(coe1))
    cvars <- intersect(c(mcols, "p3", "p3a", "p3b", "p3c", "p4a"), names(coe1))
    if (length(cvars) > length(mcols)) {
      dt <- merge(dt, coe1[, ..cvars], by = mcols, all.x = TRUE)
    }
    rm(coe1)
    gc(verbose = FALSE)
  }

  if (length(coe2_file) > 0) {
    cat(sprintf("  %s: reading COE2\n", qlab))
    coe2 <- fread(coe2_file[1])
    setnames(coe2, tolower(names(coe2)))
    mcols <- intersect(id_cols, names(coe2))
    cvars <- intersect(c(mcols, "p6b1", "p6b2", "p6c", "p7", "p7a", "p7c"), names(coe2))
    if (length(cvars) > length(mcols)) {
      dt <- merge(dt, coe2[, ..cvars], by = mcols, all.x = TRUE)
    }
    rm(coe2)
    gc(verbose = FALSE)
  }

  dt[, year := yr]
  dt[, quarter := tr]
  dt[, yq := yr + (tr - 1) / 4]

  saveRDS(dt, rds_file)
  all_data[[qlab]] <- dt

  rm(dt)
  unlink(extract_dir, recursive = TRUE)
  unlink(zip_file)
  gc(verbose = FALSE)

  cat(sprintf("  %s: done (%s obs)\n\n", qlab, format(nrow(all_data[[qlab]]), big.mark = ",")))
}

enoe <- rbindlist(all_data, fill = TRUE)
cat(sprintf("\nCombined dataset: %s observations across %d quarters\n",
            format(nrow(enoe), big.mark = ","),
            length(unique(paste(enoe$year, enoe$quarter)))))

saveRDS(enoe, file.path(data_dir, "enoe_combined.rds"))
cat("Saved combined data to data/enoe_combined.rds\n")
