# SafeTrade Mobile/Desktop App (Flutter)

App moja (Android/iOS/Windows/macOS/Linux) inayowasiliana na SafeTrade
Backend. **Imeandikwa kwa mkono bila Flutter SDK kufungwa kwenye
mazingira niliyotengeneza nayo — haijawahi kupitia `flutter analyze`
wala kuendeshwa kwenye kifaa/emulator halisi.** Hii ndiyo hatua yako ya
kwanza kabla ya kuamini inafanya kazi 100%.

## ⚠️ HATUA YA KWANZA KABISA: Bado Hakuna android/ios Folders

Mradi huu HAUJAWAHI kupitia `flutter create` (hakuna Flutter SDK
kwenye mazingira yangu) - kuna `pubspec.yaml` na `lib/` pekee. Kabla ya
`flutter run`, fanya:

```bash
cd mobile_app
flutter create . --org com.safetrade --project-name safetrade_app
```

Hii itaunda `android/`, `ios/`, `windows/`, `macos/`, `linux/` folders
BILA kugusa `lib/` yako iliyokwisha-andikwa (Flutter haiandiki upya
`lib/` iliyopo). Kisha:

```bash
flutter pub get
```

### Bluetooth Permissions (LAZIMA kwa Printer)

Baada ya `flutter create`, ongeza kwenye
`android/app/src/main/AndroidManifest.xml` (ndani ya `<manifest>`,
nje ya `<application>`):

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

(BLUETOOTH_CONNECT/SCAN ni za Android 12+; ACCESS_FINE_LOCATION
inahitajika na baadhi ya vifaa vya Android kwa Bluetooth scanning hata
kwenye matoleo ya zamani.)

## Kilichokamilika

### Uthibitisho (NIDA + OTP)
- Splash, Login, Register Owner (NIDA + Simu), OTP verification
- Role Router - baada ya login, inasoma `/auth/me/` na kuelekeza
  dashboard sahihi

### Storekeeper (Vipengele Vipya: Gharama)
- **"Ongeza Mzigo Mpya"** (`StockIntakeCreateScreen`) — bei ya ununuzi
  (kwa kipande au kwa carton/kifungu — inakokotoa moja kwa moja), gharama
  ya usafiri na gharama nyingine ZIMETENGWA, na inaonyesha bei ya chini
  kabisa isiyo na hasara KABLA ya kuhifadhi
- **"Ongeza Gharama"** (`ExpenseCreateScreen`) — gharama za jumla (kodi,
  umeme, mishahara) zenye category na kipindi (siku/wiki/mwezi)

### Cashier (Kimeboreshwa: Jumla/Rejareja + Bei Inayobadilika)
- Toggle ya **Rejareja/Jumla** juu ya orodha ya bidhaa - inabadilisha bei
  ya chaguo-msingi kwa bidhaa zote
- Kila bidhaa ina **kitufe cha kuhariri bei** (✏️) - Cashier anaweza
  kuweka bei yoyote kulingana na makubaliano na Mmiliki; akiweka bei
  chini ya gharama ya ununuzi, anaonywa (lakini hazuiwi)
- Clock-in/out, ACCEPT ya mzigo
- Kukata risiti: stock inatoka **StockCacheService** (live + offline
  cache salama), **printer halisi ya Bluetooth ESC/POS**, foleni ya
  offline kwa risiti
- Mipangilio ya Printer (scan/pair/test print)

### Owner (Kimeboreshwa: Faida/Hasara)
- Dashboard: muhtasari wa maduka + **kadi ya Faida/Hasara ya Leo** (rangi
  nyekundu = hasara, kijani = faida, inabofya kwenda ripoti kamili) +
  **Predictive Analytics** (bidhaa: siku-hadi-kuisha-stock, mwenendo,
  kiasi cha kupendekezwa kuagiza; **biashara: onyo la hasara na mwenendo
  wa faida**) yenye vitufe vya "Kokotoa Upya" / "Nimeshughulikia"
- `ProfitLossReportScreen` — ripoti kamili (Mapato, COGS, Faida Ghafi,
  Usafiri, Gharama Nyingine, Net) kwa siku/wiki/mwezi
- Kuunda Storekeeper/Cashier

### Customer (Marketplace)
- Kuvinjari, Cart, **Delivery selection (Pickup/Free/Bolt/Custom)**,
  Checkout, Order History, **"Nimepokea Mzigo" (confirm-delivery kwa Bolt)**

### Lugha Mbili (Kiswahili cha Tanzania + English)
- `l10n/app_strings.dart` — kamusi kamili ya maneno ya UI
- `state/locale_controller.dart` — inahifadhi chaguo la lugha kwenye kifaa
- `widgets/language_switcher.dart` — kitufe cha SW/EN kwenye kila AppBar
- Default ni Kiswahili (soko la Tanzania), badilika papo hapo bila
  ku-restart app

### Offline (Imeboreshwa Zaidi)
- `local/local_database.dart` — SQLite moja ya pamoja
- Risiti: foleni + sync + **auto-sync kupitia ConnectivityWatcher**
  (mtandao ukirudi, sync inajaribiwa moja kwa moja bila kusubiri
  mtumiaji afungue dashboard)
- **Stock cache ya Kaunta** (`local/offline_stock_store.dart`) - Cashier
  anaweza kuuza akiwa offline BILA hatari ya kuuza zaidi ya kilichopo
  (cache inapungua mara moja baada ya kila muuzo wa offline)
- Stock Transfer offline queue (Storekeeper)

## KIPI BADO SIYO "KAMILI" (Kwa Uwazi Kabisa)

0. **Product.cost_price inaanza 0 kwa bidhaa zote** mpaka Storekeeper
   aandike StockIntake ya kwanza - kabla ya hapo, ripoti za faida
   zitaonekana kubwa isivyo kweli (COGS=0). Andika StockIntake kwa
   bidhaa ZOTE zilizopo dukani KABLA ya kuanza kutumia mfumo huu wa
   ripoti kwa uzito.

1. **Migogoro kati ya VIFAA VIWILI tofauti vinavyofanya kazi offline kwa
   wakati mmoja** bado hayawezi kuzuiwa kikamilifu na muundo huu -
   yataonekana tu kama `DiscrepancyFlag` baada ya sync (angalia maelezo
   kwenye `offline_stock_store.dart`). Kwa duka lenye Cashier mmoja
   anayefanya kazi wakati mmoja, hatari hii ni ndogo sana kivitendo.
2. **Printer ya Bluetooth (`print_bluetooth_thermal` +
   `esc_pos_utils_plus`) HAIJAWAHI kujaribiwa na kifaa halisi.** Nimefuata
   API rasmi ya packages hizi kwa uangalifu, lakini:
   - `BluetoothInfo.macAdress` ni jina la field lenye typo ya kihistoria
     kwenye package hii ("macAdress" siyo "macAddress") - kama toleo
     jipya limebadilisha jina hili, `flutter analyze` itaonyesha error
     - badilisha jina la field kulingana na ilivyoonekana.
   - Muundo wa risiti (`ThermalPrinterService.printReceipt`) umejengwa
     kwa printa za kawaida za 58mm - kama yako ni 80mm au ina muundo
     tofauti, `PaperSize` na column widths zinaweza kuhitaji marekebisho.
3. **Bolt payment-capture** (`core/services/bolt.py::release_payment_to_courier`)
   bado ni stub - escrow LOGIC iko sahihi (pesa haitolewi mpaka
   confirm-delivery), lakini hakuna muunganiko halisi wa kutuma pesa
   kwa Bolt bado.
4. **Delivery fee ya Bolt kwenye Cart ni 0 kila wakati** kwa sasa (hakuna
   quote endpoint halisi) - checkout inakubali `bolt_estimated_fee` ya
   hiari kutoka kwa client lakini app HAITUMII bado field hii kwenye
   `cart_screen.dart` UI (ni tayari upande wa backend, lakini UI
   haijaongeza input ya makadirio).
5. **Kamusi ya tafsiri (`app_strings.dart`) haijafunika 100% ya maneno
   yote madogo** - baadhi ya maandiko ya ndani kabisa (mfano baadhi ya
   michanganyiko ya maneno kwenye orodha za predictive alerts) bado ni
   Kiswahili pekee bila EN sanjari, lakini muundo mkuu (AppBar titles,
   vitufe vikubwa, fomu zote za input) umefunikwa vizuri sana kwa lugha
   zote mbili.
6. **Hakuna majaribio (widget/unit tests).**
7. **State management ni ya kimsingi** (`Session()` inaundwa upya kwa kila
   screen badala ya `ChangeNotifierProvider` moja kwenye `main.dart`) -
   inafanya kazi lakini si mazoezi bora ya muda mrefu.

## Jinsi ya Kuanza Kupima

```bash
cd mobile_app
flutter create . --org com.safetrade --project-name safetrade_app
# ongeza Bluetooth permissions kwenye AndroidManifest.xml (angalia juu)
flutter pub get
flutter analyze              # itaonyesha makosa yoyote ya kurekebisha
flutter run --dart-define=API_BASE_URL=http://<ip-ya-backend>:8000/api
```

Ukipata error yoyote kutoka `flutter analyze` au wakati wa `flutter run`,
niletee ujumbe kamili wa error - tutarekebisha pamoja hatua kwa hatua.

## Muundo wa Folda

```
lib/
  main.dart                 Provider ya LocaleController + ConnectivityWatcher
  l10n/
    app_strings.dart         Kamusi ya SW/EN
    tr.dart                  Helper function tr(context, 'key')
  models/                   Data classes
  services/                 API calls + business logic (offline-aware)
  state/                    Session, LocaleController
  local/                    SQLite: receipts, stock cache, stock transfers
  widgets/
    language_switcher.dart   Kitufe cha SW/EN
  screens/
    login_screen.dart, register_owner_screen.dart, otp_verification_screen.dart
    role_router_screen.dart, splash_screen.dart
    owner/          Dashboard (+ Predictive Analytics) + Staff creation
    storekeeper/    Dashboard + Stock Transfer (+ offline queue)
    cashier/        Dashboard + Receipt creation (+ printer + offline) + Printer Settings
    customer/       Marketplace + Cart (+ Pickup/Delivery) + Order History (+ confirm delivery)
assets/branding/    Logo ya SafeTrade
```
