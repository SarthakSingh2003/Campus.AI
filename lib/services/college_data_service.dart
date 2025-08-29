// lib/services/college_data_service.dart
import 'package:kira_college_ai/config/college_config.dart';

class CollegeDataService {
  // Basic information about United Institute of Technology
  static final Map<String, String> collegeInfo = {
    'name': CollegeConfig.collegeName,
    'location': CollegeConfig.location,
    'established': CollegeConfig.established,
    'website': CollegeConfig.website,
    'type': 'Private Engineering College',
    'affiliation': 'Dr. A.P.J. Abdul Kalam Technical University (AKTU)',
    'address': CollegeConfig.address,
    'phone': CollegeConfig.phone,
    'email': CollegeConfig.email,
  };

  // Vision and mission
  static final Map<String, String> visionMission = {
    'vision': CollegeConfig.vision,
    'mission1': CollegeConfig.mission[0],
    'mission2': CollegeConfig.mission[1],
    'mission3': CollegeConfig.mission[2],
    'mission4': CollegeConfig.mission[3],
  };

  // Placement information
  static final Map<String, dynamic> placementInfo = {
    'placement_rate': CollegeConfig.placementRate,
    'average_package': CollegeConfig.averagePackage,
    'highest_package': CollegeConfig.highestPackage,
    'major_recruiters': CollegeConfig.majorRecruiters,
    'cs_department_highest': '${CollegeConfig.highestPackage} (Walmart)',
  };

  // Computer Science Department information
  static final Map<String, dynamic> csDepartmentInfo = {
    'faculty_count': CollegeConfig.csFacultyCount,
    'labs': CollegeConfig.csLabs,
    'specializations': CollegeConfig.specializations['CSE']!,
    'opportunities': [
      'Software Development',
      'Data Analysis',
      'System Administration',
      'Network Security',
      'Cloud Architecture',
      'Artificial Intelligence'
    ]
  };

  // Course information
  static final Map<String, dynamic> courseInfo = {
    'total_courses': CollegeConfig.totalCourses.toString(),
    'undergraduate_courses': CollegeConfig.courses,
    'duration': '4 years (8 semesters)',
    'intake_capacity': CollegeConfig.intakeCapacity,
    'specializations': CollegeConfig.specializations
  };

  // Infrastructure information
  static final Map<String, dynamic> infrastructureInfo = {
    'campus_size': CollegeConfig.quickFacts['Campus Size']!,
    'facilities': CollegeConfig.facilities,
    'computing_facilities': CollegeConfig.quickFacts['Computing Facilities']!
  };

  // Generate a personalized response about UIT based on query keywords
  static String getPersonalizedResponse(String query) {
    query = query.toLowerCase();

    if (query.contains('placement') || query.contains('job') || query.contains('package')) {
      return _generatePlacementResponse();
    } else if (query.contains('computer') || query.contains('cs') || query.contains('cse')) {
      return _generateCSDepartmentResponse();
    } else if (query.contains('course') || query.contains('branch') || query.contains('department') || query.contains('program')) {
      return _generateCourseResponse();
    } else if (query.contains('infrastructure') || query.contains('campus') || query.contains('facility')) {
      return _generateInfrastructureResponse();
    } else if (query.contains('vision') || query.contains('mission')) {
      return _generateVisionMissionResponse();
    } else if (query.contains('contact') || query.contains('phone') || query.contains('email') || query.contains('address')) {
      return _generateContactResponse();
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

  static String _generateCourseResponse() {
    return "UIT offers ${courseInfo['total_courses']} undergraduate engineering programs with a duration of ${courseInfo['duration']}. "
        "Our courses include: ${courseInfo['undergraduate_courses'].join(', ')}. "
        "The Computer Science department has the highest intake with ${courseInfo['intake_capacity']['CSE']}, "
        "followed by other departments with ${courseInfo['intake_capacity']['IT']} each. "
        "Each department offers specialized tracks - for example, CSE students can specialize in ${courseInfo['specializations']['CSE'].join(', ')}. "
        "All programs are designed to provide hands-on experience and industry-relevant skills.";
  }

  static String _generateContactResponse() {
    return "You can contact United Institute of Technology at: "
        "Phone: ${collegeInfo['phone']}, "
        "Email: ${collegeInfo['email']}, "
        "Address: ${collegeInfo['address']}. "
        "For more information, visit our website: ${collegeInfo['website']}";
  }

  static String _generateGeneralCollegeResponse() {
    return "${collegeInfo['name']} is a premier engineering institute located in ${collegeInfo['location']}. "
        "Established in ${collegeInfo['established']}, it is affiliated with ${collegeInfo['affiliation']}. "
        "The college is known for its excellent faculty, state-of-the-art infrastructure, and strong placement record. "
        "With a focus on holistic development, UIT prepares students not just for careers but for leadership roles in the technology sector.";
  }
}
