# KIRA - College AI Assistant Customization Guide

## Overview
KIRA is an AI assistant specifically designed for United Institute of Technology Prayagraj. This guide explains how to customize the college-specific information that KIRA provides to users.

## Quick Customization
To update college information, edit the file: `lib/config/college_config.dart`

## What You Can Customize

### 1. Basic College Information
```dart
static const String collegeName = "United Institute of Technology";
static const String location = "Prayagraj, Uttar Pradesh, India";
static const String established = "2007";
static const String website = "https://www.united.ac.in/uit/";
static const String phone = "+91-532-2684281";
static const String email = "info@united.ac.in";
```

### 2. Course Information
Update the list of courses offered:
```dart
static const List<String> courses = [
  "Computer Science and Engineering (CSE)",
  "Information Technology (IT)",
  // Add or remove courses as needed
];
```

### 3. Intake Capacity
Update student intake for each department:
```dart
static const Map<String, String> intakeCapacity = {
  'CSE': '120 students',
  'IT': '60 students',
  // Update numbers as needed
};
```

### 4. Placement Information
Update placement statistics:
```dart
static const String placementRate = "90%";
static const String averagePackage = "5 LPA";
static const String highestPackage = "23.5 LPA";
static const List<String> majorRecruiters = [
  "Infosys",
  "TCS",
  // Add or remove companies
];
```

### 5. Infrastructure & Facilities
Update campus facilities:
```dart
static const List<String> facilities = [
  "Air-conditioned classrooms",
  "State-of-the-art laboratories",
  // Add or remove facilities
];
```

### 6. Specializations
Update department specializations:
```dart
static const Map<String, List<String>> specializations = {
  'CSE': ['AI & ML', 'Data Science', 'Cyber Security'],
  'IT': ['Software Engineering', 'Web Development'],
  // Update for each department
};
```

## How KIRA Responds

KIRA automatically detects user queries and provides relevant information:

- **Course queries**: "What courses do you offer?" → Lists all courses with intake capacity
- **Placement queries**: "What are the placement statistics?" → Provides placement rates and packages
- **Infrastructure queries**: "What facilities do you have?" → Lists campus facilities
- **Contact queries**: "How can I contact the college?" → Provides contact information
- **General queries**: "Tell me about the college" → Provides overview and vision/mission

## Example User Queries KIRA Can Answer

1. "How many courses does UIT offer?"
2. "What is the placement rate?"
3. "What are the specializations in CSE?"
4. "What facilities are available on campus?"
5. "How can I contact the college?"
6. "What is the highest package offered?"
7. "Tell me about the Computer Science department"
8. "What is the vision of the college?"

## AI Personality
KIRA introduces herself as: "Hi! I'm KIRA, your AI assistant for United Institute of Technology Prayagraj."

## Technical Details
- The AI uses Google's Gemini model for natural language processing
- College-specific responses are handled by `CollegeDataService`
- Configuration is centralized in `lib/config/college_config.dart`
- The app supports multiple languages including Hindi

## Updating Information
1. Open `lib/config/college_config.dart`
2. Modify the relevant constants
3. Save the file
4. Rebuild the app: `flutter run`

## Support
For technical support or questions about customization, refer to the main project documentation.
