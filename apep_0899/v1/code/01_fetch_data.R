## 01_fetch_data.R — Fetch data from Statistics Finland PxWeb API
## apep_0899: Finland compulsory education extension

source("00_packages.R")

BASE_URL <- "https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin"

## Helper: fetch PxWeb data via POST
fetch_pxweb <- function(table_path, query_items) {
  url <- paste0(BASE_URL, "/", table_path)
  cat("Fetching:", url, "\n")

  body <- toJSON(list(query = query_items, response = list(format = "json-stat2")),
                 auto_unbox = TRUE)

  resp <- POST(url, body = body, encode = "raw",
               content_type_json(), timeout(120))

  if (status_code(resp) != 200) {
    stop(sprintf("API returned %d for %s: %s",
                 status_code(resp), table_path,
                 substr(content(resp, "text", encoding = "UTF-8"), 1, 500)))
  }

  fromJSON(content(resp, "text", encoding = "UTF-8"))
}

## Helper: JSON-stat2 to tibble
parse_js2 <- function(js) {
  dim_ids <- js$id
  dim_labels <- lapply(dim_ids, function(d) {
    cats <- js$dimension[[d]]$category
    idx <- unlist(cats$index)
    lbls <- unlist(cats$label)
    lbls[order(idx)]
  })
  names(dim_labels) <- dim_ids

  grid <- expand.grid(rev(dim_labels), stringsAsFactors = FALSE)
  grid <- grid[, rev(names(grid))]

  vals <- js$value
  if (is.list(vals)) vals <- sapply(vals, function(x) if (is.null(x)) NA_real_ else as.numeric(x))

  stopifnot(length(vals) == nrow(grid))
  grid$value <- vals
  as_tibble(grid)
}

## ============================================================
## Dataset 1: School-to-work transitions by region
## Table: sijk/statfin_sijk_pxt_111l.px
## Dims: Year(18) x EduLevel(14) x Gender(3) x Region(21) x Field(13) x Info(26)
## ============================================================
cat("\n=== Dataset 1: School-to-work transitions ===\n")

meta1 <- fromJSON(content(
  GET(paste0(BASE_URL, "/sijk/statfin_sijk_pxt_111l.px"), timeout(60)),
  "text", encoding = "UTF-8"
))

all_years <- as.list(meta1$variables$values[[1]])
all_regions <- as.list(meta1$variables$values[[4]])

# Key education levels
edu_sel <- list("31", "32")  # General upper secondary, Vocational upper secondary

# Key outcomes — split into two batches to stay under API cell limit
outcomes_pct <- list(
  "tutkinto1vaiemmin",              # Total completers (number)
  "tyollinen1vpaastayhtosuus",      # Employed total %
  "tyollinen1vpaastaosuus",         # Full-time employed %
  "opiskelija1vpaastaosuus",        # Full-time students %
  "tyoton1vpaastaosuus"             # Unemployed %
)

outcomes_num <- list(
  "tyollinen1vpaastayht",           # Employed total number
  "tyoton1vpaasta",                 # Unemployed number
  "opiskelija1vpaasta",             # Students number
  "tyollinenopiskelija1vpaastaosuus", # Employed students %
  "muu1vpaastaosuus"                # Other %
)

make_q1 <- function(outs) list(
  list(code = "Vuosi", selection = list(filter = "item", values = all_years)),
  list(code = "Koulutusaste", selection = list(filter = "item", values = edu_sel)),
  list(code = "Sukupuoli", selection = list(filter = "item", values = list("S"))),
  list(code = "Asuinmaakunta", selection = list(filter = "item", values = all_regions)),
  list(code = "Koulutusala", selection = list(filter = "item", values = list("SS"))),
  list(code = "Tiedot", selection = list(filter = "item", values = outs))
)

js1a <- fetch_pxweb("sijk/statfin_sijk_pxt_111l.px", make_q1(outcomes_pct))
df1a <- parse_js2(js1a)

js1b <- fetch_pxweb("sijk/statfin_sijk_pxt_111l.px", make_q1(outcomes_num))
df1b <- parse_js2(js1b)

df1 <- bind_rows(df1a, df1b)
cat("Transitions:", nrow(df1), "rows,", sum(!is.na(df1$value)), "non-NA\n")
write_csv(df1, "../data/transitions_raw.csv")

## ============================================================
## Dataset 2: Discontinuation by region
## Table: kkesk/statfin_kkesk_pxt_14pi.px
## ============================================================
cat("\n=== Dataset 2: Discontinuation by region ===\n")

meta2 <- fromJSON(content(
  GET(paste0(BASE_URL, "/kkesk/statfin_kkesk_pxt_14pi.px"), timeout(60)),
  "text", encoding = "UTF-8"
))

cat("Dims:\n")
for (i in 1:nrow(meta2$variables)) {
  cat(sprintf("  %s: %d vals\n", meta2$variables$text[i], length(meta2$variables$values[[i]])))
}

all_years2 <- as.list(meta2$variables$values[[1]])
all_regions2 <- as.list(meta2$variables$values[[2]])
all_edu2 <- as.list(meta2$variables$values[[3]])
all_info2 <- as.list(meta2$variables$values[[4]])

query2 <- list(
  list(code = meta2$variables$code[1], selection = list(filter = "item", values = all_years2)),
  list(code = meta2$variables$code[2], selection = list(filter = "item", values = all_regions2)),
  list(code = meta2$variables$code[3], selection = list(filter = "item", values = all_edu2)),
  list(code = meta2$variables$code[4], selection = list(filter = "item", values = all_info2))
)

js2 <- fetch_pxweb("kkesk/statfin_kkesk_pxt_14pi.px", query2)
df2 <- parse_js2(js2)
cat("Regional discontinuation:", nrow(df2), "rows,", sum(!is.na(df2$value)), "non-NA\n")
write_csv(df2, "../data/dropout_regional_raw.csv")

## ============================================================
## Dataset 3: Discontinuation nationally
## Table: kkesk/statfin_kkesk_pxt_14pn.px
## ============================================================
cat("\n=== Dataset 3: National discontinuation ===\n")

meta3 <- fromJSON(content(
  GET(paste0(BASE_URL, "/kkesk/statfin_kkesk_pxt_14pn.px"), timeout(60)),
  "text", encoding = "UTF-8"
))

cat("Dims:", nrow(meta3$variables), "\n")
for (i in 1:nrow(meta3$variables)) {
  cat(sprintf("  %s: %d vals\n", meta3$variables$text[i], length(meta3$variables$values[[i]])))
}

# This table has only 2 dimensions: Year and Sector (dropout rates)
query3 <- lapply(1:nrow(meta3$variables), function(i) {
  list(
    code = meta3$variables$code[i],
    selection = list(filter = "item", values = as.list(meta3$variables$values[[i]]))
  )
})

js3 <- fetch_pxweb("kkesk/statfin_kkesk_pxt_14pn.px", query3)
df3 <- parse_js2(js3)
cat("National discontinuation:", nrow(df3), "rows,", sum(!is.na(df3$value)), "non-NA\n")
write_csv(df3, "../data/dropout_national_raw.csv")

## ============================================================
## Validation
## ============================================================
cat("\n=== Validation ===\n")
stopifnot(nrow(df1) > 100)
stopifnot(nrow(df2) > 50)
stopifnot(nrow(df3) > 50)
stopifnot(sum(!is.na(df1$value)) > 50)

cat("All data fetched and validated successfully.\n")
