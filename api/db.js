const fs = require("fs");
const path = require("path");
const sql = require("mssql");

function loadProperties(filePath) {
  const text = fs.readFileSync(filePath, "utf8");
  const props = {};
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const i = trimmed.indexOf("=");
    if (i === -1) continue;
    props[trimmed.slice(0, i).trim()] = trimmed.slice(i + 1).trim();
  }
  return props;
}

const props = loadProperties(path.join(__dirname, "configure.properties"));

const config = {
  user: props["db.user"],
  password: props["db.password"],
  server: props["db.server"],
  port: Number(props["db.port"] || 1433),
  database: props["db.name"],
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

let pool;

async function getPool() {
  if (pool) return pool;
  pool = await sql.connect(config);
  console.log("Đã kết nối SQL Server:", config.database);
  return pool;
}

module.exports = { getPool, props };