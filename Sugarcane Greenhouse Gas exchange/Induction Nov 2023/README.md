# Induction Nov 2023

## Overview

This directory contains data and analysis scripts used to visualize induction
curves measured from greenhouse-grown sugarcane plants on November 20, 2023.

## Files

- Five Microsoft Excel files whose names begin with `2023`: Licor LI-6800
  log files.

- `Sugarcane_greenhouse_induction.R`: An R script that loads and plots induction
  data

## Running the script from R

1. Set the working directory of an R session to this directory.

2. Type the following to run the script:

   ```r
   source('Sugarcane_greenhouse_induction.R')
   ```

3. The script will produce several graphs in the R workspace.

*WARNING:* This script will automatically clear your workspace before it runs.
