# scripts/fetch_climate_openmeteo.R
# Fetch daily climate from the Open-Meteo historical archive (free, no API key).
#
#   fetch_site_climate()  -> data/climate_data.csv
#       Long daily series for the reference sites in data/points_for_climate.csv
#       (used by the Climate Explorer's "All sites" views).
#   fetch_plant_climate() -> data/plant_climate_daily.csv
#       The 30 days of weather at each plant's location leading up to the date it
#       was observed (used for per-plant climate and the modeled growth index).
#
# Usage (from the project root):
#   source("scripts/fetch_climate_openmeteo.R")
#   fetch_site_climate()
#   fetch_plant_climate()
#
# Dependencies: jsonlite, dplyr

library(jsonlite)
library(dplyr)

OPENMETEO_URL <- "https://archive-api.open-meteo.com/v1/archive"
OPENMETEO_VARS <- c(
    "temperature_2m_mean", "temperature_2m_max", "temperature_2m_min",
    "precipitation_sum", "wind_speed_10m_mean", "relative_humidity_2m_mean",
    "shortwave_radiation_sum"
)

#' Daily climate for one location and date range.
openmeteo_daily <- function(lat, lon, start_date, end_date, retries = 5) {
    url <- sprintf(
        "%s?latitude=%.5f&longitude=%.5f&start_date=%s&end_date=%s&daily=%s&timezone=UTC",
        OPENMETEO_URL, lat, lon, start_date, end_date, paste(OPENMETEO_VARS, collapse = ",")
    )
    for (attempt in seq_len(retries)) {
        res <- tryCatch(jsonlite::fromJSON(url), error = function(e) e)
        if (!inherits(res, "error")) break
        message("  retry ", attempt, " for ", lat, ",", lon, ": ", conditionMessage(res))
        Sys.sleep(20 * attempt) # the archive API limits requests per minute, weighted by span
    }
    if (inherits(res, "error") || is.null(res$daily)) {
        return(NULL)
    }
    daily <- as.data.frame(res$daily, stringsAsFactors = FALSE)
    daily$date <- as.Date(daily$time)
    daily$time <- NULL
    daily$latitude <- lat
    daily$longitude <- lon
    daily[, c("date", "latitude", "longitude", OPENMETEO_VARS)]
}

site_id <- function(lat, lon) sprintf("site_%.3f_%.3f", lat, lon)

#' Long daily series for each reference site.
fetch_site_climate <- function(points_csv = "data/points_for_climate.csv",
                               start_date = "2021-01-01",
                               end_date = Sys.Date() - 7,
                               out = "data/climate_data.csv") {
    pts <- read.csv(points_csv)
    rows <- lapply(seq_len(nrow(pts)), function(i) {
        message(sprintf("[%d/%d] site %.3f, %.3f", i, nrow(pts), pts$latitude[i], pts$longitude[i]))
        Sys.sleep(0.3)
        df <- openmeteo_daily(pts$latitude[i], pts$longitude[i], start_date, end_date)
        if (!is.null(df)) df$site_id <- site_id(pts$latitude[i], pts$longitude[i])
        df
    })
    out_df <- dplyr::bind_rows(rows)
    if (nrow(out_df) == 0) stop("No climate rows retrieved.")
    n_missing <- nrow(pts) - length(unique(out_df$site_id))
    if (n_missing > 0) warning(n_missing, " of ", nrow(pts), " sites failed to download; rerun to fill them in.")
    write.csv(out_df, out, row.names = FALSE)
    message("Wrote ", out, " (", nrow(out_df), " rows, ", length(unique(out_df$site_id)), " sites).")
    invisible(out_df)
}

#' Weather at each plant's location for the `window_days` before it was observed.
fetch_plant_climate <- function(plants_csv = "data/indoor_plants.csv",
                                window_days = 30,
                                out = "data/plant_climate_daily.csv") {
    plants <- read.csv(plants_csv, stringsAsFactors = FALSE)
    plants$obs_date <- as.Date(substr(plants$eventDate, 1, 10))
    plants <- plants[!is.na(plants$obs_date) & !is.na(plants$decimalLatitude), ]
    rows <- lapply(seq_len(nrow(plants)), function(i) {
        p <- plants[i, ]
        if (i %% 25 == 1) message(sprintf("[%d/%d] plants", i, nrow(plants)))
        Sys.sleep(0.15)
        df <- openmeteo_daily(
            p$decimalLatitude, p$decimalLongitude,
            format(p$obs_date - (window_days - 1)), format(p$obs_date)
        )
        if (is.null(df)) {
            message("  no data for ", p$occurrence_id)
            return(NULL)
        }
        df$occurrence_id <- p$occurrence_id
        df
    })
    out_df <- dplyr::bind_rows(rows)
    if (nrow(out_df) == 0) stop("No plant climate rows retrieved.")
    out_df <- out_df[, c("occurrence_id", setdiff(names(out_df), "occurrence_id"))]
    write.csv(out_df, out, row.names = FALSE)
    message("Wrote ", out, " (", nrow(out_df), " rows, ", length(unique(out_df$occurrence_id)), " plants).")
    invisible(out_df)
}
