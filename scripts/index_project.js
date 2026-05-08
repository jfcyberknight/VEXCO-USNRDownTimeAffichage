const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration Architecte Senior
const COLLECTION_NAME = "vexco_usnr_downtime";
const SUPPORTED_EXTENSIONS = new Set([
    ".py", ".js", ".ts", ".md", ".css", ".html", ".json", 
    ".yml", ".yaml", ".sql", ".ps1", ".wdc.txt", ".wdr.sql", ".wde.txt"
]);
const IGNORE_DIRS = new Set([".git", "node_modules", "vendor", "dist", "build"]);

function generateUUID(content) {
    // Règle 1: Identifiants stables basés sur le contenu (Namespace-like)
    return crypto.createHash('sha256').update(content).digest('hex').substring(0, 32);
}

function chunkCode(text, filename, chunkSize = 1500) {
    const blockStarts = [
        /^[a-z0-9_]+ est une Classe/mi,
        /^PROCÉDURE/mi,
        /^CREATE TABLE/mi,
        /^-- Requête/mi,
        /^Description de l'état/mi
    ];

    // Split logic based on block starts
    let lines = text.split(/\r?\n/);
    let chunks = [];
    let currentChunk = `File: ${filename}\n\n`;

    for (let line of lines) {
        const isBlockStart = blockStarts.some(regex => regex.test(line));
        
        if (isBlockStart && currentChunk.length > 100) {
            chunks.push(currentChunk.trim());
            currentChunk = `File: ${filename}\n\n`;
        }

        if (currentChunk.length + line.length > chunkSize && currentChunk.length > 200) {
            chunks.push(currentChunk.trim());
            currentChunk = `File: ${filename}\n\n`;
        }
        currentChunk += line + "\n";
    }

    if (currentChunk.trim()) {
        chunks.push(currentChunk.trim());
    }
    
    return chunks;
}

function walk(dir, callback) {
    fs.readdirSync(dir).forEach( f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        if (isDirectory) {
            if (!IGNORE_DIRS.has(f)) walk(dirPath, callback);
        } else {
            callback(path.join(dir, f));
        }
    });
}

function indexProject() {
    console.log(`🚀 Indexation intelligente du projet ${COLLECTION_NAME}...`);
    
    const projectRoot = path.resolve(__dirname, '..');
    let indexData = [];
    let fileCount = 0;

    walk(projectRoot, (filePath) => {
        const ext = path.extname(filePath).toLowerCase();
        const fullExt = filePath.endsWith('.wdc.txt') ? '.wdc.txt' : 
                      filePath.endsWith('.wdr.sql') ? '.wdr.sql' : 
                      filePath.endsWith('.wde.txt') ? '.wde.txt' : ext;

        if (!SUPPORTED_EXTENSIONS.has(fullExt) && !SUPPORTED_EXTENSIONS.has(ext)) return;

        const relPath = path.relative(projectRoot, filePath);
        
        try {
            const content = fs.readFileSync(filePath, 'utf8');
            if (!content.trim()) return;

            fileCount++;
            const chunks = chunkCode(content, relPath);
            
            chunks.forEach((chunk, i) => {
                const chunkId = generateUUID(`${relPath}_${i}_${crypto.createHash('md5').update(chunk).digest('hex')}`);
                
                indexData.push({
                    id: chunkId,
                    metadata: {
                        path: relPath,
                        filename: path.basename(filePath),
                        extension: fullExt,
                        chunk_index: i,
                        total_chunks: chunks.length,
                        project: "VEXCO-USNRDownTimeAffichage"
                    },
                    content: chunk
                });
            });
        } catch (e) {}
    });

    const outputFile = path.join(__dirname, 'codebase_index.json');
    fs.writeFileSync(outputFile, JSON.stringify(indexData, null, 2), 'utf8');
    
    console.log(`✨ Indexation terminée !`);
    console.log(`   📁 Fichiers traités : ${fileCount}`);
    console.log(`   🧩 Chunks indexés   : ${indexData.length}`);
    console.log(`   💾 Index sauvegardé : scripts/codebase_index.json`);
}

indexProject();
