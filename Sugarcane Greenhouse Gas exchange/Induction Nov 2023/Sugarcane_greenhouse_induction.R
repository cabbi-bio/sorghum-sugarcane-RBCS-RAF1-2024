# Load required packages
library(PhotoGEA)
library(lattice)
library(ggplot2)

# Check to make sure we have the correct version of PhotoGEA
if (packageVersion('PhotoGEA') != '0.11.0') {
    stop(
        'The `Sugarcane_greenhouse_induction.R` script requires PhotoGEA ',
        'version 0.11.0. See the main README.md for installation instructions.'
    )
}

# Clear the workspace
rm(list=ls())

# Initialize the input files
LICOR_FILES_TO_PROCESS <- c(
    '2023-11-20 sugarcane induction ripe 1.xlsx',
    '2023-11-20 sugarcane induction ripe 2.xlsx',
    '2023-11-20 sugarcane induction ripe 4.xlsx',
    '2023-11-20 sugarcane induction ripe 6.xlsx',
    '2023-11-20 sugarcane induction ripe 9.xlsx'
)

# Decide whether to remove a few specific points from the data before subsequent
# processing and plotting
REMOVE_SPECIFIC_POINTS <- TRUE

# Specify which measurement numbers to choose. Here, the numbers refer to
# points along the time sequence of measurements.
NUM_OBS_IN_SEQ <- 360
MEASUREMENT_NUMBERS_TO_REMOVE <- c()

TIME_INCREMENT <- 10 / 60 # 10 seconds, converted to minutes

# Specify time range to use for normalization. This should be expressed as the
# number of elapsed minutes. For each event, the average assimilation rate
# across this interval will be calculated, and then used to normalize the A
# values.
TIME_RANGE_FOR_NORMALIZATION <- c(55, 60)

# Specify time range to use for plotting curves. Elapsed time will be shifted
# so the plots always begin at 0. Units are minutes.
A_TIME_LIM <- c(30, 60)

# Specify fraction of assimilation rate to use for speed calculations (expressed
# as a percentage)
TARGET_PERCENTAGE <- 50

# Specify time interval for calculating average assimilation. Units are minutes,
# and times should be specified relative to the start of A_TIME_LIM. For
# example, c(0, 5) is the first five minutes (300 seconds) after light
# exposure.
INTERVAL_FOR_AVG <- c(0, 5)

# Specify the names of a few important columns
A_COLUMN_NAME     <- 'A'
CI_COLUMN_NAME    <- 'Ci'
EVENT_COLUMN_NAME <- 'event'
REP_COLUMN_NAME   <- 'replicate'
TIME_COLUMN_NAME  <- 'time'

UNIQUE_ID_COLUMN_NAME <- 'line_sample'

A_NORM_COLUMN_NAME <- paste0(A_COLUMN_NAME, '_norm')

# Define a function that plots fancy error ranges using ggplot2
ggplot2_avg_rc <- function(
    Y,
    X,
    point_identifier,
    group_identifier,
    xlimit,
    ylimit,
    xlabel,
    ylabel
)
{
    # Combine inputs to make a data frame so we can use `by` more easily
    tdf <- data.frame(
        X = X,
        Y = Y,
        point_identifier = point_identifier,
        group_identifier = group_identifier
    )

    # Get basic stats information
    tdf_stats <- do.call(
        rbind,
        by(
            tdf,
            list(tdf$point_identifier, tdf$group_identifier),
            function(chunk) {
                # Get some basic info
                X_mean <- mean(chunk$X)
                X_sd <- stats::sd(chunk$X)

                Y_mean <- mean(chunk$Y)
                Y_sd <- stats::sd(chunk$Y)

                num <- nrow(chunk)

                # Calculate the standard errors and limits
                X_stderr <- X_sd / sqrt(num)
                X_upper <- X_mean + X_stderr
                X_lower <- X_mean - X_stderr

                Y_stderr <- Y_sd / sqrt(num)
                Y_upper <- Y_mean + Y_stderr
                Y_lower <- Y_mean - Y_stderr

                # Return the essentials
                data.frame(
                    X_mean = X_mean,
                    X_upper = X_upper,
                    X_lower = X_lower,
                    Y_mean = Y_mean,
                    Y_upper = Y_upper,
                    Y_lower = Y_lower,
                    point_identifier = unique(chunk$point_identifier),
                    group_identifier = unique(chunk$group_identifier)
                )
            }
        )
    )

    # Sort to make sure the curves are plotted properly
    tdf_stats <- tdf_stats[order(tdf_stats$X_mean),]
    tdf_stats <- tdf_stats[order(tdf_stats$group_identifier),]

    # Create a return the plot object
    ggplot(
        data = tdf_stats,
        aes(
            x = X_mean,
            y = Y_mean,
            ymin = Y_lower,
            ymax = Y_upper,
            fill = group_identifier,
            linetype = group_identifier
        )
      ) +
      coord_cartesian(ylim = ylimit) +
      geom_line() +
      geom_ribbon(alpha = 0.5) +
      xlab(xlabel) +
      ylab(ylabel)
}

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
    'obs', # Order the induction curves according to their `Obs` values
    Inf    # Do not require the curves to follow the same sequence of `Obs` values
)

# Add an 'elapsed time' column
combined_info[, 'elapsed_time'] <-
    (combined_info[, 'seq_num'] - 1) * TIME_INCREMENT

# Remove specific problematic points
if (REMOVE_SPECIFIC_POINTS) {
    # Specify the points to remove
    combined_info <- remove_points(
        combined_info,
        list(event = '25', replicate = '10', obs = 1263:1268),
        list(event = '25', replicate = '6',  obs = 544:552),
        list(event = '25', replicate = '9',  obs = 1623:1632),
        list(event = '3',  replicate = '6',  obs = 1264:1271),
        list(event = '9',  replicate = '5',  obs = 183:198),
        list(event = '9',  replicate = '6',  obs = 904:912)
    )
}

# Normalize the data
combined_info <- do.call(
    rbind,
    by(combined_info, combined_info[, EVENT_COLUMN_NAME], function(x) {
        subset <- x[x[, 'elapsed_time'] >= TIME_RANGE_FOR_NORMALIZATION[1] &
            x[, 'elapsed_time'] <= TIME_RANGE_FOR_NORMALIZATION[2], ]

        norm_val <- mean(subset[[A_COLUMN_NAME]])

        x[, 'A_norm_val'] <- norm_val
        x[, A_NORM_COLUMN_NAME] <- x[, A_COLUMN_NAME] / norm_val

        document_variables(
            x,
            c('', 'A_norm_val', x$units[[A_COLUMN_NAME]]),
            c('', A_NORM_COLUMN_NAME, x$units[[A_COLUMN_NAME]])
        )
    })
)

all_samples <- combined_info[['main_data']]

# Extract some additional information from the curves
curve_information <- do.call(rbind, by(
    combined_info,
    combined_info[, UNIQUE_ID_COLUMN_NAME],
    function(x) {
        # Get identifying information
        id_cols <- if (HAS_PLOT_INFO) {
            c(UNIQUE_ID_COLUMN_NAME, REP_COLUMN_NAME, EVENT_COLUMN_NAME, 'replicate', 'plot')
        } else {
            c(UNIQUE_ID_COLUMN_NAME, EVENT_COLUMN_NAME, REP_COLUMN_NAME)
        }

        res <- x[1, c(id_cols, 'A_norm_val'), TRUE]

        # Get the elapsed time when normalized assimilation is X%
        tmp <- x[, A_NORM_COLUMN_NAME] - TARGET_PERCENTAGE / 100
        indx <- which(tmp > 0)[1]

        res[, 'target_percentage'] <- TARGET_PERCENTAGE
        res[, 'time_to_target_percentage'] <- x[indx, 'elapsed_time'] - min(A_TIME_LIM)

        # Get average assimilation over the specified interval
        mintime <- min(A_TIME_LIM) + min(INTERVAL_FOR_AVG)
        maxtime <- min(A_TIME_LIM) + max(INTERVAL_FOR_AVG)
        interval_length <- (maxtime - mintime) * 60

        avg_a <- mean(x[x[, 'elapsed_time'] >= mintime & x[, 'elapsed_time'] <= maxtime, A_COLUMN_NAME], na.rm = TRUE)

        res[, 'interval_start_time']  <- min(INTERVAL_FOR_AVG)
        res[, 'interval_end_time']    <- max(INTERVAL_FOR_AVG)
        res[, 'interval_length']      <- interval_length
        res[, 'interval_A_avg']       <- avg_a

        # Include units and return results
        document_variables(
            res,
            c('', 'target_percentage',         'percent of A_norm_val'),
            c('', 'time_to_target_percentage', 'minutes'),
            c('', 'interval_start_time',       'minutes'),
            c('', 'interval_end_time',         'minutes'),
            c('', 'interval_A_avg',            'micromol m^(-2) s^(-1)')
        )
    }
))

# One curve is an outlier for "time to 50%" so we discard that value
curve_information[curve_information[, UNIQUE_ID_COLUMN_NAME] == 'WT 10', 'time_to_target_percentage'] <- NA

###                               ###
### PLOT AVERAGE INDUCTION CURVES ###
###                               ###

rc_caption <- 'Average induction curves for each event'

all_samples_for_plots <- all_samples[all_samples[['elapsed_time']] >= A_TIME_LIM[1] & all_samples[['elapsed_time']] <= A_TIME_LIM[2], ]
all_samples_for_plots[['elapsed_time']] <- all_samples_for_plots[['elapsed_time']] - min(all_samples_for_plots[['elapsed_time']])

x_t <- all_samples_for_plots[['elapsed_time']]
x_s <- all_samples_for_plots[['seq_num']]
x_e <- all_samples_for_plots[[EVENT_COLUMN_NAME]]

a_lim      <- c(-3, 50)
a_norm_lim <- c(-0.1, 1.1)
gs_lim     <- c(0, 0.5)

t_lab      <- 'Elapsed time (minutes)'
a_lab      <- 'Net CO2 assimilation rate (micromol / m^2 / s)\n(error bars: standard error of the mean for each time point)'
a_norm_lab <- 'Normalized net CO2 assimilation rate (dimensionless)\n(error bars: standard error of the mean for each time point)'
gs_lab     <- 'Stomatal conductance to H2O (mol / m^2 / s)\n(error bars: standard error of the mean for each time point)'

avg_plot_param <- list(
  list(all_samples_for_plots[[A_COLUMN_NAME]],      x_t, x_s, x_e, xlab = t_lab, ylab = a_lab,      ylim = a_lim,      xlim = A_TIME_LIM - min(A_TIME_LIM)),
  list(all_samples_for_plots[[A_NORM_COLUMN_NAME]], x_t, x_s, x_e, xlab = t_lab, ylab = a_norm_lab, ylim = a_norm_lim, xlim = A_TIME_LIM - min(A_TIME_LIM)),
  list(all_samples_for_plots[['gsw']],              x_t, x_s, x_e, xlab = t_lab, ylab = gs_lab,     ylim = gs_lim,     xlim = A_TIME_LIM - min(A_TIME_LIM))
)

invisible(lapply(avg_plot_param, function(x) {
    pdf_print(
        do.call(
            xyplot_avg_rc,
            c(
                x,
                list(
                    y_error_bars = FALSE,
                    type = 'b',
                    pch = 20,
                    auto = TRUE,
                    grid = TRUE,
                    main = rc_caption
                )
            )
        ),
        width = 8,
        height = 8
    )

    pdf_print(
        ggplot2_avg_rc(
            x[[1]],
            x[[2]],
            x[[3]],
            x[[4]],
            x[[8]],
            x[[7]],
            x[[5]],
            x[[6]]
        ),
        width = 8,
        height = 6
    )
}))

###                                      ###
### PLOT ALL INDIVIDUAL INDUCTION CURVES ###
###                                      ###

ind_caption <- 'Individual induction curves for each event and rep'

# Plot each individual induction curve, where each event will have multiple traces
# corresponding to different plants
pdf_print(
    xyplot(
        all_samples[[A_COLUMN_NAME]] ~ all_samples[['elapsed_time']] | all_samples[[EVENT_COLUMN_NAME]],
        group = all_samples[[UNIQUE_ID_COLUMN_NAME]],
        type = 'b',
        pch = 20,
        auto.key = list(space = 'right'),
        grid = TRUE,
        main = ind_caption,
        xlab = 'Elapsed time (minutes)',
        ylab = 'Net CO2 assimilation rate (micromol / m^2 / s)',
        ylim = c(-10, 60),
        par.settings = list(
            superpose.line = list(col = multi_curve_colors()),
            superpose.symbol = list(col = multi_curve_colors())
        )
    )
)

###                                ###
### PLOT CURVE SUMMARY INFORMATION ###
###                                ###

interval_main <- paste(
    'Interval:', INTERVAL_FOR_AVG[1], 'to',
    INTERVAL_FOR_AVG[2], curve_information$units$interval_start_time
)

curve_info_for_time <- curve_information[!is.na(curve_information[, 'time_to_target_percentage']), ]

plot_param <- list(
    list(
        Y = curve_info_for_time[, 'time_to_target_percentage'],
        X = curve_info_for_time[, EVENT_COLUMN_NAME],
        ylab = paste('Time to target percentage [', curve_information$units$time_to_target_percentage, ']'),
        xlab = 'Event',
        ylim = c(0, 15),
        main = paste('Target percentage:', TARGET_PERCENTAGE)
    ),
    list(
        Y = curve_information[, 'interval_A_avg'],
        X = curve_information[, EVENT_COLUMN_NAME],
        ylab = paste('Average A [', curve_information$units$interval_A_avg, ']'),
        xlab = 'Event',
        ylim = c(0, 30),
        main = interval_main
    )
)

invisible(lapply(plot_param, function(x) {
    pdf_print(do.call(bwplot_wrapper, x))
    pdf_print(do.call(barchart_with_errorbars, x))
}))
