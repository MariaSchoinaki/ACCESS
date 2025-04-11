# Use Dart SDK base image
FROM dart:stable

# Create app directory
WORKDIR /app

# Copy pubspec and resolve dependencies first (layer caching)
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the project
COPY . .

# Optional: precompile to native (if you want faster startup)
# RUN dart compile exe bin/server.dart -o bin/server

# Set environment vars
ENV PORT=8080

# Expose the port
EXPOSE 8080

# Run the server
CMD ["dart", "bin/search_service.dart"]
# Or, if precompiled:
# CMD ["./bin/server"]
