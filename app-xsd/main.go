package main

import (
	"encoding/xml"
	"fmt"
	"os"
	"time"

	// IMPORTA AS STRUCTS GERADAS PELO XGEN DA TAG v2.01! 🎯
	tiss "github.com/renatofagalde/app-tiss-schemas/pkg/v4_01_00/schema_v4_01_00"
)

func main() {
	fmt.Printf("🚀 Gerador de XML TISS - Usando STRUCTS REAIS do xgen v2.01!\n")
	fmt.Printf("================================================================\n")

	// USA AS STRUCTS REAIS do xgen para criar a mensagem
	mensagem := createRecursoGlosaMessage()

	// Gera o XML
	xmlData, err := xml.MarshalIndent(mensagem, "", "  ")
	if err != nil {
		fmt.Printf("❌ Erro ao gerar XML: %v\n", err)
		return
	}

	fmt.Printf("✅ XML gerado com sucesso!\n\n")
	fmt.Printf("📄 Conteúdo do XML TISS v4.01.00:\n")
	fmt.Printf("==================================\n")
	fmt.Printf("%s\n", string(xmlData))

	// Salva em arquivo
	filename := fmt.Sprintf("recurso_glosa_%s.xml", time.Now().Format("20060102_150405"))
	err = os.WriteFile(filename, xmlData, 0644)
	if err != nil {
		fmt.Printf("❌ Erro ao salvar arquivo: %v\n", err)
		return
	}

	fmt.Printf("\n💾 Arquivo salvo como: %s\n", filename)
}

func createRecursoGlosaMessage() *tiss.MensagemTISS {
	// Gera timestamp para transação
	agora := time.Now()
	dataRegistro := agora.Format("2006-01-02")

	return &tiss.MensagemTISS{
		XMLName: xml.Name{Local: "mensagemTISS"},
		Cabecalho: &tiss.CtcabecalhoTransacao{
			IdentificacaoTransacao: &tiss.CtidentificacaoTransacao{
				TipoTransacao:       "RECURSO_GLOSA",
				SequencialTransacao: "000001",
			},
			OrigemDestino: &tiss.CtorigemDestino{
				RegistroANS:       "326305",
				TipoIntermediario: "1",
				NomeOperadora:     "OPERADORA TESTE LTDA",
			},
		},
		PrestadorParaOperadora: &tiss.CtprestadorOperadora{
			RecursoGlosa: &tiss.CtguiaRecursoLote{
				// USANDO A STRUCT REAL CtmrecursoGlosa! 🎯
				GuiaRecursoGlosa: &tiss.CtmrecursoGlosa{
					RegistroANS:                 "326305",
					NumeroGuiaRecGlosaPrestador: "20250616001",
					NomeOperadora:               "OPERADORA TESTE LTDA",
					ObjetoRecurso:               "PROTOCOLO",
					NumeroGuiaRecGlosaOperadora: "OPR20250616001",
					DadosContratado: &tiss.CtcontratadoDados{
						CodigoPrestadorNaOperadora: "PREST001",
						NomeContratado:             "CLINICA TESTE LTDA",
						CNPJ:                       "12.345.678/0001-90",
					},
					NumeroLote:      "LOTE2025061601",
					NumeroProtocolo: 249932,
					OpcaoRecurso: &tiss.OpcaoRecurso{
						RecursoProtocolo: &tiss.RecursoProtocolo{
							CodigoGlosaProtocolo:           "001",
							JustificativaProtocolo:         "Recurso contra glosa indevida do protocolo",
							RecursoAcatado:                 "N",
							JustificativaOPSnaoAcatadoProt: "",
						},
					},
					ValorTotalRecursado: 1500.00,
					DataRecurso:         dataRegistro,
				},
				// GuiaRecursoGlosaOdonto fica nil (não é odonto)
			},
		},
	}
}
