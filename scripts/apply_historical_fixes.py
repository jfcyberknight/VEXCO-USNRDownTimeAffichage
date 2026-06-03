import os
import sys
import re
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

def apply_historical_fixes():
    conn = get_connection()
    if not conn:
        return

    cursor = conn.cursor()
    migration_file = os.path.join("migrations", "20260520_fix_historical_shifts.sql")
    
    if not os.path.exists(migration_file):
        print(f"❌ Fichier de migration introuvable : {migration_file}")
        conn.close()
        return

    print(f"📖 Lecture de la migration : {migration_file}...")
    try:
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        # Nettoyage et découpage par bloc d'exécution (séparés par GO)
        statements = re.split(r'\bGO\b', sql_content, flags=re.IGNORECASE)
        
        total_executed = 0
        for stmt in statements:
            stmt = stmt.strip()
            if not stmt:
                continue
                
            # Exécution de chaque instruction SQL individuelle
            print(f"⏳ Exécution du bloc SQL...")
            cursor.execute(stmt)
            
            # Affichage du nombre de lignes affectées si possible
            if cursor.rowcount > 0:
                print(f"✅ {cursor.rowcount} lignes mises à jour.")
                total_executed += cursor.rowcount
            else:
                print("✅ Exécuté (aucune ligne affectée ou retour non disponible).")

        conn.commit()
        print(f"\n🎉 Migration historique appliquée avec succès !")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Erreur lors de l'application de la migration : {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    apply_historical_fixes()
