# Self CarWash - Randevu & Rezervasyon Sistemi

Bu proje, araç yıkama randevu sistemini hem web hem de mobil platformda yönetmek amacıyla geliştirilmiştir. Kullanıcılar kayıt olabilir, giriş yapabilir ve uygun tarih/saat seçerek randevu oluşturabilir.

---

## 📋 Proje Tasarım Durumu

### Frontend

#### Login-Register Sistemi
Uygulamayı başlattığımızda ilk başta karşımıza bir login-register ekranı çıkıyor.

<img width="400" alt="Login Ekranı" src="https://github.com/user-attachments/assets/c83bcda3-65da-48b6-8be5-5f5a0f49ecd4" />

Kayıt olmak istediğiniz takdirde "Kayıt ol" butonuna basarak ad, soyad, e-posta, telefon ve şifrenizi girerek güvenli bir şekilde kaydolabilirsiniz.

<img width="400" alt="Kayıt Ekranı" src="https://github.com/user-attachments/assets/e59fd598-43b1-4385-b21c-4e7a6fde4e23" />

#### Ana Sayfa Kısmı
Kayıt olup giriş yaptıktan sonra karşımıza bir Türkiye haritası geliyor. Bu harita üzerinden randevu almak istediğiniz bayiyi seçebilme imkanı sunulur. Alt butonlar sayesinde randevular ve profil sayfanıza geçiş yapabilirsiniz.

<img width="400" alt="Ana Sayfa - Harita" src="https://github.com/user-attachments/assets/3c3686fe-083e-4f08-99d1-c8d8ca84dac7" />

#### Randevular Kısmı
Randevular sekmesine geldiğimizde karşımıza basit bir randevu oluşturma kısmı geliyor. Randevu oluştururken ilk başta araç plakası girilir, devamında arabaya yapılacak hizmetin türü seçilir. Ardından tarih ve saat seçildikten sonra "Randevu Al" butonuna basılır ve randevu başarıyla oluşturulur. Ayrıca oluşturduğumuz randevunun sağında bulunan "Düzenle" ve "Sil" butonlarını kullanarak randevuyu düzenleyebilir veya silebiliriz.

<img width="448" height="895" alt="image" src="https://github.com/user-attachments/assets/2182c2f0-5147-4d24-8439-0761b1e21b04" /> <img width="446" height="898" alt="image" src="https://github.com/user-attachments/assets/0eec14d7-af3f-43f0-8431-dd8fddc6b5b5" />



#### Profil Kısmı
Profil kısmına geldiğimizde önümüze basit bir ad-soyad, e-posta ve telefon numarası bilgilerinin görüleceği kısım karşımıza çıkıyor. Sağ üstte başta da dediğimiz gibi "Çıkış Yap" butonu ortaya çıkıyor. Butona basarak çıkış yapabilirsiniz.

<img width="400" alt="Profil Sayfası" src="https://github.com/user-attachments/assets/e579f8fc-f500-4a03-9153-275e87d6d67a" />

---

### Backend

#### Login-Register Sistemi
Kullanıcı giriş–kayıt işlemleri için ASP.NET Core Web API üzerinde çalışan bir Authentication Controller (AuthController) geliştirilmiştir.


[HttpPost("register")]
public IActionResult Register([FromBody] User user)

[HttpPost("login")]
public IActionResult Login([FromBody] LoginRequest request)


#### Veritabanı Sistemi
Kimlik doğrulama sistemi için MySQL üzerinde Users tablosu oluşturulmuştur. Her kullanıcı şu alanlarla saklanmaktadır:

| Alan | Açıklama |
|------|----------|
| Id | Kullanıcı birincil anahtarı |
| Name | Ad Soyad |
| Email | Kullanıcı email adresi |
| Phone | Telefon |
| Password | Parola |

#### API Sistemi
Kullanıcı kayıt ve giriş işlemleri REST API üzerinden gerçekleşir. Swagger UI ile bu endpointler kolayca test edilebilmektedir.

#### Flutter – .NET API Bağlantısı

Mobil uygulama doğrudan ASP.NET Core Web API üzerinden veri alışverişi yapmaktadır.

Flutter tarafında backend bağlantısı ApiService sınıfı ile yönetilmektedir:


class ApiService {
  static const String baseUrl = "http://10.0.2.2:5227/api"; // Yerel .NET API

  // Kayıt işlemi
  Future<bool> register(String name, String email, String phone, String password) async {
    final url = Uri.parse("$baseUrl/auth/register");
    // ...
  }

  // Giriş işlemi
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    // ...
  }
}


#### Kullanıcı Modelleri
Flutter tarafında backend ile uyumlu modeller oluşturulmuştur:

**UserModel**

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
}


#### Swagger UI Sistemi
Backend geliştirirken ve test ortamında kolaylık sağlaması için Swagger UI aktif edilmiştir.

**Özellikler:**
- Tüm endpointler listelenir
- Request–Response gövdesi canlı gösterilir
- API çağrıları direkt tarayıcıdan test edilir

<img width="800" alt="Swagger UI" src="https://github.com/user-attachments/assets/efbc69e7-4438-485e-9027-92ef07f66857" />

#### Frontend ve API Entegrasyonu
Web tarafı, backend ile şu şekilde haberleşir:


const res = await fetch("/api/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ email, password })
});


## 📌 Sonuç

Kısaca Backend'in Frontend ile entegrasyonu, API aracılığıyla bağlantıların kurulması, veritabanı entegrasyonu, login-register sistemi ve randevu alma sisteminin başarılı şekilde gerçekleşmesi sayesinde randevu ve rezervasyon sistemi projesinin kısmen tamamlandığını söylenebilir. Geri kalan zamanda arayüz güncellemeleri ve admin paneli oluşturularak birtakım eksiklikler düzeltilecektir.
