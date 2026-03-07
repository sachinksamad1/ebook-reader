# 📚 Ebook Reader

A minimal, fast, and distraction-free ebook reader built with **Flutter**, designed for language learners, students, and knowledge workers.

**Core differentiator:** Instant dictionary lookup + inline notes while reading — making it a blend of Kindle, language learning, and research notes.

---

## ✨ Features

### 📖 Reader
- **EPUB & PDF** support via `epub_view` and `syncfusion_flutter_pdfviewer`
- **Reader themes:** Light, Dark, and Sepia
- **Adjustable font size** for comfortable reading
- **Reading progress bar** with position memory (resume where you left off)
- **Smooth scrolling** with iOS-style bouncing physics
- **Chapter navigator sidebar** with auto-hide (slide-in TOC for EPUBs, page navigator for PDFs)

### 📚 Library
- Grid view of all uploaded books with cover images
- Sort by recently read
- Upload EPUB/PDF files directly from your device
- Custom book covers via image picker
- Progress indicator on each book

### 📝 Notes
- Add notes directly from the reader via the AppBar
- Notes are linked to specific books
- View, edit, and delete all notes from the dedicated Notes tab
- Synced to Firestore in real-time

### 🔍 Dictionary
- Tap a word in the PDF reader to instantly look up its definition
- Uses the free [Dictionary API](https://api.dictionaryapi.dev)
- Save words to your vocabulary list directly from the popup

### 🔦 Highlights
- Highlight text passages with color options (Yellow, Green, Blue)
- Highlights saved to Firestore per book

### 📓 Vocabulary Builder
- Automatically saves words you look up
- Review your vocabulary list in a dedicated tab
- Each word is linked back to the book it was found in

---

## 🏗️ Architecture

```
Flutter Android App
       │
Firebase Services
 ├─ Firebase Storage  → store ebook files
 ├─ Firestore         → metadata, notes, highlights, vocabulary
 └─ Firebase Auth     → user authentication
```

### Project Structure

```
lib/
├── core/
│   └── theme/            # App themes & reader themes
│
├── models/
│   ├── book.dart         # Book metadata model
│   ├── note.dart         # Note model
│   ├── highlight.dart    # Highlight model
│   └── vocabulary.dart   # Vocabulary word model
│
├── services/
│   ├── firebase_service.dart     # Firestore & Storage CRUD
│   ├── auth_service.dart         # Firebase Authentication
│   ├── cache_service.dart        # Local file caching
│   └── dictionary_service.dart   # Dictionary API lookups
│
├── features/
│   ├── auth/             # Login & registration screens
│   ├── library/          # Book grid, upload, providers
│   ├── reader/           # EPUB & PDF reader screens
│   │   ├── epub_reader_screen.dart
│   │   ├── pdf_reader_screen.dart
│   │   ├── reader_settings.dart
│   │   ├── add_note_sheet.dart
│   │   └── chapter_sidebar.dart
│   ├── dictionary/       # Word lookup popup
│   ├── notes/            # Notes list screen
│   ├── vocabulary/       # Vocabulary list screen
│   └── settings/         # App settings
│
└── main.dart
```

### State Management

- **Riverpod** (`flutter_riverpod`) — lightweight, compile-safe, and reactive

---

## 🔥 Firebase Setup

### Firestore Database

**Database ID:** `ebook-reader`  
**Edition:** Standard  
**Location:** `nam5`  
**Mode:** Native

#### Collections

| Collection    | Purpose                          |
|---------------|----------------------------------|
| `books`       | Book metadata & reading progress |
| `notes`       | User notes per book              |
| `highlights`  | Text highlights per book         |
| `vocabulary`  | Saved dictionary lookups         |

#### Required Composite Indexes

Firestore requires composite indexes for queries that filter and sort on different fields. Create these indexes via the Firebase Console (Firestore will provide direct links in the debug console if they're missing):

| Collection   | Fields                              |
|--------------|-------------------------------------|
| `books`      | `user_id` (Asc) + `last_read` (Desc) |
| `notes`      | `user_id` (Asc) + `created_at` (Desc) |
| `vocabulary` | `user_id` (Asc) + `created_at` (Desc) |

### Storage

```
ebooks/
  └── {user_id}/
        ├── {book_id}.epub
        ├── {book_id}.pdf
        └── {book_id}_cover.jpg
```

### Security Rules (Development)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📦 Dependencies

### Core
| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `firebase_core` | Firebase initialization |
| `cloud_firestore` | Database |
| `firebase_storage` | File storage |
| `firebase_auth` | Authentication |

### Reader
| Package | Purpose |
|---------|---------|
| `epub_view` | EPUB rendering |
| `syncfusion_flutter_pdfviewer` | PDF rendering |

### Utilities
| Package | Purpose |
|---------|---------|
| `path_provider` | Local file paths |
| `flutter_cache_manager` | Ebook file caching |
| `file_picker` | Book upload from device |
| `image_picker` | Custom cover images |
| `google_fonts` | Typography (Inter) |
| `http` | Dictionary API calls |
| `uuid` | Unique ID generation |
| `intl` | Date formatting |
| `shared_preferences` | Theme persistence |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.11.1`
- A Firebase project with Firestore, Storage, and Auth enabled

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sachinksamad1/ebook-reader.git
   cd ebook_reader
   ```

2. **Configure Firebase:**
   - Create a Firebase project
   - Create a Firestore database (Native mode, Database ID: `ebook-reader`)
   - Enable Firebase Storage and Authentication
   - Add your `google-services.json` (Android) to `android/app/`

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📄 Data Flows

### Book Upload
```
Select file → Upload to Firebase Storage → Save metadata to Firestore → Display in Library
```

### Reading
```
Select book → Download from Storage → Cache locally → Render in reader
```

### Dictionary Lookup (PDF)
```
Select text → Extract word → Call Dictionary API → Show popup → Optionally save to vocabulary
```

---

## 📜 License

This project is for personal use.
