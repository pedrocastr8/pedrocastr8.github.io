# Loading Packages
library(httr)
library(jsonlite)
library(tidyverse)
library(googledrive)

# Function for user in API
get_random_user <- function() {
  # Make the API request
  response <- httr::GET("https://randomuser.me/api/?nat=BR")
  # Parse the JSON response
  json <- jsonlite::fromJSON(httr::content(response, "text"), simplifyDataFrame = TRUE)
  # Extract the user data
  user <- json$results
  return(user)
}

# Single user
users <- list()
for (i in 1:1000) {
  users[[i]] <- get_random_user()
}

# Convert to df
users_df <- dplyr::bind_rows(users)

# Create a new column for user's state based on their phone number's area code
json_text <- readLines("./dddsBrasileiros.json", warn = FALSE)
json <- fromJSON(json_text)
df_ddd_uf <- tibble(
  DDD = names(json$estadoPorDdd),
  UF = unlist(json$estadoPorDdd)
)
users_df_teste <- users_df %>%
  mutate(DDD = stringr::str_sub(cell, 2, 3),
         UF = df_ddd_uf$UF[match(DDD, df_ddd_uf$DDD)]) %>%
  filter(!is.na(UF))

# Starter pokemons from each generation
pokemons <- c("bulbasaur", "charmander", "squirtle", "pikachu", "chikorita", "cyndaquil", "totodile", "treecko",
              "torchic", "mudkip", "turtwig", "chimchar", "piplup", "snivy", "tepig", "oshawott", "chespin",
              "fennekin", "froakie", "rowlet", "litten", "popplio", "grookey", "scorbunny", "sobble")

pokemon_data <- list()

for (pokemon in pokemons) {
  # query to get name and id for pokemons list
  response_info <- GET(paste0("https://pokeapi.co/api/v2/pokemon/", pokemon))
  name <- content(response_info)$name
  id <- content(response_info)$id
  
  # get all informations
  response_type <- GET(paste0("https://pokeapi.co/api/v2/pokemon-species/", pokemon))
  types <- content(response_type)$color$name
  
  # add to list
  pokemon_data[[pokemon]] <- c(name = name, id = id, element = types)
}

# convert to data frame
pokemon_df <- bind_rows(pokemon_data, .id = "pokemon") %>%
  select(id, pokemon,name, element)


# Join user pokemon

users_pokemon_df <- users_df_teste %>%
  mutate(pokemon = sample(pokemon_df$name, size = n(), replace = TRUE)) %>%
  inner_join(pokemon_df, by = "pokemon")

# Connect to Google Drive

drive_auth()

# Get distinct values from element column

unique_element <- unique(users_pokemon_df$element)

# Creating folders in Google Drive

for (element in unique_element) {
  drive_mkdir(paste0(element))
  
  # Group by element and gender, and write csv files to the corresponding folder
  users_pokemon_df %>% 
    filter(element == .data[[1]]) %>%
    group_by(gender) %>%
    { write.csv(., file = paste0(element, "/", unique(.$gender), "_users_pokemon.csv"), row.names = FALSE) }
}