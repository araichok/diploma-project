FROM golang:1.24

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o location-service ./cmd/location-service

EXPOSE 50054

CMD ["./location-service"]