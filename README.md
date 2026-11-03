# Music Player

Ứng dụng nghe nhạc gồm API Node.js, giao diện Flutter và SQL Server.

## Yêu cầu

- Node.js
- Flutter SDK
- SQL Server

## Cài đặt CSDL

1. Mở SQL Server Management Studio.
2. Chạy toàn bộ file [`PRM_Pe.sql`](./PRM_Pe.sql).
3. Copy configure.example.properties thanhf configure.properties và điền thông tin

## Chạy API

```powershell
cd api
npm install
npm start
```

API chạy tại `http://localhost:3000`.

## Chạy ứng dụng Flutter

```powershell
cd ui
flutter pub get
flutter run
```

Ứng dụng Android Emulator dùng `http://10.0.2.2:3000` trong [`api_config.dart`](./ui/lib/services/api_config.dart). Nếu chạy trên thiết bị thật, thay địa chỉ này bằng IP LAN của máy chạy API.
