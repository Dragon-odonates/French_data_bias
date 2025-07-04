# Header #############################################################
#
# Author: Romain Frelat
# Email:  romain.frelat@fondationbiodiversite.fr
#
# Date: 2025-05-05
#
# Script Description: get distribution of gis values over the whole France

library(terra)
library(here)

read_folder <- here("data", "03_grid")
write_folder <- here("data/04_gis_info/reference")
data_folder <- here("data", "gis")
# extdata_folder <- here("~/OneDrive/Documents/Data/")


# Get French map ----------------------------------
# from https://gadm.org/data.html
fr <- vect(here(data_folder, "gadm41_FRA_shp", "gadm41_FRA_0.shp"))
# plot(fr)

# CORINE land cover 2018 -----------------
# https://land.copernicus.eu/en/products/corine-land-cover/clc2018
# with 100m resolution (but we could get Corine plus at 10m)
clc <- rast(here(
  data_folder,
  "Corine",
  "u2018_clc2018_v2020_20u1_raster100m/DATA/U2018_CLC2018_V2020_20u1.tif"
))
# extract the values of land cover
fr_3035 <- project(fr, crs(clc))
# plot(fr_3035)
clc_fr <- crop(clc, fr_3035, mask = TRUE)
# plot(clc_fr)
clc_values <- values(clc_fr)
nclc <- table(clc_values)

france_clc <- data.frame(
  "LABEL3" = levels(clc)[[1]]$LABEL3[levels(clc)[[1]]$Value %in% names(nclc)],
  "count" = as.numeric(nclc),
  "perc" = round(as.numeric(nclc) / sum(nclc) * 100, 3)
)

write.csv(
  france_clc,
  here::here(write_folder, "france_clc2018_100m.csv"),
  row.names = FALSE
)


# Bioclimatic regions ---------
# Metzger et al. 2013 https://doi.org/10.1111/geb.12022
gens <- rast(here(data_folder, "bioclim", "eu_croped_gens_v3.tif"))
meta_gens <- read.csv(here(data_folder, "bioclim", "GEnS_v3_classification.csv"))

gens_fr <- crop(gens, fr, mask = TRUE)
# for non-equal area projection, pixels are not the same size
# at the scale of France, it is acceptable, but best to avoid
# gens_values <- values(gens_fr)
# ngens <- table(gens_values)
# for raster in lat/long, best to calculate statistics with expanse
# if raster is too big, can be transform into polygons
# with as.polygons()
area_gens <- expanse(gens_fr, unit = "km", byValue = TRUE)
#plot(gens_fr)

france_gens <- data.frame(
  "GEnS" = meta_gens$GEnS[match(area_gens$value, meta_gens$GEnS_seq)],
  "GEnZname" = meta_gens$GEnZname[match(area_gens$value, meta_gens$GEnS_seq)],
  "count" = as.numeric(area_gens$area),
  "perc" = round(as.numeric(area_gens$area) / sum(area_gens$area) * 100, 3)
)

write.csv(
  france_gens,
  here::here(write_folder, "france_GEnS_v3.csv"),
  row.names = FALSE
)


# population density 2010 ---------
# https://data.jrc.ec.europa.eu/dataset/2ff68a52-5b5b-4a22-8f40-c41da8332cfe
pop <- rast(
  here(data_folder, "GHS", "GHS_POP_E2010_GLOBE_R2023A_54009_1000_V1_0.tif")
)
# project france borders
fr_54009 <- project(fr, crs(pop))
pop_fr <- crop(pop, fr_54009, mask = TRUE)

# not sure if we want to log transform or not
# extract the raw data first
valpop <- values(pop_fr)

# round the values with 6
npop <- table(round(valpop, 6), useNA = "ifany")
pop_density <- data.frame(
  value = as.numeric(names(npop)),
  area = as.numeric(npop),
  perc = as.numeric(npop) / sum(npop) * 100
)

# same as
# area_pop <- expanse(pop_fr, unit = "km", byValue = TRUE)
# hist(log1p(valpop))
# plot(pop_density$value + 1, pop_density$perc, log = "x", type = "l")
write.csv(
  pop_density,
  here::here(write_folder, "france_pop_density.csv"),
  row.names = FALSE
)

# elevation ------------
# the best source of data ae EU scale is Copernicus GLO-30
# https://dataspace.copernicus.eu/explore-data/data-collections/copernicus-contributing-missions/collections-description/COP-DEM
# imported from Google Earth Engine
fr_stat <- read.csv(here(data_folder, "glo30_fr_stats.csv"))
valC <- grep("^Class_", names(fr_stat))
valC <- valC[valC != which(names(fr_stat) == "Class_sum")]
area <- as.numeric(fr_stat[, valC])
elevation <- as.numeric(gsub("^Class_", "", names(fr_stat)[valC]))
elev <- round(elevation)
area_km <- tapply(area, elev, sum)

fr_glo <- data.frame(
  value = as.numeric(names(area_km)),
  area = area_km,
  perc = area_km / sum(area_km) * 100
)
fr_glo <- fr_glo[order(fr_glo$value), ]

write.csv(
  fr_glo,
  here::here(write_folder, "france_elevation.csv"),
  row.names = FALSE
)
