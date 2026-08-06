CREATE OR REPLACE PROCEDURE `abc-area-provider-ambiente.DS_DATASET.SP_TABELA_IMPLEMENTACAO_INICIAL`()
BEGIN

/*****************************************************************************************************
PROCEDURE: SP_TABELA_IMPLEMENTACAO_INICIAL
OBJETIVO: Procedure para implementação da tabela TABELA_IMPLEMENTACAO_INICIAL.
******************************************************************************************************/

  -- Nomes completos das tabelas temporária e de destino.
  DECLARE temp_table_full_path STRING DEFAULT '`abc-area-provider-ambiente.DS_DATASET.TEMP_TABELA_PARA_INICIALIZACAO`';
  DECLARE target_table_full_path STRING DEFAULT '`abc-area-provider-ambiente.DS_DATASET.TR_TABELA_INICIAL`';
   
  -- Variáveis para extrair partes do caminho das tabelas
  DECLARE project_id_target STRING;
  DECLARE dataset_id_target STRING;
  DECLARE table_id_target STRING;

  DECLARE project_id_temp STRING;
  DECLARE dataset_id_temp STRING;
  DECLARE table_id_temp STRING;

  -- Variáveis para armazenar as strings de DDL dinâmicas
  DECLARE dynamic_schema_definition STRING;
  DECLARE insert_column_names STRING;
  DECLARE values_column_names STRING;

  -- 0. Definição Explícita do Schema da Tabela de Destino com Descrições das Colunas.
  SET dynamic_schema_definition = """
    COLUNA_1 STRING NOT NULL OPTIONS(description="Identificador único para o registro, ex: id do cliente, código do produto."),
    COLUNA_2 STRING OPTIONS(description="Nome ou descrição textual associada ao registro."),
    COLUNA_3 NUMERIC(38,9) OPTIONS(description="Um valor numérico de precisão para transações ou medidas."),
    DT_EXTRACAO_GCP TIMESTAMP OPTIONS(description="Timestamp da extração/processamento no Google Cloud Platform.")
  """;

  -- 0.1. Definição dos nomes das colunas para INSERT e VALUES, com base no schema acima.
  SET insert_column_names = 'COLUNA_1, COLUNA_2, COLUNA_3, DT_EXTRACAO_GCP';
  SET values_column_names = 'S.COLUNA_1, S.COLUNA_2, S.COLUNA_3, S.DT_EXTRACAO_GCP';

  -- 1. Cria uma tabela temporária para gerar e armazenar os novos dados.
  EXECUTE IMMEDIATE CONCAT("""
    CREATE OR REPLACE TABLE """, temp_table_full_path, """ (
      """, dynamic_schema_definition, """
    ) AS (
        WITH CODIGO AS (
            SELECT
                COLUNA_1,
                COLUNA_2,
                COLUNA_3,
                DT_EXTRACAO_GCP
            FROM `abc-area-provider-ambiente.DS_DATASET.TABELA`
        )
        SELECT
            COLUNA_1,
            COLUNA_2,
            COLUNA_3,
            CURRENT_TIMESTAMP() AS DT_EXTRACAO_GCP
        FROM CODIGO
  """);

  -- Extrai as partes do caminho da tabela de destino
  SET project_id_target = REGEXP_EXTRACT(target_table_full_path, r'`([^.]+)\.[^.]+\.[^`]+`');
  SET dataset_id_target = REGEXP_EXTRACT(target_table_full_path, r'`[^.]+\.([^.]+)\.[^`]+`');
  SET table_id_target = REGEXP_EXTRACT(target_table_full_path, r'`[^.]+\.[^.]+\.([^`]+)`');

  -- Extrai as partes do caminho da tabela TEMPORÁRIA
  SET project_id_temp = REGEXP_EXTRACT(temp_table_full_path, r'`([^.]+)\.[^.]+\.[^`]+`');
  SET dataset_id_temp = REGEXP_EXTRACT(temp_table_full_path, r'`[^.]+\.([^.]+)\.[^`]+`');
  SET table_id_temp = REGEXP_EXTRACT(temp_table_full_path, r'`[^.]+\.[^.]+\.([^`]+)`');

  -- 3. Constrói dinamicamente o DDL para criar a tabela de destino se ela não existir, usando o schema definido.
  EXECUTE IMMEDIATE CONCAT("""
    CREATE TABLE IF NOT EXISTS """, target_table_full_path, """ (
      """, dynamic_schema_definition, """
    )
    PARTITION BY DT_EXTRACAO_GCP
    OPTIONS(
      description="Tabela de exemplo - implementação inicial para manter criar metadados."
      , labels=[('ambiente', 'dev'), ('projeto', 'nome_projeto')]
    );
  """);
   
  -- 4. Usa MERGE para substituir os dados na tabela principal, com colunas dinâmicas.
  EXECUTE IMMEDIATE FORMAT("""
    MERGE INTO %s AS T
    USING %s AS S
    ON FALSE -- Esta condição garante que nenhuma linha da T seja "matched" com S
    WHEN NOT MATCHED BY SOURCE THEN
      DELETE -- Exclui todas as linhas de T que não foram "matched" por S (ou seja, todas as linhas de T quando ON FALSE)
    WHEN NOT MATCHED THEN
      INSERT (%s)
      VALUES (%s); -- Insere todas as linhas de S em T
  """, target_table_full_path, temp_table_full_path, insert_column_names, values_column_names);
   
  -- 5. Exclui a tabela temporária para limpar os recursos após a conclusão.
  EXECUTE IMMEDIATE FORMAT("DROP TABLE %s", temp_table_full_path);

END;