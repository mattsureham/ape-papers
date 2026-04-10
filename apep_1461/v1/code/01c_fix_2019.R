source("code/00_packages.R")

data_dir <- "data"
base_url <- "https://www.inegi.org.mx/contenidos/programas/enoe/15ymas/datosabiertos"

quarters <- data.frame(
  year = c(2019, 2019, 2019, 2019, 2020),
  trim = c(1, 2, 3, 4, 1)
)

for (i in seq_len(nrow(quarters))) {
  yr <- quarters$year[i]
  tr <- quarters$trim[i]
  qlab <- sprintf("%dQ%d", yr, tr)

  rds_file <- file.path(data_dir, sprintf("enoe_%s.rds", qlab))
  zip_file <- file.path(data_dir, sprintf("enoe_%s.zip", qlab))
  extract_dir <- file.path(data_dir, sprintf("enoe_%s", qlab))

  url <- sprintf("%s/%d/conjunto_de_datos_enoe_%d_%dt_csv.zip", base_url, yr, yr, tr)
  cat(sprintf("  %s: downloading from %s\n", qlab, url))

  curl::curl_download(url, zip_file, quiet = TRUE)
  fsize <- file.info(zip_file)$size / 1048576
  cat(sprintf("  %s: downloaded %.1fMB\n", qlab, fsize))

  dir.create(extract_dir, showWarnings = FALSE)
  unzip(zip_file, exdir = extract_dir)

  csv_files <- list.files(extract_dir, pattern = "\\.csv$|\\.CSV$",
                          recursive = TRUE, full.names = TRUE)

  data_csvs <- csv_files[grepl("conjunto_de_datos/conjunto_de_datos_", csv_files)]
  sdem_file <- data_csvs[grepl("sdem", data_csvs, ignore.case = TRUE)]
  coe1_file <- data_csvs[grepl("coe1", data_csvs, ignore.case = TRUE)]
  coe2_file <- data_csvs[grepl("coe2", data_csvs, ignore.case = TRUE)]

  cat(sprintf("  %s: SDEM file: %s\n", qlab, basename(sdem_file[1])))
  sdem <- fread(sdem_file[1])
  setnames(sdem, tolower(names(sdem)))

  id_cols <- intersect(c("cd_a", "ent", "con", "v_sel", "n_hog", "h_mud", "n_ren"), names(sdem))
  keep <- intersect(c(id_cols, "sex", "eda", "niv_ins", "clase1", "clase2",
                       "pos_ocu", "seg_soc", "tip_con", "rama_est1", "rama_est2",
                       "hrsocup", "ingocup", "dur9c", "fac"), names(sdem))
  dt <- sdem[, ..keep]
  rm(sdem); gc(verbose = FALSE)

  if (length(coe1_file) > 0) {
    coe1 <- fread(coe1_file[1])
    setnames(coe1, tolower(names(coe1)))
    mcols <- intersect(id_cols, names(coe1))
    cvars <- intersect(c(mcols, "p3", "p3a", "p3b", "p3c"), names(coe1))
    if (length(cvars) > length(mcols)) dt <- merge(dt, coe1[, ..cvars], by = mcols, all.x = TRUE)
    rm(coe1); gc(verbose = FALSE)
  }

  if (length(coe2_file) > 0) {
    coe2 <- fread(coe2_file[1])
    setnames(coe2, tolower(names(coe2)))
    mcols <- intersect(id_cols, names(coe2))
    cvars <- intersect(c(mcols, "p6b1", "p6b2", "p7", "p7a"), names(coe2))
    if (length(cvars) > length(mcols)) dt <- merge(dt, coe2[, ..cvars], by = mcols, all.x = TRUE)
    rm(coe2); gc(verbose = FALSE)
  }

  dt[, year := yr]
  dt[, quarter := tr]
  dt[, yq := yr + (tr - 1) / 4]

  saveRDS(dt, rds_file)
  cat(sprintf("  %s: saved %s obs\n\n", qlab, format(nrow(dt), big.mark = ",")))

  rm(dt); gc(verbose = FALSE)
  unlink(extract_dir, recursive = TRUE)
  unlink(zip_file)
}

cat("Done re-downloading 2019 and 2020Q1.\n")
