package service

import (
	"log"

	"preference-service/internal/cache"
	"preference-service/internal/messaging"
	"preference-service/internal/model"
	"preference-service/internal/repository"
)

type PreferenceService struct {
	repo            *repository.PreferenceRepository
	userClient      *messaging.UserNATSClient
	preferenceCache *cache.PreferenceCache
}

func NewPreferenceService(
	repo *repository.PreferenceRepository,
	userClient *messaging.UserNATSClient,
	preferenceCache *cache.PreferenceCache,
) *PreferenceService {
	return &PreferenceService{
		repo:            repo,
		userClient:      userClient,
		preferenceCache: preferenceCache,
	}
}

func (s *PreferenceService) CreatePreference(p *model.Preference) (*model.Preference, error) {
	log.Println("[Preference Service] CreatePreference started for user_id:", p.UserID)

	err := s.userClient.CheckUserExists(p.UserID)
	if err != nil {
		log.Println("[Preference Service] User verification failed:", err)
		return nil, err
	}

	log.Println("[Preference Service] User verified, saving preference")

	created, err := s.repo.Create(p)
	if err != nil {
		return nil, err
	}

	_ = s.preferenceCache.DeleteHistory(p.UserID)

	event := messaging.PreferenceCreatedEvent{
		PreferenceID: created.ID,
		UserID:       created.UserID,
		Mood:         created.Mood,
		Date:         created.TravelDate,
		Budget:       float64(created.Budget),
		Duration:     created.Duration,
		Location:     created.Location,
	}

	err = s.userClient.PublishPreferenceCreated(event)
	if err != nil {
		log.Println("[Preference Service] Failed to publish preference.created:", err)
	} else {
		log.Println("[Preference Service] preference.created published")
	}

	return created, nil
}

func (s *PreferenceService) GetPreferenceHistory(userID string) ([]*model.Preference, error) {
	cachedPreferences, err := s.preferenceCache.GetHistory(userID)
	if err == nil {
		log.Println("[Preference Service] Preferences returned from Redis cache")
		return cachedPreferences, nil
	}

	preferences, err := s.repo.GetHistory(userID)
	if err != nil {
		return nil, err
	}

	_ = s.preferenceCache.SetHistory(userID, preferences)

	return preferences, nil
}

func (s *PreferenceService) UpdatePreference(p *model.Preference) (*model.Preference, error) {
	updated, err := s.repo.Update(p)
	if err != nil {
		return nil, err
	}

	_ = s.preferenceCache.DeleteHistory(p.UserID)

	return updated, nil
}

func (s *PreferenceService) DeletePreference(id string, userID string) error {
	err := s.repo.Delete(id, userID)
	if err != nil {
		return err
	}

	_ = s.preferenceCache.DeleteHistory(userID)

	return nil
}
