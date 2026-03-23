## 01b_explore_data.R — Explore what data is available for Romania bunching
source("00_packages.R")

# ---- 1. Check what turnover indicators we have in the SBS data ----
sbs <- readRDS("../data/sbs_raw.rds")

# Focus on Romania
ro <- sbs[sbs$geo == "RO", ]
cat("Romania data: ", nrow(ro), " rows\n")
cat("Years: ", paste(sort(unique(ro$TIME_PERIOD)), collapse = ", "), "\n")
cat("Size classes: ", paste(sort(unique(ro$size_emp)), collapse = ", "), "\n")
cat("\nIndicators:\n")
print(sort(unique(ro$indic_sb)))

# Key indicators:
# V11110 = Number of enterprises
# V12110 = Turnover or gross premiums written
# V12120 = Production value
# V12150 = Value added at factor cost
# V13110 = Total purchases of goods and services
# V16110 = Gross investment in tangible goods
# V91110 = Number of persons employed

# ---- 2. Extract enterprise counts and turnover by size class ----
# Number of enterprises by employee size class for Romania
ro_ent <- ro %>%
  filter(indic_sb == "V11110") %>%
  select(nace_r2, size_emp, year = TIME_PERIOD, enterprises = values)

cat("\n=== Enterprise counts (all sectors) by size class ===\n")
ro_ent %>%
  filter(nace_r2 == "B-S_X_K642") %>%  # Total business economy
  arrange(year, size_emp) %>%
  print(n = 100)

# Turnover by size class
ro_turn <- ro %>%
  filter(indic_sb == "V12110") %>%
  select(nace_r2, size_emp, year = TIME_PERIOD, turnover = values)

cat("\n=== Turnover by size class (total business economy) ===\n")
ro_turn %>%
  filter(nace_r2 == "B-S_X_K642") %>%
  arrange(year, size_emp) %>%
  print(n = 100)

# ---- 3. Compute average turnover per enterprise ----
ro_avg <- ro_ent %>%
  inner_join(ro_turn, by = c("nace_r2", "size_emp", "year")) %>%
  mutate(avg_turnover = turnover / enterprises) %>%
  filter(nace_r2 == "B-S_X_K642")

cat("\n=== Average turnover per enterprise (thousands EUR) ===\n")
ro_avg %>%
  select(size_emp, year, enterprises, turnover, avg_turnover) %>%
  arrange(size_emp, year) %>%
  print(n = 100)

# ---- 4. Try to find Eurostat datasets with TURNOVER size classes ----
cat("\n=== Searching for turnover-based size class datasets ===\n")

# Check available SBS datasets
datasets_to_try <- c(
  "sbs_sc_ovw",      # SBS overview
  "sbs_na_1a_se_r2", # SBS national level
  "sbs_sc_con_r2",   # SBS construction
  "sbs_sc_dt_r2",    # SBS trade
  "tin00145",        # SME indicators
  "sbs_sc_sca_r2"    # Already have this one
)

for (ds in datasets_to_try[1:4]) {
  cat("\nTrying dataset:", ds, "...\n")
  tryCatch({
    tmp <- get_eurostat(ds, time_format = "num",
                        filters = list(geo = "RO"))
    cat("  Success:", nrow(tmp), "rows\n")
    cat("  Variables:", paste(names(tmp), collapse = ", "), "\n")
    for (v in names(tmp)) {
      uv <- unique(tmp[[v]])
      if (length(uv) < 30) {
        cat("  ", v, ":", paste(head(uv, 15), collapse = ", "), "\n")
      }
    }
  }, error = function(e) {
    cat("  Failed:", e$message, "\n")
  })
}

# ---- 5. Also check the second SBS dataset we fetched ----
if (file.exists("../data/sbs_emp_raw.rds")) {
  sbs2 <- readRDS("../data/sbs_emp_raw.rds")
  cat("\n=== Second SBS dataset dimensions ===\n")
  cat("Variables:", paste(names(sbs2), collapse = ", "), "\n")
  for (v in names(sbs2)) {
    uv <- unique(sbs2[[v]])
    if (length(uv) < 50) {
      cat(v, ":", length(uv), "values:", paste(head(uv, 20), collapse = ", "), "\n")
    }
  }
}

# ---- 6. Check business demography for size class info ----
if (file.exists("../data/bd_raw.rds")) {
  bd <- readRDS("../data/bd_raw.rds")
  cat("\n=== Business demography dimensions ===\n")
  cat("Variables:", paste(names(bd), collapse = ", "), "\n")
  for (v in names(bd)) {
    uv <- unique(bd[[v]])
    if (length(uv) < 50) {
      cat(v, ":", length(uv), "values:", paste(head(uv, 20), collapse = ", "), "\n")
    }
  }

  # Check Romania birth/death data
  bd_ro <- bd %>%
    filter(geo == "RO") %>%
    filter(grepl("V1111|V1112|V9711|BIRTH|DEATH", indic_sb, ignore.case = TRUE))

  cat("\nRomania business demography indicators:\n")
  print(unique(bd_ro$indic_sb))
}
