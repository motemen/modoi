CREATE TABLE thread (
    uri VARCHAR(1024) NOT NULL,
    thumbnail_uri VARCHAR(1024) NOT NULL,
    summary TEXT NOT NULL DEFAULT '',
    response_count INTEGER NOT NULL DEFAULT 0,
    created_on DATETIME NOT NULL,
    updated_on DATETIME NOT NULL,
    PRIMARY KEY (uri)
);