# Stage 1: Bouwt de Spring Boot applicatie
FROM eclipse-temurin:17-jre AS builder

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

# Download dependencies before copying source code to leverage Docker caching
#RUN mvn dependency:go-offline

# Kopieert de broncode van de applicatie
COPY src ./src

# Build the Spring Boot application
RUN mvn clean package -DskipTests

# Stage 2: Create a minimal runtime environment
FROM adoptopenjdk:17-jre-slim

# Set working directory
WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Omgevingsvariabelen instellen voor databaseconfiguratie en logging
ENV SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/mydatabase \
    SPRING_DATASOURCE_USERNAME=root \
    SPRING_DATASOURCE_PASSWORD=securepassword \
    LOGGING_LEVEL_ROOT=INFO \
    LOGGING_FILE_NAME=/app/logs/app.log

# Zorg ervoor dat de logs directory bestaat en rechten juist zijn ingesteld
RUN mkdir -p /app/logs && chmod -R 777 /app/logs

 #Systeempakketten installeren en opruimen (LibSSL3 en curl)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Expose application port
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "app.jar", "--logging.file.name=/app/logs/app.log"]