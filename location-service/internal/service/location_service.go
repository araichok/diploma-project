package service

import (
	"log"
	"strings"

	"location-service/internal/client"
	"location-service/internal/model"
	"location-service/internal/repository"
)

type LocationService struct {
	repo *repository.LocationRepository
}

type CategoryRule struct {
	Category string
	Limit    int
}

func NewLocationService(
	repo *repository.LocationRepository,
) *LocationService {

	return &LocationService{
		repo: repo,
	}
}

func (s *LocationService) FindSuitableLocations(
	mood string,
	locationName string,
) ([]model.Location, error) {

	log.Println("FindSuitableLocations request:")
	log.Println("Mood:", mood)
	log.Println("Location:", locationName)

	categoryRules := getCategoriesByMood(mood)

	var result []model.Location
	seen := make(map[string]bool)

	priorityPlaces := getPriorityPlacesByCity(locationName)

	for _, placeName := range priorityPlaces {

		places, err := client.GetPlaceByName(placeName)

		if err != nil {
			log.Println("failed to get priority place:", placeName, err)
			continue
		}

		for _, place := range places {

			if seen[place.PlaceID] {
				continue
			}

			seen[place.PlaceID] = true

			location := model.Location{
				PlaceID: place.PlaceID,
				Name:    place.Name,
				Type:    "city_landmark",
				Address: place.Address,
				City:    place.City,
				Lat:     place.Lat,
				Lon:     place.Lon,
				Mood:    mood,
			}

			err := s.repo.SaveIfNotExists(location)

			if err != nil {
				log.Println("failed to save priority location:", err)
			}

			result = append(result, location)
		}
	}

	for _, rule := range categoryRules {

		places, err := client.GetPlaces(
			locationName,
			rule.Category,
			rule.Limit,
		)

		if err != nil {
			log.Println(
				"failed to get places for category:",
				rule.Category,
				err,
			)
			continue
		}

		for _, place := range places {

			if seen[place.PlaceID] {
				continue
			}

			seen[place.PlaceID] = true

			location := model.Location{
				PlaceID: place.PlaceID,
				Name:    place.Name,
				Type:    normalizePlaceType(place.Name, rule.Category),
				Address: place.Address,
				City:    place.City,
				Lat:     place.Lat,
				Lon:     place.Lon,
				Mood:    mood,
			}

			err := s.repo.SaveIfNotExists(location)
			if err != nil {
				log.Println("failed to save location:", err)
			}

			result = append(result, location)
		}
	}

	return result, nil
}

func normalizePlaceType(
	name string,
	category string,
) string {

	lowerName := strings.ToLower(name)

	if strings.Contains(lowerName, "байтерек") ||
		strings.Contains(lowerName, "baiterek") {

		return "landmark"
	}

	if strings.Contains(lowerName, "хан шатыр") ||
		strings.Contains(lowerName, "khan shatyr") {

		return "shopping_entertainment_center"
	}

	if strings.Contains(lowerName, "медеу") ||
		strings.Contains(lowerName, "medeu") {

		return "mountain_sports"
	}

	if strings.Contains(lowerName, "кок тобе") ||
		strings.Contains(lowerName, "kok tobe") {

		return "mountain_park"
	}

	if strings.Contains(category, "museum") {
		return "museum"
	}

	if strings.Contains(category, "park") {
		return "park"
	}

	if strings.Contains(category, "restaurant") {
		return "restaurant"
	}

	if strings.Contains(category, "cafe") {
		return "cafe"
	}

	if strings.Contains(category, "shopping") {
		return "shopping"
	}

	if strings.Contains(category, "library") {
		return "library"
	}

	if strings.Contains(category, "cinema") {
		return "cinema"
	}

	if strings.Contains(category, "sights") {
		return "tourist_attraction"
	}

	return category
}

func getCategoriesByMood(mood string) []CategoryRule {

	switch mood {

	case "calm":
		return []CategoryRule{
			{Category: "tourism.sights", Limit: 5},
			{Category: "leisure.park", Limit: 5},
			{Category: "natural", Limit: 4},
			{Category: "entertainment.museum", Limit: 4},
			{Category: "catering.cafe", Limit: 4},
		}

	case "happy":
		return []CategoryRule{
			{Category: "tourism.sights", Limit: 5},
			{Category: "leisure.park", Limit: 4},
			{Category: "entertainment.cinema", Limit: 3},
			{Category: "catering.restaurant", Limit: 4},
			{Category: "commercial.shopping_mall", Limit: 4},
		}

	case "romantic":
		return []CategoryRule{
			{Category: "tourism.sights", Limit: 4},
			{Category: "leisure.park", Limit: 4},
			{Category: "catering.restaurant", Limit: 5},
			{Category: "catering.cafe", Limit: 4},
			{Category: "entertainment.cinema", Limit: 2},
		}

	case "active":
		return []CategoryRule{
			{Category: "sport", Limit: 5},
			{Category: "natural", Limit: 5},
			{Category: "tourism.sights", Limit: 4},
			{Category: "leisure.park", Limit: 4},
			{Category: "entertainment", Limit: 3},
		}

	case "cultural":
		return []CategoryRule{
			{Category: "entertainment.museum", Limit: 6},
			{Category: "heritage", Limit: 5},
			{Category: "tourism.sights", Limit: 5},
			{Category: "education.library", Limit: 3},
			{Category: "entertainment.culture", Limit: 3},
		}

	case "food":
		return []CategoryRule{
			{Category: "catering.restaurant", Limit: 8},
			{Category: "catering.cafe", Limit: 5},
			{Category: "catering.fast_food", Limit: 3},
			{Category: "catering.food_court", Limit: 3},
		}

	case "shopping":
		return []CategoryRule{
			{Category: "commercial.shopping_mall", Limit: 6},
			{Category: "commercial.marketplace", Limit: 4},
			{Category: "commercial.supermarket", Limit: 3},
			{Category: "catering.cafe", Limit: 3},
			{Category: "entertainment.cinema", Limit: 2},
		}

	default:
		return []CategoryRule{
			{Category: "tourism.sights", Limit: 5},
			{Category: "leisure.park", Limit: 4},
			{Category: "entertainment.museum", Limit: 4},
			{Category: "catering.cafe", Limit: 4},
		}
	}
}

func getPriorityPlacesByCity(locationName string) []string {

	location := strings.ToLower(locationName)

	if strings.Contains(location, "astana") ||
		strings.Contains(location, "астана") {

		return []string{
			"Baiterek Astana Kazakhstan",
			"Khan Shatyr Astana Kazakhstan",
			"National Museum of Kazakhstan Astana Kazakhstan",
			"Nur Alem Astana Kazakhstan",
			"EXPO Astana Kazakhstan",
		}
	}

	if strings.Contains(location, "almaty") ||
		strings.Contains(location, "алматы") {

		return []string{
			"Medeu Almaty Kazakhstan",
			"Kok Tobe Almaty Kazakhstan",
			"Central Park Almaty Kazakhstan",
			"Green Bazaar Almaty Kazakhstan",
			"Central State Museum Almaty Kazakhstan",
		}
	}

	return []string{}
}
