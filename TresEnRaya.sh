#!/bin/bash

# Define el estado inicial del tablero
tablero=(· · · · · · · · ·)
pos_cursor=1

# Colores
ROJO=$(tput setaf 1)
AZUL=$(tput setaf 4)
NC=$(tput sgr0) # Sin color

# Función para mostrar el tablero
mostrar_tablero() {
    for i in {0..8}; do
        celda=${tablero[$i]}
        if [ "$celda" == "X" ]; then
            celda="${ROJO}X${NC}"
        elif [ "$celda" == "O" ]; then
            celda="${AZUL}O${NC}"
        fi

        if [ $((i+1)) -eq $pos_cursor ]; then
            echo -n "[ $celda ]"
        else
            echo -n "  $celda  "
        fi

        if [ $((i % 3)) -eq 2 ]; then
            echo -e "\n\n\n"
        else
            echo -n " | "
        fi
    done
    echo
}
resettablero(){
    tablero=(· · · · · · · · ·)
}
# Función para verificar un ganador
verificar_ganador() {
    for combo in "0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6"; do
        a=$(echo $combo | awk '{print $1}')
        b=$(echo $combo | awk '{print $2}')
        c=$(echo $combo | awk '{print $3}')
        if [ "${tablero[$a]}" == "${tablero[$b]}" ] && [ "${tablero[$b]}" == "${tablero[$c]}" ] && [ "${tablero[$a]}" != "·" ]; then
            clear
            mostrar_tablero
            echo "¡Jugador ${tablero[$a]} gana!"
            read -rsn1 tecla
            resettablero
            menu
        fi
    done
}

# Función para verificar un empate
verificar_empate() {
    for i in {0..8}; do
        if [[ "${tablero[$i]}" == "·" ]]; then
            return
        fi
    done
    clear
    mostrar_tablero
    echo "¡Es un empate!"
    read -rsn1 tecla
    resettablero
    menu
}

# Función para hacer un movimiento
hacer_movimiento() {
    local jugador=$1
    if [[ "${tablero[$((pos_cursor-1))]}" == "·" ]]; then
        tablero[$((pos_cursor-1))]=$jugador
        return 0
    else
        return 1
    fi
}

# Función para manejar la entrada del usuario
manejar_entrada() {
    local jugador=$1
    while true; do
        clear
        mostrar_tablero
        echo "Jugador $jugador, use las teclas de flecha para moverse, Enter para seleccionar, 3 para salir."
        read -rsn1 tecla
        case $tecla in
            $'\e')
                read -rsn2 -t 0.1 tecla
                case $tecla in
                    '[A')  # Flecha arriba
                        if [ $pos_cursor -gt 3 ]; then
                            pos_cursor=$((pos_cursor - 3))
                        fi
                        ;;
                    '[B')  # Flecha abajo
                        if [ $pos_cursor -le 6 ]; then
                            pos_cursor=$((pos_cursor + 3))
                        fi
                        ;;
                    '[D')  # Flecha izquierda
                        if [ $((pos_cursor % 3)) -ne 1 ]; then
                            pos_cursor=$((pos_cursor - 1))
                        fi
                        ;;
                    '[C')  # Flecha derecha
                        if [ $((pos_cursor % 3)) -ne 0 ]; then
                            pos_cursor=$((pos_cursor + 1))
                        fi
                        ;;
                esac
                ;;
            '')  # Tecla Enter
                if hacer_movimiento $jugador; then
                    verificar_ganador
                    verificar_empate
                    return
                else
                    echo "Posición ya ocupada, intenta de nuevo."
                    sleep 1
                fi
                ;;
            3)  # Opción para salir
                echo "Saliendo del juego..."
                exit
                ;;
        esac
    done
}

# Función para verificar posible victoria o bloqueo
verificar_victoria_o_bloqueo() {
    local jugador=$1
    for combo in "0 1 2" "3 4 5" "6 7 8" "0 3 6" "1 4 7" "2 5 8" "0 4 8" "2 4 6"; do
        a=$(echo $combo | awk '{print $1}')
        b=$(echo $combo | awk '{print $2}')
        c=$(echo $combo | awk '{print $3}')
        if [ "${tablero[$a]}" == "$jugador" ] && [ "${tablero[$b]}" == "$jugador" ] && [ "${tablero[$c]}" == "·" ]; then
            tablero[$c]=$ficha_ia
            return 0
        elif [ "${tablero[$a]}" == "$jugador" ] && [ "${tablero[$c]}" == "$jugador" ] && [ "${tablero[$b]}" == "·" ]; then
            tablero[$b]=$ficha_ia
            return 0
        elif [ "${tablero[$b]}" == "$jugador" ] && [ "${tablero[$c]}" == "$jugador" ] && [ "${tablero[$a]}" == "·" ]; then
            tablero[$a]=$ficha_ia
            return 0
        fi
    done
    return 1
}

# Movimiento del AI mejorado
movimiento_ai() {
    # Intentar ganar
    verificar_victoria_o_bloqueo $ficha_ia
    if [ $? -eq 0 ]; then
        verificar_ganador
        verificar_empate
        return
    fi

    # Bloquear al jugador
    verificar_victoria_o_bloqueo $jugador1
    if [ $? -eq 0 ]; then
        verificar_ganador
        verificar_empate
        return
    fi

    # Movimiento aleatorio si no hay posibilidad de ganar o bloquear
    for i in {0..8}; do
        if [[ "${tablero[$i]}" == "·" ]]; then
            tablero[$i]=$ficha_ia
            break
        fi
    done
    verificar_ganador
    verificar_empate
}

# Bucle principal del juego contra la IA
jugar_ia() {
    clear
    mostrar_tablero
    if [ $((RANDOM % 2)) -eq 0 ]; then
        jugador1="O"
        ficha_ia="X"
    else
        jugador1="X"
        ficha_ia="O"
    fi
    for turno in {1..9}; do
        if [ $((turno % 2)) -eq 1 ]; then
            manejar_entrada $jugador1
        else
            movimiento_ai
        fi
    done
}

# Menú para elegir modo de juego
menu() {
    clear
    echo "Elige el modo de juego:"
    echo "1. Jugar contra la IA"
    echo "2. Jugar contra otro jugador"
    echo "3. Salir"
    read -rsn1 opcion
    case $opcion in
        1) jugar_ia ;;
        2) jugar_humano ;;
        3) echo "Saliendo..." && exit ;;
        *) menu ;;
    esac
}

# Bucle del juego Humano vs Humano
jugar_humano() {
    clear
    mostrar_tablero
    if [ $((RANDOM % 2)) -eq 0 ]; then
        jugador1="O"
        jugador2="X"
    else
        jugador1="X"
        jugador2="O"
    fi
    for turno in {1..9}; do
        if [ $((turno % 2)) -eq 1 ]; then
            manejar_entrada $jugador1
        else
            manejar_entrada $jugador2
        fi
    done
}

while true; do
    menu
done
