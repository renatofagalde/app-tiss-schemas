# app-tiss-schemas

Este repositório contém os arquivos **XSD oficiais da ANS** (Agência Nacional de Saúde Suplementar) e os **stubs gerados em Go** a partir da versão **4.01.00** do padrão TISS (Troca de Informação em Saúde Suplementar).

---

## 📥 Fonte dos arquivos

Os arquivos `.xsd` e `.wsdl` foram baixados diretamente do portal oficial da ANS:

🔗 [https://www.gov.br/ans/pt-br/assuntos/operadoras/compromissos-e-interacoes-com-a-ans-1/padroes-e-schemas](https://www.gov.br/ans/pt-br/assuntos/operadoras/compromissos-e-interacoes-com-a-ans-1/padroes-e-schemas)

---

## ⚙️ Geração dos stubs Go

Os stubs foram gerados utilizando a ferramenta [`xgen`](https://github.com/xuri/xgen):

```bash
go install github.com/xuri/xgen/cmd/xgen@latest
xgen -i . -l Go -p v4_01_00 -o ./v4_01_00


```

- Linguagem: Go
- Package gerado: `v4_01_00`
- Suporte a `encoding/xml`

---

## 📁 Estrutura do projeto

```text
app-tiss-schemas/
├── go.mod
├── internal/
│   └── tiss/
│       ├── tissV4_01_00.xsd                # Arquivo principal da versão 4.01.00
│       ├── tissGuiasV4_01_00.xsd           # Guias TISS (consultas, SADT, etc.)
│       ├── tissSimpleTypesV4_01_00.xsd     # Tipos simples como enums e strings
│       ├── tissComplexTypesV4_01_00.xsd    # Tipos compostos (structs, objetos)
│       ├── tissWebServicesV4_01_00.xsd     # Definições de Web Services
│       ├── xmldsig-core-schema.xsd         # Assinaturas XML (W3C)
│       └── v4_01_00/
│           └── go_struct.go                # Arquivo gerado com structs Go
├── main.go                                 # Exemplo de uso com MensagemTISS
└── README.md                               # Este arquivo
```

---

## 🚀 Exemplo de uso

```go
package main

import (
    "encoding/xml"
    "fmt"

    "github.com/renatofagalde/app-tiss-schemas/internal/tiss/v4_01_00"
)

func main() {
    msg := v4_01_00.MensagemTISS{}
    out, _ := xml.MarshalIndent(msg, "", "  ")
    fmt.Println(string(out))
}
```

---

## 📝 Licença

Este projeto apenas agrupa arquivos públicos da ANS e é disponibilizado **sem modificações** para fins de integração, testes e uso em aplicações Go.
