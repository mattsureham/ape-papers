# 01_fetch_data.R — Download and parse DOJ ESAC FOIA data
# APEP Working Paper apep_0917
# Source: DOJ Asset Forfeiture Program, Equitable Sharing Annual Certification FOIA
# URL: https://www.justice.gov/afp/dl/ESACfoia.zip

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

zip_path <- file.path(data_dir, "ESACfoia.zip")
extract_dir <- file.path(data_dir, "esac_raw")

# ---------- Download ----------
if (!file.exists(zip_path)) {
  cat("Downloading ESAC FOIA data from DOJ...\n")
  download.file(
    url = "https://www.justice.gov/afp/dl/ESACfoia.zip",
    destfile = zip_path, mode = "wb", quiet = FALSE
  )
}
stopifnot("Download failed" = file.exists(zip_path) && file.size(zip_path) > 1e6)
cat("ESAC FOIA zip:", file.size(zip_path), "bytes\n")

# ---------- Extract ----------
if (!dir.exists(extract_dir)) {
  unzip(zip_path, exdir = extract_dir, overwrite = TRUE)
}

# ---------- Read relational tables ----------
read_esac <- function(fname) {
  fp <- file.path(extract_dir, fname)
  # Files are CSV with quoted headers and +prefixed numbers
  dt <- fread(fp, header = TRUE, strip.white = TRUE)
  # Fix +prefixed numeric columns
  for (col in names(dt)) {
    if (is.character(dt[[col]])) {
      vals <- dt[[col]]
      # Check if this looks like a +prefixed number
      if (sum(grepl("^\\+[0-9]", vals), na.rm = TRUE) > nrow(dt) * 0.3) {
        dt[[col]] <- as.numeric(sub("^\\+", "", vals))
      }
    }
  }
  dt
}

cat("Reading certification table...\n")
cert <- read_esac("ACA_CERTIFICATION_T.txt")
cat("  Certifications:", nrow(cert), "rows\n")

cat("Reading income table...\n")
income <- read_esac("ACA_INCOME_T.txt")
cat("  Income records:", nrow(income), "rows\n")

cat("Reading income type lookup...\n")
income_typ <- read_esac("ACA_INCOME_TYP_L.txt")
cat("  Income types:\n")
print(income_typ)

cat("Reading agency lookup...\n")
ncic <- read_esac("NCIC_CD_L.txt")
cat("  Agencies:", nrow(ncic), "rows\n")

# ---------- Parse key variables ----------
# Certification: CERT_ID, NCIC_CD (agency), NCIC_ST (state), FORM_FY (fiscal year)
cert[, NCIC_CD := trimws(NCIC_CD)]
cert[, NCIC_ST := trimws(NCIC_ST)]
cert[, FORM_FY := as.integer(FORM_FY)]

cat("\nFiscal year range:", range(cert$FORM_FY, na.rm=TRUE), "\n")
cat("States:", length(unique(cert$NCIC_ST)), "\n")
cat("Agencies:", length(unique(cert$NCIC_CD)), "\n")
cat("FY distribution:\n")
print(table(cert$FORM_FY))

# ---------- Build income by certification ----------
# Income types: 01=ES Funds Received, 02=ES from other agencies, 03=Other,
#               04=Interest, 05=Sale Proceeds, 06=Reimbursements, 07=Adjustment
income[, JUSTICE_AMT := ifelse(is.na(JUSTICE_AMT), 0, JUSTICE_AMT)]
income[, TREASURY_AMT := ifelse(is.na(TREASURY_AMT), 0, TREASURY_AMT)]
income[, TOTAL_AMT := JUSTICE_AMT + TREASURY_AMT]

# Aggregate income by certification and type
income_wide <- income[, .(total = sum(TOTAL_AMT, na.rm=TRUE)),
                       by = .(CERT_ID, INCOME_TYP_CD)]
income_wide <- dcast(income_wide, CERT_ID ~ INCOME_TYP_CD,
                     value.var = "total", fill = 0)
# Rename columns
type_names <- c("1" = "es_funds_received", "2" = "es_funds_other_agency",
                "3" = "other_income", "4" = "interest_income",
                "5" = "sale_proceeds", "6" = "reimbursements",
                "7" = "adjustment")
for (old in names(type_names)) {
  if (old %in% names(income_wide)) {
    setnames(income_wide, old, type_names[old])
  }
}

# Total equitable sharing revenue = ES funds received + ES from other agencies
if (!"es_funds_other_agency" %in% names(income_wide))
  income_wide[, es_funds_other_agency := 0]
income_wide[, es_total_revenue := es_funds_received + es_funds_other_agency]

# Also compute total income across all types
income_cols <- intersect(names(income_wide),
                         c("es_funds_received", "es_funds_other_agency",
                           "other_income", "interest_income", "sale_proceeds",
                           "reimbursements", "adjustment"))
income_wide[, total_all_income := rowSums(.SD, na.rm=TRUE), .SDcols = income_cols]

# ---------- Merge certification + income ----------
panel <- merge(cert[, .(CERT_ID, NCIC_CD, NCIC_ST, FORM_FY, NCIC_CTY,
                         ESAC_STATUS_CD,
                         JUSTICE_CURR_FY_END_BAL, TREASURY_CURR_FY_END_BAL)],
               income_wide,
               by = "CERT_ID", all.x = TRUE)

# Fill missing income with 0
for (col in c("es_funds_received", "es_total_revenue", "total_all_income",
              "interest_income", "sale_proceeds")) {
  if (col %in% names(panel)) {
    set(panel, which(is.na(panel[[col]])), col, 0)
  }
}

cat("\n=== MERGED PANEL ===\n")
cat("Rows:", nrow(panel), "\n")
cat("Unique agencies:", length(unique(panel$NCIC_CD)), "\n")
cat("Unique states:", length(unique(panel$NCIC_ST)), "\n")
cat("FY range:", range(panel$FORM_FY, na.rm=TRUE), "\n")
cat("\nRevenue summary:\n")
print(summary(panel$es_total_revenue))

# ---------- Keep US states only (drop territories, military, etc.) ----------
us_states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
               "HI","ID","IL","IN","IA","KS","KY","LA","MA","MD",
               "ME","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
               "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
               "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY",
               "DC")
panel <- panel[NCIC_ST %in% us_states]
cat("\nAfter US states filter:", nrow(panel), "rows,",
    length(unique(panel$NCIC_CD)), "agencies\n")

# ---------- Validate ----------
stopifnot("Too few records" = nrow(panel) > 10000)
stopifnot("Too few agencies" = length(unique(panel$NCIC_CD)) > 1000)
stopifnot("Missing fiscal years" = all(!is.na(panel$FORM_FY)))

# ---------- Save ----------
saveRDS(panel, file.path(data_dir, "esac_panel_raw.rds"))
cat("\nSaved", nrow(panel), "rows to esac_panel_raw.rds\n")
cat("FETCH COMPLETE\n")
