## 01b_fix_iem.R — Re-fetch IEM verification with correct field names
## The IEM Cow API uses field names like "avg_leadtime[min]", "POD[1]", etc.

library(data.table)
library(httr)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

county_wfo <- fread("data/county_wfo_map.csv")
wfos <- sort(unique(county_wfo$wfo))
cat("WFOs to query:", length(wfos), "\n")

years <- 2008:2024
iem_results <- list()
n_fetched <- 0
n_errors <- 0

for (w in wfos) {
  for (y in years) {
    url <- sprintf(
      "https://mesonet.agron.iastate.edu/api/1/cow.json?wfo=%s&begints=%d-01-01T00:00Z&endts=%d-12-31T23:59Z&phenomena=TO&lsrtype=TO",
      w, y, y
    )

    resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
    if (is.null(resp) || status_code(resp) != 200) {
      n_errors <- n_errors + 1
      next
    }

    json_text <- content(resp, "text", encoding = "UTF-8")
    json <- tryCatch(fromJSON(json_text), error = function(e) NULL)
    if (is.null(json) || is.null(json$stats)) next

    s <- json$stats

    # Fields use bracket notation: "avg_leadtime[min]", "POD[1]", etc.
    get_val <- function(name) {
      v <- s[[name]]
      if (is.null(v) || length(v) == 0) return(NA_real_)
      as.numeric(v)
    }

    iem_results[[length(iem_results) + 1]] <- data.table(
      wfo = w,
      year = y,
      avg_leadtime = get_val("avg_leadtime[min]"),
      max_leadtime = get_val("max_leadtime[min]"),
      min_leadtime = get_val("min_leadtime[min]"),
      pod = get_val("POD[1]"),
      far = get_val("FAR[1]"),
      csi = get_val("CSI[1]"),
      events_verified = get_val("events_verified"),
      events_total = get_val("events_total"),
      warned_reports = get_val("warned_reports"),
      unwarned_reports = get_val("unwarned_reports")
    )
    n_fetched <- n_fetched + 1
  }

  if (n_fetched %% 200 == 0 && n_fetched > 0)
    cat("  Fetched", n_fetched, "WFO-year records...\n")
  Sys.sleep(0.05)
}

iem <- rbindlist(iem_results, fill = TRUE)
cat("IEM records total:", nrow(iem), "\n")
cat("Records with lead time:", sum(!is.na(iem$avg_leadtime)), "\n")
cat("Records with POD:", sum(!is.na(iem$pod)), "\n")
cat("Errors:", n_errors, "\n")

# Summary stats
cat("\nLead time summary (minutes):\n")
print(summary(iem$avg_leadtime))
cat("\nPOD summary:\n")
print(summary(iem$pod))

# Compute WFO-level long-run averages
wfo_avg <- iem[!is.na(avg_leadtime), .(
  avg_lt_overall = mean(avg_leadtime, na.rm = TRUE),
  sd_lt = sd(avg_leadtime, na.rm = TRUE),
  avg_pod_overall = mean(pod, na.rm = TRUE),
  avg_far_overall = mean(far, na.rm = TRUE),
  avg_csi_overall = mean(csi, na.rm = TRUE),
  n_years = .N,
  total_events = sum(events_verified, na.rm = TRUE)
), by = wfo]

cat("\nWFO average lead time distribution:\n")
print(summary(wfo_avg$avg_lt_overall))
cat("WFOs with data:", nrow(wfo_avg), "\n")

fwrite(iem, "data/iem_verification.csv")
fwrite(wfo_avg, "data/wfo_averages.csv")
cat("\nSaved data/iem_verification.csv and data/wfo_averages.csv\n")
