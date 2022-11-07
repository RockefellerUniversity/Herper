#' List Conda packages.
#'
#' List Conda packages
#'
#'
#' @name list_CondaPkgs
#' @rdname ListCondaPackages
#'
#'
#' @author Matt Paul
#' @param env environment to look in
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param pkg Package name. If this is supplied to list_CondaPkg, it will query whether that package is present in the given environment.
#' @return Conda package information is printed to the screen. If package name is supplied a TRUE/FALSE will be returned depending on whether that package is present or not.
#' @import reticulate rjson
#' @examples
#' condaPaths <- install_CondaTools("salmon", "herper_env")
#' list_CondaPkgs("herper_env")
#' @export
list_CondaPkgs <- function(env, pathToMiniConda = NULL,
                           pkg = NULL) {

  if (!is.null(pathToMiniConda)) {
    pathToMiniConda <- normalizePath(pathToMiniConda)
    pathToMiniConda <- file.path(pathToMiniConda)
  } else {
    pathToMiniConda <- reticulate::miniconda_path()
  }
  condaPathExists <- miniconda_exists(pathToMiniConda)
  
  if (!condaPathExists) {
    stop("There is no conda installed at", pathToMiniConda)}    
  #   result<-menu(c("Yes", "No"), title=strwrap(paste("Conda does not exist at", pathToMiniConda, ". Do you want to install it here?")))
  # if(result==1){
  # reticulate::install_miniconda(pathToMiniConda)
  # }else{
  # stop(strwrap("Please specify the location of an exisintg conda directory, or where you would like to install conda and retry."))    
  #   }}
  
  
  pathToConda <- miniconda_conda(pathToMiniConda)

  args <- paste0("-n", env)

  result <- suppressWarnings(system2(pathToConda,
    shQuote(c("list", args, "--quiet", "--json")),
    stdout = TRUE, stderr = FALSE
  ))
  result <- rjson::fromJSON(paste(result, collapse = ""))

  if ("exception_name" %in% names(result)) {
    if (result$exception_name == "EnvironmentLocationNotFound") {
      message(strwrap(paste("The environment ", env,
        " was not found. Use list_CondaEnv() to check what environments are available."
      )))
    } else {
      message("Unexepected conda error. conda command failed.")
    }
  }else{

  result <- do.call(rbind.data.frame, result)
  rownames(result) <- NULL

  if (!is.null(pkg)) {
    return(any(result[, "name"] %in% pkg))
  }
  return(result[, c(
    "name", "version", "channel",
    "platform"
  )])

}}
