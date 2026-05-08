import os
import sys
import uuid
import hashlib
import re
from pathlib import Path
from qdrant_client.http import models

# Configuration des chemins
SCRIPTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPTS_DIR.parent
# On cherche le moteur dans darkmedia-x_studio à côté de darkmedia-x_scripts
ENGINE_DIR = REPO_ROOT.parent / "darkmedia-x_studio" / "Engine"

if not ENGINE_DIR.exists():
    # Fallback si on est dans une structure différente
    ENGINE_DIR = REPO_ROOT.parent / "darkmedia-x_studio" / "🎥 Engine"

sys.path.insert(0, str(ENGINE_DIR))

try:
    from qdrant_store import _get_client, _get_embedding
except ImportError:
    print(f"❌ Erreur: Impossible d'importer qdrant_store depuis {ENGINE_DIR}")
    print("Vérifiez que darkmedia-x_studio/Engine existe à côté de darkmedia-x_scripts.")
    sys.exit(1)

COLLECTION_NAME = "codebase"

# Fichiers et dossiers à ignorer
IGNORE_DIRS = {".git", "node_modules", "vendor", "brain", "assets", "tmp", "__pycache__", ".vercel", "dist", "build", ".claude", ".mcp", ".next"}
IGNORE_FILES = {"package-lock.json", "yarn.lock", "pnpm-lock.yaml"}
SUPPORTED_EXTENSIONS = {".py", ".js", ".ts", ".md", ".css", ".html", ".json", ".yml", ".yaml", ".env", ".ps1", ".bat"}

def init_codebase_collection():
    client = _get_client()
    try:
        client.get_collection(COLLECTION_NAME)
    except Exception:
        print(f"📦 Création de la collection '{COLLECTION_NAME}'...")
        client.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=models.VectorParams(size=384, distance=models.Distance.COSINE),
        )

def chunk_text(text, filename, chunk_size=1000, overlap=100):
    # Split by double newline for better logical blocks
    blocks = re.split(r'\n\s*\n', text)
    chunks = []
    current_chunk = f"File: {filename}\n\n"
    
    for block in blocks:
        if len(current_chunk) + len(block) < chunk_size:
            current_chunk += block + "\n\n"
        else:
            chunks.append(current_chunk.strip())
            current_chunk = f"File: {filename}\n\n" + block + "\n\n"
            
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    # Fallback for very long blocks
    final_chunks = []
    for c in chunks:
        if len(c) > chunk_size * 1.5:
            # Hard split
            for i in range(0, len(c), chunk_size - overlap):
                final_chunks.append(c[i:i + chunk_size])
        else:
            final_chunks.append(c)
            
    return final_chunks

def get_language(ext):
    mapping = {
        ".py": "python", ".js": "javascript", ".ts": "typescript", 
        ".md": "markdown", ".css": "css", ".html": "html",
        ".json": "json", ".yml": "yaml", ".yaml": "yaml",
        ".ps1": "powershell", ".bat": "batch"
    }
    return mapping.get(ext, "text")

def index_codebase():
    client = _get_client()
    init_codebase_collection()
    
    print(f"🔍 Indexation intelligente du codebase dans Qdrant ({COLLECTION_NAME})...")
    
    points = []
    file_count = 0
    chunk_count = 0
    
    # On indexe à partir du parent pour inclure tous les dépôts darkmedia-x_*
    INDEX_ROOT = REPO_ROOT.parent
    
    for root, dirs, files in os.walk(INDEX_ROOT):
        # Filtrer les dossiers ignorés
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith(".")]
        
        for file in files:
            if file in IGNORE_FILES:
                continue
            ext = os.path.splitext(file)[1].lower()
            if ext not in SUPPORTED_EXTENSIONS:
                continue
                
            file_path = Path(root) / file
            
            # Éviter les fichiers trop gros ou binaires par erreur
            if file_path.stat().st_size > 1_000_000: # 1MB limit
                continue
                
            try:
                rel_path = file_path.relative_to(INDEX_ROOT)
                content = file_path.read_text(encoding="utf-8", errors="ignore")
            except Exception as e:
                # print(f"   [⚠️] Erreur de lecture {file}: {e}")
                continue
                
            if not content.strip():
                continue
                
            file_count += 1
            chunks = chunk_text(content, str(rel_path))
            
            for i, chunk in enumerate(chunks):
                chunk_id = f"{rel_path}_{i}"
                q_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, chunk_id))
                
                vector = _get_embedding(chunk)
                
                payload = {
                    "path": str(rel_path),
                    "filename": file,
                    "extension": ext,
                    "language": get_language(ext),
                    "chunk_index": i,
                    "total_chunks": len(chunks),
                    "content": chunk
                }
                
                points.append(models.PointStruct(id=q_id, vector=vector, payload=payload))
                chunk_count += 1
                
                if len(points) >= 50:
                    try:
                        client.upsert(collection_name=COLLECTION_NAME, points=points)
                        points = []
                        # print(f"   🚀 [{file_count:3d}] Chunks indexés : {chunk_count}")
                    except Exception as e:
                        print(f"❌ Erreur lors de l'upsert : {e}")
                        points = []

    if points:
        client.upsert(collection_name=COLLECTION_NAME, points=points)
        
    print(f"\n✨ Indexation terminée !")
    print(f"   📁 Fichiers traités : {file_count}")
    print(f"   🧩 Chunks indexés   : {chunk_count}")

if __name__ == "__main__":
    index_codebase()
