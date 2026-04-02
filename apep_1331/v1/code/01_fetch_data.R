## 01_fetch_data.R — Fetch FOS quarterly complaints data
## APEP apep_1331: The No-Advice Trap

source("00_packages.R")

data_dir <- "../data"

# --- FOS Quarterly Complaints Data ---
# Archive (Q1 2014/15 through Q4 2020/21) and Current (Q1 2021/22 onwards)

fos_urls <- c(
  # Archive 2014/15
  "Q1_2014" = "https://www.financial-ombudsman.org.uk/files/290446/Product-complaints-data-Q1-2014-2015.xlsx",
  "Q2_2014" = "https://www.financial-ombudsman.org.uk/files/290447/Product-complaints-data-Q2-2014-2015.xlsx",
  "Q3_2014" = "https://www.financial-ombudsman.org.uk/files/290448/Product-complaints-data-Q3-2014-2015.xlsx",
  # Archive 2015/16
  "Q1_2015" = "https://www.financial-ombudsman.org.uk/files/290451/Product-complaints-data-Q1-2015-2016.xlsx",
  "Q2_2015" = "https://www.financial-ombudsman.org.uk/files/290452/Product-complaints-data-Q2-2015-2016.xlsx",
  "Q3_2015" = "https://www.financial-ombudsman.org.uk/files/290454/Product-complaints-data-Q3-2015-2016.xlsx",
  # Archive 2016/17
  "Q1_2016" = "https://www.financial-ombudsman.org.uk/files/290457/Product-complaints-data-Q1-2016-2017.xlsx",
  "Q2_2016" = "https://www.financial-ombudsman.org.uk/files/290458/Product-complaints-data-Q2-2016-2017.xlsx",
  "Q3_2016" = "https://www.financial-ombudsman.org.uk/files/290459/Product-complaints-data-Q3-2016-2017.xlsx",
  # Archive 2017/18
  "Q1_2017" = "https://www.financial-ombudsman.org.uk/files/290460/Product-complaints-data-Q1-2017-2018.xlsx",
  "Q2_2017" = "https://www.financial-ombudsman.org.uk/files/290461/Product-complaints-data-Q2-2017-2018.xlsx",
  "Q3_2017" = "https://www.financial-ombudsman.org.uk/files/290462/Product-complaints-data-Q3-2017-2018.xlsx",
  # Archive 2018/19
  "Q1_2018" = "https://www.financial-ombudsman.org.uk/files/290463/Product-complaints-data-Q1-2018-2019.xlsx",
  "Q2_2018" = "https://www.financial-ombudsman.org.uk/files/290464/Product-complaints-data-Q2-2018-2019.xlsx",
  "Q3_2018" = "https://www.financial-ombudsman.org.uk/files/290465/Product-complaints-data-Q3-2018-2019.xlsx",
  # Archive 2019/20
  "Q1_2019" = "https://www.financial-ombudsman.org.uk/files/292372/Product-complaints-data-Q1-2019-2020.xlsx",
  "Q2_2019" = "https://www.financial-ombudsman.org.uk/files/292373/Product-complaints-data-Q2-2019-2020.xlsx",
  "Q3_2019" = "https://www.financial-ombudsman.org.uk/files/292520/Product-complaints-data-Q3-2019-2020.xlsx",
  "Q4_2019" = "https://www.financial-ombudsman.org.uk/files/276224/Product-complaints-data-Q4-2019-2020.xlsx",
  # Archive 2020/21
  "Q1_2020" = "https://www.financial-ombudsman.org.uk/files/282230/Product-complaints-data-Q1-2020-21.xlsx",
  "Q2_2020" = "https://www.financial-ombudsman.org.uk/files/287810/Product-complaints-data-Q2-2020-21.xlsx",
  "Q3_2020" = "https://www.financial-ombudsman.org.uk/files/295944/Product-complaints-data-Q3-2020-21.xlsx",
  "Q4_2020" = "https://www.financial-ombudsman.org.uk/files/303853/Product-complaints-data-Q4-2020-21.xlsx",
  # Current 2021/22
  "Q1_2021" = "https://files.financial-ombudsman.org.uk/public/Uploads/Product-complaints-data-Q1-2021-22.xlsx",
  "Q2_2021" = "https://files.financial-ombudsman.org.uk/public/Uploads/Product-complaints-data-Q2-2021-22.xlsx",
  "Q3_2021" = "https://www.financial-ombudsman.org.uk/files/323879/Product-complaints-data-Q3-2021-22.xlsx",
  "Q4_2021" = "https://www.financial-ombudsman.org.uk/files/323979/Quarterly-product-complaints-data-Q4-2021-22.xlsx",
  # Current 2022/23
  "Q1_2022" = "https://www.financial-ombudsman.org.uk/files/324031/Quarterly-product-complaints-data-Q1-2022-23.xlsx",
  "Q2_2022" = "https://www.financial-ombudsman.org.uk/files/324074/Quarterly-product-complaints-data-Q2-2022-23.xlsx",
  "Q3_2022" = "https://www.financial-ombudsman.org.uk/files/324155/Quarterly-product-complaints-data-Q3-2022-23.xlsx",
  "Q4_2022" = "https://www.financial-ombudsman.org.uk/files/324240/Quarterly-product-complaints-data-Q4-2022-23.xlsx",
  # Current 2023/24
  "Q1_2023" = "https://www.financial-ombudsman.org.uk/files/324294/Quarterly-product-complaints-data-Q1-2023-24.xlsx",
  "Q2_2023" = "https://www.financial-ombudsman.org.uk/files/324388/Quarterly-complaints-data-Q2-2023-24.xlsx",
  "Q3_2023" = "https://www.financial-ombudsman.org.uk/files/324407/Quarterly-complaints-data-Q3-2023-24.xlsx",
  # Current 2024/25
  "Q1_2024" = "https://www.financial-ombudsman.org.uk/files/324462/Quarterly-complaints-data-Q1-2024-25.xlsx",
  "Q2_2024" = "https://www.financial-ombudsman.org.uk/files/324506/Quarterly-complaints-data-Q2-2024-25.xlsx",
  "Q3_2024" = "https://www.financial-ombudsman.org.uk/files/324561/Quarterly-complaints-data-Q3-2024-25.xlsx",
  "Q4_2024" = "https://www.financial-ombudsman.org.uk/files/324635/Quarterly-complaints-data-Q4-2024-25.xlsx",
  # Current 2025/26
  "Q1_2025" = "https://www.financial-ombudsman.org.uk/files/324654/Quarterly-complaints-data-Q1-2025-26.xlsx",
  "Q2_2025" = "https://www.financial-ombudsman.org.uk/files/324689/Quarterly-complaints-data-Q2-2025-26.xlsx"
)

cat(sprintf("=== Downloading %d FOS quarterly files ===\n", length(fos_urls)))

download_results <- list()
for (qname in names(fos_urls)) {
  dest <- file.path(data_dir, paste0("fos_", qname, ".xlsx"))

  # Skip if already downloaded
  if (file.exists(dest) && file.size(dest) > 1000) {
    cat(sprintf("  %s: already exists (%d bytes)\n", qname, file.size(dest)))
    download_results[[qname]] <- TRUE
    next
  }

  result <- tryCatch({
    download.file(fos_urls[[qname]], dest, mode = "wb", quiet = TRUE)
    size <- file.size(dest)
    if (size < 1000) {
      cat(sprintf("  %s: FAILED (file too small: %d bytes)\n", qname, size))
      file.remove(dest)
      FALSE
    } else {
      cat(sprintf("  %s: OK (%d bytes)\n", qname, size))
      TRUE
    }
  }, error = function(e) {
    cat(sprintf("  %s: ERROR (%s)\n", qname, e$message))
    FALSE
  })

  download_results[[qname]] <- result
}

successes <- sum(unlist(download_results))
failures <- sum(!unlist(download_results))
cat(sprintf("\n=== DOWNLOAD SUMMARY: %d OK, %d FAILED ===\n", successes, failures))

if (failures > 0) {
  cat("Failed quarters:\n")
  for (qname in names(download_results)) {
    if (!download_results[[qname]]) cat(sprintf("  %s\n", qname))
  }
}

stopifnot("Must have at least 30 quarterly files" = successes >= 30)

cat("\nData fetch complete.\n")
