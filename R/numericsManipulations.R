###################################################################################################
############################### findAndTransformNumerics  #########################################
###################################################################################################
#' Identify numeric columns in a dataSet set
#' 
#' Function to find and transform characters that are in fact numeric.
#' @param dataSet Matrix, data.frame or data.table
#' @param cols List of column(s) name(s) of dataSet to look into. To check all all columns, set it 
#'  to "auto". (characters, default to "auto")
#' @param n_test Number of non-null rows on which to test (numeric, default to 30)
#' @param verbose Should the algorithm talk? (logical, default to TRUE)
#' @details 
#' This function is looking for perfect transformation. 
#' If there are some mistakes in dataSet, consider setting them to NA before. \cr
#' If there are some columns that have no chance to be a match think of removing them from \code{cols} 
#' to save some computation time.
#' @section Warning:
#' All these changes will happen \strong{by reference}.
#' @return The dataSet set (as a data.table) with identified numeric transformed.
#' @examples
#' # Let's build a dataSet set
#' dataSet <- data.frame(ID = 1:5,
#'                   col1 = c("1.2", "1.3", "1.2", "1", "6"), 
#'                   col2 = c("1,2", "1,3", "1,2", "1", "6")
#'                   )
#' 
#' # using the findAndTransformNumerics
#' findAndTransformNumerics(dataSet, n_test = 5)
#' @import data.table
#' @export
findAndTransformNumerics <- function(dataSet, cols = "auto", n_test = 30, verbose = TRUE){
  ## Working environment
  function_name <- "findAndTransformNumerics"
  
  ## Sanity check
  dataSet <- checkAndReturnDataTable(dataSet)
  is.verbose(verbose)
  cols <- real_cols(dataSet, cols, function_name)
  ## Initialization
  start_time <- proc.time()
  
  ## Computation
  # identify
  numerics <- identifyNumerics(dataSet, cols = cols, n_test = n_test, verbose = verbose)
  if (verbose){
    printl(function_name, ": It took me ", round( (proc.time() - start_time)[[3]], 2), 
           "s to identify ", length(numerics$dont_strip) + length(numerics$strip), 
           " numerics column(s), i will set them as numerics")
  }
  
  # Format
  if (is.null(numerics$strip) & is.null(numerics$dont_strip)){
    if (verbose){
      printl(function_name, 
             ": There are no numerics to transform.", 
             "(If i missed something consider using setColAsNumeric to transform it)")
    }
    return(dataSet)
  }
  start_time <- proc.time()
  if (length(numerics$dont_strip) > 0 || length(numerics$strip) > 0 ){
    dataSet <- setColAsNumeric(dataSet, cols = numerics$dont_strip, stripString = FALSE, verbose = verbose)  
    dataSet <- setColAsNumeric(dataSet, cols = numerics$strip, stripString = TRUE, verbose = verbose)  
    
    if (verbose){
      printl(function_name, ": It took me ", round( (proc.time() - start_time)[[3]], 2), 
             "s to transform ", length(numerics$dont_strip) + length(numerics$strip), 
             " column(s) to a numeric format.")
    }
  }
  
  
  ## Wrapp-up
  return(dataSet)
}

###################################################################################################
############################### identifyNumerics  #################################################
###################################################################################################
#' @import data.table
identifyNumerics <- function(dataSet, cols = "auto", n_test = 30, verbose = TRUE, ...){
  ## Working environment
  function_name <- "identifyNumerics"
  
  ## Sanity check
  dataSet <- checkAndReturnDataTable(dataSet)
  n_test <- control_nb_rows(dataSet = dataSet, nb_rows = n_test, function_name = function_name, 
                            variable_name = "n_test")
  is.verbose(verbose)
  cols <- real_cols(dataSet, cols, function_name)
  ## Initialization
  numerics_cols_dont_strip <- NULL
  numerics_cols_strip <- NULL
  if (verbose){ 
    pb <- initPB(function_name, names(dataSet))
  }
  
  ## Computation
  for (col in cols){
    # Something is performed only if col is in a character format
    if (is.character(dataSet[[col]])){
      # Get a few lines that aren't NA, NULL nor ""
      data_sample <- findNFirstNonNull(dataSet[[col]], n_test)
      
      # We check only columns that contains something (not NA, NULL, "")
      if (length(data_sample) > 0){ 
        format <- identifyNumericsFormats(dataSet = data_sample)
        if (is.null(format)){
          next()
        }
        if (format == "notstrip"){
          numerics_cols_dont_strip <- c(numerics_cols_dont_strip, col)
          next()
        }
        if (format == "strip"){
          numerics_cols_strip <- c(numerics_cols_strip, col)
          next()
        }
      }
    }
    if (verbose){
      setPB(pb, col)
    }
  }
  
  ## Wrapp-up
  return(list(dont_strip = numerics_cols_dont_strip, strip = numerics_cols_strip))
}


#######################################################################################
############################### Identify numeric format  ##############################
#######################################################################################
identifyNumericsFormats <- function(dataSet){
  if (! is.character(dataSet)){
    stop("identifyNumericsFormats: dataSet should be some characters")
  }
  
  # Check convertions either strip or don't strip
  options(warn = -1) # Localy disable warning (we are trying to transform stuff if there is a mistake we skip it)
  dataSet_converted <- as.numeric(dataSet)
  dataSet_converted_stripped <- as.numericStrip(dataSet)
  options(warn = 0)
  # Wrapp-up
  if (identical(is.na(dataSet_converted), is.na(dataSet))){
    return("notstrip")
  }
  if (identical(is.na(dataSet_converted_stripped), is.na(dataSet))){
    return("strip")
  }
  return(NULL)
}

#######################################################################################
############################### As numerical strip  ###################################
#######################################################################################
as.numericStrip <- function(x){
  return(as.numeric(gsub(",", ".", x)))
}
