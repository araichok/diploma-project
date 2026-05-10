package service

import (
	"log"

	"preference-service/internal/messaging"
	"preference-service/internal/model"
	"preference-service/internal/repository"
)

type PreferenceService struct {
	repo       *repository.PreferenceRepository
	userClient *messaging.UserNATSClient
}

func NewPreferenceService(
	repo *repository.PreferenceRepository,
	userClient *messaging.UserNATSClient,
) *PreferenceService {
	return &PreferenceService{
		repo:       repo,
		userClient: userClient,
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

	return s.repo.Create(p)
}

func (s *PreferenceService) GetPreferenceHistory(userID string) ([]*model.Preference, error) {
	return s.repo.GetHistory(userID)
}

func (s *PreferenceService) UpdatePreference(p *model.Preference) (*model.Preference, error) {
	return s.repo.Update(p)
}

func (s *PreferenceService) DeletePreference(id int64, userID string) error {
	return s.repo.Delete(id, userID)
}
