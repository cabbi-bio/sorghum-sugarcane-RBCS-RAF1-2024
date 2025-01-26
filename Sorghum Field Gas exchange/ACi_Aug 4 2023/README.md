# ACi_Aug 4 2023

## Overview

This directory contains data and analysis scripts used to fit CO2 response
curves measured from field-grown sorghum plants on August 4, 2023.

## Files

- Three Microsoft Excel files whose names begin with `2023`: Licor LI-6800
  log files.

- `Sb_Field_Aug4_c4_co2_response.R`: An R script that estimates Vpmax and Vcmax
  from the measured gas exchange data

## Running the script from R

1. Set the working directory of an R session to this directory.

2. Type the following to run the script:

   ```r
   source('Sb_Field_Aug4_c4_co2_response.R')
   ```

3. The script will produce several graphs in the R workspace, as well as output
   PDF and CSV files in this directory.

*WARNING:* This script will automatically clear your workspace before it runs.
