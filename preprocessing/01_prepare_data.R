# Header #############################################################
#
# Author: Lisa Nicvert
# Email:  lisa.nicvert@fondationbiodiversite.fr
#
# Date: 2025-01-24
#
# Script Description: prepare data


# Libraries etc -----------------------------------------------------------
library(here)

# Data wrangling
library(data.table)
library(readxl)
library(rgbif)
library(stringr)

# Spatial analysis
library(sf)

# Paths
fun_folder <- here("functions")
read_folder <- here("data/01_raw")
write_folder <- here("data/02_clean")

# Own functions
source(file.path(fun_folder, "format_data.R"))


# Read data ---------------------------------------------------------------

df_steli <- fread(file.path(read_folder,
                            "STELI_data_FR_DMS.csv"))

df_atlas <- fread(file.path(read_folder,
                            "France Opportunistics data (Opie)/odonata_202410091558.csv"))


# Standardize column names ------------------------------------------------

names_key <- read_excel(file.path(here("data"),
                                  "column_names.xlsx"),
                        sheet = 1)
names_key <- data.table(names_key)


df_steli <- rename_cols(key = names_key,
                        dtable = df_steli,
                        nam = "STELI")

df_atlas <- rename_cols(key = names_key,
                        dtable = df_atlas,
                        nam = "Atlas")


# Clean data in columns ---------------------------------------------------

## Species names -----
taxo_steli <- fread(file.path(read_folder,
                              "taxo_STELI.csv"))
taxo_steli <- unique(taxo_steli)
taxo_steli <- taxo_steli[!scientificName %in% c("Zygoptera", "Anisopetera"),]

taxo_atlas <- fread(file.path(read_folder,
                              "taxo_Atlas.csv"))
taxo_atlas <- unique(taxo_atlas)
taxo_atlas <- taxo_atlas[!scientificName %in% c("Zygoptera", "Anisopetera"),]


df_steli <- taxo_steli[df_steli,
                       on = c("verbatimName" = "scientificName")]

df_atlas <- taxo_atlas[df_atlas,
                       on = c("verbatimName" = "scientificName")]

## Dates -----
df_steli[, eventDate := as.IDate(eventDate, format =  "%d/%m/%Y")]
df_atlas[, eventDate := as.IDate(eventDate, format =  "%Y-%m-%d")]

## Times -----

# Hour and sampling effort with STELI
df_steli[, eventTime := as.ITime(eventTime)]

effort_char <- df_steli$samplingEffort # Some negative values
# -> I suspect start and end dates have been inverted
effort_char[effort_char == ""] <- NA

effort <- str_split(effort_char, ":")

effort_min <- lapply(effort,
                     function(e) {
                       as.numeric(e[1])*60+ as.numeric(e[2]) + as.numeric(e[3])/60
                     })
effort_min <- unlist(effort_min)

df_steli[, samplingEffort := effort_min]

## Coordinates -----
coord_atlas <- st_as_text(st_as_sf(df_atlas, coords = c("decimalLongitude",
                                                        "decimalLatitude"),
                                   na.fail = FALSE)$geometry)

df_atlas[, decimalCoordinates := coord_atlas]

setnames(df_steli,
         old = c("lon centroid site", "lat centroid site"),
         new = c("decimalLongitude", "decimalLatitude"))

## Reorder columns -----
cnames_steli <- names_key$Standard[names_key$Standard %in% colnames(df_steli)]
setcolorder(df_steli,
            cnames_steli)

cnames_atlas <- names_key$Standard[names_key$Standard %in% colnames(df_atlas)]
setcolorder(df_atlas,
            cnames_atlas)

# Write files -------------------------------------------------------------
write.table(df_steli,
            file = file.path(write_folder,
                             "steli.csv"),
            row.names = FALSE,
            qmethod = "double",
            sep = ",")
saveRDS(df_steli,
        file = file.path(write_folder,
                         "steli.rds"))

write.table(df_atlas,
            file = file.path(write_folder,
                             "atlas.csv"),
            row.names = FALSE,
            qmethod = "double",
            sep = ",")
saveRDS(df_atlas,
        file = file.path(write_folder,
                         "atlas.rds"))
