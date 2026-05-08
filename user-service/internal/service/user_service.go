package service

import (
	"errors"

	"user-service/internal/auth"
	"user-service/internal/model"
	"user-service/internal/repository"
)

type UserService struct {
	userRepo  *repository.UserRepository
	jwtSecret string
}

func NewUserService(userRepo *repository.UserRepository, jwtSecret string) *UserService {
	return &UserService{
		userRepo:  userRepo,
		jwtSecret: jwtSecret,
	}
}

func (s *UserService) Register(req model.RegisterRequest) (*model.User, error) {
	if req.FirstName == "" || req.LastName == "" || req.Email == "" || req.Password == "" {
		return nil, errors.New("all fields are required")
	}

	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Email:        req.Email,
		PasswordHash: hashedPassword,
	}

	err = s.userRepo.CreateUser(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *UserService) Login(req model.LoginRequest) (*model.LoginResponse, error) {
	if req.Email == "" || req.Password == "" {
		return nil, errors.New("email and password are required")
	}

	user, err := s.userRepo.GetUserByEmail(req.Email)
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	if !auth.CheckPassword(req.Password, user.PasswordHash) {
		return nil, errors.New("invalid email or password")
	}

	token, err := auth.GenerateToken(user.ID, user.Email, user.Role, s.jwtSecret)
	if err != nil {
		return nil, err
	}

	return &model.LoginResponse{
		Token: token,
		User:  *user,
	}, nil
}

func (s *UserService) GetProfile(id string) (*model.User, error) {
	if id == "" {
		return nil, errors.New("user id is required")
	}

	return s.userRepo.GetUserByID(id)
}

func (s *UserService) UpdateUser(id string, req model.UpdateUserRequest) (*model.User, error) {
	if id == "" {
		return nil, errors.New("user id is required")
	}

	if req.FirstName == "" || req.LastName == "" || req.Email == "" {
		return nil, errors.New("all fields are required")
	}

	return s.userRepo.UpdateUser(id, req)
}

func (s *UserService) DeleteUser(id string) error {
	if id == "" {
		return errors.New("user id is required")
	}

	return s.userRepo.DeleteUser(id)
}
