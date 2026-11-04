const path = require("path");
const dotenv = require("dotenv");
const sql = require("mssql");

dotenv.config({ path: path.join(__dirname, "../.env") });

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 1433),
  database: process.env.DB_NAME,
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

module.exports = {
  getPool,
  config,
  apiPort: Number(process.env.PORT || 3000),
};