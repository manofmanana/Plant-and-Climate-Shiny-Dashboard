# scripts/fetch_plants_gbif.R
# Fetch occurrence records from GBIF for a list of species and write data/indoor_plants.csv
# Minimal dependencies: rgbif, dplyr, lubridate

library(rgbif)
library(dplyr)
library(lubridate)

fetch_plants <- function(species_vec, per_species = 100, out = "data/indoor_plants.csv", country = NULL, year = NULL) {
    rows <- list()
    for (sp in species_vec) {
        message("Querying GBIF for ", sp)
        occ <- tryCatch(
            occ_search(scientificName = sp, hasCoordinate = TRUE, limit = per_species, country = country, year = year),
            error = function(e) {
                message("GBIF query error for ", sp, ": ", e$message)
                return(NULL)
            }
        )
        if (!is.null(occ) && !is.null(occ$data) && nrow(occ$data) > 0) {
            # ensure expected columns exist (fill with NA if missing)
            expected_cols <- c("key", "scientificName", "genus", "eventDate", "year", "country", "decimalLatitude", "decimalLongitude", "basisOfRecord", "datasetKey", "elevation", "recordedBy", "institutionCode", "occurrenceRemarks")
            for (col in expected_cols) {
                if (!(col %in% names(occ$data))) occ$data[[col]] <- NA
            }
            df <- occ$data %>%
                transmute(
                    occurrence_id = paste0("gbif_", .data$key),
                    species = .data$scientificName,
                    genus = .data$genus,
                    eventDate = as.character(.data$eventDate),
                    year = .data$year,
                    country = .data$country, # GBIF's country field is often named 'country'
                    decimalLatitude = .data$decimalLatitude,
                    decimalLongitude = .data$decimalLongitude,
                    basisOfRecord = .data$basisOfRecord,
                    datasetKey = .data$datasetKey,
                    elevation = .data$elevation,
                    recordedBy = .data$recordedBy,
                    institutionCode = .data$institutionCode,
                    occurrenceRemarks = .data$occurrenceRemarks
                )
            rows[[sp]] <- df
        } else {
            message("No occurrences returned for ", sp)
        }
        Sys.sleep(0.2) # polite throttle
    }
    out_df <- bind_rows(rows)
    if (nrow(out_df) == 0) {
        stop("No plant occurrences retrieved. Try increasing per_species or changing species list.")
    }
    write.csv(out_df, out, row.names = FALSE)
    message("Wrote ", out, " (", nrow(out_df), " rows).")
    invisible(out_df)
}
