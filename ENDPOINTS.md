# Teguk API — Endpoint Documentation

**Stack:** ASP.NET Core / .NET 10 | **Auth:** JWT Bearer  
**Base URL:** `https://<your-domain>/api`  
**Auth Header:** `Authorization: Bearer <token>`

---

## Table of Contents
- [Auth](#1-auth)
- [Users](#2-users)
- [Water](#3-water)
- [Activity](#4-activity)
- [Reminder](#5-reminder)
- [Consultation](#6-consultation)
- [Health Expert](#7-health-expert)
- [Admin](#8-admin)
- [Statistics](#9-statistics)

---

## 1. Auth
> Base: `/api/auth` — Public (no token required)

### `POST /api/auth/register`
Register akun baru.

**Request Body:**
```json
{
  "fullName": "string",
  "email": "string",
  "password": "string",
  "age": 0,
  "weight": 0.0,
  "gender": "string",
  "activityLevel": "Low | Medium | High",
  "environmentCondition": "Normal | Hot",
  "role": "User | Admin"
}
```

**Response:**
```
"Register Success"
"Email already exists"
```

---

### `POST /api/auth/login`
Login dan dapatkan JWT token.

**Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response (success):**
```json
{
  "token": "string",
  "role": "string",
  "email": "string",
  "fullname": "string"
}
```

**Response (failed):**
```
"Email not found"
"Wrong password"
```

---

## 2. Users
> Base: `/api/users` — 🔒 Requires token

### `GET /api/users/profile`
🔒 Role: `User`  
Ambil profil user yang sedang login.

**Response:**
```json
{
  "id": "guid",
  "fullName": "string",
  "email": "string",
  "age": 0,
  "weight": 0.0,
  "gender": "string",
  "activityLevel": "string",
  "environmentCondition": "string",
  "targetWater": 0
}
```

---

### `PUT /api/users/profile`
🔒 Role: `User`  
Update profil user. Target air dihitung ulang otomatis:
- Base: `weight × 30` ml
- `+500` ml jika `activityLevel == "High"`
- `+300` ml jika `environmentCondition == "Hot"`

**Request Body:**
```json
{
  "fullName": "string",
  "age": 0,
  "weight": 0.0,
  "gender": "string",
  "activityLevel": "Low | Medium | High",
  "environmentCondition": "Normal | Hot"
}
```

**Response:**
```
"Profile updated"
"Profile not found"
```

---

### `GET /api/users/admin-only`
🔒 Role: `Admin`  
Test endpoint khusus Admin.

**Response:** `"Welcome Admin"`

---

### `GET /api/users/expert-only`
🔒 Role: `HealthExpert`  
Test endpoint khusus HealthExpert.

**Response:** `"Welcome Expert"`

---

## 3. Water
> Base: `/api/water` — 🔒 Role: `User`

### `POST /api/water`
Catat intake air minum.

**Request Body:**
```json
{
  "amountMl": 0
}
```

**Response:** `"Water intake added"`

---

### `GET /api/water/today`
Progress minum air hari ini.

**Response:**
```json
{
  "totalDrink": 0,
  "target": 0,
  "percentage": 0.0
}
```

---

### `GET /api/water/history`
Semua riwayat intake air user.

**Response:**
```json
[
  {
    "id": "guid",
    "accountId": "guid",
    "amountMl": 0,
    "drinkTime": "datetime"
  }
]
```

---

## 4. Activity
> Base: `/api/activity` — 🔒 Role: `User`

### `POST /api/activity`
Catat aktivitas fisik.

**Request Body:**
```json
{
  "activityType": "string",
  "activityLevel": "Low | Medium | High"
}
```

**Response:** `"Activity added"`

---

### `GET /api/activity`
Ambil semua aktivitas user (urut terbaru).

**Response:**
```json
[
  {
    "id": "guid",
    "accountId": "guid",
    "activityType": "string",
    "activityLevel": "string",
    "createdAt": "datetime"
  }
]
```

---

## 5. Reminder
> Base: `/api/reminder` — 🔒 Role: `User`

### `POST /api/reminder`
Buat reminder minum air.

**Request Body:**
```json
{
  "reminderTime": "HH:mm:ss",
  "intervalMinutes": 0
}
```

**Response:** `"Reminder created"`

---

### `GET /api/reminder`
Ambil semua reminder milik user.

**Response:**
```json
[
  {
    "id": "guid",
    "accountId": "guid",
    "reminderTime": "string",
    "intervalMinutes": 0
  }
]
```

---

### `DELETE /api/reminder/{id}`
Hapus reminder berdasarkan ID.

**Path Param:** `id` — guid reminder

**Response:**
```
"Reminder deleted"
"Reminder not found"
```

---

## 6. Consultation
> Base: `/api/consultation` — 🔒 Requires token

### `POST /api/consultation`
🔒 Role: `User`  
Buat sesi konsultasi dengan health expert.

**Request Body:**
```json
{
  "expertId": "guid"
}
```
> `expertId` = `AccountId` dari HealthExpert (didapat dari `GET /api/healthexpert/list`)

**Response:** `"Consultation created"`

---

### `POST /api/consultation/message`
🔒 Role: `User | HealthExpert`  
Kirim pesan dalam sesi konsultasi.

**Request Body:**
```json
{
  "consultationId": "guid",
  "message": "string"
}
```

**Response:** `"Message sent"`

---

### `GET /api/consultation/{id}`
🔒 Role: `User | HealthExpert`  
Ambil semua pesan dalam 1 sesi konsultasi.

**Path Param:** `id` — consultationId (guid)

**Response:**
```json
[
  {
    "sender": "string",
    "message": "string",
    "sentAt": "datetime"
  }
]
```

---

### `GET /api/consultation/my-consultations`
🔒 Role: `User | HealthExpert`  
Ambil semua konsultasi milik user/expert yang sedang login. Response berbeda berdasarkan role.

**Response (role = `User`):**
```json
[
  {
    "consultationId": "guid",
    "expertName": "string",
    "status": "string",
    "createdAt": "datetime"
  }
]
```

**Response (role = `HealthExpert`):**
```json
[
  {
    "consultationId": "guid",
    "userName": "string",
    "status": "string",
    "createdAt": "datetime"
  }
]
```

---

## 7. Health Expert
> Base: `/api/healthexpert` — 🔒 Requires token

### `POST /api/healthexpert/apply`
🔒 Role: `User`  
User mendaftar jadi HealthExpert.

**Request Body:**
```json
{
  "profession": "string",
  "specialization": "string",
  "licenseNumber": "string",
  "experienceYears": 0
}
```

**Response:**
```
"Application submitted"
"Application already exists"
```

---

### `GET /api/healthexpert/my-application`
🔒 Role: `User`  
Cek status pendaftaran expert milik user yang login.

**Response:**
```json
{
  "id": "guid",
  "accountId": "guid",
  "profession": "string",
  "specialization": "string",
  "licenseNumber": "string",
  "experienceYears": 0,
  "status": "Pending | Approved | Rejected"
}
```

---

### `GET /api/healthexpert/pending`
🔒 Role: `Admin`  
Lihat semua pendaftar expert yang masih berstatus Pending.

**Response:**
```json
[
  {
    "id": "guid",
    "profession": "string",
    "specialization": "string",
    "experienceYears": 0,
    "fullname": "string",
    "email": "string"
  }
]
```

---

### `PUT /api/healthexpert/approve/{id}`
🔒 Role: `Admin`  
Setujui pendaftaran expert. Role akun otomatis diubah ke `HealthExpert`.

**Path Param:** `id` — `HealthExpert.Id` (guid, **bukan** AccountId)

**Response:**
```
"Expert approved"
"Application not found"
```

---

### `PUT /api/healthexpert/reject/{id}`
🔒 Role: `Admin`  
Tolak pendaftaran expert.

**Path Param:** `id` — `HealthExpert.Id` (guid)

**Response:**
```
"Expert rejected"
"Application not found"
```

---

### `GET /api/healthexpert/list`
🔒 Role: `Any` (semua role, butuh token)  
Daftar semua HealthExpert yang sudah Approved.

**Response:**
```json
[
  {
    "expertId": "guid",
    "fullName": "string",
    "profession": "string",
    "specialization": "string",
    "experienceYears": 0
  }
]
```

---

## 8. Admin
> Base: `/api/admin` — 🔒 Role: `Admin`

### `GET /api/admin/dashboard`
Ringkasan statistik platform.

**Response:**
```json
{
  "totalUsers": 0,
  "totalExperts": 0,
  "totalConsultations": 0
}
```

---

### `GET /api/admin/users`
List semua akun dengan role `User`.

**Response:** Array of Account objects

---

### `GET /api/admin/experts`
List semua akun dengan role `HealthExpert`.

**Response:** Array of Account objects

---

## 9. Statistics
> Base: `/api/statistics` — 🔒 Role: `User`

### `GET /api/statistics/weekly`
Total intake air per hari dalam **7 hari terakhir**.

**Response:**
```json
[
  {
    "date": "date",
    "total": 0
  }
]
```

---

### `GET /api/statistics/monthly`
Total intake air per hari dalam **30 hari terakhir**.

**Response:**
```json
[
  {
    "date": "date",
    "total": 0
  }
]
```

---

## Quick Reference

| Method | Endpoint | Role |
|--------|----------|------|
| POST | /api/auth/register | Public |
| POST | /api/auth/login | Public |
| GET | /api/users/profile | User |
| PUT | /api/users/profile | User |
| GET | /api/users/admin-only | Admin |
| GET | /api/users/expert-only | HealthExpert |
| POST | /api/water | User |
| GET | /api/water/today | User |
| GET | /api/water/history | User |
| POST | /api/activity | User |
| GET | /api/activity | User |
| POST | /api/reminder | User |
| GET | /api/reminder | User |
| DELETE | /api/reminder/{id} | User |
| POST | /api/consultation | User |
| POST | /api/consultation/message | User, HealthExpert |
| GET | /api/consultation/{id} | User, HealthExpert |
| GET | /api/consultation/my-consultations | User, HealthExpert |
| POST | /api/healthexpert/apply | User |
| GET | /api/healthexpert/my-application | User |
| GET | /api/healthexpert/pending | Admin |
| PUT | /api/healthexpert/approve/{id} | Admin |
| PUT | /api/healthexpert/reject/{id} | Admin |
| GET | /api/healthexpert/list | Any |
| GET | /api/admin/dashboard | Admin |
| GET | /api/admin/users | Admin |
| GET | /api/admin/experts | Admin |
| GET | /api/statistics/weekly | User |
| GET | /api/statistics/monthly | User |
