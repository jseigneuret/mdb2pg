#!/bin/sh
#Script de migration de la base de données
#Ce script doit impérativement être exécuté par un administrateur ayant les droits 
# superutilisateur sur le SGBD postgres

DB="$2"
FILE="$1"

prepare_db (){
    #1) suppression de la base de données 
    echo "Suppression de la base de données $DB"
    dropdb $DB #--if-exists uniquement avec postgresql >= 9.2
    sleep 10
    #2) création de la base de données 
    echo "Creation de la base de données $DB"
    createdb $DB
    echo "CREATE DATABASE"
    sleep 10
    }

migrate_mdb2pg (){
    echo "file: $FILE"
    #3) dump des tables, des clés primaires et des index
    echo "Création de la structure de la base de données"
    mdb-schema "$FILE" postgres | \
    sed -e '/-- CREATE Relationships .../,/},\.$/d'\
    | psql -d $DB
    #4) injection des données dans la base
    echo "Injection des données provenant des différentes tables:"
    for table in $(mdb-tables -1 $FILE )
    do
        echo "Injection des données pour la table \"$table\""
        # pour l'injection SQL dans postgresql:
        # - l'option I est obligatoire
        # - l'option D "%Y-%m-%d %h:%M:%S" est obligatoire pour la compatibilité avec le format timestamp
        # - l'option q "'" est obligatoire car le texte doit être mis entre simple cote
        # - la commande sed -e "s/,\([0|1]\)\([,)]\)/,'\1'\2/g" permet de mettre entre cote 
        # les valeurs booléennes (elle est passée deux fois et c'est normal)
        mdb-export -I postgres -D "%Y-%m-%d %H:%M:%S" -q "'" "$FILE" "$table" | \
        sed -e "s/,\([0|1]\)\([,)]\)/,'\1'\2/g" |\
        sed -e "s/,\([0|1]\)\([,)]\)/,'\1'\2/g" |\
        psql -d $DB
    done
    #5) dump des containtes de clés étrangères
    mdb-schema "$FILE" postgres | sed -n '/-- CREATE Relationships .../,$p' | psql -d $DB
    }

run (){
    prepare_db
    migrate_mdb2pg
    }
run 
