# E-Learning Adaptatif AI

Plateforme d'e-learning adaptatif qui détecte la **frustration des apprenants en temps réel via la webcam** (modèle TensorFlow Lite embarqué côté mobile) et remonte cette information à l'enseignant sur un tableau de bord de monitoring en direct.

Le projet est composé de deux applications :

| Module | Stack | Rôle |
|---|---|---|
| [`Backend/`](Backend) | Java 17 · Spring Boot 3.4 · PostgreSQL | API REST : authentification, cours/leçons/quiz, sessions d'apprentissage, agrégation des scores de frustration, recommandations |
| [`elearningfrontv2/`](elearningfrontv2) | Flutter 3 · Dart · Riverpod · TensorFlow Lite | Application mobile (Android/iOS) : parcours étudiant, détection d'émotion on-device via caméra frontale, dashboard enseignant |

---

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Architecture générale](#architecture-générale)
- [Backend — Spring Boot](#backend--spring-boot)
- [Frontend — Flutter](#frontend--flutter)
- [Pipeline de détection de frustration (IA embarquée)](#pipeline-de-détection-de-frustration-ia-embarquée)
- [Démarrage rapide](#démarrage-rapide)
- [Rôles utilisateurs](#rôles-utilisateurs)
- [Limitations connues / dette technique](#limitations-connues--dette-technique)
- [Structure du dépôt](#structure-du-dépôt)

---

## Fonctionnalités

- **Authentification** par email/mot de passe avec JWT, deux rôles (`STUDENT`, `TEACHER`).
- **Gestion de cours** (enseignant) : création de cours, leçons (théorie / vidéo / quiz / mixte), quiz à choix multiples.
- **Parcours étudiant** : inscription à un cours, suivi des leçons, lecture vidéo, réponse aux quiz.
- **Détection de frustration en temps réel** : pendant qu'un étudiant suit une leçon, la caméra frontale capture son visage, un modèle TensorFlow Lite embarqué calcule un score de frustration continu (0.0 à 1.0), lissé sur une fenêtre glissante et envoyé périodiquement au backend.
- **Sessions d'apprentissage** : chaque parcours de leçon est tracé (durée, statut, score moyen de frustration).
- **Dashboard enseignant temps réel** : suivi live des sessions actives de tous les étudiants avec code couleur (🟢 calme / 🟠 stressé / 🔴 frustré), rafraîchi toutes les 5 secondes.
- **Recommandations** (infrastructure présente côté API : déclencheurs de frustration, messages non lus) — génération automatique du contenu non encore implémentée côté serveur (voir [Limitations](#limitations-connues--dette-technique)).

---

## Architecture générale

```
                     ┌────────────────────────────┐
                     │   Application Flutter        │
                     │   (Android / iOS)             │
                     │                                │
                     │  Caméra frontale → YUV420      │
                     │       → RGB 224×224            │
                     │       → TFLite (on-device)      │
                     │       → score frustration 0-1   │
                     └───────────────┬────────────────┘
                                     │ REST / JWT (Dio & http)
                                     ▼
                     ┌────────────────────────────┐
                     │   API Spring Boot (8080)      │
                     │   Auth · Courses · Lessons     │
                     │   Quiz · Enrollments · Sessions│
                     │   FrustrationMetric · Reco.    │
                     └───────────────┬────────────────┘
                                     │ JPA / Hibernate
                                     ▼
                     ┌────────────────────────────┐
                     │      PostgreSQL 15            │
                     └────────────────────────────┘
```

Point clé d'architecture : **toute l'inférence IA (détection d'émotion/frustration) s'exécute côté client, sur l'appareil mobile**, via TensorFlow Lite. Le backend ne reçoit et ne stocke que le score déjà calculé — il ne charge aucun modèle ML et se contente d'agréger (moyenne) et d'exposer ces scores.

---

## Backend — Spring Boot

Répertoire : [`Backend/`](Backend)

### Stack technique

- **Java 17**, **Spring Boot 3.4.12** (artefact Maven `com.elearning:adaptive-learning-ai`)
- `spring-boot-starter-web`, `spring-boot-starter-data-jpa`, `spring-boot-starter-security`, `spring-boot-starter-validation`, `spring-boot-starter-websocket` (déclaré, non exploité actuellement), `spring-boot-starter-actuator`
- **PostgreSQL** comme unique base de données (driver `org.postgresql:postgresql`), schéma généré automatiquement par Hibernate (`ddl-auto: update`, pas de Flyway/Liquibase)
- **JWT** (JJWT 0.11.5, HS256) pour l'authentification stateless
- **Lombok** pour réduire le boilerplate
- **springdoc-openapi** pour une documentation Swagger/OpenAPI auto-générée
- `spring-ai-bom` importé en gestion de dépendances mais **non exploité actuellement** (préparation possible d'une future IA générative côté serveur)

### Modèle de données

| Entité | Rôle |
|---|---|
| `User` / `Role` (STUDENT, TEACHER) | Comptes utilisateurs |
| `Course` | Cours créé par un enseignant |
| `Lesson` / `LessonContentType` (THEORY, VIDEO, QUIZ, MIXED) | Contenu pédagogique d'un cours |
| `Quiz` | Question à choix multiples rattachée à une leçon de type QUIZ |
| `Enrollment` | Inscription d'un étudiant à un cours |
| `Session` / `SessionStatus` (IN_PROGRESS, COMPLETED) | Session de suivi d'une leçon : durée, score moyen de frustration |
| `FrustrationMetric` | Score de frustration ponctuel (0-1) horodaté, envoyé par le mobile — source utilisée pour calculer la moyenne de la session |
| `EmotionEvent` | Événement émotionnel détaillé (score, détection de visage, version du modèle, seuil, métadonnées) — chaîne parallèle plus riche, utilisée pour des statistiques par fenêtre glissante |
| `Recommendation` | Message de recommandation adressé à un étudiant, lié à une session |
| `RecommendationTrigger` | Journal des déclenchements de recommandation (ex. `FRUSTRATION_HIGH`) |

### Principaux endpoints REST

| Ressource | Endpoints |
|---|---|
| Auth | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me` |
| Cours | `GET/POST/PUT/DELETE /api/courses`, `GET /api/courses/{id}` |
| Leçons | `GET/POST/PUT/DELETE /api/lessons`, `GET /api/lessons/course/{courseId}`, `POST /api/lessons/{id}/video` |
| Quiz | `POST /api/quizzes?lessonId=`, `GET /api/quizzes/lesson/{id}`, `DELETE /api/quizzes/{id}`, `POST /api/quizzes/submit-answers` |
| Inscriptions | `POST /api/enrollments`, `GET /api/enrollments/my`, `DELETE /api/enrollments/{id}` |
| Sessions | `POST /api/sessions/start`, `PUT /api/sessions/{id}/time`, `PUT /api/sessions/{id}/end`, `POST /api/sessions/frustration-metric`, `GET /api/sessions/my`, `GET /api/sessions/active`, `GET /api/sessions/teacher/monitor` |
| Émotion | `POST /api/sessions/{sessionId}/emotion`, `POST /api/sessions/{sessionId}/emotion/bulk` |
| Recommandations | `GET /api/recommendations/session/{sessionId}/unread`, `PATCH /api/recommendations/{id}/read` |
| Utilisateurs | `GET/POST/PUT/DELETE /api/users` |

Documentation interactive disponible via Swagger UI une fois le serveur démarré (`/swagger-ui.html`, exposée par `springdoc-openapi`).

### Sécurité

- Authentification **JWT stateless** (`Authorization: Bearer <token>`), filtre `JwtAuthenticationFilter`.
- Autorisations par rôle via `SecurityConfig` : gestion de cours réservée à `TEACHER`, inscriptions/sessions réservées à `STUDENT`, dashboard `teacher/monitor` protégé par `@PreAuthorize("hasRole('TEACHER')")`.
- Mot de passe hashé avec `BCryptPasswordEncoder`.
- Un flag `app.jwt.enabled` permet de désactiver la sécurité pour le développement local (tout devient `permitAll`).

### Configuration

Fichier `Backend/src/main/resources/application.yaml` :

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/elearningdb
    username: elearning_user
    password: 123456
  jpa:
    hibernate:
      ddl-auto: update
app:
  jwt:
    enabled: true
    secret: <à changer en production>
    expiration-ms: 86400000
```

Le serveur écoute sur le port **8080** par défaut.

### Docker

Un `docker-compose.yml` fournit un service PostgreSQL 15 et un service applicatif construit depuis le `Dockerfile` (image `eclipse-temurin:17-jdk-alpine`, exécution d'un jar pré-construit).

> ⚠️ Avant de lancer `docker compose up`, il faut : (1) builder le jar avec `mvn package`, (2) harmoniser le nom de la base/utilisateur entre `docker-compose.yml` et `application.yaml` (ou passer par des variables d'environnement), le compose ne câble pas encore automatiquement l'app conteneurisée sur la base conteneurisée.

---

## Frontend — Flutter

Répertoire : [`elearningfrontv2/`](elearningfrontv2)

### Stack technique

- **Flutter / Dart ≥ 3.0**, cible principale **Android / iOS** (squelettes web/Windows/Linux/macOS générés mais non spécifiquement adaptés à la partie caméra/IA)
- **Riverpod** (`flutter_riverpod`) pour la gestion d'état (auth notamment)
- **go_router** pour la navigation déclarative
- **Dio** et **http** pour les appels API (deux clients coexistent, voir [Limitations](#limitations-connues--dette-technique))
- **flutter_secure_storage** pour stocker le token JWT
- **tflite_flutter** + **image** pour l'inférence TensorFlow Lite on-device
- **camera** pour l'accès à la caméra frontale
- **video_player** pour les leçons vidéo
- **flutter_animate**, **fl_chart**, **shimmer** pour l'UI/UX

### Organisation du code (`lib/`)

```
lib/
├── main.dart              # point d'entrée, routes go_router, init caméra
├── core/
│   ├── constants/          # URL de base de l'API, constantes
│   ├── providers/          # AuthNotifier (Riverpod)
│   ├── services/           # clients API : auth, course, lesson, quiz, enrollment, session
│   ├── theme/               # design system (couleurs, typographie, spacing)
│   └── utils/                # secure storage, conversion image YUV→RGB, validators
├── models/                 # User, AuthResponse, FrustrationModel (wrapper TFLite)
├── screens/
│   ├── auth/                 # login, signup
│   ├── course/, lesson/, quiz/   # gestion de contenu (enseignant)
│   ├── student/              # accueil étudiant, leçon + détection IA, mes cours
│   └── teacher/               # accueil enseignant, dashboard de monitoring frustration
└── shared/widgets/          # boutons, champs de texte, sélecteur de rôle
```

### Écrans principaux

- **Auth** : `LoginScreen`, `SignupScreen` — sélection du rôle, décodage du JWT côté client pour router vers l'espace étudiant ou enseignant.
- **Enseignant** : `HomeTeacher` (accueil), `CoursesScreen` / `LessonScreen` / `QuizScreen` (CRUD de contenu), `TeacherDashboardStudent` (monitoring live des sessions étudiantes avec score de frustration, rafraîchi toutes les 5s).
- **Étudiant** : `HomeStudent` (catalogue de cours, statut d'avancement), `MyCoursesScreen` (mes inscriptions), `LessonStudentScreen` (lecture de leçon avec détection de frustration en direct via webcam).

### Communication avec l'API

- URL de base définie dans `lib/core/constants/api_constants.dart` (adresse IP locale, à adapter selon l'environnement de déploiement).
- Le token JWT est stocké via `flutter_secure_storage` et injecté automatiquement (intercepteur Dio) ou manuellement (headers `http`) selon le service.

---

## Pipeline de détection de frustration (IA embarquée)

Le cœur "adaptatif" du projet repose sur un modèle **TensorFlow Lite** embarqué dans l'application mobile (`elearningfrontv2/assets/model_tflite_rebuilt.tflite`, ~11 Mo, type MobileNetV2), exécuté **entièrement on-device**, sans appel réseau pour l'inférence elle-même.

```
Caméra frontale (flux continu)
      │  format YUV420
      ▼
Conversion YUV420 → RGB (lib/core/utils/image_converter.dart)
      │
      ▼
Redimensionnement 224×224 + normalisation [-1, 1]
      │
      ▼
Inférence TFLite (lib/models/frustration_model.dart)
      │  sortie : score scalaire [0.0 – 1.0]
      ▼
Lissage sur fenêtre glissante (25 derniers scores)
      │
      ├─► Affichage temps réel (jauges LIVE / MOY, couleur dynamique)
      │
      └─► Envoi périodique (toutes les 5s) au backend
                 POST /api/sessions/frustration-metric
                      │
                      ▼
          FrustrationMetric persisté + moyenne recalculée
          sur Session.averageFrustrationScore
                      │
                      ▼
          GET /api/sessions/teacher/monitor (polling 5s)
                      │
                      ▼
          Dashboard enseignant (code couleur 🟢/🟠/🔴)
```

- **Seuil de décision** : `0.3759` (calibré à l'entraînement) — au-delà, l'état est classé `FRUSTRATION`, en-deçà `CALM`.
- **Throttling** : une inférence au maximum toutes les 600 ms pour ménager les ressources de l'appareil.
- Le backend ne fait **aucun traitement ML** : il reçoit un score déjà calculé, le stocke (`FrustrationMetric`), et calcule une simple moyenne arithmétique par session.

---

## Démarrage rapide

### Prérequis

- Java 17, Maven
- PostgreSQL 15 (ou Docker)
- Flutter SDK ≥ 3.x, un appareil/émulateur Android ou iOS avec caméra

### Backend

```bash
cd Backend
# Configurer PostgreSQL (créer la base "elearningdb" et l'utilisateur défini dans application.yaml)
./mvnw spring-boot:run
# API disponible sur http://localhost:8080
# Swagger UI sur http://localhost:8080/swagger-ui.html
```

Ou via Docker :

```bash
cd Backend
mvn package -DskipTests
docker compose up --build
```

### Frontend

```bash
cd elearningfrontv2
flutter pub get
# Adapter l'URL de l'API dans lib/core/constants/api_constants.dart
# (adresse IP de la machine hébergeant le backend, accessible depuis l'appareil/émulateur)
flutter run
```

> La détection de frustration nécessite un appareil physique ou un émulateur avec accès caméra ; le comportement sur web/desktop n'est pas garanti.

---

## Rôles utilisateurs

| Rôle | Capacités |
|---|---|
| **STUDENT** | S'inscrire à des cours, suivre des leçons, répondre aux quiz, être suivi automatiquement via la détection de frustration pendant l'apprentissage |
| **TEACHER** | Créer/gérer cours, leçons et quiz, superviser en temps réel l'état émotionnel de ses étudiants via le dashboard de monitoring |

---

## Limitations connues / dette technique

Ces points sont documentés ici pour donner une image honnête de l'état actuel du projet :

- **Génération des recommandations non implémentée côté backend** : les tables `Recommendation`/`RecommendationTrigger` et les endpoints de lecture existent, mais aucun service ne génère automatiquement un message de recommandation à partir d'un score de frustration élevé.
- **Résultat de quiz non persisté** : `POST /api/quizzes/submit-answers` calcule un score mais ne le sauvegarde pas encore.
- **Deux chaînes de suivi de frustration parallèles** côté backend (`FrustrationMetric` réellement utilisé vs `EmotionEvent` plus riche mais peu exploité) — à unifier.
- **Frontend** : coexistence de deux clients HTTP (Dio et `http`) avec deux stratégies différentes d'injection du token JWT ; modèles de données Course/Lesson/Quiz/Session non typés (échanges via `Map<String, dynamic>`), seul `User` dispose d'un vrai modèle Dart ; thème personnalisé (`AppTheme`) partiellement branché ; quelques écrans/fichiers vides ou dupliqués (`my_sessions_screen.dart`, `login_request.dart`, `frustration_api_service.dart` redondant avec `SessionService`).
- **Configuration en dur** : URL de l'API (IP locale) et secret JWT codés en dur, à externaliser via variables d'environnement pour un déploiement en production.
- **`docker-compose.yml`** : les identifiants de connexion à la base ne sont pas encore alignés avec `application.yaml` pour une connexion automatique entre conteneurs.

---

## Structure du dépôt

```
.
├── Backend/                 # API Spring Boot
│   ├── src/main/java/com/elearning/adaptive/
│   │   ├── controller/       # Endpoints REST
│   │   ├── service/           # Logique métier
│   │   ├── entity/             # Entités JPA
│   │   ├── repository/        # Spring Data JPA
│   │   ├── dto/ mapper/        # Objets d'échange
│   │   └── security/           # JWT, configuration Spring Security
│   ├── Dockerfile
│   └── docker-compose.yml
└── elearningfrontv2/         # Application Flutter
    ├── lib/
    │   ├── core/               # Services API, thème, utilitaires, providers
    │   ├── models/              # Modèles de données + wrapper TFLite
    │   ├── screens/              # Écrans par rôle (auth, étudiant, enseignant)
    │   └── shared/                # Composants UI réutilisables
    └── assets/
        └── model_tflite_rebuilt.tflite   # Modèle de détection de frustration
```
