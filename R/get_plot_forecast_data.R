#' Combines load_truth() and pivot_forecasts_wider(), returns the data.
#'
#' @param data forecasts data frame from load_forecast(). It has columns model, 
#' forecast_date,location, target, type, quantile, value, horizon and 
#' target_end_date.
#' @param model_to_plot characters of model abbreviations 
#' @param horizons_to_plot forecasts are plotted for the horizon time steps after the 
#' forecast date
#' @param quantiles_to_plot vector of quanitles to include in the plot
#' @param location_to_plot character vector of one location. 
#' @param include_truth boolean to indicate whether truth data should be plotted.
#' Default to TRUE.
#' @param truth_source character vector specifying where the truths will
#' be loaded from: currently support "JHU","USAFacts", "NYTimes"
#' @param target_variable string specifying target type. It should be one of 
#' "Cumulative Deaths","Incident Cases" and "Incident Deaths."
#' @param  truth_as_of the plot includes the truth data that would have been 
#' in real time as of the truth_as_of date.
#' 
#' @return data frame with columns model, 
#' forecast_date, location, inc_cum, death_case, type, quantile, value, horizon and 
#' target_end_date.
#' 
#' @export
get_plot_forecast_data <- function(data, 
                                   model_to_plot,
                                   horizons_to_plot,
                                   quantiles_to_plot,
                                   location_to_plot,
                                   include_truth = TRUE,
                                   truth_source,
                                   target_variable,
                                   truth_as_of = NULL){
  
  # validate location
  all_valid_fips <- covidHubUtils::hub_locations$fips

  
  if (!missing(location_to_plot)){
    location_to_plot <- match.arg(location_to_plot, 
                           choices = all_valid_fips, 
                           several.ok = FALSE)
  } else {
    stop("Error in get_plot_forecast_data: Please provide a location_to_plot parameter.")
  }
  
  # warning for truth_as_of
  if(!is.null(truth_as_of)){
    warning("Warning in get_plot_forecast_data: Currently versioned truth data is not supported.")
  }
  
  
  inc_cum_to_plot = ifelse(
    unlist(strsplit(target_variable, " "))[1] == "Cumulative","cum", "inc")
  
  death_case_to_plot = ifelse(
    unlist(strsplit(target_variable, " "))[2] == "Cases","case","death")
  
  # filter horizons and locations. Only plot one location now.
  data <- data %>%
    dplyr::filter(model == model_to_plot,
                  horizon <= horizons_to_plot, 
                  location == location_to_plot,
                  inc_cum == inc_cum_to_plot,
                  death_case == death_case_to_plot)
  
  
  forecasts<- pivot_forecasts_wider(data, quantiles_to_plot) %>%
    dplyr::mutate(truth_forecast = "forecast")
   
  if (include_truth){
    # load truth from remote git hub repo. 
    # not using truth_as_of here.
    truth <- load_truth(truth_source,
                target_variable, 
                #truth_end_date = ,
                locations = location_to_plot) %>%
      dplyr::rename(point = value) %>%
      dplyr::mutate(truth_forecast = "truth")
    
    plot_data <- dplyr::bind_rows(forecasts, truth)
    return (plot_data)
  } else {
    return (forecasts)
  }
  
}