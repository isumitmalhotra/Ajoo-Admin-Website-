class SafetyDataModel {
  final bool success;
  final String message;
  final SafetyData safetyData;

  SafetyDataModel({
    required this.success,
    required this.message,
    required this.safetyData,
  });

  factory SafetyDataModel.fromJson(Map<String, dynamic> json) {
    return SafetyDataModel(
      success: json['success'],
      message: json['message'],
      safetyData: SafetyData.fromJson(json['data']['safetyData']),
    );
  }
}

class SafetyData {
  final Heading heading;
  final Content content;
  final String conclusion;

  SafetyData({
    required this.heading,
    required this.content,
    required this.conclusion,
  });

  factory SafetyData.fromJson(Map<String, dynamic> json) {
    return SafetyData(
      heading: Heading.fromJson(json['heading']),
      content: Content.fromJson(json['content']),
      conclusion: json['Conclusion'],
    );
  }
}

class Heading {
  final String title;
  final String description;

  Heading({
    required this.title,
    required this.description,
  });

  factory Heading.fromJson(Map<String, dynamic> json) {
    return Heading(
      title: json['title'],
      description: json['description'],
    );
  }
}

class Content {
  final Map<String, List<Map<String, String>>> sections;

  Content({required this.sections});

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      sections: json.map((key, value) => 
        MapEntry(key, List<Map<String, String>>.from(value.map((item) => Map<String, String>.from(item)))))
    );
  }
}
