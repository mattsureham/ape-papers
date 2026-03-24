## 01c_iem_careful.R — Carefully fetch IEM data with generous delays
## Fetches WFO performance data using wider time windows (fewer API calls)

library(data.table)
library(httr)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

county_wfo <- fread("data/county_wfo_map.csv")
# Focus on CONUS WFOs (exclude territories)
wfos <- sort(unique(county_wfo$wfo))
wfos <- wfos[nchar(wfos) == 3 & !wfos %in% c("PPG", "HFO", "GUM", "AFC", "AJK", "AFG")]
cat("CONUS WFOs to query:", length(wfos), "\n")

# Strategy: fetch 3-year windows instead of yearly (fewer calls)
# Periods: 2008-2011, 2012-2015, 2016-2019, 2020-2024
periods <- list(
  c(2008, 2011),
  c(2012, 2015),
  c(2016, 2019),
  c(2020, 2024)
)

iem_results <- list()
n_fetched <- 0
n_errors <- 0

for (w in wfos) {
  for (p in periods) {
    url <- sprintf(
      "https://mesonet.agron.iastate.edu/api/1/cow.json?wfo=%s&begints=%d-01-01T00:00Z&endts=%d-12-31T23:59Z&phenomena=TO&lsrtype=TO",
      w, p[1], p[2]
    )

    resp <- tryCatch(GET(url, timeout(45)), error = function(e) {
      cat("  Timeout for", w, p[1], "-", p[2], "\n")
      return(NULL)
    })

    if (is.null(resp)) { n_errors <- n_errors + 1; Sys.sleep(3); next }

    if (status_code(resp) != 200) {
      n_errors <- n_errors + 1
      if (status_code(resp) == 502) Sys.sleep(5)  # back off on 502
      next
    }

    json_text <- content(resp, "text", encoding = "UTF-8")
    json <- tryCatch(fromJSON(json_text), error = function(e) NULL)
    if (is.null(json) || is.null(json$stats)) next

    s <- json$stats
    get_val <- function(name) {
      v <- s[[name]]
      if (is.null(v) || length(v) == 0) return(NA_real_)
      as.numeric(v)
    }

    iem_results[[length(iem_results) + 1]] <- data.table(
      wfo = w,
      period_start = p[1],
      period_end = p[2],
      avg_leadtime = get_val("avg_leadtime[min]"),
      max_leadtime = get_val("max_leadtime[min]"),
      pod = get_val("POD[1]"),
      far = get_val("FAR[1]"),
      csi = get_val("CSI[1]"),
      events_verified = get_val("events_verified"),
      events_total = get_val("events_total"),
      warned_reports = get_val("warned_reports"),
      unwarned_reports = get_val("unwarned_reports")
    )
    n_fetched <- n_fetched + 1

    # Be polite: 0.5 second between requests
    Sys.sleep(0.5)
  }

  if (n_fetched %% 50 == 0 && n_fetched > 0)
    cat("  Progress:", n_fetched, "records fetched,", n_errors, "errors\n")
}

iem <- rbindlist(iem_results, fill = TRUE)
cat("\nIEM records:", nrow(iem), "\n")
cat("With lead time:", sum(!is.na(iem$avg_leadtime)), "\n")
cat("Errors:", n_errors, "\n")

# Compute WFO-level long-run averages (weighted by events)
wfo_avg <- iem[!is.na(avg_leadtime) & events_verified > 0, .(
  avg_lt_overall = weighted.mean(avg_leadtime, events_verified, na.rm = TRUE),
  avg_pod_overall = weighted.mean(pod, events_verified, na.rm = TRUE),
  avg_far_overall = weighted.mean(far, events_verified, na.rm = TRUE),
  avg_csi_overall = weighted.mean(csi, events_verified, na.rm = TRUE),
  n_periods = .N,
  total_events = sum(events_verified)
), by = wfo]

cat("\nWFO average lead time:\n")
print(summary(wfo_avg$avg_lt_overall))
cat("WFOs with data:", nrow(wfo_avg), "\n")
cat("SD of WFO avg lead time:", round(sd(wfo_avg$avg_lt_overall, na.rm = TRUE), 2), "min\n")

fwrite(iem, "data/iem_verification.csv")
fwrite(wfo_avg, "data/wfo_averages.csv")
cat("\nSaved data/iem_verification.csv and data/wfo_averages.csv\n")
