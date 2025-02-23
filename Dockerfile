# Stage 1: Build the application
FROM maven:3.8.4-openjdk-17-slim AS builder

# Werkdirectory instellen
WORKDIR /app

# Kopieer pom.xml en dependencies installeren
COPY pom.xml .
RUN mvn dependency:go-offline

# Kopieer de rest van de broncode
COPY src ./src
COPY src/main/resources/static/assets ./assets
# Bouw de applicatie
RUN mvn clean package -DskipTests

# Stage 2: Run the application
#FROM openjdk:17-jdk-slim
FROM gcr.io/distroless/java17-debian11 AS runtime

# Werkdirectory instellen
WORKDIR /app

# Kopieer het jar-bestand uit de builder stage
COPY --from=builder /app/target/*.jar app.jar
COPY --from=builder /app/assets ./assets

# Exposeer de poort waarop de applicatie draait
EXPOSE 3030

# Start de applicatie
ENTRYPOINT ["java", "-jar", "app.jar"]



# mvn package builden
# Multi staging van JDK naar JDE/ JDR
# Is er een workdir nodig?
# Docker run --rm
# In de best practices staat hoe je een nieuwe user toevoegd
# In de docker interface klikken op de image. kijk naar de layers en de copy. Dan kun je zien hoe klein het bestand mininmaal kan worden