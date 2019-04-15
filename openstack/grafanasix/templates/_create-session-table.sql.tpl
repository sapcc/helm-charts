CREATE TABLE session (
    key       CHAR(16) NOT NULL,
    data      BYTEA,
    expiry    INTEGER NOT NULL,
    PRIMARY KEY (key)
);
