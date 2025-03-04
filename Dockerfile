# Stage 1: Bouw de Spring Boot applicatie
FROM maven:3.8.4-eclipse-temurin-17 AS builder

# Set de working directory
WORKDIR /app

# Omgevingsvariabelen instellen voor betere controle
# Dit versnelt de built en verbruikt minder CPU
ENV MAVEN_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1"

# Kopieeren van bestanden naar de container image
# Kopieert de maven configuratie bestanden voor gebruik van caching
COPY pom.xml mvnw ./
# Kopieert de map waar de maven wrapper zich bevind
COPY .mvn .mvn

# Download de depencies voordat de broncode wordt gekopieert (caching)
RUN mvn dependency:go-offline

# Kopieert de broncode van de applicatie
COPY src ./src

# Bouwt de springboot applicatie
RUN mvn clean package -DskipTests

# Stage 2: maak een minimale runtime omgeving
FROM eclipse-temurin:17-jre-alpine

# Zet de werkmap
WORKDIR /app

# Kopieert de bouw JAR vanuit de bouwfase
COPY --from=builder /app/target/*.jar app.jar

# Zorg ervoor dat de logs directory bestaat en rechten juist zijn ingesteld
RUN mkdir -p /app/logs && chmod -R 777 /app/logs

#Systeempakketten installeren en opruimen (LibSSL3 en curl)
RUN apk update && apk add --no-cache \
    libssl3 curl ca-certificates

# Expose de applicatie poort voor betere beveiliging
EXPOSE 1010
ENV SERVER_PORT=1010

# Run de applicatie
CMD ["java", "-jar", "app.jar", "--logging.file.name=/app/logs/app.log"]