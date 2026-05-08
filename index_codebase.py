import os
import sys
import uuid
import hashlib
import re
import json
from pathlib import Path

# Tentative d'import des dépendances nécessaires
try:
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("❌ Erreur: Dépendances manquantes.")
    print("Veuillez installer les bibliothèques requises :")
    print("pip install qdrant-client sentence-transformers")
    sys.exit(1)

# --- Configuration Architecte ---
QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY", None)
COLLECTION_NAME = "codebase"
MODEL_NAME = "all-MiniLM-L6-v2"  # Taille 384
VECTOR_SIZE = 384

# Chemins
REPO_ROOT = Path(__file__).resolve().parent
IGNORE_DIRS = {".git", "node_modules", "vendor", "brain", "assets", "tmp", "__pycache__", ".vercel", "dist", "build", ".claude", ".mcp", ".next"}
IGNORE_FILES = {"package-lock.json", "yarn.lock", "pnpm-lock.yaml"}
SUPPORTED_EXTENSIONS = {
    ".py", ".js", ".ts", ".md", ".css", ".html", ".json", 
    ".yml", ".yaml", ".env", ".ps1", ".bat", ".wdc.txt", ".wdr.sql", ".wde.txt"
}

# --- Initialisation des Singletons ---
_client = None
_model = None

def get_client():
    global _client
    if _client is None:
        _client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)
    return _client

def get_model():
    global _model
    if _model is None:
        print(f"📥 Chargement du modèle d'embedding ({MODEL_NAME})...")
        _model = SentenceTransformer(MODEL_NAME)
    return _model

def init_collection():
    client = get_client()
    try:
        client.get_collection(COLLECTION_NAME)
    except Exception:
        print(f"📦 Création de la collection '{COLLECTION_NAME}'...")
        client.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=models.VectorParams(size=VECTOR_SIZE, distance=models.Distance.COSINE),
        )

def chunk_text(text, filename, chunk_size=1000, overlap=100):
    # Découpage sémantique : priorité aux blocs logiques
    # Patterns pour WinDev, SQL et Markdown
    block_starts = [
        r"(?i)^[a-z0-9_]+ est une Classe",
        r"(?i)^PROCÉDURE",
        r"(?i)^CREATE TABLE",
        r"(?i)^-- Requête",
        r"(?i)^# ",
        r"\n\s*\n"
    ]
    combined_pattern = "|".join(block_starts)
    
    parts = re.split(f"({combined_pattern})", text, flags=re.MULTILINE)
    
    chunks = []
    current_chunk = f"File: {filename}\n\n"
    
    for i in range(0, len(parts)):
        block = parts[i]
        if not block: continue
        
        if len(current_chunk) + len(block) > chunk_size and len(current_chunk) > 100:
            chunks.append(current_chunk.strip())
            current_chunk = f"File: {filename}\n\n"
        
        current_chunk += block
            
    if current_chunk.strip():
        chunks.append(current_chunk.strip())
            
    return chunks

def get_language(ext):
    mapping = {
        ".py": "python", ".js": "javascript", ".ts": "typescript", 
        ".md": "markdown", ".css": "css", ".html": "html",
        ".json": "json", ".yml": "yaml", ".yaml": "yaml",
        ".ps1": "powershell", ".bat": "batch", ".sql": "sql",
        ".wdc.txt": "windev", ".wdr.sql": "sql", ".wde.txt": "windev"
    }
    return mapping.get(ext, "text")

def index_codebase():
    client = get_client()
    model = get_model()
    init_collection()
    
    print(f"🔍 Indexation intelligente autonome ({COLLECTION_NAME})...")
    
    points = []
    file_count = 0
    chunk_count = 0
    
    # On indexe à partir de la racine du dépôt
    INDEX_ROOT = REPO_ROOT
    
    for root, dirs, files in os.walk(INDEX_ROOT):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith(".")]
        
        for file in files:
            if file in IGNORE_FILES:
                continue
                
            # Gestion des extensions composées (ex: .wdc.txt)
            ext = "".join(Path(file).suffixes).lower()
            simple_ext = Path(file).suffix.lower()
            
            if ext not in SUPPORTED_EXTENSIONS and simple_ext not in SUPPORTED_EXTENSIONS:
                continue
                
            file_path = Path(root) / file
            if file_path.stat().st_size > 1_000_000: # 1MB limit
                continue
                
            try:
                rel_path = file_path.relative_to(INDEX_ROOT)
                content = file_path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
                
            if not content.strip():
                continue
                
            file_count += 1
            chunks = chunk_text(content, str(rel_path))
            
            for i, chunk in enumerate(chunks):
                # Règle 1 : UUID stable basé sur le chemin et l'index
                chunk_id_str = f"{rel_path}_{i}"
                q_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, chunk_id_str))
                
                # Génération de l'embedding
                vector = model.encode(chunk).tolist()
                
                payload = {
                    "path": str(rel_path),
                    "filename": file,
                    "extension": ext if ext in SUPPORTED_EXTENSIONS else simple_ext,
                    "language": get_language(ext if ext in SUPPORTED_EXTENSIONS else simple_ext),
                    "chunk_index": i,
                    "total_chunks": len(chunks),
                    "content": chunk,
                    "project": "VEXCO-USNRDownTimeAffichage"
                }
                
                points.append(models.PointStruct(id=q_id, vector=vector, payload=payload))
                chunk_count += 1
                
                if len(points) >= 25: # Batch plus petit pour la stabilité
                    try:
                        client.upsert(collection_name=COLLECTION_NAME, points=points)
                        points = []
                        print(f"   🚀 [{file_count:3d}] Fichiers traités... Chunks indexés : {chunk_count}", end="\r")
                    except Exception as e:
                        print(f"\n❌ Erreur lors de l'upsert : {e}")
                        points = []

    if points:
        client.upsert(collection_name=COLLECTION_NAME, points=points)
        
    print(f"\n✨ Indexation terminée !")
    print(f"   📁 Fichiers traités : {file_count}")
    print(f"   🧩 Chunks indexés   : {chunk_count}")

if __name__ == "__main__":
    index_codebase()
