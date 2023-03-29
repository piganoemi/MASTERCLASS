# -----------------------------------------------------------
# Project RAGE: 
#
# Read the Series Matrix File and create 
#   patients.rds   ... patient characteristics
#   expression.rds ... expression data 
# Sample 1000 genes to create an exploratory dataset
#   training.rds   ... 200 samples data
#   validation.rds ... 112 samples data
#
# Date: 21 March 2023
#
library(tidyverse)
library(fs) #shortcut to create directories and handling files

# -------------------------------------------------
# data folders
#
cache    <- "data/cache/"
rawData  <- "data/rawData"

# -------------------------------------------------
# dependencies - input files used by this script
#
url <- "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE168753&format=file&file=GSE168753%5Fprocessed%5Fdata%2Ecsv%2Egz"

# -------------------------------------------------
# targets - output files created by this script
#
serRDS <- path(rawData, "GSE168753_processed_data.csv")
exnRDS <- path(cache,   "expression.rds")
patRDS <- path(cache,   "patients.rds")
valRDS <- path(cache,   "validation.rds")
trnRDS <- path(cache,   "training.rds")

# --------------------------------------------------
# Divert warning messages to a log file
#
lf <- file(path(cache,   "read_log.txt"), open = "wt")
sink(lf, type = "message")

# --------------------------------------------------
# Download the series file from GEO. Save in rawData
#
if(!file.exists(serRDS) ) 
  download.file(url, serRDS)

# --------------------------------------------------
# Read the file as lines of text for exploration
#
# lines <- readLines(serRDS )
# substr(lines[1:15], 1, 30)

# --------------------------------------------------
# line 5 contains the patient identifiers
#
df <- read.table(serRDS,  
           sep    = ',', 
           header = TRUE)
patientId <- df$patient_ID

--------------------------------------------------
# lines 1-4 contain the patient characteristics
#
df %>%
  as_tibble() %>%
  select(CMV, GENDER, AGE, BMI, patient_ID) %>%
  mutate(study = c(rep("training", 200), rep("validation", 194))) %>%
  select(patient_ID, study, GENDER, AGE, BMI,CMV) %>%
  saveRDS(patRDS) 

# --------------------------------------------------
# columns 6-5095 contain gene expressions, plus line 5 with patient ID
# 5090 genes for 394 patients
#
df %>% select(-c(1:4)) %>%
  as_tibble() %>%
  saveRDS(exnRDS) 

# -----------------------------------------------
# Create a sample of 1000 genes 
#
set.seed(8906)
sample(1:5090, size = 1000, replace = FALSE) %>%
  sort() -> rows

# -----------------------------------------------
# Use training (rows 1-200) as the training data
#
readRDS(exnRDS) %>%
  .[1:200,] %>%
  saveRDS(trnRDS) 

# -----------------------------------------------
# USE validation (rows 201-394) as the validation data
#
readRDS(exnRDS) %>%
  .[c(1,201:394), ]  %>%
  saveRDS(valRDS) 

# -----------------------------------------------
# Close the log file
#
sink(type = "message" ) 
close(lf)

