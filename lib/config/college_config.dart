// lib/config/college_config.dart
// Configuration file for United Institute of Technology Prayagraj
// Update these values to customize KIRA's responses

class CollegeConfig {
  // Basic College Information
  static const String collegeName = "United Institute of Technology";
  static const String location = "Prayagraj (Allahabad), Uttar Pradesh, India";
  static const String established = "2007";
  static const String website = "https://www.united.ac.in/uit/";
  static const String phone = "0532-2402951-55";
  static const String email = "info@united.ac.in";
  static const String address = "D3, UPSIDC Industrial Area, Naini, Allahabad (Prayagraj) – 211010";
  static const String corporateOffice = "United Tower 53, Leader Road, Allahabad, U.P.";

  // AI Assistant Information
  static const String aiName = "KIRA";
  static const String aiDescription = "AI Assistant for United Institute of Technology Prayagraj";

  // Course Information - Update these as needed
  static const int totalCourses = 6;
  static const List<String> courses = [
    "Computer Science and Engineering (CSE)",
    "Electronics and Communication Engineering (ECE)",
    "Mechanical Engineering (ME)",
    "Civil Engineering (CE)",
    "Electrical Engineering (EE)",
    "AI & ML Engineering (Artificial Intelligence & Machine Learning)"
  ];

  // Intake Capacity - Update these numbers
  static const Map<String, String> intakeCapacity = {
    'CSE': 'varies by branch',
    'ECE': 'varies by branch',
    'EE': 'varies by branch',
    'ME': 'varies by branch',
    'CE': 'varies by branch',
    'AIML': 'varies by branch'
  };

  // Placement Information - Update these statistics
  static const String placementRate = "90%";
  static const String averagePackage = "5 LPA";
  static const String highestPackage = "23.5 LPA";
  static const String totalPlacements = "11400+ placements offered on campus";
  static const String totalAlumni = "14000+ alumni pan India";
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
    "Hostels",
    "State-of-the-art laboratories",
    "Well-equipped library",
    "Transport facilities",
    "Wi-Fi enabled campus",
    "Canteen",
    "Modern classrooms",
    "Computer labs"
  ];

  // Vision and Mission
  static const String vision = "To be a value-based institution continuously striving for excellence in engineering education, research and entrepreneurship development, fostering skill development and multidimensional growth.";
  
  static const List<String> mission = [
    "To provide state-of-the-art infrastructure and conducive learning environment to analyze, investigate, design and develop solutions using engineering knowledge.",
    "To foster skill development and entrepreneurship focused towards in-depth knowledge, leadership and multidimensional growth.",
    "To conduct impactful research, generate novel ideas and reach innovative solutions for addressing the needs of the society.",
    "To inculcate ethical values and social responsibility in thoughts, expressions and deeds, individually and also collectively."
  ];

  // Specializations by Department
  static const Map<String, List<String>> specializations = {
    'CSE': ['AI & ML', 'Data Science', 'Cyber Security', 'Cloud Computing', 'IoT'],
    'ECE': ['VLSI Design', 'Communication Systems', 'Signal Processing'],
    'EE': ['Power Systems', 'Control Systems', 'Renewable Energy'],
    'ME': ['Automobile Engineering', 'Robotics', 'Manufacturing'],
    'CE': ['Structural Engineering', 'Transportation', 'Environmental Engineering'],
    'AIML': ['Machine Learning', 'Deep Learning', 'Natural Language Processing', 'Computer Vision']
  };

  // Faculty Information
  static const String csFacultyCount = "60+";
  static const String cseHod = "Dr. Amit Kumar Tiwari";
  static const List<String> csLabs = [
    "Machine Learning Lab",
    "Database Systems Lab",
    "Software Engineering Lab",
    "Computer Networks Lab",
    "Data Structures Lab",
    "Python Programming Lab",
    "Web Development Lab"
  ];
  
  // Fee Information
  static const Map<String, String> feeInfo = {
    'btech_4year': '₹ 5.09 Lakhs - ₹ 5.65 Lakhs (total tuition fee for entire duration)',
    'btech_lateral': 'varies by specialization',
    'mtech': '₹ 2.17 Lakhs (total fee for two years)'
  };
  
  // Academic Programs
  static const List<String> academicPrograms = [
    'B.Tech (4-year)',
    'B.Tech (Lateral Entry)',
    'M.Tech (Postgraduate)'
  ];
  
  // Affiliation and Approval
  static const String approval = "All India Council for Technical Education (AICTE)";
  static const String affiliation = "Dr. A.P.J. Abdul Kalam Technical University (AKTU), Lucknow";

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
