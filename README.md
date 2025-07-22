# ip_address_checker

This is an app to check the ip address.

## How to build

### Android

```
$ flutter build apk
or
$ flutter build apk --debug
```

### iOS
```
$ flutter build ios
or
$ flutter build ios --debug
or
$ flutter build ios --simulator
```

## How to debug on local

### Android

```
$ flutter emulators --launch Pixel_7
$ flutter devices
$ flutter run -d emulator-xxxx
```

<img width="434" height="735" alt="Screenshot 2025-07-22 at 9 42 48" src="https://github.com/user-attachments/assets/b99cf1f3-8345-49a9-8ada-fc42c4ec0532" />


### iOS

```
$ xcrun simctl list devices
$ xcrun simctl boot xxxx-xxxx-xxxx-xxxx-xxxx
$ flutter devices
$ flutter run -d xxxx-xxxx-xxxx-xxxx-xxxx
```