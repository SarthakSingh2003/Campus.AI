// lib/config/college_config.dart
// Configuration file for United Institute of Technology Prayagraj
// Update these values to customize KIRA's responses

class CollegeConfig {
  // Basic College Information
  static const String collegeName = "United Institute of Technology";
  static const String location = "Prayagraj, Uttar Pradesh, India";
  static const String established = "2007";
  static const String website = "https://www.united.ac.in/uit/";
  static const String phone = "+91-532-2684281";
  static const String email = "info@united.ac.in";
  static const String address = "Prayagraj, Uttar Pradesh, India";

  // AI Assistant Information
  static const String aiName = "KIRA";
  static const String aiDescription = "AI Assistant for United Institute of Technology Prayagraj";

  // Course Information - Update these as needed
  static const int totalCourses = 8;
  static const List<String> courses = [
    "Computer Science and Engineering (CSE)",
    "Information Technology (IT)",
    "Electronics and Communication Engineering (ECE)",
    "Electrical Engineering (EE)",
    "Mechanical Engineering (ME)",
    "Civil Engineering (CE)",
    "Chemical Engineering (CHE)",
    "Biotechnology (BT)"
  ];

  // Intake Capacity - Update these numbers
  static const Map<String, String> intakeCapacity = {
    'CSE': '120 students',
    'IT': '60 students',
    'ECE': '60 students',
    'EE': '60 students',
    'ME': '60 students',
    'CE': '60 students',
    'CHE': '30 students',
    'BT': '30 students'
  };

  // Placement Information - Update these statistics
  static const String placementRate = "90%";
  static const String averagePackage = "5 LPA";
  static const String highestPackage = "23.5 LPA";
  static const List<String> majorRecruiters = [
    "Infosys",
    "TCS",
    "Accenture",
    "Wipro",
    "Capgemini",
    "Tech Mahindra",
    "Jio"
  ];

  // Infrastructure Information
  static const List<String> facilities = [
    "Air-conditioned classrooms",
    "State-of-the-art laboratories",
    "Well-equipped library",
    "Sports facilities",
    "Wi-Fi enabled campus",
    "Auditorium",
    "Cafeteria",
    "Hostel accommodation"
  ];

  // Vision and Mission
  static const String vision = "To be a value-based institution continuously striving for excellence in engineering education, research and entrepreneurship development, fostering habitude of skill development and multidimensional growth.";
  
  static const List<String> mission = [
    "To provide state-of-the-art infrastructure and conducive learning environment to analyze, investigate, design and develop solutions using engineering knowledge.",
    "To foster a habitude of skill development and entrepreneurship focused towards in-depth knowledge, leadership and multidimensional growth.",
    "To conduct impactful research, generate novel ideas and reach innovative solutions for addressing the needs of the society.",
    "To inculcate ethical values and social responsibility in thoughts, expressions and deeds, individually and also collectively."
  ];

  // Specializations by Department
  static const Map<String, List<String>> specializations = {
    'CSE': ['AI & ML', 'Data Science', 'Cyber Security', 'Cloud Computing', 'IoT'],
    'IT': ['Software Engineering', 'Web Development', 'Mobile App Development'],
    'ECE': ['VLSI Design', 'Communication Systems', 'Signal Processing'],
    'EE': ['Power Systems', 'Control Systems', 'Renewable Energy'],
    'ME': ['Automobile Engineering', 'Robotics', 'Manufacturing'],
    'CE': ['Structural Engineering', 'Transportation', 'Environmental Engineering'],
    'CHE': ['Process Design', 'Petroleum Technology'],
    'BT': ['Biomedical Engineering', 'Pharmaceutical Technology']
  };

  // Faculty Information
  static const String csFacultyCount = "60+";
  static const List<String> csLabs = [
    "Machine Learning Lab",
    "Database Systems Lab",
    "Software Engineering Lab",
    "Computer Networks Lab",
    "Data Structures Lab",
    "Python Programming Lab",
    "Web Development Lab"
  ];

  // Quick Facts
  static const Map<String, String> quickFacts = {
    "Campus Size": "Spacious campus with modern facilities",
    "Computing Facilities": "198 P4 computers across three labs",
    "Library": "Well-equipped with latest books and journals",
    "Sports": "Multiple sports facilities available",
    "Hostel": "Separate hostels for boys and girls",
    "Transportation": "Bus facilities available",
    "Medical": "On-campus medical facilities",
    "Cafeteria": "Modern cafeteria with variety of food options"
  };
}
