#### determine_country_by_coordinate ####

#' @rdname country_attribution
#' @export
determine_country_by_coordinate <- function(x) {
  UseMethod("determine_country_by_coordinate")
}

#' @rdname country_attribution
#' @export
determine_country_by_coordinate.default <- function(x) {
  stop("x is not an object of class c14_date_list")
}

#' @rdname country_attribution
#' @export
determine_country_by_coordinate.c14_date_list <- function(x) {

  check_if_packages_are_available(c("sf", "rworldxtra", "rgeos"))
  x %>% check_if_columns_are_present(c("lat", "lon"))

  x %<>% dplyr::mutate(ID = seq(1,nrow(x),1))

  sf_x <- x %>%
    dplyr::filter(!is.na(.data$lat),.data$lon!=0,.data$lat!=0) %>%
    spatial_join_with_country_dataset()

  sf_x <- x %>%
    dplyr::filter(is.na(.data$lat) | .data$lon == 0 | .data$lat == 0) %>%
    dplyr::bind_rows(., sf_x) %>%
    dplyr::arrange(.data$ID) %>%
    dplyr::select(-.data$ID) %>%
    as.c14_date_list()

  return(sf_x)
}

#### helpers ####

get_world_map <- function() {
  # load world map data from rworldxtra
  countriesHigh <- NA
  utils::data("countriesHigh", package = "rworldxtra", envir = environment())
  if(!"SpatialPolygonsDataFrame" %in% class(countriesHigh)) {
    stop("Problems loading countriesHigh dataset from package rworldxtra.")
  }
  world <- countriesHigh %>%
    sf::st_as_sf()
  return(world)
}

spatial_join_with_country_dataset <- function(x, buffer_dist = NA) {
  world <- get_world_map()
  x_sf <- x %>% sf::st_as_sf(coords = c("lon","lat"),
               remove = FALSE,
               crs = 4326)
  if(!is.na(buffer_dist)) {x_sf %<>% sf::st_buffer(dist = buffer_dist)}
  x_sf %>%
    sf::st_join(y = world) %>%
    dplyr::mutate(country_coord = as.character(.data$ADMIN.1)) %>%
    dplyr::select(unique(c(names(x), "country_coord"))) %>%
    return()
}