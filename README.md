# 📱 Espelhar Tela no PC (scrcpy Wireless Toggle)

Espelhe a tela do seu celular Android no computador **sem cabos** e com **1 clique** — seja pesquisando **"Espelhar Tela"** no Menu Iniciar do Windows ou tocando no botão do aplicativo no celular (ou no botão rápido da barra de notificações do Android).

Não é necessário fixar IP no roteador nem configurar o IP do PC no celular: a comunicação usa **UDP Broadcast (`:8888`)** e descoberta automática da porta ADB (`:5555`) na rede local.

---

## ✨ Recursos

- **Zero Configuração de IP:** Troque de roteador ou operadora sem precisar editar scripts.
  - **Pelo Celular:** O app envia um pacote UDP Broadcast na rede Wi-Fi (`TOGGLE_CLL` na porta `8888`). O PC identifica automaticamente o IP do celular pelo pacote recebido e abre a janela com o título **"Meu Celular"**.
  - **Pelo PC:** O atalho **Espelhar Tela** lê o último IP recebido ou salvo no `phone_ip.txt` e se conecta instantaneamente.
- **Atalho Indexado no Windows Search:** Basta apertar a tecla `Windows` e digitar **Espelhar Tela**.
- **App Android Ultra-Leve (`EspelharTela.apk` — ~16 KB):**
  - Botão grande de *Toggle* (abre se estiver fechado, fecha se estiver aberto).
  - Inclui **Bloco de Configurações Rápidas (Quick Settings Tile)** no topo da barra de notificações do Android ("Espelhar PC").

---

## 🚀 Como Instalar (Para qualquer usuário)

### 1. Pré-requisito no Celular
1. Ative as **Opções do Desenvolvedor** no Android (toque 7 vezes em *Configurações > Sobre o telefone > Número da versão*).
2. Ative a **Depuração USB** (e, se disponível, *Depuração por Wi-Fi*).

### 2. Instalação em 1 Clique no Windows
1. Baixe ou clone este repositório em uma pasta permanente (ex.: `Documentos\Scripts`).
2. Conecte o celular no PC via cabo USB **apenas na primeira vez** (e aceite a permissão de Depuração USB na tela do celular).
3. Dê dois cliques em **[Instalar.bat](./Instalar.bat)** (recomendado clicar com botão direito -> *Executar como Administrador* para liberar a porta `8888` no Firewall automaticamente).

O instalador fará tudo sozinho:
- Instala o `scrcpy` e o `adb` via `winget` (caso você ainda não tenha).
- Cria o atalho **Espelhar Tela** no **Menu Iniciar** (para aparecer na pesquisa do Windows) e na Área de Trabalho.
- Registra a tarefa **Ouvinte do Celular** no Agendador de Tarefas do Windows (`listener_udp.exe`).
- Ativa o `adb tcpip 5555` e instala o `EspelharTela.apk` no seu celular conectado!

---

## 🛠️ Estrutura do Projeto

- [listener.go](./listener.go) / `listener_udp.exe`: Serviço em Go (sem janela de console) que roda em segundo plano escutando pacotes UDP na porta `8888` e gerencia o comando `--toggle` do atalho do PC.
- [Instalar.bat](./Instalar.bat): Instalador automático para Windows e Android.
- [EspelharTela.apk](./EspelharTela.apk): Aplicativo Android pronto para instalar.
- `mobile-app/`: Código-fonte completo do aplicativo Android nativo + script [build_apk.ps1](./mobile-app/build_apk.ps1) para recompilar o APK sem precisar abrir o Android Studio.
- `transmitting.bat`: Script de inicialização e encerramento do espelhamento via scrcpy.

---

## 🔧 Como Compilar Manualmente (Desenvolvedores)

### Compilar o executável do PC (Go):
```powershell
go build -trimpath -ldflags="-s -w -H=windowsgui" -o listener_udp.exe listener.go
```

### Compilar o APK do Android:
```powershell
powershell -ExecutionPolicy Bypass -File .\mobile-app\build_apk.ps1
```
