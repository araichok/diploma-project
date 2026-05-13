FROM golang:1.22 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o app ./cmd

FROM gcr.io/distroless/base-debian11

WORKDIR /app

COPY --from=builder /app/app .

EXPOSE 50057

CMD ["./app"]