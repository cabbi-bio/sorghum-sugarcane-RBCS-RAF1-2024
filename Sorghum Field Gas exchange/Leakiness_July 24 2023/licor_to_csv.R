library(PhotoGEA)

# Clear the workspace
rm(list=ls())

# This function will convert a Licor LI-6800 file (either Excel or plaintext) to
# a csv file with a new `Hour` column as required by Yu Wang's MATLAB code for
# processing TDL leakiness measurements.
licor_to_csv <- function(tdl_fpath, licor_fpath) {
    # Load TDL file
    tdl_file <- read_gasex_file(tdl_fpath, 'TIMESTAMP')$main_data

    # Get the TDL start time as an H, M, S triplet
    tdl_start <- c(
        as.numeric(format(tdl_file$TIMESTAMP[1], format = '%H')),
        as.numeric(format(tdl_file$TIMESTAMP[1], format = '%M')),
        as.numeric(format(tdl_file$TIMESTAMP[1], format = '%S'))
    )

    # Load Licor file
    licor_file <- read_gasex_file(licor_fpath)$main_data

    # Get the subset of the data where Qin is zero; these are the data points
    # recorded for Rd measurements
    rd_subset <- licor_file[licor_file$Qin == 0, ]

    # Get the last measured value of A from that subset; this is Rd
    rd <- rd_subset$A[nrow(rd_subset)]

    # Get the subset of the data where Qin > 0; these are the data points
    # recorded for leakiness measurements
    leakiness_subset <- licor_file[licor_file$Qin > 0, ]

    # Get the time of the first leakiness measurement
    leakiness_start <- leakiness_subset$hhmmss[1]

    # Convert it into an H, M, S triplet
    leakiness_start <- as.numeric(unlist(strsplit(leakiness_start, ':')))

    # Now convert all the H, M, S times into fractional hour values
    hms <- licor_file[, 'hhmmss']

    hour <- sapply(hms, function(x) {
        info <- as.numeric(unlist(strsplit(x, ':')))
        info[1] + info[2] / 60 + info[3] / 3600
    })

    licor_file$Hour <- hour

    # Keep a subset of the columns in a particular order
    licor_columns_to_keep <- c(
        'obs', 'time', 'elapsed', 'Hour', 'TIME', 'E', 'A', 'Ca', 'Ci', 'Pci',
        'Pca', 'gsw', 'gbw', 'gtw', 'gtc', 'Rabs', 'TleafEB', 'TleafCnd',
        'SVPleaf', 'RHcham', 'VPcham', 'SVPcham', 'VPDleaf', 'LatHFlux',
        'SenHFlux', 'NetTherm', 'EBSum', 'Leak', 'LeakPct', 'CorrFact',
        'CorrFactPct', 'Fan', 'Qin', 'Qabs', 'alpha', 'convert', 'S', 'K',
        'Custom', 'TIME', 'CO2_s', 'CO2_r', 'H2O_s', 'H2O_r', 'CO2_a', 'H2O_a',
        'Flow', 'Pa', 'DeltaPcham', 'Tair', 'Tleaf', 'Tleaf2'
    )

    licor_file <- licor_file[, licor_columns_to_keep]

    # Save the results as a CSV file
    file_base_name <- tools::file_path_sans_ext(basename(licor_fpath))

    write.csv(
        licor_file,
        file = paste0(file_base_name, '.csv'),
        quote = FALSE,
        row.names = FALSE
    )

    # Form the text to paste into `Simulations.m` and return it
    short_base_name <- tools::file_path_sans_ext(basename(licor_fpath))

    return(
        c(
            'clear all;',
            paste0('Rd=', rd, ';'),
            paste0(
                "TDL_leakiness_all('",
                basename(tdl_fpath),
                "', '",
                paste0(short_base_name, '.csv'),
                "', ",
                paste(tdl_start, collapse = ', '),
                ", ",
                paste(leakiness_start, collapse = ', '),
                ", '",
                short_base_name,
                "', Rd, 'Leakiness_",
                paste0(short_base_name, '.txt'),
                "');"
            )
        )
    )
}

# Specify TDL and Licor file paths
sets_to_process <- list(
    list(
        tdl_path = file.path('TDL data', '20230724_TGA Sampling System_RawData.dat'),
        licor_paths = c(
            file.path('Licor data', '2023-07-24 hn1a 1.xlsx'),
            file.path('Licor data', '2023-07-24 hn1a 2.xlsx'),
            file.path('Licor data', '2023-07-24 hn1a 3.xlsx'),
            file.path('Licor data', '2023-07-24 WT 1.xlsx'),
            file.path('Licor data', '2023-07-24 WT 2.xlsx'),
            file.path('Licor data', '2023-07-24 WT 3.xlsx'),
            file.path('Licor data', '2023-07-24 zg12a 1.xlsx'),
            file.path('Licor data', '2023-07-24 zg12a 2.xlsx'),
            file.path('Licor data', '2023-07-24 zg12a 3.xlsx'),
            file.path('Licor data', '2023-07-24 zg5b 1.xlsx'),
            file.path('Licor data', '2023-07-24 zg5b 2.xlsx'),
            file.path('Licor data', '2023-07-24 zg5b 3.xlsx')
        )
    ),
    list(
        tdl_path = file.path('TDL data', '20230725_TGA Sampling System_RawData.dat'),
        licor_paths = c(
            file.path('Licor data', '2023-07-25 hn1a 4.xlsx'),
            file.path('Licor data', '2023-07-25 hn1a 5.xlsx'),
            file.path('Licor data', '2023-07-25 WT 4.xlsx'),
            file.path('Licor data', '2023-07-25 WT 5.xlsx'),
            file.path('Licor data', '2023-07-25 zg12a 4.xlsx'),
            file.path('Licor data', '2023-07-25 zg12a 5.xlsx'),
            file.path('Licor data', '2023-07-25 zg5b 4.xlsx'),
            file.path('Licor data', '2023-07-25 zg5b 5.xlsx')
        )
    ),
    list(
        tdl_path = file.path('TDL data', '20230726_TGA Sampling System_RawData.dat'),
        licor_paths = c(
            file.path('Licor data', '2023-07-26 hn1a 6.xlsx'),
            file.path('Licor data', '2023-07-26 WT 12.xlsx'),
            file.path('Licor data', '2023-07-26 WT 22.xlsx'),
            file.path('Licor data', '2023-07-26 WT 6.xlsx'),
            file.path('Licor data', '2023-07-26 zg5b 6.xlsx')
        )
    )
)

# Initialize the content of `Simulations.m`
simulation_file <- readLines('Simulations_template.txt')

# Process all the files, creating CSV files and generating the content of the
# simulation file
for (set in sets_to_process) {
    tdl_fp <- set$tdl_path

    for (licor_fp in set$licor_paths) {
        print(paste0("Processing '", tdl_fp, "' and '", licor_fp, "'"))

        simulation_file <- append(
            simulation_file,
            licor_to_csv(tdl_fp, licor_fp)
        )
    }
}

# Create the simulation file
writeLines(simulation_file, 'Simulations.m')
