import 'package:flutter/material.dart';
import './custom_text.dart';
import '../constants.dart';

class TabViewDetails extends StatelessWidget {
  final String? titleText;
  final List<String>? listText;

  const TabViewDetails({
    super.key,
    @required this.titleText,
    @required this.listText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: CustomText(
                text: titleText,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                colors: kDarkGreyColor,
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (ctx, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CustomText(
                      text: listText![index],
                      colors: kDarkGreyColor,
                      fontSize: 14,
                    ),
                    if (index < listText!.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Divider(
                          height: 3,
                          color: Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            },
            itemCount: listText!.length,
          ),
        ),
      ],
    );
  }
}
