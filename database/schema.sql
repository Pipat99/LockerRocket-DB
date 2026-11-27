CREATE TYPE locker_size AS ENUM ('small', 'medium', 'large');
CREATE TYPE locker_status AS ENUM ('available', 'maintenance');
CREATE TYPE reservation_status AS ENUM (
    'pending',
    'active',
    'completed',
    'cancelled'
);

CREATE TABLE campuses (
    campus_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(20) NOT NULL UNIQUE,
    name varchar(120) NOT NULL,
    address text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT campuses_code_not_blank CHECK (btrim(code) <> ''),
    CONSTRAINT campuses_name_not_blank CHECK (btrim(name) <> '')
);

CREATE TABLE members (
    member_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    university_id varchar(40) NOT NULL UNIQUE,
    first_name varchar(80) NOT NULL,
    last_name varchar(80) NOT NULL,
    email varchar(254) NOT NULL UNIQUE,
    phone varchar(30),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT members_university_id_not_blank CHECK (btrim(university_id) <> ''),
    CONSTRAINT members_first_name_not_blank CHECK (btrim(first_name) <> ''),
    CONSTRAINT members_last_name_not_blank CHECK (btrim(last_name) <> ''),
    CONSTRAINT members_email_not_blank CHECK (btrim(email) <> '')
);

CREATE TABLE lockers (
    locker_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    campus_id bigint NOT NULL REFERENCES campuses(campus_id) ON DELETE RESTRICT,
    locker_number varchar(30) NOT NULL,
    size locker_size NOT NULL,
    status locker_status NOT NULL DEFAULT 'available',
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT lockers_number_not_blank CHECK (btrim(locker_number) <> ''),
    CONSTRAINT lockers_campus_number_unique UNIQUE (campus_id, locker_number),
    CONSTRAINT lockers_id_campus_unique UNIQUE (locker_id, campus_id)
);

CREATE TABLE reservations (
    reservation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id bigint NOT NULL REFERENCES members(member_id) ON DELETE RESTRICT,
    locker_id bigint NOT NULL REFERENCES lockers(locker_id) ON DELETE RESTRICT,
    status reservation_status NOT NULL DEFAULT 'pending',
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT reservations_valid_period CHECK (ends_at > starts_at)
);

CREATE UNIQUE INDEX reservations_one_open_per_locker
    ON reservations (locker_id)
    WHERE status IN ('pending', 'active');

CREATE INDEX reservations_member_id_idx ON reservations (member_id);
CREATE INDEX reservations_locker_id_idx ON reservations (locker_id);
CREATE INDEX reservations_starts_at_idx ON reservations (starts_at);
