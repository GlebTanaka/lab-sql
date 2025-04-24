QL Learning Repository

Welcome to my SQL learning repo! This project helps me track my progress while learning SQL development across different database engines. I'm working through tutorials and capturing my learnings, examples, and Docker setup commands.

## 📚 Overview
This repository is structured by database engine:

- `sqlite/` – Lightweight SQL engine, good for quick testing
- `postgresql/` – Powerful open-source relational database
- `mysql/` – Widely used database, often seen in web stacks
- `mssql/` – Microsoft's SQL Server
- `oracle/` – Oracle's enterprise database offering

Each folder contains setup instructions and example SQL scripts.

## ✅ Progress Checklist

- [x] Set up SQLite container and connect
- [x] Set up PostgreSQL container and connect
- [x] Set up MySQL container and connect
- [x] Set up MSSQL container and connect
- [x] Set up Oracle DB container and connect

## 🚀 Getting Started
Each database folder contains a `setup.sh` script to help spin up containers using Podman or Docker. Exercises are located in the `exercises/` subfolder.

Example for SQLite:
```sh
cd sqlite
./setup.sh
```

## 🗃️ Sample Exercise
```sql
-- 01_create_table.sql
CREATE TABLE products (
    product_name TEXT,
        price REAL
        );
```

## 💡 Notes
This repo is a personal learning project. Feel free to fork and use it for your own learning!

## 📄 License
MIT License

