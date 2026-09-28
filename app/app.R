library(shiny)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(ggplot2)
library(tidyr)
library(plotly)

# Shiny only auto-sources global.R for the server.R/ui.R directory
# convention, not for the single-file app.R convention used here - so it's
# sourced explicitly. Provides: mission_data, state_obligation,
# incident_type_plot, feature_importance_plot, ny_forecast_plot,
# season_levels.
source("global.R")

ui <- fluidPage(
  tags$head(
    tags$style(
      HTML(
        "
        #intro {
          background: url('https://images.unsplash.com/photo-1536245344390-dbf1df63c30a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2073&q=80') no-repeat center center fixed;
          background-size: cover;
          position: fixed;
          top: 14.2%;
          left: 0;
          height: 90%;
          width: 100%;
          z-index: -1;
        }
        .well {
          margin-top: 110px;
        }
        "
      )
    )
  ),
  titlePanel("Hazard Mitigation Analysis"),
  tabsetPanel(
    tabPanel(
      "Introduction",
      div(id = "intro"),
      fluidRow(
        column(
          12,
          wellPanel(
            class = "intro-text",
            style = "max-width: 800px; margin: auto; margin-top: 100px;",
            tags$h1("How can citizens know and prepare for local disasters, and how can the government distribute adequate funds to disasters?"),
            tags$p(
              "From COVID-19 to hurricanes, unexpected disasters can happen any time at any place. Living in New York City, it's vital to be prepared.
              The Hazard Mitigation Assistance (HMA) Projects dataset contains information on disaster risk reduction projects that have been funded by the Federal Emergency Management Agency (FEMA)."
            ),
            tags$p(
              "This Shiny app is designed to help citizens prepare for and respond to disasters, and to give government agencies information to allocate future funds where they matter most."
            )
          )
        )
      )
    ),
    tabPanel(
      "Disaster geo distribution",
      sidebarLayout(
        sidebarPanel(
          selectInput("disasterType", "Select Disaster Type",
            choices = sort(unique(mission_data$disasterDescription)),
            selected = "Fire"
          ),
          selectInput("selectedYear", "Select Year",
            choices = c("All", sort(unique(mission_data$year))),
            selected = "All"
          )
        ),
        mainPanel(
          leafletOutput("disasterMap", width = "100%", height = "600px")
        )
      )
    ),
    tabPanel(
      "Disaster time distribution",
      sidebarLayout(
        sidebarPanel(
          selectInput("disasterTypeSeason", "Select Disaster Type",
            choices = sort(unique(mission_data$disasterDescription)),
            selected = "Hurricane"
          )
        ),
        mainPanel(
          plotOutput("seasonalPlot", width = "100%", height = "600px")
        )
      )
    ),
    tabPanel(
      "Fund percentage allocation",
      fluidRow(
        tags$style(type = "text/css", "#incidentTypePlot { margin-top: 20px; }"),
        column(6, offset = 2, plotOutput("incidentTypePlot", width = "150%", height = "600px"))
      )
    ),
    tabPanel(
      "Fund allocation by disasters",
      fluidRow(
        tags$style(type = "text/css", "#choroplethMap { margin-top: 20px; }"),
        column(6, offset = 2, plotlyOutput("choroplethMap", width = "150%", height = "800px"))
      )
    ),
    tabPanel(
      "Crucial fund amount factors",
      fluidRow(
        column(2),
        column(
          8,
          offset = 1,
          tags$div(style = "padding-top: 40px;"),
          plotOutput("featureImportancePlot", width = "80%", height = "500px")
        ),
        column(2)
      )
    ),
    tabPanel(
      "NY 2024 disaster pred",
      fluidRow(
        column(2),
        column(
          8,
          offset = 1,
          tags$div(style = "padding-top: 40px;"),
          plotOutput("pieChartPlot", width = "80%", height = "500px")
        ),
        column(2)
      )
    ),
    tabPanel(
      "References",
      fluidRow(
        column(
          12,
          wellPanel(
            tags$h1("Data Sources"),
            tags$ul(
              tags$li("https://www.fema.gov/openfema-data-page/mission-assignments-v1"),
              tags$li("https://www.fema.gov/openfema-data-page/hazard-mitigation-assistance-projects-v3"),
              tags$li("https://www.fema.gov/openfema-data-page/disaster-declarations-summaries-v2"),
              tags$li("https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html")
            ),
            tags$h1("About"),
            tags$p(
              "Originally built as a team project for Columbia's GR5243 Applied Data Science (Fall 2023); ",
              "refactored and maintained here as an individual portfolio project."
            ),
            tags$h1("GitHub Repository"),
            tags$a(
              href = "https://github.com/BessiePengjinWang/Hazard-Mitigation-Analysis",
              "https://github.com/BessiePengjinWang/Hazard-Mitigation-Analysis"
            )
          )
        )
      )
    )
  )
)

server <- function(input, output) {
  output$disasterMap <- renderLeaflet({
    filtered_data <- if (input$selectedYear == "All") {
      mission_data[mission_data$disasterDescription == input$disasterType, ]
    } else {
      mission_data[mission_data$disasterDescription == input$disasterType & mission_data$year == as.integer(input$selectedYear), ]
    }

    disaster_counts <- filtered_data %>%
      group_by(latitude, longitude) %>%
      summarise(Disaster_Count = n(), .groups = "drop")

    leaflet(disaster_counts) %>%
      addTiles() %>%
      addHeatmap(
        lng = ~longitude,
        lat = ~latitude,
        intensity = ~Disaster_Count,
        radius = 15,
        blur = 15,
        max = max(disaster_counts$Disaster_Count, 1),
        minOpacity = 0.5
      )
  })

  output$seasonalPlot <- renderPlot({
    seasonal_data <- mission_data[mission_data$disasterDescription == input$disasterTypeSeason, ] %>%
      group_by(season) %>%
      summarise(Disaster_Count = n(), .groups = "drop") %>%
      complete(season = season_levels, fill = list(Disaster_Count = 0))

    ggplot(seasonal_data, aes(x = factor(season, levels = season_levels), y = Disaster_Count)) +
      geom_bar(stat = "identity", fill = "royalblue") +
      labs(
        title = paste("Seasonal Distribution of", input$disasterTypeSeason, "Occurrences"),
        x = "Season",
        y = "Number of Disasters"
      ) +
      theme_minimal()
  })

  output$incidentTypePlot <- renderPlot({
    incident_type_plot
  })

  output$choroplethMap <- renderPlotly({
    custom_hover_text <- paste(
      state_obligation$state, "<br>",
      "Percentage Obligated: ", round(state_obligation$percentage_obligated, 2), "%"
    )

    plot_ly(
      data = state_obligation,
      z = ~percentage_obligated,
      locations = ~state_code,
      locationmode = "USA-states",
      type = "choropleth",
      colorscale = list(
        c(0, "#2c2c2c"),
        c(0.5, "#6a3d9a"),
        c(0.6, "#1f78b4"),
        c(0.62, "#4575b4"),
        c(0.65, "#74add1"),
        c(0.68, "#abd9e9"),
        c(0.7, "#33a02c"),
        c(0.85, "#ffff99"),
        c(0.99, "#ff7f00"),
        c(1, "#e31a1c")
      ),
      zmin = 0,
      zmax = 100,
      text = custom_hover_text,
      hoverinfo = "text"
    ) %>%
      layout(
        title = "Percentage Obligated by State",
        geo = list(scope = "usa")
      )
  })

  output$featureImportancePlot <- renderPlot({
    feature_importance_plot
  })

  output$pieChartPlot <- renderPlot({
    ny_forecast_plot
  })
}

shinyApp(ui = ui, server = server)
