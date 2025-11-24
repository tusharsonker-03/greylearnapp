/// ------------------------------OLD CODE-----------------------------------------////////////
//
// import 'dart:convert';
// import 'package:academy_app/constants.dart';
// import 'package:academy_app/screens/webview_screen.dart';
// import 'package:academy_app/widgets/app_bar.dart';
// import 'package:academy_app/widgets/filter_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/config_data.dart';
// import '../providers/auth.dart';
// import '../providers/config.dart';
// import '../providers/shared_pref_helper.dart';
// import 'account_screen.dart';
// import 'home_screen.dart';
// import 'job_web_view.dart';
// import 'login_screen.dart';
// import 'my_wishlist_screen.dart';
// import 'my_courses_screen.dart';
//
// class TabsScreen extends StatefulWidget {
//   static const routeName = '/home';
//   int index;
//   TabsScreen({super.key,required this.index});
//
//   @override
//   State<TabsScreen> createState() => _TabsScreenState();
// }
//
// class _TabsScreenState extends State<TabsScreen> {
//   List<Widget> _pages = [
//     const HomeScreen(),
//     const LoginScreen(),
//     const LoginScreen(),
//     const LoginScreen(),
//   ];
//
//   var _isInit = true;
//   late Widget _homeScreenStable;
//   bool _justLoggedIn = false;
//
//
//   int _selectedPageIndex = 0;
//   ConfigData configData = ConfigData();
//
//   @override
//   void initState(){
//
//     super.initState();
//     _homeScreenStable = HomeScreen(key: UniqueKey()); // Stable, no rebuild
//
//     _selectPage(widget.index );
//     Provider.of<Auth>(context, listen: false).updateFCMData();
//     configData = Provider.of<Config>(context, listen: false).configItems;
//     getConfigData();
//     debugPrint(_selectedPageIndex.toString());
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<Auth>().hydrateFromPrefs();
//     });
//   }
//
//   Future<void> getConfigData() async {
//     dynamic data = await SharedPreferenceHelper().getConfigData();
//
//     if (data != null) {
//       setState(() {
//         configData = ConfigData.fromJson(json.decode(data));
//       });
//     }
//   }
//   setData() async{
//     if(configData.appname?.isNotEmpty ?? false) {
//       await SharedPreferenceHelper().setConfigData(json.encode(configData));
//     }
//
//     getConfigData();
//   }
//
//   @override
//   void didChangeDependencies() async {
//     if (_isInit) {
//       bool isAuth = false;
//
//       final t = await SharedPreferenceHelper().getAuthToken();
//       debugPrint('🧩 [Tabs] authToken(from helper) = ${t ?? "(null)"}');
//       isAuth = t != null && t.isNotEmpty;
//
//       if (mounted) {
//         setState(() {
//           _pages = isAuth
//               ? [
//             _homeScreenStable, // 👈 fixed, NO rebuild
//             MyCoursesScreen(),
//             JobWebViewScreen(
//               url: configData.jobs?.link ?? "https://greylearn.com/placements",
//             ),
//             AccountScreen(),
//           ]
//               : [
//             _homeScreenStable, // 👈 fixed, NO rebuild
//             LoginScreen(),
//             LoginScreen(),
//             LoginScreen(),
//           ];
//           if (isAuth) {
//             _justLoggedIn = true;   // ⭐ LOGIN DETECTED
//           }
//         });
//       }
//       _isInit = false;
//     }
//
//     // ✅ Add this small block — it forces refresh of HomeScreen right after login
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_selectedPageIndex == 0) {
//         setState(() {
//           _pages[0] = _homeScreenStable; // 🔁 Force rebuild of Home
//         });
//         _justLoggedIn = false;  // ⭐ Do not repeat → NO flicker
//
//       }
//     });
//
//     super.didChangeDependencies();
//   }
//
//
//
//   // void didChangeDependencies() async {
//   //   if (_isInit) {
//   //     bool isAuth;
//   //     dynamic userData;
//   //     dynamic response;
//   //     dynamic token;
//   //     // var token = await SharedPreferenceHelper().getAuthToken();
//   //     // setState(() {});
//   //     // if (token != null && token.isNotEmpty) {
//   //     //   _isAuth = true;
//   //     // } else {
//   //     //   _isAuth = false;
//   //     // }
//   //
//   //     // _isAuth = Provider.of<Auth>(context, listen: false).isAuth;
//   //
//   //     final prefs = await SharedPreferences.getInstance();
//   //     userData = (prefs.getString('userData') ?? '');
//   //     if (userData != null && userData.isNotEmpty) {
//   //       response = json.decode(userData);
//   //       token = response['token'];
//   //     }
//   //     isAuth = token != null && token.isNotEmpty;
//   //
//   //     // ⬇️ setState se pages update kar do taa ki UI turant rebuild ho
//   //     if (mounted) {
//   //       setState(() {
//   //         _pages = isAuth
//   //             ? [
//   //           const HomeScreen(),
//   //           const MyCoursesScreen(),
//   //           const WebViewScreen(url: "https://greylearn.com/placements"),
//   //           const AccountScreen(),
//   //         ]
//   //             : [
//   //           const HomeScreen(),
//   //           const LoginScreen(),
//   //           const LoginScreen(),
//   //           const LoginScreen(),
//   //         ];
//   //       });
//   //     }
//   //     _isInit = false;
//   //   }
//   //   super.didChangeDependencies();
//   // }
//
//   void _selectPage(int index) => setState(() => _selectedPageIndex = index);
//
//   // ✅ BACK handling
//   Future<bool> _onWillPop() async {
//     // 1) agar Home tab pe nahi ho, toh pehle Home tab dikhado
//     if (_selectedPageIndex != 0) {
//       setState(() => _selectedPageIndex = 0);
//       return false; // app exit nahi hogi
//     }
//     // 2) already Home par ho -> ab system ko exit karne do
//     return true;
//   }
//
//   void _showFilterModal(BuildContext ctx) {
//     showModalBottomSheet(
//       context: ctx,
//       isScrollControlled: true,
//       builder: (_) {
//         return const FilterWidget();
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(onWillPop: _onWillPop,child:  Scaffold(
//       backgroundColor: kBackgroundColor,
//       appBar:  CustomAppBar(configData),
//       body: _pages[_selectedPageIndex],
//       // filter code commented
//       floatingActionButton: _selectedPageIndex != 3 ? FloatingActionButton(
//         onPressed: () => _showFilterModal(context),
//         backgroundColor: kDarkButtonBg,
//         child: const Icon(Icons.filter_list),
//       ) : null,
//       // floatingActionButton: FloatingActionButton(
//       //     onPressed: _join,
//       //   child: const Icon(Icons.add_ic_call),
//       // ),
//       bottomNavigationBar: BottomNavigationBar(
//         onTap: _selectPage,
//         items: const [
//           BottomNavigationBarItem(
//             backgroundColor: kBackgroundColor,
//             icon: Icon(Icons.home_outlined),
//             activeIcon: Icon(Icons.home_outlined,color: kPrimaryColor),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             backgroundColor: kBackgroundColor,
//             icon: Icon(Icons.my_library_books_sharp),
//             activeIcon: Icon(Icons.my_library_books_sharp,color: kPrimaryColor),
//             label: 'My Course',
//           ),
//           BottomNavigationBarItem(
//             backgroundColor: kBackgroundColor,
//             icon: Icon(Icons.wallet_travel_sharp),
//             activeIcon: Icon(Icons.wallet_travel_sharp,color: kPrimaryColor),
//             label: 'Jobs',
//           ),
//           BottomNavigationBarItem(
//             backgroundColor: kBackgroundColor,
//             icon: Icon(Icons.account_circle_outlined),
//             activeIcon: Icon(Icons.account_circle_outlined,color: kPrimaryColor,),
//             label: 'Account',
//           ),
//         ],
//         backgroundColor: Colors.white,
//         unselectedItemColor: kSecondaryColor,
//         selectedItemColor: kSelectItemColor,
//         currentIndex: _selectedPageIndex,
//         type: BottomNavigationBarType.fixed,
//       ),
//     ) );
//   }
//
// }
//
































import 'dart:convert';
import 'package:academy_app/constants.dart';
import 'package:academy_app/screens/webview_screen.dart';
import 'package:academy_app/widgets/app_bar.dart';
import 'package:academy_app/widgets/filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/config_data.dart';
import '../providers/auth.dart';
import '../providers/config.dart';
import '../providers/shared_pref_helper.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'job_web_view.dart';
import 'login_screen.dart';
import 'my_wishlist_screen.dart';
import 'my_courses_screen.dart';

class TabsScreen extends StatefulWidget {
  static const routeName = '/home';
  int index;
  TabsScreen({super.key, required this.index});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {

  late final HomeScreen _homeScreen; // fixed instance
  ConfigData configData = ConfigData();
  List<Widget> _pages = [];
  int _selectedPageIndex = 0;

  // @override
  // void initState() {
  //   super.initState();
  //   Provider.of<Auth>(context, listen: false).updateFCMData();
  //
  //   _homeScreen = const HomeScreen();  // only once
  //   configData = Provider.of<Config>(context, listen: false).configItems;
  //
  //   _selectPage(widget.index);
  // }



    @override
  void initState(){

    super.initState();
      _homeScreen = const HomeScreen();  // only once

    _selectPage(widget.index );
    Provider.of<Auth>(context, listen: false).updateFCMData();
    configData = Provider.of<Config>(context, listen: false).configItems;
    debugPrint(_selectedPageIndex.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<Auth>().hydrateFromPrefs();
    });
  }

  @override
  void didChangeDependencies() async {
    bool isAuth = false;
    final token = await SharedPreferenceHelper().getAuthToken();
    isAuth = token != null && token.isNotEmpty;

    setState(() {
      _pages = isAuth
          ? [
        _homeScreen,         // ← never recreated
        MyCoursesScreen(),
        JobWebViewScreen(
            url: configData.jobs?.link ??
                "https://greylearn.com/placements"),
        AccountScreen(),
      ]
          : [
        _homeScreen,         // ← never recreated
        LoginScreen(),
        LoginScreen(),
        LoginScreen(),
      ];
    });

    super.didChangeDependencies();
  }

    void _showFilterModal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return const FilterWidget();
      },
    );
  }
  void _selectPage(int index) => setState(() => _selectedPageIndex = index);

    Future<bool> _onWillPop() async {
    // 1) agar Home tab pe nahi ho, toh pehle Home tab dikhado
    if (_selectedPageIndex != 0) {
      setState(() => _selectedPageIndex = 0);
      return false; // app exit nahi hogi
    }
    // 2) already Home par ho -> ab system ko exit karne do
    return true;
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: _onWillPop,child:  Scaffold(
      backgroundColor: kBackgroundColor,
      appBar:  CustomAppBar(configData),
      body: _pages[_selectedPageIndex],
      // filter code commented
      floatingActionButton: _selectedPageIndex != 3 ? FloatingActionButton(
        onPressed: () => _showFilterModal(context),
        backgroundColor: kDarkButtonBg,
        child: const Icon(Icons.filter_list),
      ) : null,
      // floatingActionButton: FloatingActionButton(
      //     onPressed: _join,
      //   child: const Icon(Icons.add_ic_call),
      // ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectPage,
        items: const [
          BottomNavigationBarItem(
            backgroundColor: kBackgroundColor,
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_outlined,color: kPrimaryColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            backgroundColor: kBackgroundColor,
            icon: Icon(Icons.my_library_books_sharp),
            activeIcon: Icon(Icons.my_library_books_sharp,color: kPrimaryColor),
            label: 'My Course',
          ),
          BottomNavigationBarItem(
            backgroundColor: kBackgroundColor,
            icon: Icon(Icons.wallet_travel_sharp),
            activeIcon: Icon(Icons.wallet_travel_sharp,color: kPrimaryColor),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            backgroundColor: kBackgroundColor,
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_outlined,color: kPrimaryColor,),
            label: 'Account',
          ),
        ],
        backgroundColor: Colors.white,
        unselectedItemColor: kSecondaryColor,
        selectedItemColor: kSelectItemColor,
        currentIndex: _selectedPageIndex,
        type: BottomNavigationBarType.fixed,
      ),
    ) );
  }
}
