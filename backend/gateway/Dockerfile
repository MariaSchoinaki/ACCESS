### Build Stage
FROM dart:stable AS builder

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY bin/ bin/
RUN dart compile exe bin/gateway_main.dart -o bin/gateway


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

COPY --from=builder /app/bin/gateway /app/gateway
COPY --from=builder /app/.dart_tool /app/.dart_tool

ENV PORT=9090
EXPOSE 9090

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
  CMD curl --fail http://localhost:9090/health || exit 1

CMD ["./gateway"]
