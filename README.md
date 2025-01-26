# sorghum-sugarcane-RBCS-RAF1-2024

## Overview

This repository includes data sets and R scripts that were used to perform
analysis and produce figures for the manuscript titled "Adapting C4
photosynthesis to atmospheric change and increasing productivity by elevating
Rubisco content in Sorghum and Sugarcane," published in PNAS (full citation
will be added later).

## Scripts

Subdirectories of the `Sorghum Field Gas exchange`,
`Sorghum Greenhouse Gas exchange`, and `Sugarcane Greenhouse Gas exchange`
directories contains R scripts that were used for the analysis. These scripts
have been tested using the following installation:

- Windows:
  - R version 4.4.2 (2024-10-31 ucrt)
  - Platform: x86_64-w64-mingw32
  - Microsoft Windows 11 Enterprise version 10.0.26100 Build 26100

These scripts use version `0.11.0` of the
[PhotoGEA R package](https://eloch216.github.io/PhotoGEA/) for processing and
analyzing gas exchange data.

### Required R packages

The scripts in this directory require several R packages: `lattice`, `ggplot2`,
and `PhotoGEA` (version `0.11.0`):

- The `lattice` package can be installed from within R using
  ```r
  install.packages('lattice')
  ````

- The `ggplot2` package can be installed from within R using
  ```r
  install.packages('ggplot2')
  ```

- The required version of `PhotoGEA` can be installed from within R by calling
  ```r
  remotes::install_github('eloch216/PhotoGEA', ref = 'v0.11.0')
  ```
  Note that this command requires the `remotes` package, which can be installed
  using
  ```r
  install.packages('remotes')
  ```

### Other instructions

To run these scripts, it is recommended to first download a local copy of this
entire repository.

Additional instructions for running the scripts can be found in the `README.md`
files in each directory that contains R scripts.

## License
This repository is licensed under the CC BY 4.0
(https://creativecommons.org/licenses/by/4.0/)
