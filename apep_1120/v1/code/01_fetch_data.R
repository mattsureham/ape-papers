# apep_1120 - Romanian 2014 EU-2 Restriction Lifting
# 01_fetch_data.R - Fetch data from Eurostat and INSSE

source("code/00_packages.R")

# Additional packages for data access
if (!requireNamespace("eurostat", quietly = TRUE)) install.packages("eurostat")
library(eurostat)

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

# ============================================================
# INSSE TEMPO helper: download via Python subprocess
# The R httr package fails due to SSL; Python works on HTTP
# ============================================================
fetch_insse_via_python <- function(matrix_id, output_file) {
  py_script <- sprintf('
import requests, json, csv, sys

url = "http://statistici.insse.ro:8077/tempo-ins/matrix/%s"
r = requests.get(url, timeout=60)
meta = r.json()
dims = meta["dimensionsMap"]

# Extract dimension labels
rows = []
for i, dim in enumerate(dims):
    for opt in dim["options"]:
        rows.append({
            "dim_id": i,
            "dim_label": "",
            "item_id": opt["nomItemId"],
            "item_label": opt["label"],
            "offset": opt["offset"]
        })

with open("%s", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["dim_id","dim_label","item_id","item_label","offset"])
    w.writeheader()
    w.writerows(rows)

print(f"Saved {len(rows)} dimension items to %s")
', matrix_id, output_file, output_file)

  system2("python3", args = c("-c", shQuote(py_script)), stdout = TRUE, stderr = TRUE)
}

# ============================================================
# 1. Eurostat: NUTS3 GDP per capita for Romania (nama_10r_3gdp)
# ============================================================
cat("1. Fetching Eurostat NUTS3 GDP per capita...\n")

tryCatch({
  gdp_nuts3 <- get_eurostat("nama_10r_3gdp",
                             filters = list(geo = "RO",  # Romania
                                          unit = "MIO_EUR"),
                             time_format = "num")
  # Filter to Romanian NUTS3 regions (RO111-RO424 pattern)
  gdp_ro <- gdp_nuts3[grepl("^RO[0-9]{3}", gdp_nuts3$geo), ]
  cat(sprintf("  GDP NUTS3: %d rows, %d regions, %d years\n",
              nrow(gdp_ro), length(unique(gdp_ro$geo)), length(unique(gdp_ro$time))))
  saveRDS(gdp_ro, file.path(data_dir, "eurostat_gdp_nuts3.rds"))
}, error = function(e) {
  cat(sprintf("  GDP fetch failed: %s\n", e$message))
  cat("  Trying alternative download...\n")
  # Fallback: download bulk TSV
  tryCatch({
    gdp_nuts3 <- get_eurostat("nama_10r_3gdp", time_format = "num")
    gdp_ro <- gdp_nuts3[grepl("^RO", gdp_nuts3$geo), ]
    saveRDS(gdp_ro, file.path(data_dir, "eurostat_gdp_nuts3.rds"))
    cat(sprintf("  Fallback: %d rows\n", nrow(gdp_ro)))
  }, error = function(e2) {
    cat(sprintf("  Fallback also failed: %s\n", e2$message))
  })
})

# ============================================================
# 2. Eurostat: NUTS3 employment (lfst_r_lfe2emp)
# ============================================================
cat("\n2. Fetching Eurostat NUTS3 employment...\n")

tryCatch({
  emp_nuts3 <- get_eurostat("lfst_r_lfe2emp",
                             filters = list(geo = "RO",
                                          sex = "T",       # Total
                                          age = "Y15-64"), # Working age
                             time_format = "num")
  emp_ro <- emp_nuts3[grepl("^RO[0-9]{3}", emp_nuts3$geo), ]
  cat(sprintf("  Employment NUTS3: %d rows, %d regions\n",
              nrow(emp_ro), length(unique(emp_ro$geo))))
  saveRDS(emp_ro, file.path(data_dir, "eurostat_emp_nuts3.rds"))
}, error = function(e) {
  cat(sprintf("  Employment fetch failed: %s\n", e$message))
  tryCatch({
    emp_nuts3 <- get_eurostat("lfst_r_lfe2emp", time_format = "num")
    emp_ro <- emp_nuts3[grepl("^RO", emp_nuts3$geo), ]
    saveRDS(emp_ro, file.path(data_dir, "eurostat_emp_nuts3.rds"))
    cat(sprintf("  Fallback: %d rows\n", nrow(emp_ro)))
  }, error = function(e2) {
    cat(sprintf("  Fallback failed: %s\n", e2$message))
  })
})

# ============================================================
# 3. Eurostat: NUTS3 population (demo_r_pjanaggr3)
# ============================================================
cat("\n3. Fetching Eurostat NUTS3 population...\n")

tryCatch({
  pop_nuts3 <- get_eurostat("demo_r_pjanaggr3",
                             filters = list(geo = "RO",
                                          sex = "T",
                                          age = "TOTAL"),
                             time_format = "num")
  pop_ro <- pop_nuts3[grepl("^RO[0-9]{3}", pop_nuts3$geo), ]
  cat(sprintf("  Population NUTS3: %d rows, %d regions\n",
              nrow(pop_ro), length(unique(pop_ro$geo))))
  saveRDS(pop_ro, file.path(data_dir, "eurostat_pop_nuts3.rds"))
}, error = function(e) {
  cat(sprintf("  Population fetch failed: %s\n", e$message))
  tryCatch({
    pop_nuts3 <- get_eurostat("demo_r_pjanaggr3", time_format = "num")
    pop_ro <- pop_nuts3[grepl("^RO", pop_nuts3$geo), ]
    saveRDS(pop_ro, file.path(data_dir, "eurostat_pop_nuts3.rds"))
    cat(sprintf("  Fallback: %d rows\n", nrow(pop_ro)))
  }, error = function(e2) {
    cat(sprintf("  Fallback failed: %s\n", e2$message))
  })
})

# ============================================================
# 4. Eurostat: Romania->Germany immigration (migr_imm1ctz)
# National aggregate for first-stage validation
# ============================================================
cat("\n4. Fetching Eurostat RO→DE immigration...\n")

tryCatch({
  imm <- get_eurostat("migr_imm1ctz",
                       filters = list(citizen = "RO",
                                    geo = "DE",
                                    sex = "T",
                                    age = "TOTAL"),
                       time_format = "num")
  cat(sprintf("  RO→DE immigration: %d rows, years %d-%d\n",
              nrow(imm), min(imm$time), max(imm$time)))
  cat("  Values:\n")
  imm_sorted <- imm[order(imm$time), ]
  for (i in 1:nrow(imm_sorted)) {
    cat(sprintf("    %d: %s\n", imm_sorted$time[i], format(imm_sorted$values[i], big.mark = ",")))
  }
  saveRDS(imm, file.path(data_dir, "eurostat_ro_de_immigration.rds"))
}, error = function(e) {
  cat(sprintf("  Immigration fetch failed: %s\n", e$message))
})

# ============================================================
# 5. Eurostat: Romania total emigration (migr_emi1ctz)
# ============================================================
cat("\n5. Fetching Eurostat RO emigration by destination...\n")

tryCatch({
  emi <- get_eurostat("migr_emi1ctz",
                       filters = list(citizen = "RO",
                                    sex = "T",
                                    age = "TOTAL"),
                       time_format = "num")
  emi_filtered <- emi[emi$geo %in% c("DE", "IT", "ES", "FR", "AT", "UK", "HU"), ]
  cat(sprintf("  RO emigration to key destinations: %d rows\n", nrow(emi_filtered)))
  saveRDS(emi_filtered, file.path(data_dir, "eurostat_ro_emigration.rds"))
}, error = function(e) {
  cat(sprintf("  Emigration fetch failed: %s\n", e$message))
})

# ============================================================
# 6. Eurostat: NUTS2 earnings / compensation (earn_ses18_42)
# Romania has 8 NUTS2 regions — coarser than 42 counties
# ============================================================
cat("\n6. Fetching Eurostat NUTS2 earnings...\n")

tryCatch({
  earn <- get_eurostat("earn_ses18_42", time_format = "num")
  earn_ro <- earn[grepl("^RO", earn$geo), ]
  if (nrow(earn_ro) > 0) {
    cat(sprintf("  Earnings NUTS2: %d rows, regions: %s\n",
                nrow(earn_ro), paste(unique(earn_ro$geo), collapse = ", ")))
    saveRDS(earn_ro, file.path(data_dir, "eurostat_earn_nuts2.rds"))
  } else {
    cat("  No Romanian earnings data found\n")
  }
}, error = function(e) {
  cat(sprintf("  Earnings fetch failed: %s\n", e$message))
})

# ============================================================
# 7. INSSE TEMPO metadata (dimension maps for manual construction)
# ============================================================
cat("\n7. Fetching INSSE dimension metadata...\n")

for (matrix in c("FOM106E", "POP309A", "POP309D", "FOM105G")) {
  outfile <- file.path(data_dir, paste0("insse_", tolower(matrix), "_dims.csv"))
  cat(sprintf("  %s → %s\n", matrix, outfile))
  fetch_insse_via_python(matrix, outfile)
}

# ============================================================
# 8. Eurostat: NUTS3 compensation of employees (nama_10r_3empers)
# ============================================================
cat("\n8. Fetching Eurostat NUTS3 employment by sector...\n")

tryCatch({
  empsec <- get_eurostat("nama_10r_3empers", time_format = "num")
  empsec_ro <- empsec[grepl("^RO[0-9]{3}", empsec$geo), ]
  cat(sprintf("  Employment by sector NUTS3: %d rows, %d regions\n",
              nrow(empsec_ro), length(unique(empsec_ro$geo))))
  if (nrow(empsec_ro) > 0) {
    saveRDS(empsec_ro, file.path(data_dir, "eurostat_empsec_nuts3.rds"))
  }
}, error = function(e) {
  cat(sprintf("  Employment by sector failed: %s\n", e$message))
})

# ============================================================
# Summary
# ============================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
files <- list.files(data_dir, pattern = "\\.(rds|csv|json)$")
for (f in files) {
  size <- file.size(file.path(data_dir, f))
  cat(sprintf("  %s: %.1f KB\n", f, size / 1024))
}
cat("=========================\n")
