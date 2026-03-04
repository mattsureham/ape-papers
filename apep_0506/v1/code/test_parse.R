## Test the parse_rupees function
parse_rupees <- function(x) {
  x <- as.character(x)
  n <- length(x)
  result <- numeric(n)

  for (i in seq_len(n)) {
    s <- x[i]
    if (is.na(s) || s == "" || tolower(trimws(s)) == "nil") {
      result[i] <- 0
      next
    }

    s <- gsub("^Rs\\s*", "", s)
    s <- trimws(s)

    if (s == "" || s == "0") {
      result[i] <- 0
      next
    }

    has_crore <- grepl("Crore", s, ignore.case = TRUE)
    has_lac   <- grepl("Lac|Lakh", s, ignore.case = TRUE)
    has_thou  <- grepl("Thou", s, ignore.case = TRUE)

    num_str <- gsub("\\s*(Crore|Lacs?|Lakhs?|Thou)\\+?.*$", "", s, ignore.case = TRUE)
    num_str <- gsub(",", "", num_str)
    num_str <- gsub("[^0-9.]", "", num_str)

    if (has_crore || has_lac || has_thou) {
      mult <- if (has_crore) 1e7 else if (has_lac) 1e5 else 1e3

      found <- FALSE
      for (strip in 1:min(4, nchar(num_str) - 1)) {
        candidate_str <- substr(num_str, 1, nchar(num_str) - strip)
        candidate_val <- suppressWarnings(as.numeric(candidate_str))
        if (!is.na(candidate_val)) {
          summary_val <- floor(candidate_val / mult)
          if (nchar(as.character(summary_val)) == strip) {
            result[i] <- candidate_val
            found <- TRUE
            break
          }
        }
      }
      if (!found) {
        val <- suppressWarnings(as.numeric(num_str))
        result[i] <- ifelse(is.na(val), 0, val)
      }
    } else {
      val <- suppressWarnings(as.numeric(num_str))
      result[i] <- ifelse(is.na(val), 0, val)
    }
  }

  return(result)
}

tests <- c(
  "Rs 31,00031 Thou+",
  "Rs 2,45,0002 Lacs+",
  "Rs 16,54,00016 Lacs+",
  "Rs 41,80,64841 Lacs+",
  "Rs 9,04,11,7979 Crore+",
  "Rs 0",
  "Nil",
  "Rs 20,15,00020 Lacs+",
  "Rs 1,0001 Thou+"
)
results <- parse_rupees(tests)
for (j in seq_along(tests)) {
  cat(sprintf("%-35s => %15s\n", tests[j],
              formatC(results[j], format = "f", big.mark = ",", digits = 0)))
}
