import os
import sys
import uuid
import hashlib
import re
import json
from pathlib import Path

# Configuration Architecte Senior
COLLECTION_NAME = "vexco_usnr_downtime"
SUPPORTED_EXTENSIONS = {
    ".py", ".js", ".ts", ".md", ".css", ".html", ".json", 
    ".yml", ".yaml", ".sql", ".ps1", ".wdc.txt", ".wdr.sql", ".wde.txt"
}
IGNORE_DIRS = {".git", "node_modules", "vendor", "dist", "build", "Recreation_old"}

def generate_uuid(content):
    """Génère un UUID stable basé sur le contenu (Règle 1)."""
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, content))

def chunk_code(text, filename, chunk_size=1500):
    """
    Découpage sémantique intelligent pour le code (WLanguage, SQL).
    Priorise les blocs logiques (Classes, Procédures, Tables).
    """
    # Pattern pour repérer les débuts de blocs logiques
    # WinDev: Classe, Procédure | SQL: CREATE TABLE, SELECT
    block_starts = [
        r"(?i)^[a-z0-9_]+ est une Classe",
        r"(?i)^PROCÉDURE",
        r"(?i)^CREATE TABLE",
        r"(?i)^-- Requête",
        r"(?i)^Description de l'état"
    ]
    combined_pattern = "|".join(block_starts)
    
    # Split par les débuts de blocs tout en gardant le délimiteur
    parts = re.split(f"({combined_pattern})", text, flags=re.MULTILINE)
    
    chunks = []
    current_chunk = f"File: {filename}\n\n"
    
    for i in range(1, len(parts), 2):
        header = parts[i]
        body = parts[i+1] if i+1 < len(parts) else ""
        block = header + body
        
        if len(current_chunk) + len(block) > chunk_size and len(current_chunk) > 50:
            chunks.append(current_chunk.strip())
            current_chunk = f"File: {filename}\n\n"
        
        current_chunk += block
        
    if current_chunk.strip():
        chunks.append(current_chunk.strip())
        
    return chunks

def index_project():
    """
    Prépare l'indexation du projet. 
    Note: Ce script génère un fichier JSON d'indexation pour être consommé par le RAG.
    """
    print(f"🚀 Préparation de l'indexation pour {COLLECTION_NAME}...")
    
    project_root = Path(__file__).resolve().parent.parent
    index_data = []
    file_count = 0
    
    for root, dirs, files in os.walk(project_root):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        for file in files:
            ext = "".join(Path(file).suffixes).lower()
            if ext not in SUPPORTED_EXTENSIONS and Path(file).suffix not in SUPPORTED_EXTENSIONS:
                continue
                
            file_path = Path(root) / file
            rel_path = file_path.relative_to(project_root)
            
            try:
                # Gestion de l'encodage spécifique (UTF-16 pour les sources WinDev recréées)
                content = file_path.read_text(encoding="utf-8", errors="ignore")
            except Exception as e:
                continue
                
            if not content.strip():
                continue
                
            file_count += 1
            chunks = chunk_code(content, str(rel_path))
            
            for i, chunk in enumerate(chunks):
                chunk_id = generate_uuid(f"{rel_path}_{i}_{hashlib.md5(chunk.encode()).hexdigest()}")
                
                index_data.append({
                    "id": chunk_id,
                    "metadata": {
                        "path": str(rel_path),
                        "filename": file,
                        "extension": ext,
                        "chunk_index": i,
                        "total_chunks": len(chunks),
                        "project": "VEXCO-USNRDownTimeAffichage"
                    },
                    "content": chunk
                })

    # Sauvegarde locale de l'index pour vérification/moteur externe
    output_file = project_root / "scripts" / "codebase_index.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(index_data, f, indent=2, ensure_ascii=False)
        
    print(f"✨ Préparation terminée !")
    print(f"   📁 Fichiers traités : {file_count}")
    print(f"   🧩 Chunks générés   : {len(index_data)}")
    print(f"   💾 Index sauvegardé dans : scripts/codebase_index.json")

if __name__ == "__main__":
    index_project()
