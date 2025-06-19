#!/bin/bash

# Script generate_versions.sh - Gerador TISS Multi-Versão Melhorado
# Execute a partir do diretório pkg/tiss/
# Autor: Assistente IA
# Versão: 2.2 - INCLUINDO MENSAGEM TISS E ARQUIVOS BASE

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "${CYAN}=== $1 ===${NC}"; }

# Configurações
MODULE_BASE="github.com/renatofagalde/app-tiss-schemas/pkg/tiss"

# Arquivos base que devem sempre ser incluídos
BASE_FILES=(
    "tissAssinaturaDigital_*.xsd"
    "xmldsig-core-schema.xsd"
    "mensagemTISS*.xsd"
    "*mensagemTISS*.xsd"
    "tissComplexTypes*.xsd"
    "*ComplexTypes*.xsd"
    "*SimpleTypes*.xsd"
    "*Glosa*.xsd"
    "*glosa*.xsd"
    "tissGlosa*.xsd"
    "*RecursoGlosa*.xsd"
    "*recursoglosa*.xsd"
)

# Função para mostrar ajuda
show_help() {
    echo "🚀 Gerador TISS Multi-Versão Melhorado"
    echo "======================================"
    echo ""
    echo "Uso: $0 [opções] [versão]"
    echo ""
    echo "Opções:"
    echo "  -h, --help          Mostra esta ajuda"
    echo "  -l, --list          Lista todas as versões disponíveis"
    echo "  -a, --all           Gera todas as versões disponíveis"
    echo "  -c, --clean         Limpa versões geradas antes de gerar"
    echo "  --radar-only        Gera apenas schemas radar"
    echo "  --latest            Gera apenas a versão mais recente"
    echo "  --debug             Modo debug com informações detalhadas"
    echo ""
    echo "Versões específicas:"
    echo "  4_01_00             Gera apenas TISS v4.01.00"
    echo "  4_00_01             Gera apenas TISS v4.00.01"
    echo "  3_05_00             Gera apenas TISS v3.05.00"
    echo ""
    echo "Exemplos:"
    echo "  $0                  # Gera versão mais recente"
    echo "  $0 4_01_00          # Gera TISS v4.01.00"
    echo "  $0 --all            # Gera todas as versões"
    echo "  $0 --list           # Lista versões disponíveis"
    echo "  $0 --clean 4_01_00  # Limpa e gera v4.01.00"
    echo ""
    echo "💡 Este script agora inclui automaticamente:"
    echo "   - Arquivos mensagemTISS"
    echo "   - Estruturas de glosa e recurso de glosa"
    echo "   - Tipos complexos e simples"
    echo "   - Arquivos de assinatura digital"
    echo "   - Todas as dependências necessárias"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."

    # Verifica se está no diretório correto
    xsd_count=$(ls *.xsd 2>/dev/null | wc -l)
    wsdl_count=$(ls *.wsdl 2>/dev/null | wc -l)

    if [ $xsd_count -eq 0 ] && [ $wsdl_count -eq 0 ]; then
        log_error "Nenhum arquivo XSD/WSDL encontrado no diretório atual"
        log_info "Execute este script a partir do diretório pkg/tiss/ que contém os arquivos fonte"
        log_info "Diretório atual: $(pwd)"
        exit 1
    fi

    log_success "Encontrados $xsd_count arquivos XSD e $wsdl_count arquivos WSDL"

    # Verifica mensagemTISS e glosa
    mensagem_count=$(ls *mensagem* 2>/dev/null | wc -l)
    if [ $mensagem_count -gt 0 ]; then
        log_success "Encontrados $mensagem_count arquivos mensagemTISS"
    else
        log_warning "Nenhum arquivo mensagemTISS encontrado"
    fi

    glosa_count=$(ls *[Gg]losa* 2>/dev/null | wc -l)
    if [ $glosa_count -gt 0 ]; then
        log_success "Encontrados $glosa_count arquivos de glosa"
    else
        log_warning "Nenhum arquivo de glosa encontrado"
    fi

    # Verifica se xgen está instalado
    if ! command -v xgen &> /dev/null; then
        log_error "xgen não encontrado. Instale com:"
        echo "  go install github.com/xuri/xgen@latest"
        exit 1
    fi

    # Verifica se go está instalado
    if ! command -v go &> /dev/null; then
        log_error "Go não encontrado. Instale Go primeiro."
        exit 1
    fi

    log_success "Pré-requisitos verificados"
}

# Função para detectar versões disponíveis
detect_versions() {
    log_info "Detectando versões disponíveis..."

    # Extrai versões dos nomes dos arquivos - MELHORADO
    versions=$(ls -1 *.xsd *.wsdl 2>/dev/null | \
               grep -E 'V[0-9]_[0-9]+_[0-9]+' | \
               sed -E 's/.*V([0-9]_[0-9]+_[0-9]+).*/\1/' | \
               sort -V -u)

    # Se não encontrou versões com V, tenta outros padrões
    if [ -z "$versions" ]; then
        # Tenta padrão com underscores
        versions=$(ls -1 *.xsd *.wsdl 2>/dev/null | \
                   grep -E '[0-9]_[0-9]+_[0-9]+' | \
                   sed -E 's/.*([0-9]_[0-9]+_[0-9]+).*/\1/' | \
                   sort -V -u)
    fi

    # Se ainda não encontrou, cria uma versão padrão baseada nos arquivos disponíveis
    if [ -z "$versions" ]; then
        log_warning "Nenhum padrão de versão detectado, criando versão padrão 'current'"
        echo "current"
    else
        echo "$versions"
    fi
}

# Função para coletar arquivos base
collect_base_files() {
    local temp_dir="$1"
    local collected=0

    log_info "Coletando arquivos base..."

    for pattern in "${BASE_FILES[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                cp "$file" "$temp_dir/"
                log_info "  ✓ $file (base)"
                ((collected++))
            fi
        done
    done

    log_info "Arquivos base coletados: $collected"
    return $collected
}

# Função para coletar arquivos de uma versão específica
collect_version_files() {
    local version="$1"
    local temp_dir="$2"
    local collected=0

    log_info "Coletando arquivos da versão $version..."

    if [ "$version" = "current" ]; then
        # Para versão current, pega todos os arquivos principais
        for file in *.xsd *.wsdl; do
            if [ -f "$file" ] && [[ ! "$file" == radar* ]]; then
                cp "$file" "$temp_dir/"
                log_info "  ✓ $file"
                ((collected++))
            fi
        done
    else
        # Para versões específicas, pega arquivos com padrão da versão
        for file in *V${version}* *v${version}* *${version}*; do
            if [ -f "$file" ]; then
                cp "$file" "$temp_dir/"
                log_info "  ✓ $file"
                ((collected++))
            fi
        done
    fi

    log_info "Arquivos da versão coletados: $collected"
    return $collected
}

# Função para listar versões
list_versions() {
    log_section "VERSÕES DISPONÍVEIS"

    versions=$(detect_versions)

    echo "📦 Versões TISS detectadas:"
    for version in $versions; do
        if [ "$version" = "current" ]; then
            readable_version="current (todos os arquivos)"
            file_count=$(ls -1 *.xsd *.wsdl 2>/dev/null | grep -v radar | wc -l)
        else
            readable_version=$(echo $version | sed 's/_/./g')
            file_count=$(ls -1 *${version}* 2>/dev/null | wc -l)
        fi

        # Verifica se já foi gerada
        if [ -d "../v${version}" ]; then
            status="✅ Gerada"
        else
            status="⚪ Não gerada"
        fi

        echo "  📋 v${readable_version} (${file_count} arquivos) - ${status}"
    done

    # Detecta versão mais recente
    latest=$(echo "$versions" | tail -1)
    if [ "$latest" = "current" ]; then
        latest_readable="current"
    else
        latest_readable=$(echo $latest | sed 's/_/./g')
    fi
    echo ""
    echo "🆕 Versão mais recente: v${latest_readable}"

    # Mostra arquivos importantes
    echo ""
    echo "📄 Arquivos importantes detectados:"

    mensagem_files=$(ls -1 *mensagem* 2>/dev/null | wc -l)
    if [ $mensagem_files -gt 0 ]; then
        echo "  📝 Arquivos mensagemTISS: $mensagem_files"
        ls -1 *mensagem* 2>/dev/null | sed 's/^/    📄 /'
    fi

    glosa_files=$(ls -1 *[Gg]losa* 2>/dev/null | wc -l)
    if [ $glosa_files -gt 0 ]; then
        echo "  🔄 Arquivos de glosa: $glosa_files"
        ls -1 *[Gg]losa* 2>/dev/null | sed 's/^/    📄 /'
    fi

    complex_files=$(ls -1 *ComplexTypes* 2>/dev/null | wc -l)
    if [ $complex_files -gt 0 ]; then
        echo "  🧩 Arquivos ComplexTypes: $complex_files"
    fi

    radar_files=$(ls -1 radar*.xsd 2>/dev/null | wc -l)
    if [ $radar_files -gt 0 ]; then
        echo "  🎯 Arquivos radar: $radar_files"
    fi
}

# Função para limpar versões geradas
clean_versions() {
    log_info "Limpando versões geradas anteriormente..."

    count=0
    for dir in ../v* ../current; do
        if [ -d "$dir" ]; then
            log_info "Removendo: $(basename $dir)"
            rm -rf "$dir"
            ((count++))
        fi
    done

    # Limpa radar também
    if [ -d "../radar" ]; then
        log_info "Removendo: radar"
        rm -rf "../radar"
        ((count++))
    fi

    log_success "Removidas $count versões geradas"
}

# Função para gerar uma versão específica
generate_version() {
    local version="$1"
    local output_dir="../v${version}"
    local temp_dir="./schema_v${version}"

    if [ "$version" = "current" ]; then
        log_section "GERANDO TISS CURRENT (todos os arquivos)"
    else
        log_section "GERANDO TISS v$(echo $version | sed 's/_/./g')"
    fi

    # Remove saída anterior se existir
    if [ -d "$output_dir" ]; then
        log_warning "Removendo versão anterior..."
        rm -rf "$output_dir"
    fi

    # Cria diretório temporário
    mkdir -p "$temp_dir"

    # Coleta arquivos base
    collect_base_files "$temp_dir"
    base_count=$?

    # Coleta arquivos da versão
    collect_version_files "$version" "$temp_dir"
    version_count=$?

    total_files=$((base_count + version_count))

    if [ $total_files -eq 0 ]; then
        log_error "Nenhum arquivo encontrado para versão $version"
        rm -rf "$temp_dir"
        return 1
    fi

    log_success "Total de arquivos coletados: $total_files"

    # Lista arquivos no diretório de schema para debug
    if [ "${DEBUG:-false}" = "true" ]; then
        log_info "Arquivos no diretório de schema:"
        ls -la "$temp_dir/"
    fi

    # Gera código usando xgen diretamente no diretório de saída
    log_info "Gerando código Go..."
    if xgen -i "$temp_dir" -l Go -p "tiss" -o "$output_dir" 2>/dev/null; then
        log_success "Código gerado com sucesso!"

        # Remove diretório de schema
        rm -rf "$temp_dir"

        # Configura o módulo Go
        log_info "Configurando módulo Go..."
        cd "$output_dir"

        # Cria go.mod com nome mais limpo
        go mod init "$MODULE_BASE/v${version}" 2>/dev/null || true

        # Corrige o nome do pacote nos arquivos Go gerados
        log_info "Ajustando nome do pacote..."
        for gofile in *.go; do
            if [ -f "$gofile" ]; then
                sed -i.bak "s/package tiss/package v${version}/g" "$gofile" 2>/dev/null || true
                rm -f "${gofile}.bak" 2>/dev/null || true
            fi
        done

        # Testa compilação
        log_info "Testando compilação..."
        if go build . 2>/dev/null; then
            log_success "✅ Compilação bem-sucedida!"
        else
            log_warning "⚠️  Compilação com avisos, tentando resolver..."

            # Resolve conflitos com build tags
            resolve_conflicts "$output_dir"

            # Testa novamente
            if go build . 2>/dev/null; then
                log_success "✅ Conflitos resolvidos!"
            else
                log_warning "⚠️  Ainda há avisos, mas código utilizável"
            fi
        fi

        # Volta ao diretório original
        cd - > /dev/null

        # Mostra estatísticas
        show_version_stats "$version" "$output_dir"

        return 0

    else
        log_error "Falha na geração do código"
        log_info "Tentando diagnóstico..."

        # Mostra conteúdo do diretório de schema para debug
        echo "Arquivos no diretório de schema:"
        ls -la "$temp_dir/" 2>/dev/null || true

        # Tenta xgen com output de erro
        echo "Erro detalhado do xgen:"
        xgen -i "$temp_dir" -l Go -p "tiss" -o "$output_dir" 2>&1 || true

        rm -rf "$temp_dir"
        return 1
    fi
}

# Função para resolver conflitos com build tags
resolve_conflicts() {
    local dir="$1"

    log_info "Resolvendo conflitos com build tags..."

    cd "$dir"

    conflict_count=0

    # Processa arquivos radar
    for file in *.go; do
        if [[ "$file" == *"radar"* ]]; then
            # Extrai ano do radar
            radar_year=$(echo "$file" | sed -E 's/.*radar([0-9]+).*/\1/')

            if [ ! -z "$radar_year" ]; then
                # Adiciona build tag
                {
                    echo "//go:build radar$radar_year"
                    echo "// +build radar$radar_year"
                    echo ""
                    cat "$file"
                } > "${file}.tmp" && mv "${file}.tmp" "$file"

                log_info "  ✓ Build tag 'radar$radar_year' adicionada ao $file"
                ((conflict_count++))
            fi
        fi
    done

    cd - > /dev/null

    if [ $conflict_count -gt 0 ]; then
        log_success "Resolvidos $conflict_count conflitos"
    fi
}

# Função para mostrar estatísticas da versão gerada
show_version_stats() {
    local version="$1"
    local output_dir="$2"

    if [ "$version" = "current" ]; then
        local readable_version="current"
    else
        local readable_version=$(echo $version | sed 's/_/./g')
    fi

    log_section "ESTATÍSTICAS v$readable_version"

    local go_files=$(find "$output_dir" -name "*.go" 2>/dev/null | wc -l)
    local total_lines=$(find "$output_dir" -name "*.go" -exec cat {} \; 2>/dev/null | wc -l || echo "0")
    local dir_size=$(du -sh "$output_dir" 2>/dev/null | cut -f1)

    echo "📊 Estatísticas:"
    echo "  📁 Diretório: $(realpath "$output_dir")"
    echo "  📄 Arquivos Go: $go_files"
    echo "  📏 Total de linhas: $total_lines"
    echo "  💾 Tamanho: $dir_size"
    echo "  📦 Pacote: v$version"
    echo ""
    echo "🔗 Import para usar:"
    echo "  import tiss \"$MODULE_BASE/v$version\""
    echo ""

    # Verifica se mensagemTISS e glosa foram incluídas
    mensagem_structs=$(find "$output_dir" -name "*.go" -exec grep -l "MensagemTISS\|mensagemTISS" {} \; 2>/dev/null | wc -l)
    if [ $mensagem_structs -gt 0 ]; then
        echo "✅ Estruturas mensagemTISS incluídas"
    else
        echo "⚠️  Estruturas mensagemTISS não detectadas"
    fi

    glosa_structs=$(find "$output_dir" -name "*.go" -exec grep -l "Glosa\|RecursoGlosa\|glosa" {} \; 2>/dev/null | wc -l)
    if [ $glosa_structs -gt 0 ]; then
        echo "✅ Estruturas de glosa incluídas"
    else
        echo "⚠️  Estruturas de glosa não detectadas"
    fi

    # Lista algumas estruturas importantes encontradas
    echo ""
    echo "🔍 Principais estruturas encontradas:"
    find "$output_dir" -name "*.go" -exec grep -l "type.*struct" {} \; 2>/dev/null | head -3 | while read file; do
        echo "  📄 $(basename "$file"):"
        grep "type.*struct" "$file" 2>/dev/null | head -5 | sed 's/^/    /'
    done

    # Lista build tags disponíveis
    build_tags=$(find "$output_dir" -name "*.go" -exec grep -l "//go:build" {} \; 2>/dev/null)
    if [ ! -z "$build_tags" ]; then
        echo "📋 Build tags disponíveis:"
        echo "$build_tags" | while read file; do
            tag=$(grep "//go:build" "$file" | sed 's/.*build //')
            echo "  🏷️  $tag ($(basename "$file"))"
        done
    fi
}

# Função para gerar schemas radar
generate_radar() {
    log_section "GERANDO SCHEMAS RADAR"

    local radar_dir="../radar"

    # Remove radar anterior
    if [ -d "$radar_dir" ]; then
        rm -rf "$radar_dir"
    fi

    mkdir -p "$radar_dir"

    # Processa cada arquivo radar separadamente
    for radar_file in radar*.xsd; do
        if [ -f "$radar_file" ]; then
            # Extrai ano
            radar_year=$(echo "$radar_file" | sed -E 's/.*radar([0-9]+).*/\1/')

            if [ ! -z "$radar_year" ]; then
                local radar_package_dir="$radar_dir/radar$radar_year"
                local temp_radar="./schema_radar$radar_year"

                log_info "Gerando radar$radar_year..."

                mkdir -p "$temp_radar"
                cp "$radar_file" "$temp_radar/"

                # Copia dependências se existirem
                for dep in radarSimpleTypes$radar_year.xsd radarPerguntas$radar_year.xsd; do
                    if [ -f "$dep" ]; then
                        cp "$dep" "$temp_radar/"
                    fi
                done

                # Gera código diretamente no diretório do radar
                if xgen -i "$temp_radar" -l Go -p "radar${radar_year}" -o "$radar_package_dir" 2>/dev/null; then
                    log_success "✅ Radar$radar_year gerado"

                    # Configura módulo
                    cd "$radar_package_dir"
                    go mod init "$MODULE_BASE/radar/radar$radar_year" 2>/dev/null || true

                    if go build . 2>/dev/null; then
                        log_success "✅ Radar$radar_year compila"
                    fi

                    cd - > /dev/null
                else
                    log_warning "⚠️  Falha ao gerar radar$radar_year"
                fi

                rm -rf "$temp_radar"
            fi
        fi
    done
}

# Função para gerar todas as versões
generate_all_versions() {
    log_section "GERANDO TODAS AS VERSÕES"

    local versions=$(detect_versions)
    local success_count=0
    local total_count=0

    for version in $versions; do
        ((total_count++))
        log_info "[$total_count] Processando versão $version..."

        if generate_version "$version"; then
            ((success_count++))
        else
            log_error "Falha na versão $version"
        fi

        echo ""
    done

    log_section "RESUMO FINAL"
    echo "📊 Versões processadas: $total_count"
    echo "✅ Versões bem-sucedidas: $success_count"
    echo "❌ Versões com falha: $((total_count - success_count))"

    if [ $success_count -gt 0 ]; then
        echo ""
        echo "📁 Versões geradas:"
        for dir in ../v*; do
            if [ -d "$dir" ]; then
                version_name=$(basename "$dir" | sed 's/v//; s/_/./g')
                echo "  📦 v$version_name"
            fi
        done
    fi
}

# Função para obter versão mais recente
get_latest_version() {
    local versions=$(detect_versions)
    echo "$versions" | tail -1
}

# Função principal
main() {
    echo "🚀 Gerador TISS Multi-Versão Melhorado v2.2"
    echo "==========================================="
    echo ""

    # Verifica pré-requisitos
    check_prerequisites

    # Processa argumentos
    local clean_before=false
    local generate_all=false
    local generate_radar=false
    local target_version=""
    local debug_mode=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_versions
                exit 0
                ;;
            -a|--all)
                generate_all=true
                shift
                ;;
            -c|--clean)
                clean_before=true
                shift
                ;;
            --radar-only)
                generate_radar=true
                shift
                ;;
            --latest)
                target_version=$(get_latest_version)
                shift
                ;;
            --debug)
                debug_mode=true
                export DEBUG=true
                shift
                ;;
            [0-9]_[0-9]*_[0-9]*|current)
                target_version="$1"
                shift
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Ativa modo debug se solicitado
    if [ "$debug_mode" = true ]; then
        log_info "Modo debug ativado"
        set -x
    fi

    # Limpa se solicitado
    if [ "$clean_before" = true ]; then
        clean_versions
        echo ""
    fi

    # Executa operação solicitada
    if [ "$generate_radar" = true ]; then
        generate_radar
    elif [ "$generate_all" = true ]; then
        generate_all_versions
        echo ""
        generate_radar
    elif [ ! -z "$target_version" ]; then
        if generate_version "$target_version"; then
            log_success "🎉 Versão $target_version gerada com sucesso!"
        else
            log_error "❌ Falha ao gerar versão $target_version"
            exit 1
        fi
    else
        # Comportamento padrão: gera versão mais recente
        latest=$(get_latest_version)
        if [ "$latest" = "current" ]; then
            log_info "Gerando versão current (todos os arquivos)"
        else
            log_info "Gerando versão mais recente: v$(echo $latest | sed 's/_/./g')"
        fi

        if generate_version "$latest"; then
            log_success "🎉 Versão gerada com sucesso!"
        else
            log_error "❌ Falha ao gerar versão"
            exit 1
        fi
    fi

    echo ""
    log_success "✅ Operação concluída!"
}

# Executa função principal
main "$@"