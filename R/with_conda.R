getCondaPaths <- function(environment,pathToMiniConda,winslash="\\"){
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
  }
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  pathToCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  condaPkgEnvPathExists <- dir.exists(pathToCondaPkgEnv)
  if(!condaPathExists) stop("No Conda found at ",pathToCondaInstall)
  if(!condaPkgEnvPathExists) stop("No Conda environment found for ",environment," at ",condaPkgEnvPathExists)
  pathToEnvBin <- file.path(dirname(dirname(pathToConda)),"envs",environment,"bin")
  condaPaths <- list(pathToConda=pathToConda,environment=environment,pathToEnvBin=pathToEnvBin)
  condaPaths <- lapply(condaPaths,normalizePath, winslash = winslash,mustWork=FALSE)
  return(condaPaths)
}

setPATH <- function(condaPaths,old,path_additional,path_action,winslash = "\\"){
  if(!is_windows()){
    newPATH <- c(condaPaths$pathToEnvBin,path_additional)
  }else{
    newPATH <- c(condaPaths$pathToEnvBin,
                 file.path(dirname(condaPaths$pathToEnvBin),"Library", "mingw-w64", "bin"),
                 file.path(dirname(condaPaths$pathToEnvBin),"Library", "usr", "bin"),
                 file.path(dirname(condaPaths$pathToEnvBin),"Library", "bin"),
                 file.path(dirname(condaPaths$pathToEnvBin), "Scripts"),
                 path_additional)
  }
  if (path_action == "suffix") {
    newPATH <- c(old$PATH, newPATH)
  } else if (path_action == "prefix") {
    newPATH <- c(newPATH, old$PATH)
  }

  newPATH <- normalizePath(newPATH, winslash = "\\",mustWork = FALSE)
  newPATH <- paste(newPATH, collapse = .Platform$path.sep)
  Sys.setenv(PATH = newPATH)
  Sys.setenv(CONDA_PREFIX = normalizePath(dirname(condaPaths$pathToEnvBin),
                                          winslash = winslash,mustWork = FALSE))
  invisible(newPATH)
}

unsetPATH <- function(old){
  path <- old$PATH
  path <- paste(path, collapse = .Platform$path.sep)
  Sys.setenv(PATH = path)
  Sys.unsetenv("CONDA_PREFIX")
}

setEnvVariables <- function(libpath,old,additional,action,winslash = "\\"){
  if(!is.null(additional)){
    ENVVAR <- additional
    old_ENVVAR <- old[libpath]
    if (action == "suffix") {
      ENVVAR <- c(old_ENVVAR, ENVVAR)
    } else if (action == "prefix") {
      ENVVAR <- c(ENVVAR, old_ENVVAR)
    }
    ENVVAR <- paste(ENVVAR, collapse = .Platform$path.sep)
    do.call(Sys.setenv, as.list(setNames(ENVVAR, libpath)))
  }
  invisible(libpath)
}

unsetEnvVariables <- function(libpath,old){
  ENVVAR <- old[[libpath]]
  if(!is.null(ENVVAR)){
    do.call(Sys.setenv, as.list(setNames(ENVVAR, libpath)))
  }else{
    Sys.unsetenv(libpath)
  }
}

getEnvVariables <- function(winslash = "\\"){
  path <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
  old <- list()
  old$PATH <- path
  old$PYTHONPATH <- Sys.getenv("PYTHONPATH",unset = NA)
  old$PERL5LIB <- Sys.getenv("PERL5LIB",unset = NA)
  old <- old[c(TRUE,!vapply(old[-1],is.na, FUN.VALUE = logical(length = 1)))]
  old <- lapply(old,normalizePath, winslash = winslash,
                        mustWork = FALSE)
  return(old)
}

setActivateEnvVariables <- function(activateScript,winslash = "\\"){
  EnvironmentalVariables <- list()
  envvarcmd <- file.path(R.home(component = "bin"),"Rscript -e 'cat(rjson::toJSON(Sys.getenv()))' ")
  if(!is_windows()){
    cmd <- "source"
    args <- paste0(activateScript," && ",envvarcmd)
  }else{
    cmd <- Sys.getenv("COMSPEC")
    args <- paste0("/c call ",activateScript," && ",envvarcmd)
  }
  CondaPrefix <- paste0("CONDA_PREFIX=",Sys.getenv("CONDA_PREFIX"))
  CondaPath <- paste0("PATH=",Sys.getenv("PATH"))
  envsToMount <- system2(command = cmd,args=args,
                         env = c(CondaPrefix,CondaPath),stdout =TRUE)
  envsToMount <- rjson::fromJSON(envsToMount)
  for(k in seq_along(envsToMount)){
    # envS <- unlist(strsplit(envsToMount[k],"="))
    envVariable <- names(envsToMount)[k]
    envValue<- envsToMount[k]
    previousEnv <- Sys.getenv(envVariable,unset = NA)
    EnvironmentalVariables[envVariable] <- previousEnv
    do.call(Sys.setenv, as.list(setNames(envValue, envVariable)))
  }
  return(EnvironmentalVariables)
}

activateScriptsEnvVariables <- function(old,condaPaths){
  activateScripts <- dir(file.path(dirname(condaPaths$pathToEnvBin),
                                   "etc",
                                   "conda",
                                   "activate.d"),full.names = TRUE)

  deactivateScripts <- dir(file.path(dirname(condaPaths$pathToEnvBin),
                                     "etc",
                                     "conda",
                                     "deactivate.d"),full.names = TRUE)
  stopifnot(length(activateScripts) == length(deactivateScripts))

  if(length(activateScripts) > 0){
    old$activateScripts <- activateScripts
    old$deactivateScripts <- deactivateScripts
    old$EnvironmentalVariables <- unlist(lapply(activateScripts,setActivateEnvVariables))
  }
  return(old)
}

deactivateScriptsEnvVariables <- function(old){
  if(length(old$EnvironmentalVariables) > 0){
    for(e in seq_along(old$EnvironmentalVariables)){
      envVariable <- names(old$EnvironmentalVariables)[e]
      envValue <- old$EnvironmentalVariables[[e]]
      if(is.na(envValue)){
        Sys.unsetenv(envVariable)
      }else{
        do.call(Sys.setenv, as.list(setNames(envValue, envVariable)))
      }
    }
  }
}


set_condapaths <- function(environment,
                           pathToMiniConda=NULL,
                           path_action= "prefix",
                           pythonpath_action = "replace",
                           perl5lib_action = "replace",
                           path_additional= NULL,
                           pythonpath_additional = NULL,
                           perl5lib_additional = NULL
                           ) {

  if (length(environment) == 0) return()
  stopifnot(is.character(path_action), length(path_action) == 1,
            is.character(perl5lib_action), length(perl5lib_action) == 1,
            is.character(pythonpath_action), length(pythonpath_action) == 1)

  path_action <- match.arg(path_action, c("replace", "prefix", "suffix"))
  perl5lib_action <- match.arg(perl5lib_action, c("replace", "prefix", "suffix"))
  pythonpath_action <- match.arg(pythonpath_action, c("replace", "prefix", "suffix"))


  condaPaths <- getCondaPaths(environment,pathToMiniConda,winslash="\\")
  old <- getEnvVariables()
  setPATH(condaPaths,old,path_additional,path_action)
  setEnvVariables("PYTHONPATH",old,perl5lib_additional,perl5lib_action,winslash = "\\")
  setEnvVariables("PERL5LIB",old,pythonpath_additional,pythonpath_action,winslash = "\\")
  old <- activateScriptsEnvVariables(old,condaPaths)
  invisible(old)
}

unset_condapaths <- function(old) {
  if (length(old) == 0) return()
  deactivateScriptsEnvVariables(old)
  unsetPATH(old)
  unsetEnvVariables("PERL5LIB",old)
  unsetEnvVariables("PYTHONPATH",old)
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
#' @param new The name of conda environment to include in the temporary R environment.
#' @param code Code to execute in the temporary R environment
#' @param pathToMiniConda Path to miniconda.
#' @param path_action 	Should new values "replace", "prefix" or "suffix" existing PATH variable.
#' @param pythonpath_action Should new values "replace", "prefix" or "suffix" existing PYTHONPATH variable.
#' @param perl5lib_action Should new values "replace", "prefix" or "suffix" existing PERL5LIB variable.
#' @param path_additional Additional paths to suffix to existing PATH variable.
#' @param pythonpath_additional Additional paths to suffix to existing PYTHONPATH variable.
#' @param perl5lib_additional Additional paths to suffix to existing PERL5LIB variable.
#' @param .local_envir The environment to use for scoping.
#' @import withr
#' @importFrom stats setNames
#' @return Nothing returned.
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
#' @examples
#' local_CondaEnv(new = "herperTestDWB")
#' @export
local_CondaEnv <- withr::local_(set_condapaths,function(old)unset_condapaths(old))

