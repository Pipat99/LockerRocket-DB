# LockerRocket-DB

Database design and a lightweight testing interface for the RocketLocker system
(310-2309 Database System — Group LockerRocket).

## Deliverables

- [Crow’s Foot ERD](docs/erd.md) describing the entities and their relationships.
- [PostgreSQL schema](database/schema.sql) defining the tables, keys, and constraints.
- A browser-based testing interface in `web/` for trying campus, member, locker,
  and reservation workflows.

## Database setup

Create a database, then apply the schema:

```sh
createdb lockerrocket
psql -d lockerrocket -f database/schema.sql
```

The schema targets PostgreSQL 14 or newer. It is intended to be applied once to
a new database; it does not drop existing objects.

## Web testing interface

Open `web/index.html` in a modern browser. The interface lets you add campuses,
members, lockers, and reservations, and view or cancel reservations. It runs
without a server or third-party dependencies and stores its demo data in the
browser’s `localStorage`; it does not connect to PostgreSQL. Use the SQL schema
as the authoritative database design.

## Model notes

- Each locker belongs to one campus and has a campus-unique locker number.
- Reservations belong to one member and one locker.
- A locker can have at most one pending or active reservation at a time.
- Reservation end times must be later than start times.
- Foreign keys prevent deleting a campus, member, or locker while it is in use.
