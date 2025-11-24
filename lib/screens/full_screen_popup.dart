// ignore_for_file: use_build_context_synchronously

import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/models/update_user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../models/config_data.dart';
import 'auth_screen.dart';

class FullScreenPopup extends StatefulWidget {
  static const routeName = '/fullscreen_subscription_popup';
  final Subscription subscription;
  FullScreenPopup(this.subscription, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FullScreenPopupState createState() => _FullScreenPopupState();
}
class _FullScreenPopupState extends State<FullScreenPopup> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  var _isLoading = false;
  var popupcontent = "";
  // var text = "";

  @override
  void initState() {
    var unescape = new HtmlUnescape();
    // text = unescape.convert("&lt;h2 style=&quot;margin-top:0;color:#111&quot;&gt;You get access to&lt;/h2&gt;&lt;ul style=&quot;list-style:none;padding-left:0;margin:0&quot;&gt;&lt;li style=&quot;margin-bottom:10px&quot;&gt;&lt;span style=&quot;color:teal;font-weight:700&quot;&gt;✔&lt;/span&gt;Unlimited Certificate Courses&lt;/li&gt;&lt;li style=&quot;margin-bottom:10px&quot;&gt;&lt;span style=&quot;color:teal;font-weight:700&quot;&gt;✔&lt;/span&gt;Unlimited Webinars&lt;/li&gt;&lt;li style=&quot;margin-bottom:10px&quot;&gt;&lt;span style=&quot;color:teal;font-weight:700&quot;&gt;✔&lt;/span&gt;Unlimited Mentorships&lt;/li&gt;&lt;li style=&quot;margin-bottom:10px&quot;&gt;&lt;span style=&quot;color:teal;font-weight:700&quot;&gt;✔&lt;/span&gt;Free Career Navigator&lt;/li&gt;&lt;li style=&quot;margin-bottom:10px&quot;&gt;&lt;span style=&quot;color:teal;font-weight:700&quot;&gt;✔&lt;/span&gt;Job &amp; Internship Alerts First&lt;/li&gt;&lt;li style=&quot;margin-bottom:10px&quot;&gt;&lt;span style=&quot;color:teal;font-weight:700&quot;&gt;✔&lt;/span&gt;Resume Review by Industry Recruiter&lt;/li&gt;&lt;/ul&gt;&lt;p style=&quot;margin-top:20px;background-color:#ff0;padding:10px;border-radius:5px;font-weight:700;text-align:center&quot;&gt;This offer is valid till 23 March 2025&lt;/p&gt;");
    popupcontent = HtmlUnescape().convert(widget.subscription.popupcontent.toString() ?? "");

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();

  }
  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.clear,
              color: kBackgroundColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        key: scaffoldKey,
        elevation: 0,
        // iconTheme: const IconThemeData(color: kSelectItemColor),
        backgroundColor: kGreenColorColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: kGreenColorColor,
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/loading_animated.gif',
                image: widget.subscription.popupimage ?? "",
                fit: BoxFit.fitWidth,
              ),
            ),
            Html(data:popupcontent),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(AuthScreen.routeName);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child:  InkWell(
                        onTap:  () {
                          Navigator.of(context).pop();
                          launchUrl(Uri.parse(widget.subscription.popuplink ?? ""), mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          color: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal:40.0,vertical: 14.0),
                          child: const Center(
                            child: Text(
                              'Buy Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                   Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          widget.subscription.price ?? "",
                          style: const TextStyle(
                            color: kTextLightColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                              decoration: TextDecoration.lineThrough
                          ),
                        ),
                        Text(
                          widget.subscription.discountedprice ?? "",
                          style: const TextStyle(
                            color: kRedColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.subscription.duration ?? "",
                          style: const TextStyle(
                            color: kTextLightColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
