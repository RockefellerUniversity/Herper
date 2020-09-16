
set_condapaths <- function(env,
                           pathToMiniConda=NULL,
                           path_action= "prefix",
                           pythonpath_action = "replace",
                           perl5lib_action = "replace",
                           javahome_action = "replace",
                           path_additional= NULL,
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
  ###
  ##
  
  if(file.exists(file.path(condaPaths$pathToEnvBin,"java"))){
    JAVA_HOME=c(dirname(condaPaths$pathToEnvBin))
    JAVA_HOME=c(JAVA_HOME,javahome_additional)
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
  if(file.exists(file.path(condaPaths$pathToEnvBin,"python"))){
    PYTHONPATH <- dir(file.path(dirname(condaPaths$pathToEnvBin),"lib"),
                      pattern="site-packages$",
                      recursive=TRUE,
                      full.names = TRUE,
                      include.dirs=TRUE)
    PYTHONPATH=c(PYTHONPATH,pythonpath_additional)
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
  if(file.exists(file.path(condaPaths$pathToEnvBin,"perl"))){
    PERL5LIB <- dirname(dir(file.path(dirname(condaPaths$pathToEnvBin),"lib"),
                pattern="CPAN.pm",
                recursive=TRUE,
                full.names = TRUE))
    PERL5LIB <- c(PERL5LIB,perl5lib_additional)
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
  ##
  ###
  
  newPATH <- condaPaths$pathToEnvBin
  if (path_action == "suffix") {
    newPATH <- c(old$PATH, newPATH)
  } else if (path_action == "prefix") {
    newPATH <- c(newPATH, old$PATH)
  }
  newPATH <- paste(newPATH, collapse = .Platform$path.sep)
  Sys.setenv(PATH = newPATH)
  invisible(old)
}

unset_condapaths <- function(old) {
  if (length(old) == 0) return()
  # path <- old$PATH
  # path <- strsplit(path, .Platform$path.sep)
  # path <- normalizePath(unlist(path), mustWork = FALSE)
  # path <- paste(path, collapse = .Platform$path.sep)
  # Sys.setenv(PATH = path)
  # 
  # JAVA_HOME <- old$JAVA_HOME
  # JAVA_HOME <- strsplit(JAVA_HOME, .Platform$path.sep)
  # JAVA_HOME <- normalizePath(unlist(JAVA_HOME), mustWork = FALSE)
  # JAVA_HOME <- paste(JAVA_HOME, collapse = .Platform$path.sep)    
  # Sys.setenv(JAVA_HOME = JAVA_HOME)
  # 
  # PERL5LIB <- old$PERL5LIB
  # PERL5LIB <- strsplit(PERL5LIB, .Platform$path.sep)
  # PERL5LIB <- normalizePath(unlist(PERL5LIB), mustWork = FALSE)
  # PERL5LIB <- paste(PERL5LIB, collapse = .Platform$path.sep)    
  # Sys.setenv(PERL5LIB = PERL5LIB)
  # 
  # PYTHONPATH <- old$PYTHONPATH
  # PYTHONPATH <- strsplit(PYTHONPATH, .Platform$path.sep)
  # PYTHONPATH <- normalizePath(unlist(PYTHONPATH), mustWork = FALSE)
  # PYTHONPATH <- paste(PYTHONPATH, collapse = .Platform$path.sep)    
  # Sys.setenv(PYTHONPATH = PYTHONPATH)
  
  
  path <- old$PATH
  path <- paste(path, collapse = .Platform$path.sep)
  Sys.setenv(PATH = path)
  
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
    Sys.unsetenv("PERL5LIB")
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


