
#' Search package availabilty
#'
#' Search package availabilty
#'
#'
#' @name conda_search
#' @rdname search_conda
#'
#'
#' @author Doug Barrows and Matt Paul
#' @param package Package to search for. If an exact match is found, the funtion will return true (assuming 'package_version' is left NULL or is a valid entry). If there is not an exact match and other packages contain this text, the function will return FALSE but the alternative options will be printed if print_out = TRUE.
#' @param channel Channels for to search in (bioconda and conda-forge are defaults).
#' @param print_out Either True or FALSE indicating whether to print out information about available builds and channels for the search entry.
#' @param pathToMiniConda Path to miniconda installation. If this is set to NULL (default), then the output of 'reticulate::miniconda_path()' is used.
#' @import utils rjson
#' @return TRUE/FALSE
#' @examples
#' condaPaths <- install_CondaTools("salmon", "herperTestDWB")
#' conda_search("salmon")
#' @export
#'

conda_search <- function(package, 
                         channel = NULL, 
                         print_out = TRUE, 
                         pathToMiniConda = NULL) {

    #Check conda install
    if (is.null(pathToMiniConda)) {
        pathToMiniConda <- reticulate::miniconda_path()
    } else {
        pathToMiniConda <- file.path(pathToMiniConda)
    }

    pathToCondaInstall <- pathToMiniConda
    pathToConda <- miniconda_conda(pathToCondaInstall)
    
    condaPathExists <- miniconda_exists(pathToMiniConda)
    
    
    if (!condaPathExists) {
        stop("There is no conda installed at", pathToMiniConda)} 
    # if (!condaPathExists) {
    #     result<-menu(c("Yes", "No"), title=strwrap(paste("Conda does not exist at", pathToMiniConda, ". Do you want to install it there?")))
    #     if(result==1){
    #         reticulate::install_miniconda(pathToMiniConda)
    #     }else{
    #         stop(strwrap("Please specify the location of an existing conda directory, or where you would like to install conda and retry."))    
    #     }}
    
    if( is.null(channel) ){
      channel <- c("bioconda", "defaults", "conda-forge")
    }
    chan <- channel_list(channel)
    channel_command <- paste(unlist(chan), collapse=" ")
    
    #parse version info
    version_sep <- c("[<>)(=]")
    pkg_and_vers <- unlist(strsplit(as.character(package), version_sep, perl = TRUE))
    pkg_and_vers <- pkg_and_vers[!(nchar(pkg_and_vers) == 0)]
    pkg_and_vers[2] <- gsub(pattern = "[[:alpha:]]", "", pkg_and_vers[2])
    version_included <- grepl("=", package)
    if (version_included) {
        if (grepl(">=", package)) {
            ver_logic <- ">="
        } else if (grepl("<=", package)) {
            ver_logic <- "<="
        } else {
            ver_logic <- "=="
        }
    }

    package_input <- paste0('"', pkg_and_vers[1], '"')
 
    # run the search
    # message(paste0('Using conda at: ', pathToConda))
    condaSearch <- 
        system(paste(pathToConda, "search --quiet --json", package_input, channel_command),
            intern = TRUE,
            ignore.stderr = TRUE
        ) # if we want to include the output for 'conda search', which is a pretty informative error message, set this to FALSE
    
    
    condaSearch <- fromJSON(paste(condaSearch, collapse = ""))

    # parse search results
    if ("exception_name" %in% names(condaSearch)) {
        if (condaSearch$exception_name == "PackagesNotFoundError") {
            if (print_out) {
                warning("package ", package, " not found")
                return(FALSE)
            } else {
                return(list(exact_match = FALSE, version_matches = NULL))
            }
        } else if (condaSearch$exception_name == "UnavailableInvalidChannel") {
            if (print_out) {
                warning("channel ", channel, " not found")
                return(FALSE)
            } else {
                return(list(exact_match = FALSE, version_matches = NULL))
            }
        } else if (condaSearch$exception_name == "CondaHTTPError") {
          stop("HTTP Connection to Conda repo failed. This is likely an intermittent issue and you can just retry. If this keeps happening you might need to check if Conda is blocked on your network.")
        } else {
            if (print_out) {
                message("conda command failed, but not sure why. We didn't get the normal error messages we look for when a package or channel isn't found")
                return(FALSE)
            } else {
                return(list(exact_match = FALSE, version_matches = NULL))
            }
        }
    # look at matches now. breakdown.
    } else if (pkg_and_vers[1] %in% names(condaSearch)) {
        condaSearch_df <- as.data.frame(do.call(rbind, lapply(condaSearch[[1]], function(x) {
            c(
                name = x$name,
                version = x$version,
                channel = x$channel
            )
        })), stringsAsFactors = FALSE)
        condaSearch_df <- condaSearch_df[!duplicated(condaSearch_df$version, fromLast = TRUE), ]

        versions_no_letters <- gsub(pattern = "[[:alpha:]]", "", condaSearch_df$version)

        
        compareVersion_vapply <- function(versions_no_letters, package_version) {
            vapply(as.list(versions_no_letters), compareVersion, FUN.VALUE = numeric(length = 1), b = package_version)
        }
        
        if (version_included) {
            package_version <- as.character(pkg_and_vers[2])
            vers_comparison <- compareVersion_vapply(versions_no_letters, package_version)
            res1 <- vers_comparison == (-1)
            res2 <- vers_comparison == 0
            res3 <- vers_comparison == 1
            res4 <- (vers_comparison >= 0)
            res5 <- (vers_comparison <= 0)
            
            equals_logic <- any(res2) & !(ver_logic %in% c("<=", ">="))
            
            if (equals_logic) {
                sub_df <- condaSearch_df[res2, ]
                rownames(sub_df) <- NULL
                if (print_out) {
                    message(paste(pkg_and_vers[1], "version", package_version, "is available from the following channels:"))
                    print(sub_df)
                    return(TRUE)
                } else {
                    return(list(exact_match = TRUE, version_matches = sub_df))
                }
                
            } else if (ver_logic == ">=") {
                greater_logic <- (sum(res3, na.rm = TRUE) + sum(res2, na.rm = TRUE) > 0)
                if (greater_logic) {
                    sub_df <- condaSearch_df[res4, ]
                    if (print_out) {
                        message(paste(pkg_and_vers[1], "version", ver_logic, package_version, "are available from the following channels:"))
                        print(sub_df)
                        return(TRUE)
                    } else {
                        return(list(exact_match = TRUE, version_matches = sub_df))
                    }
                } else {
                    if (print_out) {
                        message(paste(pkg_and_vers[1], "is available, but versions", ver_logic, package_version, "are not. The following versions are currently available:"))
                        print(condaSearch_df)
                        return(FALSE)
                    } else {
                        return(list(exact_match = FALSE, version_matches = condaSearch_df))
                    }
                }
            } else if (ver_logic == "<=") {

                lesser_logic <- (sum(res1, na.rm = TRUE) +
                                                     sum(res2, na.rm = TRUE) > 0)
                if (lesser_logic) {
                    sub_df <- condaSearch_df[res5, ]
                    if (print_out) {
                        message(paste(pkg_and_vers[1], "versions", ver_logic, package_version, "are available from the following channels:"))
                        print(sub_df)
                        return(TRUE)
                    } else {
                        return(list(exact_match = TRUE, version_matches = sub_df))
                    }
                } else {
                    if (print_out) {
                        message(paste(pkg_and_vers[1], "is available, but version", ver_logic, package_version, "are not. The following versions are currently available:"))
                        print(condaSearch_df)
                        return(FALSE)
                    } else {
                        return(list(exact_match = FALSE, version_matches = condaSearch_df))
                    }
                }
            } else {
                if (print_out) {
                    message(paste(pkg_and_vers[1], "is available, but version", package_version, "is not. The following versions are currently available:"))
                    print(condaSearch_df)
                    return(FALSE)
                } else {
                    return(list(exact_match = FALSE, version_matches = condaSearch_df))
                }
            }
        } else {
            if (print_out) {
                message(paste(pkg_and_vers[1], "is available in the following versions and channels:"))
                print(condaSearch_df)
                return(TRUE)
            } else {
                return(list(exact_match = TRUE, version_matches = condaSearch_df))
            }
        }
    } else if (!pkg_and_vers[1] %in% names(condaSearch)) {
        if (print_out) {
            message("There are no exact matches for the query '",
                pkg_and_vers[1],
                "', but multiple packages contain this text:\n",
                paste("-", names(condaSearch),
                    collapse = "\n"
                )
            )
            return(FALSE)
        } else {
            return(list(exact_match = FALSE, version_matches = paste("-", names(condaSearch),
                collapse = "\n"
            )))
        }
    }
}

