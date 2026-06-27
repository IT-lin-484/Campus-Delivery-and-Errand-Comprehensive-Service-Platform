# 校园取送 Flutter 前端

这是校园取送系统的 Flutter 前端，已按移动端最小可用界面重构，默认中文界面，直接对接后端 API。

## 启动前准备

- Android 模拟器已可用，当前环境识别到的设备是 `emulator-5554`
- 本机后端默认地址是 `http://10.0.2.2:8080`
- 如果你的 Flutter 环境还在走镜像源，请先切到官方源再运行

```powershell
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.googleapis.com'
$env:PUB_HOSTED_URL = 'https://pub.dev'
```

## 本地运行

在 `frontend` 目录下执行：

```powershell
flutter pub get
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

如果后端不在本机 `8080` 端口，把 `API_BASE_URL` 替换成你的实际地址即可。

## 说明

- 登录页同时支持注册，方便本地联调
- 数据存储使用 `shared_preferences`
- 网络请求使用 `dio`
- 页面尽量保持简洁，保留必要功能，后续可以继续扩展订单流转和 Flutter 模拟器联调
