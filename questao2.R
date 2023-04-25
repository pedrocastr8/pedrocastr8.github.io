# Loading Packages
library(httr)
library(jsonlite)
library(tidyverse)
library(googledrive)
library(googlesheets4)
library(readxl)
library(writexl)

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
  select(id, pokemon,element)


# Join user pokemon

users_pokemon_df <- users_df_teste %>%
  mutate(pokemon = sample(pokemon_df$pokemon, size = n(), replace = TRUE)) %>%
  inner_join(pokemon_df, by = "pokemon")


# Authenticate with Google Drive
drive_auth()

# Find the ID of the "greenpeace" folder in your Google Drive
greenpeace_folder_id <- drive_find(n_max = 1, pattern = "greenpeace", type = "folder")$id

# Get distinct values from element and gender columns
unique_element <- unique(users_pokemon_df$element)
unique_gender <- unique(users_pokemon_df$gender)

# Upload a local file to the "greenpeace" folder in Google Drive
for (element in unique_element) {
  element_folder_name <- paste0(element)
  element_folder <- drive_mkdir(element_folder_name, path = greenpeace_folder_id)
  
  for (gender in unique_gender) {
    # Subset the data to only include rows with the current element and gender
    subset_data <- users_pokemon_df %>%
      filter(element == !!element, gender == !!gender) %>%
      select(1, 14, 15, 17)
    
    # Write the CSV file to a temporary directory
    file_name <- paste0(gender, "_users_pokemon.csv")
    tmp_file_path <- file.path(tempdir(), file_name)
    write_csv(subset_data, tmp_file_path)
    
    # Upload the CSV file to the corresponding folder in Google Drive
    drive_upload(tmp_file_path, type = "text/csv", path = element_folder$id, name = file_name)
    
    # Remove the temporary file
    file.remove(tmp_file_path)
  }
}

# Autenticar com a conta do Google
gs4_auth()

# Nome do arquivo
sheet_name <- "Quantidade de pokemons iniciais por região"

# Criar planilha e adicionar cabeçalho
spreadsheet <- gs4_create(sheet_name, sheets = data.frame(Região = character(), UF = character(), Elemento = character(), `Número de Pessoas` = integer()))

# Inicializar variável data
data <- data.frame(Região = character(), UF = character(), Elemento = character(), `Número de Pessoas` = integer())

# Cria uma tabela com as informações de UF e região
uf_region_df <- data.frame(UF = c("AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", "MA", "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR", "RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO"),
                           Regiao = c("Norte", "Nordeste", "Norte", "Norte", "Nordeste", "Nordeste", "Centro-Oeste", "Sudeste", "Centro-Oeste", "Nordeste", "Sudeste", "Centro-Oeste", "Centro-Oeste", "Norte", "Nordeste", "Nordeste", "Nordeste", "Sul", "Sudeste", "Nordeste", "Norte", "Norte", "Sul", "Sul", "Nordeste", "Sudeste", "Norte"))

# Adiciona a coluna de região na tabela original
users_pokemon_df <- users_pokemon_df %>% left_join(uf_region_df, by = "UF")

# Escrever dados no arquivo
sheet_append(spreadsheet, "Sheet1", data = subset_data)