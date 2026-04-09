## ============================================================================
## 00_packages.R — Closing the Golden Door (apep_0626)
## Individual-level occupational mobility after the 1924 Immigration Act
## ============================================================================

pkgs <- c(
  # Core data
  "data.table", "duckdb", "DBI",
  # Econometrics
  "fixest", "sandwich", "lmtest",
  # Tables
  "modelsummary", "kableExtra",
  # Figures (V2)
  "ggplot2", "ggthemes", "scales", "patchwork",
  # Utilities
  "jsonlite", "glue", "here"
)

new_pkgs <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(new_pkgs) > 0) {
  install.packages(new_pkgs, repos = "https://cloud.r-project.org", dependencies = TRUE)
}
invisible(lapply(pkgs, library, character.only = TRUE))

options(
  scipen = 999,
  datatable.print.nrows = 20
)

# Load .env for API keys
env_file <- here::here(".env")
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  env_lines <- env_lines[!grepl("^#|^\\s*$", env_lines)]
  for (line in env_lines) {
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(line, 1, eq_pos - 1))
      val <- trimws(substr(line, eq_pos + 1, nchar(line)))
      if (nchar(key) > 0) {
        args <- list(val)
        names(args) <- key
        do.call(Sys.setenv, args)
      }
    }
  }
}

cat(sprintf("Packages loaded. R %s, data.table %s, %d threads\n",
    R.version.string, packageVersion("data.table"), data.table::getDTthreads()))
cat(sprintf("Available RAM: ~%d GB\n",
    as.integer(as.numeric(system("sysctl -n hw.memsize", intern = TRUE)) / 1e9)))
