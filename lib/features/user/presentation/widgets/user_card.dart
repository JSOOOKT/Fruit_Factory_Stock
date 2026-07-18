import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;

  const UserCard({
    super.key,
    required this.name,
    required this.role,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
        ),
        title: Text(name),
        subtitle: Text('$email • $role'),
      ),
    );
  }
}