# Quick Start - MCP MySQL untuk PicsMobile

Setup cepat agar GitHub Copilot bisa membaca database MySQL dari container Docker Anda.

## Langkah Setup (5 menit)

### 1. ✅ Dependencies Sudah Terinstall
Dependencies sudah terinstall di folder `mcp-mysql/`.

### 2. 🔧 Konfigurasi VS Code

1. Buka **Command Palette** (`Ctrl+Shift+P`)
2. Ketik: **"Preferences: Open User Settings (JSON)"**
3. Tambahkan konfigurasi ini (sesuaikan dengan kredensial MySQL container Anda):

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
        "MYSQL_DATABASE": "db_pltmp_doc"
      }
    }
  }
}
```

**⚠️ PENTING:** Ubah nilai environment variables sesuai dengan container MySQL Anda:
- `MYSQL_HOST`: Host MySQL (biasanya 127.0.0.1)
- `MYSQL_PORT`: Port yang di-forward ke localhost (cek dengan `docker ps`)
- `MYSQL_USER`: Username MySQL yang punya akses read (default: mcp_read)
- `MYSQL_PASSWORD`: Password user tersebut (default: readOnly123)
- `MYSQL_DATABASE`: Nama database yang ingin diakses (default: db_pltmp_doc untuk PicsMobile)

### 3. 🔄 Restart VS Code

Tutup dan buka kembali VS Code agar MCP server aktif.

### 4. ✨ Test Koneksi

Buka **GitHub Copilot Chat** dan coba:

```
@workspace list all tables in the database
```

Atau:

```
@workspace show me database statistics
```

## 🎯 Contoh Penggunaan

Setelah setup, Anda bisa bertanya ke Copilot:

- `@workspace berapa total inspections dalam database?`
- `@workspace tampilkan struktur table pics_result`
- `@workspace siapa inspector yang paling aktif?`
- `@workspace show inspection details for schedule 67115`
- `@workspace list all items in PLANT VESSEL section`
- `@workspace SELECT * FROM pics_schedule WHERE date >= '2026-04-01'`

## 🔍 Troubleshooting

### MCP Server tidak muncul
1. Pastikan path di `args` benar (gunakan forward slash `/` bukan backslash)
2. Restart VS Code
3. Check Developer Tools: Help > Toggle Developer Tools > Console

### Connection Failed
1. Pastikan container MySQL berjalan: `docker ps`
2. Test koneksi manual:
   ```bash
   mysql -h 127.0.0.1 -P 33306 -u mcp_read -p
   ```
3. Verifikasi port forwarding di container

### Permission Denied
Pastikan MySQL user punya privilege SELECT:
```sql
GRANT SELECT ON database_name.* TO 'mcp_read'@'%';
FLUSH PRIVILEGES;
```

## 📁 File Yang Dibuat

```
mcp-mysql/
├── server.mjs                      # MCP server code
├── package.json                    # Dependencies
├── package-lock.json               # Lock file
├── node_modules/                   # Installed packages
├── .gitignore                      # Git ignore
├── README.md                       # Full documentation
├── QUICKSTART.md                   # File ini
└── vscode-settings-example.json    # Example configuration
```

## 🚀 Next Steps

Setelah setup berhasil:
1. Gunakan Copilot untuk query database langsung dari chat
2. Minta Copilot analyze data patterns
3. Generate insights dari execution data
4. Debug data issues dengan bantuan AI

**Happy coding! 🎉**
