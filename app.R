###########################################################
# Maquerina Mundo — Plants Meet Climate
# Author: Alex Ines
# Purpose: A solarpunk inspired Shiny dashboard exploring
#          plant health, climate data, and sustainability
###########################################################

# --- Auto install + load required packages ---
required_packages <- c(
    "shiny", "bslib", "tidyverse", "plotly", "leaflet", "DT",
    "showtext", "ragg", "htmltools", "lubridate", "scales", "ggthemes", "corrplot", "leaflet.extras"
)
for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
    library(pkg, character.only = TRUE)
}

# --- Source supporting R modules ---
source("R/data_load.R")
source("R/helpers.R")
source("R/analysis.R")
source("R/visualize.R")

# --- Load and process data ---
# avoid the warning about loading R/ as a package directory by setting an option
options(shiny.suppressPackageStartupMessages = TRUE)
data <- load_data()
# Pass the full data list to the analyzer so it can attach plants_climate when valid.
analysis <- analyze_relationships(data$air, data)

###########################################################
# THEME — Solarpunk Fusion
###########################################################
solarpunk_theme <- bslib::bs_theme(
    version = 5,
    primary = "#E3C567",
    secondary = "#6BBF8F",
    success = "#A6D49F",
    info = "#88C9BF",
    dark = "#243E36",
    base_font = bslib::font_google("Outfit"),
    heading_font = bslib::font_google("Poppins")
)
# ###########################################################
# UI
###########################################################
ui <- bslib::page_navbar(
    title = NULL,
    theme = solarpunk_theme,
    window_title = "Maquerina Mundo — Solarpunk Dashboard",
    header = tags$head(
        tags$link(rel = "stylesheet", href = "style.css"),
        tags$link(rel = "icon", type = "image/jpeg", href = "favicon.jpg"),
        tags$script(src = "expand.js")
    ),

    # HOME
    bslib::nav_panel(
        title = "🏡 Home",
        div(
            class = "mm-page-wrapper",
            div(
                class = "mm-hero",
                style = "background: linear-gradient(rgba(30,48,41,0.55), rgba(14,24,21,0.85)), url('solar.JPG') center/cover no-repeat; border-radius:20px; padding:70px 30px; text-align:center; color:#E9F2E2; text-shadow:0 2px 6px rgba(0,0,0,0.4); position: relative;",
                h1(style = "font-weight:700;font-size:2.4rem;color:#E3C567;", "Maquerina Mundo — Nature, Light & Data in Harmony"),
                p(style = "font-size:1.1rem;max-width:700px;margin:0 auto 15px;", "Welcome to a solarpunk world where technology and ecology grow together. Discover how climate and plants coexist powered by sunlight and data."),
                div(class = "mm-hero-quote", tags$p(class = "mm-hero-quote-text", '"A tree falls the way it leans. Be careful which way you lean."', tags$span(class = "mm-hero-quote-author", "~ The Lorax"))),
                br()
            ),
            # feature cards placed below the hero so the hero size remains unchanged
            div(
                class = "mm-feature-row",
                bslib::layout_columns(
                    col_widths = c(4, 4, 4),
                    div(
                        class = "mm-card mm-framed mm-feature mm-feature-nasa mm-bg-nasa",
                        h4("NASA Climate Tracker", style = "text-align:center;color:#FFF;"),
                        p("Follow real time climate patterns, renewable energy insights, and sustainability progress around the world.", style = "text-align:center;color:#FFF;"),
                        div(style = "text-align:center;", tags$a(href = "https://climate.nasa.gov/", target = "_blank", class = "mm-btn", "Visit NASA Climate Tracker"))
                    ),
                    div(
                        class = "mm-card mm-framed mm-feature mm-feature-solarpunk mm-bg-solarpunk",
                        h4("Solarpunk Literature & Ideas", style = "text-align:center;color:#FFF;"),
                        p("Read stories, manifestos, and resources on building brighter ecological futures.", style = "text-align:center;color:#FFF;"),
                        div(style = "text-align:center;", tags$a(href = "https://iandennismiller.github.io/solarpunk/", target = "_blank", class = "mm-btn", "Solarpunk Resources"))
                    ),
                    div(
                        class = "mm-card mm-framed mm-feature mm-feature-news mm-bg-climate2",
                        h4("Positive Climate News", style = "text-align:center;color:#FFF;"),
                        p("Stay updated with hopeful, solution oriented stories about climate progress.", style = "text-align:center;color:#FFF;"),
                        div(style = "text-align:center;", tags$a(href = "https://www.dailyclimate.org/good-news/", target = "_blank", class = "mm-btn", "Good News"))
                    )
                )
            ),
            tags$div(
                class = "mm-page-footer site-footer",
                tags$span(class = "site-footer-left", HTML("&copy; Alejandro Ines 2025")),
                tags$span(class = "site-footer-right", "Made with Shiny for R")
            )
        )
    ),

    # PLANT GROWTH DASHBOARD
    bslib::nav_panel(
        title = "🌱 Plant Growth Dashboard",
        div(
            class = "mm-page-wrapper page-bg-plantdash",
            div(
                class = "mm-page-content",
                bslib::layout_sidebar(
                    sidebar = bslib::sidebar(
                        open = TRUE,
                        div(
                            class = "mm-card mm-framed mm-no-expand",
                            h4("Filter", class = "mm-card-title"),
                            p("Select Species:", class = "mm-sidebar-label"),
                            selectInput("species", NULL,
                                choices = if (!is.null(analysis$summary$species)) na.omit(unique(as.character(analysis$summary$species))) else character(0),
                                selected = if (!is.null(analysis$summary$species) && "Monstera" %in% analysis$summary$species) "Monstera" else if (!is.null(analysis$summary$species)) na.omit(as.character(unique(analysis$summary$species)))[1] else NULL
                            ),
                            p("Minimum Humidity:", class = "mm-sidebar-label"),
                            sliderInput("humidity", NULL, min = 30, max = 90, value = 50),
                            p(style = "color:#E9F2E2;margin-top:10px;", "Correlation summary shown below uses Temperature paired with available climate variables (Precipitation or Wind).")
                        )
                    ),
                    bslib::layout_columns(
                        col_widths = c(4, 4, 4),
                        div(class = "mm-card mm-framed", plotlyOutput("growth_plot", height = "300px")),
                        div(class = "mm-card mm-framed", plotlyOutput("species_counts", height = "300px")),
                        div(class = "mm-card mm-framed", plotlyOutput("humidity_growth", height = "300px"))
                    ),
                    br(),
                    bslib::layout_columns(
                        col_widths = c(6, 6),
                        div(class = "mm-card mm-framed", leafletOutput("plant_map", height = 380)),
                        div(class = "mm-card mm-framed", plotlyOutput("growth_trend_agg", height = 380))
                    )
                )
            ),
            tags$div(
                class = "mm-page-footer site-footer",
                tags$span(class = "site-footer-left", HTML("&copy; Alejandro Ines 2025")),
                tags$span(class = "site-footer-right", "Made with Shiny for R")
            )
        )
    ),

    # CLIMATE EXPLORER
    bslib::nav_panel(
        title = "☀️ Climate Explorer",
        div(
            class = "mm-page-wrapper page-bg-climateexplorer",
            div(
                class = "mm-page-content",
                bslib::layout_sidebar(
                    sidebar = bslib::sidebar(
                        open = TRUE,
                        div(
                            class = "mm-card mm-framed mm-no-expand",
                            h4("Select a plant", class = "mm-card-title"),
                            selectInput("location_selector", NULL, choices = c("All"), selected = "All"),
                            p("Choose a specific plant to view plant-level climate, or 'All' for aggregated views.", class = "direction-text")
                        )
                    ),
                    bslib::layout_columns(
                        col_widths = c(4, 4, 4),
                        div(class = "mm-card mm-framed", plotlyOutput("climate_plot", height = "320px")),
                        div(class = "mm-card mm-framed", plotlyOutput("monthly_precip", height = "320px")),
                        div(class = "mm-card mm-framed", plotlyOutput("temp_distribution", height = "260px"))
                    ),
                    br(),
                    bslib::layout_columns(
                        col_widths = c(6, 6),
                        div(class = "mm-card mm-framed", plotlyOutput("climate_point_ts", height = "380px")),
                        div(class = "mm-card mm-framed", plotlyOutput("growth_ts", height = "380px"))
                    )
                )
            ),
            tags$div(
                class = "mm-page-footer site-footer",
                tags$span(class = "site-footer-left", HTML("&copy; Alejandro Ines 2025")),
                tags$span(class = "site-footer-right", "Made with Shiny for R")
            )
        )
    ),

    # DATA TABLE
    bslib::nav_panel(
        title = "📊 Data Table",
        div(
            class = "mm-page-wrapper page-bg-datatable",
            div(class = "mm-page-content", div(class = "mm-card mm-framed mm-no-expand", DTOutput("data_table"))),
            tags$div(
                class = "mm-page-footer site-footer",
                tags$span(class = "site-footer-left", HTML("&copy; Alejandro Ines 2025")),
                tags$span(class = "site-footer-right", "Made with Shiny for R")
            )
        )
    )
)

###########################################################
# SERVER
###########################################################
server <- function(input, output, session) {
    # static hero quote; rotating quotes removed

    # --- Text Summary ---
    output$cor_summary <- renderText({
        # show a quick summary correlation using Temperature and another available variable
        candidates <- intersect(c("Temperature", "Precipitation", "Wind"), names(data$air))
        if ("Temperature" %in% candidates && length(candidates) >= 2) {
            other <- setdiff(candidates, "Temperature")[1]
            cor_summary(data$air, "Temperature", other)
        } else {
            "Not enough climate variables to compute a quick correlation summary."
        }
    })

    # --- Filtered Plant Data ---
    filtered_data <- reactive({
        df <- analysis$summary
        # guard: if species input is missing or NA, do not filter by species
        if (!is.null(input$species) && nzchar(as.character(input$species))) {
            df <- df %>% dplyr::filter(as.character(species) == as.character(input$species))
        }
        if ("humidity" %in% names(df)) {
            df <- df %>% dplyr::filter(humidity >= input$humidity)
        }
        df
    })

    # --- Growth Plot ---
    output$growth_plot <- renderPlotly({
        plot_growth_distribution(filtered_data())
    })

    # --- Plant Map ---
    output$plant_map <- renderLeaflet({
        # show heatmap if many points, otherwise circle markers
        if (!is.null(filtered_data()) && nrow(filtered_data()) > 200) {
            map_heat_plants(filtered_data())
        } else {
            map_random_plants(filtered_data())
        }
    })

    # --- Climate Plot ---
    output$climate_plot <- renderPlotly({
        plot_climate_trend(data$air)
    })

    output$temp_ts <- renderPlotly({
        plot_temp_timeseries(data$air)
    })

    # Temperature distribution for the climate explorer (new panel)
    output$temp_distribution <- renderPlotly({
        plot_temp_distribution(data$air)
    })

    # populate location selector choices with plant ids and climate point labels
    observe({
        # Build a named list: label -> value. "All" maps to "All".
        choices_list <- list("All" = "All")
        if (!is.null(data$plants) && nrow(data$plants) > 0) {
            if ("plant_id" %in% names(data$plants)) {
                vals <- unique(na.omit(data$plants$plant_id))
                labs <- paste0(ifelse(is.na(data$plants$species), "Unknown", data$plants$species)[match(vals, data$plants$plant_id)], " (", vals, ")")
                # create named vector where names are labels and values are ids
                named <- setNames(as.list(as.character(vals)), labs)
                choices_list <- c(choices_list, named)
            }
        }
        # also include any plant ids present in plants_climate (avoid duplicates)
        if (!is.null(data$plants_climate) && nrow(data$plants_climate) > 0 && "plant_id" %in% names(data$plants_climate)) {
            vals2 <- setdiff(unique(na.omit(data$plants_climate$plant_id)), names(choices_list))
            if (length(vals2) > 0) {
                labs2 <- paste0(ifelse(is.na(data$plants_climate$species), "Unknown", data$plants_climate$species)[match(vals2, data$plants_climate$plant_id)], " (", vals2, ")")
                named2 <- setNames(as.list(as.character(vals2)), labs2)
                choices_list <- c(choices_list, named2)
            }
        }
        updateSelectInput(session, "location_selector", choices = choices_list, selected = "All")
    })

    # --- Additional Plant Dashboard Plots ---
    output$species_counts <- renderPlotly({
        plot_species_counts(data$plants)
    })

    output$humidity_growth <- renderPlotly({
        plot_humidity_vs_growth(data$plants)
    })

    output$growth_trend_agg <- renderPlotly({
        plot_growth_trend_agg(data$plants)
    })

    output$climate_point_ts <- renderPlotly({
        sel <- input$location_selector
        if (is.null(sel) || sel == "All") {
            # when 'All' is selected we keep this card showing a richer aggregated
            # time-series for climate (monthly / temp trends)
            plot_temp_timeseries(data$air)
        } else {
            id <- as.numeric(sel)
            plot_climate_point_timeseries(data$plants_climate, id_col = "plant_id", id = id)
        }
    })

    output$growth_ts <- renderPlotly({
        sel <- input$location_selector
        if (!is.null(sel) && sel != "All") {
            id <- as.numeric(sel)
            df <- analysis$summary
            if ("plant_id" %in% names(df)) df <- df %>% dplyr::filter(plant_id == id)
            plot_growth_timeseries(df)
        } else {
            plot_growth_histogram(analysis$summary)
        }
    })

    # --- Monthly Precipitation (aggregated) ---
    output$monthly_precip <- renderPlotly({
        plot_monthly_precip(data$air)
    })

    # --- Correlation Heatmap ---
    output$cor_heatmap <- renderPlot({
        # use available climate columns; fall back to numeric columns if missing
        air_df <- data$air
        candidates <- intersect(c("Temperature", "Precipitation", "Wind"), names(air_df))
        if (length(candidates) < 2) {
            plot.new()
            text(0.5, 0.5, "Not enough climate columns for correlation")
            return()
        }
        corr <- cor(air_df[, candidates], use = "complete.obs")
        corrplot::corrplot(corr,
            method = "color", tl.col = "#E9F2E2", tl.srt = 45,
            col = colorRampPalette(c("#F3E5AB", "#6BBF8F", "#243E36"))(200)
        )
    })
    # --- Data Table ---
    output$data_table <- renderDT({
        datatable(analysis$summary,
            options = list(pageLength = 10, scrollX = TRUE),
            rownames = FALSE, class = "cell-border stripe hover"
        )
    })
}

###########################################################
# RUN APP
###########################################################
shinyApp(ui, server)
