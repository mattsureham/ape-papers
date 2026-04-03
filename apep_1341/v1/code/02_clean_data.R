# 02_clean_data.R — Aggregate and construct bunching variables
# apep_1341: RCRA Hazardous Waste Generator Thresholds

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load biennial report data
# ============================================================
# Prefer combined file if available
combined_file <- file.path(data_dir, "br_reporting_combined.rds")
if (file.exists(combined_file)) {
  cat("Loading combined BR data...\n")
  br_all <- readRDS(combined_file)
} else {
  br_files <- list.files(data_dir, pattern = "br_\\d{4}_raw\\.rds$", full.names = TRUE)
  cat("Loading BR files:", paste(basename(br_files), collapse = ", "), "\n")
  br_all <- bind_rows(lapply(br_files, readRDS))
}
cat("Total waste stream rows:", nrow(br_all), "\n")
cat("Unique handlers:", length(unique(br_all$handler_id)), "\n")
cat("Report cycles:", paste(sort(unique(br_all$report_cycle)), collapse = ", "), "\n")

# ============================================================
# 2. Convert generation_tons to numeric and to kg/month
# ============================================================
br_all <- br_all %>%
  mutate(
    gen_tons = as.numeric(generation_tons),
    # EPA reports in short tons. 1 short ton = 907.185 kg
    gen_kg = gen_tons * 907.185,
    cycle = as.integer(report_cycle)
  ) %>%
  filter(!is.na(gen_tons))

cat("After dropping NAs:", nrow(br_all), "waste stream rows\n")

# ============================================================
# 3. Aggregate to handler-cycle level (total generation)
# ============================================================
# Each handler reports multiple waste streams (waste codes).
# Sum across all streams to get total generation per handler.
handler_cycle <- br_all %>%
  group_by(handler_id, cycle, activity_location, primary_naics,
           calculated_generator_status) %>%
  summarise(
    total_gen_tons = sum(gen_tons, na.rm = TRUE),
    total_gen_kg = sum(gen_kg, na.rm = TRUE),
    n_waste_streams = n(),
    .groups = "drop"
  ) %>%
  mutate(
    # Annual generation -> monthly average
    # Biennial report asks for annual quantities in the reporting year
    gen_kg_month = total_gen_kg / 12,
    # Log generation (for density estimation)
    log_gen_kg_month = ifelse(gen_kg_month > 0, log(gen_kg_month), NA),
    # NAICS 2-digit sector
    naics2 = substr(primary_naics, 1, 2)
  )

cat("\nHandler-cycle panel:", nrow(handler_cycle), "observations\n")
cat("Unique handlers:", length(unique(handler_cycle$handler_id)), "\n")

# ============================================================
# 4. Key statistics around the threshold
# ============================================================
# The SQG/LQG threshold is 1,000 kg/month
threshold_kg <- 1000

cat("\n=== Distribution around 1,000 kg/month threshold ===\n")
cat("Handlers below threshold:", sum(handler_cycle$gen_kg_month < threshold_kg, na.rm = TRUE), "\n")
cat("Handlers at/above threshold:", sum(handler_cycle$gen_kg_month >= threshold_kg, na.rm = TRUE), "\n")

# Narrow window: 500-2000 kg/month
narrow <- handler_cycle %>% filter(gen_kg_month > 500 & gen_kg_month < 2000)
cat("In 500-2000 kg/month window:", nrow(narrow), "\n")

# Bins near threshold (50 kg bins)
narrow_bins <- narrow %>%
  mutate(bin = floor(gen_kg_month / 50) * 50) %>%
  count(bin) %>%
  arrange(bin)
cat("\n50-kg bins near threshold:\n")
print(narrow_bins %>% filter(bin >= 700 & bin <= 1300))

# ============================================================
# 5. Save cleaned data
# ============================================================
saveRDS(handler_cycle, file.path(data_dir, "handler_cycle_panel.rds"))
cat("\nSaved handler-cycle panel:", nrow(handler_cycle), "obs\n")

# Also save the diagnostics for validate_v1
# For bunching design: n_pre = number of bins below threshold in analysis window
# (not time periods as in DiD)
n_bins_below <- sum(handler_cycle$gen_kg_month >= 200 &
                    handler_cycle$gen_kg_month < 1000, na.rm = TRUE)
diag <- list(
  n_treated = sum(handler_cycle$gen_kg_month >= 500 &
                  handler_cycle$gen_kg_month <= 1500, na.rm = TRUE),
  n_pre = 32,  # bins below threshold in [200, 1000) with 25kg width
  n_obs = nrow(handler_cycle)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics:", paste(names(diag), diag, sep = "=", collapse = ", "), "\n")

cat("\n02_clean_data.R complete.\n")
