tempdir2 <- function() {
  gsub("\\", "/", tempdir(), fixed = TRUE)
}

miniconda_exists <- function(path = miniconda_path()) {
  conda <- miniconda_conda(path)
  file.exists(conda)
}

miniconda_conda <- function(path = miniconda_path()) {
  exe <- if (is_windows()) {
    "condabin/conda.bat"
  } else {
    "bin/conda"
  }
  file.path(path, exe)
}

channel_list<-function(channel){
  chan<-list()
  for (ch in channel) {
    chan <- c(chan, "-c", ch)
  }
  return(chan)
}

#####
# following are internal functions from reticulate

is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

is_windows <- function() {
  identical(.Platform$OS.type, "unix")
}

is_osx <- function() {
  Sys.info()["sysname"] == "Darwin"
}

is_linux <- function () {
  identical(tolower(Sys.info()[["sysname"]]), "linux")
}




`%||%` <- function(x, y) if (is.null(x)) y else x

python_environment_resolve <- function(envname = NULL, resolve = identity) {

  # use RETICULATE_PYTHON_ENV as default
  envname <- envname %||% Sys.getenv("RETICULATE_PYTHON_ENV", unset = "r-reticulate")

  # treat environment 'names' containing slashes as full paths
  if (grepl("[/\\]", envname)) {
    envname <- normalizePath(envname, winslash = "/", mustWork = FALSE)
    return(envname)
  }

  # otherwise, resolve the environment name as necessary
  resolve(envname)
}

conda_args <- function(action, envname = NULL, ...) {
  envname <- condaenv_resolve(envname)

  # use '--prefix' as opposed to '--name' if envname looks like a path
  args <- c(action, "--yes")
  if (grepl("[/\\]", envname)) {
    args <- c(args, "--prefix", envname, ...)
  } else {
    args <- c(args, "--name", envname, ...)
  }

  args
}

condaenv_resolve <- function(envname = NULL) {
  python_environment_resolve(
    envname = envname,
    resolve = identity
  )
}

stopf <- function(fmt, ..., call. = FALSE) {
  stop(sprintf(fmt, ...), call. = call.)
}

###


#' Silent version of reticulate's install_miniconda
#'
#' Reticulate's install_miniconda with silent output
#'
#'
#' @name install_miniconda_silent
#' @rdname install_miniconda_silent
#'
#' @param path Path to where miniconda will be installed
#' 
#' @param verbose Print system messages from conda on progress (Default is FALSE). There is a third option "silent" which suppresses Herper and Conda messaging.
#' 
#' @param update Should miniconda be updated (Default is TRUE).
#'
#' @return Nothing returned, miniconda installed.
#' @keywords internal
#'
#' @import reticulate
#' 
install_miniconda_silent <- function(path = pathToCondaInstall, 
                                     verbose = FALSE, 
                                     update = TRUE) {

  if (grepl(" ", path, fixed = TRUE))
    if(verbose==TRUE | verbose==FALSE){
    stop("\n Cannot install Miniconda into a path containing spaces")
    }else{stop()}

  if(verbose==TRUE | verbose==FALSE){
    message("* Installing Miniconda along with core packages -- please wait a moment ...")
  }
    
    url <- reticulate:::miniconda_installer_url()
    installer <- reticulate:::miniconda_installer_download(url)
    
    if(verbose!=TRUE){
    is_unix <- reticulate:::is_unix
    is_osx <- reticulate:::is_osx
    newDef <- deparse(reticulate:::miniconda_installer_run)
    iLine <- grep("status <-",newDef)
    newDef[iLine] <- "    status <- system2(installer, args, stdout=FALSE)"
    miniconda_installer_run_silent <- eval(parse(text=newDef))
    miniconda_installer_run_silent(installer, update, path)
    }else{
    reticulate:::miniconda_installer_run(installer, update, path)  
    }
    
    ok <- reticulate:::miniconda_exists(path) && reticulate:::miniconda_test(path)
    
  if (!ok) 
    stopf("\nMiniconda installation failed [unknown reason]")
  if (update)
    if(verbose==TRUE | verbose==FALSE){
      message("* Making sure Miniconda is up to date ...")
    }
    conda <- miniconda_conda(path)
    if(verbose!=TRUE){
      system2(conda, c("update", "--yes", "--name", "base", "conda"), stdout = FALSE)
    }else{
      system2(conda, c("update", "--yes", "--name", "base", "conda"))
    }
    
  #python <- reticulate:::miniconda_python_package()
  # if(verbose!=TRUE){
  # conda_create_silentJSON(envname = "r-reticulate", packages = c(python, "numpy"), 
  #                         conda = conda)
  # }else{
  # conda_create("r-reticulate", packages = c(python, "numpy"), 
  #            conda = conda)}
  
  if(verbose==TRUE | verbose==FALSE){
  reticulate:::messagef("* Miniconda has been successfully installed at %s.", 
                      reticulate:::pretty_path(path))}

}
  
#' Silent/json version of reticulate's conda_create
#'
#' Reticulate's conda_create with silent output and json output capability
#'
#'
#' @name conda_create_silentJSON
#' @rdname conda_create_silentJSON
#'
#' @param forge Boolean; include the [Conda Forge](https://conda-forge.org/)
#'   repository?
#'
#' @param channel An optional character vector of Conda channels to include.
#'   When specified, the `forge` argument is ignored. If you need to
#'   specify multiple channels, including the Conda Forge, you can use
#'   `c("conda-forge", <other channels>)`.
#'
#' @param verbose Print system messages from conda on progress (Default is FALSE). There is a third option "silent" which suppresses Herper and Conda messaging.
#' 
#' @return Nothing returned, conda environment created.
#' @keywords internal
#'
#' @import reticulate
conda_create_silentJSON <- function(envname = NULL,
                                    forge = TRUE,
                                    channel = character(),
                                    conda = "auto", 
                                    verbose=FALSE) {

  # resolve conda binary
  conda <- reticulate::conda_binary(conda)

  # resolve environment name
  envname <- condaenv_resolve(envname)

  # create the environment
  args <- conda_args("create", envname)

  # add user-requested channels
  channels <- if (length(channel)) {
    channel
  } else if (forge) {
    "conda-forge"
  }

  chan <- channel_list(channels) 
  
  args <- c(args, chan)
  
  if(verbose==TRUE){
  result <- system2(conda, shQuote(c(args, "--quiet", "--json")), stdout = TRUE)
  }else{
  result <- system2(conda, shQuote(c(args, "--quiet", "--json")), stdout = FALSE)  
  }
  
  if (result != 0L) {
    stop("Error ", result, " occurred creating conda environment ", envname,
      call. = FALSE
    )
  }

  # return the path to the python binary
  conda_python(envname = envname, conda = conda)
}


#' Silent/json version of reticulate's conda_install
#'
#' Reticulate's conda_install with silent output and json output capability
#'
#'
#' @name conda_install_silentJSON
#' @rdname conda_install_silentJSON
#'
#' @param forge Boolean; include the [Conda Forge](https://conda-forge.org/)
#'   repository?
#'
#' @param channel An optional character vector of Conda channels to include.
#'   When specified, the `forge` argument is ignored. If you need to
#'   specify multiple channels, including the Conda Forge, you can use
#'   `c("conda-forge", <other channels>)`.
#'   
#' @param verbose Print system messages from conda on progress (Default is FALSE). There is a third option "silent" which suppresses Herper and Conda messaging.
#'
#' @return Nothing returned, packages are installed in specified environment.
#'
#' @keywords internal
#'
#'
conda_install_silentJSON <- function(envname = NULL,
                                     packages,
                                     forge = TRUE,
                                     channel = character(),
                                     conda = "auto",
                                     verbose=FALSE,
                                     ...) {
  # resolve conda binary
  conda <- reticulate::conda_binary(conda)

  # resolve environment name
  envname <- condaenv_resolve(envname)

  # otherwise, use conda
  args <- conda_args("install", envname)

  # add user-requested channels
  channels <- if (length(channel)) {
    channel
  } else if (forge) {
    "conda-forge"
  }
  
  chan <- channel_list(channels) 

  args <- c(args, chan, packages)
  
  if(verbose==TRUE){
  result <- system2(conda, shQuote(c(args, "--quiet", "--json")), stdout = TRUE)  
  }else{
  result <- system2(conda, shQuote(c(args, "--quiet", "--json")), stdout = FALSE)
  }
  
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
#' @param verbose Print system messages from conda on progress (Default is FALSE). There is a third option "silent" which suppresses Herper and Conda messaging.
#' @return Nothing returned. Output written to file.
#' @import utils rjson
#' @examples
#' testPkg <- system.file("extdata/HerperTestPkg", package = "Herper")
#' install.packages(testPkg, type = "source", repos = NULL)
#' condaDir <- file.path(tempdir(), "r-miniconda")
#' condaPaths <- install_CondaSysReqs("HerperTestPkg", 
#'     pathToMiniConda = condaDir, SysReqsAsJSON = FALSE)
#' system2(file.path(condaPaths$pathToEnvBin, "samtools"), args = "--help")
#' @export
install_CondaSysReqs <- function(pkg, channels = NULL, env = NULL,
                                 pathToMiniConda = NULL, updateEnv = FALSE,
                                 SysReqsAsJSON = FALSE, SysReqsSep = ",",
                                 verbose=FALSE) {

  packageDesciptions <- utils::packageDescription(pkg, fields = "SystemRequirements")
  if (is.na(packageDesciptions)) {
    stop(paste(pkg, "has no external System Dependencies to install"))
  }

  # packageDesciptions<-"samtools==1.10, rmats>=v4.1.0, salmon"
  if (SysReqsAsJSON) {
    CondaSysReqJson <- gsub("CondaSysReq:", "", packageDesciptions[grepl("^CondaSysReq", packageDesciptions)])
    CondaSysReq <- rjson::fromJSON(json_str = CondaSysReqJson)
  } else {
    CondaSysReq <- list()
    CondaSysReq$main <- list()
    # Parse Reqs
    sysreqs <- unlist(strsplit(packageDesciptions, SysReqsSep))

    version_sep <- c("[<>)(=]")

    pkg_and_vers <- lapply(sysreqs, function(x) {
      x <- gsub("version|versions|Version|Versions", "", x)
      nm <- trimws(unlist(strsplit(x, version_sep, perl = TRUE)))
      nm <- nm[!(nchar(nm) == 0)]
    })
    parsed_count <- vapply(pkg_and_vers, length, FUN.VALUE = numeric(length = 1))
    if (sum(parsed_count > 2) > 0) {
      stop(paste("System requirements not parsed succesfully. Issues with:", sysreqs[parsed_count > 2]))
    }

    idx1 <- grep(">=", sysreqs, fixed = TRUE)
    idx2 <- grep("<=", sysreqs, fixed = TRUE)
    idx3 <- setdiff(setdiff(grep("=", sysreqs, fixed = TRUE), idx1), idx2)
    if (length(idx1) > 0) {
      pkg_and_vers[[idx1]] <- paste0(pkg_and_vers[[idx1]], collapse = ">=")
    }
    if (length(idx2) > 0) {
      pkg_and_vers[[idx2]] <- paste0(pkg_and_vers[[idx2]], collapse = ">=")
    }
    if (length(idx3) > 0) {
      pkg_and_vers[[idx3]] <- paste0(pkg_and_vers[[idx3]], collapse = "==")
    }

    CondaSysReq$main$packages <- unlist(pkg_and_vers)
    CondaSysReq$main$channels <- NULL
  }

  # Mask GNU and C++
  idx <- grepl("GNU|C++", CondaSysReq$main$packages, perl = TRUE)
  if (sum(idx) > 0) {
    CondaSysReq$main$packages <- CondaSysReq$main$packages[!idx]
    if(verbose)message("C++ and/or GNU Make will not been installed, to avoid conflicts. If you do want these installed in your conda, please use the install_CondaTools function.")
    if (!length(CondaSysReq$main$packages) > 0) {
      stop("There are no packages to install beyond C++ and/or GNU Make.")
    }
  }

  if (is.null(env)) {
    environment <- paste0(pkg, "_", utils::packageVersion(pkg))
  } else {
    environment <- env
  }

  result <- install_CondaTools(tools = CondaSysReq$main$packages, env = environment, channels = channels, pathToMiniConda = pathToMiniConda, updateEnv = updateEnv,verbose=verbose)
  return(result)
 
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
#' @param search Whether to search for the package name and version before installing. It is highly recommended this be set to TRUE as information about available versions or similar packages will be included in the output if the exact match is not found.
#' @param verbose Print system messages from conda on progress (Default is FALSE). There is a third option "silent" which suppresses Herper and Conda messaging.
#' @return Nothing returned. Output written to file.
#' @import utils reticulate rjson
#' @examples
#' condaDir <- file.path(tempdir(), "r-miniconda")
#' condaPaths <- install_CondaTools("salmon", "salmon", pathToMiniConda = condaDir)
#' system2(file.path(condaPaths$pathToEnvBin, "salmon"), args = "--help")
#' @export
install_CondaTools <- function(tools, env, channels = NULL,
                               pathToMiniConda = NULL, updateEnv = FALSE,
                               search = TRUE,
                               verbose = FALSE) {
  # pathToMiniConda <- "~/Desktop/testConda"
  
  #verbose argument check
  if(!(verbose %in% c(TRUE,FALSE,"SILENT","silent","Silent"))){
    stop(paste0("verbose argument is set to: ", verbose,". It must either be TRUE, FALSE, or 'silent'."))
  }
  
  # Setup miniconda
  if (is.null(pathToMiniConda)) {
    pathToMiniConda <- reticulate::miniconda_path()
  } else {
    pathToMiniConda <- file.path(pathToMiniConda)
  }
  pathToMiniConda <- path.expand(pathToMiniConda)
  pathToCondaInstall <- pathToMiniConda
  condaPathExists <- miniconda_exists(pathToCondaInstall)
  if (!condaPathExists) {
    if(verbose==TRUE | verbose==FALSE){
    message("* No Miniconda found at: ",pathToCondaInstall)}
    install_miniconda_silent(pathToCondaInstall, verbose = verbose)
  }else{
    if(verbose==TRUE | verbose==FALSE){
      message("* Using Miniconda at: ",pathToCondaInstall)}  
    }
  

  # Set Channels
  defaultChannels <- c("bioconda", "defaults", "conda-forge")
  channels <- unique(c(channels, defaultChannels))
  pathToConda <- miniconda_conda(pathToCondaInstall)

  if (search == TRUE) {
    
    if(verbose==TRUE | verbose==FALSE){
    message("* Checking if your conda packages are available ...")
    }
    
    checks <- lapply(as.list(tools), conda_search, print_out = FALSE, pathToMiniConda = pathToMiniConda, channel = channels)
    checks <- simplify2array(checks)

    if (sum(checks[1, ] == FALSE) > 0) {
      idx <- which(checks[1, ] == FALSE)
      
      if(verbose==TRUE | verbose==FALSE){
       for (i in 1:length(idx)) {
         x <- idx[i]
        message(paste0('\nThe package "', tools[x], '" has no matches.\nThere are these packages and versions available: \n'))
        if (is.null(dim(checks[2, x][[1]]))) {
          message(paste0(checks[2, x], "\n"))
        } else {
          print(checks[2, x])
        }
      }
      
      if (is_windows()) {
        message(strwrap("\nThe package and/or version are not available in conda. Check above for details. Unfortunately many packages are unavailable on conda for windows."))
        return()
      }
      }
      
    stop("\nThe package and/or version are not available in conda. Check above for details.")
    }
    if(verbose==TRUE | verbose==FALSE){
    message("* Conda packages are available for install.")
  }}

  environment <- env
  pathToCondaPkgEnv <- file.path(pathToMiniConda, "envs", environment)

  condaPkgEnvPathExists <- dir.exists(pathToCondaPkgEnv)

  if (!condaPkgEnvPathExists) {
    if(verbose==TRUE | verbose==FALSE){
      message(paste0("* The environment '", environment, "' does not currently exist."))
      message(paste0("* Creating the environment '", environment, "' and installing tools ..."))}
    conda_create_silentJSON(envname = environment, conda = pathToConda)
  }
  if (!condaPkgEnvPathExists | (condaPkgEnvPathExists & updateEnv)) {
    conda_install_silentJSON(
      envname = environment, packages = tools,
      conda = pathToConda,
      channel = channels
    )
    if(verbose==TRUE | verbose==FALSE)message(paste0("* The package(s) (", paste(tools, collapse = ", "), ") are in the '", environment, "' environment."))
  } else if (condaPkgEnvPathExists & !updateEnv) {
    if(verbose==TRUE | verbose==FALSE)message(paste0("The environment '", environment, "' already exists but the tools were not installed because the 'updateEnv' argument was set to FALSE. \n"))
  }
  pathToEnvBin <- file.path(dirname(dirname(pathToConda)), "envs", environment, "bin")
  condaPaths <- list(pathToConda = pathToConda, environment = environment, pathToEnvBin = pathToEnvBin)
  if(verbose==TRUE | verbose==FALSE){
    message("Conda and Environment Information")
    message(paste0(names(condaPaths[1]), " : ", condaPaths[1]))
    message(paste0(names(condaPaths[2]), " : ", condaPaths[2]))
    message(paste0(names(condaPaths[3]), " : ", condaPaths[3]))
  }
  return(condaPaths)
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
export_CondaEnv <- function(env_name, yml_export = NULL, pathToMiniConda = NULL, depends = TRUE) {
  if (is.null(pathToMiniConda)) {
    pathToMiniConda <- reticulate::miniconda_path()
  } else {
    pathToMiniConda <- file.path(pathToMiniConda)
  }

  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall, "bin", "conda")
  condaPathExists <- miniconda_exists(pathToMiniConda)
  
  if (!condaPathExists) {
    stop("Conda does not exist at", pathToMiniConda, ".")}
  
  if (is.null(yml_export)) {
    export_path <- paste0(env_name, ".yml")
  } else {
    export_path <- yml_export
  }

  if(depends==TRUE){
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
#' @param install TRUE/FALSE whether to install miniconda at path if it doesn't exist.
#' @param channels Additional channels for miniconda (bioconda defaults and conda-forge are included automatically)
#' @return Nothing returned. Output written to file.
#' @import reticulate
#' @examples
#' testYML <- system.file("extdata/HerperTestPkg_0.1.0.yml", package = "Herper")
#' condaDir <- file.path(tempdir(), "r-miniconda")
#' import_CondaEnv(testYML, "herper_test", pathToMiniConda = condaDir)
#' export_CondaEnv("herper_test", yml_export = tempfile(), pathToMiniConda = condaDir)
#' @export
import_CondaEnv <- function(yml_import, name = NULL, pathToMiniConda = NULL, install=TRUE, channels=NULL) {
  
  if (is.null(pathToMiniConda)) {
    pathToMiniConda <- reticulate::miniconda_path()
  } else {
    pathToMiniConda <- file.path(pathToMiniConda)
  }

  pathToCondaInstall <- pathToMiniConda
  pathToConda <- miniconda_conda(pathToCondaInstall)
  
  condaPathExists <- miniconda_exists(pathToMiniConda)
  
  
  if (install){
  if (!condaPathExists) reticulate::install_miniconda(pathToCondaInstall)
  
  # Set Channels
  defaultChannels <- c("bioconda", "defaults", "conda-forge")
  channels <- unique(c(channels, defaultChannels))
  pathToConda <- miniconda_conda(pathToCondaInstall)
  
  }else{
  # if (!condaPathExists) {
  #   result<-menu(c("Yes", "No"), title=strwrap(paste("Conda does not exist at", pathToMiniConda, ". Do you want to install it here?")))
  #   if(result==1){
  #     reticulate::install_miniconda(pathToMiniConda)
  #   }else{
  #     stop(strwrap("Please specify the location of an exisintg conda directory, or where you would like to install conda and retry."))    
  #   }}
  if (!condaPathExists) {
    stop("There is no conda installed at", pathToMiniConda)} 
  }
  
  name_check<-FALSE

  if (!is.null(name)) {
    name_check<-TRUE
    if (list_CondaEnv(pathToMiniConda = pathToMiniConda, env = name)) {
      stop(strwrap(paste("Conda environment with the name", name, "already exists. Try using list_CondaEnv to see what envirnoment names are already in use.")))
    }
    tmpname <- paste0("tmp_", substr(stats::rnorm(1), 5, 7), ".yml")
    file.copy(yml_import, tmpname)
    # on.exit(unlink(tmpname))
    on.exit(unlink(tmpname))
    tmp <- readLines(tmpname)
    tmp[1] <- paste0("name: ", name)
    writeLines(tmp, tmpname)
    # tmp <- yaml::read_yaml(tmpname)
    # tmp$dependencies <- c(tmp$dependencies," ")
    # writeLines(gsub("- \' \'\n","",
    #      yaml::as.yaml(c(list("name"=name),
    #                      tmp[!names(tmp) %in% c("name")])
    #                    )
    #      ),tmpname)
    
    yml_import <- tmpname
  } else {
    # tmp <- yaml::read_yaml(yml_import)
    # if(!("name" %in% names(tmp)))stop("No name information found in file, please provide a name for the environment to the import_CondaEnv's name argument")
    # name <- tmp$name
    name <- gsub("name: ", "", readLines(yml_import, n = 1))
    if (list_CondaEnv(pathToMiniConda = pathToMiniConda, env = name)) {
      stop(strwrap(paste("Conda environment with the name", name, "already exists. Try using list_CondaEnv to see what envirnoment names are already in use.")))
    }
  }
  args <- paste0("-f", yml_import)
  result <- system2(pathToConda, shQuote(c("env", "create", "--quiet", "--json", args)), stdout = TRUE, stderr = TRUE)
  # args <- paste(yml_import,sep=" ")
  # result <- system2(pathToConda, shQuote(c("env", "create", "--quiet", "--json","-f", yml_import)), stdout = TRUE, stderr = TRUE)

}
