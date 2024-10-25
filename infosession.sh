#!/bin/bash

# Universidad de La Laguna
# Escuela Superior de Ingenieria y Tecnologia
# Grado en Ingenieria Informatica
# Asignatura: Sistemas Operativos
# Curso: 2º
# Proyecto de BASH: : Información básica de las sesiones de los procesos
# Autor: Marco Perez Padilla
# Correo: alu0101469348@ull.edu.es
# Fecha: 22/10/2024

# Archivo infosession.sh: Contiene
#      
# Referencias:
#      Enlaces de interes

# Historial de revisiones:
#      22/10/2024 - Primera version (creacion) del script
#      22/10/2024 - Adicion de opciones: -u, -z, -h
#      23/10/2024 - Primera aproximacion a multiples usuarios
#      25/10/2024

# Funciones
Infosession () {
  ps -e -o sid,pgid,pid,user,tty,%mem,cmd --no-headers | tr -s " " 
}                                                   

CheckExternalTools() {
  awk_sign=$(which awk)
  lsof_sign=$(which lsof)
  if [ -z "$awk_sign" ]; then
    echo "Warning: awk not installed."
    exit 0
  fi
  if [ -z "$lsof_sign" ]; then
    echo "Warning: lsof not installed."
    exit 0
  fi
}


# Chequeo de paquetes instalados
CheckExternalTools

# Inicialización de variables
INFORMATION=$(Infosession)
HELP=0
ZERO=0
USR=()
ERROR=0
INVALID_OPTION=0
USR_INFO=""
TOTAL_INFO=""
DIR=""
TEMP_PIDS=""

# Procesamiento argumentos
while [ -n "$1" ]; do
  case "$1" in
    -h )
        HELP=1
        ;;
    -z ) 
        ZERO=1
        ;;
    -u )
        shift
        while [ -n "$1" ] && [[ "$1" != -* ]]; do
          USR+=("$1")  
          shift
        done        
        if [ ${#USR[@]} -eq 0 ]; then
          echo "Error: -u requiere al menos un nombre de usuario"
          exit 1
        fi
        continue
        ;;
    -d ) 
        shift
        DIR="$1"
        if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
          ERROR=1
          INVALID_OPTION="-d"
        fi
        ;;
    * )
        ERROR=1
        INVALID_OPTION="$1"
        ;;
  esac
  shift
done


# Evaluacion de argumentos
if [ $HELP -eq 1 ]; then
  echo "Ayuda..."
  exit 0
fi

if [ $ERROR -eq 1 ]; then 
  echo "$0: invalid option -- '$INVALID_OPTION'"
  echo "Try $0 -h for more information."
  exit 1
fi

if [ $ZERO -eq 1 ]; then 
  INFORMATION=$(echo "$INFORMATION")
else 
  INFORMATION=$(echo "$INFORMATION" | awk '$1 != 0')
fi

if [ ${#USR[@]} -gt 0 ]; then
  for i in "${USR[@]}"; do
    USR_INFO=$(echo "$INFORMATION" |awk -v user="$i" '$4 == user')
    TOTAL_INFO+=$USR_INFO'\n'
  done
  INFORMATION="$TOTAL_INFO"
fi

if [ -n "$DIR" ]; then
  TEMP_PIDS=$(lsof +d "$DIR" | awk '{print $2}')
  INFORMATION=$(echo "$INFORMATION" | grep "$TEMP_PIDS")
fi

echo "$INFORMATION" 