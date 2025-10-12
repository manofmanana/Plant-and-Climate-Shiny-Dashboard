# scripts/fetch_climate_openmeteo.R
# Fetch daily aggregated climate data from Open-Meteo for a set of lat/lon points
# Dependencies: httr, jsonlite, dplyr, purrr, lubridate

library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(lubridate)

openmeteo_daily_for_point <- function(lat, lon, start_date, end_date, timezone = "UTC") {
    base <- "https://archive-api.open-meteo.com/v1/archive"
    params <- list(
        latitude = lat,
        longitude = lon,
        start_date = start_date,
        end_date = end_date,
        timezone = timezone,
        daily = paste(c(
            "temperature_2m_max", "temperature_2m_min", "temperature_2m_mean",
            "precipitation_sum", "windspeed_10m_mean"
        ), collapse = ",")
    )
    res <- httr::GET(base, query = params)
    stop_for_status(res)
    json <- content(res, as = "text", encoding = "UTF-8")
    dat <- fromJSON(json, flatten = TRUE)
    if (is.null(dat$daily)) {
        return(NULL)
    }
    df <- as_tibble(dat$daily)
    # dat$daily typically has a 'time' column
    df <- df %>%
        mutate(date = as.Date(time), latitude = lat, longitude = lon, source = "Open-Meteo") %>%
        select(date, latitude, longitude, everything(), -time)
    df
}

fetch_climate <- function(points_df, start_date, end_date, out = "data/climate_data.csv") {
    rows <- pmap_dfr(
        list(points_df$latitude, points_df$longitude),
        function(lat, lon) {
            Sys.sleep(0.25)
            df <- tryCatch(openmeteo_daily_for_point(lat, lon, start_date, end_date),
                error = function(e) {
                    message("error fetching for ", lat, ",", lon, ": ", e$message)
                    NULL
                }
            )
            if (!is.null(df)) {
                df$id <- paste0("p_", gsub("\\.", "", sprintf("%.4f_%.4f", lat, lon)))
                df
            } else {
                tibble()
            }
        }
    )
    if (nrow(rows) == 0) stop("No climate rows retrieved.")
    write.csv(rows, out, row.names = FALSE)
    message("Wrote ", out, " (", nrow(rows), " rows).")
    invisible(rows)
}
