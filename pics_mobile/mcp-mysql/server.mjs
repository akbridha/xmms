#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import mysql from "mysql2/promise";

// MySQL connection configuration from environment variables
const config = {
  host: process.env.MYSQL_HOST || "127.0.0.1",
  port: parseInt(process.env.MYSQL_PORT || "33306"),
  user: process.env.MYSQL_USER || "mcp_read",
  password: process.env.MYSQL_PASSWORD || "readOnly123",
  database: process.env.MYSQL_DATABASE || "db_pltmp_doc",
};

// Create MySQL connection pool
const pool = mysql.createPool({
  ...config,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// Create MCP server
const server = new Server(
  {
    name: "mysql-readonly-pics-mobile",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "query_database",
        description:
          "Execute a read-only SQL query on the PicsMobile database. Only SELECT queries are allowed. Returns query results as JSON.",
        inputSchema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "The SQL SELECT query to execute (read-only)",
            },
          },
          required: ["query"],
        },
      },
      {
        name: "list_tables",
        description: "List all tables in the PicsMobile database",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "describe_table",
        description: "Get the structure/schema of a specific table",
        inputSchema: {
          type: "object",
          properties: {
            table_name: {
              type: "string",
              description: "The name of the table to describe",
            },
          },
          required: ["table_name"],
        },
      },
      {
        name: "get_inspection_details",
        description:
          "Get complete inspection details for a specific schedule ID including all items and results",
        inputSchema: {
          type: "object",
          properties: {
            schedule_id: {
              type: "number",
              description: "The schedule ID to query inspection details for",
            },
          },
          required: ["schedule_id"],
        },
      },
      {
        name: "get_statistics",
        description:
          "Get statistics about the database (total items, schedules, results, inspector activity)",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "get_inspector_activity",
        description:
          "Get activity summary for a specific inspector or all inspectors",
        inputSchema: {
          type: "object",
          properties: {
            inspector: {
              type: "string",
              description: "Inspector ID/NIK (optional, leave empty for all inspectors)",
            },
          },
        },
      },
      {
        name: "get_items_by_section",
        description:
          "Get all inspection items filtered by section",
        inputSchema: {
          type: "object",
          properties: {
            section: {
              type: "string",
              description: "Section name to filter (e.g., 'PLANT VESSEL')",
            },
          },
          required: ["section"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "query_database": {
        const query = args.query?.trim();
        if (!query) {
          throw new Error("Query parameter is required");
        }

        // Security: Only allow SELECT queries
        if (!query.toUpperCase().startsWith("SELECT")) {
          throw new Error(
            "Only SELECT queries are allowed for read-only access"
          );
        }

        const [rows] = await pool.execute(query);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(rows, null, 2),
            },
          ],
        };
      }

      case "list_tables": {
        const [rows] = await pool.execute(
          "SELECT TABLE_NAME, TABLE_ROWS, CREATE_TIME, UPDATE_TIME FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME",
          [config.database]
        );
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(rows, null, 2),
            },
          ],
        };
      }

      case "describe_table": {
        const tableName = args.table_name;
        if (!tableName) {
          throw new Error("table_name parameter is required");
        }

        const [rows] = await pool.execute(`DESCRIBE ${tableName}`);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(rows, null, 2),
            },
          ],
        };
      }

      case "get_inspection_details": {
        const scheduleId = args.schedule_id;
        if (!scheduleId) {
          throw new Error("schedule_id parameter is required");
        }

        const query = `
          SELECT 
            s.id as schedule_id,
            s.equipment_id,
            s.date as schedule_date,
            s.actual_start_time,
            s.actual_end_time,
            s.inspection_count,
            i.id as item_id,
            i.section,
            i.part_of_check,
            i.item,
            i.details_items,
            i.activity,
            i.value as expected_value,
            i.status_risk,
            r.id as result_id,
            r.result as actual_result,
            r.status,
            r.inspector,
            r.validator,
            r.validation_time,
            r.created_at as inspection_time
          FROM pics_schedule s
          LEFT JOIN pics_result r ON s.id = r.schedule_id
          LEFT JOIN pics_item i ON r.item_id = i.id
          WHERE s.id = ?
          ORDER BY i.order, i.id
        `;

        const [rows] = await pool.execute(query, [scheduleId]);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(rows, null, 2),
            },
          ],
        };
      }

      case "get_statistics": {
        const [itemCount] = await pool.execute(
          "SELECT COUNT(*) as count FROM pics_item WHERE valid = 0"
        );
        const [scheduleCount] = await pool.execute(
          "SELECT COUNT(*) as count FROM pics_schedule WHERE valid = 1"
        );
        const [resultCount] = await pool.execute(
          "SELECT COUNT(*) as count FROM pics_result"
        );
        const [finishedResults] = await pool.execute(
          "SELECT COUNT(*) as count FROM pics_result WHERE status = 'finish'"
        );
        const [topInspectors] = await pool.execute(
          "SELECT inspector, COUNT(*) as inspection_count, COUNT(DISTINCT schedule_id) as schedules_worked FROM pics_result GROUP BY inspector ORDER BY inspection_count DESC LIMIT 5"
        );
        const [recentSchedules] = await pool.execute(
          "SELECT id, equipment_id, date, inspection_count FROM pics_schedule WHERE valid = 1 ORDER BY date DESC LIMIT 5"
        );

        const stats = {
          total_items: itemCount[0].count,
          total_schedules: scheduleCount[0].count,
          total_results: resultCount[0].count,
          finished_results: finishedResults[0].count,
          completion_rate: (finishedResults[0].count / resultCount[0].count * 100).toFixed(2) + '%',
          top_inspectors: topInspectors,
          recent_schedules: recentSchedules,
          database: config.database,
        };

        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(stats, null, 2),
            },
          ],
        };
      }

      case "get_inspector_activity": {
        const inspector = args.inspector;
        
        let query;
        let params = [];
        
        if (inspector) {
          query = `
            SELECT 
              r.inspector,
              COUNT(*) as total_inspections,
              COUNT(DISTINCT r.schedule_id) as schedules_worked,
              SUM(CASE WHEN r.status = 'finish' THEN 1 ELSE 0 END) as completed,
              MIN(r.created_at) as first_inspection,
              MAX(r.created_at) as last_inspection
            FROM pics_result r
            WHERE r.inspector = ?
            GROUP BY r.inspector
          `;
          params = [inspector];
        } else {
          query = `
            SELECT 
              r.inspector,
              COUNT(*) as total_inspections,
              COUNT(DISTINCT r.schedule_id) as schedules_worked,
              SUM(CASE WHEN r.status = 'finish' THEN 1 ELSE 0 END) as completed
            FROM pics_result r
            GROUP BY r.inspector
            ORDER BY total_inspections DESC
          `;
        }

        const [rows] = await pool.execute(query, params);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(rows, null, 2),
            },
          ],
        };
      }

      case "get_items_by_section": {
        const section = args.section;
        if (!section) {
          throw new Error("section parameter is required");
        }

        const query = `
          SELECT 
            id,
            section,
            part_of_check,
            \`order\`,
            item,
            details_items,
            activity,
            value as expected_value,
            status_risk
          FROM pics_item
          WHERE section = ? AND valid = 0
          ORDER BY \`order\`, id
        `;

        const [rows] = await pool.execute(query, [section]);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(rows, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  try {
    // Test database connection
    await pool.query("SELECT 1");
    console.error("✓ Connected to MySQL database");

    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("✓ PicsMobile MCP MySQL Server running");
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
}

main();
