import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/config_data.dart';
import '../providers/shared_pref_helper.dart';
import '../screens/webview_screen.dart';
import 'link_navigator.dart';

class SubscriptionDialog extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionDialog({super.key, required this.subscription});

  /// Call this from anywhere:
  /// SubscriptionDialog.show(context, mySubscription);
  static Future<void> show(BuildContext context, Subscription subscription) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) =>
          SubscriptionDialog(subscription: subscription),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kGreenColorColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: kBackgroundColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Popup image
            Container(
              color: kGreenColorColor,
              width: double.infinity,
              child: FadeInImage.assetNetwork(
                fadeInDuration: const Duration(milliseconds: 1),
                placeholder: 'assets/images/loading_animated.gif',
                image: subscription.popupimage ?? '',
                fit: BoxFit.fitWidth,
              ),
            ),

            // Popup HTML content
            Html(data: HtmlUnescape().convert(subscription.popupcontent ?? '')),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Buy Now button
              SizedBox(
                height: 50.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () async {
                      final nav = Navigator.of(context, rootNavigator: true);
                      nav.pop(); // 👈 pehle dialog close karo

                      final bundleId = subscription.bundleid ?? 0;
                      if (bundleId == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Bundle ID missing!")),
                        );

                        return;
                      }
                      // final baseUri = Uri.parse(
                      //     BASE_URL); // e.g. https://learn.greylearn.com
                      final token =
                          await SharedPreferenceHelper().getAuthToken();
                      // final redirectUri = Uri.parse(
                      //     'https://learn.greylearn.com/go/smart-open/%7B%7B1%7D%7Dmy_course');
                      final directUrl =
                          "$BASE_URL/api/web_redirect_to_buy_bundle/$token/$bundleId/academybycreativeitem";
                      // final apiUri = Uri(
                      //   scheme: baseUri.scheme,
                      //   host: baseUri.host,
                      //   port: baseUri.hasPort ? baseUri.port : null,
                      //   pathSegments: [
                      //     ...baseUri.pathSegments.where((s) => s.isNotEmpty),
                      //     'api',
                      //     'web_redirect_to_buy_bundle',
                      //     token!, // safe as a segment
                      //     bundleId.toString(),
                      //   ],
                      //   queryParameters: {
                      //     'redirect': redirectUri
                      //         .toString(), // <-- put redirect in query
                      //   },
                      // );

                      debugPrint("👉 Direct URL: $directUrl");

                      // 👇 ab isi directUrl ko WebView me khol do
                      Future.microtask(() {
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WebViewScreen(url: directUrl),
                          ),
                        );
                      });
                    },

                    // onTap: () async {
                    //   final rootContext = context;
                    //   Navigator.of(context).pop();
                    //
                    //   final bundleId = subscription.bundleid ?? 0;
                    //
                    //   if (bundleId == 0) {
                    //     ScaffoldMessenger.of(rootContext).showSnackBar(
                    //       const SnackBar(content: Text("Bundle ID missing!")),
                    //     );
                    //     return;
                    //   }
                    //
                    //   final token = await SharedPreferenceHelper().getAuthToken();
                    //   final url =
                    //       "$BASE_URL/api/web_redirect_to_buy_bundle/$token/$bundleId/academybycreativeitem";
                    //
                    //   debugPrint("👉 Final URL: $url");
                    //
                    //   try {
                    //     final response = await http.get(Uri.parse(url));
                    //
                    //     if (response.statusCode == 200) {
                    //       // inside onTap() -> after 200 OK
                    //       final raw = response.body;
                    //       final redirectUrl = raw.trim().replaceAll('"', ''); // 👈 quotes hatao
                    //
                    //
                    //       if (Uri.tryParse(redirectUrl)?.hasScheme != true) {
                    //         ScaffoldMessenger.of(rootContext).showSnackBar(
                    //           const SnackBar(content: Text("Invalid redirect URL")),
                    //         );
                    //         return;
                    //       }
                    //
                    //       Navigator.of(rootContext).push(
                    //         MaterialPageRoute(
                    //           builder: (_) => WebViewScreen(url: redirectUrl),
                    //         ),
                    //       );
                    //     } else {
                    //       ScaffoldMessenger.of(rootContext).showSnackBar(
                    //         SnackBar(content: Text("Error: ${response.statusCode}")),
                    //       );
                    //     }
                    //   } catch (e) {
                    //     ScaffoldMessenger.of(rootContext).showSnackBar(
                    //       SnackBar(content: Text("API error: $e")),
                    //     );
                    //   }
                    // },

                    // onTap: () async {
                    //   Navigator.of(context).pop();
                    //   final token = await SharedPreferenceHelper().getAuthToken();
                    //   LinkNavigator.instance.navigate(
                    //     context,
                    //     subscription.popuplink ?? '',
                    //     'external',
                    //     0,
                    //     subscription.popuplinkauthentication ?? false,
                    //     token ?? '',
                    //     '',
                    //   );
                    // },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 14.0),
                      color: Colors.green,
                      alignment: Alignment.center,
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Price info
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Text(
                      subscription.price ?? '',
                      style: const TextStyle(
                        color: kTextLightColor,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      subscription.discountedprice ?? '',
                      style: const TextStyle(
                        color: kRedColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscription.duration ?? '',
                      style: const TextStyle(
                        color: kTextLightColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
