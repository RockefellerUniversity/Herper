
set_condapaths <- function(condaPaths,
                           actionPATH= "prefix",
                           actionPYTHONLIB = "replace",
                           actionPERL5LIB = "replace",
                           actionJAVALIB = "replace") {
  if (length(condaPaths) == 0) return()
  
  
  # stopifnot(is.named(envs))
  stopifnot(is.character(actionPATH), length(actionPATH) == 1,
            is.character(actionPYTHONLIB), length(actionPYTHONLIB) == 1,
            is.character(actionPERL5LIB), length(actionPERL5LIB) == 1,
            is.character(actionJAVALIB), length(actionJAVALIB) == 1)

  actionPATH <- match.arg(actionPATH, c("replace", "prefix", "suffix"))
  actionPYTHONLIB <- match.arg(actionPYTHONLIB, c("replace", "prefix", "suffix"))
  actionPERL5LIB <- match.arg(actionPERL5LIB, c("replace", "prefix", "suffix"))    
  actionJAVALIB <- match.arg(actionJAVALIB, c("replace", "prefix", "suffix"))
  
  # # if there are duplicated entries keep only the last one
  # envs <- envs[!duplicated(names(envs), fromLast = TRUE)]
  # 
  # old <- Sys.getenv(names(envs), names = TRUE, unset = NA)
  # set <- !is.na(envs)
  
  path <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
  path <- normalizePath(path, mustWork = FALSE)
  old <- list()
  old$PATH <- path
  newPATH <- condaPaths$pathToEnvBin
  
  # if(file.exists(file.path(dirname(myCytoscape$pathToEnvBin),"jre","bin","java"))){
  #   newPATH <- c(newPATH,file.path(dirname(myCytoscape$pathToEnvBin),"jre","bin"))
  # }
  
  if (actionPATH == "suffix") {
    newPATH <- c(old$PATH, newPATH)
  } else if (actionPATH == "prefix") {
    newPATH <- c(newPATH, old$PATH)
  }
  newPATH
  
  newPATH <- paste(newPATH, collapse = .Platform$path.sep)
  # message("A",path)
  Sys.setenv(PATH = newPATH)
  
  invisible(old)
}

unset_condapaths <- function(old) {
  if (length(old) == 0) return()
  path <- old$PATH
  path <- strsplit(path, .Platform$path.sep)
  path <- normalizePath(unlist(path), mustWork = FALSE)
  path <- paste(path, collapse = .Platform$path.sep)
  # message("hello",path)
  Sys.setenv(PATH = path)
}

#' Use Conda environments.
#'
#' Use Conda environments
#'
#'
#' @name with_CondaEnv
#' @rdname UseEnvironments
#'
#'
#' @author Thomas Carroll
#' @param env conda environment
#' @param pathToMiniConda Path to miniconda.
#' @import withr
#' @export
with_CondaEnv <- withr::with_(set_condapaths,function(old)unset_condapaths(old))

#' Use Conda environments.
#'
#' Use Conda environments
#'
#'
#' @name local_CondaEnv
#' @rdname UseEnvironments
#'
#'
#' @author Thomas Carroll
#' @param env conda environment
#' @param pathToMiniConda Path to miniconda.
#' @import withr
#' @export
local_CondaEnv <- withr::local_(set_condapaths,function(old)unset_condapaths(old))

