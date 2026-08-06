Esse modelo de procedure foi elaborado para otimizar os processos de ETL/ELT e garantir a qualidade e disponibilidade de dados, abordando as seguintes finalidades primordiais:

- Redução do tempo de processamento: através da utilização de comandos utilizados como ```CREATE TABLE... LIKE ... AS SELECT``` para criação de tabelas temporárias e o comando ```MERGE``` para a sincronização atômica de dados, buscamos otimizar a performance e a eficiência das cargas, minimizando o consumo de recursos e acelerando a entrega dos dados.

- Garantia da disponibilidade dos dados: a metodologia adota abordagens que evitam a indisponibilidade de dados em tabelas de produção, especialmente aquelas que servem como fonte crítica para dashboards e relatórios. A operação ```MERGE```, por exemplo, permite uma atualização atômica, substituindo a tabela de forma eficiente sem exposições de estados inconsistentes.

- Preservação da integridade dos metadados: é crucial que os emtadados, incluindo descrições de colunas, particionamento e rótulos (labels), não sejam perdidos ou se tornem desatualizados. Essa estrutura garante a propagação e manutenção dos metadados durante todo o processo de atualização, assegurando que as informações sobre os dados permaneçam consistentes e acessíveis.

