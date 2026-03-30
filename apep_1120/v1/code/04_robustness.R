# apep_1120 - Romanian 2014 EU-2 Restriction Lifting
# 04_robustness.R - Placebos, jackknife, inference, sensitivity

source("code/00_packages.R")

data_dir <- "data"
results <- readRDS(file.path(data_dir, "main_results.rds"))
panel <- results$panel

# County crosswalk (needed for jackknife labels)
nuts3_county <- data.frame(
  geo = c("RO111","RO112","RO113","RO114","RO115","RO116",
          "RO121","RO122","RO123","RO124","RO125","RO126",
          "RO211","RO212","RO213","RO214","RO215","RO216",
          "RO221","RO222","RO223","RO224","RO225","RO226",
          "RO311","RO312","RO313","RO314","RO315","RO316","RO317",
          "RO321","RO322",
          "RO411","RO412","RO413","RO414","RO415",
          "RO421","RO422","RO423","RO424"),
  county = c("Bihor","Bistrita-Nasaud","Cluj","Maramures","Satu Mare","Salaj",
             "Alba","Brasov","Covasna","Harghita","Mures","Sibiu",
             "Bacau","Botosani","Iasi","Neamt","Suceava","Vaslui",
             "Braila","Buzau","Constanta","Galati","Tulcea","Vrancea",
             "Arges","Calarasi","Dambovita","Giurgiu","Ialomita","Prahova","Teleorman",
             "Bucuresti","Ilfov",
             "Dolj","Gorj","Mehedinti","Olt","Valcea",
             "Arad","Caras-Severin","Hunedoara","Timis"),
  stringsAsFactors = FALSE
)

# ============================================================
# 1. PLACEBO BREAK YEARS (2011, 2012)
# ============================================================
cat("=== PLACEBO BREAK YEARS ===\n")

# Restrict to pre-2014 data only
panel_pre <- panel %>% filter(year < 2014)

for (placebo_year in c(2011, 2012)) {
  panel_pre$placebo_post <- as.integer(panel_pre$year >= placebo_year)
  panel_pre$theta_x_placebo <- panel_pre$theta * panel_pre$placebo_post

  m_placebo <- feols(log_emp ~ theta_x_placebo | geo + year, data = panel_pre, cluster = ~geo)
  cat(sprintf("\nPlacebo break at %d: beta = %.4f (SE = %.4f, p = %.4f)\n",
              placebo_year,
              coef(m_placebo)["theta_x_placebo"],
              sqrt(vcov(m_placebo)["theta_x_placebo", "theta_x_placebo"]),
              summary(m_placebo)$coeftable["theta_x_placebo", "Pr(>|t|)"]))
}

# ============================================================
# 2. LEAVE-ONE-COUNTY-OUT JACKKNIFE
# ============================================================
cat("\n=== JACKKNIFE (Leave-one-county-out) ===\n")

counties <- unique(panel$geo)
jk_betas <- numeric(length(counties))

for (i in seq_along(counties)) {
  panel_jk <- panel[panel$geo != counties[i], ]
  m_jk <- feols(log_emp ~ theta_x_post | geo + year, data = panel_jk, cluster = ~geo)
  jk_betas[i] <- coef(m_jk)["theta_x_post"]
}

cat(sprintf("  Full sample beta: %.4f\n", coef(results$m1)["theta_x_post"]))
cat(sprintf("  Jackknife range: [%.4f, %.4f]\n", min(jk_betas), max(jk_betas)))
cat(sprintf("  Jackknife mean: %.4f, SD: %.4f\n", mean(jk_betas), sd(jk_betas)))

# Identify most influential county
max_influence_idx <- which.max(abs(jk_betas - coef(results$m1)["theta_x_post"]))
cat(sprintf("  Most influential county: %s (beta without = %.4f)\n",
            counties[max_influence_idx], jk_betas[max_influence_idx]))

# Create jackknife table
jk_df <- data.frame(
  geo = counties,
  county = nuts3_county$county[match(counties, nuts3_county$geo)],
  beta_without = jk_betas,
  influence = jk_betas - coef(results$m1)["theta_x_post"]
)
jk_df <- jk_df[order(abs(jk_df$influence), decreasing = TRUE), ]
cat("\n  Top 5 most influential:\n")
print(head(jk_df[, c("county", "beta_without", "influence")], 5))

# ============================================================
# 3. REMOVE BUCHAREST
# ============================================================
cat("\n=== REMOVE BUCHAREST ===\n")

panel_no_buc <- panel[panel$geo != "RO321", ]  # Bucuresti
m_no_buc <- feols(log_emp ~ theta_x_post | geo + year, data = panel_no_buc, cluster = ~geo)
cat(sprintf("  Without Bucharest: beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_no_buc)["theta_x_post"],
            sqrt(vcov(m_no_buc)["theta_x_post", "theta_x_post"]),
            summary(m_no_buc)$coeftable["theta_x_post", "Pr(>|t|)"]))

# ============================================================
# 4. REMOVE NW/WEST COUNTIES
# ============================================================
cat("\n=== REMOVE NW/WEST COUNTIES ===\n")

panel_no_west <- panel[panel$west == 0, ]
m_no_west <- feols(log_emp ~ theta_x_post | geo + year, data = panel_no_west, cluster = ~geo)
cat(sprintf("  Without NW/West: beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_no_west)["theta_x_post"],
            sqrt(vcov(m_no_west)["theta_x_post", "theta_x_post"]),
            summary(m_no_west)$coeftable["theta_x_post", "Pr(>|t|)"]))

# ============================================================
# 5. RANDOMIZATION INFERENCE
# ============================================================
cat("\n=== RANDOMIZATION INFERENCE ===\n")

set.seed(42)
n_perms <- 1000
true_beta <- coef(results$m1)["theta_x_post"]
perm_betas <- numeric(n_perms)

for (p in 1:n_perms) {
  # Permute theta across counties (keeping panel structure)
  perm_theta <- sample(unique(panel$theta))
  names(perm_theta) <- unique(panel$geo)
  panel_perm <- panel
  panel_perm$theta_perm <- perm_theta[panel_perm$geo]
  panel_perm$theta_x_post_perm <- panel_perm$theta_perm * panel_perm$post

  m_perm <- feols(log_emp ~ theta_x_post_perm | geo + year, data = panel_perm)
  perm_betas[p] <- coef(m_perm)["theta_x_post_perm"]
}

ri_pvalue <- mean(abs(perm_betas) >= abs(true_beta))
cat(sprintf("  True beta: %.4f\n", true_beta))
cat(sprintf("  RI p-value (two-sided): %.4f (from %d permutations)\n", ri_pvalue, n_perms))
cat(sprintf("  Permutation distribution: mean = %.4f, SD = %.4f\n",
            mean(perm_betas), sd(perm_betas)))

# ============================================================
# 6. POPULATION EVENT STUDY
# ============================================================
cat("\n=== POPULATION EVENT STUDY ===\n")

panel$year_f <- factor(panel$year)
panel$year_f <- relevel(panel$year_f, ref = "2013")

m_pop_es <- feols(log_pop ~ i(year_f, theta, ref = "2013") | geo + year, data = panel, cluster = ~geo)
cat("Population event study coefficients:\n")
print(summary(m_pop_es)$coeftable)

# ============================================================
# Save robustness results
# ============================================================
robustness <- list(
  placebo_2011 = feols(log_emp ~ theta_x_placebo | geo + year,
                        data = panel_pre %>% mutate(placebo_post = as.integer(year >= 2011),
                                                     theta_x_placebo = theta * placebo_post),
                        cluster = ~geo),
  placebo_2012 = feols(log_emp ~ theta_x_placebo | geo + year,
                        data = panel_pre %>% mutate(placebo_post = as.integer(year >= 2012),
                                                     theta_x_placebo = theta * placebo_post),
                        cluster = ~geo),
  no_bucharest = m_no_buc,
  no_west = m_no_west,
  jackknife_betas = jk_betas,
  jackknife_counties = counties,
  ri_pvalue = ri_pvalue,
  ri_betas = perm_betas
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness analysis complete.\n")
