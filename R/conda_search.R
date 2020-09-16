
#' Search package availabilty
#'
#' Search package availabilty
#'
#'
#' @name conda_search
#' @rdname conda_search
#'
#'
#' @author Doug Barrows and Matt Paul 
#' @param package Package to search for. If an exact match is found, the funtion will return true (assuming 'package_version' is left NULL or is a valid entry). If there is not an exact match and other packages contain this text, the function will return FALSE but the alternative options will be printed if print_out = TRUE.  
#' @param package_version A specific package version to search for. This must be a character vector with a single version entry. 
#' @param channel A specific to search in addition to defaults (bioconda defaults and conda-forge are the default channels)
#' @param print_out Either True or FALSE indicating whether to print out information about available builds and channels for the search entry.
#' @param pathToMiniConda Path to miniconda installation. If this is set to NULL (default), then the output of 'reticulate::miniconda_path()' is used.  
#' @return TRUE/FALSE
#' @importFrom magrittr %>%
#' @examples
#' 
#' conda_search("salmon")
#' 
#' @export
#' 

conda_search <- function(package, package_version = NULL, channel = NULL, print_out=TRUE, pathToMiniConda=NULL){
  #pathToMiniConda="/tmp"
  
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
  }
  
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  if (!is.null(channel)){
    channel_command <- paste0("-c ", channel)
  }else{
    channel_command <- NULL
  }
  
  #message(paste0('Using conda at: ', pathToConda))
  condaSearch <- suppressWarnings(system(paste(pathToConda,"search --quiet --json", package, channel_command),
                                         intern = TRUE,
                                         ignore.stderr = TRUE) # if we want to include the output for 'conda search', which is a pretty informative error message, set this to FALSE
  ) %>%
    paste(collapse = "") %>%
    fromJSON()
  
  if ("exception_name" %in% names(condaSearch)){
    if(condaSearch$exception_name == "PackagesNotFoundError"){
      
      if(print_out){
        message(paste0("package ",package, " not found"))
        return(FALSE)
      }else{
        return(list(exact_match=F, version_matches=NULL))  
      }
    }else if (condaSearch$exception_name == "UnavailableInvalidChannel"){
      if(print_out){
        message(paste0("channel ",channel, " not found"))
        return(FALSE)
      }else{
        return(list(exact_match=F, version_matches=NULL))  
      }
    }else{
      if(print_out){
        message("conda command failed, but not sure why. We didn't get the normal error messages we look for when a package or channel isn't found")
        return(FALSE)
      }else{
        return(list(exact_match=F, version_matches=NULL))  
      }
    }
  }else if (package %in% names(condaSearch)){
    condaSearch_df <- do.call(rbind, lapply(condaSearch[[1]], function(x) c(name = x$name, 
                                                                            version = x$version, 
                                                                            channel = x$channel))) %>%
      as.data.frame()
    condaSearch_df <- condaSearch_df[!duplicated(condaSearch_df$version, fromLast = TRUE), ]
    
    if (!is.null(package_version)){
      package_version <- as.character(package_version)
      if (any(grepl(package_version, condaSearch_df$version))){
        sub_df <- condaSearch_df[grepl(package_version, condaSearch_df$version), ]
        rownames(sub_df) <- NULL
        if(print_out){
          message(paste(package, "version", package_version, "is available from the following channels:"))
          print(sub_df)
          return(TRUE)
        }else{
          return(list(exact_match=T, version_matches=sub_df))  
        }
      } else{
        if(print_out){
          message(paste(package, "is available, but version", package_version, "is not. The following versions are currently available:"))
          print(condaSearch_df)
          return(FALSE)
        }else{
          return(list(exact_match=F, version_matches=condaSearch_df))  
        }
      }
    }else{
      if(print_out){
        message(paste(package, "is available in the following versions and channels:"))
        print(condaSearch_df)
        return(TRUE)
      }else{
        return(list(exact_match=T, version_matches=condaSearch_df))  
      }
    }
    
  }else if(!package %in% names(condaSearch)) {
    if(print_out){
      message(paste0("There are no exact matches for the query '", 
                     package, 
                     "', but mutliple packages contain this text, they are: ",
                     paste(names(condaSearch), 
                           collapse = ", ")
      ))
      return(FALSE)
    }else{
      return(list(exact_match=F, version_matches=condaSearch_df))  
    }
  }
  
}

