#!/bin/bash

# Limpa a pasta de saída anterior
rm -rf ./v4_01_00

# Executa o xgen para gerar todos os arquivos .go
xgen -i . -l Go -p v4_01_00 -o ./v4_01_00

echo "Arquivos gerados em ./v4_01_00"

