package service

import (
	"context"
	"log"

	"location-service/internal/client"
	"location-service/internal/model"
	"location-service/internal/repository"
	locationpb "location-service/proto/locationpb"
)

type LocationService struct {
	locationpb.UnimplementedLocationServiceServer
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
	ctx context.Context,
	req *locationpb.FindLocationsRequest,
) (*locationpb.FindLocationsResponse, error) {

	log.Println("FindSuitableLocations request:")
	log.Println("Mood:", req.Mood)
	log.Println("Date:", req.Date)
	log.Println("Budget:", req.Budget)
	log.Println("Duration:", req.Duration)
	log.Println("Location:", req.Location)

	categories := getCategoriesByMood(req.Mood)

	places, err := client.GetPlaces(
		req.Location,
		categories,
	)
	if err != nil {
		return nil, err
	}

	var result []*locationpb.Location

	for _, place := range places {

		location := model.Location{
			PlaceID: place.PlaceID,
			Name:    place.Name,
			Type:    place.Type,
			City:    place.City,
			Lat:     place.Lat,
			Lon:     place.Lon,
			Mood:    req.Mood,
		}

		err := s.repo.SaveIfNotExists(location)
		if err != nil {
			log.Println("failed to save location:", err)
		}

		result = append(result, &locationpb.Location{
			PlaceId: place.PlaceID,
			Name:    place.Name,
			Type:    place.Type,
			Lat:     place.Lat,
			Lon:     place.Lon,
			Mood:    req.Mood,
			City:    place.City,
		})
	}

	return &locationpb.FindLocationsResponse{
		Locations: result,
	}, nil
}

func (s *LocationService) GetLocationDetails(
	ctx context.Context,
	req *locationpb.GetLocationDetailsRequest,
) (*locationpb.LocationDetailsResponse, error) {

	log.Println("GetLocationDetails request:")
	log.Println("PlaceID:", req.PlaceId)

	details, err := client.GetPlaceDetails(req.PlaceId)
	if err != nil {
		return nil, err
	}

	return &locationpb.LocationDetailsResponse{
		PlaceId:      details.PlaceID,
		Name:         details.Name,
		Address:      details.Address,
		Website:      details.Website,
		Phone:        details.Phone,
		OpeningHours: details.OpeningHours,
		Description:  details.Description,
	}, nil
}

func getCategoriesByMood(mood string) string {

	switch mood {

	case "calm":
		return "leisure.park,entertainment.museum,education.library,catering.cafe"

	case "happy":
		return "catering.cafe,catering.restaurant,entertainment,tourism.sights"

	case "romantic":
		return "catering.restaurant,leisure.park,tourism.sights,entertainment.cinema"

	case "active":
		return "sport,leisure,tourism.sights,natural"

	case "cultural":
		return "entertainment.museum,tourism.sights,heritage,education.library"

	case "food":
		return "catering.restaurant,catering.cafe,catering.fast_food"

	case "shopping":
		return "commercial.shopping_mall,commercial.marketplace"

	default:
		return "tourism.sights,catering.cafe,leisure.park"
	}
}
