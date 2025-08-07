# Architecture Improvement Prompts for EC2/RDS Migration

## 🎯 **High Priority Code Changes**

### **PROMPT 1: State Management Standardization**
**Context**: Currently mixing Riverpod and Provider packages, causing inconsistent state management patterns.

**Implementation Task**: 
> "Refactor the Flutter app to use only Riverpod for state management. Remove the Provider package dependency and convert `OfflineCalendarProvider` (and any other ChangeNotifier classes) to Riverpod StateNotifier. Create a centralized dependency injection container using Riverpod providers for all services (ApiService, SQLiteHelper, OfflineDataService). Ensure all providers are properly scoped and follow the Riverpod best practices."

**Files to Change**:
- `lib/main.dart` (remove Provider wrapper)
- `lib/features/calendar/events/offline_calendar_provider.dart` → Convert to StateNotifier
- Create `lib/core/providers/app_providers.dart` for centralized DI
- All feature providers to use consistent patterns

**Expected Benefits**:
- Single source of truth for state
- Better performance with fine-grained rebuilds
- Easier testing and debugging

---

### **PROMPT 2: Enhanced Offline-First Architecture**
**Context**: Current offline sync is complex with dual logic in main.dart and OfflineDataService. No proper conflict resolution.

**Implementation Task**:
> "Redesign the offline-first architecture to be more robust. Create a unified sync manager that handles all offline/online operations. Implement proper conflict resolution strategies (last-write-wins, user-choice, automatic merge). Add clear UI indicators for sync status, offline mode, and sync conflicts. Create a background sync queue that intelligently batches operations and handles retry logic. Add comprehensive sync state management with user-friendly error recovery."

**Files to Change**:
- Create `lib/core/sync/sync_manager.dart`
- Refactor `lib/shared/services/offline_data_service.dart`
- Clean up sync logic in `lib/main.dart`
- Add sync UI widgets in `lib/shared/widgets/`
- Implement conflict resolution dialogs

**Expected Benefits**:
- Reliable data synchronization
- Better user experience during network issues
- Clear feedback on sync status

---

### **PROMPT 3: API Service with Circuit Breaker & Retry Logic**
**Context**: Current API service lacks retry logic, circuit breaker patterns, and proper error classification.

**Implementation Task**:
> "Modernize the ApiService class to implement enterprise-grade reliability patterns. Add exponential backoff retry logic for transient failures, implement circuit breaker pattern to prevent cascading failures, add request/response interceptors for logging and metrics collection. Create proper error classification (network, server, client, business logic errors) with appropriate handling strategies. Add timeout configurations per endpoint type and implement request deduplication for idempotent operations."

**Files to Change**:
- Refactor `lib/data/api_service.dart`
- Create `lib/core/network/` directory with:
  - `circuit_breaker.dart`
  - `retry_policy.dart`
  - `request_interceptor.dart`
  - `error_classifier.dart`
- Update all API calls to use new patterns

**Expected Benefits**:
- Better resilience to network issues
- Improved debugging with request logging
- Reduced server load with intelligent retries

---

### **PROMPT 4: Repository Pattern Implementation**
**Context**: Direct database access from UI layers and no abstraction between data sources.

**Implementation Task**:
> "Implement the Repository pattern to create a clean abstraction layer between the UI and data sources. Create repository interfaces for each data type (EmotionalRecord, BreathingSession, etc.) with implementations that intelligently choose between local SQLite, remote API, and cache. Add automatic fallback mechanisms when one data source fails. Implement intelligent caching strategies with TTL and cache invalidation. Remove all direct SQLiteHelper and ApiService calls from UI layers."

**Files to Create**:
- `lib/core/repositories/` directory with:
  - `base_repository.dart` (interface)
  - `emotional_record_repository.dart`
  - `breathing_session_repository.dart`
  - `user_repository.dart`
- `lib/core/cache/` directory for caching logic

**Files to Change**:
- All providers and services to use repositories
- Remove direct database access from UI

**Expected Benefits**:
- Clean separation of concerns
- Easier testing with mock repositories
- Consistent data access patterns

---

## 🔧 **Medium Priority Code Changes**

### **PROMPT 5: Enhanced Error Handling System**
**Context**: Inconsistent error handling across features with generic error messages.

**Implementation Task**:
> "Create a comprehensive error handling system with a global error handler, error classification, user-friendly error messages, and automatic error reporting. Implement error boundaries for different app sections, create a centralized error logging system with different log levels, and add error recovery strategies. Create user-friendly error dialogs with actionable recovery options and implement automatic retry for recoverable errors."

**Files to Create**:
- `lib/core/error/` directory with:
  - `error_handler.dart`
  - `error_classifier.dart`
  - `error_reporter.dart`
  - `app_error.dart` (custom error types)
- Error boundary widgets

**Expected Benefits**:
- Better user experience during errors
- Easier debugging and monitoring
- Consistent error handling patterns

---

### **PROMPT 6: Background Task Management**
**Context**: Heavy operations might be blocking the UI thread.

**Implementation Task**:
> "Implement a background task management system using Dart isolates for heavy operations like database migrations, data processing, and sync operations. Create a task queue system that can prioritize and batch operations. Add progress tracking for long-running tasks with UI feedback. Implement proper task cancellation and cleanup mechanisms."

**Files to Create**:
- `lib/core/tasks/` directory with:
  - `task_manager.dart`
  - `background_worker.dart`
  - `task_queue.dart`
- Progress indicator widgets

**Expected Benefits**:
- Smooth UI performance
- Better resource management
- User feedback for long operations

---

### **PROMPT 7: Performance Monitoring Integration**
**Context**: No performance metrics collection for monitoring app behavior.

**Implementation Task**:
> "Add comprehensive performance monitoring throughout the app. Implement metrics collection for API response times, database query performance, UI render times, and memory usage. Create a metrics service that can send data to AWS CloudWatch when deployed. Add performance alerts for slow operations and memory leaks detection."

**Files to Create**:
- `lib/core/monitoring/` directory with:
  - `performance_monitor.dart`
  - `metrics_collector.dart`
  - `analytics_service.dart`

**Expected Benefits**:
- Proactive performance optimization
- Better understanding of user behavior
- Early detection of performance issues

---

## 🎨 **UI/UX Improvement Prompts**

### **PROMPT 8: Offline Mode UI Indicators**
**Context**: Users have no clear indication of offline mode or sync status.

**Implementation Task**:
> "Create comprehensive offline mode UI indicators throughout the app. Add a persistent connectivity status bar, sync progress indicators, offline badges on cached data, and clear messaging when features are limited due to offline mode. Implement sync conflict resolution UI with user-friendly options to resolve data conflicts."

**Files to Create**:
- `lib/shared/widgets/connectivity_widgets/`
- Sync status widgets
- Offline mode overlays

**Expected Benefits**:
- Clear user feedback
- Better offline experience
- Reduced user confusion

---

### **PROMPT 9: Loading State Standardization**
**Context**: Inconsistent loading states across different features.

**Implementation Task**:
> "Standardize loading states across the entire app. Create reusable loading widgets for different scenarios (initial load, refresh, infinite scroll, form submission). Implement skeleton loading screens for better perceived performance. Add timeout handling for loading states with appropriate error fallbacks."

**Files to Create**:
- `lib/shared/widgets/loading/` directory
- Skeleton loading widgets
- Loading state providers

**Expected Benefits**:
- Consistent user experience
- Better perceived performance
- Professional app feel

---

## 🔒 **Security & Reliability Prompts**

### **PROMPT 10: Enhanced Security Audit**
**Context**: Security-sensitive app with user data and AI interactions.

**Implementation Task**:
> "Conduct a comprehensive security audit and implement improvements. Review all data storage mechanisms, ensure proper encryption for sensitive data, implement secure API key management with rotation, add request/response validation, implement rate limiting on the client side, and add proper session management with automatic logout."

**Files to Review/Change**:
- All secure storage implementations
- API key management
- Session handling
- Data validation layers

**Expected Benefits**:
- Enhanced data protection
- Compliance with security standards
- User trust and confidence

---

### **PROMPT 11: Comprehensive Testing Framework**
**Context**: Limited test coverage across the app.

**Implementation Task**:
> "Implement a comprehensive testing framework with unit tests for all business logic, integration tests for data flows, widget tests for UI components, and end-to-end tests for critical user journeys. Add test coverage reporting, performance testing, and automated testing in CI/CD pipeline. Create mock services for reliable testing."

**Files to Create**:
- `test/` directory structure
- Mock services and repositories
- Test utilities and helpers
- Integration test scenarios

**Expected Benefits**:
- Reduced bugs and regressions
- Confident deployments
- Better code quality

---

## 🚀 **EC2/RDS Migration-Specific Prompts**

### **PROMPT 12: Database Connection Optimization**
**Context**: Moving from SQLite to PostgreSQL requires connection optimization.

**Implementation Task**:
> "Optimize database connections for PostgreSQL deployment. Implement connection pooling with proper lifecycle management, add connection health checks and automatic reconnection, implement query optimization with prepared statements, add database connection monitoring and metrics collection. Create database migration scripts with rollback capabilities."

**Files to Create**:
- `lib/core/database/` directory
- Connection pool management
- Migration scripts
- Database health monitoring

**Expected Benefits**:
- Efficient database usage
- Better scalability
- Reliable data access

---

### **PROMPT 13: AWS Services Integration**
**Context**: Moving to AWS requires integration with AWS services.

**Implementation Task**:
> "Integrate with AWS services for enhanced functionality. Add AWS Cognito for user authentication, implement S3 integration for file storage, add CloudWatch logging and metrics, implement AWS Secrets Manager for sensitive configuration, and add AWS SES for email notifications. Create AWS SDK wrappers for easier service management."

**Files to Create**:
- `lib/core/aws/` directory
- AWS service clients
- Configuration management
- Error handling for AWS services

**Expected Benefits**:
- Enterprise-grade infrastructure
- Scalable service architecture
- Better monitoring and alerting

---

## 📊 **Implementation Timeline & Priority**

### **Week 1 (Critical - Do First)**
1. **PROMPT 1**: State Management Standardization
2. **PROMPT 2**: Enhanced Offline-First Architecture
3. **PROMPT 8**: Offline Mode UI Indicators

### **Week 2 (High Priority)**
4. **PROMPT 3**: API Service with Circuit Breaker
5. **PROMPT 4**: Repository Pattern Implementation
6. **PROMPT 9**: Loading State Standardization

### **Week 3 (Migration Preparation)**
7. **PROMPT 12**: Database Connection Optimization
8. **PROMPT 5**: Enhanced Error Handling System
9. **PROMPT 13**: AWS Services Integration

### **Week 4 (Quality & Performance)**
10. **PROMPT 6**: Background Task Management
11. **PROMPT 7**: Performance Monitoring
12. **PROMPT 11**: Comprehensive Testing Framework

### **Ongoing (Security & Maintenance)**
13. **PROMPT 10**: Enhanced Security Audit

---

## 💡 **Implementation Tips**

1. **Start Small**: Implement one prompt at a time to avoid breaking changes
2. **Test Thoroughly**: Each change should include comprehensive testing
3. **Maintain Compatibility**: Keep existing features working during refactoring
4. **Document Changes**: Update documentation as you implement changes
5. **Monitor Performance**: Watch for performance regressions during implementation
6. **User Feedback**: Test with real users to ensure changes improve experience

## 🎯 **Success Criteria**

After implementing these prompts, your app should have:
- ✅ Consistent state management patterns
- ✅ Robust offline capabilities
- ✅ Enterprise-grade error handling
- ✅ Scalable architecture ready for EC2/RDS
- ✅ Comprehensive monitoring and logging
- ✅ Professional UI/UX with clear feedback
- ✅ High test coverage and code quality
- ✅ Security best practices implemented