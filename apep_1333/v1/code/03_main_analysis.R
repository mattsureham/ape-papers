# 03_main_analysis.R — Main DiD estimates for MPA effects on kelp forest fish
# Treatment: Central Coast MLPA (Sept 2007) — NAPL, IVEE vs 7 control sites

setwd(here::here())
source("code/00_packages.R")

panel <- readRDS("data/panel_main.rds")
panel_spp <- readRDS("data/panel_spp_main.rds")

# ========================================================================
# TABLE 1: Summary Statistics
# ========================================================================
cat("\n=== TABLE 1: Summary Statistics ===\n")

# Pre-treatment means
pre <- panel[YEAR < 2008]
post <- panel[YEAR >= 2008]

sumstats <- rbind(
  pre[mpa == 1, .(period = "Pre-MPA", group = "MPA sites",
                   mean_density = mean(fish_density), sd_density = sd(fish_density),
                   mean_richness = mean(species_richness), sd_richness = sd(species_richness),
                   mean_targeted = mean(targeted_density), sd_targeted = sd(targeted_density),
                   mean_nontargeted = mean(nontargeted_density), sd_nontargeted = sd(nontargeted_density),
                   n = .N)],
  pre[mpa == 0, .(period = "Pre-MPA", group = "Control sites",
                   mean_density = mean(fish_density), sd_density = sd(fish_density),
                   mean_richness = mean(species_richness), sd_richness = sd(species_richness),
                   mean_targeted = mean(targeted_density), sd_targeted = sd(targeted_density),
                   mean_nontargeted = mean(nontargeted_density), sd_nontargeted = sd(nontargeted_density),
                   n = .N)],
  post[mpa == 1, .(period = "Post-MPA", group = "MPA sites",
                    mean_density = mean(fish_density), sd_density = sd(fish_density),
                    mean_richness = mean(species_richness), sd_richness = sd(species_richness),
                    mean_targeted = mean(targeted_density), sd_targeted = sd(targeted_density),
                    mean_nontargeted = mean(nontargeted_density), sd_nontargeted = sd(nontargeted_density),
                    n = .N)],
  post[mpa == 0, .(period = "Post-MPA", group = "Control sites",
                    mean_density = mean(fish_density), sd_density = sd(fish_density),
                    mean_richness = mean(species_richness), sd_richness = sd(species_richness),
                    mean_targeted = mean(targeted_density), sd_targeted = sd(targeted_density),
                    mean_nontargeted = mean(nontargeted_density), sd_nontargeted = sd(nontargeted_density),
                    n = .N)]
)
saveRDS(sumstats, "data/sumstats.rds")
print(sumstats)

# ========================================================================
# TABLE 2: Main DiD Estimates (site × year panel)
# ========================================================================
cat("\n=== TABLE 2: Main DiD ===\n")

# (1) Log total fish density
m1 <- feols(log_density ~ treated | SITE + YEAR, data = panel,
            cluster = ~SITE)

# (2) Log targeted fish density
m2 <- feols(log_targeted ~ treated | SITE + YEAR, data = panel,
            cluster = ~SITE)

# (3) Log non-targeted fish density (PLACEBO — should be null)
m3 <- feols(log_nontargeted ~ treated | SITE + YEAR, data = panel,
            cluster = ~SITE)

# (4) Species richness
m4 <- feols(species_richness ~ treated | SITE + YEAR, data = panel,
            cluster = ~SITE)

etable(m1, m2, m3, m4,
       headers = c("All Fish", "Targeted", "Non-Targeted", "Richness"))

# Save regression objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4), "data/main_models.rds")

# ========================================================================
# TABLE 3: Event Study (pre-trend test)
# ========================================================================
cat("\n=== TABLE 3: Event Study ===\n")

panel[, rel_year := YEAR - 2007]
# Use 2007 (year -1, rel_year = 0) as omitted category since treatment was Sept 2007
# rel_year < 0 = pre, rel_year >= 1 = post
panel[, rel_year_fac := factor(rel_year)]
# Omit rel_year = 0 (2007) as reference
panel[, rel_year_fac := relevel(rel_year_fac, ref = "0")]

# Bin endpoints at -6 and +17
panel[, rel_year_binned := pmax(-6, pmin(17, rel_year))]
panel[, rel_year_bin_fac := factor(rel_year_binned)]
panel[, rel_year_bin_fac := relevel(rel_year_bin_fac, ref = "0")]

# Event study for targeted fish
es_targeted <- feols(log_targeted ~ i(rel_year_binned, mpa, ref = 0) | SITE + YEAR,
                     data = panel, cluster = ~SITE)

# Event study for all fish
es_all <- feols(log_density ~ i(rel_year_binned, mpa, ref = 0) | SITE + YEAR,
                data = panel, cluster = ~SITE)

# Event study for non-targeted (placebo)
es_nontarget <- feols(log_nontargeted ~ i(rel_year_binned, mpa, ref = 0) | SITE + YEAR,
                      data = panel, cluster = ~SITE)

saveRDS(list(es_targeted = es_targeted, es_all = es_all,
             es_nontarget = es_nontarget), "data/event_study_models.rds")

cat("\nEvent study — targeted fish:\n")
summary(es_targeted)

# ========================================================================
# Pre-trend test: joint F-test on pre-treatment coefficients
# ========================================================================
cat("\n=== Pre-Trend F-Test ===\n")
# Test that all pre-treatment coefficients are jointly zero
pre_coefs_targeted <- grep("rel_year_binned::-[0-9]", names(coef(es_targeted)), value = TRUE)
if (length(pre_coefs_targeted) > 0) {
  pre_test <- wald(es_targeted, pre_coefs_targeted)
  cat("Pre-trend F-test (targeted):", pre_test$stat, "p-value:", pre_test$p, "\n")
}

pre_coefs_all <- grep("rel_year_binned::-[0-9]", names(coef(es_all)), value = TRUE)
if (length(pre_coefs_all) > 0) {
  pre_test_all <- wald(es_all, pre_coefs_all)
  cat("Pre-trend F-test (all fish):", pre_test_all$stat, "p-value:", pre_test_all$p, "\n")
}

# ========================================================================
# Write diagnostics.json for validation
# ========================================================================
# Diagnostics reflect the species-level DDD (primary specification)
# where treated units are site-species pairs for targeted species at MPA sites
spp_panel <- panel_spp[mpa_status == "MPA_mainland" & targeted == 1]
diag <- list(
  n_treated = uniqueN(paste(spp_panel$SITE, spp_panel$SP_CODE)),
  n_pre = sum(unique(panel$YEAR) < 2008),
  n_obs = nrow(panel_spp),
  n_control = uniqueN(panel[mpa == 0]$SITE),
  n_years = uniqueN(panel$YEAR),
  n_species = uniqueN(panel_spp$SP_CODE),
  treatment_year = 2007,
  n_sites_treated = 2,
  n_sites_control = 7
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")
