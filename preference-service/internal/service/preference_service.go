package service

import "preference-service/internal/model"

type PreferenceService struct{}

func NewPreferenceService() *PreferenceService {
	return &PreferenceService{}
}

// основная логика
func (s *PreferenceService) GetCategories(pref model.Preference) []string {

	categories := []string{}

	switch pref.Mood {
	case "relax":
		categories = []string{"park", "cafe"}
	case "adventure":
		categories = []string{"hiking", "sports"}
	case "romantic":
		categories = []string{"restaurant", "viewpoint"}
	default:
		categories = []string{"cafe"}
	}

	if pref.TimeOfDay == "evening" {
		categories = append(categories, "restaurant")
	}

	if pref.Budget == "low" {
		categories = append(categories, "free_attraction")
	}

	return categories
}
