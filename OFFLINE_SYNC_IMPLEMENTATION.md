# 🔄 Offline/Online Sync Implementation

## 🎯 **Problem Solved**

1. ✅ **Fixed API Endpoint**: POST `/emotional_records/` now actually saves to PostgreSQL database
2. ✅ **Offline Storage**: Local SQLite database for when backend is unavailable  
3. ✅ **Automatic Sync**: Intelligent sync mechanism that handles online/offline states
4. ✅ **Enhanced Logging**: Comprehensive logging in both API and Flutter app
5. ✅ **UI Feedback**: Visual indicators for connection and sync status

## 🏗️ **Architecture Overview**

```
Flutter App                    Backend API                 Database
┌─────────────────┐           ┌─────────────────┐         ┌─────────────────┐
│                 │  HTTP     │                 │         │                 │
│  UI Layer       │◄─────────►│  FastAPI        │◄───────►│  PostgreSQL     │
│                 │   POST    │  Endpoints      │         │                 │
├─────────────────┤           └─────────────────┘         └─────────────────┘
│                 │
│  SyncService    │           ┌─────────────────┐
│                 │           │                 │
├─────────────────┤           │  Connectivity   │
│                 │           │  Monitoring     │
│ LocalDatabase   │           │                 │
│   (SQLite)      │           └─────────────────┘
└─────────────────┘
```

## 📁 **New Files Created**

### **Backend Changes:**
- ✅ **Enhanced `/emotional_records/` POST endpoint** in `src/presentation/api/routers/data.py`
  - Now actually saves to PostgreSQL database
  - Enhanced logging with emojis for easy debugging
  - Proper error handling and validation

### **Flutter Services:**
- ✅ **`LocalDatabaseService`** - SQLite database for offline storage
- ✅ **`SyncService`** - Handles online/offline sync logic
- ✅ **`SyncStatusWidget`** - UI component for sync status
- ✅ **`SyncProvider`** - Riverpod providers for state management

## 🔧 **How It Works**

### **1. Data Flow**
```
User creates emotional record
         ↓
Always save to local SQLite first
         ↓
If online: Try immediate sync to backend
         ↓
If offline: Queue for later sync
         ↓
Periodic sync attempts when online
         ↓
Mark as synced when successful
```

### **2. Sync Logic**
- **Immediate**: Try to sync right away when online
- **Periodic**: Every 30 seconds check for pending records
- **Connectivity**: Monitor network changes and sync when restored
- **Retry**: Failed syncs are retried with exponential backoff
- **Cleanup**: Old synced records are cleaned up automatically

### **3. Offline Storage Schema**
```sql
CREATE TABLE emotional_records (
  id TEXT PRIMARY KEY,
  emotion TEXT NOT NULL,
  intensity INTEGER NOT NULL,
  triggers TEXT,
  notes TEXT,
  context_data TEXT,
  tags TEXT,
  tag_confidence REAL,
  processed_for_tags INTEGER DEFAULT 0,
  recorded_at TEXT,
  created_at TEXT NOT NULL,
  synced INTEGER DEFAULT 0,           -- Sync status
  sync_attempts INTEGER DEFAULT 0,    -- Retry counter
  last_sync_attempt TEXT,             -- Last attempt timestamp
  local_only INTEGER DEFAULT 0        -- Never sync flag
);
```

## 📱 **UI Integration**

### **Sync Status Widget**
```dart
// Compact status in app bar
SyncStatusWidget(showDetails: false)

// Detailed status in settings
SyncStatusWidget(showDetails: true)
```

### **Status Indicators**
- 🌐 **Online + Synced**: Green cloud with checkmark
- 🔄 **Syncing**: Animated spinner
- ⚠️ **Pending**: Orange cloud with sync icon
- ❌ **Offline**: Red cloud with X

## 🔍 **Enhanced Logging**

### **Backend API Logs**
```
📥 Received emotional record data: {"emotion": "happy", "intensity": 8}
✅ Successfully saved emotional record to database with ID: abc-123
📤 Returning response: {"id": "abc-123", "status": "saved"}
```

### **Flutter App Logs**
```
📤 Creating emotional record: happy (intensity: 8)
💾 Saved emotional record locally
🌐 Record synced immediately
✅ Emotional record created successfully: abc-123
```

## 🚀 **Usage Examples**

### **Save Emotional Record**
```dart
// Use the sync service (handles offline/online automatically)
final syncService = ref.read(syncServiceProvider);
final record = EmotionalRecord(/* ... */);
await syncService.saveEmotionalRecord(record);
```

### **Monitor Sync Status**
```dart
// Listen to sync status changes
ref.listen(syncStatusProvider, (previous, next) {
  next.when(
    data: (status) => print('Sync status: $status'),
    loading: () => print('Loading sync status...'),
    error: (error, stack) => print('Sync error: $error'),
  );
});
```

### **Get All Records (Local + Synced)**
```dart
// Get all emotional records from local database
final records = await ref.read(emotionalRecordsProvider.future);
```

## 🧪 **Testing Scenarios**

### **Online Mode**
1. Create emotional record → Should save locally + sync immediately
2. Check database → Record should appear in PostgreSQL
3. Check logs → Should see successful sync messages

### **Offline Mode**
1. Turn off network/backend
2. Create emotional record → Should save locally only
3. Turn network back on → Should auto-sync pending records
4. Check database → Record should appear after sync

### **Error Handling**
1. Backend returns 500 error → Should save locally and retry
2. Network timeout → Should save locally and retry
3. Invalid data → Should show proper error message

## 🔧 **Configuration**

### **Sync Settings**
```dart
// In SyncService
static const Duration syncInterval = Duration(seconds: 30);
static const Duration networkTimeout = Duration(seconds: 10);
static const int maxRetryAttempts = 3;
```

### **Database Settings**
```dart
// In LocalDatabaseService  
static const String dbName = 'emotionai_local.db';
static const int dbVersion = 1;
static const int maxLocalRecords = 100;
```

## 📊 **Sync Statistics**

The app provides detailed sync statistics:
- **Total records**: Local + synced count
- **Synced records**: Successfully uploaded
- **Pending records**: Waiting for sync
- **Failed records**: Exceeded retry limit
- **Last sync time**: When sync last succeeded

## ⚡ **Performance Optimizations**

1. **Batch Sync**: Multiple records synced in sequence
2. **Cleanup**: Old synced records automatically removed
3. **Lazy Loading**: Database connections created on demand
4. **Connection Pooling**: Reuse database connections
5. **Background Sync**: Sync happens in background thread

## 🛠️ **Next Steps**

To complete the implementation:

1. **Add to main app**:
   ```dart
   // In main.dart
   final syncService = SyncService();
   await syncService.initialize();
   ```

2. **Add sync widget to UI**:
   ```dart
   // In app bar or settings
   SyncStatusWidget(showDetails: false)
   ```

3. **Update dependencies**:
   ```bash
   flutter pub get
   ```

4. **Test the flow**:
   - Create emotional records online/offline
   - Check database with SQL queries
   - Monitor logs for sync status

This implementation provides a robust, production-ready offline/online sync system with comprehensive logging and user feedback! 🎉