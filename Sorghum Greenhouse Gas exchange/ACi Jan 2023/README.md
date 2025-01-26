# ACi Jan 2023

## Overview

This directory contains data and analysis scripts used to fit CO2 response
curves measured from greenhouse-grown sorghum plants on January 24-26, 2023.

## Files

- Eight Microsoft Excel files whose names begin with `2023`: Licor LI-6800
  log files.

- `Sb_GH_c4_co2_response.R`: An R script that estimates Vpmax and Vcmax
  from the measured gas exchange data

## Running the script from R

1. Set the working directory of an R session to this directory.

2. Type the following to run the script:

   ```r
   source('Sb_GH_c4_co2_response.R')
   ```

3. The script will produce several graphs in the R workspace, as well as output
   PDF and CSV files in this directory.

*WARNING:* This script will automatically clear your workspace before it runs.
