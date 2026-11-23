# Ballerina 2201.14 (ballerina/a2a 0.8.0 needs it; the platform's Ballerina buildpack is 2201.13 only).
FROM ballerina/ballerina:2201.14.0
WORKDIR /home/ballerina/agent
# The image runs as user ballerina (uid 100), group troupe (gid 1000). Numeric ids work with every builder.
COPY --chown=100:1000 . .
RUN bal build
EXPOSE 9090
CMD ["bal", "run", "target/bin/weather.jar"]
