# TuProfe iOS

Versión iOS de la app TuProfe, migrada desde Kotlin + Jetpack Compose a Swift + SwiftUI.
Mantiene la misma apariencia visual, colores, estructura y funcionalidades que la app Android.

---

## Estructura del proyecto

```
TuProfeIOS/
├── project.yml                    ← Configuración xcodegen
├── setup.sh                       ← Script de configuración automática
├── TuProfeIOS/
│   ├── App/
│   │   ├── TuProfeIOSApp.swift    ← Entry point (@main)
│   │   └── AppDelegate.swift      ← Firebase init + FCM
│   ├── Core/
│   │   ├── Theme/
│   │   │   ├── AppColors.swift    ← Colores exactos del Android (verde TuProfe)
│   │   │   └── AppTypography.swift ← Fuentes y estilos de texto
│   │   └── Components/
│   │       ├── AppButton.swift    ← AppButton, AppButtonRow, AppTextButton
│   │       ├── AppTextField.swift ← TextField, SecureField, SearchBar, TextEditor
│   │       ├── ReviewCardView.swift ← ReviewCard, CommentCard, ConfigItemRow, Skeletons
│   │       ├── StarRating.swift   ← StarRatingView, InteractiveStarRating, RatingBadge
│   │       ├── ProfileImageView.swift ← Imágenes circulares con SDWebImage
│   │       └── BackgroundView.swift ← Background, shimmer, press effect, animations
│   ├── Data/
│   │   ├── Models/                ← Usuario, Profesor, ReviewInfo, CommentInfo, Materia
│   │   ├── DTOs/                  ← UserDto, ReviewDto, CommentDto, CreateReviewDto...
│   │   ├── Repositories/          ← Auth, User, Review, Comment, Professor, Storage
│   │   └── Services/
│   │       └── APIService.swift   ← URLSession (≈ Retrofit) + GROQ AI Service
│   ├── Navigation/
│   │   └── AppNavigation.swift    ← NavigationStack + TabBar con FAB central
│   └── UI/
│       ├── Splash/               ← Logo animado → Firebase Auth check
│       ├── Login/                ← Login con animaciones escalonadas
│       ├── Register/             ← Registro + email verification
│       ├── ResetPassword/        ← Recuperación de contraseña
│       ├── Main/                 ← Feed "Para ti" / "Siguiendo" + sort
│       ├── Search/               ← Búsqueda de profesores con ratings
│       ├── Profe/                ← Perfil de profesor + resumen IA (GROQ)
│       ├── Detalle/              ← Reseña completa + comentarios + like/share
│       ├── Review/
│       │   ├── CreateReview/     ← Crear reseña con GPS
│       │   └── EditReview/       ← Editar reseña existente
│       ├── Comment/
│       │   ├── CommentDetalle/   ← Ver comentario + respuestas
│       │   └── EditComment/      ← Editar comentario
│       ├── Historial/            ← Mis reseñas y comentarios con filtros
│       ├── Mapa/                 ← MapKit con marcadores de reseñas + filtros
│       ├── Config/               ← Perfil propio + seguidores + menú
│       ├── ConfigPerfil/         ← Editar perfil + foto + privacidad
│       ├── UserProfile/          ← Perfil de otro usuario + follow
│       ├── Notificaciones/       ← Notificaciones FCM
│       ├── Ajustes/              ← Tema y preferencias
│       └── AyudaYSoporte/        ← FAQ expandibles + contacto
└── Supporting/
    ├── Info.plist
    └── GoogleService-Info.plist   ← ⚠️ REEMPLAZAR con el tuyo
```

---

## Cómo configurar el proyecto

### Paso 1: Instalar dependencias

```bash
# Instalar Homebrew si no lo tienes
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar xcodegen
brew install xcodegen
```

### Paso 2: Configurar Firebase

1. Ve a [console.firebase.google.com](https://console.firebase.google.com)
2. Selecciona tu proyecto **TuProfe** existente
3. **Configuración del proyecto → Tus aplicaciones → Agregar app → iOS**
4. Bundle ID: `com.tuprofe.ios`
5. Descarga el archivo `GoogleService-Info.plist`
6. **Reemplaza** `TuProfeIOS/Supporting/GoogleService-Info.plist` con el archivo descargado

### Paso 3: Configurar GROQ API Key

En el archivo `TuProfeIOS/Data/Services/APIService.swift`, la clase `GroqAIService` lee la API key desde `Info.plist`.

**Opción A (recomendada):** Usar xcconfig:
```
# Crea TuProfeIOS/Configuration/Debug.xcconfig
GROQ_API_KEY = gsk_xxxxxxxxxxxxxxxxxxxx
```

**Opción B:** Editar directamente en `GroqAIService.init()`:
```swift
private let apiKey: String = "gsk_tu_api_key_aqui"
```

### Paso 4: Configurar la URL del backend

En `TuProfeIOS/Data/Services/APIService.swift`:
```swift
let baseURL = "https://TU-BACKEND-URL/api"
```

### Paso 5: Generar y abrir el proyecto

```bash
cd ~/Documents/TuProfeIOS
./setup.sh
open TuProfeIOS.xcodeproj
```

### Paso 6 (opcional): Fuentes personalizadas

Para replicar exactamente las fuentes Android:
1. Descarga **BebasNeue-Regular.ttf** de [Google Fonts](https://fonts.google.com/specimen/Bebas+Neue)
2. Descarga **Montserrat-Regular.ttf** de [Google Fonts](https://fonts.google.com/specimen/Montserrat)
3. Crea la carpeta `TuProfeIOS/Resources/Fonts/`
4. Agrega los archivos .ttf ahí
5. En Xcode, agrégalos al target y en `Info.plist` bajo `Fonts provided by application`

---

## Ejecutar la app

1. Abre `TuProfeIOS.xcodeproj` en Xcode
2. Selecciona un simulador o dispositivo iOS 16+
3. **Product → Build** para verificar que compila
4. **Product → Run** para ejecutar

---

## Equivalencias Android → iOS

| Android | iOS | Notas |
|---------|-----|-------|
| `Jetpack Compose` | `SwiftUI` | API declarativa equivalente |
| `ViewModel + StateFlow` | `@MainActor ObservableObject + @Published` | |
| `Hilt DI` | Singletons con `.shared` | |
| `Retrofit` | `URLSession async/await` | `APIService.swift` |
| `Coil` | `SDWebImageSwiftUI` | Carga de imágenes |
| `NavController` | `NavigationStack + NavigationPath` | |
| `Google Maps` | `MapKit` | Nativo iOS, misma funcionalidad |
| `FCM` | `FirebaseMessaging` | Mismo SDK |
| `Coroutines` | `async/await + Task` | |
| `AnimatedVisibility` | `.transition()` | |
| `LazyColumn` | `ScrollView + LazyVStack` | |
| `ShimmerEffect` | `shimmerEffect()` custom modifier | |
| `pressScaleEffect` | `pressScaleEffect()` custom modifier | |
| `BebasNeue font` | `Font.custom("BebasNeue-Regular", ...)` | Agregar .ttf manual |

---

## Funcionalidades implementadas

| Pantalla | Estado |
|----------|--------|
| Splash con logo animado | ✅ |
| Login con animaciones escalonadas | ✅ |
| Registro + verificación de email | ✅ |
| Recuperación de contraseña | ✅ |
| Feed "Para ti" / "Siguiendo" | ✅ |
| Ordenamiento (recientes / mejor calificadas / más gustadas) | ✅ |
| Búsqueda de profesores | ✅ |
| Perfil de profesor + reseñas | ✅ |
| **Resumen IA (GROQ Llama 3.3 70B)** | ✅ |
| Detalle de reseña + comentarios | ✅ |
| Like en reseñas y comentarios | ✅ |
| Compartir reseña | ✅ |
| Crear reseña con GPS | ✅ |
| Editar reseña | ✅ |
| Ver comentario + respuestas | ✅ |
| Editar comentario | ✅ |
| Historial con filtros | ✅ |
| Eliminar reseña y comentario | ✅ |
| **Mapa con MapKit** | ✅ |
| Filtros del mapa (estrellas, profesor) | ✅ |
| Perfil propio + seguidores/siguiendo | ✅ |
| Editar perfil + foto (PhotosPicker) | ✅ |
| Configuración de privacidad | ✅ |
| Perfil de otro usuario | ✅ |
| Seguir / dejar de seguir | ✅ |
| Transacción Firestore follow/unfollow | ✅ |
| FCM Push Notifications | ✅ |
| Ajustes (tema, notificaciones) | ✅ |
| Ayuda y soporte (FAQ expandibles) | ✅ |
| Firebase Auth completo | ✅ |
| Firebase Storage (fotos de perfil) | ✅ |
| Firebase Firestore (users, follows) | ✅ |
| Firebase Crashlytics | ✅ (automático) |

---

## Diferencias respecto a Android

### Google Maps → MapKit
- **Android:** `maps-compose` con Google Maps SDK  
- **iOS:** `MapKit` nativo (sin necesidad de API key de Google Maps para iOS)
- Las funcionalidades son equivalentes: marcadores, tap, clustering básico

### Hilt DI → Singletons
- **Android:** Hilt con módulos de inyección
- **iOS:** Singletons `Repository.shared` — sin un framework DI externo

### Fonts (requiere acción manual)
- Las fuentes BebasNeue y Montserrat deben añadirse manualmente a Xcode (ver Paso 6)
- La app funciona sin ellas usando fuentes del sistema

### Shimmer skeleton
- Implementado como `shimmerEffect()` ViewModifier personalizado
- Visualmente idéntico al shimmer de Android

### Notificaciones
- La pantalla de notificaciones muestra notificaciones FCM recibidas
- Para persistencia, necesitas guardar los mensajes FCM en Firestore o UserDefaults