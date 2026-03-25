## 01_fetch_data.R — Fetch data from DST StatBank API + construct designation list
## Denmark Parallel Society Designation and Displacement (apep_0940)

library(httr)
library(jsonlite)
library(data.table)

cat("=== Fetching data for apep_0940 ===\n")

# -------------------------------------------------------------------
# 1. DST StatBank API helper
# -------------------------------------------------------------------
fetch_dst <- function(table_id, variables, lang = "en") {
  url <- "https://api.statbank.dk/v1/data"
  body <- list(
    table = table_id,
    format = "CSV",
    lang = lang,
    variables = variables
  )
  resp <- POST(url, body = toJSON(body, auto_unbox = TRUE),
               content_type_json(), timeout(120))
  if (status_code(resp) != 200) {
    stop(paste("DST API error for", table_id, ":", status_code(resp),
               content(resp, "text")))
  }
  txt <- content(resp, "text", encoding = "UTF-8")
  dt <- fread(text = txt, sep = ";")
  cat(sprintf("  %s: %d rows fetched\n", table_id, nrow(dt)))
  return(dt)
}

# -------------------------------------------------------------------
# 2. Fetch FOLK1E: Population by municipality x ancestry (W/NW) x quarter
# -------------------------------------------------------------------
cat("\nFetching FOLK1E (population by ancestry, quarterly)...\n")

# Get all municipality codes first
resp_info <- GET("https://api.statbank.dk/v1/tableinfo/FOLK1E?lang=en")
mun_info <- fromJSON(content(resp_info, "text", encoding = "UTF-8"))
# variables is a data.frame; values is a list column of data.frames
omraade_vals <- mun_info$variables$values[[1]]  # first variable = OMRÅDE
mun_codes <- omraade_vals$id[nchar(omraade_vals$id) == 3]  # 3-digit = municipalities
cat(sprintf("  Found %d municipalities\n", length(mun_codes)))

# Get all time periods (5th variable = Tid)
time_idx <- which(mun_info$variables$id == "Tid")
time_vals <- mun_info$variables$values[[time_idx]]
q1_times <- time_vals$id[grepl("K1$", time_vals$id)]  # Q1 only (annual snapshot)
cat(sprintf("  Using %d Q1 time points: %s to %s\n",
            length(q1_times), q1_times[1], q1_times[length(q1_times)]))

folk1e <- fetch_dst("FOLK1E", list(
  list(code = "OMRÅDE", values = mun_codes),
  list(code = "KØN", values = list("TOT")),
  list(code = "ALDER", values = list("IALT")),
  list(code = "HERKOMST", values = list("TOT", "1", "25", "35")),
  list(code = "Tid", values = q1_times)
))

stopifnot(nrow(folk1e) > 0)
cat(sprintf("  FOLK1E: %d rows, %d municipalities, %d time periods\n",
            nrow(folk1e), length(unique(folk1e[[1]])), length(unique(folk1e[[6]]))))

# -------------------------------------------------------------------
# 3. Fetch RAS200: Employment rate by municipality x ancestry x year
# -------------------------------------------------------------------
cat("\nFetching RAS200 (employment rate by ancestry)...\n")

resp_ras <- GET("https://api.statbank.dk/v1/tableinfo/RAS200?lang=en")
ras_info <- fromJSON(content(resp_ras, "text", encoding = "UTF-8"))
ras_time_idx <- which(ras_info$variables$id == "Tid")
ras_time <- ras_info$variables$values[[ras_time_idx]]$id
cat(sprintf("  Available years: %s to %s\n", ras_time[1], ras_time[length(ras_time)]))

ras200 <- fetch_dst("RAS200", list(
  list(code = "OMRÅDE", values = mun_codes),
  list(code = "HERKOMST", values = list("00", "10", "25", "35")),
  list(code = "ALDER", values = list("16-64")),
  list(code = "KØN", values = list("TOT")),
  list(code = "BEREGNING", values = list("BFK")),
  list(code = "Tid", values = ras_time)
))

stopifnot(nrow(ras200) > 0)
cat(sprintf("  RAS200: %d rows\n", nrow(ras200)))

# -------------------------------------------------------------------
# 4. Construct designation list (2018 Ghetto Package)
# -------------------------------------------------------------------
cat("\nConstructing designation list...\n")

# 29 estates designated as "ghettos" (parallel societies) on Dec 1, 2018
# Source: Danish Transport, Building and Housing Authority annual list;
#         Copenhagen Post (Dec 2018); The Local DK; Wikipedia
# Municipality codes from DST StatBank FOLK1E
designation_2018 <- data.table(
  estate = c(
    "Mjølnerparken", "Gadelandet/Husumgård", "Tingbjerg/Utterslevhuse",
    "Bispeparken", "Hørgården", "Lundtoftegade", "Aldersrogade",
    "Tåstrupgård", "Charlotteager", "Gadehavegård",
    "Nøjsomhed/Sydvej",
    "Agervang",
    "Ringparken", "Motalavej",
    "Lindholm",
    "Solbakken mv.", "Korsløkkeparken Øst", "Vollsmose",
    "Nørager/Søstjernevej",
    "Stengårdsvej",
    "Sundparken",
    "Munkebo", "Skovvejen/Skovparken",
    "Finlandsparken",
    "Resedavej/Nørrevang II",
    "Bispehaven", "Skovgårdsparken", "Gellerupparken/Toveshøj",
    "Ellekonebakken"
  ),
  mun_code = c(
    "101", "101", "101", "101", "101", "101", "101",
    "169", "169", "169",
    "217",
    "316",
    "330", "330",
    "376",
    "461", "461", "461",
    "540",
    "561",
    "615",
    "621", "621",
    "630",
    "740",
    "751", "751", "751",
    "791"
  ),
  municipality = c(
    rep("Copenhagen", 7),
    rep("Høje-Taastrup", 3),
    "Helsingør",
    "Holbæk",
    rep("Slagelse", 2),
    "Guldborgsund",
    rep("Odense", 3),
    "Sønderborg",
    "Esbjerg",
    "Horsens",
    rep("Kolding", 2),
    "Vejle",
    "Silkeborg",
    rep("Aarhus", 3),
    "Viborg"
  )
)

cat(sprintf("  %d estates across %d municipalities designated in 2018\n",
            nrow(designation_2018), uniqueN(designation_2018$mun_code)))

# Municipality-level treatment: number of designated estates
mun_treatment <- designation_2018[, .(n_estates = .N), by = mun_code]
cat("\nTreatment intensity by municipality:\n")
print(mun_treatment[order(-n_estates)])

# -------------------------------------------------------------------
# 5. Save raw data
# -------------------------------------------------------------------
fwrite(folk1e, "data/folk1e_raw.csv")
fwrite(ras200, "data/ras200_raw.csv")
fwrite(designation_2018, "data/designation_2018.csv")
fwrite(mun_treatment, "data/mun_treatment.csv")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("  FOLK1E: %d rows saved\n", nrow(folk1e)))
cat(sprintf("  RAS200: %d rows saved\n", nrow(ras200)))
cat(sprintf("  Designation list: %d estates, %d municipalities\n",
            nrow(designation_2018), uniqueN(designation_2018$mun_code)))
