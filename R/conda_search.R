
conda_search <- function(package, package_version = NULL, channel = NULL, print_out=TRUE,pathToMiniConda=NULL){
  
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
  }
  
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  if (!is.null(channel)){
    channel <- paste0("-c ", channel)
  }
  
  condaSearch <- suppressWarnings(system(paste(pathToConda,"search", package, channel), 
                                         intern = TRUE, 
                                         ignore.stderr = TRUE)) # if we want to include the output for 'conda search', which is a pretty informative error message, set this to FALSE
  
  if (grepl("No match found for", condaSearch[2])){
    if(print_out){
      message(paste0("package ",package, " not found"))
      return(FALSE)
    }else{
      return(list(exact_match=F, version_matches=NULL))  
    }
  } else if (any(grepl(package, condaSearch))) { # this can probably be an 'else' but made another else below in case for some reason condas error message changes and we not longer pick up the line in the output we search for above to preent a silent error
    condaSearch <- condaSearch[-1]
    
    condaSearch_list <- list()
    for (i in seq_along(condaSearch)){
      condaSearch_list[[i]] <- strsplit(condaSearch[i], "\\s+")[[1]] 
    }
    
    condaSearch_df <- do.call(rbind, condaSearch_list[2:length(condaSearch_list)])
    condaSearch_df <-  as.data.frame(condaSearch_df)
    colnames(condaSearch_df) <- condaSearch_list[1][[1]][2:5]
    
    if (!is.null(package_version)){
      package_version <- as.character(package_version)
      if (any(grepl(package_version, condaSearch_df$Version))){
        sub_df <- condaSearch_df[grepl(package_version, condaSearch_df$Version), ]
        rownames(sub_df) <- NULL
        if(print_out){
          message(paste(package, "version", package_version, "is available from the following builds and channels:"))
          print(sub_df)
          return(TRUE)
        }else{
          return(list(exact_match=T, version_matches=sub_df))  
        }
      } else{
        if(print_out){
          message(paste(package, "is available, but version", package_version, "is not. The following builds and channels are currently available:"))
          print(condaSearch_df)
          return(FALSE)
        }else{
          return(list(exact_match=F, version_matches=condaSearch_df))  
        }
      }
    } else{
      if(print_out){
        message(paste(package, "is available from the following builds and channels:"))
        print(condaSearch_df)
        return(TRUE)
      }else{
        return(list(exact_match=T, version_matches=condaSearch_df))  
      }
    }
    
  } else {
    if(print_out){
      message("conda command failed, but not sure why. We didn't get the normal eror mesage we look for when a package isn't found")
      return(FALSE)
    }else{
      return(list(exact_match=F, version_matches=NULL))  
    }
  }
  
}

#conda_search("salmon", package_version = "0.7.2")
