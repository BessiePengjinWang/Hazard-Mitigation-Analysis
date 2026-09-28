# Hazard Mitigation Analysis: A Shiny App on FEMA Mitigation Funding

GR5243 Applied Data Science, Project 2 (Team 7, Fall 2023)

Live app (https://drake-wang-2000.shinyapps.io/project2/)

![screenshot](doc/figs/main_fig.png)

## Overview

An interactive Shiny app built on FEMA's Hazard Mitigation Assistance (HMA) data, with New York City as the focal point. It shows where and when disasters occur, how federal mitigation funds are allocated, and which factors drive fund amounts. The goal is to help residents prepare for likely hazards and to give policymakers evidence for future funding decisions.

## Data

- [OpenFEMA Hazard Mitigation Assistance Projects v3](https://www.fema.gov/about/openfema/data-sets): funded projects (financial obligation to grantees) under FEMA's three HMA grant programs
- OpenFEMA Disaster Declarations Summaries v1 (https://www.fema.gov/about/openfema/data-sets): used to add disaster type detail

## App pages

1. **Disaster geography:** heat map of disaster occurrences by type
2. **Disaster timing:** seasonal distribution of disasters by type
3. **Fund allocation:** share of requested funds obligated by state, and total federal share obligated by incident type
4. **Fund drivers and prediction:** random forest feature importance for federal share obligated, and a predicted disaster type distribution for New York in 2024

## Methods and findings

### Fund allocation analysis
- **Obligated %** = obligation amount / requested amount. **Benefit-cost ratio (BCR)** = total discounted annualized benefits / total annualized cost.
- Across all projects, obligated % and BCR have a weak positive correlation (0.23). The four states with the highest and lowest obligated % show no clear BCR pattern until outliers are removed.
- Incident type shows no significant relationship with BCR or with project accomplishment rate.

### Random forest: drivers of federal share obligated
- **Target:** federal share obligated (`federalShareObligated`)
- **Predictors:** program area, incident type, state, program fiscal year, project type (five manually selected from the available features)
- **Model:** random forest regression ([R package], [number] trees, [train/test split])
- **Importance:** permutation importance, measured as the increase in MSE after shuffling one predictor at a time, computed on [held-out / training] data
- **Result:** program area, incident type and state rank highest; program fiscal year and project type rank lower

### New York 2024 disaster estimate
- Random forest [classifier] trained on [features] to predict incident type, with the output shown as the predicted share of each type for New York in 2024
- A rough estimate from historical data, not a forecast

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

## My contribution

- Wrote the project introduction and performed EDA on disaster trends
- Ran and evaluated the random forest models (fund amount factor importance and NY 2024 disaster prediction)
- Produced the feature importance bar chart and the NY 2024 prediction pie chart
- Revised and finalized the main R file
- Organized all team meetings and task allocation
- Created the presentation slides and presented the full project, including analyses and limitations