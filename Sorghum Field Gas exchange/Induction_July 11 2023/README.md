# Induction_July 11 2023

## Overview

This directory contains data and analysis scripts used to visualize induction
curves measured from field-grown sorghum plants on July 11, 2023.

## Files

- Four Microsoft Excel files whose names begin with `2023`: Licor LI-6800
  log files.

- `Sb_field_July11_induction.R`: An R script that loads and plots induction
  data

## Running the script from R

1. Set the working directory of an R session to this directory.

2. Type the following to run the script:

   ```r
   source('Sb_field_July11_induction.R')
   ```

3. The script will produce several graphs in the R workspace.

*WARNING:* This script will automatically clear your workspace before it runs.
