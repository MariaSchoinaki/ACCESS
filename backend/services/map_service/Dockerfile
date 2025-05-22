FROM dart:stable AS builder

WORKDIR /app

COPY services/map_service/pubspec.* ./
COPY models/ ../models/

RUN dart pub get

COPY services/map_service/bin/ bin/
COPY services/map_service/lib/ lib/

RUN dart compile exe bin/map_main.dart -o bin/server


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

ENV PORT=8081
EXPOSE 8081

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8081/health || exit 1

CMD ["./server"]
