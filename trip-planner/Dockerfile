# Ballerina 2201.14 (ballerina/a2a 0.8.0 needs it; the platform's Ballerina buildpack is 2201.13 only).
FROM ballerina/ballerina:2201.14.0
WORKDIR /home/ballerina/agent
COPY --chown=ballerina:ballerina . .
RUN bal build
EXPOSE 9090
CMD ["bal", "run", "target/bin/trip_planner.jar"]
