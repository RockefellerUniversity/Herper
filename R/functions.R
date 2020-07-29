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
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param updateEnv Update existing package's conda environment if already installed.
#' @return Nothing returned. Output written to file.
#' @import utils reticulate rjson
#' @export
install_CondaSysReqs <- function(pkg,channels=NULL,pathToMiniConda=NULL,updateEnv=FALSE){
  # pathToMiniConda <- "~/Desktop/testConda"

  if(is.null(pathToMiniConda)) pathToMiniConda <- reticulate::miniconda_path()

  packageDesciptions <- utils::packageDescription(pkg,fields = "SystemRequirements")
  CondaSysReqJson <- gsub("CondaSysReq:","",packageDesciptions[grepl("^CondaSysReq",packageDesciptions)])
  CondaSysReq <- rjson::fromJSON(json_str=CondaSysReqJson)
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")

  
  defaultChannels <- c("bioconda","defaults","conda-forge")
  channels <- unique(c(CondaSysReq$main$channels,defaultChannels))
  environment <- paste0(pkg,"_",utils::packageVersion(pkg))
  pathToMiniCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)
  
  miniCondaPathExists <- miniconda_exists(pathToMiniConda)
  miniCondaPkgEnvPathExists <- dir.exists(pathToMiniCondaPkgEnv)
  
  if(!miniCondaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  if(!miniCondaPkgEnvPathExists) reticulate::conda_create(envname=environment,conda=pathToConda)
  if(!miniCondaPkgEnvPathExists | (miniCondaPkgEnvPathExists & updateEnv)){
    reticulate::conda_install(envname = environment,packages = CondaSysReq$main$packages,
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
#' @param tools software to install using conda.
#' @param env Conda environment to install tools into.
#' @param channels Additional channels for miniconda (bioconda defaults and conda-forge are included automatically)
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param updateEnv Update existing package's conda environment if already installed.
#' @return Nothing returned. Output written to file.
#' @import utils reticulate rjson
#' @export
install_CondaTools <- function(tools,env,channels=NULL,pathToMiniConda=NULL,updateEnv=FALSE){
  # pathToMiniConda <- "~/Desktop/testConda"
  
  if(is.null(pathToMiniConda)) pathToMiniConda <- reticulate::miniconda_path()
  

  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  
  defaultChannels <-  c("bioconda","defaults","conda-forge")
  channels <- unique(c(channels,defaultChannels))
  environment <- env
  pathToMiniCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)
  
  miniCondaPathExists <- miniconda_exists(pathToMiniConda)
  miniCondaPkgEnvPathExists <- dir.exists(pathToMiniCondaPkgEnv)
  
  if(!miniCondaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  if(!miniCondaPkgEnvPathExists) reticulate::conda_create(envname=environment,conda=pathToConda)
  if(!miniCondaPkgEnvPathExists | (miniCondaPkgEnvPathExists & updateEnv)){
    reticulate::conda_install(envname = environment,packages = tools,
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
#' @rdname export_CondaEnv
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

  if(is.null(pathToMiniConda)) pathToMiniConda <- reticulate::miniconda_path()
  
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
  
}


#' Import Conda environment.
#'
#' IMport Conda environment
#'
#'
#' @name import_CondaEnv
#' @rdname import_CondaEnv
#'
#'
#' @author Matt Paul
#' @param yml_import conda environment yml file
#' @param pathToMiniConda NULL Path to miniconda installation
#' @return Nothing returned. Output written to file.
#' @import reticulate
#' @export
import_CondaEnv <- function(yml_import,pathToMiniConda=NULL){
  # pathToMiniConda <- "~/Desktop/testConda"
  
  if(is.null(pathToMiniConda)) pathToMiniConda <- reticulate::miniconda_path()
  
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  
  #need to add check for existence of yml
  #need to check there is no conflicting yml name
  
  system(paste(pathToConda,"env create -f", yml_import))
  
}

 