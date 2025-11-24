import 'package:academy_app/providers/auth.dart';
import 'package:academy_app/screens/downloaded_course_list.dart';
import 'package:academy_app/screens/edit_password_screen.dart';
import 'package:academy_app/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../screens/account_remove_screen.dart';
import './custom_text.dart';

class AccountListTile extends StatelessWidget {
  final String? titleText;
  final IconData? icon;
  final String? actionType;
  final String? courseAccessibility;

  const AccountListTile({
    super.key,
    @required this.titleText,
    @required this.icon,
    @required this.actionType,
    this.courseAccessibility,
  });


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                "No",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                // Perform logout
                if (courseAccessibility == 'publicly') {
                  Provider.of<Auth>(context, listen: false)
                      .logout()
                      .then((_) => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                        (r) => false,
                  ));
                } else {
                  Provider.of<Auth>(context, listen: false)
                      .logout()
                      .then((_) => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/auth-private',
                        (r) => false,
                  ));
                }
              },
              child: const Text(
                "Yes",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _actionHandler(BuildContext context) {
    if (actionType == 'logout') {
      _showLogoutDialog(context);

      // if (courseAccessibility == 'publicly') {
      //   Provider.of<Auth>(context, listen: false).logout().then((_) =>
      //       Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false));
      // } else {
      //   Provider.of<Auth>(context, listen: false).logout().then((_) =>
      //       Navigator.pushNamedAndRemoveUntil(
      //           context, '/auth-private', (r) => false));
      // }
    } else if (actionType == 'edit') {
      Navigator.of(context).pushNamed(EditProfileScreen.routeName);
    } else if (actionType == 'change_password') {
      Navigator.of(context).pushNamed(EditPasswordScreen.routeName);
    } else if (actionType == 'account_delete') {
      Navigator.of(context).pushNamed(AccountRemoveScreen.routeName);
    } else {
      Navigator.of(context).pushNamed(DownloadedCourseList.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: kPrimaryColor.withOpacity(0.7),
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FittedBox(
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: CustomText(
        text: titleText,
        colors: kTextColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: () => _actionHandler(context),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: iCardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
              child: ImageIcon(
                const AssetImage("assets/images/long_arrow_right.png"),
                color: kPrimaryColor.withOpacity(0.7),
                size: 25,
              ),
            ),
          ),
        ),
      ),
      // trailing: IconButton(
      //   icon: const Icon(Icons.arrow_forward_ios),
      //   onPressed: () => _actionHandler(context),
      //   color: Colors.grey,
      // ),
    );
  }
}
