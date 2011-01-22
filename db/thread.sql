CREATE TABLE thread (
    url VARCHAR(1024) NOT NULL,
    image_url VARCHAR(1024),
    thumbnail_url VARCHAR(1024),
    body TEXT NOT NULL DEFAULT '',
    posts_count INTEGER NOT NULL DEFAULT 0,
    created_on DATETIME,
    updated_on DATETIME,
    PRIMARY KEY (url)
);
