package service

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"route-generation-service/internal/client"
	"route-generation-service/internal/model"
	"route-generation-service/internal/repository"

	locationpb "route-generation-service/proto/locationpb"
)

type PreferenceCreatedEvent struct {
	PreferenceID string  `json:"preference_id"`
	UserID       string  `json:"user_id"`
	Mood         string  `json:"mood"`
	Date         string  `json:"date"`
	Budget       float64 `json:"budget"`
	Duration     int32   `json:"duration"`
	Location     string  `json:"location"`
}

type RouteService struct {
	routeRepo      *repository.RouteRepository
	locationClient *client.LocationClient
}

type routeCandidate struct {
	location      *locationpb.Location
	placeType     string
	estimatedTime int32
	estimatedCost int32
	priority      int32
}

func NewRouteService(
	routeRepo *repository.RouteRepository,
	locationClient *client.LocationClient,
) *RouteService {
	return &RouteService{
		routeRepo:      routeRepo,
		locationClient: locationClient,
	}
}

func (s *RouteService) GenerateRouteFromPreference(
	ctx context.Context,
	event PreferenceCreatedEvent,
) (*model.Route, error) {

	locationsResponse, err := s.locationClient.FindSuitableLocations(
		ctx,
		event.Mood,
		event.Date,
		event.Budget,
		event.Duration,
		event.Location,
	)
	if err != nil {
		return nil, err
	}

	route := s.buildRoute(event, locationsResponse.Locations)

	if len(route.Places) == 0 {
		return nil, fmt.Errorf("no suitable locations found for route")
	}

	err = s.routeRepo.CreateRoute(ctx, route)
	if err != nil {
		return nil, err
	}

	return route, nil
}

func (s *RouteService) GetRouteByID(ctx context.Context, routeID string) (*model.Route, error) {
	return s.routeRepo.GetRouteByID(ctx, routeID)
}

func (s *RouteService) GetUserRoutes(ctx context.Context, userID string) ([]model.Route, error) {
	return s.routeRepo.GetUserRoutes(ctx, userID)
}

func (s *RouteService) buildRoute(
	event PreferenceCreatedEvent,
	locations []*locationpb.Location,
) *model.Route {

	route := &model.Route{
		UserID:        event.UserID,
		PreferenceID:  event.PreferenceID,
		Title:         fmt.Sprintf("%s route in %s", event.Mood, event.Location),
		Mood:          event.Mood,
		City:          event.Location,
		TotalBudget:   0,
		TotalDuration: 0,
		Places:        []model.RoutePlace{},
	}

	candidates := buildCandidates(event.Mood, locations)

	sort.Slice(candidates, func(i, j int) bool {
		return candidates[i].priority > candidates[j].priority
	})

	var order int32 = 1

	for _, candidate := range candidates {

		if float64(route.TotalBudget+candidate.estimatedCost) > event.Budget {
			continue
		}

		if route.TotalDuration+candidate.estimatedTime > event.Duration {
			continue
		}

		route.Places = append(route.Places, model.RoutePlace{
			PlaceID:       candidate.location.PlaceId,
			Name:          candidate.location.Name,
			Type:          candidate.placeType,
			Address:       "",
			Lat:           candidate.location.Lat,
			Lon:           candidate.location.Lon,
			VisitOrder:    order,
			EstimatedTime: candidate.estimatedTime,
			EstimatedCost: candidate.estimatedCost,
		})

		route.TotalBudget += candidate.estimatedCost
		route.TotalDuration += candidate.estimatedTime
		order++
	}

	return route
}

func buildCandidates(
	mood string,
	locations []*locationpb.Location,
) []routeCandidate {

	var candidates []routeCandidate

	for _, loc := range locations {
		normalizedType := normalizePlaceType(loc.Type)

		estimatedTime := getEstimatedTimeByType(normalizedType)
		estimatedCost := getEstimatedCostByType(normalizedType)
		priority := getPriorityByMoodAndType(mood, normalizedType)

		candidates = append(candidates, routeCandidate{
			location:      loc,
			placeType:     normalizedType,
			estimatedTime: estimatedTime,
			estimatedCost: estimatedCost,
			priority:      priority,
		})
	}

	return candidates
}

func normalizePlaceType(placeType string) string {
	placeType = strings.ToLower(placeType)

	switch {
	case strings.Contains(placeType, "catering.cafe"):
		return "cafe"
	case strings.Contains(placeType, "catering.restaurant"):
		return "restaurant"
	case strings.Contains(placeType, "catering.fast_food"):
		return "fast_food"

	case strings.Contains(placeType, "entertainment.museum"):
		return "museum"
	case strings.Contains(placeType, "museum"):
		return "museum"

	case strings.Contains(placeType, "leisure.park"):
		return "park"
	case strings.Contains(placeType, "park"):
		return "park"

	case strings.Contains(placeType, "entertainment.cinema"):
		return "cinema"
	case strings.Contains(placeType, "cinema"):
		return "cinema"

	case strings.Contains(placeType, "commercial.shopping_mall"):
		return "shopping_mall"
	case strings.Contains(placeType, "marketplace"):
		return "marketplace"

	case strings.Contains(placeType, "education.library"):
		return "library"
	case strings.Contains(placeType, "library"):
		return "library"

	case strings.Contains(placeType, "tourism.sights"):
		return "sight"
	case strings.Contains(placeType, "sights"):
		return "sight"
	case strings.Contains(placeType, "heritage"):
		return "heritage"

	case strings.Contains(placeType, "sport"):
		return "sport"

	case strings.Contains(placeType, "natural"):
		return "nature"

	case strings.Contains(placeType, "tourism"):
		return "sight"
	case strings.Contains(placeType, "catering"):
		return "cafe"
	case strings.Contains(placeType, "entertainment"):
		return "entertainment"
	case strings.Contains(placeType, "commercial"):
		return "shopping"

	default:
		return "place"
	}
}

func getEstimatedTimeByType(placeType string) int32 {
	placeType = strings.ToLower(placeType)

	switch placeType {
	case "museum":
		return 2
	case "restaurant":
		return 2
	case "cafe":
		return 1
	case "fast_food":
		return 1
	case "park":
		return 1
	case "cinema":
		return 2
	case "shopping_mall":
		return 2
	case "marketplace":
		return 2
	case "sight":
		return 1
	case "heritage":
		return 1
	case "library":
		return 1
	case "sport":
		return 2
	case "nature":
		return 2
	default:
		return 1
	}
}

func getEstimatedCostByType(placeType string) int32 {
	placeType = strings.ToLower(placeType)

	switch placeType {
	case "restaurant":
		return 6000
	case "cafe":
		return 3000
	case "fast_food":
		return 2500
	case "museum":
		return 1500
	case "cinema":
		return 2500
	case "shopping_mall":
		return 5000
	case "marketplace":
		return 4000
	case "sport":
		return 3000
	case "park":
		return 0
	case "sight":
		return 0
	case "heritage":
		return 0
	case "library":
		return 0
	case "nature":
		return 0
	default:
		return 1000
	}
}

func getPriorityByMoodAndType(mood string, placeType string) int32 {
	mood = strings.ToLower(mood)
	placeType = strings.ToLower(placeType)

	switch mood {

	case "calm":
		switch placeType {
		case "park":
			return 100
		case "library":
			return 90
		case "museum":
			return 80
		case "cafe":
			return 70
		}

	case "happy":
		switch placeType {
		case "cafe":
			return 100
		case "restaurant":
			return 90
		case "entertainment":
			return 80
		case "sight":
			return 70
		}

	case "romantic":
		switch placeType {
		case "restaurant":
			return 100
		case "park":
			return 90
		case "sight":
			return 80
		case "cinema":
			return 70
		}

	case "active":
		switch placeType {
		case "sport":
			return 100
		case "nature":
			return 90
		case "park":
			return 80
		case "sight":
			return 70
		}

	case "cultural":
		switch placeType {
		case "museum":
			return 100
		case "sight":
			return 90
		case "heritage":
			return 80
		case "library":
			return 70
		}

	case "food":
		switch placeType {
		case "restaurant":
			return 100
		case "cafe":
			return 90
		case "fast_food":
			return 70
		}

	case "shopping":
		switch placeType {
		case "shopping_mall":
			return 100
		case "marketplace":
			return 90
		case "shopping":
			return 80
		}
	}

	return 50
}
