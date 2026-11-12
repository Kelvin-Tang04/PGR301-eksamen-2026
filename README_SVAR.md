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
Url: https://github.com/Kelvin-Tang04/PGR301-eksamen-2026/actions/runs/41489052079

**Tagging-strategi:** Imaget tagges med commit-SHA (`github.sha`). Hver tag kan dermed spores tilbake til commiten den er bygget fra, og det er enkelt å rulle tilbake ved å deploye en eldre SHA. `latest` alene sier ikke hvilken versjon som faktisk kjører.

## Oppgave 2A — Infrastruktur for tjenesten

Terraform-koden i `infra/` oppretter en ECS Express-tjeneste, en S3-bucket for bilder og task-rollen `wishifai-task-role-6` med tilgang til S3, Rekognition, Bedrock og CloudWatch. `S3_BUCKET` settes automatisk fra bucketen Terraform oppretter.

Offentlig URL: https://wi-37426755399142ab86e99763799ac9cf.ecs.eu-west-1.on.aws (test med `/api/health`)

## Oppgave 2B — Remote state

State lagres i `pgr301-terraform-state` med nøkkelen `wishifai/6/terraform.tfstate`. Kandidatnummeret i nøkkelen gjør den unik.

## Oppgave 2C — Terraform i pipeline

Workflowen har to jobber: `build-push` bygger og pusher imaget til ECR, og `deploy` kjører `terraform fmt -check`, `init` og `apply` mot `infra/`. `deploy` er avhengig av `build-push` via `needs:`.

Url: https://github.com/Kelvin-Tang04/PGR301-eksamen-2026/actions/runs/41667324023

**Hvorfor Terraform kjører etter container-build:** Terraform deployer tjenesten med image-taggen fra samme commit. Kjørte Terraform før eller parallelt med bygget, kunne ECS forsøke å starte et image som ennå ikke finnes i ECR, og deployen ville feilet. Med `needs:` blir Terraform bare kjørt hvis bygget og pushen lyktes.

## Oppgave 3A — Metrikker i applikasjonen

Metrikkene publiseres til CloudWatch i namespacet `wishifai-6-l`.

- `bedrock.suggest_gifts`, `rekognition.detect_labels` og `s3.upload` (Timer): måler tiden for hvert eksterne kall, slik at det er mulig å se hvilket steg som gjør tjenesten treg.
- `wishlist.analyses` (Counter): antall analyserte bilder, som viser hvor mye tjenesten brukes.
- `wishlist.suggestions` (DistributionSummary): antall gaveforslag per analyse, som viser om Bedrock leverer det forventede antallet forslag (inntil 5).
- `wishlist.labels` (DistributionSummary): antall objekter Rekognition finner per bilde, som sier noe om hvor godt grunnlag Bedrock får. Denne er ikke med i dashboardet, men er tilgjengelig i CloudWatch.

## Oppgave 3B — Dashboard og alarm

**Terraform-kode:** `infra/dashboard.tf` og `infra/alarm.tf`

**Dashboard:** `wishifai-6-l`

![CloudWatch-dashboard, business-metrikker](img/dashboard1.png)
![CloudWatch-dashboard, applikasjon og infrastruktur](img/dashboard2.png)

**Metrikkene:**
- **Business:** bilder analysert og gaveforslag per analyse viser bruken og hva brukeren får ut av tjenesten.
- **Applikasjon:** tid per kall viser hvilket steg som er tregest. HTTP-latens og JVM-heap viser svartid og minnebruk.
- **Infrastruktur:** ECS CPU og minne viser om containeren har nok ressurser.

**Hvor blir tiden av:** Bedrock tar ca. 16 av totalt ca. 17 sekunder, mens Rekognition og S3 tar under 0,1 sekund. CPU og minne er lavt, så flaskehalsen er Bedrock og ikke infrastrukturen.

**Alarm:** `wishifai-6-l-bedrock-latency` sender e-post via SNS når Bedrock-kallet tar over 20 sekunder. Bedrock står for over 90 % av svartiden, og normal tid er ca. 16 sekunder, så 20 sekunder fanger en reell forverring uten å reagere på vanlig variasjon.

## Oppgave 4 — Drøfteoppgave

Bruk av generativ kunstig intelligens (AI) stiller andre krav til DevOps enn tradisjonell programvareutvikling. Språkmodeller kan gi ulike svar på samme forespørsel, og selv om en applikasjon fungerer teknisk, er det ingen garanti for at innholdet er relevant eller trygt. Testing, kontinuerlig leveranse og overvåking må derfor tilpasses både teknologien og konsekvensene eventuelle feil kan få.

**Testing**

Tradisjonell programvaretesting undersøker gjerne om en bestemt input gir et forventet resultat. Dette er mer utfordrende med generativ AI, ettersom flere ulike svar kan være akseptable. I min Wishifai-løsning inneholder pipelinen ingen automatiserte tester av gaveforslagene. Den benytter blant annet terraform fmt -check, som kontrollerer formateringen av Terraform-koden, men ikke kvaliteten på anbefalingene.

Jeg mener derfor at testingen bør utvides med representative forespørsler som undersøker om forslagene er relevante, trygge og tilpasset mottakeren. Resultatene kan vurderes opp mot forhåndsdefinerte kriterier. For applikasjoner som gir medisinske eller juridiske råd, bør testingen være mer omfattende og inkludere vurderinger fra fagpersoner før produksjonssetting.

**Kontinuerlig leveranse**

I Wishifai benyttes SHA-tagging for å identifisere hvilken kodeversjon som kjører. Prompten er imidlertid hardkodet i BedrockService.java, mens modell-ID-en angis gjennom en miljøvariabel. En endring av modellversjonen kan dermed påvirke anbefalingene uten at SHA-taggen endres.

Etter min vurdering bør både prompt og modellversjon dokumenteres og versjoneres. Endringer bør testes før utrulling, slik at eventuelle kvalitetsproblemer kan oppdages tidlig. Det bør også være mulig å gå tilbake til en tidligere versjon dersom endringene gir dårligere resultater. I applikasjoner med høy risiko bør større endringer kreve manuell godkjenning.

**Overvåking**

Overvåkingen i Wishifai viser hvorfor tekniske målinger alene ikke er tilstrekkelige. CloudWatch-alarmen fra oppgave 3B varsler dersom Bedrock bruker for lang tid på å svare, men oppdager ikke upassende anbefalinger. Et raskt svar med et farlig gaveforslag til et barnerom vil derfor ikke utløse alarmen.

Metrikken wishlist.suggestions fra oppgave 3A registrerer antall forslag, men sier ingenting om kvaliteten. Dashboardet kan dermed vise fem forslag selv om innholdet er lite relevant. Jeg mener derfor at overvåkingen bør suppleres med brukertilbakemeldinger og regelmessige kvalitetskontroller.

**Risiko og ansvar**

I min løsning sendes anbefalingene fra Bedrock direkte til brukeren uten filtrering eller guardrails. Selv om konsekvensene av feilaktige gaveforslag vanligvis er begrensede, kan tilsvarende feil innen juridisk eller økonomisk rådgivning få alvorlige følger.

Jeg mener derfor at kontrolltiltakene må tilpasses risikoen. I en gaveapplikasjon kan mindre relevante forslag håndteres gjennom tilbakemeldinger og forbedringer etter lansering. I løsninger med høy risiko bør potensielt skadelige svar derimot avdekkes gjennom grundig testing og menneskelig kontroll før produksjonssetting. Ansvarlig bruk av generativ AI forutsetter dermed at DevOps-praksisene ivaretar både teknisk stabilitet og kvaliteten på innholdet.

