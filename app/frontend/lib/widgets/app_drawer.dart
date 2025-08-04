import 'package:flutter/material.dart';
import 'package:testsdk/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final AuthService _authService = AuthService();

  AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber, Colors.purple],
              ),
            ),
            child: Text(
              'Sharpshooter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            text: 'Dashboard',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            text: 'History',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/page1');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            text: 'Stats',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/page2');
            },
          ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.post_add,
          //   text: 'Post',
          //   onTap: () {
          //     Navigator.pushReplacementNamed(context, '/post');
          //   },
          // ),
          _buildDrawerItem(
            context,
            icon: Icons.emoji_events,
            text: 'Daily Challenges',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/daily');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.exit_to_app,
            text: 'Logout',
            onTap: () async {
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.delete,
            text: 'Delete Account',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Account'),
                  content: Text('Are you sure you want to delete your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _authService.deleteUser();
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.purple[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
