#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

# --- CONFIGURAÇÕES ---
FIREBASE_URL="https://external-serv-default-rtdb.firebaseio.com"
FF_PACKAGE="com.dts.freefireth"
FF_DATA_ROOT="/storage/emulated/0/Android/data/${FF_PACKAGE}"
FF_ASSETS_DIR="${FF_DATA_ROOT}/files/contentcache/Optional/android"

# LINK DO ZIP APONTANDO PRO REPO NOVO (Holograma2)
REMOTE_ZIP="https://raw.githubusercontent.com/Pkdev730/Holograma2/main/HOLOGRAMA%20VIP.zip"
TMP_DIR="/data/data/com.termux/files/usr/tmp/ghost_cloud"

SHADER_ORIGINAL="shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D"
SHADER_MOD="shaders.pedroomods~vip~3D"

DATA_FALSA="202611211357.00"

# package do logcat reader do cliente
LOGCAT_PKG="com.dp.logcatapp"

# --- CHECA DEPENDÊNCIAS ---
for cmd in adb curl unzip find; do
    if ! command -v $cmd &> /dev/null; then
        printf "\033c"
        echo -e "${RED}[!] Falta: $cmd. Rode: pkg install android-tools curl unzip${NC}"
        exit 1
    fi
done

printf "\033c"
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}            AUTENTICAÇÃO GHOST            ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

# --- CONEXÃO ADB ---
ADB_STATE=$(adb get-state 2>/dev/null | tr -d '\r\n')
if [ "$ADB_STATE" == "device" ]; then
    echo -e "${GREEN}[+] ADB já conectado.${NC}"
    sleep 1
else
    echo -e "${WHITE}Etapa 1: Conexão com o Dispositivo${NC}"
    echo -e "${YELLOW}ADB não conectado. Configure agora.${NC}\n"
    echo -n "IP:PORTA de PAREAMENTO: "; read -r PAIR_ADDR < /dev/tty
    echo -n "Código de 6 dígitos:    "; read -r PAIR_CODE < /dev/tty
    echo -e "\n${YELLOW}[*] Pareando...${NC}"
    adb pair $PAIR_ADDR $PAIR_CODE
    echo -n "IP:PORTA de CONEXÃO: "; read -r CONN_ADDR < /dev/tty
    echo -e "${YELLOW}[*] Conectando...${NC}"
    adb connect $CONN_ADDR
    sleep 1
    if [ "$(adb get-state 2>/dev/null | tr -d '\r\n')" != "device" ]; then
        echo -e "${RED}[!] Falha na conexão.${NC}"; exit 1
    fi
fi

printf "\033c"
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}             VALIDAÇÃO DE LICENÇA         ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

echo -n "Digite sua Key (ex: External-teste1): "; read -r USER_KEY < /dev/tty
if [ -z "$USER_KEY" ]; then echo -e "${RED}[!] Key vazia.${NC}"; exit 1; fi

echo -e "${YELLOW}[*] Verificando Key...${NC}"
FIREBASE_RESPONSE=$(curl -s --max-time 5 "${FIREBASE_URL}/.json")
if [ -z "$FIREBASE_RESPONSE" ] || [ "$FIREBASE_RESPONSE" == "null" ]; then
    echo -e "${RED}[!] Falha ao conectar.${NC}"; exit 1
fi
STATUS=$(echo "$FIREBASE_RESPONSE" | grep -o "\"$USER_KEY\".*\"status\":\"ativada\"" | head -n 1)
if [ -z "$STATUS" ]; then echo -e "${RED}[!] Key inválida ou expirada.${NC}"; exit 1; fi

echo -e "${GREEN}[+] Acesso Autorizado!${NC}"
sleep 2

# --- MENU ---
declare -A ESTADO
ESTADO[1]=0

while true; do
    printf "\033c"
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${WHITE}              GHOST REMOTE                ${NC}"
    echo -e "${PURPLE}==========================================${NC}\n"

    status() {
        [ "${ESTADO[$1]}" -eq 1 ] && echo -e "${GREEN}[ON]${NC}" || echo -e "${RED}[OFF]${NC}"
    }

    echo -e "${CYAN}┌── MODS FREE FIRE ──────────────────────┐${NC}"
    echo -e "  [1] Injetar Holograma $(status 1)"
    echo -e "  [2] Remover Holograma"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"
    echo -e "\n${RED}┌── ENCERRAR SESSÃO ──────────────────────┐${NC}"
    echo -e "  [99] Limpar Rastros e Fechar"
    echo -e "${RED}└────────────────────────────────────────┘${NC}"
    echo -e "\n  [0] Sair"
    echo -n "  » Selecione: "
    read -r FUNC_OPT < /dev/tty

    case $FUNC_OPT in

        99)
            echo -e "\n${RED}[!] Vai fechar o jogo, limpar rastros e fechar ADB.${NC}"
            echo -n "Tem certeza? (s/n): "
            read -r CONFIRMA < /dev/tty

            if [ "$CONFIRMA" == "s" ]; then

                # 1. mata FF silencioso no celular 2
                echo -e "${YELLOW}[*] Encerrando Free Fire...${NC}"
                adb shell "pid=\$(pidof $FF_PACKAGE 2>/dev/null); \
                [ -n \"\$pid\" ] && kill -9 \$pid 2>/dev/null; true"
                sleep 1

                # 2. mata LogcatReader antes que salve qualquer coisa
                echo -e "${YELLOW}[*] Limpando LogcatReader...${NC}"
                adb shell "pid=\$(pidof $LOGCAT_PKG 2>/dev/null); \
                [ -n \"\$pid\" ] && kill -9 \$pid 2>/dev/null; true"
                adb shell "pm clear $LOGCAT_PKG" 2>/dev/null

                # 3. fecha porta ADB no celular 2
                echo -e "${YELLOW}[*] Fechando porta ADB...${NC}"
                adb shell "setprop service.adb.tcp.port -1" 2>/dev/null
                adb shell "stop adbd && start adbd" 2>/dev/null
                adb disconnect >/dev/null 2>&1

                # 4. limpa rastros locais no celular 1 (Termux)
                echo -e "${YELLOW}[*] Limpando rastros locais...${NC}"
                rm -rf "$TMP_DIR"
                rm -rf "/sdcard/Download/ff_original_backup"
                history -c
                rm -f ~/.bash_history
                rm -f /data/data/com.termux/files/home/.bash_history

                echo -e "${GREEN}[+] Feito. Celular 2 limpo, sessão encerrada.${NC}"
                exit 0
            fi
            ;;

        1)
            echo -e "\n${YELLOW}[*] Encerrando Free Fire...${NC}"
            adb shell "pid=\$(pidof $FF_PACKAGE 2>/dev/null); \
            [ -n \"\$pid\" ] && kill -9 \$pid 2>/dev/null; true"
            sleep 1

            echo -e "${YELLOW}[*] Baixando mod...${NC}"
            rm -rf "$TMP_DIR"
            mkdir -p "$TMP_DIR/download"
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/master.zip"

            if [ ! -s "${TMP_DIR}/master.zip" ]; then
                echo -e "${RED}[!] Falha ao baixar.${NC}"; sleep 3; continue
            fi

            unzip -q -o "${TMP_DIR}/master.zip" -d "${TMP_DIR}/content"

            SRC_MOD=$(find "${TMP_DIR}/content" -type d \
                -name "com.dts.freefireth" \
                -path "*/HOLOGRAMA FREE FIRE NORMAL/*" | head -n 1)

            if [ -z "$SRC_MOD" ]; then
                echo -e "${RED}[!] Pasta do MOD não encontrada.${NC}"; sleep 3; continue
            fi

            # remove shaders antigos antes do push (anti-sort)
            echo -e "${CYAN}  [+] Removendo shaders antigos...${NC}"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_ORIGINAL}'"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_MOD}'"

            echo -e "${CYAN}  [+] Injetando...${NC}"
            adb push "$SRC_MOD/." "${FF_DATA_ROOT}/" > /dev/null

            # forja timestamp — passa limpo no find -mtime e find | sort
            echo -e "${CYAN}  [+] Forjando timestamps...${NC}"
            adb shell "find '${FF_ASSETS_DIR}/gameassetbundles' \
                -exec touch -t ${DATA_FALSA} {} \; 2>/dev/null"
            adb shell "touch -t ${DATA_FALSA} \
                '${FF_ASSETS_DIR}/fileinfo' 2>/dev/null"

            ESTADO[1]=1
            echo -e "\n${GREEN}[+] Holograma Injetado! Abra o Free Fire.${NC}"
            rm -rf "$TMP_DIR"
            ;;

        2)
            echo -e "\n${YELLOW}[*] Encerrando Free Fire...${NC}"
            adb shell "pid=\$(pidof $FF_PACKAGE 2>/dev/null); \
            [ -n \"\$pid\" ] && kill -9 \$pid 2>/dev/null; true"
            sleep 1

            echo -e "${YELLOW}[*] Baixando pacote de restauração...${NC}"
            rm -rf "$TMP_DIR"
            mkdir -p "$TMP_DIR/download"
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/master.zip"

            if [ ! -s "${TMP_DIR}/master.zip" ]; then
                echo -e "${RED}[!] Falha ao baixar.${NC}"; sleep 3; continue
            fi

            unzip -q -o "${TMP_DIR}/master.zip" -d "${TMP_DIR}/content"

            SRC_RESTORE=$(find "${TMP_DIR}/content" -type d \
                -name "com.dts.freefireth" \
                -path "*/REMOVER HOLOGRAMA FREE FIRE NORMAL/*" | head -n 1)

            if [ -z "$SRC_RESTORE" ]; then
                echo -e "${RED}[!] Pasta REMOVER não encontrada.${NC}"; sleep 3; continue
            fi

            # remove shaders modificados antes do push (anti-sort)
            echo -e "${CYAN}  [+] Removendo shaders modificados...${NC}"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_ORIGINAL}'"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_MOD}'"

            echo -e "${CYAN}  [+] Restaurando originais...${NC}"
            adb push "$SRC_RESTORE/." "${FF_DATA_ROOT}/" > /dev/null

            # forja timestamp
            echo -e "${CYAN}  [+] Forjando timestamps...${NC}"
            adb shell "find '${FF_ASSETS_DIR}/gameassetbundles' \
                -exec touch -t ${DATA_FALSA} {} \; 2>/dev/null"
            adb shell "touch -t ${DATA_FALSA} \
                '${FF_ASSETS_DIR}/fileinfo' 2>/dev/null"

            ESTADO[1]=0
            echo -e "\n${GREEN}[+] Holograma Removido!${NC}"
            rm -rf "$TMP_DIR"
            ;;

        0)
            printf "\033c"
            exit 0
            ;;
    esac

    echo -e "\n${CYAN}Pressione ENTER para continuar...${NC}"
    read -r < /dev/tty
done
