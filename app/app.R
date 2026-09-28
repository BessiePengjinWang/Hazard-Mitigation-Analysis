library(shiny)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(ggplot2)
library(tidyr)
library(plotly)
library(caret)
library(randomForest)
library(tidyverse)
library(tidytext)

data <- read.csv("../data/output_file2.csv")
data$dateRequested <- as.Date(data$dateRequested, format="%Y-%m-%d")
data$Month <- format(data$dateRequested, "%m")
data$Season <- ifelse(data$Month %in% c("12", "01", "02"), "Winter",
                      ifelse(data$Month %in% c("03", "04", "05"), "Spring",
                             ifelse(data$Month %in% c("06", "07", "08"), "Summer", "Fall")))

data$Year <- format(data$dateRequested, "%Y")

data <- subset(data, !is.na(disasterDescription))
data <- subset(data, !is.na(Year))
data <- subset(data, !is.na(zip))

# UI
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
    tabPanel("Introduction",
             div(id = "intro"),
             fluidRow(
               column(12,
                      wellPanel(
                        class = "intro-text",
                        style = "max-width: 800px; margin: auto; margin-top: 100px;",
                        tags$h1("How can citizens know and prepare for local disasters, and how can the government distribute adequate funds to disasters?"),
                        tags$p("From COVID-19 to hurricanes, unexpected disasters can happen any time at any place. Living in New York City, it's vital to be prepared.
The Hazard Mitigation Assistance (HMA) Projects dataset contains information on disaster risk reduction projects that have been funded by the Federal Emergency Management Agency (FEMA)."),
                        tags$p("This Shiny app is designed to help citizens to prepare for and respond to disasters, and the government with information on how to prepare and allocate adequate funds in the future.
")
                      )
               )
             )
    ),
    tabPanel("Disaster geo distribution",
             sidebarLayout(
               sidebarPanel(
                 selectInput("disasterType", "Select Disaster Type",
                             choices = unique(data$disasterDescription),
                             selected = "Fire"),
                 selectInput("selectedYear", "Select Year",  
                             choices = c("All", unique(data$Year)), 
                             selected = "All")
               ),
               mainPanel(
                 leafletOutput("disasterMap", width = "100%", height = "600px")
               )
             )
    ),
    tabPanel("Disaster time distribution",
             sidebarLayout(
               sidebarPanel(
                 selectInput("disasterTypeSeason", "Select Disaster Type",
                             choices = unique(data$disasterDescription),
                             selected = "Hurricane")
               ),
               mainPanel(
                 plotOutput("seasonalPlot", width = "100%", height = "600px")
               )
             )
    ),
    tabPanel("Fund percentage allocation",
             fluidRow(
               tags$style(type = "text/css", "#incidentTypePlot { margin-top: 20px; }"),
               column(6, offset = 2, plotOutput("incidentTypePlot", width = "150%", height = "600px"))
             )
    ),
    tabPanel("Fund allocation by disasters",
             fluidRow(
               tags$style(type = "text/css", "#choroplethMap { margin-top: 20px; }"),
               column(6, offset = 2, plotlyOutput("choroplethMap", width = "150%", height = "800px"))
             )
    ),
    tabPanel("Crucial fund amount factors",
             fluidRow(
               column(2),  
               column(8,   
                      offset = 1,  
                      tags$div(style = "padding-top: 40px;"),  
                      plotOutput("featureImportancePlot", width = "80%", height = "500px")
               ),
               column(2)
             )
    ),
    tabPanel("NY 2024 disaster pred",
             fluidRow(
               column(2),  
               column(8,   
                      offset = 1,  
                      tags$div(style = "padding-top: 40px;"),  
                      plotOutput("pieChartPlot", width = "80%", height = "500px")
               ),
               column(2)
             )
    ),
    tabPanel("References",
             fluidRow(
               column(12,
                      wellPanel(
                        tags$h1("Data Sources"),
                        tags$ul(
                          tags$li("https://www.fema.gov/openfema-data-page/mission-assignments-v1"),
                          tags$li("https://www.fema.gov/openfema-data-page/hazard-mitigation-assistance-projects-v3"),
                          tags$li("https://www.fema.gov/openfema-data-page/disaster-declarations-summaries-v2"),
                        ),
                        tags$h1("Contributors"),
                        tags$ul(
                          tags$li("Zhaolin Wang"),
                          tags$li("Yoojin Lee"),
                          tags$li("Bessie Wang"),
                          tags$li("Yitian Shen")
                        ),
                        tags$h1("GitHub Repository"),
                        tags$a(href = "https://github.com/drakewang2000/ADS-Fall2023-Project2-ShinyApp-Group7/tree/master", "https://github.com/drakewang2000/ADS-Fall2023-Project2-ShinyApp-Group7/tree/master")
                      )
               )
             )
    )
  )
)



server <- function(input, output) {
  
  # load Global.R
  source("Global.R")
  
  output$choroplethMap <- renderPlotly({
    custom_hover_text <- paste(statewise_percentage$state, "<br>",
                               "Percentage Obligated: ", round(statewise_percentage$percentage_obligated, 2), "%")
    
    fig <- plot_ly(
      data = statewise_percentage,
      z = ~percentage_obligated,
      locations = ~state_code,
      locationmode = "USA-states",
      type = "choropleth",
      colorscale = list(
        c(0, "#2c2c2c"),     # Dark gray for 0%
        c(0.5, "#6a3d9a"),   # Purple for 50%
        c(0.6, "#1f78b4"),   # Blue for 60%
        c(0.62, "#4575b4"),  # Lighter blue for 62%
        c(0.65, "#74add1"),  # Light blue for 65%
        c(0.68, "#abd9e9"),  # Very light blue for 68%
        c(0.7, "#33a02c"),   # Green for 70%
        c(0.85, "#ffff99"),  # Yellow for 85%
        c(0.99, "#ff7f00"),  # Orange just before 100%
        c(1, "#e31a1c")      # Red for 100%
      )
      ,
      zmin = 0,
      zmax = 100,
      text = custom_hover_text,  # Custom hover text
      hoverinfo = "text"  # Show the custom text on hover
    ) %>%
      layout(
        title = "Percentage Obligated by State",
        geo = list(scope = 'usa')
      )
    fig
  })
  
  output$incidentTypePlot <- renderPlot({
    p
  })
  
  output$incidentTypePlot <- renderPlot({
    p
  })
  
  output$disasterMap <- renderLeaflet({
    filtered_data <- if (input$selectedYear == "All") {
      data[data$disasterDescription == input$disasterType, ]
    } else {
      data[data$disasterDescription == input$disasterType & data$Year == input$selectedYear, ]
    }
    
    disaster_counts <- filtered_data %>%
      group_by(latitude, longitude) %>%
      summarise(Disaster_Count = n(), .groups = 'drop')
    
    disaster_counts <- subset(disaster_counts, !is.na(latitude) & !is.na(longitude))
    
    leaflet(disaster_counts) %>%
      addTiles() %>%
      addHeatmap(
        lng = ~longitude,
        lat = ~latitude,
        intensity = ~Disaster_Count,
        radius = 15,
        blur = 15,
        max = max(disaster_counts$Disaster_Count),
        minOpacity = 0.5
      )
  })
  
  # Random forest for feature selection
  output$featureImportancePlot <- renderPlot({
    hm_data <- read_csv("../data/HazardMitigationAssistanceProjects.csv")
    # load summary data containing identifier number
    summary_data <- read_csv("../data/DisasterDeclarationsSummaries.csv")
    summary_data <- summary_data %>%
      select(disasterNumber, incidentType, title)
    hm_data <- inner_join(summary_data, hm_data, by = 'disasterNumber')
    
    hm_data <- na.omit(hm_data)
    hm_data <- hm_data %>%
      select(incidentType, programArea, programFy, state, projectType, federalShareObligated, benefitCostRatio)
    
    hm_data <- arrange(hm_data, programFy)
    hm_data <- hm_data[hm_data$programFy >= 2013, ]
    
    set.seed(123)
    train_index <- createDataPartition(hm_data$federalShareObligated, p = 0.8, list = FALSE)
    train_set <- hm_data[train_index, ]
    test_set <- hm_data[-train_index, ]
    
    rf_model <- randomForest(federalShareObligated ~ ., data = train_set, ntree = 10)
    
    original_mse <- mean(rf_model$mse)
    
    feature_importance <- numeric(ncol(train_set) - 1)
    
    for (i in 1:(ncol(train_set) - 1)) {
      temp_data <- train_set
      temp_data[, i] <- sample(temp_data[, i])
      temp_rf <- randomForest(federalShareObligated ~ ., data = temp_data, ntree = 10)
      feature_importance[i] <- original_mse - mean(temp_rf$mse)
    }
    
    names(feature_importance) <- colnames(train_set)[-ncol(train_set)]
    print(feature_importance)
    
    log_feature_importance <- log(feature_importance)
    
    plot_data <- data.frame(
      Feature = names(log_feature_importance),
      LogImportance = log_feature_importance
    )
    
    write.csv(plot_data, file = "../data/plot_data.csv", row.names = FALSE)
    imported_data <- read.csv("../data/plot_data.csv")
    
    ggplot(imported_data, aes(x = Feature, y = LogImportance)) +
      geom_bar(stat = "identity", fill = "seagreen") +
      labs(title = "Log-Transformed Feature Importance",
           x = "Feature",
           y = "Log Importance Value") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      coord_cartesian(ylim = c(min(plot_data$LogImportance) - 0.2, 27))
  })
  
  output$seasonalPlot <- renderPlot({
    seasonal_data <- data[data$disasterDescription == input$disasterTypeSeason, ] %>%
      group_by(Season, disasterDescription) %>%
      summarise(Disaster_Count = n(), .groups = 'drop') %>%
      complete(Season = unique(data$Season), disasterDescription, fill = list(Disaster_Count = 0))
    
    custom_season_levels <- c("Spring", "Summer", "Fall", "Winter")
    ggplot(seasonal_data, aes(x = factor(Season, levels = custom_season_levels), y = Disaster_Count, fill = disasterDescription)) +
      geom_bar(stat='identity', position='stack') +
      scale_fill_manual(values = c("royalblue")) +
      labs(title = "Seasonal Disaster Occurrences by Type",
           x = "Season",
           y = "Number of Disasters")
  })
  
  # Random forest for NY 2024 prediction
  output$pieChartPlot <- renderPlot({
    pa_data <- read.csv("../data/PublicAssistanceFundedProjectsDetails.csv")
    summary_data <- read.csv("../data/DisasterDeclarationsSummaries.csv")
    
    pa_data$declarationDate <- as.POSIXct(pa_data$declarationDate, format = "%Y-%m-%dT%H:%M:%OSZ")
    
    ny_data <- pa_data %>%
      filter(state == "New York")
    ny_data <- ny_data %>%
      arrange(declarationDate) %>%
      select(disasterNumber,declarationDate, incidentType)
    duplicates <- duplicated(ny_data)
    ny_data <- data.frame(subset(ny_data,!duplicates))
    rownames(ny_data) <- 1:nrow(ny_data)
    ny_data <- ny_data %>%
      mutate(year_month = format(declarationDate, format = "%Y-%m"))
    
    ny_data$year <- as.integer(substr(ny_data$year_month, 1, 4))
    ny_data$month <- as.integer(substr(ny_data$year_month, 6, 7))
    
    set.seed(123)
    split_ratio <- 0.8
    ny_data$incidentType <- as.factor(ny_data$incidentType)
    total_rows <- nrow(ny_data)
    train_rows <- floor(total_rows * split_ratio)
    train_index <- sample(1:total_rows, train_rows)
    
    training_data_pa <- ny_data[train_index, ]
    testing_data_pa <- ny_data[-train_index, ]
    
    prediction_data <- data.frame(year = rep(2024, 12), month = 1:12)
    
    # since we don't care much about error rate, we used all data
    # can also use prediction_data as training data
    model_pa <- randomForest(incidentType ~ year + month, data = ny_data)
    predictions_pa <- predict(model_pa, newdata = prediction_data)
    
    # drew pie chart for one specific output for faster loading times
    # output will change from time to time
    # can run the algorithm on your own to see results
    incidentTypeCounts <- data.frame(
      incidentType = c(
        "Snowstorm", "Severe Storm", "Severe Storm", "Severe Storm", "Tornado",
        "Severe Storm", "Hurricane", "Hurricane", "Flood", "Hurricane", "Snowstorm"
      ),
      count = c(1, 3, 1, 1, 1, 1, 2, 2, 1, 1, 1)
    )
    
    ggplot(incidentTypeCounts, aes(x = "", y = count, fill = incidentType)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar(theta = "y") +
      labs(title = "Pie Chart of Hazard Types in New York (Prediction)") +
      theme_void() +
      scale_fill_brewer(palette = "Set2")
  })
  
  
}

shinyApp(ui = ui, server = server)
