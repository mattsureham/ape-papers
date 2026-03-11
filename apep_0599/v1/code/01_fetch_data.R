# ============================================================================
# 01_fetch_data.R — Data acquisition from Statistics Denmark StatBank API
# Denmark's 2013 Disability Pension Reform (apep_0599)
# ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# --- StatBank API helper ---
fetch_statbank <- function(table_id, variables, max_retries = 3,
                           use_bulk = FALSE) {
  url <- "https://api.statbank.dk/v1/data"
  body <- list(
    table = table_id,
    format = if (use_bulk) "BULK" else "CSV",
    lang = "en",
    variables = variables
  )

  for (attempt in 1:max_retries) {
    cat(sprintf("  Fetching %s (attempt %d/%d)...\n", table_id, attempt, max_retries))
    resp <- tryCatch({
      httr::POST(
        url,
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(300)
      )
    }, error = function(e) {
      cat(sprintf("  Network error: %s\n", e$message))
      NULL
    })

    if (!is.null(resp) && httr::status_code(resp) == 200) {
      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      dt <- fread(text = txt, sep = ";")
      cat(sprintf("  Success: %d rows, %d columns\n", nrow(dt), ncol(dt)))
      return(dt)
    }

    if (!is.null(resp)) {
      cat(sprintf("  HTTP %d: %s\n", httr::status_code(resp),
                  substr(httr::content(resp, as = "text"), 1, 300)))
    }
    Sys.sleep(2 * attempt)
  }

  stop(sprintf("FATAL: Failed to fetch %s after %d attempts. Cannot proceed.",
               table_id, max_retries))
}

# --- Age groups for analysis ---
age_groups <- c("25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59")

# All quarters 2007-2025
quarters <- paste0(rep(2007:2025, each = 4), "K", 1:4)
quarters <- quarters[quarters <= "2025K3"]

# ============================================================================
# 1. AUK01 — Public benefits by municipality, benefit type, sex, age, quarter
#    Split by benefit type to stay under 1M cell limit
# ============================================================================
cat("=== Fetching AUK01 (public benefits) ===\n")

benefit_types <- c("FP", "FL", "FY", "KH", "SY", "LY", "RES", "JA")
benefit_labels <- c("Disability Pension", "Flex jobs", "Flex allowance",
                    "Cash benefits (not ready)", "Sickness benefits",
                    "Unemployment benefits", "Resource scheme",
                    "Job clarification")

auk01_list <- list()
for (i in seq_along(benefit_types)) {
  cat(sprintf("\n--- %s (%s) ---\n", benefit_labels[i], benefit_types[i]))
  vars <- list(
    list(code = "OMRÅDE", values = list("*")),
    list(code = "YDELSESTYPE", values = list(benefit_types[i])),
    list(code = "KØN", values = list("TOT")),
    list(code = "ALDER", values = age_groups),
    list(code = "Tid", values = quarters)
  )
  dt <- fetch_statbank("AUK01", vars)
  dt[, benefit_code := benefit_types[i]]
  dt[, benefit_label := benefit_labels[i]]
  auk01_list[[i]] <- dt
  Sys.sleep(1)  # Rate limit courtesy
}

auk01 <- rbindlist(auk01_list)
fwrite(auk01, file.path(DATA_DIR, "auk01_raw.csv"))
cat(sprintf("\nAUK01 combined: %d rows\n", nrow(auk01)))

# ============================================================================
# 1b. AUK01 by sex — for heterogeneity analysis
# ============================================================================
cat("\n=== Fetching AUK01 by sex ===\n")

key_benefits <- c("FP", "FL")
auk01_sex_list <- list()
idx <- 1
for (bt in key_benefits) {
  for (sex in c("M", "K")) {
    cat(sprintf("\n--- %s / %s ---\n", bt, sex))
    vars <- list(
      list(code = "OMRÅDE", values = list("*")),
      list(code = "YDELSESTYPE", values = list(bt)),
      list(code = "KØN", values = list(sex)),
      list(code = "ALDER", values = age_groups),
      list(code = "Tid", values = quarters)
    )
    dt <- fetch_statbank("AUK01", vars)
    dt[, benefit_code := bt]
    dt[, sex_code := sex]
    auk01_sex_list[[idx]] <- dt
    idx <- idx + 1
    Sys.sleep(1)
  }
}
auk01_sex <- rbindlist(auk01_sex_list)
fwrite(auk01_sex, file.path(DATA_DIR, "auk01_sex_raw.csv"))

# ============================================================================
# 2. FOLK1C — Population by municipality, age, sex, quarter
# ============================================================================
cat("\n=== Fetching FOLK1C (population) ===\n")

pop_quarters <- paste0(rep(2008:2025, each = 4), "K", 1:4)
pop_quarters <- pop_quarters[pop_quarters <= "2025K3"]

folk1c_vars <- list(
  list(code = "OMRÅDE", values = list("*")),
  list(code = "KØN", values = list("TOT")),
  list(code = "ALDER", values = age_groups),
  list(code = "HERKOMST", values = list("TOT")),
  list(code = "Tid", values = pop_quarters)
)

folk1c <- fetch_statbank("FOLK1C", folk1c_vars)
fwrite(folk1c, file.path(DATA_DIR, "folk1c_raw.csv"))

# ============================================================================
# 3. RAS200 — Employment rate by municipality, age, year
# ============================================================================
cat("\n=== Fetching RAS200 (employment rate) ===\n")

ras_years <- as.character(2008:2024)

ras200_vars <- list(
  list(code = "OMRÅDE", values = list("*")),
  list(code = "HERKOMST", values = list("00")),
  list(code = "ALDER", values = age_groups),
  list(code = "KØN", values = list("TOT")),
  list(code = "BEREGNING", values = list("BFK")),  # Employment rate
  list(code = "Tid", values = ras_years)
)

ras200 <- fetch_statbank("RAS200", ras200_vars)
fwrite(ras200, file.path(DATA_DIR, "ras200_raw.csv"))

# ============================================================================
# 4. INDKP111 — Income by region, age, year
# ============================================================================
cat("\n=== Fetching INDKP111 (income) ===\n")

inc_years <- as.character(2007:2024)

indkp111_vars <- list(
  list(code = "REGLAND", values = list("*")),
  list(code = "ENHED", values = list("116")),
  list(code = "KOEN", values = list("MOK")),
  list(code = "ALDER1", values = age_groups),
  list(code = "INDKOMSTTYPE", values = list("100", "110")),
  list(code = "Tid", values = inc_years)
)

indkp111 <- fetch_statbank("INDKP111", indkp111_vars)
fwrite(indkp111, file.path(DATA_DIR, "indkp111_raw.csv"))

# ============================================================================
# DATA VALIDATION
# ============================================================================
cat("\n=== Data Validation ===\n")

stopifnot("AUK01 has > 5000 rows" = nrow(auk01) > 5000)
stopifnot("AUK01 has FP benefit type" = "FP" %in% auk01$benefit_code)
stopifnot("AUK01 has FL benefit type" = "FL" %in% auk01$benefit_code)
n_muni_auk <- length(unique(auk01[[1]]))
stopifnot("AUK01 has 90+ municipalities" = n_muni_auk >= 90)

stopifnot("FOLK1C has data" = nrow(folk1c) > 500)
stopifnot("RAS200 has data" = nrow(ras200) > 100)
stopifnot("INDKP111 has data" = nrow(indkp111) > 50)

cat(sprintf("\nAll data fetched and validated:\n"))
cat(sprintf("  AUK01 (benefits):    %d rows, %d municipalities\n", nrow(auk01), n_muni_auk))
cat(sprintf("  AUK01 (by sex):      %d rows\n", nrow(auk01_sex)))
cat(sprintf("  FOLK1C (population): %d rows\n", nrow(folk1c)))
cat(sprintf("  RAS200 (employment): %d rows\n", nrow(ras200)))
cat(sprintf("  INDKP111 (income):   %d rows\n", nrow(indkp111)))
cat("\nData fetch complete.\n")
