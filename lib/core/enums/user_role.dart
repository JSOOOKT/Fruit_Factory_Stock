enum UserRole {
  recorder,
  manager,
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.recorder:
        return 'recorder';
      case UserRole.manager:
        return 'manager';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.recorder:
        return 'พนักงานบันทึกข้อมูล';
      case UserRole.manager:
        return 'ผู้จัดการ';
      case UserRole.admin:
        return 'ผู้ดูแลระบบ';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UserRole.recorder:
        return 'Recorder';
      case UserRole.manager:
        return 'Manager';
      case UserRole.admin:
        return 'Admin';
    }
  }

  bool get isRecorder => this == UserRole.recorder;
  bool get isManager => this == UserRole.manager || isAdmin;
  bool get isAdmin => this == UserRole.admin;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => UserRole.recorder,
    );
  }
}
