# R/data_load.R
# Load the plant observations and climate data shipped in data/.
#
# Everything here is deterministic and read-only: no random numbers and no
# files written at start-up. Refresh the CSVs with the scripts in scripts/.

#' Reduce GBIF names like "Monstera deliciosa Liebm." to "Monstera deliciosa".
clean_species <- function(x) {
    x <- trimws(x)
    # First "Genus species" pair anywhere in the string, e.g. it also finds the
    # binomial inside "ZZ plant (Zamioculcas zamiifolia)".
    m <- regmatches(x, regexpr("[A-Z][a-z]+ [a-z][a-z-]+", x))
    out <- x
    out[grepl("[A-Z][a-z]+ [a-z][a-z-]+", x)] <- m
    aliases <- c("ZZ plant" = "Zamioculcas zamiifolia")
    hit <- out %in% names(aliases)
    out[hit] <- aliases[out[hit]]
    out
}

#' Load all datasets.
#'
#' @param data_dir Directory holding the CSVs.
#' @return A list with:
#'   - `plants`: one row per GBIF observation with its 30-day climate summary,
#'     modeled growth index and Thriving/Stable category
#'   - `plant_climate`: daily weather for each plant's 30-day window
#'   - `sites`: daily weather for the reference climate sites
#'   - `air`: the sites averaged per day (global overview series)
#'   - `meta`: counts and date ranges for the UI
load_data <- function(data_dir = "data") {
    path <- function(name) file.path(data_dir, name)

    # --- Reference climate sites -------------------------------------------
    sites <- read.csv(path("climate_data.csv"), stringsAsFactors = FALSE)
    sites$date <- as.Date(sites$date)
    sites <- dplyr::rename(sites,
        Temperature = temperature_2m_mean,
        TempMax = temperature_2m_max,
        TempMin = temperature_2m_min,
        Precipitation = precipitation_sum,
        Wind = wind_speed_10m_mean,
        Humidity = relative_humidity_2m_mean,
        Radiation = shortwave_radiation_sum
    )

    # Daily average across sites. Precipitation is averaged too: summing rain
    # from sites on different continents isn't a meaningful quantity.
    air <- sites |>
        dplyr::group_by(date) |>
        dplyr::summarise(dplyr::across(
            c(Temperature, Precipitation, Wind, Humidity, Radiation),
            \(v) mean(v, na.rm = TRUE)
        ), .groups = "drop")

    # --- Per-plant climate windows -----------------------------------------
    plant_climate <- read.csv(path("plant_climate_daily.csv"), stringsAsFactors = FALSE)
    plant_climate$date <- as.Date(plant_climate$date)
    plant_climate <- dplyr::rename(plant_climate,
        Temperature = temperature_2m_mean,
        TempMax = temperature_2m_max,
        TempMin = temperature_2m_min,
        Precipitation = precipitation_sum,
        Wind = wind_speed_10m_mean,
        Humidity = relative_humidity_2m_mean,
        Radiation = shortwave_radiation_sum
    )
    climate_summary <- plant_climate |>
        dplyr::group_by(occurrence_id) |>
        dplyr::summarise(
            temperature = mean(Temperature, na.rm = TRUE),
            humidity = mean(Humidity, na.rm = TRUE),
            precipitation = sum(Precipitation, na.rm = TRUE),
            radiation = mean(Radiation, na.rm = TRUE),
            wind = mean(Wind, na.rm = TRUE),
            .groups = "drop"
        )

    # --- Plants --------------------------------------------------------------
    plants <- read.csv(path("indoor_plants.csv"), stringsAsFactors = FALSE)
    plants <- plants |>
        dplyr::transmute(
            occurrence_id,
            species = clean_species(species),
            obs_date = as.Date(substr(eventDate, 1, 10)),
            country,
            latitude = decimalLatitude,
            longitude = decimalLongitude,
            recorded_by = recordedBy,
            basis_of_record = basisOfRecord,
            dataset_key = datasetKey
        ) |>
        dplyr::left_join(climate_summary, by = "occurrence_id")

    profiles <- species_profile(plants$species)
    plants$common_name <- ifelse(is.na(profiles$common_name), plants$species, profiles$common_name)
    plants$growth_index <- growth_index(plants$species, plants$temperature, plants$humidity, plants$radiation)
    median_growth <- stats::median(plants$growth_index, na.rm = TRUE)
    plants$category <- ifelse(plants$growth_index >= median_growth, "Thriving", "Stable")
    plants$label <- sprintf(
        "%s · %s, %s", plants$common_name,
        ifelse(is.na(plants$country) | plants$country == "", "Unknown", plants$country),
        format(plants$obs_date, "%b %Y")
    )

    meta <- list(
        n_plants = nrow(plants),
        n_species = length(unique(plants$species)),
        n_sites = length(unique(sites$site_id)),
        n_countries = length(unique(stats::na.omit(plants$country))),
        plant_dates = range(plants$obs_date, na.rm = TRUE),
        climate_dates = range(sites$date, na.rm = TRUE),
        gbif_datasets = unique(stats::na.omit(plants$dataset_key))
    )

    list(plants = plants, plant_climate = plant_climate, sites = sites, air = air, meta = meta)
}
