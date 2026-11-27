# RocketLocker Crow’s Foot ERD

```mermaid
erDiagram
    CAMPUSES ||--o{ LOCKERS : contains
    MEMBERS ||--o{ RESERVATIONS : makes
    LOCKERS ||--o{ RESERVATIONS : assigned_to

    CAMPUSES {
        bigint campus_id PK
        varchar code UK
        varchar name
        varchar address
        timestamptz created_at
    }

    MEMBERS {
        bigint member_id PK
        varchar university_id UK
        varchar first_name
        varchar last_name
        varchar email UK
        varchar phone
        timestamptz created_at
    }

    LOCKERS {
        bigint locker_id PK
        bigint campus_id FK
        varchar locker_number
        locker_size size
        locker_status status
        timestamptz created_at
    }

    RESERVATIONS {
        bigint reservation_id PK
        bigint member_id FK
        bigint locker_id FK
        reservation_status status
        timestamptz starts_at
        timestamptz ends_at
        timestamptz created_at
    }
```

Each locker is associated with exactly one campus; a campus may contain no
lockers or many lockers. Each reservation refers to exactly one member and one
locker; members and lockers may have no reservations or many reservations over
time. PostgreSQL constraints further limit a locker to one pending or active
reservation at a time.
