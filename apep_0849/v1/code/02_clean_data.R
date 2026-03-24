# 02_clean_data.R — Build analysis panel at USPC-class × year level
# apep_0849: Taiwan IIA R&D Tax Credit Transition

source("00_packages.R")

# ── Load raw data ──────────────────────────────────────────────────────────
raw <- fread("../data/patents_tw_il_kr.csv",
             colClasses = c(filing_date = "character", grant_date = "character"))
cat("Raw rows:", nrow(raw), "\n")

# ── Filter to utility patents with valid filing dates and USPC ─────────────
raw <- raw[patent_type == "utility" & filing_date != "" & uspc_mainclass != ""]
raw[, filing_date := as.Date(filing_date)]
raw[, grant_date := as.Date(grant_date)]
raw[, filing_year := year(filing_date)]

# Study window: 2003-2013 (USPC coverage excellent through 2013)
raw <- raw[filing_year >= 2003 & filing_year <= 2013]
cat("After date filter:", nrow(raw), "\n")

# ── SUI Strategic Industry Classification ──────────────────────────────────
# The SUI designated sectors: semiconductors, optoelectronics, communications,
# information technology, and precision instruments.
# USPC classes mapped from SUI sector definitions:
sui_classes <- c(
  # Semiconductors
  "257",  # Active solid-state devices
  "438",  # Semiconductor device manufacturing
  # Optoelectronics and display technology
  "345",  # Computer graphics/display
  "349",  # Liquid crystal cells/elements
  "362",  # Illumination
  "359",  # Optical systems and elements
  "385",  # Optical waveguides
  "348",  # Television
  "315",  # Electric lamp and discharge devices
  # Communications technology
  "455",  # Telecommunications
  "375",  # Pulse or digital communications
  "370",  # Multiplex communications
  "343",  # Communications: directive radio wave systems
  # Precision instruments and measurement
  "382",  # Image analysis
  "324",  # Electricity: measuring and testing
  "356",  # Optics: measuring and testing
  # Information technology hardware
  "365",  # Static information storage and retrieval
  "710",  # Electrical computers: input/output
  "711",  # Electrical computers: memory
  "713",  # Electrical computers: support
  "714",  # Error detection/correction
  "716"   # Computer-aided design
)

raw[, treated_class := ifelse(uspc_mainclass %in% sui_classes, 1L, 0L)]
cat("SUI strategic classes:", length(sui_classes), "\n")
cat("Treated patents:", sum(raw$treated_class == 1), "\n")
cat("Control patents:", sum(raw$treated_class == 0), "\n")

# ── Post-treatment indicator ──────────────────────────────────────────────
raw[, post := ifelse(filing_year >= 2010, 1L, 0L)]

# ── Aggregate to country × USPC-class × year panel ────────────────────────
# Keep top 50 USPC classes by Taiwan volume for tractable panel
tw_class_counts <- raw[assignee_country == "TW", .N, by = uspc_mainclass][order(-N)]
top_classes <- tw_class_counts[1:min(50, nrow(tw_class_counts)), uspc_mainclass]

panel_data <- raw[uspc_mainclass %in% top_classes]

# Year-level aggregation (quarterly is fine with 50 classes × 11 years)
panel <- panel_data[, .(
  n_patents = .N,
  mean_claims = mean(as.numeric(num_claims), na.rm = TRUE),
  mean_citations = mean(forward_citations, na.rm = TRUE)
), by = .(assignee_country, uspc_mainclass, filing_year)]

panel[, post := ifelse(filing_year >= 2010, 1L, 0L)]
panel[, treated_class := ifelse(uspc_mainclass %in% sui_classes, 1L, 0L)]
panel[, ln_patents := log(n_patents + 1)]

panel[, class_id := as.integer(factor(uspc_mainclass))]
panel[, year_id := as.integer(factor(filing_year))]

cat("\nPanel dimensions:\n")
cat("  Countries:", uniqueN(panel$assignee_country), "\n")
cat("  USPC classes:", uniqueN(panel$uspc_mainclass), "\n")
cat("  Years:", uniqueN(panel$filing_year), "\n")
cat("  Total obs:", nrow(panel), "\n")
cat("  Treated classes:", uniqueN(panel[treated_class == 1]$uspc_mainclass), "\n")
cat("  Control classes:", uniqueN(panel[treated_class == 0]$uspc_mainclass), "\n")

# ── Save ──────────────────────────────────────────────────────────────────
fwrite(panel, "../data/analysis_panel.csv")

tw_panel <- panel[assignee_country == "TW"]
fwrite(tw_panel, "../data/tw_panel.csv")

cat("\n── Summary (Taiwan) ──\n")
print(tw_panel[, .(
  mean_patents = mean(n_patents),
  sd_patents = sd(n_patents),
  mean_claims = mean(mean_claims, na.rm = TRUE),
  mean_cites = mean(mean_citations, na.rm = TRUE)
), by = .(treated_class, post)])
