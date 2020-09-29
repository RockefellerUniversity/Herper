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
#' condaDir <- file.path(tempdir(), "r-miniconda")
#' condaPaths <- install_CondaTools("igv", "herper", pathToMiniConda = condaDir)
#' list_CondaPkgs("herper", condaDir)
#' @export
list_CondaPkgs <- function(env, pathToMiniConda = NULL,
                           pkg = NULL) {
  # pathToMiniConda <- '~/my_miniconda/' env='herper'

  if (!is.null(pathToMiniConda)) {
    pathToMiniConda <- normalizePath(pathToMiniConda)
    pathToMiniConda <- file.path(pathToMiniConda)
  } else {
    pathToMiniConda <- reticulate::miniconda_path()
  }

  pathToConda <- miniconda_conda(pathToMiniConda)

  args <- paste0("-n", env)

  result <- suppressWarnings(system2(pathToConda,
    shQuote(c("list", args, "--quiet", "--json")),
    stdout = TRUE, stderr = TRUE
  ))
  result <- rjson::fromJSON(paste(result, collapse = ""))

  if ("exception_name" %in% names(result)) {
    if (result$exception_name == "EnvironmentLocationNotFound") {
      message(paste0(
        "The environment ", env,
        " was not found./n Use list_CondaEnv() to check what environments are available."
      ))
    } else {
      message(message("Unexepected conda error. conda command failed."))
    }
  }

  result <- do.call(rbind.data.frame, result)
  rownames(result) <- NULL

  if (!is.null(pkg)) {
    return(any(result[, "name"] %in% pkg))
  }
  print(result[, c(
    "name", "version", "channel",
    "platform"
  )])
}
