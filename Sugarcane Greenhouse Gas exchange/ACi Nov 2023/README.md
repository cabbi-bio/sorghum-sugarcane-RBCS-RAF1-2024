# Field gas exchange

## Overview

This directory contains data and analysis scripts used to fit CO2 response
curves measured from greenhouse-grown sugarcane plants on November 16-17, 2023.

## Files

- Ten Microsoft Excel files whose names begin with `2023`: Licor LI-6800
  log files.

- `sugarcane_c4_co2_response.R`: An R script that estimates Vpmax and Vcmax
  from the measured gas exchange data

## Running the script from R

1. Set the working directory of an R session to this directory.

2. Type the following to run the A-Ci script:

   ```r
   source('sugarcane_c4_co2_response.R')
   ```

3. The `process_aci` script will produce several graphs in the R workspace, as
   well as output PDF and CSV files in this directory.

*WARNING:* This script will automatically clear your workspace before it runs.
