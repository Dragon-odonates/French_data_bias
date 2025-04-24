# Header #############################################################
#
# Author: Romain Frelat
# Email:  romain.frelat@fondationbiodiversite.fr
#
# Date: 2025-05-22
#
# Script Description: get distribution of gis values over the whole France


library(terra)
library(here)

read_folder <- here("data", "03_grid")
data_folder <- here("data", "gis")
extdata_folder <- here("~/OneDrive/Documents/Data/")


# Get French map ----------------------------------
# from https://gadm.org/data.html
fr <- vect(here(extdata_folder,"gadm", "gadm41_FRA_0.shp"))
# plot(fr)

# CORINE land cover 2018 -----------------
# https://land.copernicus.eu/en/products/corine-land-cover/clc2018 
# with 100m resolution (but we could get Corine plus at 10m)
clc <- rast(here(extdata_folder,"Corine", "u2018_clc2018_v2020_20u1_raster100m/DATA/U2018_CLC2018_V2020_20u1.tif"))
# extract the values of land cover
fr_3035 <- project(fr, crs(clc))
# plot(fr_3035)
clc_fr <- crop(clc, fr_3035, mask=TRUE)
# plot(clc_fr)
clc_values <- values(clc_fr)
nclc <- table(clc_values)

france_clc <- data.frame(
  "LABEL3"=levels(clc)[[1]]$LABEL3[levels(clc)[[1]]$Value%in%names(nclc)],
  "count"=as.numeric(nclc),
  "perc"=round(as.numeric(nclc)/sum(nclc)*100,3)
)

write.csv(france_clc, 
  here::here(read_folder, "france_clc2018_100m.csv"), row.names=FALSE)



# Bioclimatic regions ---------
# Metzger et al. 2013 https://doi.org/10.1111/geb.12022 
gens <-  rast(here(data_folder, "eu_croped_gens_v3.tif"))
meta_gens <- read.csv(here(data_folder, "GEnS_v3_classification.csv"))

gens_fr <- crop(gens, fr, mask=TRUE)
# for non-equal area projection, pixels are not the same size
# at the scale of France, it is acceptable, but best to avoid
# gens_values <- values(gens_fr)
# ngens <- table(gens_values)
# for raster in lat/long, best to calculate statistics with expanse
# if raster is too big, can be transform into polygons
# with as.polygons()
area_gens <- expanse(gens_fr, unit="km", byValue=TRUE)
#plot(gens_fr)

france_gens <- data.frame(
  "GEnS"=meta_gens$GEnS[match(area_gens$value, meta_gens$GEnS_seq)],
  "GEnZname"=meta_gens$GEnZname[match(area_gens$value, meta_gens$GEnS_seq)],
  "count"=as.numeric(area_gens$area),
  "perc"=round(as.numeric(area_gens$area)/sum(area_gens$area)*100,3)
)

write.csv(france_gens, 
  here::here(read_folder, "france_GEnS_v3.csv"), row.names=FALSE)
