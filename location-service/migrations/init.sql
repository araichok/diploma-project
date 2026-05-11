CREATE TABLE IF NOT EXISTS locations (
                                         id SERIAL PRIMARY KEY,
                                         place_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(255),
    city VARCHAR(255),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    mood VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );