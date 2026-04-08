import mysql from "mysql2/promise";

const config = {
  host: "127.0.0.1",
  port: 33306,
  user: "mcp_read",
  password: "readOnly123",
  database: "db_pltmp_doc",
};

async function queryTableStructures() {
  let connection;
  
  try {
    console.log("🔗 Connecting to MySQL...");
    connection = await mysql.createConnection(config);
    console.log("✅ Connected!\n");

    const tables = ["pics_item", "pics_schedule", "pics_result"];

    for (const table of tables) {
      console.log(`\n${"=".repeat(80)}`);
      console.log(`📊 TABLE: ${table}`);
      console.log(`${"=".repeat(80)}\n`);

      // Get table structure
      const [structure] = await connection.execute(`DESCRIBE ${table}`);
      
      console.log("📋 Structure:");
      console.table(structure);

      // Get row count
      const [countResult] = await connection.execute(
        `SELECT COUNT(*) as count FROM ${table}`
      );
      console.log(`\n📈 Total Rows: ${countResult[0].count}`);

      // Get sample data (first 3 rows)
      const [sampleData] = await connection.execute(
        `SELECT * FROM ${table} LIMIT 3`
      );
      
      if (sampleData.length > 0) {
        console.log("\n📝 Sample Data (first 3 rows):");
        console.table(sampleData);
      } else {
        console.log("\n⚠️  No data in this table");
      }

      // Get indexes
      const [indexes] = await connection.execute(`SHOW INDEX FROM ${table}`);
      if (indexes.length > 0) {
        console.log("\n🔑 Indexes:");
        const indexInfo = indexes.map(idx => ({
          Key_name: idx.Key_name,
          Column_name: idx.Column_name,
          Non_unique: idx.Non_unique === 0 ? 'UNIQUE' : 'NON-UNIQUE',
          Index_type: idx.Index_type
        }));
        console.table(indexInfo);
      }
    }

    console.log(`\n${"=".repeat(80)}`);
    console.log("✅ Query completed successfully!");
    console.log(`${"=".repeat(80)}\n`);

  } catch (error) {
    console.error("\n❌ Error:", error.message);
    if (error.code === "ECONNREFUSED") {
      console.error("   → Check if MySQL container is running");
      console.error("   → Verify the port (33306) is correct");
    } else if (error.code === "ER_ACCESS_DENIED_ERROR") {
      console.error("   → Check username and password");
    } else if (error.code === "ER_BAD_DB_ERROR") {
      console.error("   → Database 'db_pltmp_doc' does not exist");
    } else if (error.code === "ER_NO_SUCH_TABLE") {
      console.error("   → One or more tables do not exist in the database");
    }
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log("🔌 Connection closed");
    }
  }
}

queryTableStructures();
