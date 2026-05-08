import os
import sys
import datetime
from dotenv import load_dotenv
import pyodbc

# Chargement des variables d'environnement
load_dotenv()

def get_connection():
    """Établit la connexion à la base de données SQL Server."""
    try:
        # Tentative de récupération des variables standard
        server = os.getenv('DB_SERVER') or os.getenv('DB_HOST')
        database = os.getenv('DB_DATABASE') or os.getenv('DB_NAME')
        username = os.getenv('DB_USERNAME') or os.getenv('DB_UID') or os.getenv('DB_USER')
        password = os.getenv('DB_PASSWORD') or os.getenv('DB_PWD') or os.getenv('DB_PASS')
        
        if not all([server, database, username, password]):
            print("❌ Erreur: Variables d'environnement manquantes dans le fichier .env")
            print(f"   Requis: DB_SERVER/HOST, DB_DATABASE/NAME, DB_UID/USER, DB_PWD/PASS")
            return None

        conn_str = f'DRIVER={{SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'
        return pyodbc.connect(conn_str)
    except Exception as e:
        print(f"❌ Erreur de connexion : {e}")
        return None

def format_time(dt):
    """Formate un objet datetime, time, str ou None pour l'affichage."""
    if dt is None:
        return "NULL"
    if isinstance(dt, str):
        return dt
    try:
        return dt.strftime('%H:%M:%S')
    except AttributeError:
        return str(dt)

def manage_shifts():
    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()
    
    # 1. Lecture des valeurs LIVE
    query = """
    SELECT ShiftId, MondayStart, TuesdayStart, WednesdayStart, ThursdayStart, FridayStart, SaturdayStart, SundayStart 
    FROM fpusnr_shifttimes 
    WHERE ShiftId = 1
    """
    
    try:
        cursor.execute(query)
        row = cursor.fetchone()
        
        if not row:
            print("⚠️ Aucun enregistrement trouvé pour ShiftId = 1.")
            return

        print("\n=== VALEURS ACTUELLES (LIVE) - SHIFT ID 1 ===")
        days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        current_values = list(row[1:])
        
        for i, day in enumerate(days):
            print(f"{day:10} : {format_time(current_values[i])}")

        # 2. Préparation du changement
        print("\n=== CHANGEMENTS PROPOSÉS (06:01 pour la semaine) ===")
        proposed = []
        for i, day in enumerate(days):
            if i < 5: # Semaine (Lundi à Vendredi)
                val = "06:01:00"
            else: # Weekend (Samedi, Dimanche)
                val = format_time(current_values[i])
            proposed.append(val)
            print(f"{day:10} : {format_time(current_values[i])} -> {val}")

        # 3. Confirmation de l'utilisateur
        confirm = input("\n👉 Voulez-vous appliquer ces changements ? (O/N) : ")
        
        if confirm.upper() == 'O':
            update_query = """
            UPDATE fpusnr_shifttimes
            SET 
                MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
                TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
                WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
                ThursdayStart = CAST(CONVERT(VARCHAR(10), ThursdayStart, 120) + ' 06:01:00' AS DATETIME2),
                FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2)
            WHERE ShiftId = 1
            """
            cursor.execute(update_query)
            conn.commit()
            print("✅ Mise à jour effectuée avec succès !")
            
            # Vérification finale
            cursor.execute(query)
            new_row = cursor.fetchone()
            print("\n=== NOUVELLES VALEURS EN BASE ===")
            for i, day in enumerate(days):
                print(f"{day:10} : {format_time(new_row[i+1])}")
        else:
            print("🛑 Opération annulée.")

    except Exception as e:
        print(f"❌ Erreur lors de l'exécution : {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    # Vérification des dépendances
    try:
        import pyodbc
        import dotenv
    except ImportError:
        print("❌ Dépendances manquantes. Veuillez installer :")
        print("   pip install pyodbc python-dotenv")
        sys.exit(1)
        
    manage_shifts()
