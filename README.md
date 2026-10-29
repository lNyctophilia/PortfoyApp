# 💼 PortfoyApp — Kişisel Portföy ve Varlık Yönetimi

Modern, hızlı ve gizlilik odaklı masaüstü & mobil uyumlu **Portföy Takip ve Finansal Varlık Yönetimi** uygulaması. 

Yatırım fonları (TEFAS), BIST hisse senetleri, döviz, emtialar ve kripto paralarınızı tek bir ekrandan takip edin; **FIFO (İlk Giren İlk Çıkar)** kâr/zarar algoritması, dönemsel getiri performansları ve stopaj hesaplamalarıyla finansal durumunuzu analiz edin.

---

## ✨ Özellikler

### 📊 Çoklu Varlık Desteği
- **Yatırım Fonları (TEFAS):** Fon kodu ile anlık getiri, güncel fiyat ve detaylı stopaj oranları takibi.
- **Hisse Senetleri (BIST):** Borsa İstanbul hisseleri için canlı piyasa verileri ve performans metrikleri.
- **Döviz Kurları:** USD/TRY, EUR/TRY, GBP/TRY ve diğer para birimleri.
- **Emtia:** Gram Altın, Çeyrek Altın, Ons Altın, Gümüş vb.
- **Kripto Paralar:** Bitcoin (BTC), Ethereum (ETH) ve önde gelen kripto varlıklar.

### 🧮 Gelişmiş Finansal Hesaplamalar
- **FIFO (First-In, First-Out) Kâr/Zarar:** Finansal muhasebe standartlarına tam uyumlu, gerçekleşen ve gerçekleşmeyen net/brüt kâr/zarar hesaplaması.
- **Dönemsel Performans Analizi:** Günlük, haftalık, aylık, 3 aylık, 6 aylık ve yıllık getiri oranları.
- **Stopaj ve Vergi Desteği:** Varlık türüne ve fon niteliğine göre stopaj oranını otomatik düşerek net kâr gösterimi.
- **Ağırlık & Kategori Dağılımı:** Portföy içerisindeki varlık dağılımını gösteren görsel dağılım çubuğu.

### ⚡ Hızlı & Pratik Kullanım
- **Çoklu Portföy:** Farklı hedefler veya stratejiler için ayrı portföyler oluşturma ve yönetme.
- **Canlı & Otomatik Güncelleme:** Belirli aralıklarla arka planda otomatik fiyat güncellemesi.
- **Klavye Kısayolları:** `F5` tuşu ile tek dokunuşla tüm portföyleri ve fiyatları anlık yenileme.
- **Akıllı Otomatik Tamamlama:** Varlık sembolü ve fon aramalarında hızlı filtreleme ve otomatik tamamlama.

### 🔒 Gizlilik Odaklı & Yerel Depolama (Privacy-First)
- Verileriniz hiçbir harici sunucuya veya üçüncü tarafa gönderilmez.
- Tüm portföy ve işlem geçmişiniz yerel cihazınızda (`%APPDATA%/PortfoyApp` veya çalışma dizinindeki `portfolios_data.json`) güvenle saklanır.

---

## 🏗️ Proje Yapısı

```
PortfoyApp/
├── lib/
│   ├── dialogs/          # Portföy, varlık ve işlem ekleme/düzenleme pencereleri
│   ├── models/           # Veri modelleri (Portfolio, Asset, Transaction, Category)
│   ├── providers/        # State management (PortfolioProvider - ChangeNotifier)
│   ├── services/         # Piyasa verisi (MarketDataService), arama ve depolama (StorageService)
│   ├── theme/            # Tema tanımlamaları, renk paletleri ve stiller
│   ├── utils/            # FIFO hesaplayıcı, formatlayıcılar (para, tarih, yüzde)
│   ├── widgets/          # Kartlar, rozetler, dağılım grafiği ve özel ikon bileşenleri
│   └── main.dart         # Uygulama başlangıç noktası
├── test/                 # FIFO, stopaj, piyasa ve formatlayıcı birim (unit) testleri
├── windows/              # Windows masaüstü platform entegrasyonu
└── pubspec.yaml          # Bağımlılıklar ve paket konfigürasyonları
```

---

## 🚀 Başlangıç & Kurulum

### Gereksinimler
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.12+ veya üzeri)
- [Dart SDK](https://dart.dev/get-dart)
- Masaüstü geliştirme için: Visual Studio (C++ Masaüstü Geliştirme araçları ile)

### 1. Projeyi Klonlayın
```bash
git clone <repo-url>
cd PortfoyApp
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. Uygulamayı Çalıştırın
Windows üzerinde çalıştırmak için:
```bash
flutter run -d windows
```

Tarayıcı veya diğer desteklenen platformlarda çalıştırmak için:
```bash
flutter run
```

---

## 🧪 Testleri Çalıştırma

Projedeki birim testleri (FIFO mantığı, stopaj hesaplamaları, formatlayıcılar vb.) çalıştırmak için:

```bash
flutter test
```

---

## 🛠️ Kullanılan Teknolojiler ve Kütüphaneler

- **Framework:** [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
- **Durum Yönetimi (State Management):** `provider`
- **Tarih & Sayı Formatlama:** `intl`, `flutter_localizations`
- **Vektör & Grafikler:** `flutter_svg`, `cupertino_icons`
- **Linter & Kalite:** `flutter_lints`

---

## ⌨️ Kısayollar

| Kısayol | İşlev |
| :--- | :--- |
| `F5` | Tüm portföylerdeki piyasa verilerini ve fiyatları anlık yeniler |

---

## 📄 Lisans

Bu proje kişisel portföy yönetimi ve açık kaynak geliştirme amacıyla hazırlanmıştır.
