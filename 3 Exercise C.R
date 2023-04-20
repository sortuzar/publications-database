
# Preliminary data analysis

# Limpiar environment
rm(list=ls())

# Librerías
library(tidyverse)

# Determinar ubicación de las carpetas
directory_data <- "data/"
directory_output <- "output/"

# Importar datos
publications <- readRDS(paste0(directory_output,"2 Data Retrieved from OpenAlex.rds"))

# Ideas
# 1: Check subjects (CrossRef)
sort(unique(publications$CrossRef_subject))
# Create categorical variables for specific subjects of greater interest

# 2: Check more cited journal in your references
sort(table(publications$CrossRef_container.title))

# 3: Check more cited publications
#sort(table(publications$CrossRef_is.referenced.by.count))

# 4: Check whether some publications appear in CrossRef but not OpenAlex and viceversa
publications1 <- publications %>%
  mutate(available=case_when(available_crossref==1&available_openalex==0~"Only CrossRef",
                             available_crossref==0&available_openalex==1~"Only OpenAlex",
                             available_crossref==1&available_openalex==1~"All",
                             TRUE~"Not Available")) %>%
  mutate(available=factor(available,
                          levels=c("Not Available","Only CrossRef", "Only OpenAlex", "All")))

table(publications1$available,exclude=NULL)

# 5: Correlations between OpenAlex and CrossRef counts of citations
publications2 <- publications1 %>%
  mutate(OpenAlex_cited_by_count=replace_na(OpenAlex_cited_by_count,0),
         CrossRef_is.referenced.by.count=replace_na(CrossRef_is.referenced.by.count,"0"))

table(publications2$OpenAlex_cited_by_count,exclude=NULL)
class(publications2$OpenAlex_cited_by_count)
table(publications2$CrossRef_is.referenced.by.count,exclude=NULL)
class(publications2$CrossRef_is.referenced.by.count)

publications3 <- publications2 %>%
  mutate(CrossRef_is.referenced.by.count=as.numeric(CrossRef_is.referenced.by.count),
         OpenAlex_cited_by_count=as.numeric(OpenAlex_cited_by_count))

cor(publications3$CrossRef_is.referenced.by.count,
    publications3$OpenAlex_cited_by_count,
    use="complete.obs")

# Highly correlated but values differ substantially in magnitude
# plot
