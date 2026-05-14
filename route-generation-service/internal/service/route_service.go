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
		if candidates[i].priority == candidates[j].priority {
			return candidates[i].estimatedCost < candidates[j].estimatedCost
		}
		return candidates[i].priority > candidates[j].priority
	})

	var order int32 = 1

	usedPlaces := make(map[string]bool)
	usedTypes := make(map[string]int)

	for _, candidate := range candidates {
		if route.TotalDuration >= event.Duration {
			break
		}

		if usedPlaces[candidate.location.PlaceId] {
			continue
		}

		if float64(route.TotalBudget+candidate.estimatedCost) > event.Budget {
			continue
		}

		if route.TotalDuration+candidate.estimatedTime > event.Duration {
			continue
		}

		// кафе, ресторан, fast_food, cinema только 1 раз
		if !canAddMoreByType(candidate.placeType, usedTypes) {
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

		usedPlaces[candidate.location.PlaceId] = true
		usedTypes[candidate.placeType]++

		route.TotalBudget += candidate.estimatedCost
		route.TotalDuration += candidate.estimatedTime
		order++
	}

	return route
}

func canAddMoreByType(placeType string, usedTypes map[string]int) bool {
	switch placeType {
	case "cafe":
		return usedTypes["cafe"] < 1
	case "restaurant":
		return usedTypes["restaurant"] < 1
	case "fast_food":
		return usedTypes["fast_food"] < 1
	case "cinema":
		return usedTypes["cinema"] < 1
	default:
		return true
	}
}

func buildCandidates(
	mood string,
	locations []*locationpb.Location,
) []routeCandidate {

	var candidates []routeCandidate

	for _, loc := range locations {
		normalizedType := normalizePlaceType(loc.Type, loc.Name)

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

func normalizePlaceType(placeType string, name string) string {
	placeType = strings.ToLower(placeType)
	name = strings.ToLower(name)

	switch {
	case strings.Contains(name, "саябағы"):
		return "park"
	case strings.Contains(name, "парк"):
		return "park"
	case strings.Contains(name, "park"):
		return "park"

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

	case strings.Contains(placeType, "leisure"):
		return "park"
	case strings.Contains(placeType, "park"):
		return "park"

	case strings.Contains(placeType, "tourism.sights"):
		return "sight"
	case strings.Contains(placeType, "sights"):
		return "sight"
	case strings.Contains(placeType, "heritage"):
		return "heritage"

	case strings.Contains(placeType, "education.library"):
		return "library"
	case strings.Contains(placeType, "library"):
		return "library"

	case strings.Contains(placeType, "catering"):
		return "cafe"
	case strings.Contains(placeType, "tourism"):
		return "sight"

	case strings.Contains(placeType, "bowling"):
		return "bowling"
	case strings.Contains(placeType, "cinema"):
		return "cinema"
	case strings.Contains(placeType, "theatre"):
		return "theatre"
	case strings.Contains(placeType, "entertainment"):
		return "entertainment"

	default:
		return "place"
	}
}

func getEstimatedTimeByType(placeType string) int32 {
	placeType = strings.ToLower(placeType)

	switch placeType {
	case "park":
		return 2
	case "museum":
		return 2
	case "sight":
		return 2
	case "heritage":
		return 1
	case "library":
		return 1
	case "cafe":
		return 1
	case "restaurant":
		return 2
	case "fast_food":
		return 1
	case "cinema":
		return 2
	case "shopping_mall":
		return 2
	case "marketplace":
		return 2
	case "sport":
		return 2
	case "nature":
		return 2
	case "bowling":
		return 2
	case "theatre":
		return 2
	case "entertainment":
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
	case "bowling":
		return 4000
	case "theatre":
		return 5000
	case "entertainment":
		return 3000
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

	case "happy":
		switch placeType {
		case "bowling":
			return 100
		case "cinema":
			return 90
		case "entertainment":
			return 80
		case "cafe":
			return 70
		case "sight":
			return 60
		}

	case "active":
		switch placeType {
		case "sport":
			return 100
		case "bowling":
			return 90
		case "nature":
			return 80
		case "park":
			return 70
		case "sight":
			return 60
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
