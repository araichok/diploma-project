CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS routes (
                                      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    preference_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    mood VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    total_budget INTEGER NOT NULL DEFAULT 0,
    total_duration INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS route_places (
                                            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    place_id TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    address TEXT,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    visit_order INTEGER NOT NULL,
    estimated_time INTEGER NOT NULL DEFAULT 0,
    estimated_cost INTEGER NOT NULL DEFAULT 0
    );