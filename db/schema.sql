CREATE TABLE thread (
    uri VARCHAR(1024) NOT NULL,
    thumbnail_uri VARCHAR(1024),
    summary VARCHAR(1024),
    datetime TIMESTAMP NOT NULL,
    PRIMARY KEY (uri)
);
