### Build Stage
FROM dart:stable AS builder

WORKDIR /app

# Copy and get dependencies
COPY services/report_sync_service/pubspec.* ./
COPY data/ data/
COPY models/ ../models/

RUN dart pub get

# Copy source
COPY services/report_sync_service/bin/ bin/
COPY services/report_sync_service/lib/ lib/

# Compile the CLI entrypoint
RUN dart compile exe bin/report_sync_main.dart -o bin/server

### Runtime Stage
FROM debian:stable-slim

# Install minimal system libs + curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m appuser
USER appuser

WORKDIR /app

# Copy the compiled binary and dart-tool cache
COPY --from=builder /app/bin/server /app/server
COPY --from=builder /app/.dart_tool /app/.dart_tool

# Set port and expose
ENV PORT=8083
EXPOSE 8083

# Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8083/health || exit 1

# Run the server
CMD ["./server"]
