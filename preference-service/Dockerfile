FROM golang:1.25

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY . .

RUN go build -o preference-service ./cmd/preference-service

EXPOSE 50052

CMD ["./preference-service"]