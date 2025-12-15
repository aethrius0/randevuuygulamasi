# Self CarWash - Randevu & Rezervasyon Sistemi

Bu proje, araç yıkama randevu sistemini hem web hem de mobil platformda yönetmek amacıyla geliştirilmiştir. Kullanıcılar kayıt olabilir, giriş yapabilir ve uygun tarih/saat seçerek randevu oluşturabilir.

---

## 📋 Proje Tasarım Durumu

### Frontend

#### Login-Register Sistemi
Uygulamayı başlattığımızda ilk başta karşımıza bir login-register ekranı çıkıyor.

<img width="400"  alt="Login Ekranı" src="https://github.com/user-attachments/assets/b3eec836-a89d-4196-95bf-b3c6d291f550" />


Kayıt olmak istediğiniz takdirde "Kayıt ol" butonuna basarak ad, soyad, e-posta, telefon ve şifrenizi girerek güvenli bir şekilde kaydolabilirsiniz.

<img width="400"  alt="Register Ekranı" src="https://github.com/user-attachments/assets/1dbd6241-4dac-4eee-85fc-b99b6cb4b25f" />


#### Ana Sayfa Kısmı
Kayıt olup giriş yaptıktan sonra karşımıza kullanıcı dostu, canlı bir panel geliyor. Tüm bayileri kaydırarak görebiliyor, üstüne tıklayarak çıkan pop-up'ta randevu sekmesine ayrı girmeden seçtiğimiz bayiden randevu alabiliyoruz. 
Her bayinin puan ve uzaklık göstergesi bulunmaktadır. En alt kısımda da toplam randevu sayınızın ve en yakın randevunuzun detayları birlikte gözüktüğü küçük bir panel bulunmaktadır. 

<img width="400"  alt="Ana Sayfa" src="https://github.com/user-attachments/assets/31a685a8-4271-42fd-8092-804d7c400de3" />


#### Randevular Kısmı
Randevular sekmesine geldiğimizde karşımıza randevularımızın detaylıca gözüktüğü bloklar gelmektedir. Sağ alttaki "+" butonuyla randevu oluşturabilir, önce bayiyi seçerek sonrasında plaka, fiyata göre hizmet türü, saat ve tarih girildikten sonra kolayca randevu oluşturabilirsiniz. Randevuyu ilk oluşturduğunuzda randevu durumu "Beklemede" gözükmektedir. Randevu aldığınız bayi kendi panelinden onaylayıp, reddettikten sonra randevu durumunuz güncellenecektir. Randevuyu altındaki "Düzenle" butonuyla düzenleyebilir, "Sil" butonuyla silebilirsiniz. 

<img width="400"  alt="Randevular Ekranı" src="https://github.com/user-attachments/assets/efb8776f-5be7-4ae7-905a-c7bdd6117bbe" /> <img width="400"  alt="Randevu Olusturma Ekranı" src="https://github.com/user-attachments/assets/b799881c-60a6-449c-a0e8-456b0e39d18a" />


#### Profil Kısmı
Profil kısmına geldiğimizde önümüze basit bir ad-soyad, e-posta ve telefon numarası bilgilerinin görüleceği kısım karşımıza çıkıyor. En altta "Çıkış Yap" butonu ortaya çıkıyor. Butona basarak çıkış yapabilirsiniz.

<img width="400"  alt="Profil Ekranı" src="https://github.com/user-attachments/assets/ec68c550-4435-4124-922f-f0ddfe7afe7f" />

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
