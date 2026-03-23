## 02_clean_data.R — Construct analysis panel
## apep_0841: Poland 500+ and Female Labor Supply

source("00_packages.R")

cat("=== Constructing analysis panel ===\n")

# ─── Load fetched data ──────────────────────────────────────────────────────
emp   <- readRDS("../data/employment_f.rds")
emp_m <- readRDS("../data/employment_m.rds")
fert  <- readRDS("../data/fertility.rds")
gdp   <- readRDS("../data/gdp.rds")
pop   <- readRDS("../data/population.rds")

# ─── Construct treatment intensity ──────────────────────────────────────────
# Treatment intensity = inverse TFR (lower TFR → more one-child families → more treated)
# Use pre-treatment average (2017–2018) to avoid endogeneity

fert_pre <- fert[fert$year %in% 2017:2018, ]
ti <- aggregate(tfr ~ nuts2, data = fert_pre, FUN = mean, na.rm = TRUE)
names(ti)[2] <- "tfr_pre"

# Inverse TFR as treatment intensity (higher = more one-child families)
# Standardize to mean 0, SD 1 for interpretability
ti$treat_intensity <- -1 * ti$tfr_pre  # negate so higher = more one-child families
ti$treat_intensity_std <- (ti$treat_intensity - mean(ti$treat_intensity, na.rm = TRUE)) /
                           sd(ti$treat_intensity, na.rm = TRUE)

cat(sprintf("Treatment intensity constructed for %d regions\n", nrow(ti)))
cat(sprintf("  Polish TFR range (2017-18): %.2f to %.2f\n",
            min(ti$tfr_pre[substr(ti$nuts2, 1, 2) == "PL"], na.rm = TRUE),
            max(ti$tfr_pre[substr(ti$nuts2, 1, 2) == "PL"], na.rm = TRUE)))

# ─── Merge into analysis panel ─────────────────────────────────────────────
panel <- merge(emp, emp_m, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, ti[, c("nuts2", "tfr_pre", "treat_intensity_std")],
               by = "nuts2", all.x = TRUE)
panel <- merge(panel, gdp, by = c("nuts2", "year"), all.x = TRUE)
panel <- merge(panel, pop, by = c("nuts2", "year"), all.x = TRUE)

# ─── Construct variables ────────────────────────────────────────────────────
panel$country <- substr(panel$nuts2, 1, 2)
panel$poland  <- as.integer(panel$country == "PL")
panel$post2019 <- as.integer(panel$year >= 2019)

# Interaction terms
panel$poland_post <- panel$poland * panel$post2019
panel$intensity_post <- panel$treat_intensity_std * panel$post2019
panel$poland_intensity_post <- panel$poland * panel$treat_intensity_std * panel$post2019

# Event time for event study
panel$event_time <- panel$year - 2019

# Drop observations with missing employment data
panel <- panel[!is.na(panel$emp_rate_f), ]

# ─── Summary statistics ────────────────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("Regions: %d (Poland: %d, CEE controls: %d)\n",
            length(unique(panel$nuts2)),
            sum(unique(panel$country[panel$poland == 1]) == "PL") *
              length(unique(panel$nuts2[panel$poland == 1])),
            length(unique(panel$nuts2[panel$poland == 0]))))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))

# Summary by country
cat("\nCountry-level summary:\n")
for (cc in sort(unique(panel$country))) {
  sub <- panel[panel$country == cc, ]
  cat(sprintf("  %s: %d regions, %d obs, emp_rate_f mean=%.1f%%\n",
              cc, length(unique(sub$nuts2)), nrow(sub),
              mean(sub$emp_rate_f, na.rm = TRUE)))
}

# Pre/post summary for Poland
pl_pre  <- panel[panel$poland == 1 & panel$post2019 == 0, ]
pl_post <- panel[panel$poland == 1 & panel$post2019 == 1, ]
cat(sprintf("\nPoland pre-2019 female emp rate:  %.1f%% (SD=%.1f)\n",
            mean(pl_pre$emp_rate_f, na.rm = TRUE),
            sd(pl_pre$emp_rate_f, na.rm = TRUE)))
cat(sprintf("Poland post-2019 female emp rate: %.1f%% (SD=%.1f)\n",
            mean(pl_post$emp_rate_f, na.rm = TRUE),
            sd(pl_post$emp_rate_f, na.rm = TRUE)))

# ─── Save analysis panel ────────────────────────────────────────────────────
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nPanel saved to data/analysis_panel.rds\n")

# Also save a CSV for transparency
write.csv(panel, "../data/analysis_panel.csv", row.names = FALSE)
cat("Panel also saved as CSV for replication.\n")
