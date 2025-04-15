### Build Stage
FROM dart:stable AS builder

# Set working directory inside the container
WORKDIR /app

# Copy pubspec files and download dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source files
COPY bin bin/

# Compile Dart app to native executable
RUN dart compile exe bin/gateway_main.dart -o bin/gateway


### Runtime Stage
FROM debian:stable-slim

# Install minimal required system libraries
RUN apt-get update && \
    apt-get install -y libssl-dev ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*

# Non-root user for better security
RUN useradd -m appuser
USER appuser

# Set working directory
WORKDIR /app

# Copy the compiled binary and any tool metadata
COPY --from=builder /app/bin/gateway /app/gateway
COPY --from=builder /app/.dart_tool /app/.dart_tool

# Set environment variable for runtime port
ENV PORT=9090
EXPOSE 9090

# Healthcheck for Docker
HEALTHCHECK CMD curl --fail http://localhost:9090 || exit 1

# Run the binary
CMD ["./gateway"]