# Doctor Assistant App
<img width="250" height="600" alt="Screenshot_20251024-074501" src="https://github.com/user-attachments/assets/1193c516-6ed9-462a-96e2-6a72c2ee9557" />
<img width="250" height="600" alt="Screenshot_20251024-074620" src="https://github.com/user-attachments/assets/e36f62dd-c287-49d2-8236-61494778e6b5" />
<img width="250" height="600" alt="Screenshot_20251024-074448" src="https://github.com/user-attachments/assets/7cd0b1d2-51db-4234-807b-51f939c9eb5d" />
<img width="250" height="600" alt="Screenshot_20251024-074457" src="https://github.com/user-attachments/assets/c6c99547-d7a3-497d-bb03-73a7ae16b4a4" />
<img width="250" height="600" alt="Screenshot_20251024-074538" src="https://github.com/user-attachments/assets/628a8af9-ce5e-4cad-9b7d-8b48ca776f16" />
<img width="250" height="600" alt="Screenshot_20251024-074611" src="https://github.com/user-attachments/assets/8c540123-0b09-409d-b3d3-d6f819b93626" />











A Flutter application for doctors to manage patient details, including personal info, reports, and appointments.

## Features

- Patient Info Card with personal details
- Edit and delete patient records
- Attach reports via camera or gallery
- View attached reports in a grid layout
- Local storage using Hive

## Dependencies

- `image_picker` - For capturing images from camera or gallery
- `path_provider` - For accessing device storage
- `hive` and `hive_flutter` - For local data persistence
- `flutter_staggered_grid_view` - For grid layout of reports

## Setup Instructions

1. Enable Developer Mode on Windows:
   - Press `Windows key + I` to open Settings
   - Go to "Update & Security" > "For developers"
   - Turn on "Developer mode"

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart` - Entry point of the application
- `lib/screens/patient_details_screen.dart` - Main screen for patient details
- `lib/models/patient.dart` - Patient data model
- `lib/models/report.dart` - Report data model
- `lib/services/local_storage_service.dart` - Local storage service using Hive

## How to Use

1. The app opens directly to the Patient Details screen
2. Patient information is displayed in a card at the top
3. Use the "Edit" button to modify patient details
4. Use the "Delete" button to remove the patient record
5. Tap the floating action button (camera icon) to add reports:
   - Choose "Use Camera" to take a new photo
   - Choose "From Gallery" to select an existing image
6. Reports are displayed in a grid layout below patient info
7. Tap on any report to view it in full screen
8. Tap the delete icon on a report to remove it

## Color Scheme

- Primary color: Blue (#137fec)
- Background: White
- Cards: Rounded with shadow effect
