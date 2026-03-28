## 03c_monthly_event_study.R — Monthly Bunching Around Policy Breaks
## apep_0727 v3: Addresses referee request for high-frequency evidence

source("00_packages.R")

cat("Loading data for monthly event study...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
dt_10[, ym := year * 100L + month]  # year-month identifier
all_bins <- data.table(bin_int = 30L:199L)

bunching_est_int <- function(bin_data, kink_int = 100L,
                              excl_lower = 90L, excl_upper = 110L,
                              window_lower = 30L, window_upper = 199L,
                              poly_degree = 7) {
  bd <- copy(bin_data[bin_int >= window_lower & bin_int <= window_upper])
  bd[, excluded := bin_int >= excl_lower & bin_int < excl_upper]
  bd[, z := bin_int - kink_int]
  for (p in 1:poly_degree) bd[, paste0("z", p) := z^p]
  fit <- lm(as.formula(paste0("count ~ ", paste(paste0("z", 1:poly_degree), collapse = " + "))),
             data = bd[excluded == FALSE])
  bd[, counterfactual := pmax(predict(fit, newdata = bd), 0)]
  excess <- sum(bd[excluded == TRUE, count - counterfactual])
  f0 <- bd[bin_int == kink_int, counterfactual]
  if (length(f0) == 0 || is.na(f0) || f0 <= 0) f0 <- mean(bd[excluded == FALSE]$counterfactual)
  list(bunching_ratio = excess / f0, excess_mass = excess)
}

# Monthly bunching estimates for key windows around policy breaks
# Window 1: Around Aug 2014 (surcharge introduction)
# Window 2: Around Jan 2021 (threshold expansion)
# Window 3: Around Jul 2022 (surcharge abolition)

cat("\n=== Monthly Bunching Estimates ===\n")
monthly_results <- list()

# All months from 2013-01 through 2024-12
for (yr in 2013:2024) {
  for (mo in 1:12) {
    ym_val <- yr * 100L + mo
    dt_ym <- dt_10[ym == ym_val]
    N <- nrow(dt_ym)
    if (N < 500) next  # Skip months with too few installations

    ym_bins <- dt_ym[, .(count = .N), by = bin_int]
    ym_bins <- merge(all_bins, ym_bins, by = "bin_int", all.x = TRUE)
    ym_bins[is.na(count), count := 0L]

    est <- tryCatch(
      bunching_est_int(ym_bins, poly_degree = 5),  # Lower degree for monthly
      error = function(e) list(bunching_ratio = NA, excess_mass = NA)
    )

    n99 <- sum(ym_bins[bin_int == 99L, count])
    n101 <- sum(ym_bins[bin_int == 101L, count])

    monthly_results[[length(monthly_results) + 1]] <- data.frame(
      year = yr, month = mo,
      date = as.Date(sprintf("%d-%02d-01", yr, mo)),
      bunching_ratio = round(est$bunching_ratio, 2),
      excess_mass = round(est$excess_mass),
      n_99 = n99, n_101 = n101, n_total = N,
      raw_ratio = round(n99 / max(n101, 1), 1),
      stringsAsFactors = FALSE)
  }
}

monthly_dt <- as.data.table(do.call(rbind, monthly_results))
fwrite(monthly_dt, "../data/bunching_10_monthly.csv")
cat(sprintf("Monthly estimates saved: %d months\n", nrow(monthly_dt)))

# Print key transition months
cat("\n=== Transition 1: Around Aug 2014 ===\n")
print(monthly_dt[year == 2014, .(year, month, bunching_ratio, n_99, n_101, n_total)])

cat("\n=== Transition 2: Around Jan 2021 ===\n")
print(monthly_dt[year %in% c(2020, 2021) & month %in% c(11,12,1,2,3),
                  .(year, month, bunching_ratio, n_99, n_101, n_total)])

cat("\n=== Transition 3: Around Jul 2022 ===\n")
print(monthly_dt[year == 2022, .(year, month, bunching_ratio, n_99, n_101, n_total)])

# Generate monthly event-study figure
library(ggplot2)

theme_apep <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold", size = 12),
        legend.position = "none")

p_monthly <- ggplot(monthly_dt, aes(x = date, y = bunching_ratio)) +
  geom_line(color = "#333333", linewidth = 0.5) +
  geom_point(size = 0.8, color = "#333333") +
  geom_vline(xintercept = as.Date("2014-08-01"), linetype = "dashed",
             color = "#D55E00", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2021-01-01"), linetype = "dashed",
             color = "#009E73", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2022-07-01"), linetype = "dashed",
             color = "#56B4E9", linewidth = 0.5) +
  annotate("text", x = as.Date("2014-08-01"), y = max(monthly_dt$bunching_ratio, na.rm = TRUE) * 0.95,
           label = "Surcharge\n(Aug 2014)", hjust = -0.1, size = 2.8, color = "#D55E00") +
  annotate("text", x = as.Date("2021-01-01"), y = max(monthly_dt$bunching_ratio, na.rm = TRUE) * 0.85,
           label = "Threshold\nraised\n(Jan 2021)", hjust = -0.1, size = 2.8, color = "#009E73") +
  annotate("text", x = as.Date("2022-07-01"), y = max(monthly_dt$bunching_ratio, na.rm = TRUE) * 0.75,
           label = "Surcharge\nabolished\n(Jul 2022)", hjust = -0.1, size = 2.8, color = "#56B4E9") +
  labs(
    title = "Monthly Bunching Ratio at 10 kWp, 2013-2024",
    subtitle = "Kleven-Waseem estimate, rooftop installations, polynomial degree 5",
    x = NULL,
    y = "Bunching Ratio (b)"
  ) +
  theme_apep

ggsave("../figures/fig8_monthly_event_study.pdf", p_monthly, width = 10, height = 5)
ggsave("../figures/fig8_monthly_event_study.png", p_monthly, width = 10, height = 5, dpi = 300)

cat("\nMonthly event study figure saved.\n")
