## dataPrepNews
# -------------
#' Show the NEWS file
#' 
#' Show the NEWS file of the dataPreparation package.
#' @export
dataPrepNews <- function() {
  newsfile <- system.file("NEWS", package = "dataPreparation")
  file.show(newsfile)
}

## .onAttach
# ----------
.onAttach <- function(libname, pkgname) {
  DPver <- read.dcf(file = system.file("DESCRIPTION", package = pkgname),
                    fields = "Version")
  packageStartupMessage(paste(pkgname, DPver))
  packageStartupMessage("Type dataPrepNews() to see new features/changes/bug fixes.")
}