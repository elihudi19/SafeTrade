# Mwongozo wa Kuhama: Render → AWS

Mradi huu umejengwa kimakusudi ili kuhama kusiwe "kuandika upya mfumo" bali
"kubadilisha environment variables + kuhamisha data." Hii ndiyo sababu:

- Django haijui kama iko Render au AWS — inasoma kila kitu kutoka `env vars`.
- Docker image ile ile (`Dockerfile`) inatumika sehemu zote mbili.
- `DATABASE_URL` na `REDIS_URL` ni muundo wa kawaida wa Postgres/Redis
  unaoeleweka na huduma yoyote (Render, AWS RDS, ElastiCache, hata local).
- Faili (leseni, softcopy receipts, picha za bidhaa) tayari zinahifadhiwa
  S3 tangu siku ya kwanza (`STORAGE_BACKEND=s3`) — kwa hiyo hakuna "uhamiaji
  wa faili" utakaohitajika kabisa ukitumia AWS S3 halisi tangu mwanzo.

## Hatua za Kuhama (siku utakapoamua)

### 1. Database (PostgreSQL)
```bash
# Render -> faili la ndani
pg_dump "$RENDER_DATABASE_URL" -Fc -f safetrade_backup.dump

# Weka kwenye AWS RDS mpya
pg_restore --no-owner --dbname="$AWS_RDS_DATABASE_URL" safetrade_backup.dump
```
Kwa muda mfupi wa "downtime window", unaweza kufanya `pg_dump` mara mbili
(mara ya kwanza kabla ya kuhamisha trafiki, mara ya pili dakika chache kabla
ya kubadilisha DNS/env vars) ili kuepuka kupoteza rekodi za mwisho.

### 2. Faili (S3)
Kama ulianza na `STORAGE_BACKEND=s3` ukitumia AWS S3 halisi tangu Render
(tunapendekeza hivi), **hakuna hatua inayohitajika** — bucket ile ile
inaendelea kutumika, unabadilisha tu `AWS_ACCESS_KEY_ID`/role permissions
kama zilikuwa specific kwa Render IAM user.

Kama ulitumia S3-compatible provider nyingine (si AWS), fanya:
```bash
aws s3 sync s3://old-bucket s3://new-aws-bucket
```
kisha badilisha `AWS_S3_ENDPOINT_URL` kuwa tupu (AWS S3 halisi haihitaji
endpoint maalum).

### 3. Redis
ElastiCache haihifadhi data ya kudumu inayohitaji kuhamishwa (ni queue/cache
tu ya muda mfupi) — unda instance mpya AWS, weka `REDIS_URL` mpya, maliza.

### 4. Application (Docker image)
```bash
docker build -t safetrade:latest .
docker tag safetrade:latest <account>.dkr.ecr.<region>.amazonaws.com/safetrade:latest
docker push <account>.dkr.ecr.<region>.amazonaws.com/safetrade:latest
```
Tumia `render.yaml` kama "checklist" ya services za kuunda upande wa ECS:
- `safetrade-web` → ECS Service (Fargate) + Application Load Balancer
- `safetrade-celery-worker` → ECS Service nyingine (bila load balancer)
- `safetrade-db` → RDS PostgreSQL (Multi-AZ)
- `safetrade-redis` → ElastiCache Redis

### 5. Kubadilisha DNS
Elekeza domain kwenye AWS Load Balancer, subiri TTL imalizike, kisha
zima Render services.

## Kanuni ya Dhahabu
Kamwe usiongeze kitu chochote maalum cha Render (mfano Render Disks za
kudumu, Render-specific env vars zisizo za kawaida) kwenye `settings.py`.
Ukiwa na shaka kama kipengele fulani ni "portable," jiulize: *"Je AWS RDS/
ElastiCache/S3 inaweza kutoa hii bila mabadiliko ya code?"* Kama jibu ni
hapana, tafuta njia mbadala ya jumla (generic) badala yake.
