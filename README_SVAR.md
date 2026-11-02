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

## Oppgave 1B — CI-pipeline

Workflow: `.github/workflows/deploy.yml`
Url for kjøring: https://github.com/Kelvin-Tang04/PGR301-eksamen-2026/actions/runs/41489052079

**Tagging-strategi:** Imaget tagges med commit-SHA (`github.sha`). Hver tag er dermed unik og kan spores direkte tilbake til commiten den er bygget fra, slik at man alltid vet hvilken kode som kjører hvor. Det gjør også rollback enkelt, fordi man kan deploye et tidligere image ved å angi en eldre SHA. `latest` brukes ikke, fordi den alltid peker på siste push og ikke sier noe om hvilken versjon som faktisk kjører. 