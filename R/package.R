get_package_name <- function() {
  utils::packageName()
}

system_file_path <- function(...) {
  file.path(..., system.file(package = get_package_name()))
}

get_package_spec <- function() {
  getNamespaceInfo(get_package_name(), "spec")
}

get_package_version <- function() {
  get_package_spec()[["version"]]
}
