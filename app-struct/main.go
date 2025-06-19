package main

import (
	"encoding/xml"
	"fmt"
	"os"
	"strings"
	"time"
)

// Importa as structs geradas pelo xgen
// Ajustar o caminho conforme a estrutura real do go.mod
// import tiss "github.com/renatofagalde/app-tiss-schemas/pkg/tiss/v4_01_00/schema_v4_01_00"

func main() {
	fmt.Println("🚀 Gerador de XML TISS - Recurso de Glosa")
	fmt.Println("=========================================")

	// Cria a estrutura da mensagem TISS baseada no XML fornecido
	mensagem := createRecursoGlosaMessage()

	// Gera o XML
	xmlData, err := xml.MarshalIndent(mensagem, "", "  ")
	if err != nil {
		fmt.Printf("❌ Erro ao gerar XML: %v\n", err)
		return
	}

	// Adiciona o header XML com encoding correto
	xmlHeader := `<?xml version='1.0' encoding='ISO-8859-1'?>` + "\n"
	fullXML := xmlHeader + string(xmlData)

	// Salva o arquivo
	timestamp := time.Now().Format("20060102_150405")
	filename := fmt.Sprintf("TISS4_lote_recurso_gerado_%s.xml", timestamp)

	err = os.WriteFile(filename, []byte(fullXML), 0644)
	if err != nil {
		fmt.Printf("❌ Erro ao salvar arquivo: %v\n", err)
		return
	}

	fmt.Printf("✅ Arquivo XML gerado com sucesso: %s\n", filename)
	fmt.Printf("📄 Tamanho: %d bytes\n", len(fullXML))

	// Exibe uma prévia do XML gerado
	fmt.Println("\n🔍 Prévia do XML gerado:")
	fmt.Println(strings.Repeat("=", 60))
	if len(fullXML) > 1500 {
		fmt.Printf("%s\n...\n%s\n", fullXML[:750], fullXML[len(fullXML)-750:])
	} else {
		fmt.Println(fullXML)
	}

	fmt.Println("\n📋 Instruções:")
	fmt.Println("1. Verifique se o go.mod está configurado corretamente")
	fmt.Println("2. Ajuste o import das structs TISS no código")
	fmt.Println("3. Execute: go run main.go")
}

// Estruturas temporárias que replicam a estrutura do XML TISS
// Estas devem ser substituídas pelas structs geradas pelo xgen
type MensagemTISS struct {
	XMLName                xml.Name               `xml:"ans:mensagemTISS"`
	Xmlns                  string                 `xml:"xmlns,attr"`
	XmlnsAns               string                 `xml:"xmlns:ans,attr"`
	Cabecalho              Cabecalho              `xml:"ans:cabecalho"`
	PrestadorParaOperadora PrestadorParaOperadora `xml:"ans:prestadorParaOperadora"`
	Epilogo                Epilogo                `xml:"ans:epilogo"`
}

type Cabecalho struct {
	IdentificacaoTransacao IdentificacaoTransacao `xml:"ans:identificacaoTransacao"`
	Origem                 Origem                 `xml:"ans:origem"`
	Destino                Destino                `xml:"ans:destino"`
	Padrao                 string                 `xml:"ans:Padrao"`
}

type IdentificacaoTransacao struct {
	TipoTransacao         string `xml:"ans:tipoTransacao"`
	SequencialTransacao   string `xml:"ans:sequencialTransacao"`
	DataRegistroTransacao string `xml:"ans:dataRegistroTransacao"`
	HoraRegistroTransacao string `xml:"ans:horaRegistroTransacao"`
}

type Origem struct {
	IdentificacaoPrestador IdentificacaoPrestador `xml:"ans:identificacaoPrestador"`
}

type IdentificacaoPrestador struct {
	CodigoPrestadorNaOperadora string `xml:"ans:codigoPrestadorNaOperadora"`
}

type Destino struct {
	RegistroANS string `xml:"ans:registroANS"`
}

type PrestadorParaOperadora struct {
	RecursoGlosa RecursoGlosa `xml:"ans:recursoGlosa"`
}

type RecursoGlosa struct {
	GuiaRecursoGlosa GuiaRecursoGlosa `xml:"ans:guiaRecursoGlosa"`
}

type GuiaRecursoGlosa struct {
	RegistroANS                 string          `xml:"ans:registroANS"`
	NumeroGuiaRecGlosaPrestador string          `xml:"ans:numeroGuiaRecGlosaPrestador"`
	NomeOperadora               string          `xml:"ans:nomeOperadora"`
	ObjetoRecurso               string          `xml:"ans:objetoRecurso"`
	NumeroGuiaRecGlosaOperadora string          `xml:"ans:numeroGuiaRecGlosaOperadora"`
	DadosContratado             DadosContratado `xml:"ans:dadosContratado"`
	NumeroLote                  string          `xml:"ans:numeroLote"`
	NumeroProtocolo             string          `xml:"ans:numeroProtocolo"`
	OpcaoRecurso                OpcaoRecurso    `xml:"ans:opcaoRecurso"`
	ValorTotalRecursado         string          `xml:"ans:valorTotalRecursado"`
	DataRecurso                 string          `xml:"ans:dataRecurso"`
}

type DadosContratado struct {
	CodigoPrestadorNaOperadora string `xml:"ans:codigoPrestadorNaOperadora"`
}

type OpcaoRecurso struct {
	RecursoGuia []RecursoGuia `xml:"ans:recursoGuia"`
}

type RecursoGuia struct {
	NumeroGuiaOrigem    string           `xml:"ans:numeroGuiaOrigem"`
	NumeroGuiaOperadora string           `xml:"ans:numeroGuiaOperadora"`
	OpcaoRecursoGuia    OpcaoRecursoGuia `xml:"ans:opcaoRecursoGuia"`
}

type OpcaoRecursoGuia struct {
	ItensGuia ItensGuia `xml:"ans:itensGuia"`
}

type ItensGuia struct {
	SequencialItem    string      `xml:"ans:sequencialItem"`
	DataInicio        string      `xml:"ans:dataInicio"`
	ProcRecurso       ProcRecurso `xml:"ans:procRecurso"`
	CodGlosaItem      string      `xml:"ans:codGlosaItem"`
	ValorRecursado    string      `xml:"ans:valorRecursado"`
	JustificativaItem string      `xml:"ans:justificativaItem"`
}

type ProcRecurso struct {
	CodigoTabela          string `xml:"ans:codigoTabela"`
	CodigoProcedimento    string `xml:"ans:codigoProcedimento"`
	DescricaoProcedimento string `xml:"ans:descricaoProcedimento"`
}

type Epilogo struct {
	Hash string `xml:"ans:hash"`
}

func createRecursoGlosaMessage() *MensagemTISS {
	// Cria a estrutura da mensagem TISS exatamente como no XML fornecido
	mensagem := &MensagemTISS{
		Xmlns:    "http://www.w3.org/2001/XMLSchema",
		XmlnsAns: "http://www.ans.gov.br/padroes/tiss/schemas",
		Cabecalho: Cabecalho{
			IdentificacaoTransacao: IdentificacaoTransacao{
				TipoTransacao:         "RECURSO_GLOSA",
				SequencialTransacao:   "249932",
				DataRegistroTransacao: "2025-06-16",
				HoraRegistroTransacao: "11:30:11",
			},
			Origem: Origem{
				IdentificacaoPrestador: IdentificacaoPrestador{
					CodigoPrestadorNaOperadora: "66692750",
				},
			},
			Destino: Destino{
				RegistroANS: "326305",
			},
			Padrao: "4.01.00",
		},
		PrestadorParaOperadora: PrestadorParaOperadora{
			RecursoGlosa: RecursoGlosa{
				GuiaRecursoGlosa: GuiaRecursoGlosa{
					RegistroANS:                 "326305",
					NumeroGuiaRecGlosaPrestador: "125697572",
					NomeOperadora:               "Palmeiras não tem Mundial",
					ObjetoRecurso:               "2",
					NumeroGuiaRecGlosaOperadora: "125697572",
					DadosContratado: DadosContratado{
						CodigoPrestadorNaOperadora: "66692750",
					},
					NumeroLote:      "609128",
					NumeroProtocolo: "5130698462",
					OpcaoRecurso: OpcaoRecurso{
						RecursoGuia: []RecursoGuia{
							{
								NumeroGuiaOrigem:    "125697572",
								NumeroGuiaOperadora: "125697572",
								OpcaoRecursoGuia: OpcaoRecursoGuia{
									ItensGuia: ItensGuia{
										SequencialItem: "15",
										DataInicio:     "2025-02-17",
										ProcRecurso: ProcRecurso{
											CodigoTabela:          "22",
											CodigoProcedimento:    "40402118",
											DescricaoProcedimento: "Deleucotizayyo De Unidade De Concentrado De Hemycias - Por U",
										},
										CodGlosaItem:      "1714",
										ValorRecursado:    "91.50",
										JustificativaItem: "Cobranca correta, conforme aditivo de 01/07/2024 - CASO 26694634. P/ Planos Individual (Apartamento) - Planos Nivel 350 a 750 (150 ch x 1,23=184,50)",
									},
								},
							},
							{
								NumeroGuiaOrigem:    "125707160",
								NumeroGuiaOperadora: "125707160",
								OpcaoRecursoGuia: OpcaoRecursoGuia{
									ItensGuia: ItensGuia{
										SequencialItem: "5",
										DataInicio:     "2025-02-18",
										ProcRecurso: ProcRecurso{
											CodigoTabela:          "22",
											CodigoProcedimento:    "40402118",
											DescricaoProcedimento: "Deleucotizayyo De Unidade De Concentrado De Hemycias - Por U",
										},
										CodGlosaItem:      "1714",
										ValorRecursado:    "91.50",
										JustificativaItem: "Cobranca correta, conforme aditivo de 01/07/2024 - CASO 26694634. P/ Planos Individual (Apartamento) - Planos Nivel 350 a 750 (150 ch x 1,23=184,50)",
									},
								},
							},
						},
					},
					ValorTotalRecursado: "183.00",
					DataRecurso:         "2025-06-16",
				},
			},
		},
		Epilogo: Epilogo{
			Hash: "dba6a1d89d76c5186bb0b9b068202a23",
		},
	}

	return mensagem
}

// Função auxiliar para criar structs customizadas baseadas nos dados reais
func createCustomRecursoGlosa(sequencial, codigoPrestador, registroANS, nomeOperadora string) *MensagemTISS {
	now := time.Now()

	mensagem := &MensagemTISS{
		Xmlns:    "http://www.w3.org/2001/XMLSchema",
		XmlnsAns: "http://www.ans.gov.br/padroes/tiss/schemas",
		Cabecalho: Cabecalho{
			IdentificacaoTransacao: IdentificacaoTransacao{
				TipoTransacao:         "RECURSO_GLOSA",
				SequencialTransacao:   sequencial,
				DataRegistroTransacao: now.Format("2006-01-02"),
				HoraRegistroTransacao: now.Format("15:04:05"),
			},
			Origem: Origem{
				IdentificacaoPrestador: IdentificacaoPrestador{
					CodigoPrestadorNaOperadora: codigoPrestador,
				},
			},
			Destino: Destino{
				RegistroANS: registroANS,
			},
			Padrao: "4.01.00",
		},
		PrestadorParaOperadora: PrestadorParaOperadora{
			RecursoGlosa: RecursoGlosa{
				GuiaRecursoGlosa: GuiaRecursoGlosa{
					RegistroANS:                 registroANS,
					NumeroGuiaRecGlosaPrestador: "AUTO_" + sequencial,
					NomeOperadora:               nomeOperadora,
					ObjetoRecurso:               "2",
					NumeroGuiaRecGlosaOperadora: "AUTO_" + sequencial,
					DadosContratado: DadosContratado{
						CodigoPrestadorNaOperadora: codigoPrestador,
					},
					NumeroLote:      "AUTO_" + now.Format("150405"),
					NumeroProtocolo: "AUTO_" + now.Format("20060102150405"),
					OpcaoRecurso: OpcaoRecurso{
						RecursoGuia: []RecursoGuia{
							{
								NumeroGuiaOrigem:    "AUTO_" + sequencial + "_001",
								NumeroGuiaOperadora: "AUTO_" + sequencial + "_001",
								OpcaoRecursoGuia: OpcaoRecursoGuia{
									ItensGuia: ItensGuia{
										SequencialItem: "1",
										DataInicio:     now.Format("2006-01-02"),
										ProcRecurso: ProcRecurso{
											CodigoTabela:          "22",
											CodigoProcedimento:    "40402118",
											DescricaoProcedimento: "Procedimento de exemplo gerado automaticamente",
										},
										CodGlosaItem:      "1714",
										ValorRecursado:    "100.00",
										JustificativaItem: "Justificativa automática gerada pelo sistema",
									},
								},
							},
						},
					},
					ValorTotalRecursado: "100.00",
					DataRecurso:         now.Format("2006-01-02"),
				},
			},
		},
		Epilogo: Epilogo{
			Hash: "auto_generated_hash_" + now.Format("20060102150405"),
		},
	}

	return mensagem
}

/*
🔧 INSTRUÇÕES PARA USAR AS STRUCTS GERADAS PELO XGEN:

1. Primeiro, verifique se o go.mod está configurado:
   cd pkg/v4_01_00
   cat go.mod

2. Encontre as structs corretas nos arquivos gerados:
   cd schema_v4_01_00
   grep -r "type.*struct" *.go | grep -i "mensagem\|recurso\|glosa"

3. Substitua as structs temporárias acima pelas structs reais do xgen

4. Ajuste o import:
   import tiss "github.com/renatofagalde/app-tiss-schemas/pkg/tiss/v4_01_00"

5. Use as structs reais na função createRecursoGlosaMessage()

📋 Exemplo de como deveria ficar com structs reais:
   mensagem := &tiss.TissMensagemTISS{  // Nome real da struct
       Cabecalho: tiss.TissCabecalho{   // Nome real da struct
           // ... campos conforme struct real
       },
       // ...
   }

Executar: go run main.go
*/
