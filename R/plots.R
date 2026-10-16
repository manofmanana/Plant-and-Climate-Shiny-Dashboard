# R/plots.R
# All charts and maps. Plotly charts share a dark, transparent theme so they sit
# on the solarpunk glass cards.

mm_colors <- c(
    gold = "#E3C567", leaf = "#6BBF8F", mint = "#88C9BF", soft = "#A6D49F",
    coral = "#E8998D", sky = "#8FB8DE", text = "#E9F2E2", grid = "rgba(233,242,226,0.12)"
)
mm_palette <- unname(mm_colors[c("gold", "leaf", "mint", "coral", "sky", "soft")])
category_colors <- c(Thriving = "#6BBF8F", Stable = "#E3C567")

mm_layout <- function(p, title = NULL, xlab = NULL, ylab = NULL, ...) {
    axis <- function(label) list(title = list(text = if (is.null(label)) "" else label), gridcolor = mm_colors[["grid"]], zerolinecolor = mm_colors[["grid"]], color = mm_colors[["text"]])
    p |>
        plotly::layout(
            title = list(text = title, font = list(size = 15, color = mm_colors[["gold"]]), x = 0.02),
            xaxis = axis(xlab), yaxis = axis(ylab),
            paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
            font = list(family = "Outfit, sans-serif", color = mm_colors[["text"]]),
            legend = list(orientation = "h", y = -0.2, font = list(size = 11)),
            margin = list(l = 50, r = 20, t = 45, b = 45),
            hoverlabel = list(font = list(family = "Outfit, sans-serif")),
            ...
        ) |>
        plotly::config(displayModeBar = FALSE, responsive = TRUE)
}

empty_plot <- function(message = "No data for this selection") {
    plotly::plot_ly(type = "scatter", mode = "markers") |>
        mm_layout() |>
        plotly::layout(
            xaxis = list(visible = FALSE), yaxis = list(visible = FALSE),
            annotations = list(list(text = message, showarrow = FALSE, font = list(size = 14, color = mm_colors[["text"]])))
        )
}

has_rows <- function(df) !is.null(df) && nrow(df) > 0

# ---------------------------------------------------------------------------
# Plant Growth Dashboard
# ---------------------------------------------------------------------------

plot_growth_distribution <- function(plants) {
    if (!has_rows(plants)) {
        return(empty_plot())
    }
    plotly::plot_ly(
        plants,
        x = ~common_name, y = ~growth_index, color = ~common_name, colors = mm_palette,
        type = "box", boxpoints = "all", jitter = 0.4, pointpos = 0, marker = list(size = 4, opacity = 0.6),
        text = ~label, hoverinfo = "y+text"
    ) |>
        mm_layout("Modeled growth index by species", NULL, "Growth index (0–100)") |>
        plotly::layout(showlegend = FALSE, yaxis = list(range = c(0, 105)), xaxis = list(tickangle = -35))
}

plot_species_counts <- function(plants, top_n = 10) {
    if (!has_rows(plants)) {
        return(empty_plot())
    }
    counts <- as.data.frame(sort(table(plants$common_name), decreasing = TRUE)[seq_len(min(top_n, length(unique(plants$common_name))))])
    names(counts) <- c("species", "n")
    counts$species <- factor(counts$species, levels = rev(counts$species))
    plotly::plot_ly(counts,
        x = ~n, y = ~species, type = "bar", orientation = "h",
        marker = list(color = mm_colors[["leaf"]]), hovertemplate = "%{y}: %{x} observations<extra></extra>"
    ) |>
        mm_layout("Observations by species", "Observations", NULL)
}

plot_humidity_vs_growth <- function(plants) {
    if (!has_rows(plants)) {
        return(empty_plot())
    }
    plotly::plot_ly(plants,
        x = ~humidity, y = ~growth_index, color = ~common_name, colors = mm_palette,
        type = "scatter", mode = "markers", marker = list(size = 8, opacity = 0.8),
        text = ~label,
        hovertemplate = "%{text}<br>Humidity %{x:.0f}%<br>Growth index %{y:.0f}<extra></extra>"
    ) |>
        mm_layout("Humidity vs growth index", "30-day mean relative humidity (%)", "Growth index") |>
        plotly::layout(showlegend = FALSE)
}

plot_growth_trend <- function(plants) {
    if (!has_rows(plants)) {
        return(empty_plot())
    }
    monthly <- plants |>
        dplyr::filter(!is.na(obs_date), !is.na(growth_index)) |>
        dplyr::mutate(month = lubridate::floor_date(obs_date, "month")) |>
        dplyr::group_by(common_name, month) |>
        dplyr::summarise(mean_growth = mean(growth_index), n = dplyr::n(), .groups = "drop")
    if (!has_rows(monthly)) {
        return(empty_plot())
    }
    plotly::plot_ly(monthly,
        x = ~month, y = ~mean_growth, color = ~common_name, colors = mm_palette,
        type = "scatter", mode = "lines+markers",
        text = ~ paste0(common_name, " · ", n, " obs."),
        hovertemplate = "%{text}<br>%{x|%b %Y}: %{y:.0f}<extra></extra>"
    ) |>
        mm_layout("Mean growth index by month", NULL, "Growth index") |>
        plotly::layout(legend = list(orientation = "v", x = 1.02, y = 1, font = list(size = 10)))
}

map_plants <- function(plants) {
    base <- leaflet::leaflet(options = leaflet::leafletOptions(worldCopyJump = TRUE)) |>
        # OpenStreetMap tiles need no API key; CSS in www/style.css darkens them.
        leaflet::addTiles(attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors')
    if (!has_rows(plants)) {
        return(base |> leaflet::setView(0, 20, 2))
    }
    popup <- sprintf(
        "<b>%s</b><br><i>%s</i><br>%s · %s<br>Growth index: <b>%s</b> (%s)<br>30-day temp %s&deg;C · humidity %s%%",
        htmltools::htmlEscape(plants$common_name), htmltools::htmlEscape(plants$species),
        htmltools::htmlEscape(plants$country), format(plants$obs_date, "%d %b %Y"),
        round(plants$growth_index), plants$category,
        round(plants$temperature, 1), round(plants$humidity)
    )
    pal <- leaflet::colorFactor(unname(category_colors), levels = names(category_colors))
    base |>
        leaflet::addCircleMarkers(
            data = plants, lng = ~longitude, lat = ~latitude, popup = popup,
            radius = 6, stroke = TRUE, weight = 1, color = "#0E1815",
            fillColor = ~ pal(category), fillOpacity = 0.85,
            clusterOptions = if (nrow(plants) > 120) leaflet::markerClusterOptions() else NULL
        ) |>
        leaflet::addLegend("bottomright", pal = pal, values = names(category_colors), title = "Modeled growth", opacity = 0.9)
}

plot_correlations <- function(cor_df) {
    if (!has_rows(cor_df) || all(is.na(cor_df$correlation))) {
        return(empty_plot("Not enough data to compute correlations"))
    }
    cor_df$color <- ifelse(cor_df$correlation >= 0, mm_colors[["leaf"]], mm_colors[["coral"]])
    plotly::plot_ly(cor_df,
        x = ~correlation, y = ~variable, type = "bar", orientation = "h",
        marker = list(color = ~color), hovertemplate = "%{y}: r = %{x:.2f}<extra></extra>"
    ) |>
        mm_layout("What drives the growth index?", "Correlation (r)", NULL) |>
        plotly::layout(xaxis = list(range = c(-1, 1)))
}

# ---------------------------------------------------------------------------
# Climate Explorer: all sites
# ---------------------------------------------------------------------------

plot_climate_trend <- function(air) {
    if (!has_rows(air) || !all(c("Temperature", "Precipitation") %in% names(air))) {
        return(empty_plot("No climate data available"))
    }
    plotly::plot_ly(air,
        x = ~Temperature, y = ~Precipitation, type = "scatter", mode = "markers",
        marker = list(color = mm_colors[["mint"]], size = 5, opacity = 0.5),
        text = ~ format(date, "%d %b %Y"),
        hovertemplate = "%{text}<br>%{x:.1f}&deg;C · %{y:.1f} mm<extra></extra>"
    ) |>
        mm_layout("Daily precipitation vs temperature", "Mean temperature (°C)", "Precipitation (mm)")
}

plot_monthly_precip <- function(air) {
    if (!has_rows(air)) {
        return(empty_plot("No precipitation data available"))
    }
    monthly <- air |>
        dplyr::mutate(month = lubridate::floor_date(date, "month")) |>
        dplyr::group_by(month) |>
        dplyr::summarise(precip = sum(Precipitation, na.rm = TRUE), .groups = "drop")
    plotly::plot_ly(monthly,
        x = ~month, y = ~precip, type = "bar", marker = list(color = mm_colors[["leaf"]]),
        hovertemplate = "%{x|%b %Y}: %{y:.0f} mm<extra></extra>"
    ) |>
        mm_layout("Monthly precipitation (site average)", NULL, "Precipitation (mm)")
}

plot_temp_distribution <- function(values, highlight = NULL, title = "Distribution of daily temperature",
                                   xlab = "Mean temperature (°C)") {
    values <- values[!is.na(values)]
    if (length(values) == 0) {
        return(empty_plot("No temperature data available"))
    }
    p <- plotly::plot_ly(
        x = values, type = "histogram", nbinsx = 30,
        marker = list(color = mm_colors[["gold"]], line = list(color = "#0E1815", width = 1)),
        hovertemplate = "%{x}: %{y}<extra></extra>"
    ) |>
        mm_layout(title, xlab, "Count")
    if (!is.null(highlight) && !is.na(highlight)) {
        p <- p |> plotly::layout(shapes = list(list(
            type = "line", x0 = highlight, x1 = highlight, y0 = 0, y1 = 1, yref = "paper",
            line = list(color = mm_colors[["coral"]], width = 3, dash = "dash")
        )), annotations = list(list(
            x = highlight, y = 1, yref = "paper", text = "this plant", showarrow = FALSE,
            yanchor = "bottom", font = list(color = mm_colors[["coral"]])
        )))
    }
    p
}

plot_temp_timeseries <- function(air) {
    if (!has_rows(air)) {
        return(empty_plot("No temperature data available"))
    }
    weekly <- air |>
        dplyr::mutate(week = lubridate::floor_date(date, "week")) |>
        dplyr::group_by(week) |>
        dplyr::summarise(Temperature = mean(Temperature, na.rm = TRUE), Humidity = mean(Humidity, na.rm = TRUE), .groups = "drop")
    plotly::plot_ly(weekly, x = ~week) |>
        plotly::add_lines(y = ~Temperature, name = "Temperature (°C)", line = list(color = mm_colors[["gold"]])) |>
        plotly::add_lines(y = ~Humidity, name = "Humidity (%)", yaxis = "y2", line = list(color = mm_colors[["sky"]])) |>
        mm_layout("Weekly temperature & humidity (site average)", NULL, "°C") |>
        plotly::layout(yaxis2 = list(overlaying = "y", side = "right", title = "%", color = mm_colors[["text"]], showgrid = FALSE))
}

plot_growth_histogram <- function(plants) {
    if (!has_rows(plants)) {
        return(empty_plot())
    }
    plotly::plot_ly(plants,
        x = ~growth_index, color = ~category, colors = unname(category_colors[sort(unique(plants$category))]),
        type = "histogram", nbinsx = 20, marker = list(line = list(color = "#0E1815", width = 1))
    ) |>
        mm_layout("Distribution of the growth index", "Growth index (0–100)", "Plants") |>
        plotly::layout(barmode = "stack")
}

# ---------------------------------------------------------------------------
# Climate Explorer: one plant
# ---------------------------------------------------------------------------

plot_plant_temperature <- function(window, plant) {
    if (!has_rows(window)) {
        return(empty_plot("No climate data for this plant"))
    }
    prof <- species_profile(plant$species)
    plotly::plot_ly(window, x = ~date) |>
        plotly::add_ribbons(ymin = ~TempMin, ymax = ~TempMax, name = "Daily min–max", fillcolor = "rgba(227,197,103,0.22)", line = list(width = 0)) |>
        plotly::add_lines(y = ~Temperature, name = "Daily mean", line = list(color = mm_colors[["gold"]], width = 3)) |>
        mm_layout(paste0("Temperature · 30 days before ", format(plant$obs_date, "%d %b %Y")), NULL, "Temperature (°C)") |>
        plotly::layout(shapes = list(list(
            type = "rect", xref = "paper", x0 = 0, x1 = 1, y0 = prof$temp_min, y1 = prof$temp_max,
            fillcolor = "rgba(107,191,143,0.15)", line = list(width = 0), layer = "below"
        )), annotations = list(list(
            xref = "paper", x = 0.01, y = prof$temp_max, text = "ideal range", showarrow = FALSE,
            xanchor = "left", yanchor = "bottom", font = list(color = mm_colors[["leaf"]], size = 11)
        )))
}

plot_plant_moisture <- function(window, plant) {
    if (!has_rows(window)) {
        return(empty_plot("No climate data for this plant"))
    }
    plotly::plot_ly(window, x = ~date) |>
        plotly::add_bars(y = ~Precipitation, name = "Precipitation (mm)", marker = list(color = mm_colors[["sky"]])) |>
        plotly::add_lines(y = ~Humidity, name = "Humidity (%)", yaxis = "y2", line = list(color = mm_colors[["leaf"]], width = 3)) |>
        mm_layout("Rain & humidity in the same window", NULL, "mm") |>
        plotly::layout(yaxis2 = list(overlaying = "y", side = "right", title = "%", range = c(0, 100), color = mm_colors[["text"]], showgrid = FALSE))
}

plot_growth_vs_temperature <- function(plants, highlight_id = NULL) {
    if (!has_rows(plants)) {
        return(empty_plot())
    }
    p <- plotly::plot_ly(plants,
        x = ~temperature, y = ~growth_index, type = "scatter", mode = "markers",
        marker = list(color = mm_colors[["mint"]], size = 7, opacity = 0.55), name = "Same species",
        text = ~label, hovertemplate = "%{text}<br>%{x:.1f}&deg;C → %{y:.0f}<extra></extra>"
    )
    sel <- plants[plants$occurrence_id %in% highlight_id, , drop = FALSE]
    if (has_rows(sel)) {
        p <- p |> plotly::add_markers(
            data = sel, x = ~temperature, y = ~growth_index, name = "This plant",
            marker = list(color = mm_colors[["coral"]], size = 16, line = list(color = "#fff", width = 2))
        )
    }
    p |> mm_layout("How this plant compares to its species", "30-day mean temperature (°C)", "Growth index")
}
