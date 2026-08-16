# Safari

Safari usa a mesma WebExtension, mas a Apple exige empacotá-la como uma extensão
Safari dentro de um projeto Xcode. Quando Xcode estiver instalado, execute:

```bash
cd ~/Documents/IA-Local-Pablo/CreditWatch
xcrun safari-web-extension-packager BrowserExtension --app-name CreditWatchSafari --bundle-identifier com.pablomichelin.creditwatch.safari --swift
```

O comando gera o projeto Xcode que instala e habilita a extensão no Safari.
Safari suporta WebExtensions e o packager oficial cria o app contêiner.
