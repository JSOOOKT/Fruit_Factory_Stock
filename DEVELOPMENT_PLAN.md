# Development Plan: Fruit Factory Stock

**Status:** In Progress  
**Version:** 1.0.0  
**Last Updated:** 18 July 2026

## Phase 1: Project Foundation ✅ (COMPLETE)

- [x] Initialize Flutter project structure
- [x] Set up Firebase integration
- [x] Configure Riverpod state management
- [x] Set up GoRouter navigation
- [x] Create data models (Freezed)
- [x] Configure bilingual support (TH/EN)
- [x] Set up code generation pipeline
- [x] Create analysis and linting configuration
- [x] Document development setup

### Deliverables
- ✅ pubspec.yaml with all dependencies
- ✅ Project directory structure
- ✅ Firebase configuration (firebase_options.dart)
- ✅ Data models: StockInEntry, StockOutEntry, ProductType, User, ShiftSchedule
- ✅ Localization files (TH/EN)
- ✅ Firebase and Voice service stubs
- ✅ README.md and DEVELOPMENT_SETUP.md
- ✅ Error handling framework

---

## Phase 2: Core Features (IN PROGRESS)

### 2.1 Authentication & User Management
- [ ] Firebase Auth service integration
- [ ] Login screen (email/password)
- [ ] Sign up screen (admin only)
- [ ] Password reset flow
- [ ] User profile management
- [ ] Shift schedule management
- [ ] Role-based access control (RBAC)

### 2.2 Product Management
- [ ] Create/Read/Update/Delete product types
- [ ] Product list screen
- [ ] Product form (add/edit)
- [ ] Bulk import products
- [ ] Product search and filtering

### 2.3 Stock In Entry
- [ ] Manual stock in form
- [ ] Voice-to-data entry flow
- [ ] Voice recognition setup (Thai/English)
- [ ] NLU parsing for stock in entries
- [ ] Confirmation screen
- [ ] Entry history view
- [ ] Edit/delete entries (supervisor/admin only)

**Estimated:** 4 weeks

### 2.4 Stock Out Entry
- [ ] Manual stock out form
- [ ] Voice-to-data entry flow
- [ ] Validation (prevent over-withdrawal)
- [ ] Confirmation screen
- [ ] Entry history view
- [ ] Edit/delete entries (supervisor/admin only)

**Estimated:** 3 weeks

### 2.5 Dashboard & Reporting
- [ ] Real-time stock balance calculation
- [ ] Summary table by product type
- [ ] Filtering by date range
- [ ] Filtering by sender/product
- [ ] Low-stock alerts
- [ ] PDF export
- [ ] Excel export
- [ ] Daily/weekly/monthly reports

**Estimated:** 3 weeks

---

## Phase 3: Advanced Features

### 3.1 Offline Support
- [ ] Local SQLite database for drafts
- [ ] Background sync when online
- [ ] Conflict resolution
- [ ] Draft management UI

**Estimated:** 2 weeks

### 3.2 Audit Trail & Analytics
- [ ] Complete audit logging
- [ ] User activity tracking
- [ ] Entry modification history
- [ ] Analytics dashboard
- [ ] Performance metrics

**Estimated:** 2 weeks

### 3.3 Settings & Configuration
- [ ] Language switching (TH/EN)
- [ ] Theme preferences
- [ ] Voice recognition settings
- [ ] Notification preferences
- [ ] Low-stock thresholds

**Estimated:** 1 week

### 3.4 Mobile Optimization
- [ ] Responsive design for all screen sizes
- [ ] Tablet support
- [ ] Landscape orientation
- [ ] Touch optimization (large buttons for factory floor)
- [ ] Accessibility features

**Estimated:** 2 weeks

---

## Phase 4: Testing & QA

### 4.1 Unit Tests
- [ ] Data model tests
- [ ] Service tests (Firebase, Voice)
- [ ] Calculation tests
- [ ] Validation tests
- [ ] Target: >80% coverage

**Estimated:** 2 weeks

### 4.2 Widget Tests
- [ ] Screen UI tests
- [ ] Form submission tests
- [ ] Navigation flow tests
- [ ] Localization tests

**Estimated:** 2 weeks

### 4.3 Integration Tests
- [ ] End-to-end voice entry flow
- [ ] Stock calculation verification
- [ ] Firebase data sync
- [ ] Offline to online sync

**Estimated:** 2 weeks

### 4.4 User Acceptance Testing (UAT)
- [ ] On-site testing with actual factory workers
- [ ] Voice recognition accuracy verification
- [ ] Performance under real load
- [ ] Feedback collection and iteration

**Estimated:** 3 weeks

---

## Phase 5: Deployment & Launch

### 5.1 Pre-Launch
- [ ] Final bug fixes from UAT
- [ ] Performance optimization
- [ ] Security audit
- [ ] Data migration plan
- [ ] User training materials

**Estimated:** 2 weeks

### 5.2 Launch
- [ ] Deploy to Google Play Store (Android)
- [ ] Deploy to App Store (iOS)
- [ ] Deploy web version to Firebase Hosting
- [ ] Set up monitoring and alerting
- [ ] Production Firebase environment

**Estimated:** 1 week

### 5.3 Post-Launch Support
- [ ] Monitor user feedback
- [ ] Fix critical bugs
- [ ] Performance monitoring
- [ ] User support setup

**Ongoing**

---

## Development Tasks by Priority

### HIGH PRIORITY (Critical Path)
1. **Authentication** - Needed for all other features
2. **Stock In Entry** - Core business requirement
3. **Stock Out Entry** - Core business requirement
4. **Dashboard** - Essential for stock visibility
5. **Product Management** - Required to set up initial data

### MEDIUM PRIORITY
6. Voice recognition implementation
7. NLU parsing for voice inputs
8. Offline support
9. Comprehensive testing
10. Advanced reporting

### LOW PRIORITY (Post-MVP)
11. Mobile optimization beyond basics
12. Analytics dashboard
13. Forecasting features
14. Integration with external systems

---

## Risk Mitigation

### Technical Risks
- **Voice Recognition Accuracy**: Implement confidence scoring and confirmation step
- **Firestore Costs**: Set up budget alerts, implement data pruning
- **Offline Sync Conflicts**: Use timestamps and last-write-wins strategy
- **User Adoption**: Extensive UAT and training

### Timeline Risks
- **Scope Creep**: Prioritize MVP features only
- **Resource Constraints**: Plan for parallel development
- **Integration Delays**: Test Firebase early

---

## Success Criteria

- ✅ All core features (Stock In/Out, Dashboard) deployed
- ✅ Voice recognition accuracy ≥ 90%
- ✅ >80% unit test coverage
- ✅ Successful UAT with factory team
- ✅ Zero calculation errors
- ✅ <2 second response times
- ✅ 99% uptime SLA

---

## Dependencies & Resources

### External Services
- **Firebase Firestore** - Database
- **Firebase Auth** - Authentication
- **Google Cloud Speech-to-Text** - Voice recognition
- **Firebase Hosting** - Web deployment

### Tools & Libraries
- Flutter 3.0+
- Dart 2.17+
- Riverpod (state management)
- GoRouter (navigation)
- Freezed (data models)
- Easy Localization (multilingual)

### Team
- Flutter Developer(s)
- UI/UX Designer
- QA Engineer
- Backend Support (Firebase)
- Product Manager

---

## Communication & Updates

### Sprint Planning
- **Sprint Duration**: 2 weeks
- **Sprint Planning**: Every other Monday
- **Daily Standup**: 15 minutes (async or sync)
- **Sprint Review**: End of sprint
- **Retrospective**: After sprint review

### Stakeholder Updates
- **Weekly**: Status to product manager
- **Bi-weekly**: Demo to factory team
- **Monthly**: Executive summary

---

## Appendix: Detailed Feature Checklist

### Authentication
- [ ] Firebase Auth integration
- [ ] Email/password login
- [ ] Email verification
- [ ] Password reset
- [ ] Session persistence
- [ ] User profile CRUD
- [ ] Role assignment
- [ ] Permission checking

### Stock In
- [ ] Manual entry form validation
- [ ] Voice entry flow
- [ ] Speech-to-text integration
- [ ] NLU parsing
- [ ] Confirmation UI
- [ ] Auto-save drafts
- [ ] Entry history pagination
- [ ] Edit/delete with audit
- [ ] Sender search (autocomplete)
- [ ] Date picker UI

### Stock Out
- [ ] Manual entry form validation
- [ ] Available quantity check
- [ ] Prevent over-withdrawal
- [ ] Voice entry flow
- [ ] Confirmation UI
- [ ] Entry history pagination
- [ ] Edit/delete with audit

### Dashboard
- [ ] Real-time calculations
- [ ] Summary table rendering
- [ ] Product filtering
- [ ] Date range filtering
- [ ] Sender filtering
- [ ] Low-stock highlighting
- [ ] PDF export
- [ ] Excel export

### Products
- [ ] CRUD operations
- [ ] Bilingual names (TH/EN)
- [ ] Search functionality
- [ ] Bulk import
- [ ] Deactivation (soft delete)

### Users
- [ ] CRUD operations
- [ ] Role assignment
- [ ] Shift scheduling
- [ ] Permission enforcement
- [ ] Last login tracking

### Settings
- [ ] Language toggle (TH/EN)
- [ ] Theme selection
- [ ] Voice settings
- [ ] Low-stock thresholds
- [ ] Logout

### Reporting
- [ ] Daily summary
- [ ] Weekly summary
- [ ] Monthly summary
- [ ] Sender history
- [ ] Product history
- [ ] User activity log

---

**Next Review Date**: 25 July 2026
