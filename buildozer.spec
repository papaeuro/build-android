[app]
title = Offline Messenger
package.name = offline_messenger
package.domain = com.papa.euro
source.dir = ./app
source.include_exts = py,png,jpg,kv,atlas,dart,yaml,xml
version = 1.0.0

# Permissions indispensables pour ton Tecno
android.permissions = INTERNET, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE

# Configuration spécifique pour Android
android.api = 33
android.minapi = 21
android.sdk = 33
android.ndk = 25b
android.archs = arm64-v8a, armeabi-v7a

# On s'assure que le mode plein écran est activé
android.fullscreen = 0
