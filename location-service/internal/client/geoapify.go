package client

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
)

type Place struct {
	PlaceID string
	Name    string
	Type    string
	Address string
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
			PlaceID      string   `json:"place_id"`
			Name         string   `json:"name"`
			Categories   []string `json:"categories"`
			City         string   `json:"city"`
			Formatted    string   `json:"formatted"`
			AddressLine1 string   `json:"address_line1"`
			AddressLine2 string   `json:"address_line2"`
			Lat          float64  `json:"lat"`
			Lon          float64  `json:"lon"`
		} `json:"properties"`
	} `json:"features"`
}

func GetPlaces(location string, categories string, limit int) ([]Place, error) {
	lat, lon, err := getLocationCoordinates(location)
	if err != nil {
		return nil, err
	}

	return getPlacesByCoordinates(lat, lon, categories, limit)
}

func GetPlaceByName(query string) ([]Place, error) {
	apiKey := os.Getenv("GEOAPIFY_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GEOAPIFY_API_KEY is empty")
	}

	requestURL := fmt.Sprintf(
		"https://api.geoapify.com/v1/geocode/search?text=%s&filter=countrycode:kz&limit=1&apiKey=%s",
		url.QueryEscape(query),
		url.QueryEscape(apiKey),
	)

	resp, err := http.Get(requestURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("geoapify place search error: status %d", resp.StatusCode)
	}

	var data GeoapifyPlacesResponse

	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	var places []Place

	for _, feature := range data.Features {
		if feature.Properties.PlaceID == "" ||
			feature.Properties.Name == "" {
			continue
		}

		address := buildAddress(
			feature.Properties.Formatted,
			feature.Properties.AddressLine1,
			feature.Properties.AddressLine2,
		)

		places = append(places, Place{
			PlaceID: feature.Properties.PlaceID,
			Name:    feature.Properties.Name,
			Type:    "city_landmark",
			Address: address,
			Lat:     feature.Properties.Lat,
			Lon:     feature.Properties.Lon,
			City:    feature.Properties.City,
		})
	}

	return places, nil
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

	return data.Features[0].Properties.Lat,
		data.Features[0].Properties.Lon,
		nil
}

func getPlacesByCoordinates(
	lat float64,
	lon float64,
	categories string,
	limit int,
) ([]Place, error) {
	apiKey := os.Getenv("GEOAPIFY_API_KEY")

	if apiKey == "" {
		return nil, fmt.Errorf("GEOAPIFY_API_KEY is empty")
	}

	if limit <= 0 {
		limit = 5
	}

	filter := fmt.Sprintf(
		"circle:%f,%f,15000",
		lon,
		lat,
	)

	requestURL := fmt.Sprintf(
		"https://api.geoapify.com/v2/places?categories=%s&filter=%s&limit=%d&apiKey=%s",
		url.QueryEscape(categories),
		url.QueryEscape(filter),
		limit,
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
		if feature.Properties.PlaceID == "" ||
			feature.Properties.Name == "" {
			continue
		}

		placeType := categories

		if len(feature.Properties.Categories) > 0 {
			placeType = feature.Properties.Categories[0]
		}

		address := buildAddress(
			feature.Properties.Formatted,
			feature.Properties.AddressLine1,
			feature.Properties.AddressLine2,
		)

		places = append(places, Place{
			PlaceID: feature.Properties.PlaceID,
			Name:    feature.Properties.Name,
			Type:    placeType,
			Address: address,
			Lat:     feature.Properties.Lat,
			Lon:     feature.Properties.Lon,
			City:    feature.Properties.City,
		})
	}

	return places, nil
}

func buildAddress(formatted string, addressLine1 string, addressLine2 string) string {
	if formatted != "" {
		return formatted
	}

	parts := []string{}

	if addressLine1 != "" {
		parts = append(parts, addressLine1)
	}

	if addressLine2 != "" {
		parts = append(parts, addressLine2)
	}

	return strings.Join(parts, ", ")
}
