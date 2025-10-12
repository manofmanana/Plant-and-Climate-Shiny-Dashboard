###########################################################
# Maquerina Mundo — Plants Meet Climate
# Author: Alex Ines
# Purpose: A solarpunk inspired Shiny dashboard exploring
#          plant health, climate data, and sustainability
###########################################################

# --- Auto install + load required packages ---
required_packages <- c(
    "shiny", "bslib", "tidyverse", "plotly", "leaflet", "DT",
    "showtext", "ragg", "htmltools", "lubridate", "scales", "ggthemes", "corrplot"
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
data <- load_data()
analysis <- analyze_relationships(data$air, data$plants)

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

###########################################################
# UI
###########################################################
ui <- bslib::page_navbar(
    title = NULL,
    theme = solarpunk_theme,
    window_title = "Maquerina Mundo — Solarpunk Dashboard",
    header = tags$head(
        tags$link(rel = "stylesheet", href = "style.css"),
        tags$link(rel = "icon", type = "image/jpeg", href = "favicon.jpg")
    ),
    footer = tags$div(
        class = "site-footer",
        tags$span(class = "site-footer-left", HTML("&copy; Alejandro Ines 2025")),
        tags$span(class = "site-footer-right", "Made with Shiny for R")
    ),

    ###########################################################
    # 🏡 HOME
    ###########################################################
    bslib::nav_panel(
        title = "🏡 Home",
        div(
            class = "mm-hero",
            style = "
                background: linear-gradient(
                                        rgba(30,48,41,0.55),
                                        rgba(14,24,21,0.85)
                                    ),
                                    url('solar.JPG') center/cover no-repeat;
                border-radius: 20px;
                padding: 70px 30px;
                text-align:center;
                color:#E9F2E2;
                text-shadow:0 2px 6px rgba(0,0,0,0.4);
            ",
            h1(
                style = "font-weight:700;font-size:2.4rem;color:#E3C567;",
                "Maquerina Mundo — Nature, Light & Data in Harmony"
            ),
            p(
                style = "font-size:1.1rem;max-width:700px;margin:0 auto 15px;",
                "Welcome to a solarpunk world where technology and ecology grow together.
         Discover how climate and plants coexist powered by sunlight and data."
            ),
            div(
                class = "mm-hero-quote",
                tags$p(
                    class = "mm-hero-quote-text",
                    '"A tree falls the way it leans. Be careful which way you lean."',
                    tags$span(class = "mm-hero-quote-author", "~ The Lorax")
                )
            )
        ),
        br(),

        # --- Three framed centered boxes ---
        bslib::layout_columns(
            col_widths = c(4, 4, 4),
            div(
                class = "mm-card mm-framed mm-feature mm-feature-nasa",
                h4("NASA Climate Tracker", style = "text-align:center;"),
                p("Follow real time climate patterns, renewable energy insights, and sustainability progress around the world.",
                    style = "text-align:center;"
                ),
                div(
                    style = "text-align:center;",
                    tags$a(
                        href = "https://climate.nasa.gov/", target = "_blank",
                        class = "mm-btn", "Visit NASA Climate Tracker"
                    )
                )
            ),
            div(
                class = "mm-card mm-framed mm-feature mm-feature-solarpunk",
                h4("Solarpunk Literature & Ideas", style = "text-align:center;"),
                p("Read stories, manifestos, and resources on building brighter ecological futures.",
                    style = "text-align:center;"
                ),
                div(
                    style = "text-align:center;",
                    tags$a(
                        href = "https://iandennismiller.github.io/solarpunk/",
                        target = "_blank", class = "mm-btn", "Solarpunk Resources"
                    )
                )
            ),
            div(
                class = "mm-card mm-framed mm-feature mm-feature-news",
                h4("Positive Climate News", style = "text-align:center;"),
                p("Stay updated with hopeful, solution oriented stories about climate progress.",
                    style = "text-align:center;"
                ),
                div(
                    style = "text-align:center;",
                    tags$a(
                        href = "https://www.dailyclimate.org/good-news/",
                        target = "_blank", class = "mm-btn", "Good News"
                    )
                )
            )
        ),
    ),

    ###########################################################
    # 🌱 PLANT GROWTH DASHBOARD
    ###########################################################
    bslib::nav_panel(
        title = "🌱 Plant Growth Dashboard",
        bslib::layout_sidebar(
            sidebar = bslib::sidebar(
                open = TRUE,
                # add mm-framed so the sidebar card has the same yellow frame as other boxes
                div(
                    class = "mm-card mm-framed",
                    h4("Filter", class = "mm-card-title"),
                    p("Select Species:", class = "mm-sidebar-label"),
                    selectInput("species", NULL,
                        choices = unique(analysis$summary$species),
                        selected = "Monstera"
                    ),
                    p("Minimum Humidity:", class = "mm-sidebar-label"),
                    sliderInput("humidity", NULL, min = 30, max = 90, value = 50),
                    p(
                        style = "color:#E9F2E2;margin-top:10px;",
                        "Correlation between Temperature and Ozone_Level: 0.7"
                    )
                )
            ),
            bslib::layout_columns(
                col_widths = c(6, 6),
                div(class = "mm-card mm-framed", plotlyOutput("growth_plot", height = "380px")),
                div(class = "mm-card mm-framed", leafletOutput("plant_map", height = 380))
            )
        )
    ),

    ###########################################################
    # ☀️ CLIMATE EXPLORER
    ###########################################################
    bslib::nav_panel(
        title = "☀️ Climate Explorer",
        bslib::layout_columns(
            col_widths = c(6, 6),
            div(class = "mm-card mm-framed", plotlyOutput("climate_plot", height = "420px")),
            div(class = "mm-card mm-framed", plotOutput("cor_heatmap", height = "420px"))
        )
    ),

    ###########################################################
    # 📊 DATA TABLE
    ###########################################################
    bslib::nav_panel(
        title = "📊 Data Table",
        div(class = "mm-card mm-framed", DTOutput("data_table"))
    )
)

###########################################################
# SERVER
###########################################################
server <- function(input, output, session) {
    # static hero quote; rotating quotes removed

    # --- Text Summary ---
    output$cor_summary <- renderText({
        cor_summary(data$air, "Temperature", "Ozone_Level")
    })

    # --- Filtered Plant Data ---
    filtered_data <- reactive({
        analysis$summary %>%
            dplyr::filter(species == input$species & humidity >= input$humidity)
    })

    # --- Growth Plot ---
    output$growth_plot <- renderPlotly({
        plot_growth_distribution(filtered_data())
    })

    # --- Plant Map ---
    output$plant_map <- renderLeaflet({
        map_random_plants(filtered_data())
    })

    # --- Climate Plot ---
    output$climate_plot <- renderPlotly({
        plot_climate_trend(data$air)
    })

    # --- Correlation Heatmap ---
    output$cor_heatmap <- renderPlot({
        corr <- cor(data$air[, c("Ozone_Level", "Solar.R", "Wind", "Temperature")], use = "complete.obs")
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
