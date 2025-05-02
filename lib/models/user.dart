class User {
  final int? userId;
  final String name;
  final String password;
  final String email;
  final String? gender;
  final String? dateOfBirth;
  final String dateJoined;
  final String userType;

  User({
    this.userId,
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
      'User_ID': userId,
      'Name': name,
      'Password': password,
      'Email': email,
      'Gender': gender,
      'DateOfBirth': dateOfBirth,
      'DateJoined': dateJoined,
      'UserType': userType,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['User_ID'],
      name: map['Name'],
      password: map['Password'],
      email: map['Email'],
      gender: map['Gender'],
      dateOfBirth: map['DateOfBirth'],
      dateJoined: map['DateJoined'],
      userType: map['UserType'],
    );
  }
}
