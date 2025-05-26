FROM dart:stable AS builder

WORKDIR /app

COPY services/notification_service/pubspec.* ./
COPY models/ ../models/

RUN dart pub get

# Copy source
COPY services/notification_service/bin/ bin/
COPY services/notification_service/lib/ lib/


RUN dart compile exe bin/notification_main.dart -o bin/server


### Runtime Stage
FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m appuser
USER appuser

WORKDIR /app

COPY --from=builder /app/bin/server /app/server
COPY --from=builder /app/.dart_tool /app/.dart_tool

ENV PORT=8089
EXPOSE 8089

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8089/health || exit 1

CMD ["./server"]