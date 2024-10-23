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


# Funciones
infosession () {
  ps -e -o sid,pgid,pid,user,tty,%mem,cmd --no-headers | tr -s " " 
}                                                   #awk '$1 != 0'


# Inicialización de variables
INFORMATION=$(infosession)
HELP=0
ZERO=0
USR=""
ERROR=0
INVALID_OPTION=0

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
        USR="$1"
        if [ -z "$USR" ]; then
          ERROR=1
          INVALID_OPTION="-u"
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

if [ -n "$USR" ]; then
  INFORMATION=$(echo "$INFORMATION" |awk -v user="$USR" '$4 == user')
fi



#Se está sobreescribiendo INFORMATION. Uso de variables auxiliares?

echo "$INFORMATION" 
                    #Hacer opciones separadas y luego una opcion juntas?
                    #Al ejecutar, se añaden:
                       #105869 106281 106281 usuario pts/0 0.0 /bin/bash ./infosession.sh -u root
                       #105869 106281 106282 usuario pts/0 0.0 /bin/bash ./infosession.sh -u root
                    #Por que no se filtran con -u root ?
                    #Si hago $USR me muestra todos los de usuario y: 105593 105593 105593 root ? 0.0 sshd: usuario [priv], lo mismo con "$USR", usuario, "usuario"
                    #Con sudo se muestran tanto root como usuario