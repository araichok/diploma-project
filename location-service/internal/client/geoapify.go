package client

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
)

type Place struct {
	PlaceID string
	Name    string
	Type    string
	Lat     float64
	Lon     float64
	City    string
}

type GeocodeResponse struct {
	Features []struct {
		Properties struct {
			Lat float64 `json:"lat"`
			Lon float64 `json:"lon"`
		} `json:"properties"`
	} `json:"features"`
}

type GeoapifyPlacesResponse struct {
	Features []struct {
		Properties struct {
			PlaceID    string   `json:"place_id"`
			Name       string   `json:"name"`
			Categories []string `json:"categories"`
			City       string   `json:"city"`
			Lat        float64  `json:"lat"`
			Lon        float64  `json:"lon"`
		} `json:"properties"`
	} `json:"features"`
}

func GetPlaces(location string, categories string) ([]Place, error) {
	lat, lon, err := getLocationCoordinates(location)
	if err != nil {
		return nil, err
	}

	return getPlacesByCoordinates(lat, lon, categories)
}

func getLocationCoordinates(location string) (float64, float64, error) {
	apiKey := os.Getenv("GEOAPIFY_API_KEY")
	if apiKey == "" {
		return 0, 0, fmt.Errorf("GEOAPIFY_API_KEY is empty")
	}

	requestURL := fmt.Sprintf(
		"https://api.geoapify.com/v1/geocode/search?text=%s&limit=1&apiKey=%s",
		url.QueryEscape(location),
		url.QueryEscape(apiKey),
	)

	resp, err := http.Get(requestURL)
	if err != nil {
		return 0, 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, 0, fmt.Errorf("geoapify geocode error: status %d", resp.StatusCode)
	}

	var data GeocodeResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return 0, 0, err
	}

	if len(data.Features) == 0 {
		return 0, 0, fmt.Errorf("location not found")
	}

	return data.Features[0].Properties.Lat, data.Features[0].Properties.Lon, nil
}

func getPlacesByCoordinates(lat float64, lon float64, categories string) ([]Place, error) {
	apiKey := os.Getenv("GEOAPIFY_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GEOAPIFY_API_KEY is empty")
	}

	filter := fmt.Sprintf("circle:%f,%f,15000", lon, lat)

	requestURL := fmt.Sprintf(
		"https://api.geoapify.com/v2/places?categories=%s&filter=%s&limit=20&apiKey=%s",
		url.QueryEscape(categories),
		url.QueryEscape(filter),
		url.QueryEscape(apiKey),
	)

	resp, err := http.Get(requestURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("geoapify places error: status %d", resp.StatusCode)
	}

	var data GeoapifyPlacesResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	var places []Place

	for _, feature := range data.Features {
		if feature.Properties.PlaceID == "" || feature.Properties.Name == "" {
			continue
		}

		placeType := ""
		if len(feature.Properties.Categories) > 0 {
			placeType = feature.Properties.Categories[0]
		}

		places = append(places, Place{
			PlaceID: feature.Properties.PlaceID,
			Name:    feature.Properties.Name,
			Type:    placeType,
			Lat:     feature.Properties.Lat,
			Lon:     feature.Properties.Lon,
			City:    feature.Properties.City,
		})
	}

	return places, nil
}

type PlaceDetails struct {
	PlaceID      string
	Name         string
	Address      string
	Website      string
	Phone        string
	OpeningHours string
	Description  string
}

type GeoapifyDetailsResponse struct {
	Features []struct {
		Properties struct {
			PlaceID      string `json:"place_id"`
			Name         string `json:"name"`
			Formatted    string `json:"formatted"`
			AddressLine1 string `json:"address_line1"`
			AddressLine2 string `json:"address_line2"`
			Website      string `json:"website"`
			Phone        string `json:"phone"`
			OpeningHours string `json:"opening_hours"`
			Description  string `json:"description"`
		} `json:"properties"`
	} `json:"features"`
}

func GetPlaceDetails(placeID string) (*PlaceDetails, error) {
	apiKey := os.Getenv("GEOAPIFY_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GEOAPIFY_API_KEY is empty")
	}

	requestURL := fmt.Sprintf(
		"https://api.geoapify.com/v2/place-details?id=%s&features=details&apiKey=%s",
		url.QueryEscape(placeID),
		url.QueryEscape(apiKey),
	)

	resp, err := http.Get(requestURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("geoapify place details error: status %d", resp.StatusCode)
	}

	var data GeoapifyDetailsResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	if len(data.Features) == 0 {
		return nil, fmt.Errorf("place details not found")
	}

	props := data.Features[0].Properties

	address := props.Formatted
	if address == "" {
		address = props.AddressLine1 + " " + props.AddressLine2
	}

	return &PlaceDetails{
		PlaceID:      props.PlaceID,
		Name:         props.Name,
		Address:      address,
		Website:      props.Website,
		Phone:        props.Phone,
		OpeningHours: props.OpeningHours,
		Description:  props.Description,
	}, nil
}
