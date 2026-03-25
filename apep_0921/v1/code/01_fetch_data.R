## 01_fetch_data.R — Download and parse DOJ ESAC FOIA data
## apep_0917: Civil Asset Forfeiture Regulatory Leakage

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---------- Download DOJ ESAC FOIA zip ----------
esac_url <- "https://www.justice.gov/afp/dl/ESACfoia.zip"
zip_path <- file.path(data_dir, "ESACfoia.zip")

if (!file.exists(zip_path)) {
  cat("Downloading DOJ ESAC FOIA data...\n")
  download.file(esac_url, zip_path, mode = "wb", quiet = FALSE)
  stopifnot("Download failed: zip file missing" = file.exists(zip_path))
  cat(sprintf("Downloaded: %s (%.1f MB)\n", zip_path, file.size(zip_path) / 1e6))
} else {
  cat("ESAC zip already downloaded.\n")
}

## ---------- Extract ----------
extract_dir <- file.path(data_dir, "esac_raw")
dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)
unzip(zip_path, exdir = extract_dir, overwrite = TRUE)

## ---------- Read pipe-delimited .txt files ----------
read_esac <- function(filename) {
  fread(file.path(extract_dir, filename), header = TRUE, quote = "\"")
}

# Core tables
cert <- read_esac("ACA_CERTIFICATION_T.txt")
income <- read_esac("ACA_INCOME_T.txt")
expense <- read_esac("ACA_EXPENSE_T.txt")
state_lu <- read_esac("STATE_L.txt")
income_typ <- read_esac("ACA_INCOME_TYP_L.txt")
expense_typ <- read_esac("ACA_EXPENSE_TYP_L.txt")
ncic <- read_esac("NCIC_CD_L.txt")
agcy_typ <- read_esac("AGCY_TYP_L.txt")

cat("Certifications:", nrow(cert), "\n")
cat("Income records:", nrow(income), "\n")
cat("Expense records:", nrow(expense), "\n")
cat("Unique NCIC codes:", n_distinct(ncic$OAG_NCIC_CD), "\n")

## ---------- Save parsed tables ----------
saveRDS(cert, file.path(data_dir, "cert.rds"))
saveRDS(income, file.path(data_dir, "income.rds"))
saveRDS(expense, file.path(data_dir, "expense.rds"))
saveRDS(state_lu, file.path(data_dir, "state_lu.rds"))
saveRDS(income_typ, file.path(data_dir, "income_typ.rds"))
saveRDS(ncic, file.path(data_dir, "ncic.rds"))

cat("\n=== Data fetch complete ===\n")
