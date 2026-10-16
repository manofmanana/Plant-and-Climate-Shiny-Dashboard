# scripts/build_data.R
# Rebuild everything in data/ from the public sources. Run from the project root:
#
#   Rscript scripts/build_data.R            # refresh climate only (keeps current plants)
#   Rscript scripts/build_data.R --plants   # also re-download plant observations from GBIF
#
# Takes a few minutes; Open-Meteo is free but rate-limited, so requests are spaced out.

args <- commandArgs(trailingOnly = TRUE)

if ("--plants" %in% args) {
    source("scripts/fetch_plants_gbif.R")
    fetch_plants(c(
        "Monstera deliciosa", "Epipremnum aureum", "Spathiphyllum wallisii",
        "Calathea orbifolia", "Dracaena fragrans", "Ficus lyrata",
        "Philodendron hederaceum", "Sansevieria trifasciata", "Zamioculcas zamiifolia"
    ), per_species = 80)
}

source("scripts/fetch_climate_openmeteo.R")
end_date <- Sys.Date() - 7 # the archive lags real time by a few days
fetch_site_climate(end_date = end_date)
fetch_plant_climate()
