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
#      23/10/2024 - Adicion de CheckExternalTools
#      23/10/2024 - Primera aproximacion a multiples usuarios
#      25/10/2024 - Adicion de multiples usuarios y opcion -d
#      25/10/2024 - Adicion de opcion -t
#      25/10/2024 - Adicion de comentarios en el codigo, y creacion del mensaje de ayuda
#      29/10/2024 - Mejora de la opcion -t
#      31/10/2024 - Modificacion: Adicion de la opcion -w

# Funciones:

# Obtiene la informacion del comando ps
Infosession () {
  ps -e -o sid,pgid,pid,user,tty,%mem,cmd --no-headers | tr -s " " 
}                                                   

# Chequea la existencia de awk y lsof
CheckExternalTools() {
  awk_sign=$(which awk)
  lsof_sign=$(which lsof)
  if [ -z "$awk_sign" ]; then
    echo "Warning: awk not installed."
    exit 1
  fi
  if [ -z "$lsof_sign" ]; then
    echo "Warning: lsof not installed."
    exit 1
  fi
}

CheckExternalTools

# Inicialización de variables:
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
TERMINAL=0
MIN_PROCESS=0

# Procesamiento argumentos:
while [ -n "$1" ]; do
  case "$1" in
    -h )
        HELP=1
        ;;
    -z ) 
        ZERO=1
        ;;
# Cambio al argumento. Mientras sigan habiendo usuarios, añadelos a USR. Si no hay ninguno, error
    -u ) 
        shift
        while [ -n "$1" ] && [[ "$1" != -* ]]; do
          USR+=("$1")  
          shift
        done        
        if [ ${#USR[@]} -eq 0 ]; then
          ERROR=1
        fi
        continue
        ;;
    -d ) 
# Cambio al argumento. Si no hay directorio especificado, o no existe, entonces error
        shift
        DIR="$1"
        if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
          ERROR=1
          INVALID_OPTION="-d"
        fi
        ;;
    -t )
        TERMINAL=1
        ;;
    -w )
        MIN_PROCESS=1 
        ;;
    * )
        ERROR=1
        INVALID_OPTION="$1"
        ;;
  esac
  shift
done


# Evaluacion de argumentos:

# Ayuda
if [ $HELP -eq 1 ]; then
  echo "Usage: ./infosession.sh [-h] [-z] [-u user1 ... ] [ -d dir ] [-t ]"
  echo "Shows the active processes including their sid's, pgid's, pid's, user's, tty's, %mem, cmd, without including those whose sgid's are 0"
  echo
  echo "Any of the following options can be combined to get different results:"
  echo
  echo "-h: Displays this help to the user"
  echo "-z: Shows the processes with sgid's equal to 0"
  echo "-u user1 ... : Accepts at least one user. Displays the processes that belong to the specified user/s"
  echo "-d dir : Accepts one specified directory. Shows those processes that have active files in the given directory"
  echo "-t: Shows those processes that has a terminal associated"
  exit 0
fi


# Mensaje de error
if [ $ERROR -eq 1 ]; then 
  echo "$0: invalid option -- '$INVALID_OPTION'"
  echo "Try $0 -h for more information."
  exit 1
fi

# Si -z, mostrar procesos con sgid 0. Si no, mostrar los que no tienen sgid 0
if [ $ZERO -eq 1 ]; then 
  INFORMATION=$(echo "$INFORMATION")
else 
  INFORMATION=$(echo "$INFORMATION" | awk '$1 != 0')
fi

# Opcion -u: Si el tamaño de arrays de usuarios es mayor a 0, entonces
if [ ${#USR[@]} -gt 0 ]; then
# Para cada usuario en el array
  for i in "${USR[@]}"; do
# Si el usuario es igual al user del ps, guardar sus procesos en USR_INFO
    USR_INFO=$(echo "$INFORMATION" | awk -v user="$i" '$4 == user')
# Guardar para cada usuario con un salto de linea
    TOTAL_INFO+=$USR_INFO'\n'
  done
# Una vez terminado el bucle, guardar en INFORMATION
  INFORMATION="$TOTAL_INFO"
fi


# Opcion -d: 
if [ -n "$DIR" ]; then
# Guardar los pids de lsof +d en el directorio especificado en TEMP_PIDS
  TEMP_PIDS=$(lsof +d "$DIR" | awk '{print $2}')
# Mostrar solo aquellos que se corresponden con dichos pids
  INFORMATION=$(echo "$INFORMATION" | grep "$TEMP_PIDS")
fi


# Opcion -w:
if [ $MIN_PROCESS -eq 1 ]; then
  MIN_PROCESS=$(echo "$INFORMATION" | wc -l)
  if [ $MIN_PROCESS -lt 6 ]; then
    echo "Warning: The result table has less than 5 processes"
  fi
fi

# Opcion -t: Si no activada, mostrar informacion. Si activada, mostrar aquellos en donde la tty es distinta de 0
if [ $TERMINAL -eq 0 ]; then
  INFORMATION=$(echo "$INFORMATION")
else 
  INFORMATION=$(echo "$INFORMATION" | awk '$5 != "0" && $5 != "?"')
fi

# Mostrar el resultado
echo "SID PGID PID USER TTY %MEM CMD"
echo "$INFORMATION" 