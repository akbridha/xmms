# Database Structure - db_pltmp_doc

Hasil query struktur database dari container MySQL (2026-04-08)

## 📊 Tables Overview

| Table | Rows | Description |
|-------|------|-------------|
| **pics_item** | 306 | Template item inspeksi (master data) |
| **pics_schedule** | 18 | Jadwal inspeksi per equipment |
| **pics_result** | 563 | Hasil inspeksi (transaksi) |

## 🔗 Database Relationships

```
┌─────────────────────┐
│  pics_schedule      │
│  (Jadwal Inspeksi)  │
│  - id               │◄─────┐
│  - equipment_id     │      │
│  - date             │      │ schedule_id (FK)
│  - inspection_count │      │
└─────────────────────┘      │
                             │
                             │
                       ┌─────────────────────┐
                       │  pics_result        │
                       │  (Hasil Inspeksi)   │
                       │  - id               │
                       │  - schedule_id   ───┘
                       │  - item_id       ───┐
                       │  - result           │
                       │  - status           │  item_id (FK)
                       │  - inspector        │
                       └─────────────────────┘
                                              │
                                              │
                             ┌────────────────▼────┐
                             │  pics_item          │
                             │  (Template Item)    │
                             │  - id               │
                             │  - section          │
                             │  - part_of_check    │
                             │  - item             │
                             └─────────────────────┘
```

## 📋 Table Details

### 1. pics_item (Master Template)

**Purpose**: Master data template untuk item-item yang harus diinspeksi

**Columns**:
```
id              INT             PK, Auto Increment
section         VARCHAR(100)    Kategori section (e.g., "PLANT VESSEL")
part_of_check   VARCHAR(255)    Bagian yang dicek (e.g., "BAGIAN ATAS")
order           INT             Urutan item
item            VARCHAR(255)    Nama item (e.g., "BODY AND CHASSIS")
status_risk     VARCHAR(100)    Level risk (e.g., "A", "B", "C")
details_items   TEXT            Detail sub-item (e.g., "Main Chasis")
activity        VARCHAR(255)    Aktivitas yang dilakukan (e.g., "Check")
value           VARCHAR(255)    Expected value (e.g., "No Crack")
valid           TINYINT(1)      Status validitas (0/1)
created_at      TIMESTAMP       Default CURRENT_TIMESTAMP
updated_at      TIMESTAMP       Auto update on change
created_by      VARCHAR(100)    User pembuat
updated_by      VARCHAR(100)    User pengubah terakhir
```

**Indexes**:
- PRIMARY KEY: id

**Sample Data**:
```
ID: 1
Section: PLANT VESSEL
Part of Check: BAGIAN ATAS
Item: BODY AND CHASSIS
Details: Main Chasis
Activity: Check
Value: No Crack
```

**Total Records**: 306 items

---

### 2. pics_schedule (Jadwal Inspeksi)

**Purpose**: Menyimpan jadwal inspeksi untuk setiap equipment

**Columns**:
```
id                  INT             PK, Auto Increment
equipment_id        INT             FK ke table equipment
date                DATE            Tanggal jadwal inspeksi
actual_start_time   DATETIME        Waktu mulai aktual inspeksi
actual_end_time     DATETIME        Waktu selesai aktual inspeksi
inspection_count    INT             Jumlah inspeksi yang dilakukan
valid               TINYINT         Status valid (default: 1)
created_at          TIMESTAMP       Default CURRENT_TIMESTAMP
updated_at          TIMESTAMP       Auto update on change
created_by          VARCHAR(100)    User pembuat (e.g., "ARAFIK")
updated_by          VARCHAR(100)    User pengubah terakhir
```

**Indexes**:
- PRIMARY KEY: id
- INDEX: equipment_id

**Sample Data**:
```
ID: 67113
Equipment ID: 90
Date: 2026-04-01
Inspection Count: 1
Created By: ARAFIK
```

**Total Records**: 18 schedules

---

### 3. pics_result (Hasil Inspeksi)

**Purpose**: Menyimpan hasil inspeksi per item untuk setiap schedule

**Columns**:
```
id                  INT             PK, Auto Increment
schedule_id         INT             FK ke pics_schedule
item_id             INT             FK ke pics_item
result              VARCHAR(255)    Hasil inspeksi (value yang diisi)
duration            VARCHAR(50)     Durasi inspeksi
status              VARCHAR(100)    Status (e.g., "finish")
inspector           VARCHAR(50)     NIK/ID inspector (e.g., "0115118")
validator           VARCHAR(100)    NIK/ID validator
validation_time     DATETIME        Waktu validasi
created_at          TIMESTAMP       Default CURRENT_TIMESTAMP
updated_at          TIMESTAMP       Auto update on change
created_by          VARCHAR(100)    User pembuat
updated_by          VARCHAR(100)    User pengubah terakhir
```

**Indexes**:
- PRIMARY KEY: id
- INDEX: schedule_id (named 'equipment_id')
- INDEX: item_id

**Sample Data**:
```
ID: 48749
Schedule ID: 67115
Item ID: 191
Result: 32323
Status: finish
Inspector: 0115118
```

**Total Records**: 563 results

---

## 🔍 Common Queries

### Get inspection details for a schedule
```sql
SELECT 
    s.id as schedule_id,
    s.equipment_id,
    s.date as schedule_date,
    i.section,
    i.part_of_check,
    i.item,
    i.details_items,
    r.result,
    r.status,
    r.inspector
FROM pics_schedule s
LEFT JOIN pics_result r ON s.id = r.schedule_id
LEFT JOIN pics_item i ON r.item_id = i.id
WHERE s.id = 67115
ORDER BY i.order;
```

### Get inspector activity summary
```sql
SELECT 
    inspector,
    COUNT(DISTINCT schedule_id) as total_schedules,
    COUNT(*) as total_items_inspected,
    SUM(CASE WHEN status = 'finish' THEN 1 ELSE 0 END) as completed_items
FROM pics_result
GROUP BY inspector
ORDER BY total_items_inspected DESC;
```

### Get completion rate per schedule
```sql
SELECT 
    s.id,
    s.equipment_id,
    s.date,
    s.inspection_count,
    COUNT(r.id) as items_filled,
    COUNT(r.id) * 100.0 / s.inspection_count as completion_percentage
FROM pics_schedule s
LEFT JOIN pics_result r ON s.id = r.schedule_id
GROUP BY s.id;
```

---

## 🎯 Data Flow

1. **Setup Phase**: Admin membuat template items di `pics_item`
2. **Scheduling Phase**: System/Admin membuat schedule di `pics_schedule` dengan `equipment_id` dan `date`
3. **Inspection Phase**: Inspector mengisi form, data masuk ke `pics_result` dengan reference ke `schedule_id` dan `item_id`
4. **Validation Phase**: Validator approve hasil di `pics_result` (update `validator` dan `validation_time`)

---

## 📊 Statistics (as of 2026-04-08)

- **Total Item Templates**: 306 items across multiple sections
- **Active Schedules**: 18 equipment schedules
- **Inspection Results**: 563 completed item inspections
- **Average Items per Schedule**: 31.3 items (563/18)
- **Completion Rate**: Varies per schedule (check `inspection_count` vs actual results)

---

## 🔐 Database Connection Info

```bash
Host: 127.0.0.1
Port: 33306
Database: db_pltmp_doc
User: mcp_read (read-only)
```

---

## 📝 Notes

- Table names use `pics_` prefix
- All tables have audit fields: `created_at`, `updated_at`, `created_by`, `updated_by`
- Foreign key relationships managed at application level (no explicit FK constraints in schema)
- `valid` field used for soft deletes
- Timestamps use MySQL TIMESTAMP with automatic defaults
