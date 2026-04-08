# MCP MySQL Server - PicsMobile

MCP (Model Context Protocol) server untuk membaca database MySQL dari container Docker. Server ini memberikan akses read-only ke database inspeksi PicsMobile (**db_pltmp_doc**) untuk AI tools seperti GitHub Copilot.

## Database Structure

Database **db_pltmp_doc** berisi 3 tables utama:
- **pics_item** (306 rows) - Template item inspeksi
- **pics_schedule** (18 rows) - Jadwal inspeksi equipment
- **pics_result** (563 rows) - Hasil inspeksi

Lihat [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md) untuk dokumentasi lengkap struktur database.

## Prerequisites

- Node.js >= 18.0.0
- MySQL container yang sudah berjalan
- MySQL user dengan akses read-only

## Setup

### 1. Install Dependencies

```bash
cd mcp-mysql
npm install
```

### 2. Konfigurasi VS Code

Tambahkan konfigurasi MCP ke VS Code settings. Buka Command Palette (Ctrl+Shift+P) dan pilih **"Preferences: Open User Settings (JSON)"**, lalu tambahkan:

```json
{
  "github.copilot.chat.mcp.servers": {
    "pics-mobile-mysql": {
      "command": "node",
      "args": ["C:/Users/Lenovo/Main/PicsMobile/pics_mobile/mcp-mysql/server.mjs"],
      "env": {
        "MYSQL_HOST": "127.0.0.1",
        "MYSQL_PORT": "33306",
        "MYSQL_USER": "mcp_read",
        "MYSQL_PASSWORD": "readOnly123",
        "MYSQL_DATABASE": "pics_mobile_db"
      }
    }
  }
}
```

**Sesuaikan environment variables** dengan konfigurasi MySQL container Anda:
- `MYSQL_HOST`: Host MySQL (biasanya 127.0.0.1)
- `MYSQL_PORT`: Port yang di-forward dari container (default: 33306)
- `MYSQL_USER`: User MySQL dengan akses read-only (default: mcp_read)
- `MYSQL_PASSWORD`: Password user MySQL (default: readOnly123)
- `MYSQL_DATABASE`: Nama database (default: db_pltmp_doc)

### 3. Restart VS Code

Setelah menambahkan konfigurasi, restart VS Code agar MCP server aktif.

## Verifikasi Setup

### Test Koneksi Manual

Untuk test koneksi database secara manual:

```bash
cd mcp-mysql
# Set environment variables
$env:MYSQL_HOST="127.0.0.1"
$env:MYSQL_PORT="33306"
$env:MYSQL_USER="mcp_read"
$env:MYSQL_PASSWORD="readOnly123"
$env:MYSQL_DATABASE="pics_mobile_db"

# Run server
node server.mjs
```

### Test dengan Copilot

Setelah setup, Anda bisa bertanya ke GitHub Copilot Chat:

```
@workspace list all tables in the database
```

```
@workspace show me database statistics
```

```
@workspace get inspection details for schedule 67115
```

## Available Tools

MCP server ini menyediakan 7 tools untuk query database:

### 1. `query_database`
Execute SQL SELECT query (read-only)
```json
{
  "query": "SELECT * FROM pics_schedule WHERE date >= '2026-04-01' LIMIT 10"
}
```

### 2. `list_tables`
List semua tables dalam database dengan info jumlah rows dan timestamps

### 3. `describe_table`
Get struktur/schema dari table tertentu
```json
{
  "table_name": "pics_result"
}
```

### 4. `get_inspection_details`
Get complete inspection details untuk schedule tertentu (dengan join ke items dan results)
```json
{
  "schedule_id": 67115
}
```

### 5. `get_statistics`
Get statistik database: total items, schedules, results, completion rate, top inspectors, recent schedules

### 6. `get_inspector_activity`
Get activity summary untuk inspector tertentu atau semua inspectors
```json
{
  "inspector": "0115118"  // Optional, kosongkan untuk semua
}
```

### 7. `get_items_by_section`
Get semua inspection items untuk section tertentu
```json
{
  "section": "PLANT VESSEL"
}
```

## Security

- Server ini **read-only**, hanya menerima SELECT queries
- Gunakan MySQL user dengan privilege SELECT saja
- Tidak ada akses write/update/delete ke database

## Troubleshooting

### Connection Error

Jika muncul error koneksi:

1. Pastikan container MySQL berjalan: `docker ps`
2. Cek port forwarding: `docker port <container_name>`
3. Test koneksi manual dengan MySQL client
4. Verifikasi credentials di environment variables

### MCP Server Not Found

1. Pastikan path absolut di settings benar
2. Restart VS Code setelah mengubah settings
3. Check VS Code Developer Tools (Help > Toggle Developer Tools) untuk error messages

### Dependencies Error

```bash
cd mcp-mysql
npm install --force
```

## File Structure
April 2026
```

### 2. Analyze Inspection Details
```
@workspace get complete inspection details for schedule 67115
```

### 3. Inspector Activity
```
@workspace show activity summary for inspector 0115118
```

### 4. Items by Section
```
@workspace list all inspection items in PLANT VESSEL section
```db_pltmp_doc

### 5. Database Statistics
```
@workspace show database statistics including completion rate
```

### 6. Custom Query
```
@workspace query: SELECT s.id, s.equipment_id, COUNT(r.id) as completed_items FROM pics_schedule s LEFT JOIN pics_result r ON s.id = r.schedule_id GROUP BY s.id
| `MYSQL_DATABASE` | pics_mobile_db | Database name |

## Contoh Penggunaan

### 1. Query Schedules
```
@workspace show all schedules from the database
```

### 2. Analyze Executions
```
@workspace show me execution statistics for the last 7 days
```

### 3. Inspect Table Structure
```
@workspace what is the schema of the executions table?
```

### 4. Custom Query
```
@workspace query: SELECT inspector, COUNT(*) as total FROM executions GROUP BY inspector
```
