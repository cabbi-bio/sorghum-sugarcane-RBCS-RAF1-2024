# Leakiness_July 24 2023

## Overview

This directory contains data and analysis scripts used to process and analyze
bundle sheath leakiness values measured from field-grown sorghum plants on
July 24-26, 2023.

## Files and Directories

- The `Licor data` directory contains twenty-five Licor LI-6800 log files

- The `TDL data` directory contains three tunable diode laser (TDL) log files

- The `licor_to_csv.R` script loads each Licor file and re-saves it as a CSV
  file that can be used as an input for the Matlab scripts (described below).
  It also generates `Simulations.m`, a MATLAB script that runs the MATLAB
  processing code. `Simulations_template.txt` is a template for `Simulations.m`.

- Six MATLAB script files (ending with a `.m` file extension) modified from
  the originals that can be found in the following data repository:
  https://doi.org/10.13012/B2IDB-1181155_V1. These files use the Licor and TDL
  data to calculate leakiness values.

- The `Leakiness` directory contains twenty-five text files with leakiness
  values, as created by the MATLAB scripts. Each leakiness file corresponds to
  a Licor file in `Licor data`.

- The `make_plots.R` script generates a few plots in R and saves average
  leakiness values to a CSV file.

- The `RBCS-RAF1_Sorghum_Field_Leakiness.xlsx` spreadsheet is an archived
  version of the average leakiness values calculated by `make_plots.R`.

## Reproducing the Analysis

1. Set the working directory of an R session to this directory.

2. Type the following to generate the CSV files and `Simulations.m`:

   ```r
   source('licor_to_csv.R')
   ```

3. Set the working directory of a MATLAB session to this directory.

4. Execute the commands in `Simulations.m` to generate leakiness text files.
   A copy of these files can be found in the `Leakiness` directory.

5. Set the working directory of an R session to this directory.

6. Type the following to generate a CSV file with average leakiness values:

   ```r
   source('make_plots.R')
   ```

*WARNING:* The R scripts will automatically clear your workspace before running.
