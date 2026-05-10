CREATE TABLE IF NOT EXISTS preferences (
                                           id SERIAL PRIMARY KEY,

                                           user_id UUID NOT NULL,

                                           mood TEXT NOT NULL,
                                           budget INTEGER NOT NULL,
                                           duration INTEGER NOT NULL,

                                           location TEXT,
                                           travel_date DATE,


                                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                           updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);