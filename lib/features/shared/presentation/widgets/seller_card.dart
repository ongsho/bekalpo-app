import 'package:flutter/material.dart';

class SellerCard extends StatelessWidget {
  final String name;
  final String location;

  const SellerCard({super.key, required this.name, required this.location});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.store),
        title: Text(name),
        subtitle: Text(location),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // later: navigate to seller profile
        },
      ),
    );
  }
}
