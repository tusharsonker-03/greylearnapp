import 'dart:async';
import 'dart:convert';
import 'package:academy_app/providers/config.dart';
import 'package:academy_app/providers/notification_counter.dart';
import 'package:academy_app/screens/courses_screen.dart';
import 'package:academy_app/widgets/util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/link_navigator.dart';
import '../api/api_client.dart';
import 'package:academy_app/models/app_logo.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/config_data.dart';
import '../providers/shared_pref_helper.dart';
import '../screens/login_screen_new.dart';
import '../screens/notification_screen.dart';
import 'search_widget.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {

  ConfigData config;
  @override
  final Size preferredSize;

   CustomAppBar(this.config,{super.key})
      : preferredSize = const Size.fromHeight(50.0);

  @override
  // ignore: library_private_types_in_public_api
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final bool _isSearching = false;
  final _controller = StreamController<AppLogo>();
  final searchController = TextEditingController();

  fetchMyLogo() async {
    var url = '$BASE_URL/api/app_logo';
    try {
      final response = await ApiClient().get(url);
      if (response.statusCode == 200) {
        var logo = AppLogo.fromJson(jsonDecode(response.body));
        _controller.add(logo);
      }
      // print(extractedData);
    } catch (error) {
      rethrow;
    }
  }

  void _handleSubmitted(String value) {
    final searchText = searchController.text;
    if (searchText.isEmpty) {
      return;
    }

    searchController.clear();
    Navigator.of(context).pushNamed(
      CoursesScreen.routeName,
      arguments: {
        'category_id': null,
        'seacrh_query': searchText,
        'type': CoursesPageData.Search,
      },
    );
    // print(searchText);
  }

  void _showSearchModal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return const SearchWidget();
      },
    );
  }

  void _openWhatsApp(String contact) async{
    await openWhatsapp(contact);
  }


  @override
  void initState() {
    super.initState();
    fetchMyLogo();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0.0,
      automaticallyImplyLeading: false,
      actionsPadding:  EdgeInsets.zero,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: kSecondaryColor, //change your color here
      ),
      leading: StreamBuilder<AppLogo>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else {
            if (snapshot.error != null) {
              return const Text("Error Occured");
            } else {
              return Transform.scale(
                scale: 3.5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: CachedNetworkImage(
                    alignment: Alignment.center,
                    imageUrl: snapshot.data!.darkLogo.toString(),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }
          }
        },
      ),
      title: !_isSearching
          ? Container()
          : Card(
              color: Colors.white,
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Search Here',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                ),
                controller: searchController,
                onFieldSubmitted: _handleSubmitted,
              ),
            ),
      backgroundColor: Colors.white,
      actions: <Widget>[
        GestureDetector(
          onTap: () async {
            final token = await SharedPreferenceHelper().getAuthToken();
            LinkNavigator.instance.navigate(context,widget.config.hotstickerlink ?? "", widget.config.hotstickerlinktype ?? "", 0,widget.config.hotstickerauthentication ?? false, token ?? '','');
          },
          child: SizedBox(
            width: 80.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 2),
              child: CachedNetworkImage(
                alignment: Alignment.center,
                imageUrl: widget.config.hotsticker ?? "",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.message_sharp,
            color: kSecondaryColor,
          ),
          onPressed: () => _openWhatsApp("+917400171022"), //widget.config.msglink ?? ""
        ),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            IconButton(
              icon: const Icon(
                  Icons.notifications_none,
                color: kSecondaryColor,
              ),
              onPressed: () async{
                final token = await SharedPreferenceHelper().getAuthToken();
                if(token != null && token.isNotEmpty){
                  Navigator.pushNamedAndRemoveUntil(context, NotificationScreen.routeName, (r) => true);
                }else{
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreenNew()));
                }
              },
            ),
            Consumer<NotificationCounter>(
              builder: (context, state, child) {
                debugPrint("state.count.toString()");
                debugPrint(state.count.toString());
                return state.count > 0 ?
                Positioned(
                  top: 12.0,
                  right: 12.0,
                  width: 14.0,
                  height: 14.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Center(child: Text(state.count.toString(),style: TextStyle(fontSize: 8.0,color: Colors.white,fontWeight: FontWeight.bold),)),
                  ),
                ) : const SizedBox.shrink();
              },
            ),
            // Positioned(
            //   top: 12.0,
            //   right: 12.0,
            //   width: 14.0,
            //   height: 14.0,
            //   child: Container(
            //     decoration: const BoxDecoration(
            //       shape: BoxShape.circle,
            //       color: Colors.red,
            //     ),
            //     child: Center(child: Text("12",style: TextStyle(fontSize: 8.0,color: Colors.white,fontWeight: FontWeight.bold),)),
            //   ),
            // )
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.search,
            color: kSecondaryColor,
          ),
          onPressed: () => _showSearchModal(context),
        ),
      ],
    );
  }
}
