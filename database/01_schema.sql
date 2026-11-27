-- =============================================================================
-- Project: RocketLocker System (Group: LockerRocket)
-- Course:  310-2309 Database System
-- File:    database/01_schema.sql
-- DBMS:    PostgreSQL
-- Week 1:  Initial PostgreSQL Schema aligned 100% with diagrams/week1/rocketlocker-erd.png
-- Tables:  Locker, LockerSlot, Customer, Admin, ServiceRate, Rental, Payment
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Locker
-- -----------------------------------------------------------------------------
CREATE TABLE Locker (
    locker_id     VARCHAR(20)  PRIMARY KEY,
    location_name VARCHAR(150) NOT NULL,
    locker_status VARCHAR(20)  NOT NULL DEFAULT 'Active',

    CONSTRAINT chk_locker_id_not_blank       CHECK (btrim(locker_id) <> ''),
    CONSTRAINT chk_locker_location_not_blank CHECK (btrim(location_name) <> ''),
    CONSTRAINT chk_locker_status_valid       CHECK (locker_status IN ('Active', 'Maintenance', 'Inactive'))
);

-- -----------------------------------------------------------------------------
-- 2. LockerSlot (Weak Entity of Locker — Composite PK: locker_id, slot_number)
-- -----------------------------------------------------------------------------
CREATE TABLE LockerSlot (
    locker_id   VARCHAR(20) NOT NULL,
    slot_number VARCHAR(10) NOT NULL,
    slot_status VARCHAR(20) NOT NULL DEFAULT 'Available',

    CONSTRAINT pk_locker_slot PRIMARY KEY (locker_id, slot_number),
    CONSTRAINT fk_locker_slot_locker
        FOREIGN KEY (locker_id)
        REFERENCES Locker (locker_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_slot_number_not_blank CHECK (btrim(slot_number) <> ''),
    CONSTRAINT chk_slot_status_valid     CHECK (slot_status IN ('Available', 'Occupied', 'Maintenance'))
);

-- -----------------------------------------------------------------------------
-- 3. Customer
-- -----------------------------------------------------------------------------
CREATE TABLE Customer (
    customer_id   VARCHAR(20)  PRIMARY KEY,
    customer_name VARCHAR(150) NOT NULL,
    phone         VARCHAR(20)  NOT NULL UNIQUE,

    CONSTRAINT chk_customer_id_not_blank    CHECK (btrim(customer_id) <> ''),
    CONSTRAINT chk_customer_name_not_blank  CHECK (btrim(customer_name) <> ''),
    CONSTRAINT chk_customer_phone_not_blank CHECK (btrim(phone) <> '')
);

-- -----------------------------------------------------------------------------
-- 4. Admin
-- -----------------------------------------------------------------------------
CREATE TABLE Admin (
    admin_id      VARCHAR(20)  PRIMARY KEY,
    admin_name    VARCHAR(150) NOT NULL,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,

    CONSTRAINT chk_admin_id_not_blank       CHECK (btrim(admin_id) <> ''),
    CONSTRAINT chk_admin_name_not_blank     CHECK (btrim(admin_name) <> ''),
    CONSTRAINT chk_admin_username_not_blank CHECK (btrim(username) <> ''),
    CONSTRAINT chk_admin_password_not_blank CHECK (btrim(password_hash) <> '')
);

-- -----------------------------------------------------------------------------
-- 5. ServiceRate
-- -----------------------------------------------------------------------------
CREATE TABLE ServiceRate (
    rate_id        VARCHAR(20)    PRIMARY KEY,
    admin_id       VARCHAR(20)    NOT NULL,
    rate_name      VARCHAR(100)   NOT NULL UNIQUE,
    price_per_hour NUMERIC(10, 2) NOT NULL,

    CONSTRAINT fk_service_rate_admin
        FOREIGN KEY (admin_id)
        REFERENCES Admin (admin_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_rate_id_not_blank       CHECK (btrim(rate_id) <> ''),
    CONSTRAINT chk_rate_name_not_blank     CHECK (btrim(rate_name) <> ''),
    CONSTRAINT chk_rate_price_non_negative CHECK (price_per_hour >= 0)
);

-- -----------------------------------------------------------------------------
-- 6. Rental (Composite FK referencing LockerSlot + Snapshot applied_rate_price)
-- -----------------------------------------------------------------------------
CREATE TABLE Rental (
    rental_id          VARCHAR(20)    PRIMARY KEY,
    customer_id        VARCHAR(20)    NOT NULL,
    locker_id          VARCHAR(20)    NOT NULL,
    slot_number        VARCHAR(10)    NOT NULL,
    rate_id            VARCHAR(20)    NOT NULL,
    start_time         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time           TIMESTAMP      NULL,
    pin_code           VARCHAR(20)    NOT NULL,
    applied_rate_price NUMERIC(10, 2) NOT NULL,

    CONSTRAINT fk_rental_customer
        FOREIGN KEY (customer_id)
        REFERENCES Customer (customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_rental_locker_slot
        FOREIGN KEY (locker_id, slot_number)
        REFERENCES LockerSlot (locker_id, slot_number)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_rental_service_rate
        FOREIGN KEY (rate_id)
        REFERENCES ServiceRate (rate_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_rental_id_not_blank         CHECK (btrim(rental_id) <> ''),
    CONSTRAINT chk_rental_end_after_start      CHECK (end_time IS NULL OR end_time >= start_time),
    CONSTRAINT chk_rental_pin_length           CHECK (char_length(btrim(pin_code)) >= 4),
    CONSTRAINT chk_rental_applied_price_nonneg CHECK (applied_rate_price >= 0)
);

-- Prevent overlapping active rentals (end_time IS NULL) on the same LockerSlot
CREATE UNIQUE INDEX uq_rental_one_active_per_slot
    ON Rental (locker_id, slot_number)
    WHERE end_time IS NULL;

-- -----------------------------------------------------------------------------
-- 7. Payment (0..1 per Rental via UNIQUE rental_id)
-- -----------------------------------------------------------------------------
CREATE TABLE Payment (
    payment_id     VARCHAR(20)    PRIMARY KEY,
    rental_id      VARCHAR(20)    NOT NULL UNIQUE,
    amount         NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(50)    NOT NULL,
    paid_at        TIMESTAMP      NULL,
    payment_status VARCHAR(20)    NOT NULL DEFAULT 'Pending',

    CONSTRAINT fk_payment_rental
        FOREIGN KEY (rental_id)
        REFERENCES Rental (rental_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_payment_id_not_blank       CHECK (btrim(payment_id) <> ''),
    CONSTRAINT chk_payment_amount_positive    CHECK (amount > 0),
    CONSTRAINT chk_payment_method_not_blank   CHECK (btrim(payment_method) <> ''),
    CONSTRAINT chk_payment_status_valid       CHECK (payment_status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    CONSTRAINT chk_payment_completed_has_time CHECK (payment_status <> 'Completed' OR paid_at IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- 8. Performance Indexes
-- -----------------------------------------------------------------------------
CREATE INDEX idx_locker_slot_status ON LockerSlot (slot_status);
CREATE INDEX idx_service_rate_admin ON ServiceRate (admin_id);
CREATE INDEX idx_rental_customer    ON Rental (customer_id);
CREATE INDEX idx_rental_slot        ON Rental (locker_id, slot_number);
CREATE INDEX idx_rental_rate        ON Rental (rate_id);
CREATE INDEX idx_rental_start_time  ON Rental (start_time);
CREATE INDEX idx_payment_status     ON Payment (payment_status);
