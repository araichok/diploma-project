package repository

import (
	"database/sql"
	"preference-service/internal/model"
)

type PreferenceRepository struct {
	db *sql.DB
}

func NewPreferenceRepository(db *sql.DB) *PreferenceRepository {
	return &PreferenceRepository{db: db}
}

func (r *PreferenceRepository) Create(p *model.Preference) (*model.Preference, error) {
	query := `
		INSERT INTO preferences 
		(user_id, mood, budget, duration, location, travel_date)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		p.UserID,
		p.Mood,
		p.Budget,
		p.Duration,
		p.Location,
		p.TravelDate,
	).Scan(&p.ID, &p.CreatedAt, &p.UpdatedAt)

	if err != nil {
		return nil, err
	}

	return p, nil
}

func (r *PreferenceRepository) GetHistory(userID string) ([]*model.Preference, error) {
	query := `
		SELECT id, user_id, mood, budget, duration, location, travel_date, created_at, updated_at
		FROM preferences
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var preferences []*model.Preference

	for rows.Next() {
		p := &model.Preference{}

		err := rows.Scan(
			&p.ID,
			&p.UserID,
			&p.Mood,
			&p.Budget,
			&p.Duration,
			&p.Location,
			&p.TravelDate,
			&p.CreatedAt,
			&p.UpdatedAt,
		)

		if err != nil {
			return nil, err
		}

		preferences = append(preferences, p)
	}

	return preferences, nil
}

func (r *PreferenceRepository) Update(p *model.Preference) (*model.Preference, error) {
	query := `
		UPDATE preferences
		SET mood = $1,
			budget = $2,
			duration = $3,
			location = $4,
			travel_date = $5,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $6 AND user_id = $7
		RETURNING created_at, updated_at
	`

	err := r.db.QueryRow(
		query,
		p.Mood,
		p.Budget,
		p.Duration,
		p.Location,
		p.TravelDate,
		p.ID,
		p.UserID,
	).Scan(&p.CreatedAt, &p.UpdatedAt)

	if err != nil {
		return nil, err
	}

	return p, nil
}

func (r *PreferenceRepository) Delete(id string, userID string) error {
	query := `
		DELETE FROM preferences
		WHERE id = $1 AND user_id = $2
	`

	_, err := r.db.Exec(query, id, userID)
	return err
}
