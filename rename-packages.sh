#!/bin/bash

# Controllo degli argomenti passati (vecchio e nuovo nome del pacchetto, nome del progetto, etc.)
if [ "$#" -ne 7 ]; then
  echo "Devi fornire il vecchio e il nuovo pacchetto, il groupId, l'artifactId e la versione."
  echo "Esempio: ./rename-packages.sh com.oldpackage com.newpackage com.oldgroup my-project 1.0.0"
  exit 1
fi

# Parametri passati
OLD_PACKAGE="project-name"
NEW_PACKAGE=$1
OLD_MODULE_PART="\${project-name}"
NEW_MODULE_PART=$2
GROUP_ID=$3
ARTIFACT_ID=$4
VERSION=$5
PROJECT_NAME=$6
OLD_COMPANY="company-name"
NEW_COMPANY=$7


# Rinominare la directory del modulo (solo se contiene la parte specificata)
for DIR in $(find . -type d -name "*$OLD_MODULE_PART*"); do
  NEW_DIR=$(echo "$DIR" | sed "s/$OLD_MODULE_PART/$NEW_MODULE_PART/g")
  echo "Rinominando la directory $DIR in $NEW_DIR"
  mv "$DIR" "$NEW_DIR"
done

# Modifica del pom.xml per sostituire i placeholder
echo "Sostituendo i placeholder nel pom.xml..."

find . -type f -name "pom.xml" | while read pom_file; do
  # Sostituzione dei placeholder nel pom.xml
  sed -i '' "s/\${project.groupId}/$GROUP_ID/g" "$pom_file"
  sed -i '' "s/\${project.artifactId}/$ARTIFACT_ID/g" "$pom_file"
  sed -i '' "s/\${project.version}/$VERSION/g" "$pom_file"
  sed -i '' "s/\${project.name}/$PROJECT_NAME/g" "$pom_file"
  echo "Aggiornato il file $pom_file"
done

echo "Operazione completata. Pacchetti, classi e pom.xml sono stati rinominati."

# ----------------------------------- #

# Trova tutti i moduli Maven nel progetto
find . -name "pom.xml" -exec dirname {} \; > modules.txt

# Rinominare i pacchetti nei moduli trovati
while read MODULE_DIR; do
  echo "Processing module: $MODULE_DIR"

  # 1. Rinominare le directory che corrispondono al vecchio pacchetto
    echo "Rinominando directory in $MODULE_DIR..."
    find "$MODULE_DIR/src/main/java" -type d -name "$OLD_COMPANY" -exec bash -c 'mv "$0" "${0/'$OLD_COMPANY'/'$NEW_COMPANY'}"' {} \;
    find "$MODULE_DIR/src/main/java" -type d -name "$OLD_PACKAGE" -exec bash -c 'mv "$0" "${0/'$OLD_PACKAGE'/'$NEW_PACKAGE'}"' {} \;

    # 2. Rinominare i riferimenti nei file Java
    echo "Aggiornando i riferimenti nel codice Java..."
    find "$MODULE_DIR/src/main/java" -type f -name "*.java" -exec sed -i "s|package $OLD_COMPANY.$OLD_PACKAGE|package $NEW_COMPANY.$NEW_PACKAGE|g" {} \;

    # 3. Aggiornare i riferimenti nel file pom.xml del modulo
    echo "Aggiornando il file pom.xml del modulo..."
    sed -i "s|$OLD_COMPANY.$OLD_PACKAGE|$NEW_COMPANY.$NEW_PACKAGE|g" "$MODULE_DIR/pom.xml"

    # 4. Se ci sono altri pom.xml nei moduli figli, aggiorna anche quelli
    find "$MODULE_DIR" -name "pom.xml" -exec sed -i "s|$OLD_COMPANY.$OLD_PACKAGE|$NEW_COMPANY.$NEW_PACKAGE|g" {} \;

done < modules.txt

# Rimuovi il file temporaneo che contiene i moduli
rm modules.txt

echo "Rinominamento completato per tutti i moduli!"