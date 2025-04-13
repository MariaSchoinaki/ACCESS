
FROM dart:stable AS builder

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY bin/ bin/
COPY lib/ lib/

RUN dart compile exe bin/search_main.dart -o bin/server


FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y libssl-dev ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/bin/server /app/server
COPY --from=builder /app/.dart_tool /app/.dart_tool

ENV PORT=8080
EXPOSE 8080

CMD ["./server"]