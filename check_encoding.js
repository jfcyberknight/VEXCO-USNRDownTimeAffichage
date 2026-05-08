const fs = require('fs');
const buf = fs.readFileSync(process.argv[2]);
console.log(buf.slice(0, 10).toString('hex'));
console.log(buf.slice(0, 100).toString('utf16le'));
console.log(buf.slice(0, 100).toString('utf8'));
