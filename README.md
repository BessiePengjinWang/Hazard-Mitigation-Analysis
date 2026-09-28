# Hazard Mitigation Analysis: A Shiny App on FEMA Mitigation Funding

GR5243 Applied Data Science, Project 2 (Team 7, Fall 2023)

Live app: https://drake-wang-2000.shinyapps.io/project2/

Forked from the [original team repository](https://github.com/drakewang2000/ADS-Fall2023-Project2-ShinyApp-Group7).

![screenshot](doc/figs/main_fig.png)

## Overview

An interactive Shiny app built on FEMA's Hazard Mitigation Assistance (HMA) data, with New York City as the focal point. It shows where and when disasters occur, how federal mitigation funds are allocated, and which factors drive fund amounts. The goal is to help residents prepare for likely hazards and to give policymakers evidence for future funding decisions.

## Data

- [OpenFEMA Hazard Mitigation Assistance Projects v3](https://www.fema.gov/about/openfema/data-sets): funded projects (financial obligation to grantees) under FEMA's three HMA grant programs
- OpenFEMA Disaster Declarations Summaries v1: used to add disaster type detail

## App pages

1. **Disaster geography:** heat map of disaster occurrences by type
2. **Disaster timing:** seasonal distribution of disasters by type
3. **Fund allocation:** share of requested funds obligated by state, and total federal share obligated by incident type
4. **Fund drivers and prediction:** random forest feature importance for federal share obligated, and a predicted disaster type distribution for New York in 2024

## Methods and findings

- **Obligated %** = obligation amount / requested amount. **Benefit-cost ratio (BCR)** = total discounted annualized benefits / total annualized cost.
- Across all projects, obligated % and BCR have a weak positive correlation (0.23). The four states with the highest and lowest obligated % show no clear BCR pattern until outliers are removed.
- Incident type shows no significant relationship with BCR or with project accomplishment rate.
- Feature importance is computed by permutation: shuffle one predictor at a time and measure the increase in model MSE. Program area, incident type and state rank highest; program fiscal year and project type rank lower.

## Limitations

- The New York 2024 distribution is a rough estimate from historical data, not a forecast.
- Feature importance covers five manually selected predictors and shows association, not causation.
- Correlations are weak, so the fund allocation findings are descriptive.

## Repository structure

```
proj/
├── app/      Shiny app code
├── lib/      helper functions
├── data/     datasets
├── doc/      project description and figures
└── output/   generated outputs
```

Each subfolder contains its own README. Structure follows [nicercode](http://nicercode.github.io/blog/2013-04-05-projects/) project organization suggestions.

## My contribution

- Wrote the project introduction and performed EDA on disaster trends
- Ran and evaluated the random forest models (fund amount factor importance and NY 2024 disaster prediction)
- Produced the feature importance bar chart and the NY 2024 prediction pie chart
- Revised and finalized the main R file
- Organized all team meetings and task allocation
- Created the presentation slides and presented the full project, including analyses and limitations