module test-client

go 1.26.1

replace feedback-service => ../feedback-service

replace route-history-service => ../route-history-service

require (
	feedback-service v0.0.0-00010101000000-000000000000
	google.golang.org/grpc v1.79.2
	route-history-service v0.0.0-00010101000000-000000000000
)

require (
	golang.org/x/net v0.48.0 // indirect
	golang.org/x/sys v0.39.0 // indirect
	golang.org/x/text v0.32.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20251202230838-ff82c1b0f217 // indirect
	google.golang.org/protobuf v1.36.11 // indirect
)
