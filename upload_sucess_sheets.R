# Nome do arquivo
sheet_name <- "Minha planilha"

# Criar planilha e adicionar cabeçalho
spreadsheet <- gs4_create(sheet_name, sheets = data.frame(A = character(), B = character()))

# Escrever dados no arquivo
data <- data.frame(A = c("Valor 1", "Valor 2", "Valor 3"), B = c(10, 20, 30))
sheet_write(spreadsheet, "Sheet1", data = data)

# Encontrar o ID da pasta "greenpeace" no Google Drive
greenpeace_folder_id <- drive_find(n_max = 1, pattern = "greenpeace", type = "folder")$id

# Salvar a planilha em um arquivo xlsx
file_name <- paste0(sheet_name, ".xlsx")
write_xlsx(data, file_name)

# Enviar a planilha para a pasta "greenpeace" no Google Drive
file_path <- drive_upload(file_name, name = file_name, type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", path = greenpeace_folder_id)$path

# Abrir a planilha no navegador
gs4_browse(spreadsheet)
