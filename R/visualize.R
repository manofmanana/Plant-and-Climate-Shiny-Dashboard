# R/visualize.R
# Purpose: Generate visualizations

library(ggplot2)
library(plotly)
library(leaflet)

plot_growth_distribution <- function(summary_df) {
    p <- ggplot(summary_df, aes(x = species, y = adjusted_growth, fill = category)) +
        geom_boxplot(alpha = 0.7) +
        theme_minimal() +
        labs(title = "Plant Growth by Species", y = "Adjusted Growth Rate", x = "Species") +
        scale_fill_manual(values = c("#A8D5BA", "#77BFA3"))
    ggplotly(p)
}

plot_climate_trend <- function(air) {
    p <- ggplot(air, aes(x = Temperature, y = Ozone_Level)) +
        geom_point(color = "#77BFA3", alpha = 0.8) +
        geom_smooth(method = "lm", color = "#4B7856") +
        theme_light() +
        labs(title = "Ozone vs. Temperature", x = "Temperature (°F)", y = "Ozone Level (ppb)")
    ggplotly(p)
}

map_random_plants <- function(plants) {
    # Random lat/long for demo (simulating a plant observation map)
    plants$lat <- runif(nrow(plants), 34, 42)
    plants$lon <- runif(nrow(plants), -120, -70)

    leaflet(plants) %>%
        addProviderTiles("CartoDB.Positron") %>%
        addCircleMarkers(
            ~lon, ~lat,
            popup = ~ paste0("<b>", species, "</b><br>Growth Rate: ", round(growth_rate, 2)),
            color = "#77BFA3",
            radius = 5,
            fillOpacity = 0.7
        )
}
