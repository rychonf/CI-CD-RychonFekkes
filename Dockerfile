# Stage 1: Build the Spring Boot application
FROM maven:3.8.4-openjdk-17-slim AS builder

# Set working directory
WORKDIR /app

# Copy Maven files separately for better caching
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Download dependencies before copying source code to leverage Docker caching
RUN mvn dependency:go-offline

# Copy application source code
COPY src ./src

# Build the Spring Boot application
RUN mvn clean package -DskipTests

# Stage 2: Create a minimal runtime environment
FROM gcr.io/distroless/base:latest

# Set working directory
WORKDIR /app

# Copy the built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Use a non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Expose application port
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "app.jar"]