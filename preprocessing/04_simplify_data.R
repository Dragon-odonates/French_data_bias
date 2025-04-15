# Header #############################################################
#
# Author: Romain Frelat
# Email:  romain.frelat@fondationbiodiversite.fr
#
# Date: 2025-04-14
#
# Script Description: merge datasets and simplify them

# Libraries and parameters -------------------------------------------------
library(data.table)
library(here)

read_folder <- here("data/03_grid")


# Load and merge dataset ---------------------------------------------
df_steli <- readRDS(file.path(read_folder, "steli.rds"))
df_atlas <- readRDS(file.path(read_folder, "atlas.rds"))

df_steli <- as.data.table(df_steli)
df_atlas <- as.data.table(df_atlas)

df_steli[, source := "STELI"]
df_atlas[, source := "atlas"]

dat <- rbind(df_steli,
  df_atlas, fill = TRUE)

# Filter only species level information
dat <- dat[taxonRank == "SPECIES", ]

# Filter columns that are in the two datasets
keep_col <- names(dat)%in%names(df_steli) & names(dat) %in% names(df_atlas)
dat <- dat[, ..keep_col]

# Remove the separate data (to save RAM)
rm(df_atlas)
rm(df_steli)

# Match with GIS information ---------------------------------------------

# load gis data
gis_info <- read.csv(file.path(read_folder, "gis_info.csv"))

#create an ID for matching rows
gis_info$coordinate_ID <- paste(gis_info$longitude, gis_info$latitude, sep="_")
dat$coordinate_ID <- paste(dat$decimalLongitude, dat$decimalLatitude, sep="_")

# match the coordinates
mgis <- match(dat$coordinate_ID, gis_info$coordinate_ID)

# join the two datasets
dat_full <- cbind(dat, gis_info[mgis,])



# remove unnecessary columns
rmCol <- c("decimalCoordinates", "geometry", "coordinate_ID", 
            "X", "longitude", "latitude")
dat_full <- set(dat_full, j=which(names(dat_full)%in%rmCol), value=NULL)

dim(dat_full)
# str(dat_full)


# Export -------------------------------------------------------------
write.table(dat_full,
            file = file.path(read_folder,
                             "french_odonate_data.csv"),
            row.names = FALSE,
            qmethod = "double",
            sep = ",")
saveRDS(dat_full,
        file = file.path(read_folder,
                         "french_odonate_data.rds"))