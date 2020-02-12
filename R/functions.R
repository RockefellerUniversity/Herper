
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
#' @return Nothing returned. Output written to file.
#' @import utils reticulate
#' @export
install_CondaSysReqs <- function(pkg,channels=NULL,pathToMiniConda=NULL){
  # pathToMiniConda <- "~/Desktop/testConda"

  if(is.null(pathToMiniConda)) pathToMiniConda <- reticulate:::miniconda_path()

  packageDesciptions <- utils::packageDescription(pkg,fields = "SystemRequirements")
  CondaSysReq <- gsub("CondaSysReq:","",packageDesciptions[grepl("^CondaSysReq",packageDesciptions)])
  rjson:::fromJSON(json_str=CondaSysReq)
  pathToCondaInstall <- pathToMiniConda
  pathToConda <- file.path(pathToCondaInstall,"bin","conda")

  defaultChannels <- c("bioconda","defaults","conda-forge")
  channels <- unique(c(channels,defaultChannels))
  environment <- paste0(pkg,"_",utils::packageVersion(pkg))
  reticulate::install_miniconda(pathToCondaInstall)
  reticulate::conda_create(envname=environment,conda=pathToConda)
  return(list(pathToConda=pathToConda,environment=environment))
}

