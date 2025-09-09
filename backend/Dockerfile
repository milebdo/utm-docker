# Use existing WAR file
FROM eclipse-temurin:11-jre-focal

# Runtime stage
FROM eclipse-temurin:11-jre-focal

# Create app user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy the existing WAR file
COPY target/utmstack.war ./

# Change ownership to app user
RUN chown -R appuser:appuser /app

# Switch to app user
USER appuser

# Health check
HEALTHCHECK --start-period=60s --interval=60s --timeout=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "utmstack.war"]
