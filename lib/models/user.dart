class User {
  final int? id;
  final String name;
  final String password;
  final String email;
  final String? gender;
  final DateTime? dateOfBirth;
  final DateTime dateJoined;
  final String userType;

  User({
    this.id,
    required this.name,
    required this.password,
    required this.email,
    this.gender,
    this.dateOfBirth,
    required this.dateJoined,
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'User_ID': id,
      'Name': name,
      'Password': password,
      'Email': email,
      'Gender': gender,
      'DateOfBirth': dateOfBirth?.toIso8601String(),
      'DateJoined': dateJoined.toIso8601String(),
      'UserType': userType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['User_ID'],
      name: map['Name'],
      password: map['Password'],
      email: map['Email'],
      gender: map['Gender'],
      dateOfBirth:
          map['DateOfBirth'] != null
              ? DateTime.parse(map['DateOfBirth'])
              : null,
      dateJoined: DateTime.parse(map['DateJoined']),
      userType: map['UserType'],
    );
  }
}
