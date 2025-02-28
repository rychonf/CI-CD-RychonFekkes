# Stage 1: Build the application
# Gebruik een specifieke Maven-versie en een minimalistische OpenJDK 17 image
FROM maven:3.8.4-openjdk-17-slim AS builder

# Werkdirectory instellen
WORKDIR /app

# Omgevingsvariabelen instellen (indien nodig voor build)
ENV MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"

# Minimaliseer lagen door in één stap dependencies te installeren en de code te kopiëren
COPY pom.xml ./
RUN mvn dependency:go-offline

# Kopieer de rest van de broncode
COPY src ./src
COPY src/main/resources/static/assets ./assets

# Bouw de applicatie, waarbij tests worden overgeslagen om de buildtijd te verkorten
RUN mvn clean package -DskipTests

# Stage 2: Run the application
# Gebruik een lichtgewicht productiebase image
FROM gcr.io/distroless/java17-debian11 AS runtime

# Werkdirectory instellen
WORKDIR /app

# Kopieer het jar-bestand uit de builder stage
COPY --from=builder /app/target/*.jar app.jar
COPY --from=builder /app/assets ./assets

# Voeg een niet-root gebruiker toe voor betere beveiliging
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Exposeer de poort waarop de applicatie draait
EXPOSE 3030

# Start de applicatie
CMD ["java", "-jar", "app.jar"]