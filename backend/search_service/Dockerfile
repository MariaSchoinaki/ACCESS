### Build Stage
FROM dart:stable AS builder

# Set working directory inside the container
WORKDIR /app

# Copy pubspec files and download dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source files
COPY bin/ bin/
COPY lib/ lib/

# Compile Dart app to native executable
RUN dart compile exe bin/search_main.dart -o bin/server


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
COPY --from=builder /app/bin/server /app/server
COPY --from=builder /app/.dart_tool /app/.dart_tool

# Set environment variable for runtime port
ENV PORT=8080
EXPOSE 8080

# Healthcheck for Docker
HEALTHCHECK CMD curl --fail http://localhost:8080 || exit 1

# Run the binary
CMD ["./server"]