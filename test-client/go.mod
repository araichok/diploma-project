module test-client

go 1.26.1

replace feedback-service => ../feedback-service

replace route-history-service => ../route-history-service

replace admin-service => ../admin-service

replace notification-service => ../notification-service

require (
	admin-service v0.0.0
	feedback-service v0.0.0-00010101000000-000000000000
	google.golang.org/grpc v1.81.0
	notification-service v0.0.0-00010101000000-000000000000
	route-history-service v0.0.0-00010101000000-000000000000
)

require (
	golang.org/x/net v0.51.0 // indirect
	golang.org/x/sys v0.42.0 // indirect
	golang.org/x/text v0.34.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260226221140-a57be14db171 // indirect
	google.golang.org/protobuf v1.36.11 // indirect
)
