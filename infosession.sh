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

# Archivo infosession.sh: Contiene las especificaciones del comando ./infosession.sh
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
#      31/10/2024 - Eliminación de la opcion -w
#      31/10/2024 - Adición de opcion -e
#      05/11/2024 - Separacion del mensaje de ayuda segun se invoca -e o no
#      05/11/2024 - Mejora de opcion -d. Eliminacion del uso de grep
#      05/11/2024 - Comentarios para cada varibale
#      05/11/2024 - Adicion de la tabla de sesiones
#      06/11/2024 - Manejo de casos en donde el pid lider no coincide con el sid
#      06/11/2024 - Actualizacion del mensaje de ayuda

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
INFORMATION=$(Infosession)   # Contiene la informacion pura del comando ps. Será sobreescrito según los argumentos pasados
HELP=0                       # Se usa para señalar si el usuario ha pedido la ayuda o no
ZERO=0                       # Se usa para señalar si el usuario quiere los procesos con sid 0 o no
USR=()                       # Se usa para almacenar los usuarios introducidos
ERROR=0                      # Se usa para señalar si hay un error en la ejecución o no
INVALID_OPTION=""            # Se usa para indicar qué opción es inválida           
USR_INFO=""                  # Se usa para filtrar por cada usuario individualmente
TOTAL_INFO=""                # Se usa para almacenar el filtrado individual de cada usuario en un total
DIR=()                       # Se usa para almacenar el directorio con el que usar lsof
TEMP_PIDS=""                 # Equivalente a USR_INFO con los pids del directoria¡o
TERMINAL=0                   # Se usa para señalar si el usuario ha pedido la terminal o no
SESSION_TABLE=1              # Se usa para señalar si el usuario ha pedido la tabla de sesiones o no
UNICO=1                      # Se usa para señalar si no se ha pasado ningun argumento

# Procesamiento argumentos:
while [ -n "$1" ]; do
  case "$1" in
    -h )
        HELP=1
        UNICO=0
        ;;
    -z ) 
        ZERO=1
        UNICO=0
        ;;
# Cambio al argumento. Mientras sigan habiendo usuarios, añadelos a USR. Si no hay ninguno, error
    -u ) 
        shift
        UNICO=0
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
        UNICO=0
        DIR+=("$1")
        if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
          ERROR=1
          INVALID_OPTION="-d"
        fi
        ;;
    -t )
        TERMINAL=1
        UNICO=0
        ;;
    -e )
        SESSION_TABLE=0
        UNICO=0
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
  echo "Usage: ./infosession.sh [-h] [-e] [-z] [-u user1 ... ] [ -d dir ] [-t ]" 
  echo "       ./infosession.sh [-h] [-z] [-u user1 ... ] [ -d dir ] [-t ]"
  echo "If used without any option, its defualt behaviour is showing the active processes including their sid's, pgid's, pid's, user's, tty's, %mem, cmd, without including those whose sgid's are 0"
  echo
  echo "-e: It shows the active processes including their sid's, pgid's, pid's, user's, tty's, %mem, cmd, without including those whose sgid's are 0"
  echo "If -e is not used, it shows the session table, displaying the sid, number of groups it has, pid leader, user, terminal and command"
  echo "Both can be combined with any of the folloring options:"
  echo
  echo "    -h: Displays this help to the user"
  echo "    -z: Shows the processes with sgid's equal to 0"
  echo "    -u user1 ... : Accepts at least one user. Displays the processes that belong to the specified user/s"
  echo "    -d dir : Accepts one specified directory. Shows those processes that have active files in the given directory"
  echo "    -t: Shows those processes that has a terminal associated"
  echo
  exit 0
fi


# Mensaje de error
if [ $ERROR -eq 1 ]; then 
  echo "$0: invalid option -- '$INVALID_OPTION'" 2>&1
  echo "Try $0 -h for more information." 2>&1
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
  for i in $TEMP_PIDS; do
    TOTAL_INFO_PIDS+=$(echo "$INFORMATION" | awk -v pid="$i" '$3 == pid')$'\n'
  done
  # Mostrar solo aquellos que se corresponden con dichos pids
  INFORMATION=$(echo "$TOTAL_INFO_PIDS")
fi


# Opcion -t: Si no activada, mostrar informacion. Si activada, mostrar aquellos en donde hay tty asociada
if [ $TERMINAL -eq 0 ]; then
  INFORMATION=$(echo "$INFORMATION")
else 
  INFORMATION=$(echo "$INFORMATION" | awk '$5 != "0" && $5 != "?"')
fi


if [ $SESSION_TABLE -eq 0 ] || [ $UNICO -eq 1 ] ; then
  # Mostrar el resultado de la tabla de procesos
  echo "SID PGID PID USER TTY %MEM CMD"
  echo "$INFORMATION" 
  exit 0
else
  # Impresion de cabecera
  echo -e "SID NUMBER_OF_PROCESSES PID_LEADER USER TTY\t   CMD\n"
  # Inicializacion de variables
  SID_TABLE=$(echo "$INFORMATION" | awk '{print $1}')
  SID_UNIQ=$(echo "$INFORMATION" | awk '{print $1}' | sort -u)
  # Para cada proceso unico
  for i in $SID_UNIQ; do
    # Inicializacion de variables
    sid_group_count=0
    pid_leader=""
    pid_user="?"
    pid_tty="?"
    
    # Recorremos cada proceso
    for j in $SID_TABLE; do 
      # Si el sid de los procesos coinciden con el sid del proceso unico
      if [ "$i" = "$j" ]; then
        # Contamos los grupos de procesos
        sid_group_count=$((sid_group_count + 1))
        # Obtenemos la linea de cada proceso, siempre y cuando el pid sea igual al sid
        line=$(echo "$INFORMATION" | awk -v sid="$i" '$1 == sid && $1 == $3')
        # Obtenemos el pid
        pid=$(echo "$line" | awk '{print $3}')
        # Obtenemos el usuario
        pid_user=$(echo "$line" | awk '{print $4}')
        # Obtenemos la terminal
        tty=$(echo "$line" | awk '{print $5}')
        # Comprobamos si hay terminal
        pid_tty=$(echo "$tty" | awk '$5 != "0" && $5 != "?"')
        # Obtenemos el comando
        pid_command=$(echo "$line" | awk '{print $7}')
        # Si no hay terminal asociada
        if [ -z "$tty" ]; then
          pid_tty="?"
        fi 
        if [ -z "$pid_user" ]; then
          pid_user="?"
        fi 
        if [ -z "$pid" ]; then
          pid="?"
        fi 
        if [ -z "$pid_command" ]; then
          pid_command="?"
        fi 
      fi
    done
    echo -e "$i\t\t$sid_group_count\t  $pid $pid_user $pid_tty\t$pid_command"
  done
  exit 0
fi