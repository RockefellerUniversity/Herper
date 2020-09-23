
set_condapaths <- function(env,
                           pathToMiniConda=NULL,
                           path_action= "prefix",
                           path_additional= NULL,
                           pythonpath_action = "replace",
                           perl5lib_action = "replace",
                           javahome_action = "replace",
                           pythonpath_additional = NULL,
                           perl5lib_additional = NULL,
                           javahome_additional = NULL
                           ) {
  
  if (length(environment) == 0) return()
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
  }
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  environment <- env
  pathToCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  condaPkgEnvPathExists <- dir.exists(pathToCondaPkgEnv)
  if(!condaPathExists) stop("No Conda found at ",pathToCondaInstall)
  if(!condaPkgEnvPathExists) stop("No Conda environment found for ",environment," at ",condaPkgEnvPathExists)
  
  
  pathToEnvBin <- file.path(dirname(dirname(pathToConda)),"envs",environment,"bin")
  condaPaths <- list(pathToConda=pathToConda,environment=environment,pathToEnvBin=pathToEnvBin)
  
  
  stopifnot(is.character(path_action), length(path_action) == 1,
            is.character(perl5lib_action), length(perl5lib_action) == 1,
            is.character(pythonpath_action), length(pythonpath_action) == 1,
            is.character(javahome_action), length(javahome_action) == 1
  )
  
  path_action <- match.arg(path_action, c("replace", "prefix", "suffix"))
  perl5lib_action <- match.arg(perl5lib_action, c("replace", "prefix", "suffix"))    
  javahome_action <- match.arg(javahome_action, c("replace", "prefix", "suffix"))    
  pythonpath_action <- match.arg(pythonpath_action, c("replace", "prefix", "suffix")) 
  
  
  path <- strsplit(Sys.getenv("PATH"), .Platform$path.sep)[[1]]
  path <- normalizePath(path, mustWork = FALSE)
  
  old <- list()
  old$PATH <- path
  old$JAVA_HOME <- Sys.getenv("JAVA_HOME",unset = NA)
  old$PYTHONPATH <- Sys.getenv("PYTHONPATH",unset = NA)
  old$PERL5LIB <- Sys.getenv("PERL5LIB",unset = NA)
  old <- old[c(TRUE,!sapply(old[-1],is.na))]
  
  newPATH <- c(condaPaths$pathToEnvBin,path_additional)
  if (path_action == "suffix") {
    newPATH <- c(old$PATH, newPATH)
  } else if (path_action == "prefix") {
    newPATH <- c(newPATH, old$PATH)
  }
  newPATH <- paste(newPATH, collapse = .Platform$path.sep)
  
  Sys.setenv(PATH = newPATH)
  Sys.setenv(CONDA_PREFIX = pathToCondaPkgEnv)
  
  if(!is.null(javahome_additional)){
    JAVA_HOME <- javahome_additional
    old_JAVA_HOME <- old$JAVA_HOME
    if (javahome_action == "suffix") {
      JAVA_HOME <- c(old_JAVA_HOME, JAVA_HOME)
    } else if (javahome_action == "prefix") {
      JAVA_HOME <- c(JAVA_HOME, old_JAVA_HOME)
    }
    JAVA_HOME <- paste(JAVA_HOME, collapse = .Platform$path.sep)
    Sys.setenv(JAVA_HOME=JAVA_HOME)
    message(JAVA_HOME)
  }
  ##
  ###
  ###
  ##
  if(!is.null(pythonpath_additional)){
    PYTHONPATH <- pythonpath_additional
    old_PYTHONPATH <- old$PYTHONPATH
    if (pythonpath_action == "suffix") {
      PYTHONPATH <- c(old_PYTHONPATH, PYTHONPATH)
    } else if (pythonpath_action == "prefix") {
      PYTHONPATH <- c(PYTHONPATH, old_PYTHONPATH)
    }
    PYTHONPATH <- paste(PYTHONPATH, collapse = .Platform$path.sep)
    Sys.setenv(PYTHONPATH=PYTHONPATH)
    message(PYTHONPATH)
  }
  ##
  ###
  ###
  ##
  if(!is.null(perl5lib_additional)){
    PERL5LIB <- perl5lib_additional
    old_PERL5LIB <- old$PERL5LIB
    if (perl5lib_action == "suffix") {
      PERL5LIB <- c(old_PERL5LIB, PERL5LIB)
    } else if (perl5lib_action == "prefix") {
      PERL5LIB <- c(PERL5LIB, old_PERL5LIB)
    }
    PERL5LIB <- paste(PERL5LIB, collapse = .Platform$path.sep)
    Sys.setenv(PERL5LIB=PERL5LIB)
    message(PERL5LIB)
  }
  
  activateScripts <- dir(file.path(pathToCondaPkgEnv,
                               "etc",
                               "conda",
                               "activate.d"),full.names = TRUE)

  deactivateScripts <- dir(file.path(pathToCondaPkgEnv,
                                   "etc",
                                   "conda",
                                   "deactivate.d"),full.names = TRUE)
  
  
  if(length(activateScripts) > 0 & length(activateScripts) == length(deactivateScripts)){
    old$activateScripts <- activateScripts
    old$deactivateScripts <- deactivateScripts    
    old$EnvironmentalVariables <- list()
    for(i in 1:length(activateScripts)){
      # message("Running activate script - ",activateScripts[i])
      # system(readLines(activateScripts[i]),intern = TRUE)
      if(.Platform$OS.type == "unix"){
        CondaPrefix <- paste0("CONDA_PREFIX=",Sys.getenv("CONDA_PREFIX"))
        CondaPath <- paste0("PATH=",Sys.getenv("PATH"))      
        # allEnv <- paste(names(allEnv),unname(allEnv),sep = "=")
        envsToMount <- system2(command = "source",args=paste0(activateScripts[i],";printenv"),env = c(CondaPrefix,CondaPath),stdout =TRUE)
        for(k in 1:length(envsToMount)){
          envS <- unlist(strsplit(envsToMount[k],"="))
          envVariable <- envS[1]
          envValue<- envS[2]
          previousEnv <- Sys.getenv(envVariable,unset = NA)
          old$EnvironmentalVariables[envVariable] <- previousEnv
          # if(previousEnv!=envValue){
            # message("Setting environmental variable for ",envVariable," to ",envValue)
            # .Internal(Sys.setenv(envVariable,envValue))
            do.call(Sys.setenv, as.list(setNames(envValue, envVariable)))
          # }
          
        }
      }
    }
  }
  
  

  invisible(old)
}

unset_condapaths <- function(old) {
  if (length(old) == 0) return()
  
  
  # if(length(old$deactivateScripts) > 0){
  #   for(i in 1:length(old$deactivateScripts)){
  #     message("Running activate script - ",old$deactivateScripts[i])
  #     if(.Platform$OS.type == "unix"){
  #       system(paste0("source ",old$deactivateScripts[i]),intern = TRUE)
  #     }
  #   }
  # }
  
  if(length(old$EnvironmentalVariables) > 0){
    for(e in 1:length(old$EnvironmentalVariables)){
      envVariable <- names(old$EnvironmentalVariables)[e]
      envValue <- old$EnvironmentalVariables[[e]]
      if(is.na(envValue)){
        Sys.unsetenv(envVariable)
      }else{
        do.call(Sys.setenv, as.list(setNames(envValue, envVariable)))
        # .Internal(Sys.setenv(envVariable,envValue))
      }
    }
  }
  
  path <- old$PATH
  path <- paste(path, collapse = .Platform$path.sep)
  Sys.setenv(PATH = path)
  Sys.unsetenv("CONDA_PREFIX")
  JAVA_HOME <- old$JAVA_HOME
  if(!is.null(JAVA_HOME)){
    Sys.setenv(JAVA_HOME = old$JAVA_HOME)
  }else{
    Sys.unsetenv("JAVA_HOME")
  }
  PERL5LIB <- old$PERL5LIB
  if(!is.null(PERL5LIB)){  
    Sys.setenv(PERL5LIB = PERL5LIB)
  }else{
    Sys.unsetenv("PERL5LIB")
  }
  
  PYTHONPATH <- old$PYTHONPATH
  if(!is.null(PYTHONPATH)){  
    Sys.setenv(PYTHONPATH = PYTHONPATH)
  }else{
    Sys.unsetenv("PYTHONPATH")
  }
  
  
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
#' @param javahome_action Should new values "replace", "prefix" or "suffix" existing JAVA_HOME variable.
#' @param perl5lib_action Should new values "replace", "prefix" or "suffix" existing PERL5LIB variable.
#' @param path_additional Additional paths to suffix to existing PATH variable.
#' @param pythonpath_additional Additional paths to suffix to existing PYTHONPATH variable.
#' @param javahome_additional Additional paths to suffix to existing JAVA_HOME variable.
#' @param perl5lib_additional Additional paths to suffix to existing PERL5LIB variable.
#' @param .local_envir The environment to use for scoping.
#' @import withr
#' @importFrom stats setNames
#' @examples
#' testYML <- system.file("extdata/HerperTestPkg_0.1.0.yml",package="CondaSysReqs")
#' condaDir <- file.path(tempdir(),"r-miniconda")
#' import_CondaEnv(testYML,"HerperTest",pathToMiniConda=condaDir)
#' with_CondaEnv("HerperTest",system2(command = "rmats.py",args = "-h"),pathToMiniConda = condaDir)
#' \dontrun{
#'   install_CondaTools("cytoscape","cytoscape",updateEnv = TRUE,pathToMiniConda = condaDir)
#'   with_CondaEnv("cytoscape",system2(command = "cytoscape.sh"),pathToMiniConda = condaDir)
#' }
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
#' @export
local_CondaEnv <- withr::local_(set_condapaths,function(old)unset_condapaths(old))

#' #' Use Conda environments.
#' #'
#' #' Use Conda environments
#' #'
#' #'
#' #' @name local_CondaEnv
#' #' @rdname UseEnvironments
#' #'
#' #' @export
#' System2_CondaEnv <- function()


