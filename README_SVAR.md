# Besvarelse PGR301 Eksamen 2026

## Oppgave 1A — Container

Multi-stage Dockerfile: første steg bygger JAR-filen med Maven og JDK, andre steg inneholder kun JRE og den ferdige JAR-filen. Build-verktøy og kildekode blir dermed ikke med i det endelige imaget.

Bygg og kjør (lytter på localhost:9999):

```bash
docker build -t wishifai .
docker run -p 9999:8080 \
  -e AWS_ACCESS_KEY_ID=<din-nøkkel> \
  -e AWS_SECRET_ACCESS_KEY=<din-hemmelige-nøkkel> \
  -e AWS_REGION=eu-west-1 \
  -e S3_BUCKET=<bucket-navn> \
  wishifai
```

Test: `curl http://localhost:9999/api/health`