package service

import (
	"context"

	"user-service/internal/model"
	"user-service/internal/repository"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	repo *repository.UserRepository
}

func NewUserService(repo *repository.UserRepository) *UserService {
	return &UserService{repo: repo}
}

func (s *UserService) RegisterUser(ctx context.Context, email, password, name string) (*model.User, error) {

	hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	user := &model.User{
		ID:       uuid.New().String(),
		Email:    email,
		Password: string(hash),
		Name:     name,
		Role:     "user",
	}

	err := s.repo.Create(ctx, user)

	return user, err
}

func (s *UserService) LoginUser(ctx context.Context, email, password string) (*model.User, error) {

	user, err := s.repo.GetByEmail(ctx, email)
	if err != nil {
		return nil, err
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *UserService) GetUser(ctx context.Context, id string) (*model.User, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *UserService) UpdateUser(ctx context.Context, id string, name string) (*model.User, error) {
	return s.repo.Update(ctx, id, name)
}
