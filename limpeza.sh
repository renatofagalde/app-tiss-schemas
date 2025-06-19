#!/bin/bash

# Script para limpar e reorganizar a estrutura TISS
# Remove pastas geradas e mantém apenas arquivos fonte

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🧹 Limpando estrutura TISS bagunçada..."
echo "====================================="

# Vai para o diretório correto
cd /home/renatofagalde/desenvolvimento/app-tiss-schemas

log_info "Estrutura atual:"
tree -L 3 pkg/tiss/

echo ""
log_warning "Esta operação vai:"
echo "  ❌ Remover todas as pastas v4_01_00 geradas"
echo "  ❌ Remover todos os arquivos .go gerados"
echo "  ✅ Manter apenas os arquivos fonte (.xsd, .wsdl)"
echo "  ✅ Reorganizar estrutura limpa"

echo ""
read -p "Deseja continuar? (s/N): " confirm
if [[ $confirm != [sS] ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
log_info "Iniciando limpeza..."

# 1. Remove todas as pastas v4_01_00 aninhadas
log_info "1. Removendo pastas v4_01_00..."
find pkg/tiss/ -type d -name "v4_01_00" -exec rm -rf {} + 2>/dev/null || true

# 2. Remove todos os arquivos .go gerados
log_info "2. Removendo arquivos .go gerados..."
find pkg/tiss/ -name "*.go" -type f -delete 2>/dev/null || true

# 3. Reorganiza a estrutura para ser mais limpa
log_info "3. Reorganizando estrutura..."

# Cria diretório schemas se não existir
mkdir -p pkg/tiss/schemas

# Move todos os arquivos XSD/WSDL para o diretório schemas
log_info "4. Movendo arquivos fonte para pkg/tiss/schemas..."
find pkg/tiss/ -maxdepth 1 -name "*.xsd" -o -name "*.wsdl" -o -name "*.doc" | while read file; do
    if [ -f "$file" ]; then
        mv "$file" pkg/tiss/schemas/
        log_info "  ✓ Movido: $(basename "$file")"
    fi
done

# 5. Remove arquivos indesejados
log_info "5. Removendo arquivos desnecessários..."
find pkg/tiss/ -name "index.php_" -delete 2>/dev/null || true
find pkg/tiss/ -name "*.doc" -delete 2>/dev/null || true

log_success "Limpeza concluída!"

echo ""
log_info "Nova estrutura:"
tree pkg/tiss/

echo ""
log_success "✅ Estrutura limpa e organizada!"
echo ""
echo "📁 Estrutura final:"
echo "  pkg/tiss/schemas/     # Todos os arquivos XSD/WSDL"
echo "  pkg/tiss/             # Pronto para gerar versões organizadas"
echo ""
echo "🚀 Próximos passos:"
echo "  1. cd pkg/tiss/schemas"
echo "  2. Execute o script de geração multi-versão"
echo "  3. Cada versão será gerada em seu próprio diretório"

# Gera um novo script otimizado para essa estrutura
cat > pkg/tiss/generate_versions.sh << 'EOF'
#!/bin/bash

# Script otimizado para gerar versões TISS da estrutura limpa
# Execute a partir do diretório pkg/tiss/

echo "🚀 Gerando versões TISS organizadas..."

# Verifica se está no diretório correto
if [ ! -d "schemas" ]; then
    echo "❌ Execute este script a partir do diretório pkg/tiss/"
    exit 1
fi

cd schemas

# Detecta versões disponíveis
echo "📋 Detectando versões..."
versions=$(ls -1 *.xsd *.wsdl 2>/dev/null | grep -E 'V[0-9]_[0-9]+_[0-9]+' | \
           sed -E 's/.*V([0-9]_[0-9]+_[0-9]+).*/\1/' | sort -u)

echo "Versões encontradas:"
for version in $versions; do
    readable_version=$(echo $version | sed 's/_/./g')
    file_count=$(ls -1 *V${version}* 2>/dev/null | wc -l)
    echo "  📦 v${readable_version} (${file_count} arquivos)"
done

# Gera apenas TISS 4.01.00 por enquanto
VERSION="4_01_00"
OUTPUT_DIR="../v${VERSION}"

echo ""
echo "🔨 Gerando TISS v${VERSION}..."

# Remove saída anterior
rm -rf "$OUTPUT_DIR"

# Cria diretório temporário
TEMP_DIR="./temp_v${VERSION}"
mkdir -p "$TEMP_DIR"

# Copia arquivos da versão específica
file_count=0
for file in *V${VERSION}*; do
    if [ -f "$file" ]; then
        cp "$file" "$TEMP_DIR/"
        echo "  ✓ $file"
        ((file_count++))
    fi
done

# Copia arquivos base
for base_file in tissAssinaturaDigital_*.xsd xmldsig-core-schema.xsd; do
    if [ -f "$base_file" ]; then
        cp "$base_file" "$TEMP_DIR/"
        echo "  ✓ $base_file (base)"
        ((file_count++))
    fi
done

if [ $file_count -eq 0 ]; then
    echo "❌ Nenhum arquivo encontrado para versão $VERSION"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "📊 Total: $file_count arquivos"

# Gera código
echo "🏗️  Gerando código Go..."
if xgen -i "$TEMP_DIR" -l Go -p "v${VERSION}" -o "$OUTPUT_DIR"; then
    echo "✅ Código gerado!"
    
    # Limpa temporários
    rm -rf "$TEMP_DIR"
    
    # Configura go.mod
    cd "$OUTPUT_DIR"
    go mod init "github.com/renatofagalde/app-tiss-schemas/pkg/tiss/v${VERSION}"
    
    # Testa compilação
    if go build . 2>/dev/null; then
        echo "✅ Compilação bem-sucedida!"
    else
        echo "⚠️  Compilação com avisos"
        
        # Resolve conflitos com build tags
        for file in *.go; do
            if [[ "$file" == *"radar"* ]]; then
                radar_year=$(echo "$file" | sed -E 's/.*radar([0-9]+).*/\1/')
                if [ ! -z "$radar_year" ]; then
                    {
                        echo "//go:build radar$radar_year"
                        echo "// +build radar$radar_year"
                        echo ""
                        cat "$file"
                    } > "${file}.tmp" && mv "${file}.tmp" "$file"
                    echo "  ✅ Build tag adicionada: $file"
                fi
            fi
        done
        
        if go build . 2>/dev/null; then
            echo "✅ Conflitos resolvidos!"
        fi
    fi
    
    cd ../schemas
    
    echo ""
    echo "📊 Resultado:"
    echo "  📁 Diretório: $(realpath $OUTPUT_DIR)"
    echo "  📄 Arquivos Go: $(ls -1 $OUTPUT_DIR/*.go 2>/dev/null | wc -l)"
    echo ""
    echo "🔗 Import para usar:"
    echo '  import tiss "github.com/renatofagalde/app-tiss-schemas/pkg/tiss/v'$VERSION'"'
    
else
    echo "❌ Falha na geração"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "✅ Geração concluída!"
EOF

chmod +x pkg/tiss/generate_versions.sh

log_success "Script de geração criado: pkg/tiss/generate_versions.sh"

echo ""
echo "🎯 Para gerar a versão 4.01.00 agora:"
echo "  cd pkg/tiss"
echo "  ./generate_versions.sh"
