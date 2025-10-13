# R/visualize.R
# Purpose: Generate visualizations

library(ggplot2)
library(plotly)
library(leaflet)

library(lubridate)
library(dplyr)
library(tidyr)
library(htmlwidgets)
library(leaflet.extras)

plot_growth_distribution <- function(summary_df) {
    # Accept either a summary data.frame or the full data list (defensive)
    if (is.list(summary_df) && !is.data.frame(summary_df)) {
        if ("summary" %in% names(summary_df)) {
            summary_df <- summary_df$summary
        } else if ("plants" %in% names(summary_df)) summary_df <- summary_df$plants
    }
    if (is.null(summary_df) || nrow(summary_df) == 0) {
        p <- ggplot() +
            labs(title = "No plant summary available")
        return(ggplotly(p))
    }
    # if adjusted_growth doesn't exist, fall back to growth_rate
    y_col <- ifelse("adjusted_growth" %in% names(summary_df), "adjusted_growth", ifelse("growth_rate" %in% names(summary_df), "growth_rate", NA))
    if (is.na(y_col)) {
        p <- ggplot() +
            labs(title = "No growth variable available")
        return(ggplotly(p))
    }
    # ensure species and category exist
    if (!"species" %in% names(summary_df)) summary_df$species <- "Unknown"
    if (!"category" %in% names(summary_df)) summary_df$category <- "A"
    # use tidy-eval instead of deprecated aes_string
    x_sym <- rlang::sym("species")
    y_sym <- rlang::sym(y_col)
    fill_sym <- rlang::sym("category")
    p <- ggplot(summary_df, aes(x = !!x_sym, y = !!y_sym, fill = !!fill_sym)) +
        geom_boxplot(alpha = 0.8) +
        theme_minimal(base_size = 12) +
        labs(title = "Plant Growth by Species", y = ifelse(y_col == "adjusted_growth", "Adjusted Growth Rate", "Growth Rate"), x = "Species") +
        scale_fill_manual(values = c("#A8D5BA", "#77BFA3")) +
        theme(legend.position = "none")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 20, r = 12, t = 36, b = 24)) %>%
        plotly::config(displayModeBar = FALSE)
}

plot_climate_trend <- function(air) {
    # Accept either the air data.frame or the full data list
    if (is.list(air) && !is.data.frame(air)) {
        if ("air" %in% names(air)) {
            air <- air$air
        } else {
            stop("plot_climate_trend: expected a data.frame-like 'air' input")
        }
    }
    if (is.null(air) || nrow(air) == 0) {
        p <- ggplot() +
            labs(title = "No climate data available")
        return(ggplotly(p))
    }
    # Use Temperature vs Precipitation as a simple climate explorer
    if (!all(c("Temperature", "Precipitation") %in% names(air))) {
        p <- ggplot() +
            labs(title = "Insufficient climate columns for trend")
        return(ggplotly(p))
    }
    p <- ggplot(air, aes(x = Temperature, y = Precipitation)) +
        geom_point(color = "#77BFA3", alpha = 0.8) +
        geom_smooth(method = "loess", color = "#4B7856") +
        theme_light() +
        labs(title = "Precipitation vs. Temperature", x = "Temperature (°C)", y = "Precipitation (mm)")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 20, r = 12, t = 36, b = 24)) %>%
        plotly::config(displayModeBar = FALSE)
}

map_random_plants <- function(plants) {
    # Use actual plant coordinates if available
    lat_col <- ifelse("decimalLatitude" %in% names(plants), "decimalLatitude", "lat")
    lon_col <- ifelse("decimalLongitude" %in% names(plants), "decimalLongitude", "lon")
    lat <- plants[[lat_col]]
    lon <- plants[[lon_col]]
    popup <- ifelse("growth_rate" %in% names(plants), paste0("<b>", plants$species, "</b><br>Growth Rate: ", round(plants$growth_rate, 2)), plants$species)

    leaflet() %>%
        addProviderTiles("CartoDB.Positron") %>%
        addCircleMarkers(lng = lon, lat = lat, popup = popup, color = "#77BFA3", radius = 5, fillOpacity = 0.8)
}

# heatmap of plant locations (density)
map_heat_plants <- function(plants) {
    # Accept a list with plants as well
    if (is.list(plants) && !is.data.frame(plants)) {
        if ("plants" %in% names(plants)) plants <- plants$plants
    }
    lat_col <- ifelse("decimalLatitude" %in% names(plants), "decimalLatitude", "lat")
    lon_col <- ifelse("decimalLongitude" %in% names(plants), "decimalLongitude", "lon")
    coords <- na.omit(dplyr::select(plants, all_of(c(lat_col, lon_col))))
    if (nrow(coords) == 0) {
        return(leaflet() %>% addProviderTiles("CartoDB.Positron"))
    }
    # compute a reasonable max parameter for heat intensity
    max_val <- max(1, nrow(coords) / 1000)
    leaflet() %>%
        addProviderTiles("CartoDB.Positron") %>%
        leaflet.extras::addHeatmap(lng = coords[[lon_col]], lat = coords[[lat_col]], blur = 20, max = max_val, radius = 15)
}

plot_growth_timeseries <- function(summary_df, species = NULL) {
    df <- summary_df
    if (!is.null(species)) df <- df %>% dplyr::filter(species == species)
    if (!"eventDate" %in% names(df)) {
        p <- ggplot() +
            labs(title = "No date information available for time series")
        return(ggplotly(p))
    }
    p <- ggplot(df, aes(x = as.Date(eventDate), y = adjusted_growth, color = species)) +
        geom_jitter(alpha = 0.7, width = 3, height = 0) +
        geom_smooth(method = "loess", se = FALSE) +
        theme_minimal() +
        labs(title = "Adjusted Growth over Time", x = "Date", y = "Adjusted Growth") +
        scale_color_manual(values = c("#A8D5BA", "#77BFA3", "#5A9A7B", "#4B7856"))
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}

plot_growth_histogram <- function(summary_df) {
    p <- ggplot(summary_df, aes(x = adjusted_growth, fill = category)) +
        geom_histogram(bins = 30, alpha = 0.9, color = "white") +
        theme_minimal() +
        labs(title = "Distribution of Adjusted Growth", x = "Adjusted Growth", y = "Count") +
        scale_fill_manual(values = c("#A8D5BA", "#77BFA3"))
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}

# New helper: species counts (bar chart)
plot_species_counts <- function(plants, top_n = 10) {
    # accept list wrapper
    if (is.list(plants) && !is.data.frame(plants) && "plants" %in% names(plants)) plants <- plants$plants
    if (is.null(plants) || nrow(plants) == 0) {
        p <- ggplot() +
            labs(title = "No plant data available")
        return(ggplotly(p))
    }
    df <- plants %>%
        dplyr::count(species, sort = TRUE) %>%
        head(top_n)
    p <- ggplot(df, aes(x = reorder(species, n), y = n, fill = species)) +
        geom_col(show.legend = FALSE) +
        coord_flip() +
        theme_minimal() +
        labs(title = "Top Species by Observations", x = "Species", y = "Count") +
        scale_fill_manual(values = rep(c("#A8D5BA", "#77BFA3", "#5A9A7B", "#4B7856"), 10))
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 80, r = 12, t = 36, b = 24)) %>%
        plotly::config(displayModeBar = FALSE)
}

# New helper: humidity vs growth scatter
plot_humidity_vs_growth <- function(plants) {
    if (is.list(plants) && !is.data.frame(plants) && "plants" %in% names(plants)) plants <- plants$plants
    if (is.null(plants) || nrow(plants) == 0) {
        p <- ggplot() +
            labs(title = "No plant data available")
        return(ggplotly(p))
    }
    # ensure required columns
    if (!"growth_rate" %in% names(plants) && !"adjusted_growth" %in% names(plants)) {
        p <- ggplot() +
            labs(title = "No growth metric available")
        return(ggplotly(p))
    }
    y_col <- ifelse("adjusted_growth" %in% names(plants), "adjusted_growth", "growth_rate")
    if (!"humidity" %in% names(plants)) plants$humidity <- NA
    # tidy-eval for aesthetics
    y_sym2 <- rlang::sym(y_col)
    p <- ggplot(plants, aes(x = humidity, y = !!y_sym2, color = species, text = species)) +
        geom_point(alpha = 0.8, size = 3) +
        theme_minimal() +
        labs(title = "Humidity vs Growth", x = "Humidity (%)", y = ifelse(y_col == "adjusted_growth", "Adjusted Growth", "Growth Rate"))
    ggplotly(p, tooltip = c("text", "x", "y")) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}

# New helper: aggregated growth trend across time (daily mean)
plot_growth_trend_agg <- function(plants) {
    if (is.list(plants) && !is.data.frame(plants) && "plants" %in% names(plants)) plants <- plants$plants
    if (is.null(plants) || nrow(plants) == 0 || !"eventDate" %in% names(plants)) {
        p <- ggplot() +
            labs(title = "No temporal plant data available")
        return(ggplotly(p))
    }
    y_col <- ifelse("adjusted_growth" %in% names(plants), "adjusted_growth", ifelse("growth_rate" %in% names(plants), "growth_rate", NA))
    if (is.na(y_col)) {
        p <- ggplot() +
            labs(title = "No growth metric available")
        return(ggplotly(p))
    }
    df <- plants %>%
        dplyr::group_by(eventDate) %>%
        dplyr::summarise(mean_growth = mean(.data[[y_col]], na.rm = TRUE)) %>%
        dplyr::ungroup()
    p <- ggplot(df, aes(x = as.Date(eventDate), y = mean_growth)) +
        geom_line(color = "#77BFA3") +
        geom_smooth(method = "loess", se = FALSE, color = "#4B7856") +
        theme_minimal() +
        labs(title = "Mean Growth over Time", x = "Date", y = "Mean Growth")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}

plot_climate_point_timeseries <- function(plants_climate, id_col = "plant_id", id = NULL) {
    if (is.null(plants_climate) || nrow(plants_climate) == 0) {
        p <- ggplot() +
            labs(title = "No plant-level climate data available")
        return(ggplotly(p))
    }
    df <- plants_climate
    if (!is.null(id) && id_col %in% names(df)) df <- df %>% dplyr::filter(.data[[id_col]] == id)
    if (!"eventDate" %in% names(df)) df$eventDate <- NA
    # long format for multi-line — ensure expected climate columns exist first
    climate_cols <- intersect(c("Temperature", "Precipitation", "Wind"), names(df))
    if (length(climate_cols) == 0) {
        p <- ggplot() +
            labs(title = "No plant-level climate variables (Temperature/Precipitation/Wind) available for selected point")
        return(ggplotly(p))
    }
    df_long <- df %>% tidyr::pivot_longer(cols = tidyselect::all_of(climate_cols), names_to = "variable", values_to = "value")
    p <- ggplot(df_long, aes(x = as.Date(eventDate), y = value, color = variable)) +
        geom_line() +
        geom_point(size = 1) +
        theme_minimal() +
        labs(title = "Plant-level Climate Time Series", x = "Date", y = "Value") +
        scale_color_manual(values = c(Temperature = "#E3C567", Precipitation = "#77BFA3", Wind = "#4B7856"))
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 20, r = 12, t = 36, b = 24)) %>%
        plotly::config(displayModeBar = FALSE)
}

# Monthly precipitation bar chart from air (aggregated by month)
plot_monthly_precip <- function(air) {
    # accept list wrapper
    if (is.list(air) && !is.data.frame(air) && "air" %in% names(air)) air <- air$air
    if (is.null(air) || nrow(air) == 0 || !"date" %in% names(air) || !"Precipitation" %in% names(air)) {
        p <- ggplot() +
            labs(title = "No precipitation data available")
        return(ggplotly(p))
    }
    df <- air %>%
        mutate(month = lubridate::floor_date(as.Date(date), "month")) %>%
        group_by(month) %>%
        summarise(precip = sum(Precipitation, na.rm = TRUE)) %>%
        ungroup()
    p <- ggplot(df, aes(x = month, y = precip)) +
        geom_col(fill = "#77BFA3") +
        theme_minimal() +
        labs(title = "Monthly Precipitation", x = "Month", y = "Precipitation (mm)")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}

# Small temperature timeseries for climate explorer module
plot_temp_timeseries <- function(air) {
    if (is.list(air) && !is.data.frame(air) && "air" %in% names(air)) air <- air$air
    if (is.null(air) || nrow(air) == 0 || !"date" %in% names(air) || !"Temperature" %in% names(air)) {
        p <- ggplot() +
            labs(title = "No temperature data available")
        return(ggplotly(p))
    }
    df <- air %>% arrange(as.Date(date))
    p <- ggplot(df, aes(x = as.Date(date), y = Temperature)) +
        geom_line(color = "#E3C567") +
        theme_minimal() +
        labs(title = "Temperature over Time", x = "Date", y = "Temperature (°C)")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}

# New: Temperature distribution histogram for the climate explorer
plot_temp_distribution <- function(air) {
    if (is.list(air) && !is.data.frame(air) && "air" %in% names(air)) air <- air$air
    if (is.null(air) || nrow(air) == 0 || !"Temperature" %in% names(air)) {
        p <- ggplot() +
            labs(title = "No temperature data available")
        return(ggplotly(p))
    }
    df <- air %>% dplyr::filter(!is.na(Temperature))
    p <- ggplot(df, aes(x = Temperature)) +
        geom_histogram(bins = 30, fill = "#E3C567", color = "white", alpha = 0.95) +
        theme_minimal() +
        labs(title = "Distribution of Temperature", x = "Temperature (°C)", y = "Count")
    ggplotly(p) %>%
        plotly::layout(margin = list(l = 12, r = 12, t = 28, b = 16)) %>%
        plotly::config(displayModeBar = FALSE)
}
