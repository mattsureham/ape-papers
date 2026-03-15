## 00_packages.R — apep_0697
## NZ Foreign Buyer Ban: Housing Price Effects

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Core packages
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("fixest", quietly = TRUE)) install.packages("fixest")
if (!requireNamespace("modelsummary", quietly = TRUE)) install.packages("modelsummary")
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
if (!requireNamespace("httr", quietly = TRUE)) install.packages("httr")
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  tryCatch(install.packages("fwildclusterboot"), error = function(e) {
    cat("fwildclusterboot not available for this R version, will use boottest alternative\n")
  })
}
if (!requireNamespace("Synth", quietly = TRUE)) install.packages("Synth")
if (!requireNamespace("kableExtra", quietly = TRUE)) install.packages("kableExtra")
if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")

library(tidyverse)
library(fixest)
library(modelsummary)
library(jsonlite)
library(httr)
tryCatch(library(fwildclusterboot), error = function(e) {
  cat("fwildclusterboot not loaded — will use sandwich/boot for bootstrap inference\n")
})
if (!requireNamespace("boot", quietly = TRUE)) install.packages("boot")
library(boot)
library(Synth)
library(kableExtra)
library(readxl)

cat("All packages loaded successfully.\n")
