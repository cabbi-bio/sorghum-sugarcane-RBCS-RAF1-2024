library(lattice)
library(PhotoGEA)
library(ggplot2)

# Clear the workspace
rm(list=ls())

# Specify options
CHOOSE_FILES_INTERACTIVELY <- TRUE

LEAKINESS_COLUMN_NAME <- 'LHL' # Can be 'LHL' or 'LLL'

LEAKINESS_MIN <- 5e-3

LEAKINESS_LIMITS <- list(
    list(start_time = 0,    end_time = 600,  leakiness_min = LEAKINESS_MIN, leakiness_max = 10),
    list(start_time = 600,  end_time = 1400, leakiness_min = LEAKINESS_MIN, leakiness_max = 0.5),
    list(start_time = 1400, end_time = 2100, leakiness_min = LEAKINESS_MIN, leakiness_max = 0.5)
)

TIME_RANGE_FOR_PLOTTING <- c(0, 2000)

TIME_RANGE_FOR_AVERAGES <- c(1500, 2000)

TIME_BIN_SIZE_FOR_FANCY_PLOT <- 30 # seconds

PLANT_ID_TO_REMOVE_FOR_FANCY_PLOT <- c(
    'WT 1'
)

# Load files, make plots, etc
file_names <- c(
    file.path('Leakiness', 'Leakiness_2023-07-24 hn1a 1.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 hn1a 2.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 hn1a 3.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 WT 1.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 WT 2.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 WT 3.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 zg12a 1.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 zg12a 2.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 zg12a 3.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 zg5b 1.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 zg5b 2.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-24 zg5b 3.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 hn1a 4.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 hn1a 5.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 WT 4.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 WT 5.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 zg12a 4.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 zg12a 5.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 zg5b 4.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-25 zg5b 5.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-26 hn1a 6.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-26 WT 12.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-26 WT 22.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-26 WT 6.txt'),
    file.path('Leakiness', 'Leakiness_2023-07-26 zg5b 6.txt')
)

file_list <- lapply(file_names, function(fn) {
    fd <- read.delim(fn, header = FALSE)

    colnames(fd) <- c(
        'elapsed_time',
        'LHL',
        'Dtdl_TDL',
        'xsi_TDL',
        'LLL',
        'Jt',
        'Cbs',
        'Ci_licor',
        'Vc',
        'Vp',
        'Vo',
        'Cs_TDL'
    )

    trimmed_name <- tools::file_path_sans_ext(basename(fn))

    info_phrase <-
        toupper(regmatches(trimmed_name, regexpr('[[:alnum:]]+ [[:alnum:]]+$', trimmed_name)))

    fd$event     <- strsplit(info_phrase, ' ')[[1]][1]
    fd$replicate <- strsplit(info_phrase, ' ')[[1]][2]
    fd$plant_id  <- info_phrase
    fd$file_name <- fn

    return(fd)
})

leakiness_data <- do.call(rbind, file_list)

# Only keep points within the acceptable range
cat(paste('\nThe full data set has', nrow(leakiness_data), 'points\n'))

leakiness_list <- lapply(LEAKINESS_LIMITS, function(x) {
    leakiness_subset <- leakiness_data[leakiness_data[['elapsed_time']] >= x$start_time & leakiness_data[['elapsed_time']] < x$end_time, ]
    leakiness_subset[leakiness_subset[[LEAKINESS_COLUMN_NAME]] >= x$leakiness_min & leakiness_subset[[LEAKINESS_COLUMN_NAME]] <= x$leakiness_max, ]
})

leakiness_data <- do.call(rbind, leakiness_list)

cat(paste('\nAfter restricting to the acceptable leakiness range, there are', nrow(leakiness_data), 'points\n'))

# Factorize to get ready for plotting
leakiness_data <- factorize_id_column(leakiness_data, 'event')

# Limit time range for plotting
leakiness_data_for_plots <- leakiness_data[leakiness_data[['elapsed_time']] >= TIME_RANGE_FOR_PLOTTING[1] & leakiness_data[['elapsed_time']] <= TIME_RANGE_FOR_PLOTTING[2], ]

# Limit time range for averaging
leakiness_data_for_averages <- leakiness_data[leakiness_data[['elapsed_time']] >= TIME_RANGE_FOR_AVERAGES[1] & leakiness_data[['elapsed_time']] <= TIME_RANGE_FOR_AVERAGES[2], ]

# Split data into bins for fancy plots and exclude some curves
leakiness_data_for_fancy_plots <- leakiness_data_for_plots[!leakiness_data_for_plots[['plant_id']] %in% PLANT_ID_TO_REMOVE_FOR_FANCY_PLOT, ]

leakiness_data_for_fancy_plots[, 'elapsed_time_bin'] <- TIME_BIN_SIZE_FOR_FANCY_PLOT * (0.5 + floor(leakiness_data_for_fancy_plots[['elapsed_time']] / TIME_BIN_SIZE_FOR_FANCY_PLOT))

# Calculate average leakiness values over a time range for each plant
average_leakiness_by_plant <- do.call(rbind, by(leakiness_data_for_averages, leakiness_data_for_averages[['plant_id']], function(x) {
    data.frame(
        plant_id = x$plant_id[1],
        event = x$event[1],
        replicate = x$replicate[1],
        leakiness_avg = mean(x[[LEAKINESS_COLUMN_NAME]]),
        leakiness_stderr = sd(x[[LEAKINESS_COLUMN_NAME]]) / sqrt(nrow(x))
    )
}))

row.names(average_leakiness_by_plant) <- NULL

average_leakiness_by_plant$start_time <- TIME_RANGE_FOR_AVERAGES[1]
average_leakiness_by_plant$end_time <- TIME_RANGE_FOR_AVERAGES[2]

# Plot all individual leakiness curves
pdf_print(
    xyplot(
        LHL ~ elapsed_time | plant_id,
        data = leakiness_data_for_plots,
        type = 'p',
        pch = 20,
        auto = TRUE,
        grid = TRUE,
        ylim = c(-0.1, 1.1)
    ),
    width = 12,
    height = 6
)

# Plot average leakiness values
pdf_print(
    barchart_with_errorbars(
        average_leakiness_by_plant$leakiness_avg,
        average_leakiness_by_plant$event,
        xlab = 'Event',
        ylab = 'Average leakiness (dimensionless)',
        main = paste('Averages calculated between t =', TIME_RANGE_FOR_AVERAGES[1], 'and t =', TIME_RANGE_FOR_AVERAGES[2], 'seconds'),
        ylim = c(0, 0.6)
    )
)

# Make fancy average induction curve
ggplot2_avg_rc <- function(
    Y,
    X,
    point_identifier,
    group_identifier,
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
    geom_line() +
    geom_ribbon(alpha = 0.5) +
    coord_cartesian(ylim = ylimit) +
    xlab(xlabel) +
    ylab(ylabel)
}

pdf_print(
    ggplot2_avg_rc(
        leakiness_data_for_fancy_plots[[LEAKINESS_COLUMN_NAME]],
        leakiness_data_for_fancy_plots$elapsed_time_bin,
        leakiness_data_for_fancy_plots$elapsed_time_bin,
        leakiness_data_for_fancy_plots$event,
        c(0, 1),
        'Elapsed time (seconds)',
        'Leakiness (dimensionless)'
    )
)

# Save average leakiness values
write.csv(average_leakiness_by_plant, file = 'average_leakiness_by_plant.csv', row.names = FALSE)
