# Profile Update Feature

## Overview
The profile update feature allows users to modify their personal information and upload identity documents. This feature uses FormData to support file uploads and integrates with the existing authentication system.

## Files Modified/Created

### New Files:
- `lib/screens/Profile/update_profile_screen.dart` - Main profile update screen

### Modified Files:
- `lib/service/auth_service.dart` - Updated updateProfile method to use FormData
- `lib/controller/auth_controller.dart` - Enhanced error handling and success messages
- `lib/screens/profile_screen.dart` - Added "Edit Profile" menu option
- `lib/screens/Host/host_profile.dart` - Added "Edit Profile" card for hosts

## Features

### 1. Personal Information Update
- First Name and Last Name (separate fields)
- Phone Number
- Address (multi-line)
- City and Zipcode
- Form validation for required fields

### 2. Document Management
- **Document Type Selection**: Dropdown populated from CommonController
- **Document Number**: Text input for ID numbers
- **Document Upload**: Image picker for ID document photos
- **Current Document Display**: Shows existing document info if uploaded
- **Status Indicators**: Visual feedback for document status

### 3. User Experience
- **Loading States**: Shows progress during updates
- **Success/Error Messages**: Clear feedback via SnackBars
- **Form Validation**: Client-side validation before submission
- **Auto-populate**: Pre-fills form with existing user data
- **Document Preview**: Shows selected file name before upload

## Technical Implementation

### FormData Structure
The profile update uses FormData to handle mixed content (text + files):

```dart
FormData.fromMap({
  'user_fname': firstName,
  'user_lname': lastName,
  'user_pnumber': phoneNumber,
  'user_address': address,
  'user_city': city,
  'user_zipcode': zipcode,
  'doc_type': documentTypeId, // Optional
  'doc_number': documentNumber, // Optional
  'user_id_doc': MultipartFile, // Optional file upload
})
```

### Document Types Integration
- Fetches document types from `CommonController.docTypes`
- Maps document names to IDs for API submission
- Supports dynamic document type list from backend

### State Management
- Uses GetX for reactive state management
- Integrates with existing `AuthController`
- Auto-refreshes user data after successful update

## Navigation Integration

### User Profile (Guest/Customer)
- Added to settings menu as "Edit Profile" option
- Uses `Get.to()` navigation

### Host Profile
- Added as dedicated card section
- Positioned between KYC and Properties sections
- Maintains consistent UI design

## Error Handling
- Network errors with user-friendly messages
- Form validation errors
- File selection errors
- Server response errors

## Security Considerations
- File type validation (images only)
- Form data sanitization
- Token-based authentication
- Secure file upload via MultipartFile

## Usage

### For Users:
1. Navigate to Profile Screen
2. Tap "Edit Profile" in settings menu
3. Update desired fields
4. Optionally upload new document
5. Tap "Update Profile" button

### For Hosts:
1. Navigate to Host Profile Screen
2. Tap "Edit Profile" card
3. Follow same process as users

## Dependencies
- `image_picker`: For document photo selection
- `get`: State management and navigation
- `dio`: HTTP client with FormData support
- Existing app dependencies (constants, controllers, models)

## Future Enhancements
- Profile photo upload
- Document verification status tracking
- Bulk document upload
- Document expiry date tracking
- Advanced form validation rules
