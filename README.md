# Telemetría 02

Prototipo original de paneles naranjas para watchOS, con una app SwiftUI y complicaciones WidgetKit.

**Estado: compilación para simulador superada el 26 de octubre de 2026 con Xcode 16.4 y SDK watchOS 11.5 (arm64 y x86_64), sin firma. No se ha ejecutado ni probado en un reloj real, y no es una esfera instalable.**

[Ver ejecución correcta de GitHub Actions](https://github.com/zanottazuccoli-create/telemetria-02/actions/runs/40390601817). Código verificado: `3e63f441c07e88b23da3a909ec99b529ba5ec408`.

## Contenido

- App independiente para Apple Watch: pasos, distancia, energía activa y última lectura de pulso, previa autorización de Salud.
- Complicaciones rectangular y circular que presentan una caché local compartida.
- Formas y texto dibujados por código; sin gráficos extraídos de esferas comerciales.
- Vista web de demostración con valores ficticios. No se conecta a ningún reloj ni valida el comportamiento de watchOS.

## Compilación

Se necesitan Xcode con SDK watchOS y [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
bash build-on-mac.sh
```

El script genera el proyecto y compila para simulador sin firma. El workflow manual de GitHub Actions hace la misma comprobación en un runner macOS estándar, exclusivamente en repositorios públicos. No sube artefactos ni utiliza cachés o credenciales Apple.

## Alcance y límites

La app no sustituye el sistema de esferas de watchOS. Cada complicación ocupa el espacio que ofrece la esfera elegida. watchOS controla el tinte, presentación atenuada y presupuesto de actualización; solicitar una actualización no garantiza que ocurra a esa hora.

Los valores ausentes se muestran como un guion. La hora de consulta acompaña a los datos; los acumulados de un día anterior se ocultan y los de más de una hora se marcan como antiguos. El pulso indica la fecha de la muestra y no es una medición continua. La demostración no se guarda en la caché de las complicaciones.

Los datos de Salud se almacenan únicamente en un contenedor local protegido. No hay servidor, analítica ni transmisión de datos. Falta validar permisos parciales, revocación, eliminación explícita de caché, actualización en segundo plano y funcionamiento en dispositivo real. No se incluyen meteorología propia ni iconos de distribución finales.

Para firmar e instalar hay que configurar identificadores propios, equipo de desarrollo, HealthKit y el mismo App Group en ambos targets. La compilación de simulador no constituye un instalador para dispositivo. No se garantiza compatibilidad de todas las capacidades con una cuenta gratuita Personal Team.

## Privacidad

Este repositorio contiene código y datos de ejemplo, no lecturas de Salud reales, credenciales ni capturas de diseños comerciales.

## Referencias

- [WidgetKit](https://developer.apple.com/documentation/WidgetKit/Creating-accessory-widgets-and-watch-complications)
- [Autorización de Salud](https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data)
- [Condiciones de GitHub Actions](https://docs.github.com/en/actions/concepts/billing-and-usage)
