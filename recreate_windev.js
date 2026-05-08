const fs = require('fs');
const path = require('path');

function parseAnalysis(filePath) {
    // Read as UTF-16LE because of the FFFE BOM
    const content = fs.readFileSync(filePath, 'utf16le');
    const lines = content.split(/\r?\n/);

    const tables = {};
    
    // 1. Find all table names
    let tableNames = [];
    lines.forEach(line => {
        // Use a regex that allows for various characters but focuses on table prefixes
        const match = line.match(/(fpusnr_\w+|tbl_\w+)/);
        if (match) {
            const tname = match[1];
            if (!tableNames.includes(tname)) {
                tableNames.push(tname);
            }
        }
    });

    // Filter table names: they should appear in a "Rubriques du fichier" header
    tableNames = tableNames.filter(tname => {
        return lines.some(line => line.includes(`Rubriques du fichier ${tname}`));
    });

    console.log(`Verified tables: ${tableNames.length}`);

    tableNames.forEach(tname => {
        tables[tname] = [];
        let inFields = false;
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            
            if (line.includes(`Rubriques du fichier ${tname}`)) {
                inFields = true;
                continue;
            }

            if (inFields) {
                // End of fields: next section
                if (line.includes("Rubriques du fichier") && !line.includes(tname)) {
                    inFields = false;
                    continue;
                }
                if (line.includes("Partie 2")) {
                    inFields = false;
                    continue;
                }

                // Skip page headers
                if (line.includes("Projet") || line.includes("Partie") || /^\d{4}-\d{2}-\d{2}/.test(line.trim())) {
                    continue;
                }

                const trimmed = line.trim();
                if (!trimmed) continue;

                const parts = trimmed.split(/\s{2,}/);
                if (parts.length >= 2) {
                    const fieldName = parts[0];
                    if (["Libellé", "Type", "Rubrique", "Rubriques"].includes(fieldName)) continue;
                    
                    if (!/^[a-zA-Z0-9_$]+$/.test(fieldName)) continue;

                    let fieldType = "";
                    let fieldSize = "";
                    
                    for (let j = 1; j < parts.length; j++) {
                        if (/(Chaîne|Entier|Décimal|Date|Identifiant|Réel|Mémo|Clé)/i.test(parts[j])) {
                            fieldType = parts[j];
                            if (parts[j+1] && /^\d+$/.test(parts[j+1])) {
                                fieldSize = parts[j+1];
                            }
                            break;
                        }
                    }

                    if (fieldType) {
                        if (!tables[tname].some(f => f.name === fieldName)) {
                            tables[tname].push({
                                name: fieldName,
                                type: fieldType,
                                size: fieldSize
                            });
                        }
                    }
                }
            }
        }
    });

    return tables;
}

function generateWLanguageClass(tname, fields) {
    let classCode = `${tname} est une Classe\n`;
    // Mandatory UUID for Rule 1
    classCode += `    m_uuid est un chaîne // Identifiant unique stable (UUID)\n`;
    
    fields.forEach(f => {
        let wtype = "chaîne";
        if (f.type.includes("Entier")) wtype = "entier";
        else if (f.type.includes("Réel")) wtype = "réel";
        else if (f.type.includes("Décimal")) wtype = "numérique";
        else if (f.type.includes("Date et Heure")) wtype = "DateHeure";
        else if (f.type.includes("Date")) wtype = "Date";
        else if (f.type.includes("Identifiant")) wtype = "entier";
        else if (f.type.includes("Mémo")) wtype = "chaîne";
        
        classCode += `    m_${f.name} est un ${wtype}\n`;
    });

    classCode += `\nFIN\n\n`;
    classCode += `PROCÉDURE Constructeur()\n`;
    classCode += `// Initialisation du UUID si nouveau\n`;
    classCode += `SI m_uuid = "" ALORS m_uuid = DonneGUID(guidFormatDashed)\n\n`;
    
    classCode += `PROCÉDURE Destructeur()\n\n`;
    
    classCode += `PROCÉDURE ChargerParUUID(sUUID)\n`;
    classCode += `SI HLitRecherchePremier(${tname}, uuid, sUUID) ALORS\n`;
    classCode += `    FichierVersMémoire(objet, ${tname})\n`;
    classCode += `    RENVOYER Vrai\n`;
    classCode += `FIN\n`;
    classCode += `RENVOYER Faux\n\n`;
    
    classCode += `PROCÉDURE Enregistrer()\n`;
    classCode += `MémoireVersFichier(objet, ${tname})\n`;
    classCode += `RENVOYER HEnregistre(${tname})\n`;

    return classCode;
}

function generateSQLQuery(tname, fields) {
    const cols = ["uuid", ...fields.map(f => f.name)].join(", ");
    return `-- Requête pour ${tname} (Architect Standard)\nSELECT ${cols}\nFROM ${tname}\nWHERE uuid = {pUuid}\n`;
}

function generateReportDesc(tname, fields) {
    let desc = `Description de l'état : Liste des ${tname}\nFormat : A4 Paysage\nCorps de l'état :\n`;
    desc += `- [Rubrique] uuid (Identifiant Unique)\n`;
    fields.forEach(f => {
        desc += `- [Rubrique] ${f.name} (${f.type})\n`;
    });
    return desc;
}

const analysisFile = path.resolve(__dirname, '..', '..', 'GDS', 'USNRDowntimeAffichage', 'Dossier', 'USNRDowntimeAffichage.TXT');
const outputDir = path.resolve(__dirname, 'Recreation');

if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}
if (!fs.existsSync(path.join(outputDir, 'Classes'))) fs.mkdirSync(path.join(outputDir, 'Classes'), { recursive: true });
if (!fs.existsSync(path.join(outputDir, 'Requetes'))) fs.mkdirSync(path.join(outputDir, 'Requetes'), { recursive: true });
if (!fs.existsSync(path.join(outputDir, 'Etats'))) fs.mkdirSync(path.join(outputDir, 'Etats'), { recursive: true });

const data = parseAnalysis(analysisFile);

let schemaSql = "";

Object.keys(data).forEach(tname => {
    const fields = data[tname];
    if (fields.length === 0) return;

    fs.writeFileSync(path.join(outputDir, 'Classes', `${tname}.wdc.txt`), generateWLanguageClass(tname, fields));
    fs.writeFileSync(path.join(outputDir, 'Requetes', `Get_${tname}.wdr.sql`), generateSQLQuery(tname, fields));
    fs.writeFileSync(path.join(outputDir, 'Etats', `Etat_${tname}.wde.txt`), generateReportDesc(tname, fields));

    schemaSql += `CREATE TABLE ${tname} (\n`;
    schemaSql += `    uuid UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,\n`;
    
    const colDefs = fields.map(f => {
        let sqlType = "NVARCHAR(MAX)";
        if (f.type.includes("Chaîne")) {
            const size = f.size || "255";
            sqlType = `NVARCHAR(${size})`;
        } else if (f.type.includes("Entier sur 4")) sqlType = "INT";
        else if (f.type.includes("Entier sur 2")) sqlType = "SMALLINT";
        else if (f.type.includes("Décimal")) sqlType = "DECIMAL(18,4)";
        else if (f.type.includes("Date et Heure")) sqlType = "DATETIME2";
        else if (f.type.includes("Date")) sqlType = "DATE";
        else if (f.type.includes("Identifiant")) sqlType = "INT"; // Legacy ID preserved but not PK
        else if (f.type.includes("Réel")) sqlType = "FLOAT";
        
        return `    ${f.name} ${sqlType}`;
    });
    schemaSql += colDefs.join(",\n");
    schemaSql += "\n);\n\n";
});


fs.writeFileSync(path.join(outputDir, 'Schema.sql'), schemaSql);

console.log(`Generated recreation files for ${Object.keys(data).filter(k => data[k].length > 0).length} tables in ${outputDir}`);
