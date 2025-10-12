# scripts/join_and_write_csvs.R
# Join plant occurrences to nearest climate observations (by date +/- 7 days and nearest location)
# Dependencies: dplyr, lubridate, geosphere

library(dplyr)
library(lubridate)
library(geosphere)

join_data <- function(plants_csv = "data/indoor_plants.csv", climate_csv = "data/climate_data.csv", out_plants_joined = "data/indoor_plants_with_climate.csv") {
  plants <- read.csv(plants_csv, stringsAsFactors = FALSE)
  climate <- read.csv(climate_csv, stringsAsFactors = FALSE)
  # Convert dates
  plants$eventDate <- as.Date(substr(plants$eventDate, 1, 10))
  if ("date" %in% names(climate)) climate$date <- as.Date(climate$date)
  # For each plant occurrence find climate rows within +/- 7 days
  joined_list <- lapply(seq_len(nrow(plants)), function(i) {
    pdate <- plants$eventDate[i]
    cand <- climate %>% filter(date >= pdate - 7 & date <= pdate + 7)
    if (nrow(cand) == 0) return(cbind(plants[i,], setNames(rep(NA, ncol(climate)), paste0('climate_', names(climate)))))
    ds <- distHaversine(matrix(c(plants$decimalLongitude[i], plants$decimalLatitude[i]), ncol = 2),
                        matrix(c(cand$longitude, cand$latitude), ncol = 2))
    best <- cand[which.min(ds), , drop = FALSE]
    # prefix climate cols to avoid name collisions
    climate_prefixed <- setNames(as.list(best[1,]), paste0('climate_', names(best)))
    cbind(plants[i,], as.data.frame(climate_prefixed, stringsAsFactors = FALSE))
  })
  # ensure all rows have same columns
  all_cols <- unique(unlist(lapply(joined_list, names)))
  normalize_row <- function(df_row) {
    missing <- setdiff(all_cols, names(df_row))
    if (length(missing) > 0) df_row[missing] <- NA
    return(df_row[all_cols])
  }
  joined <- do.call(rbind, lapply(joined_list, normalize_row))
  out <- do.call(rbind, joined)
  write.csv(out, out_plants_joined, row.names = FALSE)
  message("Wrote ", out_plants_joined, " (", nrow(out), " rows).")
  invisible(out)
}
