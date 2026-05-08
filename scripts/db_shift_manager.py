import os
import sys
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

def format_time(dt):
    """Formate un objet datetime, time, str ou None pour l'affichage."""
    if dt is None:
        return "NULL"
    if isinstance(dt, str):
        # On essaie d'extraire juste l'heure si c'est une chaîne datetime
        if ' ' in dt:
            return dt.split(' ')[1].split('.')[0]
        return dt
    try:
        return dt.strftime('%H:%M:%S')
    except AttributeError:
        return str(dt)

def get_snapshot(cursor):
    """Récupère l'état actuel de la table pour le ShiftId 1."""
    query = """
    SELECT MondayStart, MondayEnd, 
           TuesdayStart, TuesdayEnd, 
           WednesdayStart, WednesdayEnd, 
           ThursdayStart, ThursdayEnd, 
           FridayStart, FridayEnd, 
           SaturdayStart, SaturdayEnd, 
           SundayStart, SundayEnd 
    FROM fpusnr_shifttimes 
    WHERE ShiftId = 1
    """
    cursor.execute(query)
    return cursor.fetchone()

def manage_shifts():
    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()
    days_fr = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
    
    try:
        # 1. Capture du Snapshot Initial
        row = get_snapshot(cursor)
        if not row:
            print("⚠️ Aucun enregistrement trouvé pour ShiftId = 1.")
            return

        print("\n📸 SNAPSHOT DES VALEURS ACTUELLES (AVANT)")
        print(f"{'Jour':12} | {'Début':10} | {'Fin':10}")
        print("-" * 38)
        for i, day in enumerate(days_fr):
            print(f"{day:12} | {format_time(row[i*2]):10} | {format_time(row[i*2+1]):10}")

        # 2. Détermination du mode (Lecture ou Correction)
        is_fix_mode = len(sys.argv) > 1 and sys.argv[1] == "--fix"

        if is_fix_mode:
            print("\n🛠️ PRÉPARATION DE LA CORRECTION (CIBLE)")
            print(f"{'Jour':12} | {'Début':10} | {'Fin':10}")
            print("-" * 38)
            
            # On définit les cibles
            # Semaine : 06:01 -> 16:00
            # Weekend : NULL -> NULL
            targets = []
            for i in range(7):
                if i < 5: # Semaine
                    targets.append(("06:01:00", "16:00:00"))
                else: # Weekend
                    targets.append((format_time(row[i*2]), format_time(row[i*2+1])))
            
            for i, day in enumerate(days_fr):
                print(f"{day:12} | {targets[i][0]:10} | {targets[i][1]:10}")

            confirm = input("\n👉 Voulez-vous appliquer ces changements et écraser les anciennes valeurs ? (O/N) : ")
            
            if confirm.upper() == 'O':
                update_query = """
                UPDATE fpusnr_shifttimes
                SET 
                    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
                    MondayEnd   = CAST(CONVERT(VARCHAR(10), MondayEnd, 120)   + ' 16:00:00' AS DATETIME2),
                    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
                    TuesdayEnd   = CAST(CONVERT(VARCHAR(10), TuesdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
                    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
                    WednesdayEnd   = CAST(CONVERT(VARCHAR(10), WednesdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
                    ThursdayStart = CAST(CONVERT(VARCHAR(10), ThursdayStart, 120) + ' 06:01:00' AS DATETIME2),
                    ThursdayEnd   = CAST(CONVERT(VARCHAR(10), ThursdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
                    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2),
                    FridayEnd   = CAST(CONVERT(VARCHAR(10), FridayEnd, 120)   + ' 16:00:00' AS DATETIME2)
                WHERE ShiftId = 1
                """
                cursor.execute(update_query)
                conn.commit()
                print("\n✅ Correction appliquée !")

                # 3. Snapshot Final pour Validation
                final_row = get_snapshot(cursor)
                print("\n📸 SNAPSHOT DES VALEURS FINALES (APRÈS)")
                print(f"{'Jour':12} | {'Début':10} | {'Fin':10}")
                print("-" * 38)
                for i, day in enumerate(days_fr):
                    print(f"{day:12} | {format_time(final_row[i*2]):10} | {format_time(final_row[i*2+1]):10}")
            else:
                print("🛑 Opération annulée.")
        else:
            print("\n💡 Note: Utilisez 'npm run verify-and-fix-shifts' pour appliquer des corrections.")

    except Exception as e:
        print(f"❌ Erreur lors de l'exécution : {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    manage_shifts()
