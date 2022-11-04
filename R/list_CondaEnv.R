#' List Conda environments.
#'
#' List Conda environments
#'
#'
#' @name list_CondaEnv
#' @rdname ListCondaEnvironments
#'
#'
#' @author Matt Paul
#' @param pathToMiniConda NULL Path to miniconda installation
#' @param allCondas Logical. Whether to return conda environments, for all discoverable conda installs, or just the conda specified in pathToMiniConda.
#' @param env Environment name. If this is supplied to list_CondaEnv, it will query whether that environment is present in the given conda.
#' @return Conda environment names and the file paths to their conda installation are printed to the screen. If environment name is supplied a TRUE/FALSE will be returned depending on whether that environment is present or not.
#' @import reticulate
#' @examples
#' condaPaths <- install_CondaTools("salmon", "herperTestDWB")
#' list_CondaEnv()
#' list_CondaEnv( env = "herperTestDWB")
#' @export
list_CondaEnv <- function(pathToMiniConda = NULL, allCondas = FALSE, env = NULL) {
  # pathToMiniConda <- "~/my_miniconda/"

  if (!is.null(pathToMiniConda)) {
    pathToMiniConda <- normalizePath(pathToMiniConda)
    conda_bin <- file.path(pathToMiniConda, "bin", "conda")
    all_envs <- conda_list(conda_bin)
  } else {
    all_envs <- conda_list()
  }

  conda_paths <- vapply(all_envs[, 2], strsplit, FUN.VALUE = list(length = length(all_envs[, 2])), split = "/condaenvs/|/envs/")
  conda_paths <- vapply(as.list(conda_paths), function(x) {
    ifelse(length(x) == 1, gsub("/bin/python", "", x), x)
  }, FUN.VALUE = character(length = 1))
  conda_paths <- as.data.frame(conda_paths)
  rownames(conda_paths) <- NULL
  all_envs <- cbind(conda_paths, all_envs)
  colnames(all_envs)[c(1, 2)] <- c("conda path", "env")


  if (is.null(pathToMiniConda) | allCondas == TRUE) {
    print(all_envs[, c(1, 2)])
  } else {
    env_out <- (all_envs[all_envs[, 1] %in% pathToMiniConda, ])
    rownames(env_out) <- NULL
    if (!is.null(env)) {
      return(any(env_out[, 2] %in% env))
    }

    print(env_out[, c(1,2)])
  }
}
