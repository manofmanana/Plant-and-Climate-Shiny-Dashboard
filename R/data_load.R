# R/data_load.R
# Purpose: Load and clean plant & climate data

library(tidyverse)
library(lubridate)

# Load real CSVs created by the fetch scripts. If they are not present,
# fall back to small synthetic examples so the app still runs.
load_data <- function() {
    # --- Climate / air ---
    climate_path <- "data/climate_data.csv"
    if (file.exists(climate_path)) {
        clim <- read.csv(climate_path, stringsAsFactors = FALSE)
        # ensure date column
        if ("date" %in% names(clim)) clim$date <- as.Date(clim$date)
        # normalize column names used by the app
        clim <- clim %>%
            rename(
                Temperature = temperature_2m_mean,
                Precipitation = precipitation_sum,
                Wind = windspeed_10m_mean
            ) %>%
            group_by(date) %>%
            summarise(
                Temperature = mean(Temperature, na.rm = TRUE),
                Precipitation = sum(Precipitation, na.rm = TRUE),
                Wind = mean(Wind, na.rm = TRUE)
            ) %>%
            ungroup()
        air <- clim
    } else {
        # fallback: small built-in example (keeps original shape expectations)
        air <- airquality %>%
            drop_na() %>%
            rename(Temperature = Temp)
        air$Precipitation <- air$Solar.R %>% replace_na(0)
        air$Wind <- air$Wind
    }

    # --- Plants ---
    plants_path <- "data/indoor_plants.csv"
    plants_with_climate_path <- "data/indoor_plants_with_climate.csv"

    # If a per-plant joined file exists, prefer it — it contains matched climate features
    plants_climate <- NULL
    if (file.exists(plants_with_climate_path)) {
        ptsc <- read.csv(plants_with_climate_path, stringsAsFactors = FALSE, check.names = FALSE)
        # If the file was accidentally written transposed or has placeholder V1..Vn names
        # try to recover by transposing it: some exports create a very wide file where
        # rows became columns. Heuristic: all column names are V# and there are many columns.
        if (all(grepl("^V[0-9]+$", names(ptsc))) && ncol(ptsc) > 50 && nrow(ptsc) <= 100) {
            raw <- read.csv(plants_with_climate_path, header = FALSE, stringsAsFactors = FALSE, check.names = FALSE)
            tdf <- as.data.frame(t(raw), stringsAsFactors = FALSE)
            # If the first row looks like a header (non-empty strings), use it as names
            first_row <- as.character(tdf[1, ])
            if (any(nzchar(first_row))) {
                names(tdf) <- make.names(first_row, unique = TRUE)
                ptsc <- tdf[-1, , drop = FALSE]
                rownames(ptsc) <- NULL
            } else {
                ptsc <- tdf
                rownames(ptsc) <- NULL
            }
        }
        # defensive: try to detect common plant columns
        if ("eventDate" %in% names(ptsc)) ptsc$eventDate <- as.Date(substr(ptsc$eventDate, 1, 10))
        if (!"plant_id" %in% names(ptsc)) ptsc$plant_id <- seq_len(nrow(ptsc))
        # detect climate-like columns and normalize names onto plant rows
        nm <- names(ptsc)
        find_col <- function(patterns) {
            idx <- which(tolower(nm) %in% tolower(patterns) | grepl(paste(patterns, collapse = "|"), tolower(nm)))
            if (length(idx) > 0) {
                return(nm[idx[1]])
            }
            return(NA_character_)
        }
        temp_col <- find_col(c("temperature", "temperature_2m_mean", "temp"))
        prec_col <- find_col(c("precipitation", "precipitation_sum", "precip"))
        wind_col <- find_col(c("windspeed", "windspeed_10m_mean", "wind"))

        if (!is.na(temp_col)) ptsc$Temperature <- as.numeric(as.character(ptsc[[temp_col]]))
        if (!is.na(prec_col)) ptsc$Precipitation <- as.numeric(as.character(ptsc[[prec_col]]))
        if (!is.na(wind_col)) ptsc$Wind <- as.numeric(as.character(ptsc[[wind_col]]))

        # If we couldn't detect any climate columns, attempt a best-effort recovery
        climate_detected <- any(c("Temperature", "Precipitation", "Wind") %in% names(ptsc))
        if (!climate_detected) {
            # Best-effort: try to read and transpose the raw CSV and heuristically
            # identify date / numeric columns that look like climate time series.
            try_recover <- try(
                {
                    raw <- read.csv(plants_with_climate_path, header = FALSE, stringsAsFactors = FALSE, check.names = FALSE)
                    tdf <- as.data.frame(t(raw), stringsAsFactors = FALSE)
                    # If the first row looks like a header, use it
                    first_row <- as.character(tdf[1, ])
                    if (sum(nzchar(first_row)) > ncol(tdf) / 4) {
                        names(tdf) <- make.names(first_row, unique = TRUE)
                        tdf <- tdf[-1, , drop = FALSE]
                        rownames(tdf) <- NULL
                    }
                    # helper: proportion of parseable dates in a column
                    prop_date <- function(x) {
                        xch <- as.character(x)
                        parsed <- suppressWarnings(as.Date(substr(xch, 1, 10)))
                        mean(!is.na(parsed))
                    }
                    # helper: proportion numeric
                    prop_num <- function(x) {
                        xch <- as.character(x)
                        suppressWarnings(num <- as.numeric(xch))
                        mean(!is.na(num))
                    }
                    # detect date-like column (highest prop_date > 0.5)
                    date_scores <- sapply(tdf, prop_date)
                    date_col <- ifelse(max(date_scores, na.rm = TRUE) > 0.5, names(date_scores)[which.max(date_scores)], NA_character_)
                    # detect numeric columns (prop_num > 0.5)
                    num_scores <- sapply(tdf, prop_num)
                    numeric_candidates <- names(num_scores)[which(num_scores > 0.5)]
                    # If names contain obvious clues, prefer them
                    temp_guess <- intersect(tolower(names(tdf)), c("temperature", "temperature_2m_mean", "temp"))
                    prec_guess <- intersect(tolower(names(tdf)), c("precipitation", "precipitation_sum", "precip"))
                    wind_guess <- intersect(tolower(names(tdf)), c("windspeed", "windspeed_10m_mean", "wind"))
                    # assign climate columns
                    assigned <- list()
                    if (length(temp_guess) > 0) assigned$Temperature <- as.numeric(as.character(tdf[[temp_guess[1]]]))
                    if (length(prec_guess) > 0) assigned$Precipitation <- as.numeric(as.character(tdf[[prec_guess[1]]]))
                    if (length(wind_guess) > 0) assigned$Wind <- as.numeric(as.character(tdf[[wind_guess[1]]]))
                    # if we still miss columns, take top numeric candidates by variance
                    if (!"Temperature" %in% names(assigned) && length(numeric_candidates) >= 1) {
                        assigned$Temperature <- as.numeric(as.character(tdf[[numeric_candidates[1]]]))
                    }
                    if (!"Precipitation" %in% names(assigned) && length(numeric_candidates) >= 2) {
                        assigned$Precipitation <- as.numeric(as.character(tdf[[numeric_candidates[2]]]))
                    }
                    if (!"Wind" %in% names(assigned) && length(numeric_candidates) >= 3) {
                        assigned$Wind <- as.numeric(as.character(tdf[[numeric_candidates[3]]]))
                    }
                    # add detected eventDate if available
                    if (!is.na(date_col) && nzchar(date_col)) {
                        assigned$eventDate <- as.Date(substr(as.character(tdf[[date_col]]), 1, 10))
                    }
                    # bring together into a recovered tibble
                    recovered <- tibble::as_tibble(tdf)
                    # attach assigned columns (overwrite if present)
                    for (nm in names(assigned)) recovered[[nm]] <- assigned[[nm]]
                    # ensure plant_id exists
                    if (!"plant_id" %in% names(recovered)) recovered$plant_id <- seq_len(nrow(recovered))
                    # write backup fixed CSV so user can inspect/review
                    try(write.csv(recovered, file = file.path("data", "indoor_plants_with_climate_fixed.csv"), row.names = FALSE), silent = TRUE)
                    recovered
                },
                silent = TRUE
            )

            if (!inherits(try_recover, "try-error") && !is.null(try_recover)) {
                plants_climate <- try_recover
            } else {
                # mark as malformed so caller/UI can show a friendly message
                attr(ptsc, "malformed") <- TRUE
                plants_climate <- NULL
            }
        } else {
            plants_climate <- ptsc
        }
    }

    if (file.exists(plants_path)) {
        pts <- read.csv(plants_path, stringsAsFactors = FALSE)
        # parse eventDate to date
        if ("eventDate" %in% names(pts)) pts$eventDate <- as.Date(substr(pts$eventDate, 1, 10))
        # ensure growth_rate and humidity exist (simulate if missing)
        if (!"growth_rate" %in% names(pts)) pts$growth_rate <- runif(nrow(pts), 0.1, 1.5)
        if (!"humidity" %in% names(pts)) pts$humidity <- runif(nrow(pts), 30, 90)
        # add plant_id if missing
        if (!"plant_id" %in% names(pts)) pts$plant_id <- seq_len(nrow(pts))
        plants <- pts
    } else {
        set.seed(123)
        plants <- tibble::tibble(
            plant_id = 1:50,
            species = sample(c("Monstera", "Pothos", "Snake Plant", "Peace Lily"), 50, TRUE),
            light = runif(50, 100, 1000),
            humidity = runif(50, 30, 90),
            growth_rate = runif(50, 0.1, 1.5),
            decimalLatitude = runif(50, 34, 42),
            decimalLongitude = runif(50, -120, -70),
            eventDate = sample(seq.Date(as.Date("2021-01-01"), as.Date("2021-12-31"), by = "day"), 50, replace = TRUE)
        )
    }

    # If we couldn't recover a proper plants_climate from the joined CSV,
    # derive per-plant climate by joining plants -> air on date (eventDate -> date).
    if (is.null(plants_climate) && exists("air") && !is.null(air) && nrow(air) > 0) {
        # only join if plants have eventDate
        if ("eventDate" %in% names(plants)) {
            joined <- plants %>% dplyr::left_join(air, by = c("eventDate" = "date"))
            # keep a compact set for plants_climate: plant metadata + the climate cols
            keep_cols <- intersect(c(names(plants), "Temperature", "Precipitation", "Wind"), names(joined))
            plants_climate <- joined %>% dplyr::select(dplyr::any_of(keep_cols))
            # write a generated CSV so user can inspect it
            try(write.csv(plants_climate, file = file.path("data", "indoor_plants_with_climate_generated.csv"), row.names = FALSE), silent = TRUE)
        }
    }

    # provenance / metadata
    meta <- list(
        n_air = ifelse(exists("air") && !is.null(air), nrow(air), 0),
        n_plants = ifelse(exists("plants") && !is.null(plants), nrow(plants), 0),
        n_plants_with_climate = ifelse(!is.null(plants_climate), nrow(plants_climate), 0),
        gbif_datasets = NA_character_,
        openmeteo = ifelse(file.exists(climate_path), "Open-Meteo (historical daily)", NA_character_)
    )

    # try to extract GBIF dataset keys if present in plants file
    if (file.exists(plants_path)) {
        pts_keys <- read.csv(plants_path, nrows = 100, stringsAsFactors = FALSE)
        key_col <- intersect(c("datasetKey", "dataset_key", "datasetkey"), names(pts_keys))
        if (length(key_col) > 0) meta$gbif_datasets <- unique(pts_keys[[key_col[1]]])
    }

    list(air = air, plants = plants, plants_climate = plants_climate, meta = meta)
}
