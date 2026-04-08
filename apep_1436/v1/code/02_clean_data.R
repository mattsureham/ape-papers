#!/usr/bin/env Rscript
# 02_clean_data.R — merge ClaimReview events into GDELT topic-day panel
suppressPackageStartupMessages({
  library(arrow); library(data.table); library(jsonlite); library(lubridate)
})

out_dir <- "../data"
cr_dir  <- file.path(out_dir, "claimreview")

# query -> canonical topic mapping
topic_map <- list(
  immigration = c("immigration"),
  climate     = c("climate"),
  covid       = c("covid","masks","vaccine"),
  elections   = c("election","ballot","fraud","trump","biden"),
  economy     = c("economy","inflation"),
  healthcare  = c("healthcare","abortion"),
  crime       = c("crime","gun","school")
)

parse_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  if (!length(lines)) return(NULL)
  recs <- lapply(lines, function(l) tryCatch(fromJSON(l, simplifyVector = FALSE), error = function(e) NULL))
  recs <- Filter(Negate(is.null), recs)
  if (!length(recs)) return(NULL)
  rbindlist(lapply(recs, function(r) {
    cr <- r$claimReview[[1]]
    if (is.null(cr)) return(NULL)
    rd <- cr$reviewDate
    if (is.null(rd) || !nzchar(rd)) return(NULL)
    data.table(
      query  = r$`_query_topic`,
      date   = as.Date(substr(rd, 1, 10)),
      rating = tolower(cr$textualRating %||% ""),
      publisher = cr$publisher$site %||% ""
    )
  }), fill = TRUE)
}
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

files <- list.files(cr_dir, pattern = "\\.jsonl$", full.names = TRUE)
cr <- rbindlist(lapply(files, parse_file), fill = TRUE)
cat("raw claimreview rows:", nrow(cr), "\n")

# Assign canonical topic
query2topic <- unlist(lapply(names(topic_map), function(t) setNames(rep(t, length(topic_map[[t]])), topic_map[[t]])))
cr[, topic := query2topic[query]]
cr <- cr[!is.na(topic)]
cat("after topic mapping:", nrow(cr), "\n")

# Classify rating
false_terms <- c("false","misleading","mostly false","pants on fire","four pinocchios",
                 "incorrect","distorts the facts","miscaptioned","mixture","missing context",
                 "unproven","unsupported","not true","not legit","scam","fake","altered",
                 "partly false","half true","wrong","no evidence","exaggerated")
true_terms  <- c("true","correct","mostly true","correct attribution","accurate","legit","verified")
cr[, is_false := as.integer(rating %in% false_terms)]
cr[, is_true  := as.integer(rating %in% true_terms)]

# Keep all events — each row is a distinct fact-check article

# Collapse to topic x date event counts
cr[, date := as.Date(date)]
cr <- cr[date >= as.Date("2017-01-01") & date <= as.Date("2024-12-31")]
events <- cr[, .(n_fc = .N,
                 n_fc_false = sum(is_false),
                 n_fc_true  = sum(is_true)),
             by = .(topic, date)]
cat("event topic-days:", nrow(events), "\n")

# Load GDELT topic panels
topics <- names(topic_map)
gd <- rbindlist(lapply(topics, function(t) {
  p <- file.path(out_dir, paste0("gdelt_topic_", t, ".parquet"))
  d <- as.data.table(read_parquet(p))
  d[, date := as.Date(day)]
  d[, topic := t]
  d[, .(topic, date, n_articles, avg_tone, sd_tone)]
}))
cat("gdelt topic-days:", nrow(gd), "\n")

# IV / total
iv <- as.data.table(read_parquet(file.path(out_dir, "gdelt_iv_daily.parquet")))
iv[, date := as.Date(day)]
iv[, day := NULL]
iv[, comp_news := log1p(sports_events + disaster_related)]

tot <- as.data.table(read_parquet(file.path(out_dir, "gdelt_total_daily.parquet")))
tot[, date := as.Date(day)]; tot[, day := NULL]

panel <- merge(gd, events, by = c("topic","date"), all.x = TRUE)
panel[is.na(n_fc), `:=`(n_fc = 0L, n_fc_false = 0L, n_fc_true = 0L)]
panel <- merge(panel, iv[, .(date, comp_news, sports_events, disaster_related,
                             conflict_events, coop_events)], by = "date", all.x = TRUE)
panel <- merge(panel, tot, by = "date", all.x = TRUE)
panel[, log_n_articles := log1p(n_articles)]
panel[, log_total := log1p(total_articles)]
panel[, iso_week := paste0(year(date), "-W", sprintf("%02d", isoweek(date)))]
panel[, topic_week := paste(topic, iso_week, sep = "_")]
panel[, month := format(date, "%Y-%m")]
panel[, dow := wday(date)]
setorder(panel, topic, date)

# Leads/lags of fc_false
setkey(panel, topic, date)
for (k in -14:14) {
  panel[, paste0("fc_false_l", ifelse(k<0,paste0("m",-k),k)) := shift(n_fc_false, k, type = "lag"), by = topic]
}

write_parquet(panel, file.path(out_dir, "panel.parquet"))
fwrite(panel, file.path(out_dir, "panel.csv"))
cat("panel rows:", nrow(panel), "cols:", ncol(panel), "\n")

# diagnostics.json
diag <- list(
  n_obs = nrow(panel),
  n_topics = length(topics),
  n_dates = length(unique(panel$date)),
  n_events_total = sum(panel$n_fc),
  n_events_false = sum(panel$n_fc_false),
  n_events_true = sum(panel$n_fc_true),
  n_treated = sum(panel$n_fc_false > 0),
  n_pre = sum(panel$date < as.Date("2020-01-01")),
  date_min = as.character(min(panel$date)),
  date_max = as.character(max(panel$date))
)
writeLines(toJSON(diag, auto_unbox = TRUE, pretty = TRUE),
           file.path(out_dir, "diagnostics.json"))
print(diag)
