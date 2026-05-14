package service

import (
	"log"

	"location-service/internal/client"
	"location-service/internal/model"
	"location-service/internal/repository"
)

type LocationService struct {
	repo *repository.LocationRepository
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

	categories := getCategoriesByMood(mood)

	places, err := client.GetPlaces(
		locationName,
		categories,
	)
	if err != nil {
		return nil, err
	}

	var result []model.Location

	for _, place := range places {

		location := model.Location{
			PlaceID: place.PlaceID,
			Name:    place.Name,
			Type:    place.Type,
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

	return result, nil
}

func (s *LocationService) GetLocationDetails(
	placeID string,
) (*client.PlaceDetails, error) {

	log.Println("GetLocationDetails request:")
	log.Println("PlaceID:", placeID)

	return client.GetPlaceDetails(placeID)
}

func getCategoriesByMood(mood string) string {

	switch mood {

	case "calm":
		return "leisure.park,tourism.sights,heritage,entertainment.museum,education.library,natural,catering.cafe"

	case "happy":
		return "catering.cafe,catering.restaurant,entertainment.cinema,tourism.sights,leisure.park"

	case "romantic":
		return "catering.restaurant,catering.cafe,leisure.park,tourism.sights,entertainment.cinema"

	case "active":
		return "sport,leisure.park,natural,tourism.sights,entertainment"

	case "cultural":
		return "entertainment.museum,tourism.sights,heritage,education.library"

	case "food":
		return "catering.restaurant,catering.cafe,catering.fast_food"

	case "shopping":
		return "commercial.shopping_mall,commercial.marketplace,catering.cafe,entertainment.cinema"

	default:
		return "tourism.sights,leisure.park,catering.cafe,entertainment"
	}
}
