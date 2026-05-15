FROM golang:1.26

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o api-gateway ./cmd/api-gateway/main.go

EXPOSE 8080

CMD ["./api-gateway"]