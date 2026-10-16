# R/growth_model.R
# A transparent, deterministic *modeled* growth index.
#
# The GBIF occurrence data says where and when a plant was seen, but nothing
# about how fast it grew. Instead of inventing random growth numbers, we score
# how favourable the real weather (Open-Meteo, 30 days before the observation)
# was for that species, using commonly cited houseplant care ranges:
#
#   growth_index = 100 * temp_score^0.5 * humidity_score^0.3 * light_score^0.2
#
# Each score is 1 inside the species' ideal range and falls linearly to 0 at
# `temp_tolerance` degC / `humidity_tolerance` %RH outside it. It's an
# illustrative model, not a measurement, and the UI labels it that way.

species_profiles <- data.frame(
    species = c(
        "Monstera deliciosa", "Epipremnum aureum", "Spathiphyllum wallisii",
        "Calathea orbifolia", "Dracaena fragrans", "Ficus lyrata",
        "Philodendron hederaceum", "Sansevieria trifasciata", "Zamioculcas zamiifolia"
    ),
    common_name = c(
        "Monstera", "Golden pothos", "Peace lily", "Calathea", "Corn plant",
        "Fiddle-leaf fig", "Heartleaf philodendron", "Snake plant", "ZZ plant"
    ),
    temp_min = c(20, 18, 18, 18, 18, 18, 18, 18, 18),
    temp_max = c(29, 29, 27, 24, 27, 27, 27, 30, 26),
    humidity_min = c(60, 40, 50, 60, 40, 40, 50, 30, 40),
    humidity_max = c(80, 70, 80, 80, 60, 65, 80, 50, 60),
    stringsAsFactors = FALSE
)

default_profile <- data.frame(
    species = NA_character_, common_name = NA_character_,
    temp_min = 18, temp_max = 27, humidity_min = 40, humidity_max = 70
)

temp_tolerance <- 10
humidity_tolerance <- 35
# Daily shortwave radiation (MJ/m2) at which light stops being limiting.
light_saturation <- 15

#' Score in [0, 1]: 1 inside [lo, hi], linear fall-off over `tol` outside.
range_score <- function(x, lo, hi, tol) {
    below <- pmax(lo - x, 0)
    above <- pmax(x - hi, 0)
    score <- 1 - (below + above) / tol
    pmin(pmax(score, 0), 1)
}

#' Look up care ranges for each species (falls back to a generic profile).
species_profile <- function(species) {
    idx <- match(species, species_profiles$species)
    prof <- species_profiles[idx, , drop = FALSE]
    missing <- is.na(idx)
    if (any(missing)) {
        for (col in c("temp_min", "temp_max", "humidity_min", "humidity_max")) {
            prof[[col]][missing] <- default_profile[[col]]
        }
    }
    rownames(prof) <- NULL
    prof
}

#' Modeled growth index (0-100) from 30-day mean conditions.
growth_index <- function(species, temperature, humidity, radiation) {
    prof <- species_profile(species)
    t_score <- range_score(temperature, prof$temp_min, prof$temp_max, temp_tolerance)
    h_score <- range_score(humidity, prof$humidity_min, prof$humidity_max, humidity_tolerance)
    l_score <- pmin(pmax(radiation / light_saturation, 0), 1)
    idx <- 100 * t_score^0.5 * h_score^0.3 * l_score^0.2
    round(idx, 1)
}
