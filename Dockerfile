# Dockerfile for containerizing the Go application
# This file builds the binary and runs it using a lightweight runtime image

# ---------- Build Stage ----------
# Use the official Go image to compile the application
FROM golang:1.22.5 AS base

# Set the application working directory
WORKDIR /app

# Copy dependency definitions first (for better layer caching)
COPY go.mod ./

# Download Go module dependencies
RUN go mod download

# Copy the full source code into the container
COPY . .

# Compile the Go application
RUN go build -o main .

#######################################################
# ---------- Runtime Stage ----------
# Use a minimal distroless image to reduce final image size
FROM gcr.io/distroless/base

# Copy the compiled binary from the build stage
COPY --from=base /app/main .

# Copy static assets required by the application
COPY --from=base /app/static ./static

# Expose the application port
EXPOSE 8080

# Start the application
CMD ["./main"]
