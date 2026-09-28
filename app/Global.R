library(dplyr)
library(readr)
library(ggplot2)
library(viridis)
library(plotly)

# Read data
df_hm <- read_csv('../data/HazardMitigationAssistanceProjects.csv')
df_disaster <- read_csv('../data/DisasterDeclarationsSummaries.csv')

# Merge Dataframes
merged <- left_join(df_hm, df_disaster %>% select(disasterNumber, incidentType), by = 'disasterNumber')
df_hm <- merged

# Calculate Percentage Obligated
df_hm <- df_hm %>% mutate(
  percentage_obligated = case_when(
    projectAmount == 0 & federalShareObligated == 0 ~ 0,
    projectAmount == 0 & federalShareObligated != 0 ~ 100,
    TRUE ~ (federalShareObligated / projectAmount) * 100
  )
)

# Group by state and calculate mean percentage
statewise_percentage <- df_hm %>% group_by(state) %>%
  summarise(percentage_obligated = mean(percentage_obligated, na.rm = TRUE)) %>%
  ungroup()

# Dictionary to map full state names to abbreviations
state_to_code <- c(
  'Alabama' = 'AL', 'Alaska' = 'AK', 'Arizona' = 'AZ', 'Arkansas' = 'AR', 'California' = 'CA', 'Colorado' = 'CO',
  'Connecticut' = 'CT', 'Delaware' = 'DE', 'Florida' = 'FL', 'Georgia' = 'GA', 'Hawaii' = 'HI', 'Idaho' = 'ID',
  'Illinois' = 'IL', 'Indiana' = 'IN', 'Iowa' = 'IA', 'Kansas' = 'KS', 'Kentucky' = 'KY', 'Louisiana' = 'LA',
  'Maine' = 'ME', 'Maryland' = 'MD', 'Massachusetts' = 'MA', 'Michigan' = 'MI', 'Minnesota' = 'MN', 'Mississippi' = 'MS',
  'Missouri' = 'MO', 'Montana' = 'MT', 'Nebraska' = 'NE', 'Nevada' = 'NV', 'New Hampshire' = 'NH', 'New Jersey' = 'NJ',
  'New Mexico' = 'NM', 'New York' = 'NY', 'North Carolina' = 'NC', 'North Dakota' = 'ND', 'Ohio' = 'OH', 'Oklahoma' = 'OK',
  'Oregon' = 'OR', 'Pennsylvania' = 'PA', 'Rhode Island' = 'RI', 'South Carolina' = 'SC', 'South Dakota' = 'SD',
  'Tennessee' = 'TN', 'Texas' = 'TX', 'Utah' = 'UT', 'Vermont' = 'VT', 'Virginia' = 'VA', 'Washington' = 'WA',
  'West Virginia' = 'WV', 'Wisconsin' = 'WI', 'Wyoming' = 'WY'
)

# Assign state codes
statewise_percentage$state_code <- unlist(state_to_code[statewise_percentage$state])

# Group by incidentType and calculate the total federalShareObligated
incident_stats <- df_hm %>% 
  filter(!is.na(incidentType)) %>% 
  group_by(incidentType) %>%
  summarise(total_federal_share = sum(federalShareObligated, na.rm = TRUE))

# Calculate the threshold: 1% of the mean
threshold <- 0.01 * mean(incident_stats$total_federal_share)

# Filter out incident types with values below the threshold
filtered_incident_stats <- incident_stats %>%
  filter(total_federal_share > threshold)

# Adjusted plot for total federal share obligated by incident type
p <- ggplot(data = filtered_incident_stats, 
            aes(x = reorder(incidentType, total_federal_share), 
                y = total_federal_share / 1e9, # Convert to billions
                fill = total_federal_share)) +
  geom_bar(stat = "identity") +
  scale_fill_viridis_c() +
  coord_flip() +
  labs(title = "Total Federal Share Obligated by Incident Type", 
       x = "Incident Type",
       y = "Total Federal Share Obligated (in billions)") +  # Indicate that y values are in billions
  theme_minimal() +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(linetype = "dashed"),
        axis.text.y = element_text(size = 12)) + 
  scale_y_continuous(labels = scales::comma)  # Use comma as a thousands separator

