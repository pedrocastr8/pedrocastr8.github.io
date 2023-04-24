-- Questão 3.1
GRANT SELECT ON TABLE press_data TO gp_user;
-- maneira como são feitas as permissões para AWS redshift

-- Questão 3.2

-- Altera as permissões para que o user herde todas as permissões anteriores
ALTER DEFAULT PRIVILEGES IN SCHEMA schema_press_data
GRANT SELECT ON TABLES TO gp_user;

-- forma de especificar o schema e a tabela para o gp_user
GRANT SELECT ON TABLE schema_press_data.press_data TO gp_user;

-- Questão 3.3

ALTER TABLE press_data OWNER TO gp_new_user;
-- Muda o proprietário da tabela. Retirando as permissões anteriores do antigo user