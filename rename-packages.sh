#!/bin/bash

# Controllo degli argomenti passati (vecchio e nuovo nome del pacchetto, nome del progetto, etc.)
if [ "$#" -ne 6 ]; then
  echo "Devi fornire il vecchio e il nuovo pacchetto, il groupId, l'artifactId e la versione."
  echo "Esempio: ./rename-packages.sh com.oldpackage com.newpackage com.oldgroup my-project 1.0.0"
  exit 1
fi

# Parametri passati
OLD_PACKAGE="com.package"
NEW_PACKAGE=$1
OLD_MODULE_PART="\${project-name}"
NEW_MODULE_PART=$2
GROUP_ID=$3
ARTIFACT_ID=$4
VERSION=$5
PROJECT_NAME=$6

# Rinominare la directory del modulo (solo se contiene la parte specificata)
for DIR in $(find . -type d -name "*$OLD_MODULE_PART*"); do
  NEW_DIR=$(echo "$DIR" | sed "s/$OLD_MODULE_PART/$NEW_MODULE_PART/g")
  echo "Rinominando la directory $DIR in $NEW_DIR"
  mv "$DIR" "$NEW_DIR"
done

# Rinominare i moduli nel pom.xml principale
sed -i "s/<module>$OLD_MODULE<\/module>/<module>$NEW_MODULE_PART<\/module>/g" pom.xml

# Rinominare i moduli nei rispettivi pom.xml
for MODULE in $(find . -type f -name "pom.xml"); do
  sed -i "s/<artifactId>$OLD_MODULE<\/artifactId>/<artifactId>$NEW_MODULE_PART<\/artifactId>/g" "$MODULE"
  sed -i "s/$OLD_PACKAGE/$NEW_PACKAGE/g" "$MODULE"
done

# Rinominare i package e le classi
find . -type d -name "$OLD_PACKAGE" -exec bash -c 'mv "$0" "$(echo $0 | sed s/$OLD_PACKAGE/$NEW_PACKAGE/)"' {} \;
find . -type f -name "*.java" -exec sed -i "s/package $OLD_PACKAGE;/package $NEW_PACKAGE;/g" {} \;

# Rinominare le dipendenze nei pom.xml
find . -type f -name "pom.xml" -exec sed -i "s/<artifactId>$OLD_MODULE<\/artifactId>/<artifactId>$NEW_MODULE<\/artifactId>/g" {} \;

# Trova tutti i file .java nel progetto
echo "Rinominando pacchetti e classi da '$OLD_PACKAGE' a '$NEW_PACKAGE'..."

# Passaggio 1: Rinominare le dichiarazioni dei pacchetti nei file .java
find . -type f -name "*.java" | while read file; do
  # Modifica la dichiarazione del package nel file
  sed -i '' "s/package $OLD_PACKAGE/package $NEW_PACKAGE/" "$file"

  # Rinominare i file se necessario (se il nome del file include il pacchetto)
  if [[ "$file" == *"$OLD_PACKAGE"* ]]; then
    # Rinominare il percorso dei file
    new_file=$(echo "$file" | sed "s/$OLD_PACKAGE/$NEW_PACKAGE/")
    mv "$file" "$new_file"
    echo "Rinominato $file in $new_file"
  fi
done

# Passaggio 2: Rinominare tutte le occorrenze di classi nel codice
find . -type f -name "*.java" | while read file; do
  # Trova tutte le occorrenze della vecchia classe e sostituiscile con la nuova
  sed -i '' "s/$OLD_PACKAGE/$NEW_PACKAGE/g" "$file"
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

# Passaggio 2: Rinominare le dichiarazioni di pacchetto nei file .java
echo "Rinominando pacchetti e classi da '$OLD_PACKAGE' a '$NEW_PACKAGE'..."

find . -type f -name "*.java" | while read file; do
  # Modifica la dichiarazione del package nel file
  sed -i '' "s/package $OLD_PACKAGE/package $NEW_PACKAGE/" "$file"

  # Rinominare i file se necessario (se il nome del file include il pacchetto)
  if [[ "$file" == *"$OLD_PACKAGE"* ]]; then
    # Rinominare il percorso dei file
    new_file=$(echo "$file" | sed "s/$OLD_PACKAGE/$NEW_PACKAGE/")
    mv "$file" "$new_file"
    echo "Rinominato $file in $new_file"
  fi
done

# Passaggio 3: Rinominare tutte le occorrenze di classi nel codice
find . -type f -name "*.java" | while read file; do
  # Trova tutte le occorrenze della vecchia classe e sostituiscile con la nuova
  sed -i '' "s/$OLD_PACKAGE/$NEW_PACKAGE/g" "$file"
done

echo "Operazione completata. Pacchetti, classi e pom.xml sono stati rinominati."
