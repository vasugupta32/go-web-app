# ---------- Build Stage ----------
FROM golang:1.22.5 AS base

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .

# ---------- Runtime Stage ----------
FROM alpine:latest

# Install certificates (very important for Go apps)
RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY --from=base /app/main .
COPY --from=base /app/static ./static

EXPOSE 8080

CMD ["./main"]

