package repository

import (
	"context"
	"database/sql"

	"route-generation-service/internal/model"
)

type RouteRepository struct {
	db *sql.DB
}

func NewRouteRepository(db *sql.DB) *RouteRepository {
	return &RouteRepository{db: db}
}

func (r *RouteRepository) CreateRoute(ctx context.Context, route *model.Route) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO routes 
		(user_id, preference_id, title, mood, city, total_budget, total_duration)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at
	`

	err = tx.QueryRowContext(
		ctx,
		query,
		route.UserID,
		route.PreferenceID,
		route.Title,
		route.Mood,
		route.City,
		route.TotalBudget,
		route.TotalDuration,
	).Scan(&route.ID, &route.CreatedAt)

	if err != nil {
		tx.Rollback()
		return err
	}

	placeQuery := `
		INSERT INTO route_places
		(route_id, place_id, name, type, address, lat, lon, visit_order, estimated_time, estimated_cost)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id
	`

	for i := range route.Places {
		route.Places[i].RouteID = route.ID

		err = tx.QueryRowContext(
			ctx,
			placeQuery,
			route.Places[i].RouteID,
			route.Places[i].PlaceID,
			route.Places[i].Name,
			route.Places[i].Type,
			route.Places[i].Address,
			route.Places[i].Lat,
			route.Places[i].Lon,
			route.Places[i].VisitOrder,
			route.Places[i].EstimatedTime,
			route.Places[i].EstimatedCost,
		).Scan(&route.Places[i].ID)

		if err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit()
}

func (r *RouteRepository) GetRouteByID(ctx context.Context, routeID string) (*model.Route, error) {
	route := &model.Route{}

	query := `
		SELECT id, user_id, preference_id, title, mood, city, total_budget, total_duration, created_at
		FROM routes
		WHERE id = $1
	`

	err := r.db.QueryRowContext(ctx, query, routeID).Scan(
		&route.ID,
		&route.UserID,
		&route.PreferenceID,
		&route.Title,
		&route.Mood,
		&route.City,
		&route.TotalBudget,
		&route.TotalDuration,
		&route.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	places, err := r.getRoutePlaces(ctx, route.ID)
	if err != nil {
		return nil, err
	}

	route.Places = places

	return route, nil
}

func (r *RouteRepository) GetUserRoutes(ctx context.Context, userID string) ([]model.Route, error) {
	query := `
		SELECT id, user_id, preference_id, title, mood, city, total_budget, total_duration, created_at
		FROM routes
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var routes []model.Route

	for rows.Next() {
		var route model.Route

		err := rows.Scan(
			&route.ID,
			&route.UserID,
			&route.PreferenceID,
			&route.Title,
			&route.Mood,
			&route.City,
			&route.TotalBudget,
			&route.TotalDuration,
			&route.CreatedAt,
		)
		if err != nil {
			return nil, err
		}

		places, err := r.getRoutePlaces(ctx, route.ID)
		if err != nil {
			return nil, err
		}

		route.Places = places
		routes = append(routes, route)
	}

	return routes, nil
}

func (r *RouteRepository) getRoutePlaces(ctx context.Context, routeID string) ([]model.RoutePlace, error) {
	query := `
		SELECT id, route_id, place_id, name, type, address, lat, lon, visit_order, estimated_time, estimated_cost
		FROM route_places
		WHERE route_id = $1
		ORDER BY visit_order ASC
	`

	rows, err := r.db.QueryContext(ctx, query, routeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var places []model.RoutePlace

	for rows.Next() {
		var place model.RoutePlace

		err := rows.Scan(
			&place.ID,
			&place.RouteID,
			&place.PlaceID,
			&place.Name,
			&place.Type,
			&place.Address,
			&place.Lat,
			&place.Lon,
			&place.VisitOrder,
			&place.EstimatedTime,
			&place.EstimatedCost,
		)
		if err != nil {
			return nil, err
		}

		places = append(places, place)
	}

	return places, nil
}
