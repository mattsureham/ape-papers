# 01b_add_month.R — Add one more pre-reform month (2013-06) to the panel
library(data.table)

data_dir <- "../data"
archive_dir <- file.path(data_dir, "archives")
zip_file <- file.path(archive_dir, "2013-06.zip")
ds <- "2013-06"

crosswalk <- fread(file.path(data_dir, "force_crosswalk.csv"))

csv_list <- unzip(zip_file, list = TRUE)$Name
street_csvs <- csv_list[grepl("-street\\.csv$", csv_list)]

month_results <- list()
tmp_dir <- tempdir()

for (csv_name in street_csvs) {
  base_name <- basename(csv_name)
  pattern <- paste0("^", ds, "-(.+)-street\\.csv$")
  force_match <- sub(pattern, "\\1", base_name)
  if (force_match == base_name) next
  if (!force_match %in% crosswalk$force_slug) next

  csv_data <- tryCatch({
    unzip(zip_file, files = csv_name, exdir = tmp_dir, overwrite = TRUE, junkpaths = TRUE)
    fread(file.path(tmp_dir, base_name), select = c("Crime type"))
  }, error = function(e) NULL)

  if (is.null(csv_data) || nrow(csv_data) == 0) next

  type_counts <- csv_data[, .N, by = `Crime type`]
  type_counts[, force_slug := force_match]
  type_counts[, date := ds]
  month_results[[length(month_results) + 1]] <- type_counts
}

month_dt <- rbindlist(month_results)
cat("Extracted", uniqueN(month_dt$force_slug), "forces for 2013-06\n")

# Build panel rows for new month
asb_counts <- month_dt[`Crime type` == "Anti-social behaviour",
                       .(asb_count = sum(N)), by = .(force_slug, date)]
burglary_counts <- month_dt[`Crime type` == "Burglary",
                            .(burglary_count = sum(N)), by = .(force_slug, date)]
new_panel <- merge(asb_counts, burglary_counts, by = c("force_slug", "date"), all = TRUE)
new_panel <- merge(new_panel, crosswalk, by = "force_slug", all.x = TRUE)
new_panel <- new_panel[!is.na(cjs_area)]

# Append to existing panel
old_panel <- fread(file.path(data_dir, "asb_monthly_raw.csv"))
combined <- rbind(old_panel, new_panel)
fwrite(combined, file.path(data_dir, "asb_monthly_raw.csv"))

cat("Panel now:", nrow(combined), "rows,", uniqueN(combined$date), "months\n")

# Clean up
file.remove(zip_file)
cat("Done.\n")
