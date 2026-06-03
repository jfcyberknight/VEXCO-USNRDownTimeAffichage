import os
from dotenv import load_dotenv
import pyodbc

# Chargement des variables d'environnement
load_dotenv()

def get_connection():
    """Établit la connexion à la base de données SQL Server."""
    try:
        server = os.getenv('DB_SERVER') or os.getenv('DB_HOST')
        database = os.getenv('DB_DATABASE') or os.getenv('DB_NAME')
        username = os.getenv('DB_USERNAME') or os.getenv('DB_UID') or os.getenv('DB_USER')
        password = os.getenv('DB_PASSWORD') or os.getenv('DB_PWD') or os.getenv('DB_PASS')
        
        if not all([server, database, username, password]):
            print("❌ Erreur: Variables d'environnement manquantes dans le fichier .env")
            return None

        conn_str = f'DRIVER={{SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
        return pyodbc.connect(conn_str)
    except Exception as e:
        print(f"❌ Erreur de connexion : {e}")
        return None

def verify_historical_fixes():
    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()
    print("🔍 Analyse de la base de données pour les corrections historiques (Lundi 06:01 à 07:00)...")

    tables_view = ["fpusnr_downtime_view", "fpusnr_downtime_view_autre", "fpusnr_Arc_downtime_view", "fpusnr_arc_downtime_view_autre"]
    tables_traiter = ["fpusnr_downtime_view_traiter", "fpusnr_arc_downtime_view_traiter"]

    total_to_update = 0
    updates_by_table = {}

    # 1. Vérification des tables de type View / Autre
    for table in tables_view:
        try:
            query = f"""
            SELECT COUNT(*) 
            FROM {table}
            WHERE DATEPART(WEEKDAY, StartTime) = 2
              AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
              AND Shift = 'Nuit'
            """
            cursor.execute(query)
            count = cursor.fetchone()[0]
            updates_by_table[table] = count
            total_to_update += count
        except Exception as e:
            print(f"⚠️ Erreur de lecture sur {table} : {e}")

    # 2. Vérification des tables de type Traiter
    for table in tables_traiter:
        try:
            query = f"""
            SELECT COUNT(*) 
            FROM {table}
            WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
              AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
              AND fld_Quart = 3
            """
            cursor.execute(query)
            count = cursor.fetchone()[0]
            updates_by_table[table] = count
            total_to_update += count
        except Exception as e:
            print(f"⚠️ Erreur de lecture sur {table} : {e}")

    # 3. Affichage des résultats
    print("\n📊 TABLEAU SYNTHÉTIQUE DES CORRECTIONS REQUISES :")
    print("-" * 55)
    print(f"{'Nom de la Table':35} | {'Enregistrements à corriger':20}")
    print("-" * 55)
    for table, count in updates_by_table.items():
        color = "🔴" if count > 0 else "🟢"
        print(f"{table:35} | {color} {count:<18}")
    print("-" * 55)
    print(f"Total général à corriger : {total_to_update} ligne(s)\n")

    # 4. Affichage d'exemples si nécessaire
    if total_to_update > 0:
        print("💡 Quelques exemples d'enregistrements qui seront modifiés :")
        for table in tables_view:
            if updates_by_table.get(table, 0) > 0:
                print(f"\nExemples de la table {table} :")
                query = f"""
                SELECT TOP 3 StartTime, Shift AS OldShift, DateTime AS OldDateTime,
                    'Jour' AS NewShift, CAST(StartTime AS DATE) AS NewDateTime
                FROM {table}
                WHERE DATEPART(WEEKDAY, StartTime) = 2
                  AND CAST(StartTime AS TIME) >= '06:01:00' AND CAST(StartTime AS TIME) < '07:00:00'
                  AND Shift = 'Nuit'
                """
                cursor.execute(query)
                for row in cursor.fetchall():
                    print(f"  - StartTime: {row[0]} | Shift: {row[1]} -> {row[3]} | Date: {row[2]} -> {row[4]}")
                    
        for table in tables_traiter:
            if updates_by_table.get(table, 0) > 0:
                print(f"\nExemples de la table {table} :")
                query = f"""
                SELECT TOP 3 fld_DateDebut, fld_Quart AS OldQuart, fld_DateQuart AS OldDateQuart,
                    1 AS NewQuart, CAST(fld_DateDebut AS DATE) AS NewDateQuart
                FROM {table}
                WHERE DATEPART(WEEKDAY, fld_DateDebut) = 2
                  AND CAST(fld_DateDebut AS TIME) >= '06:01:00' AND CAST(fld_DateDebut AS TIME) < '07:00:00'
                  AND fld_Quart = 3
                """
                cursor.execute(query)
                for row in cursor.fetchall():
                    print(f"  - Début: {row[0]} | Quart ID: {row[1]} -> {row[3]} | Date: {row[2]} -> {row[4]}")
        print("\n👉 Exécutez 'npm run fix-historical-shifts' pour appliquer les corrections.")
    else:
        print("🎉 Tout est déjà en ordre ! Aucun enregistrement n'a besoin d'être corrigé.")

    conn.close()

if __name__ == "__main__":
    verify_historical_fixes()
