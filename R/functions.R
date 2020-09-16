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
#' @param env Name of Conda environment to install tools into.
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param updateEnv Update existing package's conda environment if already installed.
#' @param SysReqsAsJSON Parse the SystemRequirements in JSON format (see Details). Default is TRUE.
#' @param SysReqsSep Separator used in SystemRequirement field.
#' @return Nothing returned. Output written to file.
#' @import utils reticulate rjson
#' @examples
#' testPkg <- system.file("extdata/HerperTestPkg",package="CondaSysReqs")
#' install.packages(testPkg,type = "source",repos = NULL)
#' condaDir <- file.path(tempdir(),"r-miniconda")
#' condaPaths <- install_CondaSysReqs("HerperTestPkg",pathToMiniConda=condaDir,SysReqsAsJSON=FALSE)
#' system2(file.path(condaPaths$pathToEnvBin,"samtools"),args = "--help")
#' @export
install_CondaSysReqs <- function(pkg,channels=NULL,env=NULL,pathToMiniConda=NULL,updateEnv=FALSE,SysReqsAsJSON=TRUE,SysReqsSep=","){
  # pathToMiniConda <- "~/Desktop/testConda"

  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
  }

  packageDesciptions <- utils::packageDescription(pkg,fields = "SystemRequirements")
  if(is.na(packageDesciptions)){
    stop(paste(pkg, "has no external System Dependencies to install"))
  }
  
  #packageDesciptions<-"samtools==1.10, rmats>=v4.1.0, salmon"
  if(SysReqsAsJSON){
    CondaSysReqJson <- gsub("CondaSysReq:","",packageDesciptions[grepl("^CondaSysReq",packageDesciptions)])
    CondaSysReq <- rjson::fromJSON(json_str=CondaSysReqJson)
  }else{
    CondaSysReq <- list()
    CondaSysReq$main <- list()
    #Parse Reqs
    sysreqs <- unlist(strsplit(packageDesciptions,SysReqsSep))
    
    version_sep<-c("[<>)(=]")
    
    pkg_and_vers<-lapply(sysreqs, function(x) {
      x<-gsub("version|versions|Version|Versions","",x)
      nm<-trimws(unlist(strsplit(x, version_sep, perl = T)))
      nm<-nm[!(nchar(nm)==0)]
    })
    parsed_count<-sapply(pkg_and_vers, length)
  if(sum(parsed_count>2)>0){
    stop(paste("System requirements not parsed succesfully. Issues with:",sysreqs[parsed_count>2]))
  }
  
  idx1<-grep(">=",sysreqs, fixed = T)
  idx2<-grep("<=",sysreqs, fixed = T)
  idx3<-setdiff(setdiff(grep("=",sysreqs, fixed = T), idx1), idx2)
  if(length(idx1)>0){pkg_and_vers[[idx1]] <- paste0(pkg_and_vers[[idx1]], collapse=">=")}
  if(length(idx2)>0){pkg_and_vers[[idx2]] <- paste0(pkg_and_vers[[idx2]], collapse=">=")}
  if(length(idx3)>0){pkg_and_vers[[idx3]] <- paste0(pkg_and_vers[[idx3]], collapse="==")}
  
  CondaSysReq$main$packages <- unlist(pkg_and_vers)
  CondaSysReq$main$channels <- NULL     
  }
  
  # Mask GNU and C++
  idx <- grepl("GNU|C++",CondaSysReq$main$packages,perl=T)
  if(sum(idx)>0){
    CondaSysReq$main$packages<-CondaSysReq$main$packages[!idx]
    message('C++ and/or GNU Make will not been installed, to avoid conflicts. If you do want these installed in your conda, please use the install_CondaTools function.')
    if(!length(CondaSysReq$main$packages)>0){
      stop("There are no pacakges to install beyond C++ and/or GNU Make.")}}
  
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
  if(!condaPkgEnvPathExists) reticulate::conda_create(envname=environment,conda=pathToConda)
  if(!condaPkgEnvPathExists | (condaPkgEnvPathExists & updateEnv)){
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
#' @param tools Vector of software to install using conda.
#' @param env Name of Conda environment to install tools into.
#' @param channels Additional channels for miniconda (bioconda defaults and conda-forge are included automatically)
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param updateEnv Update existing package's conda environment if already installed.
#' @return Nothing returned. Output written to file.
#' @import utils reticulate rjson
#' @examples 
#' condaDir <- file.path(tempdir(),"r-miniconda")
#' condaPaths <- install_CondaTools("salmon","salmon",pathToMiniConda=condaDir)
#' system2(file.path(condaPaths$pathToEnvBin,"salmon"),args = "--help")
#' @export
install_CondaTools <- function(tools,env,channels=NULL,pathToMiniConda=NULL,updateEnv=FALSE){
  # pathToMiniConda <- "~/Desktop/testConda"
  
  #Setup miniconda 
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
  }
  pathToCondaInstall <- pathToMiniConda
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  if(!condaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  
  #Backup conda config file. Updates will be made to config for search, but want to undo these changes. 
  # if(file.exists("~/.condarc")){
  #   cp_pass<-file.copy("~/.condarc", "~/tmp_condarc")
  #   if(cp_pass){
  #     unlink("~/.condarc")
  #   }else{stop("Backup of your .condarc file failed.")}
  #   on.exit(file.copy("~/tmp_condarc", "~/.condarc", overwrite = T))
  #   on.exit(unlink("~/tmp_condarc"))
  # }else{
  #   on.exit(unlink("~/.condarc"))
  # }
  
  # #Set Channels
  # defaultChannels <- c("bioconda","defaults","conda-forge")
  # channels <- unique(c(channels,defaultChannels))
  # pathToConda <- file.path(pathToCondaInstall,"bin","conda")
  # set<-suppressWarnings(sapply(channels, function(x) system(paste(pathToConda, "config --add channels", x),intern = TRUE,
  #                                                      ignore.stderr = TRUE)))
  
  
  checks<-sapply(tools, conda_search, print_out=F, pathToMiniConda=pathToMiniConda)
  
  if(sum(checks[1,]==F)>0){
    idx<-which(checks[1,]==F)
    sapply(idx, function(x){
      message(paste0('The package "',tools[x], '" has no matches.\nThere are these packages and versions available: \n'))
    if(is.null(dim(checks[2,x][[1]]))){
    message(paste0(checks[2,x],"\n"))
    }else{
    print(checks[2,x])
    }})
    stop("The package and/or version are not available in conda. Check above for details.")
  }
  
  environment <- env
  pathToCondaPkgEnv <- file.path(pathToMiniConda,"envs",environment)

  condaPkgEnvPathExists <- dir.exists(pathToCondaPkgEnv)
  
  
  
 
  if(!condaPkgEnvPathExists) reticulate::conda_create(envname=environment,conda=pathToConda)
  if(!condaPkgEnvPathExists | (condaPkgEnvPathExists & updateEnv)){
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
    pathToMiniConda <- file.path(pathToMiniConda)
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
#' condaDir <- file.path(tempdir(),"r-miniconda")
#' import_CondaEnv(testYML,"HerperTest",pathToMiniConda=condaDir)
#' export_CondaEnv("HerperTest",yml_export=tempfile(),pathToMiniConda=condaDir)
#' @export
import_CondaEnv <- function(yml_import, name=NULL, pathToMiniConda=NULL){
  # pathToMiniConda <- "~/Desktop/testConda"
  
  if(is.null(pathToMiniConda)){
    pathToMiniConda <- reticulate::miniconda_path()
  }else{
    pathToMiniConda <- file.path(pathToMiniConda)
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

 