// lib/services/college_data_service.dart
class CollegeDataService {
  // Basic information about United Institute of Technology
  static final Map<String, String> collegeInfo = {
    'name': 'United Institute of Technology',
    'location': 'Prayagraj, Uttar Pradesh, India',
    'established': '2007',
    'website': 'https://www.united.ac.in/uit/',
    'type': 'Private Engineering College',
    'affiliation': 'Dr. A.P.J. Abdul Kalam Technical University (AKTU)',
  };

  // Vision and mission
  static final Map<String, String> visionMission = {
    'vision': 'To be a value-based institution continuously striving for excellence in engineering education, research and entrepreneurship development, fostering habitude of skill development and multidimensional growth.',
    'mission1': 'To provide state-of-the-art infrastructure and conducive learning environment to analyze, investigate, design and develop solutions using engineering knowledge.',
    'mission2': 'To foster a habitude of skill development and entrepreneurship focused towards in-depth knowledge, leadership and multidimensional growth.',
    'mission3': 'To conduct impactful research, generate novel ideas and reach innovative solutions for addressing the needs of the society.',
    'mission4': 'To inculcate ethical values and social responsibility in thoughts, expressions and deeds, individually and also collectively.',
  };

  // Placement information
  static final Map<String, dynamic> placementInfo = {
    'placement_rate': '90%',
    'average_package': '5 LPA',
    'highest_package': '23.5 LPA',
    'major_recruiters': [
      'Infosys',
      'TCS',
      'Accenture',
      'Wipro',
      'Capgemini',
      'Tech Mahindra',
      'Jio'
    ],
    'cs_department_highest': '23.5 LPA (Walmart)',
  };

  // Computer Science Department information
  static final Map<String, dynamic> csDepartmentInfo = {
    'faculty_count': '60+',
    'labs': [
      'Machine Learning Lab',
      'Database Systems Lab',
      'Software Engineering Lab',
      'Computer Networks Lab',
      'Data Structures Lab',
      'Python Programming Lab',
      'Web Development Lab'
    ],
    'specializations': [
      'Artificial Intelligence & Machine Learning',
      'Data Science',
      'Cyber Security',
      'Cloud Computing',
      'Internet of Things (IoT)'
    ],
    'opportunities': [
      'Software Development',
      'Data Analysis',
      'System Administration',
      'Network Security',
      'Cloud Architecture',
      'Artificial Intelligence'
    ]
  };

  // Infrastructure information
  static final Map<String, dynamic> infrastructureInfo = {
    'campus_size': 'Spacious campus with modern facilities',
    'facilities': [
      'Air-conditioned classrooms',
      'State-of-the-art laboratories',
      'Well-equipped library',
      'Sports facilities',
      'Wi-Fi enabled campus',
      'Auditorium',
      'Cafeteria',
      'Hostel accommodation'
    ],
    'computing_facilities': '198 P4 computers across three labs'
  };

  // Generate a personalized response about UIT based on query keywords
  static String getPersonalizedResponse(String query) {
    query = query.toLowerCase();

    if (query.contains('placement') || query.contains('job') || query.contains('package')) {
      return _generatePlacementResponse();
    } else if (query.contains('computer') || query.contains('cs') || query.contains('cse')) {
      return _generateCSDepartmentResponse();
    } else if (query.contains('infrastructure') || query.contains('campus') || query.contains('facility')) {
      return _generateInfrastructureResponse();
    } else if (query.contains('vision') || query.contains('mission')) {
      return _generateVisionMissionResponse();
    } else if (query.contains('uit') || query.contains('united') || query.contains('college')) {
      return _generateGeneralCollegeResponse();
    }

    // Default response if no specific category matches
    return '';
  }

  // Generate responses for different categories
  static String _generatePlacementResponse() {
    return "United Institute of Technology has an excellent placement record with a ${placementInfo['placement_rate']} placement rate. "
        "The average package for students is around ${placementInfo['average_package']}, with the highest package reaching ${placementInfo['highest_package']}. "
        "Major recruiters include ${placementInfo['major_recruiters'].join(', ')}. "
        "The Computer Science department specifically has seen outstanding placements with roles in AI, ML, and Data Science.";
  }

  static String _generateCSDepartmentResponse() {
    return "The Computer Science Department at UIT is one of the strongest, with ${csDepartmentInfo['faculty_count']} experienced faculty members. "
        "The department offers specializations in ${csDepartmentInfo['specializations'].join(', ')}. "
        "Students have access to state-of-the-art labs including ${csDepartmentInfo['labs'].sublist(0, 3).join(', ')}, and more. "
        "Graduates from our CS department have secured excellent positions in leading companies, with career opportunities in ${csDepartmentInfo['opportunities'].sublist(0, 4).join(', ')}, among others.";
  }

  static String _generateInfrastructureResponse() {
    return "UIT boasts a ${infrastructureInfo['campus_size']} that provides an excellent learning environment. "
        "Our facilities include ${infrastructureInfo['facilities'].sublist(0, 5).join(', ')}, and more. "
        "The computing infrastructure includes ${infrastructureInfo['computing_facilities']} to support hands-on learning and practical applications.";
  }

  static String _generateVisionMissionResponse() {
    return "Vision: ${visionMission['vision']}\n\n"
        "Mission:\n"
        "1. ${visionMission['mission1']}\n"
        "2. ${visionMission['mission2']}\n"
        "3. ${visionMission['mission3']}\n"
        "4. ${visionMission['mission4']}";
  }

  static String _generateGeneralCollegeResponse() {
    return "${collegeInfo['name']} is a premier engineering institute located in ${collegeInfo['location']}. "
        "Established in ${collegeInfo['established']}, it is affiliated with ${collegeInfo['affiliation']}. "
        "The college is known for its excellent faculty, state-of-the-art infrastructure, and strong placement record. "
        "With a focus on holistic development, UIT prepares students not just for careers but for leadership roles in the technology sector.";
  }
}
