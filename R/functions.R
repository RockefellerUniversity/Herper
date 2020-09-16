is_windows <- function () {
  identical(.Platform$OS.type, "windows")
}

miniconda_exists <- function (path = miniconda_path()) 
{
  conda <- miniconda_conda(path)
  file.exists(conda)
}

miniconda_conda <- function (path = miniconda_path()) 
{
  exe <- if (is_windows()) 
    "condabin/conda.bat"
  else "bin/conda"
  file.path(path, exe)
}

#' @param forge Boolean; include the [Conda Forge](https://conda-forge.org/)
#'   repository?
#'
#' @param channel An optional character vector of Conda channels to include.
#'   When specified, the `forge` argument is ignored. If you need to
#'   specify multiple channels, including the Conda Forge, you can use
#'   `c("conda-forge", <other channels>)`.
#'
#'
#' @keywords internal
#'
#' @import reticulate
conda_create_silent <- function(envname = NULL,
                         packages = "python",
                         forge = TRUE,
                         channel = character(),
                         conda = "auto") {
  
  # resolve conda binary
  conda <- conda_binary(conda)
  
  # resolve environment name
  envname <- reticulate:::condaenv_resolve(envname)
  
  # create the environment
  args <- reticulate:::conda_args("create", envname, packages)
  
  # add user-requested channels
  channels <- if (length(channel))
    channel
  else if (forge)
    "conda-forge"
  
  for (ch in channels)
    args <- c(args, "-c", ch)
  
  result <- system2(conda, shQuote(args), stderr = FALSE, stdout = paste0("/Users/douglasbarrows/Desktop/", envname, "_environment_create_stdOut.txt"))
  
  if (result != 0L) {
    stop("Error ", result, " occurred creating conda environment ", envname,
         call. = FALSE)
  }
  
  # return the path to the python binary
  conda_python(envname = envname, conda = conda)
  
}


#' @param forge Boolean; include the [Conda Forge](https://conda-forge.org/)
#'   repository?
#'   
#' @param channel An optional character vector of Conda channels to include.
#'   When specified, the `forge` argument is ignored. If you need to
#'   specify multiple channels, including the Conda Forge, you can use
#'   `c("conda-forge", <other channels>)`.
#'
#' @param pip_ignore_installed Ignore installed versions when using pip. This is
#'   `TRUE` by default so that specific package versions can be installed even
#'   if they are downgrades. The `FALSE` option is useful for situations where
#'   you don't want a pip install to attempt an overwrite of a conda binary
#'   package (e.g. SciPy on Windows which is very difficult to install via pip
#'   due to compilation requirements).
#'   
#' @param pip_options An optional character vector of additional command line
#'   arguments to be passed to `pip` if `pip` is used.
#'
#'
#' @keywords internal
#'
#'
conda_install_silent <- function(envname = NULL,
                          packages,
                          forge = TRUE,
                          channel = character(),
                          pip = FALSE,
                          pip_options = character(),
                          pip_ignore_installed = FALSE,
                          conda = "auto",
                          python_version = NULL,
                          ...)
{
  # resolve conda binary
  conda <- conda_binary(conda)
  
  # resolve environment name
  envname <- reticulate:::condaenv_resolve(envname)
  
  # honor request for specific Python
  python_package <- "python"
  if (!is.null(python_version))
    python_package <- paste(python_package, python_version, sep = "=")
  
  # check if the environment exists, and create it on demand if needed.
  # if the environment does already exist, but a version of Python was
  # requested, attempt to install that in the existing environment
  # (effectively re-creating it if the Python version differs)
  python <- tryCatch(conda_python(envname = envname, conda = conda), error = identity)  
  
  if (inherits(python, "error") || !file.exists(python)) {
    conda_create_silent(envname, packages = python_package, conda = conda) # create environment if doesn't exist
    python <- conda_python(envname = envname, conda = conda)
  } else if (!is.null(python_package)) {
    args <- reticulate:::conda_args("install", envname, python_package)
    status <- system2(conda, shQuote(args), stderr = FALSE, stdout = paste0("/Users/douglasbarrows/Desktop/", envname, "_python_install_stdOut.txt")) # install python into the environment if its not there
    if (status != 0L) {
      fmt <- "installation of '%s' into environment '%s' failed [error code %i]"
      msg <- sprintf(fmt, python_package, envname, status)
      stop(msg, call. = FALSE)
    }
  }
  # delegate to pip if requested
  if (pip)
    return(pip_install(python, packages, pip_options = pip_options))
  
  # otherwise, use conda
  args <- reticulate:::conda_args("install", envname)
  
  # add user-requested channels
  channels <- if (length(channel))
    channel
  else if (forge)
    "conda-forge"
  
  for (ch in channels)
    args <- c(args, "-c", ch)
  
  args <- c(args, python_package, packages)
  
  result <- system2(conda, shQuote(args), stderr = FALSE, stdout = paste0("/Users/douglasbarrows/Desktop/",envname, "_",paste(packages, collapse = "_") ,"_package_install_stdOut.txt"))
  
  # check for errors
  if (result != 0L) {
    fmt <- "one or more Python packages failed to install [error code %i]"
    stopf(fmt, result)
  } 
  
  
  invisible(packages)
}

#' Install Conda requirements listed in the System Requirement field of description
#'
#' Install Conda requirements
#'
#'
#' @name install_CondaSysReqs
#' @rdname install_CondaSysReqs
#'
#'
#' @author Thomas Carroll
#' @param pkg Package to install Conda System Requirements from.
#' @param channels Additional channels for miniconda (bioconda defaults and conda-forge are included automatically)
#' @param env Name of Conda environment to install tools into.
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param updateEnv Update existing package's conda environment if already installed.
#' @param SysReqsAsJSON Parse the SystemRequirements in JSON format (see Details). Default is TRUE.
#' @param SysReqsSep Separator used in SystemRequirement field.
#' @return Nothing returned. Output written to file.
#' @import utils rjson
#' @examples
#' testPkg <- system.file("extdata/HerperTestPkg",package="CondaSysReqs")
#' install.packages(testPkg,type = "source",repos = NULL)
#' condaPaths <- install_CondaSysReqs("HerperTestPkg",pathToMiniConda=tempdir(),SysReqsAsJSON=FALSE)
#' system2(file.path(condaPaths$pathToEnvBin,"samtools"),args = "--help")
#' @export
install_CondaSysReqs <- function(pkg,channels=NULL,env=NULL,pathToMiniConda=NULL,updateEnv=FALSE,SysReqsAsJSON=TRUE,SysReqsSep=","){
  # pathToMiniConda <- "~/Desktop/testConda"

  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda,"r-miniconda")
  }

  packageDesciptions <- utils::packageDescription(pkg,fields = "SystemRequirements")
  if(SysReqsAsJSON){
    CondaSysReqJson <- gsub("CondaSysReq:","",packageDesciptions[grepl("^CondaSysReq",packageDesciptions)])
    CondaSysReq <- rjson::fromJSON(json_str=CondaSysReqJson)
  }else{
    CondaSysReq <- list()
    CondaSysReq$main <- list()
      sysreqs <- unlist(strsplit(packageDesciptions,SysReqsSep))
      CondaSysReq$main$packages <-unlist(lapply(sysreqs,function(x)gsub("^\\s+|\\s+$","",x)))
      CondaSysReq$main$channels <- NULL     
  }
  
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  defaultChannels <- c("bioconda","defaults","conda-forge")
  channels <- unique(c(CondaSysReq$main$channels,defaultChannels))
  if(is.null(env)){
    environment <- paste0(pkg,"_",utils::packageVersion(pkg))
  }else{
    environment <- env
  }
  pathToCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)
  
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  condaPkgEnvPathExists <- dir.exists(pathToCondaPkgEnv)
  
  if(!condaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  if(!condaPkgEnvPathExists) conda_create_silent(envname=environment,conda=pathToConda)
  if(!condaPkgEnvPathExists | (condaPkgEnvPathExists & updateEnv)){
    conda_install_silent(envname = environment,packages = CondaSysReq$main$packages,
                              conda=pathToConda,
                              channel = channels)
  }
  pathToEnvBin <- file.path(dirname(dirname(pathToConda)),"envs",environment,"bin")
  return(list(pathToConda=pathToConda,environment=environment,pathToEnvBin=pathToEnvBin))
}


#' Install Conda requirements.
#'
#' Install Conda requirements
#'
#'
#' @name install_CondaTools
#' @rdname install_CondaTools
#'
#'
#' @author Thomas Carroll
#' @param tools Vector of software to install using conda.
#' @param env Name of Conda environment to install tools into.
#' @param vers Vector of software version numbers to install using conda
#' @param channels Additional channels for miniconda (bioconda defaults and conda-forge are included automatically)
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param updateEnv Update existing package's conda environment if already installed.
#' @return Nothing returned. Output written to file.
#' @import utils reticulate rjson
#' @examples 
#' condaPaths <- install_CondaTools("salmon","salmon",pathToMiniConda=tempdir())
#' system2(file.path(condaPaths$pathToEnvBin,"salmon"),args = "--help")
#' @export
install_CondaTools <- function(tools,env,vers=NULL,channels=NULL,pathToMiniConda=NULL,updateEnv=FALSE){
  # pathToMiniConda <- "~/Desktop/testConda"
  
  if(is.null(vers)){
    #checks<-sapply(tools, conda_search, print_out=F)
  }else{
    #checks<-sapply(1:length(tools), function(x) conda_search(tools[x], package_version=vers[x], print_out=F))
    tools<-paste(tools,vers,sep="=")
  }
  
  
  # if(sum(checks[1,]==F)>0){
  #   idx<-which(checks[1,]==F)
  #   sapply(idx, function(x){
  #   message(paste0("The package ",tools[x], ", and version ",vers[x], " has no matches. There are these versions available: \n"))
  #   print(checks[2,x])})
  #   stop("The package and/or version are not available in conda. Check above for details.")
  #   }
  
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda,"r-miniconda")
  }
 
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  defaultChannels <- c("bioconda","defaults","conda-forge")
  channels <- unique(c(channels,defaultChannels))
  environment <- env
  pathToCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)
  
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  condaPkgEnvPathExists <- dir.exists(pathToCondaPkgEnv)
  
  
  
  if(!condaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  if(!condaPkgEnvPathExists) conda_create_silent(envname=environment,conda=pathToConda)
  if(!condaPkgEnvPathExists | (condaPkgEnvPathExists & updateEnv)){
    conda_install_silent(envname = environment,packages = tools,
                              conda=pathToConda,
                              channel = channels)
  }
  pathToEnvBin <- file.path(dirname(dirname(pathToConda)),"envs",environment,"bin")
  return(list(pathToConda=pathToConda,environment=environment,pathToEnvBin=pathToEnvBin))
}


#' Export Conda environment.
#'
#' Export Conda environment
#'
#'
#' @name export_CondaEnv
#' @rdname SaveEnvironments
#'
#'
#' @author Matt Paul
#' @param env_name Name of environment you want to save
#' @param yml_export Destination for exported environment yml file
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param depends if FALSE will only include packages explicitly installed and not dependencies
#' @return Nothing returned. Output written to file.
#' @import reticulate
#' @export
export_CondaEnv <- function(env_name,yml_export=NULL,pathToMiniConda=NULL,depends=TRUE){

  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda,"r-miniconda")
  }
  
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  if(is.null(yml_export)){
    export_path<-paste0(env_name, ".yml")
  }else{export_path<-yml_export}
  
  #need to add check for existence
  
  if(depends==T){
  system(paste(pathToConda,"env export -n", env_name, ">", export_path))
  }else{
  system(paste(pathToConda,"env export --from-history -n", env_name, ">", export_path))
  }
  return(export_path)
}


#' Import Conda environment.
#'
#' Import Conda environment
#'
#'
#' @name import_CondaEnv
#' @rdname SaveEnvironments
#'
#'
#' @author Matt Paul
#' @param yml_import conda environment yml file
#' @param name Name of the environment to create.
#' @param pathToMiniConda NULL Path to miniconda installation
#' @return Nothing returned. Output written to file.
#' @import reticulate
#' @examples 
#' testYML <- system.file("extdata/HerperTestPkg_0.1.0.yml",package="CondaSysReqs")
#' condaDir <- tempdir()
#' import_CondaEnv(testYML,"HerperTest",pathToMiniConda=condaDir)
#' export_CondaEnv("HerperTest",yml_export=tempfile(),pathToMiniConda=condaDir)
#' @export
import_CondaEnv <- function(yml_import, name=NULL, pathToMiniConda=NULL){
  # pathToMiniConda <- "~/Desktop/testConda"
  
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda,"r-miniconda")
  }
  
  if(!is.null(name)){
    file.copy(yml_import, "tmp.yml")
    tmp <- readLines("tmp.yml")
    tmp[1]<-paste0("name: ", name)
    writeLines(tmp,"tmp.yml")
    yml_import <- "tmp.yml"
  }
  
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  if(!condaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  
  #need to add check for existence of yml
  #need to check there is no conflicting yml name
  
  system(paste(pathToConda,"env create -f", yml_import))
 
  if(!is.null(name)){
   unlink("tmp.yml") 
  }
}

 