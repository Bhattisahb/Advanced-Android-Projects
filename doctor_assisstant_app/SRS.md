# Software Requirements Specification (SRS)
## Doctor Assistant App

---

### **Document Information**

| Item | Details |
|------|---------|
| **Project Name** | Doctor Assistant App |
| **Document Type** | Software Requirements Specification (SRS) |
| **Version** | 1.0 |
| **Date** | December 17, 2025 |
| **Submitted By** | Husnain Amin (FA22 BSE 004) |
| **Team Member** | Muhammad Ahmad (FA22 BSE 035) |
| **Submitted To** | Mam Sidra Tariq |

---

## 1. Introduction

### 1.1 Purpose
The Doctor Assistant App is a comprehensive clinic/hospital management system designed to streamline patient and doctor management workflows. The application enables healthcare facilities to efficiently manage patient records, appointments, medical documentation, and doctor schedules.

### 1.2 Scope
The application provides functionality for:
- **Patient Management**: Create, view, update patient records
- **Doctor Management**: Add and manage doctor profiles with specialties and availability
- **Appointment Scheduling**: Book and manage appointments between patients and doctors
- **Medical Records**: Store and retrieve patient medical history, prescriptions, and test results
- **Patient Queue Management**: Track patients in waiting queue
- **Search Functionality**: Find patients and doctors by various criteria
- **Dashboard Analytics**: Display clinic statistics and metrics

### 1.3 Intended Audience
- Hospital/Clinic Administrators
- Receptionists
- Medical Staff
- Doctors
- System Developers and Maintainers

### 1.4 Document Overview
This SRS document details functional requirements, non-functional requirements, system architecture, data models, and constraints for the Doctor Assistant App.

---

## 2. Overall Description

### 2.1 Product Perspective
The Doctor Assistant App is a standalone mobile/web application built with Flutter, designed to operate independently with local data storage. It manages the complete lifecycle of patient-doctor interactions within a healthcare facility.

### 2.2 Product Features
1. **Patient Management Module**
   - Patient registration and profile management
   - Contact information and emergency details
   - Appointment history tracking
   - Medical records access

2. **Doctor Management Module**
   - Doctor profile creation with qualifications and specialties
   - Availability scheduling and working hours
   - Clinic information management
   - Consultation fee configuration

3. **Appointment System**
   - Appointment booking with date/time slots
   - Status tracking (scheduled, in-progress, completed, cancelled)
   - Appointment notes and reason documentation

4. **Medical Records**
   - Medical record creation and storage
   - Prescription management
   - Test result documentation
   - Attachment support for medical documents

5. **Dashboard & Search**
   - Quick access to clinic statistics
   - Patient and doctor search functionality
   - Settings for user preferences (dark mode)

### 2.3 User Classes and Characteristics

| User Class | Characteristics | Interactions |
|------------|------------------|--------------|
| **Admin/Receptionist** | Manages patients and doctors, books appointments | Full access to all features |
| **Doctor** | Views patient records, prescribes treatments | View appointments, patient details, medical records |
| **Patient** | Views appointments, medical history | Limited access to personal records |
| **System Administrator** | Maintains system health and data integrity | Backend configuration and monitoring |

---

## 3. Functional Requirements

### 3.1 Patient Management (FR-1)

#### FR-1.1: Patient Registration
- **Description**: System shall allow creation of new patient records
- **Inputs**: Name, age, gender, contact number, email, date of birth
- **Processing**: Validate inputs, generate unique patient ID, store in database
- **Outputs**: Confirmation message, patient ID
- **Priority**: High

#### FR-1.2: Patient Information Display
- **Description**: System shall display complete patient information
- **Inputs**: Patient ID
- **Processing**: Retrieve from Hive database
- **Outputs**: All patient details with formatted display
- **Priority**: High

#### FR-1.3: Patient Update
- **Description**: System shall allow updating existing patient information
- **Inputs**: Patient ID, updated fields
- **Processing**: Validate changes, update database
- **Outputs**: Success confirmation
- **Priority**: High

#### FR-1.4: Patient Deletion
- **Description**: System shall allow removal of patient records
- **Inputs**: Patient ID
- **Processing**: Delete from database, handle related appointments/records
- **Outputs**: Deletion confirmation
- **Priority**: Medium

#### FR-1.5: Patient Search
- **Description**: System shall search patients by name, ID, or contact
- **Inputs**: Search query
- **Processing**: Query Hive database with filters
- **Outputs**: List of matching patients
- **Priority**: High

#### FR-1.6: Last Appointment Tracking
- **Description**: System shall track patient's last appointment date
- **Inputs**: Appointment completion
- **Processing**: Update patient's lastAppointment field
- **Outputs**: Updated patient record
- **Priority**: Medium

---

### 3.2 Doctor Management (FR-2)

#### FR-2.1: Doctor Registration
- **Description**: System shall allow addition of new doctors
- **Inputs**: Name, specialty, qualification, experience, contact, clinic details, consultation fee, availability
- **Processing**: Validate inputs, generate unique doctor ID, store in database
- **Outputs**: Confirmation with doctor ID
- **Priority**: High

#### FR-2.2: Doctor Profile Display
- **Description**: System shall display complete doctor information
- **Inputs**: Doctor ID
- **Processing**: Retrieve doctor record from database
- **Outputs**: Doctor details including availability and qualifications
- **Priority**: High

#### FR-2.3: Doctor Update
- **Description**: System shall allow updating doctor information
- **Inputs**: Doctor ID, updated fields
- **Processing**: Validate and update database
- **Outputs**: Success confirmation
- **Priority**: High

#### FR-2.4: Doctor Deletion
- **Description**: System shall allow removing doctor records
- **Inputs**: Doctor ID
- **Processing**: Delete doctor and update related appointments
- **Outputs**: Deletion confirmation
- **Priority**: Medium

#### FR-2.5: Availability Management
- **Description**: System shall manage doctor working hours and availability
- **Inputs**: Doctor ID, day, start time, end time
- **Processing**: Store availability schedule in Availability nested class
- **Outputs**: Updated availability list
- **Priority**: High

#### FR-2.6: Doctor Search & Filtering
- **Description**: System shall search and filter doctors by specialty, qualifications
- **Inputs**: Search criteria
- **Processing**: Query doctors by attributes
- **Outputs**: Filtered doctor list
- **Priority**: High

---

### 3.3 Appointment Management (FR-3)

#### FR-3.1: Appointment Booking
- **Description**: System shall allow booking appointments between patients and doctors
- **Inputs**: Doctor ID, patient ID, date, time, reason for visit
- **Processing**: Validate slot availability, create appointment record
- **Outputs**: Appointment confirmation with ID
- **Priority**: High

#### FR-3.2: Appointment Status Management
- **Description**: System shall track appointment status
- **Inputs**: Appointment ID, new status
- **Processing**: Update status (scheduled → in-progress → completed/cancelled)
- **Outputs**: Updated appointment
- **Priority**: High

#### FR-3.3: Appointment Listing
- **Description**: System shall display appointments with filters
- **Inputs**: Filter criteria (doctor, patient, date range, status)
- **Processing**: Query appointments from database
- **Outputs**: List of matching appointments
- **Priority**: High

#### FR-3.4: Time Slot Management
- **Description**: System shall manage available time slots for doctors
- **Inputs**: Doctor ID, date
- **Processing**: Generate time slots based on doctor availability, mark booked slots
- **Outputs**: List of available and booked slots
- **Priority**: High

#### FR-3.5: Appointment Notes
- **Description**: System shall store notes for appointments
- **Inputs**: Appointment ID, notes text
- **Processing**: Save notes to appointment record
- **Outputs**: Updated appointment with notes
- **Priority**: Medium

#### FR-3.6: Appointment Cancellation
- **Description**: System shall allow cancelling scheduled appointments
- **Inputs**: Appointment ID
- **Processing**: Update status to cancelled, free up time slot
- **Outputs**: Cancellation confirmation
- **Priority**: High

---

### 3.4 Medical Records Management (FR-4)

#### FR-4.1: Medical Record Creation
- **Description**: System shall create medical records for patient-doctor interactions
- **Inputs**: Patient ID, doctor ID, title, description, date, prescriptions, test results
- **Processing**: Create record with nested Prescription and TestResult objects
- **Outputs**: Medical record confirmation with ID
- **Priority**: High

#### FR-4.2: Medical Record Retrieval
- **Description**: System shall retrieve patient medical history
- **Inputs**: Patient ID
- **Processing**: Query all records for patient from database
- **Outputs**: List of medical records sorted by date
- **Priority**: High

#### FR-4.3: Prescription Management
- **Description**: System shall manage prescriptions within medical records
- **Inputs**: Medical record ID, medication name, dosage, duration
- **Processing**: Store prescription data as nested object
- **Outputs**: Medical record with prescription
- **Priority**: High

#### FR-4.4: Test Result Documentation
- **Description**: System shall store test results
- **Inputs**: Medical record ID, test name, result, date
- **Processing**: Store as nested TestResult object
- **Outputs**: Updated medical record
- **Priority**: High

#### FR-4.5: Document Attachments
- **Description**: System shall support file attachments to medical records
- **Inputs**: Medical record ID, file path
- **Processing**: Store file paths in attachments list
- **Outputs**: Medical record with attachments
- **Priority**: Medium

#### FR-4.6: Medical Record Search
- **Description**: System shall search medical records by patient or date range
- **Inputs**: Search criteria
- **Processing**: Query medical records
- **Outputs**: Matching medical records
- **Priority**: Medium

---

### 3.5 Patient Queue Management (FR-5)

#### FR-5.1: Queue Entry Creation
- **Description**: System shall add patients to waiting queue
- **Inputs**: Patient ID, doctor ID, entry time
- **Processing**: Create queue entry with sequence number
- **Outputs**: Queue position confirmation
- **Priority**: Medium

#### FR-5.2: Queue Status Display
- **Description**: System shall display current patient queue
- **Inputs**: Doctor ID or clinic-wide view
- **Processing**: Retrieve and sort queue entries by entry time
- **Outputs**: Ordered patient queue list
- **Priority**: Medium

#### FR-5.3: Queue Removal
- **Description**: System shall remove patients from queue when called
- **Inputs**: Queue entry ID
- **Processing**: Delete queue entry, update remaining positions
- **Outputs**: Updated queue list
- **Priority**: Medium

---

### 3.6 Dashboard & Analytics (FR-6)

#### FR-6.1: Dashboard Display
- **Description**: System shall show clinic overview statistics
- **Inputs**: None (auto-loaded on dashboard access)
- **Processing**: Calculate total patients, doctors, appointments, queue length
- **Outputs**: Dashboard with statistics tiles
- **Priority**: Medium

#### FR-6.2: Appointment Overview
- **Description**: System shall display upcoming and past appointments
- **Inputs**: Date range (optional)
- **Processing**: Query and categorize appointments
- **Outputs**: Appointment summary with status breakdown
- **Priority**: Medium

---

### 3.7 Search & Filter (FR-7)

#### FR-7.1: Global Search
- **Description**: System shall provide unified search functionality
- **Inputs**: Search query
- **Processing**: Search across patients, doctors, appointments
- **Outputs**: Categorized results
- **Priority**: High

#### FR-7.2: Advanced Filtering
- **Description**: System shall support filtering by multiple criteria
- **Inputs**: Filter parameters
- **Processing**: Apply filters to queries
- **Outputs**: Filtered results
- **Priority**: Medium

---

### 3.8 Settings & Preferences (FR-8)

#### FR-8.1: Dark Mode Toggle
- **Description**: System shall support light and dark themes
- **Inputs**: User preference
- **Processing**: Apply theme globally
- **Outputs**: Theme applied to entire app
- **Priority**: Low

#### FR-8.2: Preference Persistence
- **Description**: System shall save user preferences
- **Inputs**: User settings changes
- **Processing**: Store in local storage
- **Outputs**: Preferences restored on app restart
- **Priority**: Low

---

## 4. Non-Functional Requirements

### 4.1 Performance Requirements (NFR-1)
- **NFR-1.1**: Patient search shall return results within 500ms for database with up to 10,000 records
- **NFR-1.2**: Appointment booking shall complete within 1000ms
- **NFR-1.3**: Dashboard loading time shall not exceed 2 seconds
- **NFR-1.4**: Database queries shall be optimized with indexing on frequently searched fields

### 4.2 Usability Requirements (NFR-2)
- **NFR-2.1**: User interface shall follow Material Design 3 guidelines
- **NFR-2.2**: Average user shall complete patient registration in less than 5 minutes
- **NFR-2.3**: Navigation structure shall be intuitive with clear button labels
- **NFR-2.4**: Error messages shall be clear and actionable

### 4.3 Reliability Requirements (NFR-3)
- **NFR-3.1**: System shall have 99% uptime (local app)
- **NFR-3.2**: Data loss risk shall be minimized through Hive database reliability
- **NFR-3.3**: All critical operations shall have data validation before execution
- **NFR-3.4**: Application shall recover gracefully from errors

### 4.4 Security Requirements (NFR-4)
- **NFR-4.1**: Patient medical records shall be stored securely locally
- **NFR-4.2**: Sensitive data shall not be logged or exposed in logs
- **NFR-4.3**: Input validation shall prevent SQL injection and data corruption
- **NFR-4.4**: Future versions shall implement user authentication and role-based access control

### 4.5 Maintainability Requirements (NFR-5)
- **NFR-5.1**: Code shall follow Dart best practices and style guidelines
- **NFR-5.2**: All classes shall have clear separation of concerns
- **NFR-5.3**: Services shall be testable and decoupled from UI
- **NFR-5.4**: Code shall be documented with comments for complex logic

### 4.6 Scalability Requirements (NFR-6)
- **NFR-6.1**: System architecture shall support future database migration to backend
- **NFR-6.2**: Data models shall be designed for API integration
- **NFR-6.3**: Local storage shall efficiently handle up to 100,000 records

### 4.7 Compatibility Requirements (NFR-7)
- **NFR-7.1**: Application shall run on Android 7.0+ (API level 24+)
- **NFR-7.2**: Application shall run on iOS 11.0+
- **NFR-7.3**: Application shall support Windows, macOS, Linux desktop platforms
- **NFR-7.4**: Application shall be responsive on various screen sizes (mobile, tablet, web)

---

## 5. System Architecture

### 5.1 Architectural Pattern
The application follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│        Presentation Layer (UI)      │
│  (Screens: Dashboard, Search, etc)  │
├─────────────────────────────────────┤
│    Business Logic Layer (Models)    │
│  (Patient, Doctor, Appointment)     │
├─────────────────────────────────────┤
│      Data Access Layer (Services)   │
│  (LocalStorageService, DoctorService)│
├─────────────────────────────────────┤
│   Database Layer (Hive + SharedPref)|
│  (Local persistent storage)         │
└─────────────────────────────────────┘
```

### 5.2 Technology Stack
| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter |
| **Programming Language** | Dart |
| **Database** | Hive (primary), SharedPreferences (secondary) |
| **Design System** | Material Design 3 |
| **State Management** | setState (StatefulWidget) |
| **Platform Support** | Android, iOS, Windows, macOS, Linux, Web |

### 5.3 Module Structure

```
lib/
├── main.dart                          # Application entry point
├── models/                            # Data models
│   ├── patient.dart
│   ├── doctor.dart
│   ├── doctor_model.dart
│   ├── appointment.dart
│   ├── medical_record.dart
│   ├── patient_queue.dart
│   └── report.dart
├── services/                          # Business logic & data access
│   ├── local_storage_service.dart     # Hive database wrapper
│   └── doctor_service.dart            # Doctor-specific operations
└── screens/                           # UI Screens
    ├── main_screen.dart               # Tab navigation hub
    ├── dashboard_screen.dart
    ├── search_screen.dart
    ├── appointments_screen.dart
    ├── medical_records_screen.dart
    ├── patient_details_screen.dart
    ├── patient_queue_screen.dart
    ├── doctor_management_page.dart
    ├── add_doctor_screen.dart
    ├── view_doctors_screen.dart
    ├── doctor_dashboard_screen.dart
    ├── doctor_profile_screen.dart
    ├── doctor_availability_screen.dart
    ├── clinic_info_screen.dart
    ├── settings_screen.dart
    └── appointment_scheduler_screen.dart
```

---

## 6. Data Models

### 6.1 Patient Model
```dart
class Patient {
  final String id;           // Unique identifier
  final String name;         // Full name
  final int age;            // Age in years
  final String gender;      // Male/Female/Other
  final String contactNumber;
  final String email;
  final DateTime dateOfBirth;
  final DateTime lastAppointment;  // Track history
}
```
- **Purpose**: Store patient demographic and contact information
- **Persistence**: Hive database (patientBox)
- **Relationships**: Referenced in Appointment, MedicalRecord models

### 6.2 Doctor Model
```dart
class Doctor {
  final String id;
  final String name;
  final String specialty;        // e.g., "Cardiologist"
  final String qualification;    // e.g., "MBBS, MD"
  final int experience;          // Years of experience
  final String contactNumber;
  final String profilePhotoPath;
  final String clinicName;
  final String clinicAddress;
  final double consultationFee;
  final String workingHours;     // e.g., "9:00 AM - 5:00 PM"
  final List<Availability> availability;
}

class Availability {
  final String day;        // Monday, Tuesday, etc.
  final String startTime;  // HH:MM format
  final String endTime;    // HH:MM format
}
```
- **Purpose**: Store doctor credentials, clinic info, and schedule
- **Persistence**: Hive database (doctorBox)
- **Relationships**: Referenced in Appointment, MedicalRecord models

### 6.3 Appointment Model
```dart
class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final DateTime dateTime;
  final String reason;
  final AppointmentStatus status;  // scheduled, inProgress, completed, cancelled
  final String notes;
}

enum AppointmentStatus { scheduled, inProgress, completed, cancelled }

class TimeSlot {
  final String id;
  final DateTime dateTime;
  final bool isBooked;
}
```
- **Purpose**: Manage appointment bookings and tracking
- **Persistence**: Hive database (appointmentsBox)
- **Relationships**: Links Patient and Doctor models

### 6.4 Medical Record Model
```dart
class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String title;
  final String description;
  final DateTime date;
  final List<String> attachments;  // File paths
  final String notes;
  final List<Prescription> prescriptions;
  final List<TestResult> testResults;
}

class Prescription {
  final String medicationName;
  final String dosage;
  final String duration;
  // ... serialization methods
}

class TestResult {
  final String testName;
  final String result;
  final DateTime date;
  // ... serialization methods
}
```
- **Purpose**: Store patient medical history, treatments, and tests
- **Persistence**: Hive database (reportsBox)
- **Relationships**: References Patient and Doctor

### 6.5 Patient Queue Model
```dart
class PatientQueue {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime entryTime;
  final int queuePosition;
  // ... serialization methods
}
```
- **Purpose**: Track patients in waiting queue
- **Persistence**: Hive database (patient_queuesBox)
- **Relationships**: References Patient and Doctor

### 6.6 Report Model
```dart
class Report {
  // Medical report/document model for additional documentation
  // (Details similar to MedicalRecord)
}
```

---

## 7. Database Design

### 7.1 Hive Database Structure

| Box Name | Key | Value (Serialized) | Purpose |
|----------|-----|-------------------|---------|
| `patients` | Patient ID | JSON serialized Patient | Store all patients |
| `doctors` | Doctor ID | JSON serialized Doctor | Store all doctors |
| `appointments` | Appointment ID | JSON serialized Appointment | Store all appointments |
| `reports` | Report ID | JSON serialized Report | Store medical reports |
| `patient_queues` | Queue ID | JSON serialized PatientQueue | Store queue entries |

### 7.2 Data Serialization
- All models implement `toJson()` and `fromJson()` methods
- DateTime fields stored as millisecondsSinceEpoch for portability
- Enum fields stored as index values
- Nested objects (Prescription, TestResult) serialized recursively

### 7.3 Query Operations
```dart
// Examples of supported queries
getDoctors()              // Fetch all doctors
getPatient(String id)     // Get specific patient
getReportsForPatient(String patientId)  // Filter by patient
getDoctorById(String id)  // Get specific doctor
```

---

## 8. User Interface Design

### 8.1 Design System
- **Framework**: Material Design 3
- **Primary Color**: #137fec (Blue)
- **Theme**: Supports light and dark modes
- **Responsive**: Adapts to mobile, tablet, and web screens

### 8.2 Navigation Structure

#### Home Screen
- Welcome message
- Two main buttons:
  - **Patient Management** → MainScreen
  - **Doctor Management** → DoctorManagementPage

#### Patient Management (MainScreen)
- **BottomNavigationBar** with 4 tabs:
  1. **Dashboard** - Clinic overview and statistics
  2. **Search** - Find patients and doctors
  3. **Appointments** - View/manage appointments
  4. **Settings** - User preferences (dark mode)

#### Doctor Management
- **Add Doctor** → AddDoctorScreen
- **View Doctors** → ViewDoctorsScreen
- **Doctor Dashboard** → DoctorDashboardScreen

### 8.3 Screen Components
- **AppBar**: Consistent header with title and white text on blue background
- **ElevatedButtons**: Full-width buttons with icons and text
- **Cards**: Display patient/doctor information in organized cards
- **Lists**: Scrollable lists for appointments, medical records, queues
- **Forms**: Input fields for patient registration, appointment booking

---

## 9. Interface Specifications

### 9.1 Input Interfaces
- **Patient Registration Form**: Name, age, gender, contact, email, DOB
- **Doctor Registration Form**: Name, specialty, qualifications, experience, clinic details, fees, availability
- **Appointment Booking Form**: Date, time, reason, notes
- **Medical Record Form**: Title, description, prescriptions, test results

### 9.2 Output Interfaces
- **Dashboard Display**: Statistics tiles showing key metrics
- **Patient List**: Searchable, sortable list of patients
- **Doctor List**: Filterable list by specialty
- **Appointment Calendar**: Visual appointment schedule
- **Medical Records View**: Patient history with detailed records

---

## 10. Constraints and Assumptions

### 10.1 Constraints
1. **Storage**: Limited by device storage capacity (applicable for mobile)
2. **Performance**: Database performance degrades with very large datasets (100K+ records)
3. **Offline-Only**: Currently operates offline without cloud synchronization
4. **No Authentication**: No user login/role-based access control (planned for future)
5. **Single Device**: Data is device-specific; no cross-device synchronization
6. **Platform Dependencies**: Requires platform-specific SDKs for compilation

### 10.2 Assumptions
1. Users have Flutter development environment set up for installation
2. Device has sufficient storage (minimum 100MB free space)
3. Users are familiar with clinic management concepts
4. Data backup is user's responsibility
5. Future versions will integrate with backend server
6. No concurrent multi-user access (single device assumption)

---

## 11. Testing Requirements

### 11.1 Unit Testing
- Test all model serialization (toJson/fromJson)
- Test business logic in services (CRUD operations)
- Test data validation in models

### 11.2 Integration Testing
- Test LocalStorageService with Hive database
- Test complete appointment booking flow
- Test patient search functionality

### 11.3 UI Testing
- Verify all screens render correctly
- Test navigation between screens
- Test dark mode toggle functionality
- Test responsiveness on different screen sizes

### 11.4 Performance Testing
- Measure database query response times
- Test with 10,000+ records
- Verify memory usage is acceptable

---

## 12. Future Enhancements

### 12.1 Planned Features
1. **Backend Integration**: Connect to REST API for data synchronization
2. **User Authentication**: Login system with role-based access control
3. **Cloud Backup**: Automatic data synchronization to cloud
4. **Notifications**: Appointment reminders via push notifications
5. **Payment Integration**: In-app payment for consultations
6. **Video Consultations**: Integrated video calling feature
7. **Prescription Management**: Digital prescription generation and printing
8. **Analytics**: Advanced reports and clinic statistics
9. **Multi-Language Support**: Localization for different languages
10. **Insurance Integration**: Support for insurance claim processing

### 12.2 Technical Improvements
1. Implement GetX or Provider for state management
2. Add comprehensive error handling and logging
3. Implement database migrations for schema changes
4. Add unit and integration tests
5. Optimize database queries with proper indexing
6. Implement data encryption for sensitive information

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| **SRS** | Software Requirements Specification document |
| **Patient** | Individual receiving medical services |
| **Doctor** | Healthcare professional providing services |
| **Appointment** | Scheduled meeting between patient and doctor |
| **Medical Record** | Documentation of patient's medical history and treatment |
| **Prescription** | Doctor's recommendation for medication |
| **Clinic** | Healthcare facility where services are provided |
| **Hive** | Fast, embedded NoSQL database for Flutter apps |
| **Availability** | Doctor's working hours and schedule |
| **Queue** | Waiting list of patients |
| **Status** | Current state of appointment (scheduled, in-progress, etc.) |

---

## 14. Approval and Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Developed By** | Husnain Amin (FA22 BSE 004) | ________________ | Dec 17, 2025 |
| **Team Member** | Muhammad Ahmad (FA22 BSE 035) | ________________ | Dec 17, 2025 |
| **Submitted To** | Mam Sidra Tariq | ________________ | Dec 17, 2025 |

---

## 15. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 17, 2025 | Husnain Amin | Initial SRS document creation |

---

**End of Document**
