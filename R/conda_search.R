
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
#' @param channel A specific to search in addition to defaults (bioconda defaults and conda-forge are the default channels)
#' @param print_out Either True or FALSE indicating whether to print out information about available builds and channels for the search entry.
#' @param pathToMiniConda Path to miniconda installation. If this is set to NULL (default), then the output of 'reticulate::miniconda_path()' is used.  
#' @import utils rjson
#' @return TRUE/FALSE
#' @examples
#' 
#' conda_search("salmon")
#' 
#' @export
#' 

conda_search <- function(package, channel = NULL, print_out=TRUE, pathToMiniConda=NULL){
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
  
  version_sep<-c("[<>)(=]")
  pkg_and_vers<-unlist(strsplit(package, version_sep, perl = T))
  pkg_and_vers<-pkg_and_vers[!(nchar(pkg_and_vers)==0)]
  version_included<-grepl("=",package)
  if(version_included){
    if(grepl(">=",package)){
      ver_logic<-">="
    } else if(grepl("<=",package)){
      ver_logic<-"<="
    } else {ver_logic<-"=="}}
  
  package_input <- paste0("'",pkg_and_vers[1],"'")
  
  #message(paste0('Using conda at: ', pathToConda))
  condaSearch <- suppressWarnings(system(paste(pathToConda,"search --quiet --json", package_input, channel_command),
                                         intern = TRUE,
                                         ignore.stderr = TRUE) # if we want to include the output for 'conda search', which is a pretty informative error message, set this to FALSE
  )
  condaSearch <- fromJSON(paste(condaSearch, collapse = ""))
  
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
  }else if (pkg_and_vers[1] %in% names(condaSearch)){
    condaSearch_df <- as.data.frame(do.call(rbind, lapply(condaSearch[[1]], function(x) c(name = x$name, 
                                                                            version = x$version, 
                                                                            channel = x$channel))))
    condaSearch_df <- condaSearch_df[!duplicated(condaSearch_df$version, fromLast = TRUE), ]
    
    if (version_included){
      package_version <- as.character(pkg_and_vers[2])
      if (any(grepl(package_version, condaSearch_df$version)) & !(ver_logic %in% c("<=",">=")) ){
        sub_df <- condaSearch_df[grepl(package_version, condaSearch_df$version), ]
        rownames(sub_df) <- NULL
        if(print_out){
          message(paste(pkg_and_vers[1], "version", package_version, "is available from the following channels:"))
          print(sub_df)
          return(TRUE)
        }else{
          return(list(exact_match=T, version_matches=sub_df))  
        }
      }else if(ver_logic==">="){
          if(sum(sapply(condaSearch_df$version, compareVersion, b=package_version)==1)>0){
            sub_df <- condaSearch_df[sapply(condaSearch_df$version, compareVersion, b=package_version)==1, ]
          if(print_out){
            message(paste(pkg_and_vers[1], "version", ver_logic ,package_version, "are available from the following channels:"))
             print(sub_df)
            return(TRUE)
          }else{
            return(list(exact_match=T, version_matches=sub_df))  
          }}else{
            if(print_out){
              message(paste(pkg_and_vers[1], "is available, but versions",ver_logic , package_version, "are not. The following versions are currently available:"))
              print(condaSearch_df)
              return(FALSE)
            }else{
              return(list(exact_match=F, version_matches=condaSearch_df))  
            }
          }
      }else if(ver_logic=="<="){
        if(sum(sapply(condaSearch_df$version, compareVersion, b=package_version)==(-1))>0){
          sub_df <- condaSearch_df[sapply(condaSearch_df$version, compareVersion, b=package_version)==(-1), ]
          if(print_out){
            message(paste(pkg_and_vers[1], "versions", ver_logic ,package_version, "are available from the following channels:"))
            print(sub_df)
            return(TRUE)
          }else{
            return(list(exact_match=T, version_matches=sub_df))  
          }}else{
            if(print_out){
              message(paste(pkg_and_vers[1], "is available, but version",ver_logic , package_version, "are not. The following versions are currently available:"))
              print(condaSearch_df)
              return(FALSE)
            }else{
              return(list(exact_match=F, version_matches=condaSearch_df))  
            }
          }
      }else{
        if(print_out){
          message(paste(pkg_and_vers[1], "is available, but version", package_version, "is not. The following versions are currently available:"))
          print(condaSearch_df)
          return(FALSE)
        }else{
          return(list(exact_match=F, version_matches=condaSearch_df))  
        }
      }
    }else{
      if(print_out){
        message(paste(pkg_and_vers[1], "is available in the following versions and channels:"))
        print(condaSearch_df)
        return(TRUE)
      }else{
        return(list(exact_match=T, version_matches=condaSearch_df))  
      }
    }
    
  }else if(!pkg_and_vers[1] %in% names(condaSearch)) {
    if(print_out){
      message(paste0("There are no exact matches for the query '", 
                     pkg_and_vers[1], 
                     "', but multiple packages contain this text:\n",
                     paste(names(condaSearch), 
                           collapse = "\n")
      ))
      return(FALSE)
    }else{
      return(list(exact_match=F, version_matches=paste(names(condaSearch), 
                                                       collapse = "\n")))  
    }
  }
  
}

