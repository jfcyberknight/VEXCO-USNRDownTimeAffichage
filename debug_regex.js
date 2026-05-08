const fs = require('fs');
const content = fs.readFileSync(process.argv[2], 'utf8');
const lines = content.split('\n');
console.log("First 100 lines matching regex:");
lines.slice(0, 1000).forEach((line, i) => {
    const match = line.match(/\s+([a-zA-Z0-9_]+)\s+Fichiers et rubriques/);
    if (match) {
        console.log(`Line ${i+1}: ${match[1]}`);
    }
});
