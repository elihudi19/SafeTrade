# SafeTrade — Backend (Awamu 1) + Mobile App Skeleton

Django + DRF backend ya SafeTrade, iliyojengwa kuanzia Render, ikiwa tayari
kwa uhamiaji rahisi kwenda AWS baadaye bila kuandika upya (angalia
`MIGRATION_TO_AWS.md`). Skeleton ya awali ya Flutter app iko `mobile_app/`.

## Maendeleo ya Ndani (Local Dev)

```bash
cp .env.example .env
docker-compose up --build
docker-compose exec web python manage.py makemigrations core
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser
docker-compose exec web python manage.py seed_fee_tiers
```

App itapatikana: http://localhost:8000/admin/

## Usajili wa Owner — NIDA + OTP (Badala ya Leseni)

Owner HAWEZI tena kuwasha duka kwa kupakia Leseni ya Biashara pekee —
badala yake:

1. `POST /api/auth/register-owner/` — anatoa `username`, `password`,
   `nida_number`, `phone_number`, `business_name`. Mfumo unapiga
   `core/services/nida.py::verify_identity()` kuhakikisha namba ya simu
   imesajiliwa rasmi kwa NIDA namba hiyo.
   - **Mismatch** → 400 error yenye ujumbe wazi, **HAKUNA OTP inayotumwa**.
   - **Match** → User + Business (`status=pending`) vinaundwa, OTP ya
     tarakimu 6 inatumwa kwa SMS (dakika 10 muda wake).
2. `POST /api/auth/verify-otp/` — OTP ikithibitika, akaunti inawashwa
   (`is_active=True`) na Business inakuwa `active` MOJA KWA MOJA.
3. `POST /api/auth/resend-otp/` — OTP mpya ikiisha muda.
4. `POST /api/auth/login/` — JWT login (SimpleJWT).

**NIDA_MOCK_MODE=True** (default kwenye `.env.example`) inakuwezesha
kupima mzunguko mzima bila muunganiko halisi wa NIDA (inakagua muundo
wa namba tu). **Badilisha kuwa `False` na weka credentials halisi kabla
ya wateja halisi**, la sivyo mtu yeyote ataweza "kuthibitishwa" bila
ukaguzi wa kweli.

## Mchanganuo wa Makato (Monetization Logic) — Jedwali Rasmi

| Aina ya Muamala | Ada ya Mteja | Ada ya Muuzaji |
|---|---|---|
| POS Offline (Cash bila SMS/Softcopy) | TZS 0 | Nusu Ada (40–1,000 kulingana na kiwango) |
| POS Digital & SMS (Lipa Namba/SMS/WhatsApp) | TZS 0 | Ada Kamili (80–2,000 kulingana na kiwango) |
| Marketplace Small Order (<100k) | TZS 200 (Fixed) | TZS 80 (Ada Kamili ya SMS) |
| Marketplace Large Order (100k+) | Fixed kulingana na daraja (500–2,500) | Nusu Ada (50–1,000) |
| Internal Ledger: Cashier Wallet → Business Wallet | — | TZS 0 (No Network Charge) |

Namba zote ni **fixed TZS amounts** (siyo asilimia), zimewekwa kwenye
`FeeTier` (ada ya muuzaji ya POS) na `MarketplaceFeeTier` (ada ya mteja
ya Marketplace) kupitia
`python manage.py seed_fee_tiers`. Mfumo **HAUWEZI kuruhusu muamala
kupita bila ada** — kama hakuna tier inayolingana, API inarudisha 400
error badala ya kuendelea kimya kimya.

## Branding (Logo ya SafeTrade)

Logo rasmi iko `static/branding/safetrade_logo.png` (backend/Django
Admin) na `mobile_app/assets/branding/safetrade_logo.png` (Flutter) —
faili moja, maeneo mawili ya matumizi. Tagline rasmi: **"Mauzo bila
kikomo"** — tayari kwenye Django Admin index title na Splash Screen ya
app.

## Muundo wa Mradi

```
config/                 Django project settings, urls, celery config
core/
  models.py              Models zote: Business, Store, User, OTPVerification,
                          Product, ShelfStock, StockTransfer, Shift, Receipt,
                          Marketplace, Wallet/Monetization (FeeTier,
                          MarketplaceFeeTier), PredictiveAlert, AuditLog
  serializers.py          DRF serializers (ikiwemo Owner registration/OTP)
  views.py                 Business logic: NIDA+OTP registration, handover
                          workflow, shift management, receipt creation,
                          offline sync, cart checkout, dashboard ya Owner
  permissions.py           Role-based permissions
  tasks.py                 Celery: SMS resend, kupiga Predictive Analytics
  services/predictive_analytics.py   Utabiri wa Akiba (v2) - angalia sehemu husika hapa chini
  services/fees.py          Monetization logic (POS + Marketplace fees)
  services/bolt.py           Bolt API integration - STUB
  services/nida.py           NIDA verification - STUB + Mock Mode
  services/sms.py             SMS gateway - STUB
  urls.py                  REST endpoints zote
mobile_app/              Flutter app skeleton (angalia mobile_app/README.md)
Dockerfile               Image moja inayotumika Render na AWS
docker-compose.yml       Local dev (db, redis, web, worker, beat)
render.yaml              Infrastructure-as-code kwa Render
MIGRATION_TO_AWS.md      Hatua kamili za kuhama siku utakapotaka
```

## Kilichojumuishwa (Wigo Kamili Bila Communication Module)

- ✅ Owner registration kwa NIDA + OTP (badala ya leseni)
- ✅ Business/Store/Staff management, na Security Alert System
- ✅ Stock Transfer handover workflow (Storekeeper → ACCEPT na Cashier)
- ✅ Receipt issuance (online + offline sync, hakuna edit/delete)
- ✅ Shift management (clock-in/out, "Funga Hesabu" na ripoti kiotomatiki)
- ✅ Anti-Theft: Discrepancy Flags, Audit Trail kamili
- ✅ Marketplace: Listings, Cart & Bulk Payments, Orders
- ✅ Delivery: Free/Custom mara moja; Bolt API ipo kama stub
- ✅ Monetization Logic: namba halisi za POS na Marketplace fees
- ✅ Predictive Analytics v2 (sales velocity, trend, siku-hadi-kuisha-stock,
  kiasi kinachopendekezwa cha kuagiza) kupitia Celery Beat + endpoint ya
  "recompute" ya papo hapo
- ✅ Flutter app skeleton (splash, login, register-owner, OTP)
- ❌ Communication Module (calls/chats) — imeondolewa kwa maombi yako
- ❌ Dashboard za ndani za Storekeeper/Cashier/Owner (Flutter) — bado

## Predictive Analytics (Utabiri wa Akiba) — v2

Toleo hili siyo tena "je, mauzo yamezidi reorder_level?" tu — ni reorder-
point engine halisi (`core/services/predictive_analytics.py`):

- **Sales velocity** — wastani wa mauzo ya kila siku (dirisha la siku 7
  na siku 30) kwa kila mchanganyiko wa (duka, bidhaa).
- **Mwenendo (trend)** — asilimia ya ongezeko/upungufu wa kasi ya wiki
  ya karibuni dhidi ya wastani wa mwezi.
- **Siku-hadi-kuisha-stock** — kutumia kasi ya sasa kukadiria ni lini
  stock itaisha, siyo tu "chini ya kiwango X".
- **Lead time ya bidhaa** (`Product.lead_time_days`, default siku 3) —
  alert ya "fast_moving" inatolewa MAPEMA iwapo stock itaisha KABLA
  mzigo mpya haujafika, siyo baada ya kufika sifuri.
- **Kiasi kinachopendekezwa cha kuagiza** — pendekezo halisi la namba
  (kasi ya sasa × lead time × kizio cha usalama 1.5), siyo tu "agiza".
- **Bidhaa za polepole** — hazijauzwa kabisa kwa siku 30, AU zina stock
  ya ziada isiyolingana na kasi ya mauzo (zaidi ya siku 60 za stock
  zilizosimama bila kuuzwa).

Endpoints:
- `GET /api/predictive-alerts/` — alerts zisizoshughulikiwa za Owner
- `POST /api/predictive-alerts/recompute/` — kokotoa upya papo hapo
  (badala ya kusubiri Celery Beat ya masaa 6)
- `POST /api/predictive-alerts/{id}/acknowledge/` — Owner ameshughulikia

Alerts zinakokotolewa upya kila run (siyo kuandikwa mara moja tu) ili
`detail_json` ibaki ya kisasa kila wakati.

## Marketplace: Mtiririko wa Malipo (Muuzaji Kwanza, Bolt kwa Escrow)

Sheria mpya (blueprint update): mteja analipa **kiasi kimoja** (bidhaa +
delivery) kwenye checkout, lakini pesa hizo hazifiki mahali pamoja kwa
wakati mmoja:

1. **Malipo ya muuzaji (thamani ya bidhaa) yanakamilika MARA MOJA** -
   `credit_seller_sale_proceeds()` inaongeza `subtotal_amount` kwenye
   Business Wallet papo hapo checkout inapokamilika, bila kusubiri
   delivery. Hii inatekelezwa kwenye `fees.py` na kuitwa moja kwa moja
   ndani ya `CartViewSet.checkout()`.
2. **Kwa Bolt PEKEE: pesa ya delivery haitolewi kwa dereva mpaka mteja
   athibitishe amepokea mzigo wake** - `DeliveryRequest.payment_released_to_courier`
   inabaki `False` mpaka `POST /api/orders/{id}/confirm-delivery/` iitwe.
   Kabla ya hapo, pesa hiyo "inashikiliwa" kimuundo (haijawahi kuguswa
   kabisa) - hakuna Wallet transaction ya ziada inayohitajika kuionyesha,
   kwa sababu tu haijawahi kuingizwa mahali popote.
3. **Free/Custom delivery**: siyo suala la SafeTrade kuishikilia (ni
   fedha ya duka lenyewe/dereva wake), kwa hiyo hazina escrow.
4. **Pickup (Mteja/mtu wake anachukua dukani mwenyewe)**: hakuna
   `delivery_fee` wala `DeliveryRequest` kabisa - `DeliveryOption.Kind.PICKUP`
   au `delivery_option=null` kwenye checkout.

Endpoint mpya: `POST /api/orders/{id}/confirm-delivery/` - Order
inayotumika kuashiria "nimepokea mzigo" (Customer), ikiwasha malipo ya
Bolt kama ilikuwa Bolt delivery.

**Muhimu**: `core/services/bolt.py::release_payment_to_courier()` bado ni
stub - haitoi pesa halisi kwa dereva (Bolt API haijaunganishwa bado).
Muundo wa escrow uko sahihi na tayari; unachohitaji ni credentials za
Bolt na wito halisi wa payment-capture API yao.

## Gharama na Faida/Hasara (Costing & Profit/Loss)

Sehemu hii ndiyo msingi wa uamuzi wa kibiashara — "je, ninapata faida au
hasara, na kwa kiasi gani?"

### 1. StockIntake — "Kila Mzigo Unapoingia Stoo"

`POST /api/stock-intakes/` (Storekeeper pekee) — badala ya kubadilisha
`ShelfStock` moja kwa moja (ambayo haikuwa na endpoint ya create kabisa
kwenye toleo la awali — pengo hili sasa limezibwa), Storekeeper LAZIMA
apitie hapa kila mzigo mpya unapoingia:

- `quantity_received` — idadi ya vipande HALISI
- `is_bundle_purchase` + `units_per_bundle` + `bundle_cost_price` — kama
  imenunuliwa kwa carton/kifungu, bei ya kipande inakokotolewa kiotomatiki
  (`bundle_cost_price / units_per_bundle`)
- `unit_cost_price` — kama SIYO bundle, bei ya kipande inatolewa moja kwa moja
- `transport_cost` na `other_costs` — **zimetengwa kabisa** kutoka kwa
  kila mmoja (kwa mujibu wa maombi yako), ili ripoti ziweze kuchambua
  usafiri dhidi ya gharama nyingine

Baada ya kuandikwa: `Product.cost_price` inasasishwa kiotomatiki (njia ya
"last cost" — bei ya mzigo wa mwisho), `ShelfStock` ya Warehouse
inaongezeka, na `suggested_min_selling_price` inakokotolewa
(`total_cost / quantity_received`) — hii ni **pendekezo tu**, si kikomo;
Owner/Cashier bado wanaamua bei ya kuuzia.

### 2. Expense — Gharama za Jumla za Biashara

`POST /api/expenses/` (Storekeeper/Owner) — gharama zisizo za mzigo
maalum (kodi, umeme, mishahara), zenye `category` (Usafiri umetengwa
kama category yake yenyewe) na `period` (kila siku/wiki/mwezi/mara moja)
ili ziweze kujumuishwa kwenye ripoti kwa usahihi.

### 3. Bei ya Kuuzia — Jumla/Rejareja, Uamuzi wa Cashier/Owner

`Product.unit_price` (rejareja) na `Product.wholesale_price` (jumla) ni
**chaguo-msingi za kumsaidia Cashier tu** — `ReceiptItem.unit_price`
inabaki *huru kuandikwa* kwa bei yoyote Cashier anayoiweka kulingana na
makubaliano na Mmiliki (kwa mujibu wa maombi: "ataamua sasa mwenye duka
na wafanyakazi wao wanaweka kiasi gani"). `ReceiptItem.sale_type`
(`retail`/`wholesale`) inarekodiwa kwa ripoti tu, haizuii bei.

### 4. Faida/Hasara — Papo Hapo kwa Kila Risiti

Kila `Receipt` inapoundwa, `apply_receipt_costing()` inanasa
`cost_price` ya WAKATI HUO (snapshot kwenye `ReceiptItem.cost_price_snapshot`
— hivyo faida inabaki sahihi hata `cost_price` ikibadilika baadaye), na
kukokotoa `Receipt.total_cost_of_goods` / `Receipt.gross_profit` papo hapo.

### 5. Ripoti ya Faida/Hasara

`GET /api/reports/profit-loss/?store=<id>&period=daily|weekly|monthly`
(Owner) — Mapato, COGS, Faida Ghafi, Gharama za Usafiri (zimetengwa),
Gharama Nyingine za Uendeshaji, na **Faida/Hasara Halisi (Net)**.
`OwnerDashboardView` (`/api/dashboard/store-overview/`) sasa inajumuisha
`today_net_profit` na `today_is_loss` kwa kila duka — hii ndiyo "alert ya
hasara/faida" iliyoombwa, inayoonekana moja kwa moja kwenye dashibodi.

### 6. Predictive Analytics — Utabiri wa Mwenendo wa Faida/Hasara

`core/services/predictive_analytics.py::run_business_trend_analytics()`
inachambua faida/hasara ya kila siku (siku 30 zilizopita) kwa kila duka,
inalinganisha wastani wa siku 7 dhidi ya siku 30, na inatoa:
- `PredictiveAlert.AlertType.LOSS_WARNING` — kama wastani wa faida ya
  siku 7 za karibuni ni HASARA, ikiwa na `recommendation` ya maandishi
- `PredictiveAlert.AlertType.PROFIT_TREND` — mwenendo wa faida (chanya),
  ikiwa na makadirio ya faida ya mwezi mzima kwa kasi ya sasa

Hizi ni tofauti na alerts za bidhaa (fast/slow moving) — `product` ni
`null` kwa alerts hizi za kibiashara (angalia `PredictiveAlert.product`
sasa ni `nullable`).

## Muhimu Kabla ya Kwenda Live

1. **Hakuna mtandao ndani ya mazingira niliyotengeneza nayo** — sikuweza
   kufanya `pip install`, `flutter pub get`, wala kupima
   `makemigrations`/`migrate`/`flutter analyze` halisi. Fanya haya
   kwenye kompyuta yako kwanza (maelekezo hapo juu). Ukipata error
   yoyote, niletee hapa nitairekebisha papo hapo.
2. **NIDA** (`core/services/nida.py`) — bado ni Mock Mode. Lazima
   upate credentials halisi za NIDA API na uzime `NIDA_MOCK_MODE`
   kabla ya wateja halisi.
3. **Bolt API** (`core/services/bolt.py`) — stub, inasubiri credentials
   na uthibitisho kuwa Bolt inatoa API kwa third-party delivery Tanzania.
4. **SMS Gateway** (`core/services/sms.py`) — stub, unahitaji kusajili
   na mtoa huduma (Beem, Africa's Talking) kwa Sender ID "SafeTrade".
5. **FeeTier/MarketplaceFeeTier** — lazima `seed_fee_tiers` iendeshwe
   kabla ya muamala wa kwanza.
6. **Wallet.balance ilikuwa haisasishwi kabisa** kwenye toleo la kwanza
   (WalletTransaction zilikuwa zinaandikwa lakini balance ya Wallet
   haikubadilika) - hii imerekebishwa sasa (`fees.py`), lakini kama
   una data ya majaribio uliyoiunda KABLA ya marekebisho haya, balance
   zake hazitakuwa sahihi - futa na uanze upya, au andika script ya
   kurekebisha (backfill) kwa data ya uzalishaji halisi.
7. **`Product.lead_time_days`** ni field mpya (default siku 3) muhimu
   kwa Predictive Analytics - badilisha thamani halisi kwa kila bidhaa
   kupitia Django Admin kulingana na muda halisi wa uagizaji wako.
8. **`Product.cost_price` inaanza kuwa 0** kwa bidhaa zote mpaka
   Storekeeper aandike `StockIntake` ya kwanza kwa bidhaa hiyo — kabla
   ya hapo, faida ya risiti itaonekana kuwa 100% ya mauzo (COGS=0), jambo
   ambalo si kweli. **Andika StockIntake kwa bidhaa zote ZILIZOPO kabla
   ya kuanza kuuza**, la sivyo ripoti za faida/hasara zitakuwa potofu.
9. **`get_daily_net_profit_series()`** (Predictive Analytics ya faida)
   inafanya query nyingi (moja kwa kila siku ya 30) kwa kila duka kila
   ikiendeshwa - inatosha kwa maduka machache ya mwanzo lakini itahitaji
   kuboreshwa (mfano: cache ya kila siku iliyokwisha pita, ambayo
   haiwezi kubadilika tena) endapo idadi ya maduka itaongezeka sana.

## Deploy Render

1. Push repo hii kwenye GitHub.
2. Render → New → Blueprint → chagua repo → itasoma `render.yaml`
   kiotomatiki na kuunda: web service, celery worker, celery beat,
   PostgreSQL, Redis.
3. Ongeza env vars za siri (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
   `AWS_STORAGE_BUCKET_NAME`, `NIDA_API_KEY`, `SMS_API_KEY`, n.k.) kwenye
   dashboard ya Render.
4. Run migrations + seed: Render Shell →
   `python manage.py migrate && python manage.py seed_fee_tiers`.
