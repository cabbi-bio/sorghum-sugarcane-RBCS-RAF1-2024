# Load required packages
library(PhotoGEA)
library(lattice)

# Check to make sure we have the correct version of PhotoGEA
if (packageVersion('PhotoGEA') != '0.11.0') {
    stop(
        'The `Sb_Field_July10_c4_co2_response.R` script requires PhotoGEA version ',
        '0.11.0. See the main README.md for installation instructions.'
    )
}

# Clear the workspace
rm(list=ls())

# Decide whether to save average response curves to PDF
SAVE_TO_PDF <- TRUE

# Specify a value for mesophyll conductance
GM_VALUE <- 3  # mol / m^2 / s / bar
GM_UNITS <- 'mol m^(-2) s^(-1) bar^(-1)'
GM_TABLE <- list()

 # Initialize the input files
LICOR_FILES_TO_PROCESS <- c(
    '2023-07-10 sorghum cabbi.xlsx',
    '2023-07-10 sorghum ripe 2.xlsx',
    '2023-07-10 sorghum ripe 3.xlsx',
    '2023-07-10 sorghum rogue.xlsx'
)

# Specify which measurement numbers to choose. Here, the numbers refer to
# points along the sequence of A-Ci measurements.
#
# These numbers have been chosen for a sequence with 15 measurements. Points 1,
# 8, 9, and 10 all have the CO2 setpoint set to 400. Here we only want to keep
# the first one, so we exclude points 8 and 9.
NUM_OBS_IN_SEQ <- 15
MEASUREMENT_NUMBERS_TO_REMOVE <- c(8, 9, 10, 15)
POINT_FOR_BOX_PLOTS <- 1

# Decide whether to remove a few specific points from the data before fitting
REMOVE_SPECIFIC_POINTS <- TRUE

# Decide whether to average over plots
AVERAGE_OVER_PLOTS <- TRUE

# Decide which solver to use
solver <- optimizer_deoptim(itermax = 200)

# Specify the names of a few important columns
A_COLUMN_NAME              <- 'A'
CI_COLUMN_NAME             <- 'Ci'
DELTA_PRESSURE_COLUMN_NAME <- 'DeltaPcham'
EVENT_COLUMN_NAME          <- 'event'
GM_COLUMN_NAME             <- 'gmc'
GS_COLUMN_NAME             <- 'gsw'
PRESSURE_COLUMN_NAME       <- 'Pa'
REP_COLUMN_NAME            <- 'replicate'
TIME_COLUMN_NAME           <- 'time'
TLEAF_COLUMN_NAME          <- 'TleafCnd'

UNIQUE_ID_COLUMN_NAME <- 'line_sample'

# Define a function that averages across key columns in an exdf object
avg_exdf <- function(exdf_obj) {
    id_columns <- c(
        EVENT_COLUMN_NAME,
        'plot',
        UNIQUE_ID_COLUMN_NAME,
        'seq_num',
        'CO2_r_sp'
    )

    avg_obj <- exdf_obj[1, id_columns, TRUE]

    col_to_avg <- c(
        A_COLUMN_NAME,
        CI_COLUMN_NAME,
        'Ca',
        PRESSURE_COLUMN_NAME,
        GS_COLUMN_NAME,
        DELTA_PRESSURE_COLUMN_NAME,
        TLEAF_COLUMN_NAME,
        'E',
        'gbw',
        'H2O_s'
    )

    for (cn in col_to_avg) {
        avg_obj <- set_variable(
            avg_obj,
            cn,
            exdf_obj$units[[cn]],
            exdf_obj$category[[cn]],
            mean(exdf_obj[, cn])
        )
    }

    return(avg_obj)
}

###                                                                   ###
### COMMANDS THAT ACTUALLY CALL THE FUNCTIONS WITH APPROPRIATE INPUTS ###
###                                                                   ###

# Load the data
multi_file_info <- lapply(LICOR_FILES_TO_PROCESS, function(fname) {
    read_gasex_file(fname, TIME_COLUMN_NAME)
})

common_columns <- do.call(identify_common_columns, multi_file_info)

extracted_multi_file_info <- lapply(multi_file_info, function(exdf_obj) {
    exdf_obj[ , common_columns, TRUE]
})

combined_info <- do.call(rbind, extracted_multi_file_info)

# Determine if there is a `plot` column
HAS_PLOT_INFO <- 'plot' %in% colnames(combined_info)

# Add a column that combines `plot` and `replicate` if necessary
if (HAS_PLOT_INFO) {
  combined_info[, paste0('plot_', REP_COLUMN_NAME)] <-
    paste(combined_info[, 'plot'], combined_info[, REP_COLUMN_NAME])
}

# Reset the rep column name depending on whether there is plot information
REP_COLUMN_NAME <- if (HAS_PLOT_INFO) {
    paste0('plot_', REP_COLUMN_NAME)
} else {
    REP_COLUMN_NAME
}

combined_info[, UNIQUE_ID_COLUMN_NAME] <-
    paste(combined_info[, EVENT_COLUMN_NAME], combined_info[, REP_COLUMN_NAME])

# Factorize ID columns
combined_info <- factorize_id_column(combined_info, EVENT_COLUMN_NAME)
combined_info <- factorize_id_column(combined_info, UNIQUE_ID_COLUMN_NAME)

# Check the data for any issues before proceeding with additional analysis
check_licor_data(
    combined_info,
    c(EVENT_COLUMN_NAME, REP_COLUMN_NAME),
    NUM_OBS_IN_SEQ
)

# Organize the data, keeping only the desired measurement points
combined_info <- organize_response_curve_data(
    combined_info,
    UNIQUE_ID_COLUMN_NAME,
    MEASUREMENT_NUMBERS_TO_REMOVE,
    'Ci'
)

# Remove specific problematic points
if (REMOVE_SPECIFIC_POINTS) {
    # Specify the points to remove
    combined_info <- remove_points(
        combined_info,
        list(event = 'WT',    replicate = '1', plot = '4', seq_num = 14),
        list(event = 'zg12a', replicate = '2', plot = '2', seq_num = 7)
    )
}

# Average over curves from the same event and plot, if necessary
if (AVERAGE_OVER_PLOTS) {
    combined_info <- do.call(rbind.exdf, by(
        combined_info,
        list(combined_info[, EVENT_COLUMN_NAME], combined_info[, 'plot'], combined_info[, 'CO2_r_sp']),
        avg_exdf
    ))

    REP_COLUMN_NAME <- 'plot'

    combined_info[, UNIQUE_ID_COLUMN_NAME] <-
        paste(combined_info[, EVENT_COLUMN_NAME], combined_info[, REP_COLUMN_NAME])

    combined_info <- factorize_id_column(combined_info, UNIQUE_ID_COLUMN_NAME)
}

# Calculate temperature-dependent values of C4 parameters
combined_info <-
    calculate_arrhenius(combined_info, c4_arrhenius_von_caemmerer)

# Include gm values
combined_info <- set_variable(
    combined_info,
    GM_COLUMN_NAME,
    GM_UNITS,
    'c4_co2_response',
    GM_VALUE
)

# Calculate the total pressure
combined_info <- calculate_total_pressure(combined_info)

# Calculate PCm
combined_info <- apply_gm(combined_info, 'C4')

# Calculate additional gas properties
combined_info <- calculate_gas_properties(combined_info)

# Calculate intrinsic water-use efficiency
combined_info <- calculate_wue(combined_info)

# Perform A-Ci fits
fit_result <- consolidate(by(
    combined_info,
    combined_info[, UNIQUE_ID_COLUMN_NAME],
    fit_c4_aci,
    OPTIM_FUN = solver,
    Ca_atmospheric = 420,
    alpha = 0,
    gbs = 0,
    Rm_frac = 1
))

all_samples <- combined_info[['main_data']]
all_fit_parameters <- fit_result$parameters
all_fits <- fit_result$fits

all_fit_parameters <- all_fit_parameters$main_data
all_fits <- all_fits$main_data

# Make a subset of the full result for just the one measurement point
all_samples_one_point <-
    all_samples[all_samples[['seq_num']] == POINT_FOR_BOX_PLOTS,]

###                                    ###
### PLOT AVERAGE RESPONSE CURVES TO CI ###
###                                    ###

rc_caption <- 'Average response curves for each event'

x_ci <- all_samples[[CI_COLUMN_NAME]]
x_s  <- all_samples[['seq_num']]
x_e  <- all_samples[[EVENT_COLUMN_NAME]]

ci_lim  <- c(0, 1000)
a_lim   <- c(0, 70)
gsw_lim <- c(0, 0.5)

ci_lab   <- 'Intercellular [CO2] (ppm)'
a_lab    <- 'Net CO2 assimilation rate (micromol / m^2 / s)\n(error bars: standard error of the mean for same CO2 setpoint)'
iWUE_lab <- 'Intrinsic water use efficiency (micromol CO2 / mol H2O)\n(error bars: standard error of the mean for same CO2 setpoint)'
gsw_lab  <- 'Stomatal conductance to H2O (mol / m^2 / s)\n(error bars: standard error of the mean for same CO2 setpoint)'

avg_plot_param <- list(
    a_plot    = list(all_samples[['A']],    x_ci, x_s, x_e, xlab = ci_lab, ylab = a_lab,    xlim = ci_lim, ylim = a_lim),
    iwue_plot = list(all_samples[['iWUE']], x_ci, x_s, x_e, xlab = ci_lab, ylab = iWUE_lab, xlim = ci_lim),
    gsw_plot  = list(all_samples[['gsw']],  x_ci, x_s, x_e, xlab = ci_lab, ylab = gsw_lab,  xlim = ci_lim, ylim = gsw_lim)
)

for (i in seq_along(avg_plot_param)) {
    plot_obj <- do.call(xyplot_avg_rc, c(avg_plot_param[[i]], list(
        type = 'b',
        pch = 20,
        cex = 1.5,
        lwd = 2,
        auto.key = list(space = 'right'),
        grid = TRUE,
        main = rc_caption
    )))

    pdf_print(
        plot_obj,
        width = 8,
        height = 6,
        save_to_pdf = SAVE_TO_PDF,
        file = paste0(names(avg_plot_param)[i], '.pdf')
    )
}

###                                     ###
### PLOT ALL INDIVIDUAL RESPONSE CURVES ###
###                                     ###

ind_caption <- 'Individual response curves for each event and rep'

# Plot each individual A-Ci curve, where each event will have multiple traces
# corresponding to different plants
pdf_print(
    xyplot(
        all_samples[[A_COLUMN_NAME]] ~ all_samples[[CI_COLUMN_NAME]] | all_samples[[EVENT_COLUMN_NAME]],
        group = all_samples[[UNIQUE_ID_COLUMN_NAME]],
        type = 'b',
        pch = 20,
        auto.key = list(space = 'right'),
        grid = TRUE,
        main = ind_caption,
        xlab = 'Intercellular [CO2] (ppm)',
        ylab = 'Net CO2 assimilation rate (micromol / m^2 / s)',
        ylim = c(-5, 70),
        xlim = c(-100, 1600),
        par.settings = list(
            superpose.line = list(col = multi_curve_colors()),
            superpose.symbol = list(col = multi_curve_colors())
        )
    ),
    width = 8,
    height = 6
)

# Plot each individual gsw-Ci curve, where each event will have multiple
# traces corresponding to different plants
pdf_print(
    xyplot(
        all_samples[[GS_COLUMN_NAME]] ~ all_samples[[CI_COLUMN_NAME]] | all_samples[[EVENT_COLUMN_NAME]],
        group = all_samples[[UNIQUE_ID_COLUMN_NAME]],
        type = 'b',
        pch = 20,
        auto.key = list(space = 'right'),
        grid = TRUE,
        main = ind_caption,
        xlab = 'Intercellular [CO2] (ppm)',
        ylab = 'Stomatal conductance to water (mol / m^2 / s)',
        ylim = c(0, 0.8),
        xlim = c(-100, 1600),
        par.settings = list(
            superpose.line = list(col = multi_curve_colors()),
            superpose.symbol = list(col = multi_curve_colors())
        )
    ),
    width = 8,
    height = 6
)

###                      ###
### PLOT FITTING RESULTS ###
###                      ###

pdf_print(
    xyplot(
        all_fits[[A_COLUMN_NAME]] + all_fits[[paste0(A_COLUMN_NAME, '_fit')]] ~ all_fits[[CI_COLUMN_NAME]] | all_fits[[UNIQUE_ID_COLUMN_NAME]],
        type = 'b',
        auto.key = list(text = c('Measured', 'Fitted')),
        grid = TRUE,
        xlab = 'Intercellular [CO2] (ppm)',
        ylab = 'Net CO2 assimilation rate (micromol / m^2 / s)',
        ylim = c(-5, 70)
    ),
    width = 8,
    height = 6
)

###                                        ###
### MAKE BOX-WHISKER PLOTS AND BAR CHARTS  ###
###                                        ###

# Define a caption
boxplot_caption <- paste0(
    'Data for measurement point ',
    POINT_FOR_BOX_PLOTS,
    '\n(where CO2 setpoint = ',
    all_samples_one_point[['CO2_r_sp']][POINT_FOR_BOX_PLOTS],
    ')'
)

fitting_caption <- 'Fitted values'

# Define plotting parameters
x_s <- all_samples_one_point[[EVENT_COLUMN_NAME]]
x_p <- all_fit_parameters[[EVENT_COLUMN_NAME]]
xl  <- 'Genotype'

plot_param <- list(
    list(Y = all_fit_parameters[['Vcmax_at_25']],     X = x_p, xlab = xl, ylab = 'Vcmax at 25 C (micromol / m^2 / s)',                      ylim = c(0, 50),  main = fitting_caption),
    list(Y = all_fit_parameters[['Vpmax_at_25']],     X = x_p, xlab = xl, ylab = 'Vpmax at 25 C (micromol / m^2 / s)',                      ylim = c(0, 120), main = fitting_caption),
    list(Y = all_samples_one_point[[A_COLUMN_NAME]],  X = x_s, xlab = xl, ylab = 'Net CO2 assimilation rate (micromol / m^2 / s)',          ylim = c(0, 70),  main = boxplot_caption),
    list(Y = all_samples_one_point[[CI_COLUMN_NAME]], X = x_s, xlab = xl, ylab = 'Intercellular CO2 concentration (micromol / mol)',        ylim = c(0, 150), main = boxplot_caption),
    list(Y = all_samples_one_point[['iWUE']],         X = x_s, xlab = xl, ylab = 'Intrinsic water use efficiency (micromol CO2 / mol H2O)',                   main = boxplot_caption)
)

# Make all the plots
invisible(lapply(plot_param, function(x) {
    pdf_print(do.call(bwplot_wrapper, x))
    pdf_print(do.call(barchart_with_errorbars, x))
}))

# Save some outputs to CSV
all_samples_col <- c(
    UNIQUE_ID_COLUMN_NAME, EVENT_COLUMN_NAME, REP_COLUMN_NAME, 'iWUE', 'Ci', 'gsw', 'A'
)

all_samples_one_point_subset <- all_samples_one_point[, all_samples_col]

param_col <- c(
    UNIQUE_ID_COLUMN_NAME, EVENT_COLUMN_NAME, REP_COLUMN_NAME, 'Vcmax_at_25', 'Vpmax_at_25'
)

all_fit_parameters_subset <- all_fit_parameters[, param_col]

write.csv(all_samples_one_point_subset, file = 'all_samples_one_point.csv', row.names = FALSE)
write.csv(all_fit_parameters_subset,    file = 'all_fit_parameters.csv',    row.names = FALSE)
