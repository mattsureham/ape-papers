# 00_packages.R — Load libraries for EV registration fee analysis
# APEP-0622

library(tidyverse)
library(fixest)
library(did)
library(jsonlite)
library(httr)

# Suppress scientific notation
options(scipen = 999)

# Load environment variables from .env
env_file <- file.path(Sys.getenv("HOME"), "auto-policy-evals", ".env")
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    if (grepl("^export\\s+", line)) line <- sub("^export\\s+", "", line)
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub("^['\"]|['\"]$", "", val)
      if (Sys.getenv(key) == "") Sys.setenv2 <- function(k, v) do.call(Sys.setenv, setNames(list(v), k))
      if (Sys.getenv(key) == "") do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env from:", env_file, "\n")
}

# Set working directory to paper root (relative paths only)
if (!file.exists("code/00_packages.R") && file.exists("../code/00_packages.R")) {
  setwd("..")
}

cat("Working directory:", getwd(), "\n")
cat("Packages loaded successfully.\n")
