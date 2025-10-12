
# Maquerina Mundo

Modeling the harmony between nature, climate, and machines.

Author: Alejandro (Alex) Ines

## Overview
Maquerina Mundo is a solarpunk-inspired Shiny dashboard that explores the relationships between climate variables and indoor plant health. The app combines climate data visualizations, spatial mapping of plant locations, and interactive controls to help users explore how temperature, humidity, solar radiation, and other factors correlate with plant growth.

The project was inspired by a personal love for plants, hiking, and the outdoors, and a desire to make climate data feel accessible and hopeful. It blends aesthetic design and data-first storytelling to encourage sustainable thinking.

## Features
- Interactive climate trend plots and correlation heatmaps
- Filterable plant growth dashboard with map and distribution plots
- Data table browsing and export
- Curated hero presentation with editorial quote

## Local setup
Prerequisites: R >= 4.0

1. From the repository root, install packages listed in `requirements.txt` (run inside R):

```r
pkgs <- readLines('requirements.txt')
install.packages(pkgs)
```

2. Run the Shiny app:

```bash
R -e "shiny::runApp('.', launch.browser = TRUE)"
```

## Files of interest
- `app.R` — main Shiny UI and server logic
- `www/` — static assets (images, CSS)
- `R/` — helper scripts for data loading, analysis, and visualization
- `data/` — CSV datasets

## Dependencies
See `requirements.txt` for R package dependencies used by the project.

## Design & Inspiration
Solarpunk aesthetics, a love of plants and hiking, and concern about climate change influenced the project. The visual language uses warm solar golds and verdant greens to communicate optimism and regeneration.

## License & Credit
Author: Alejandro Ines. Please credit the author when reusing or adapting this work.

## Contact
Open an issue or contact the author directly for collaboration.


