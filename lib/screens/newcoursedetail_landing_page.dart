// lib/course_landing_page.dart
// Same-to-same mobile course landing page, Provider-based.
//
// Add provider to pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   provider: ^6.0.0

import 'dart:io';

import 'package:academy_app/models/common_functions.dart' as cf;
import 'package:academy_app/screens/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../models/course_detail_landing_models.dart';
import '../providers/course_detail_landing_provider.dart';
import '../providers/courses.dart';
import '../providers/shared_pref_helper.dart';
import 'auth_screen.dart';
import 'coursedetailscreendeeiplink.dart';

/* ================== PALETTE & CONSTANTS ================== */

class _Palette {
  static const brand = Color(0xFF00A779); // primary green
  static const brandDeep = Color(0xFF0C3B3A);
  static const brandDeepgreen = Color(0xFF003840);
  static const chip = Color(0xFFE9F6F1);
  static const neongreen = Color(0xFFD7FC5A);
  static const card = Colors.white;
  static const textDark = Color(0xFF0B1220);
  static const muted = Color(0xFF7C8B9A);
  static const success = Color(0xFF27AE60);
  static const stroke = Color(0xFFE7ECEB);
  static const kPayBlue  = Color(0xFF1677FF);
  static const successLight =
      Color(0xFFE8F8EE); // 👈 Very light success color for fills
}

const _pad = 16.0;

String landingCtaText(LandingVM vm) {
  if (Platform.isIOS) return 'View Details'; // iOS override

  final purchased = vm.data?.isPurchased ?? false;
  final isFree    = vm.data?.isFreeCourse ?? false;

  if (purchased) return 'Purchased';
  if (isFree)    return 'Register Now'; //Get Enroll
  return 'Buy Now';
}


// String landingCtaText(LandingVM vm) {
//   final purchased = vm.data?.isPurchased ?? false;
//   final isFree    = vm.data?.isFreeCourse ?? false;
//
//   if (purchased) return 'Purchased';
//   if (isFree)    return 'Get Enroll';
//   return 'Buy Now';
// }


String _sanitizeUrl(String raw) {
  final s = (raw).trim();
  if (s.isEmpty) return '';
  // add scheme if missing
  if (!s.startsWith('http://') && !s.startsWith('https://')) {
    return 'https://$s';
  }
  return s;
}

Future<void> _openIosExternal(BuildContext context) async {
  // read from LandingVM model: data.webLink
  try {
    final vm = context.read<LandingVM>();
    final fromModel = vm.data?.webLink ?? '';
    final url = _sanitizeUrl(fromModel.isNotEmpty ? fromModel : 'https://www.greylearn.com');
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // last-resort fallback
    final uri = Uri.parse('https://www.greylearn.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}



Future<void> handleLandingCTA(BuildContext context, int courseId) async {
  // iOS: always open external browser and return
  if (Platform.isIOS) {
    await _openIosExternal(context);
    return;
  }
  // 0) login gate
  final token = await SharedPreferenceHelper().getAuthToken();
  final loggedIn = token != null && token.trim().isNotEmpty;
  if (!loggedIn) {
    try {
      cf.CommonFunctions.showSuccessToast('Please login first');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
    }
    if (context.mounted) {
      Navigator.of(context).pushNamed(AuthScreen.routeName);
    }
    return;
  }

  // 1) Read latest flags (prefer VM)
  bool purchased = false;
  bool isFree = false;
  try {
    final vm = context.read<LandingVM>();
    if (vm.data == null) {
      await vm.loadCourseById(courseId);
    }
    purchased = vm.data?.isPurchased ?? false;
    isFree    = vm.data?.isFreeCourse ?? false;
  } catch (_) {}

  // Fallback to Courses provider if VM not ready
  if (!purchased) {
    try {
      await context.read<Courses>().fetchCourseDetailById(courseId);
      purchased = context.read<Courses>().getCourseDetail.isPurchased == true;
      // If your CourseDetail has free flag, you can read it here too
    } catch (_) {}
  }

  // 2) If already purchased -> stop
  if (purchased) {
    try {
      cf.CommonFunctions.showSuccessToast('Already purchased');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already purchased')),
      );
    }
    return;
  }

  // 3) Free enroll flow
  if (isFree) {
    try {
      await context.read<Courses>().getEnrolled(courseId);

      // Re-sync both data sources
      await Future.wait([
        context.read<Courses>().fetchCourseDetailById(courseId),
        context.read<LandingVM>().loadCourseById(courseId),
      ]);

      try {
        cf.CommonFunctions.showSuccessToast('Enrolled Successfully');
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrolled Successfully')),
        );
      }
      return;
    } catch (_) {
      try {
        cf.CommonFunctions.showWarningToast('Something went wrong. Please try again.');
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
      return;
    }
  }
  //
  // 4) Paid flow -> WebView checkout
  final base = BASE_URL;
  final url = '$base/api/web_redirect_to_buy_course/$token/$courseId/academybycreativeitem';

  if (!context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => WebViewScreen(url: url)),
  );

//   // 4) Paid flow -> WebView checkout
//   // --------- ✅ SAFE URL BUILD (GET) ----------
//   final baseUri = Uri.parse(BASE_URL); // e.g. https://learn.greylearn.com
//   final redirectUri = Uri.parse('https://learn.greylearn.com/go/smart-open/%7B%7B1%7D%7Dmy_course');
//
//   final apiUri = Uri(
//     scheme: baseUri.scheme,
//     host: baseUri.host,
//     port: baseUri.hasPort ? baseUri.port : null,
//     pathSegments: [
//       ...baseUri.pathSegments.where((s) => s.isNotEmpty),
//       'api',
//       'web_redirect_to_buy_course',
//       token!,                 // safe as a segment
//       courseId.toString(),
//     ],
//     queryParameters: {
//       'redirect': redirectUri.toString(), // <-- put redirect in query
//     },
//   );
// // ---------- FORCE RAW PRINT ----------
//   print("🔗 ENCODED API URL: ${apiUri.toString()}");
//   print("🔍 DECODED (REAL) URL: ${Uri.decodeFull(apiUri.toString())}");
//
//   // -------------------------------------------
//
//   if (!context.mounted) return;
//
//   await Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => WebViewScreen(url: apiUri.toString())),
//   );

  // 5) Back from WebView => re-sync both (so Purchased shows instantly)
  try {
    await Future.wait([
      context.read<Courses>().fetchCourseDetailById(courseId),
      context.read<LandingVM>().loadCourseById(courseId),
    ]);
  } catch (_) {}
}
/* ================== PAGE ================== */

class CourseLandingPage extends StatelessWidget {
  static const routeName = '/course-landing'; // 👈 add this

  final int courseId;
  const CourseLandingPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    // Helper: if provider not found, wrap and load; else use existing
    Widget ensureProvided({required Widget child}) {
      try {
        // Will throw if provider is missing
        context.read<LandingVM>();
        // Provider already up the tree: trigger load once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final vm = context.read<LandingVM>();
          if (vm.data == null && !vm.loading) vm.loadCourseById(courseId);
        });
        return child;
      } catch (_) {
        // No provider -> wrap now
        return ChangeNotifierProvider(
          create: (_) => LandingVM()..loadCourseById(courseId),
          child: child,
        );
      }
    }

    return ensureProvided(
      child: Builder(
        // Re-enter tree after (maybe) providing VM
        builder: (ctx) {
          return Scaffold(
            appBar: const CustomAppBarr(),
            body: SafeArea(
              bottom: false,
              child: Consumer<LandingVM>(
                builder: (_, vm, __) {
                  if (vm.loading)
                    // return const Center(child: CircularProgressIndicator(color: _Palette.success,));
                    return const _LandingSkeletonPage();

                  if (vm.error != null) return Center(child: Text(vm.error!));
                  if (vm.data == null)
                    return const Center(child: Text("No data"));
                  final purchased = vm.data?.isPurchased ?? false;


                  return CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: _HeroHeader()),
                      const SliverToBoxAdapter(child: _QuickStats()),
                      const SliverToBoxAdapter(child: _RegisterRow()),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      const SliverToBoxAdapter(child: _PromoBanner()),
                      const SliverToBoxAdapter(child: _GreenTickNote()),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      const SliverToBoxAdapter(
                          child: _CertificateAndLearnSection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                      const SliverToBoxAdapter(child: _CourseCurriculum()),
                      const SliverToBoxAdapter(child: _LearnWithGreyLearn()),
                      const SliverToBoxAdapter(child: _ReviewsSection()),
                      const SliverToBoxAdapter(child: _CertificateMock()),
                      const SliverToBoxAdapter(child: _FaqsBlock()),
                      const SliverToBoxAdapter(child: _LimitedTimeOffer()),
                      SliverPadding(

                        padding:
                            const EdgeInsets.fromLTRB(_pad, 0, _pad, 20 + _pad),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: SizedBox(
                              // width: 240,
                              width: double.infinity,
                              height: 55,
                              child: _PrimaryCTA(
                                text: landingCtaText(context.read<LandingVM>()),
                                // bgColor: purchased ? _Palette.kPayBlue : null,
                                onTap: () => handleLandingCTA(
                                  context,
                                  context.read<LandingVM>().data?.id ?? 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ⬇️ show bottom bar ONLY when data is loaded (not while loading/error)
            bottomNavigationBar: Consumer<LandingVM>(
              builder: (_, vm, __) {
                // data ready guard
                if (vm.loading || vm.data == null || vm.error != null) {
                  return const SizedBox.shrink();
                }

                // ---- iOS: only "View Details" button, no price ----
                if (Platform.isIOS) {
                  return Material(
                    color: _Palette.brandDeep,
                    elevation: 12,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(_pad, 10, _pad, 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 200,
                            height: 48,
                            child: _PrimaryCTA(
                              text: 'View Details',
                              onTap: () async => _openIosExternal(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // ---- ANDROID: your existing StickyEnrollBar with price ----
                final priceText = vm.data!.price;
                final priceLabel = (priceText.isEmpty || priceText == '0')
                    ? '₹0'
                    : (priceText.contains('₹') ? priceText : '$priceText');

                return _StickyEnrollBar(
                  price: priceLabel,
                  onTap: () => handleLandingCTA(_, vm.data!.id),
                  ctaText: landingCtaText(vm),
                  buttonWidth: 200,
                );
              },
            ),
            // bottomNavigationBar: Consumer<LandingVM>(
            //   builder: (_, vm, __) {
            //     // hide completely until data is ready
            //     if (vm.loading || vm.data == null || vm.error != null) {
            //       return const SizedBox.shrink();
            //     }
            //
            //     final priceText = vm.data!.price;
            //     final priceLabel = (priceText.isEmpty || priceText == '0')
            //         ? '₹0'
            //         : (priceText.contains('₹') ? priceText : '₹$priceText');
            //
            //     return _StickyEnrollBar(
            //       price: priceLabel,
            //       onTap: () => handleLandingCTA(_, vm.data!.id),
            //       ctaText: landingCtaText(vm),
            //       buttonWidth: 200,
            //     );
            //   },
            // ),

          );
        },
      ),
    );
  }
}

class _StickyEnrollBar extends StatelessWidget {
  final String price; // e.g. "₹1,000"
  // final String mrp; // e.g. "₹8,500"
  final String ctaText;
  final VoidCallback onTap;
  final double buttonWidth;
  final double buttonHeight;
  final Color? buttonColor; // 👈 NEW


  const _StickyEnrollBar({
    super.key,
    required this.price,
    // required this.mrp,
    required this.onTap,
    this.ctaText = "",
    this.buttonWidth = 180,
    this.buttonHeight = 48,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Material(
      color: _Palette.brandDeep,
      elevation: 12,
      child: SizedBox(
        height: 72 + bottomInset, // 🔒 fixed height
        child: Padding(
          padding: EdgeInsets.fromLTRB(_pad, 10, _pad, 10 + bottomInset),
          child: Row(
            children: [
              // LEFT: Price
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(price,
                        style: const TextStyle(
                          color: _Palette.brand,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        )),
                    // const SizedBox(height: 2),
                    // Text(mrp,
                    //     style: TextStyle(
                    //       color: Colors.white.withOpacity(0.65),
                    //       decoration: TextDecoration.lineThrough,
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.w600,
                    //     )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // RIGHT: Button
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(ctaText,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor ?? _Palette.brand, // 👈 use custom
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12), // 👈 fixed radius 23
                    ),
                    elevation: 0,
                  ),
                  onPressed: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================== SECTIONS ================== */

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    // Read dynamic values from LandingVM (ensure LandingVM is provided above)
    final vm = context.watch<LandingVM>();
    final String title = (vm.data?.title?.trim().isNotEmpty ?? false)
        ? vm.data!.title
        : 'Java Programming';
    final String badgeText = (vm.data?.categoryName?.trim().isNotEmpty ?? false)
        ? vm.data!.categoryName
        : 'Certificate Course';
    final String shortdescription =
        (vm.data?.shortdescription?.trim().isNotEmpty ?? false)
            ? vm.data!.shortdescription
            : 'Java Programming';
    return Padding(
      padding: const EdgeInsets.all(_pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Badge(text: badgeText),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: _Palette.brand,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            shortdescription,
            style: TextStyle(color: _Palette.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    const gap = 10.0; // space between tiles
    const columns = 2; // two tiles per row
    final vm = context.watch<LandingVM>();
    final totalEnroll = vm.data?.totalEnrollmentfake ?? 0;
    final languages = vm.data?.languages ?? "English";
    final courseduration = vm.data?.courseduration ?? "Weeks";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth =
              (constraints.maxWidth - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: tileWidth,
                child: _InfoTile(
                  icon: Icons.people_alt_rounded,
                  title: 'STUDENTS ENROLLED',
                  value: '${totalEnroll}+',
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: const _InfoTile(
                  icon: Icons.event_seat_rounded,
                  title: 'SEATS LEFT',
                  value: 'Limited (Hurry!)',
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _InfoTile(
                  icon: Icons.translate_rounded,
                  title: 'LANGUAGE',
                  value: languages,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _InfoTile(
                  icon: Icons.timelapse_rounded,
                  title: 'DURATION',
                  value: courseduration,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final faces = vm.data?.reviewFaces ?? const [];
    final enroll = vm.data?.totalEnrollmentfake ?? 0;
    final purchased = vm.data?.isPurchased ?? false;

    return Padding(
      padding: const EdgeInsets.all(_pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrimaryCTA(
            text: landingCtaText(context.read<LandingVM>()),
            // bgColor: purchased ? _Palette.kPayBlue : null, // 👈
            onTap: () => handleLandingCTA(
              context,
              context.read<LandingVM>().data?.id ?? 0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Faces
              Row(
                children: [
                  for (final url in faces.take(4)) _Face(size: 36, url: url),
                ],
              ),
              // Right pill: enrollment
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.grey[700]!, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_alt_rounded,
                        size: 18, color: _Palette.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${enroll >= 1000 ? "${(enroll / 1000).toStringAsFixed(1)}k+" : enroll} students',
                      style: const TextStyle(
                          color: Color(0xff003840),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Stars + rating
          Row(
            children: [
              _Stars(rating: (vm.data?.rating ?? 0).toDouble()),
              const SizedBox(width: 6),
              Text(
                '${(vm.data?.rating ?? 0).toStringAsFixed(1)}/5 • ${(vm.data?.numberOfRatings ?? 0)} reviews',
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final thumb = (vm.data?.thumbnail.trim().isNotEmpty ?? false)
        ? vm.data!.thumbnail
        : 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=1200&auto=format&fit=crop';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: Material(
        color: _Palette.card,
        elevation: 16,
        shadowColor: Colors.black.withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 16 / 10, // frame 16:9 रहेगा
          child: Container(
            color: Colors.black12, // letterbox background
            child: Center(
              child: Image.network(
                thumb,
                fit: BoxFit.contain,          // ✅ no crop, no stretch
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined, size: 42, color: Colors.black38),
                // optional: nice shimmer while loading
                loadingBuilder: (ctx, child, ev) {
                  if (ev == null) return child;
                  return const SizedBox.expand(
                    // child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    child: const _LandingSkeletonPage(),

                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ================== SKELETON LANDING PAGE ==================

class _LandingSkeletonPage extends StatelessWidget {
  const _LandingSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _LandingHeaderSkeleton()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: _QuickStatsSkeleton()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _PromoBannerSkeleton()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'Certificate section')),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'What will you learn')),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'Curriculum')),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'Reviews')),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'Certificate preview')),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'FAQs')),
          const SliverToBoxAdapter(child: _SectionBlockSkeleton(title: 'Limited-time offer')),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _LandingHeaderSkeleton extends StatelessWidget {
  const _LandingHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // badge
          Container(
            height: 24,
            width: 120,
            decoration: BoxDecoration(
              color: _Palette.neongreen,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          // title lines
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 18,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          // subtitle
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 20),
          // primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.brand,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Enroll Now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsSkeleton extends StatelessWidget {
  const _QuickStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    const columns = 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth =
              (constraints.maxWidth - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(4, (index) {
              return SizedBox(
                width: tileWidth,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Palette.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _Palette.stroke),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _Palette.chip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: _Palette.brand, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(
                              height: 10,
                              child: Text('STAT TITLE'),
                            ),
                            SizedBox(height: 4),
                            SizedBox(
                              height: 14,
                              child: Text('123+'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _PromoBannerSkeleton extends StatelessWidget {
  const _PromoBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pad),
      child: Material(
        color: _Palette.card,
        elevation: 16,
        shadowColor: Colors.black.withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            color: Colors.black12,
          ),
        ),
      ),
    );
  }
}

class _SectionBlockSkeleton extends StatelessWidget {
  final String title;
  const _SectionBlockSkeleton({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, 16, _pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _Palette.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _Palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Palette.stroke),
            ),
          ),
        ],
      ),
    );
  }
}


class _GreenTickNote extends StatelessWidget {
  const _GreenTickNote();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final infotitle = vm.data?.infotitle ?? "Na";

    return Padding(
      padding: const EdgeInsets.all(_pad),
      child: _NoteCard(icon: Icons.info, text: infotitle),
    );
  }
}

// class _CertificateAndLearnSection extends StatelessWidget {
//   const _CertificateAndLearnSection();
//
//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<LandingVM>();
//     final outs = vm.data?.outcomes ?? const <String>[];
//
//     return Container(
//       color: _Palette.brandDeep, // 👈 Same background for both sections
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // ---------------- Certificate Section ----------------
//           Padding(
//             padding: const EdgeInsets.fromLTRB(_pad, 24, _pad, 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 RichText(
//                   textAlign: TextAlign.center,
//                   text: TextSpan(
//                     style: const TextStyle(
//                         fontSize: 20, color: Colors.white, height: 1.3),
//                     children: [
//                       const TextSpan(
//                         text: 'The ',
//                         style: TextStyle(fontWeight: FontWeight.w800),
//                       ),
//                       TextSpan(
//                         text: 'certificate',
//                         style: TextStyle(
//                             color: _Palette.brand, fontWeight: FontWeight.w800),
//                       ),
//                       const TextSpan(
//                         text: '\ncourse for you!',
//                         style: TextStyle(fontWeight: FontWeight.w800),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 14),
//                 const _TickLine.light(
//                     text:
//                         'Master OOP, Collections, and error handling with best practices.'),
//                 const _TickLine.light(
//                     text:
//                         'Write modern Java with Streams, and clean functional patterns.'),
//                 const _TickLine.light(
//                     text:
//                         'Intro to Spring Boot & REST APIs—controllers, DTOs, persistence.'),
//                 const SizedBox(height: 12),
//                 const _PrimaryCTA(text: "Register Now"),
//               ],
//             ),
//           ),
//
//           // ---------------- Learn Section ----------------
//           Padding(
//             padding: const EdgeInsets.all(_pad),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _SectionTitle.light(
//                   leading: 'What Will You',
//                   highlight: 'Learn?',
//                 ),
//                 const SizedBox(height: 12),
//                 const _LearnCard(
//                   icon: Icons.data_object_rounded,
//                   title:
//                       'Core Java: types, control flow, classes/objects, constructors, encapsulation.',
//                 ),
//                 const SizedBox(height: 10),
//                 const _LearnCard(
//                   icon: Icons.view_list_rounded,
//                   title:
//                       'Collections & generics: List/Set/Map, iterators, algorithms, immutability.',
//                 ),
//                 const SizedBox(height: 10),
//                 const _LearnCard(
//                   icon: Icons.stream_rounded,
//                   title:
//                       'Streams & lambdas: mapping, filtering, collectors, parallel streams basics.',
//                 ),
//                 const SizedBox(height: 10),
//                 const _LearnCard(
//                   icon: Icons.bug_report_rounded,
//                   title:
//                       'Testing & debugging: JUnit, assertions, logging, stack traces, exceptions.',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _CertificateAndLearnSection extends StatelessWidget {
  const _CertificateAndLearnSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final outs = vm.data?.outcomes ?? const <String>[];
    final whatuwilllearn = vm.data?.whatyouwillbelearn ?? const <String>[];
    final purchased = vm.data?.isPurchased ?? false;

    // icons for learn cards (cycle through)
    const learnIcons = <IconData>[
      Icons.data_object_rounded,
      Icons.view_list_rounded,
      Icons.stream_rounded,
      Icons.bug_report_rounded,
      Icons.auto_awesome_rounded,
      Icons.integration_instructions_rounded,
    ];

    // ===== Certificate ticks: render ALL outcomes (no cap)
    final certificateTicks = outs.isNotEmpty
        ? outs.map((s) => _TickLine.light(text: s)).toList()
        : const [
            _TickLine.light(
                text:
                    'Master OOP, Collections, and error handling with best practices.'),
            _TickLine.light(
                text:
                    'Write modern Java with Streams, and clean functional patterns.'),
            _TickLine.light(
                text:
                    'Intro to Spring Boot & REST APIs—controllers, DTOs, persistence.'),
          ];

    // ===== Learn cards: also render ALL outcomes as cards (no cap)
    final learnCards = whatuwilllearn.isNotEmpty
        ? List.generate(whatuwilllearn.length, (i) {
            return _LearnCard(
                icon: learnIcons[i % learnIcons.length],
                title: whatuwilllearn[i]);
          })
        : const [
            _LearnCard(
              icon: Icons.data_object_rounded,
              title:
                  'Core Java: types, control flow, classes/objects, constructors, encapsulation.',
            ),
            _LearnCard(
              icon: Icons.view_list_rounded,
              title:
                  'Collections & generics: List/Set/Map, iterators, algorithms, immutability.',
            ),
            _LearnCard(
              icon: Icons.stream_rounded,
              title:
                  'Streams & lambdas: mapping, filtering, collectors, parallel streams basics.',
            ),
            _LearnCard(
              icon: Icons.bug_report_rounded,
              title:
                  'Testing & debugging: JUnit, assertions, logging, stack traces, exceptions.',
            ),
          ];

    return Container(
      color: _Palette.brandDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- Certificate Section ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(_pad, 24, _pad, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const RichTitleCertificate(),
                const SizedBox(height: 14),
                ...certificateTicks,
                const SizedBox(height: 12),
                _PrimaryCTA(
                  text: landingCtaText(context.read<LandingVM>()),
                  // bgColor: purchased ? _Palette.kPayBlue : null,
                  onTap: () => handleLandingCTA(
                    context,
                    context.read<LandingVM>().data?.id ?? 0,
                  ),
                ),
              ],
            ),
          ),

          // ---------------- Learn Section ----------------
          Padding(
            padding: const EdgeInsets.all(_pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle.light(
                    leading: 'What Will You', highlight: 'Learn?'),
                const SizedBox(height: 12),
                for (int i = 0; i < learnCards.length; i++) ...[
                  learnCards[i],
                  if (i != learnCards.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// small helper to keep the original heading intact
class RichTitleCertificate extends StatelessWidget {
  const RichTitleCertificate({super.key});
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(fontSize: 20, color: Colors.white, height: 1.3),
        children: [
          TextSpan(text: 'The ', style: TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(
              text: 'certificate',
              style: TextStyle(
                  color: _Palette.brand, fontWeight: FontWeight.w800)),
          TextSpan(
              text: '\ncourse for you!',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}


class _CourseCurriculum extends StatelessWidget {
  const _CourseCurriculum();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final all = vm.data?.sections ?? const <LandingSection>[];

    // 👇 only first 10 sections visible
    final sections = all.take(10).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(leading: 'Course', highlight: 'Curriculum'),
          const SizedBox(height: 12),
          if (sections.isEmpty)
            _MutedCenter(text: 'No sections available')
          else
            ...List.generate(sections.length, (i) {
              final sec = sections[i];
              final open = vm.isOpen(i);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _Palette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.stroke),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => vm.toggle(i),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        // ===== HEADER (unchanged) =====
                        Row(
                          children: [
                            Icon(
                              open
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: _Palette.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sec.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _Palette.chip,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${sec.lessons.toString().padLeft(2, '0')} Lessons',
                                style: TextStyle(
                                  color: _Palette.brand,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ===== BODY (new screenshot-style) =====
                        if (open) ...[
                          const SizedBox(height: 10),
                          Divider(
                              height: 1, color: Colors.black.withOpacity(.06)),
                          const SizedBox(height: 8),
                          if (sec.items.isEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('No lessons',
                                  style: TextStyle(color: _Palette.muted)),
                            )
                          else
                            ...List.generate(sec.items.length, (j) {
                              final l = sec.items[j];
                              return _LessonRowSimple(
                                title: l.title,
                                duration: l.duration,
                                isLast: j == sec.items.length - 1,
                              );
                            }),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Simple lesson row: left play circle, center title, right duration, with divider.
class _LessonRowSimple extends StatelessWidget {
  final String title;
  final String duration;
  final bool isLast;
  const _LessonRowSimple({
    required this.title,
    required this.duration,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // circular play icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _Palette.brand.withOpacity(.85), width: 2),
              ),
              child: Icon(Icons.play_arrow_rounded,
                  size: 14, color: _Palette.brand),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w200, height: 1.2),
              ),
            ),
            const SizedBox(width: 8),
            if (duration.isNotEmpty)
              Text(
                duration,
                style: TextStyle(
                    color: _Palette.muted, fontWeight: FontWeight.w600),
              ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.black.withOpacity(.06)),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

// top of file: import 'package:flutter/material.dart'; (already)
// and provider import for vm as you have

class _LearnWithGreyLearn extends StatelessWidget {
  const _LearnWithGreyLearn({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final imageUrl = (vm.data?.heroimg.trim().isNotEmpty ?? false)
        ? vm.data!.heroimg
        : 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?q=80&w=1600&auto=format&fit=crop';
    final purchased = vm.data?.isPurchased ?? false;
    final points = vm.data?.learnwithgreylearn ?? const <String>[];

    return Container(
      color: _Palette.brandDeep,
      padding: const EdgeInsets.fromLTRB(_pad, 20, _pad, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======== HERO CARD: gradient bg + rounded + shadow + image ========
          _HeroImageCard(
            imageUrl: imageUrl,
            // OPTIONAL: overlay widgets (e.g., certificate png) => see param below
            overlay: const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          const _SectionTitle.light(
              leading: 'Learn With', highlight: 'GreyLearn'),
          const SizedBox(height: 12),

          if (points.isNotEmpty)
            ...points.map((s) => _TickLine.light(text: s)).expand((w) sync* {
              yield w;
              yield const SizedBox(height: 8);
            })
          else ...const [
            _TickLine.light(
                text:
                    'Built Java services in production—REST APIs, persistence, and CI-friendly testing.'),
            SizedBox(height: 8),
            _TickLine.light(
                text:
                    'Teaches clean code, domain modeling, and refactoring habits from day one.'),
            SizedBox(height: 8),
            _TickLine.light(
                text:
                    "Focus on practical patterns you'll use in interviews and real teams."),
            SizedBox(height: 8),
            _TickLine.light(
                text:
                    'Hands-on exercises and mini projects to apply each concept immediately.'),
            SizedBox(height: 8),
            _TickLine.light(
                text:
                    'Interview-oriented tips: debugging, clean commits, and explaining trade-offs clearly.'),
          ],

          const SizedBox(height: 12),
          _PrimaryCTA(
            text: landingCtaText(context.read<LandingVM>()),
            // bgColor: purchased ? _Palette.kPayBlue : null,
            onTap: () => handleLandingCTA(
              context,
              context.read<LandingVM>().data?.id ?? 0,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Gradient rounded background with big shadow + hero image on top (cover).
class _HeroImageCard extends StatelessWidget {
  final String imageUrl;
  final Widget overlay; // e.g., Positioned certificate PNG if you want
  const _HeroImageCard(
      {required this.imageUrl,
      this.overlay = const SizedBox.shrink(),
      super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // BACKGROUND CARD
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0FB48E), // light teal
                  Color(0xFF045B5B), // deep teal
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.25),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            // inner highlight for depth (soft glassy feel)
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // HERO IMAGE (full, center-crop)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Align(
              alignment: Alignment.center,
              child: Image.network(
                imageUrl,
                fit: BoxFit.scaleDown, // FULL cover
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(color: Colors.black12),
              ),
            ),
          ),

          // OPTIONAL: overlay content (certificate png etc.)
          overlay,
        ],
      ),
    );
  }
}

// ---- helper: open masterclass/register deeplink ----
// const String _MASTERCLASS_URL = 'https://greylearn.com/masterclass/java'; // 🔁 change as needed
// Future<void> _openMasterclass() async {
//   final uri = Uri.parse(_MASTERCLASS_URL);
//   if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//     throw 'Could not launch $_MASTERCLASS_URL';
//   }
// }

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final all = vm.data?.testimonials ?? const <Testimonial>[];
    final list = vm.showAllReviews ? all : all.take(4).toList();
    final canToggle = all.length > 4;
    final purchased = vm.data?.isPurchased ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, 18, _pad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(leading: 'What Learners', highlight: 'Say'),
          const SizedBox(height: 12),

          ...list
              .map((t) => _ReviewCard(_Review(
                    name: t.name,
                    text: t.content,
                    avatar: t.userImage,
                    rating: t.rating,
                  )))
              .expand((w) sync* {
            yield w;
            yield const SizedBox(height: 10);
          }),

          // ⬇️ Primary CTA: ALWAYS joins masterclass (no toggle)
          Align(
            alignment: Alignment.center,
            child: _PrimaryCTA(
              text: landingCtaText(context.read<LandingVM>()),
              // bgColor: purchased ? _Palette.kPayBlue : null,
              onTap: () => handleLandingCTA(
                context,
                context.read<LandingVM>().data?.id ?? 0,
              ),
              icon: Icons.electric_bolt_rounded,
              // onTap: _openMasterclass, // 👈 real action
            ),
          ),

          // ⬇️ Secondary small link: toggles reviews (optional)
          if (canToggle) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: vm.toggleReviews,
                child: Text(
                  vm.showAllReviews ? 'Show fewer reviews' : 'See more reviews',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }
}

class _CertificateMock extends StatelessWidget {
  const _CertificateMock();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final certificateurl = (vm.data?.certificateUrl.trim().isNotEmpty ?? false)
        ? vm.data!.certificateUrl
        : 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?q=80&w=1600&auto=format&fit=crop';
    final purchased = vm.data?.isPurchased ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_pad, 8, _pad, 16),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                  color: _Palette.textDark, fontSize: 18, height: 1.3),
              children: [
                const TextSpan(
                    text: 'Yes! You will be ',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(
                    text: 'certified ',
                    style: TextStyle(
                        color: _Palette.brand, fontWeight: FontWeight.w800)),
                const TextSpan(
                    text: 'for this Masterclass.',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _Palette.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // primary deep shadow
                BoxShadow(
                  color: Colors.black.withOpacity(.20),
                  blurRadius: 30,
                  spreadRadius: 1,
                  offset: const Offset(0, 14),
                ),
                // soft ambient shadow
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 19 / 13.5,
              child: Image.network(
                certificateurl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 15),
          _PrimaryCTA(
            text: landingCtaText(context.read<LandingVM>()),
            // bgColor: purchased ? _Palette.kPayBlue : null,
            onTap: () => handleLandingCTA(
              context,
              context.read<LandingVM>().data?.id ?? 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqsBlock extends StatefulWidget {
  const _FaqsBlock();

  @override
  State<_FaqsBlock> createState() => _FaqsBlockState();
}

class _FaqsBlockState extends State<_FaqsBlock> {
  // final Set<int> _open = {}; // indices currently expanded
  int? _openIndex; // null = sab band


  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>();
    final allEntries = (vm.data?.faqs ?? const <String, String>{}).entries.toList();

    // ✅ sirf pehle 5 FAQs
    final entries = allEntries.take(5).toList();
    // (safety) agar current open index out of range ho gaya to reset
    if (_openIndex != null &&
        (_openIndex! < 0 || _openIndex! >= entries.length)) {
      _openIndex = null;
    }

    return Padding(
      padding: const EdgeInsets.all(_pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              leading: 'Frequently Asked', highlight: 'Questions'),
          const SizedBox(height: 10),
          if (entries.isEmpty) ...const [
            _MutedCenter(text: "Have something to know? Check here if you"),
            _MutedCenter(text: "have any questions about us."),
            _MutedCenter(text: "No FAQs added yet."),
          ] else
            ...List.generate(entries.length, (i) {
              final q = entries[i].key.trim();
              final a = entries[i].value.trim();
              final isOpen = _openIndex == i; // ✅ sirf yahi index open

              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (isOpen) {
                              // agar same wala click karo -> band karo
                              _openIndex = null;
                            } else {
                              // koi dusra click karo -> sirf ye open
                              _openIndex = i;
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  // green ? icon
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _Palette.brand.withOpacity(.12),
                                    ),
                                    child: Icon(Icons.help_outline_rounded,
                                        size: 16, color: _Palette.brand),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      q,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _Palette
                                            .textDark, // blue-ish like screenshot
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isOpen
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: _Palette.muted,
                                  ),
                                ],
                              ),

                              // Body
                              if (isOpen) ...[
                                const SizedBox(height: 12),
                                Text(
                                  a,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.2,
                                      fontWeight: FontWeight.w200),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // thin divider like screenshot
                  Divider(height: 1, color: Colors.black.withOpacity(.08)),
                  const SizedBox(height: 6),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _LimitedTimeOffer extends StatelessWidget {
  const _LimitedTimeOffer();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LandingVM>(); // ya cl.LandingVM
    final priceLabel = vm.data?.price ?? '0';
    // final mrpLabel   = _rupee(vm.data?.mrpText ?? '');
    return Padding(
      padding: const EdgeInsets.all(_pad),
      child: Column(
        children: [
          Text('Limited-Time Offer',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 18, color: _Palette.textDark),
              children: [
                // const TextSpan(text: '₹ '),
                // const TextSpan(
                //     text: '8,999',
                //     style: TextStyle(
                //         decoration: TextDecoration.lineThrough,
                //         color: _Palette.muted)),
                // const TextSpan(text: '   '),
                TextSpan(
                    text: '${priceLabel}',
                    style: TextStyle(
                        color: _Palette.brand, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/* ================== REUSABLE WIDGETS ================== */

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Palette.neongreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style:
              TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.stroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _Palette.chip, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _Palette.brand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: _Palette.muted,
                        fontSize: 12,
                        letterSpacing: .6)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCTA extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? bgColor; // 👈 NEW

  const _PrimaryCTA({required this.text, this.onTap, this.icon, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      // width: 240,
      child: ElevatedButton.icon(
        icon: Icon(icon ?? Icons.electric_bolt_rounded, size: 20),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor ?? _Palette.brand, // 👈 use custom
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onTap ?? () {},
      ),
    );
  }
}

class _Face extends StatelessWidget {
  final String url;
  final double size;
  const _Face({required this.url, this.size = 24});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.scaleDown),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});
  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        if (i < full)
          return const Icon(Icons.star_rate_rounded,
              color: Colors.amber, size: 25);
        if (i == full && half)
          return const Icon(Icons.star_half_rounded,
              color: Colors.amber, size: 25);
        return const Icon(Icons.star_border_rounded,
            color: Colors.amber, size: 25);
      }),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NoteCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.successLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.success),
      ),
      child: Row(
        children: [
          Icon(icon, color: _Palette.brand),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(text, style: TextStyle(color: _Palette.brandDeepgreen))),
        ],
      ),
    );
  }
}

class _TickLine extends StatelessWidget {
  final String text;
  final bool light; // dark background पर "light" true रखें
  const _TickLine({required this.text, this.light = false});
  const _TickLine.light({required String text}) : this(text: text, light: true);

  @override
  Widget build(BuildContext context) {
    // --- Colors tuned to screenshot ---
    final bg = light ? Colors.white.withOpacity(0.06) : const Color(0xFFEFF6F4);
    final stroke =
        light ? Colors.white.withOpacity(0.10) : const Color(0xFFE0ECE8);
    final txt = light
        ? Colors.white.withOpacity(0.92)
        : _Palette.textDark.withOpacity(0.88);
    final ico = _Palette.brand;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stroke),
        boxShadow: light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading square with rounded corners (as in screenshot)
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: light
                    ? Colors.white.withOpacity(0.25)
                    : _Palette.brand.withOpacity(0.25),
                width: 2,
              ),
            ),
            child: Icon(Icons.check_rounded, size: 18, color: ico),
          ),
          const SizedBox(width: 12),
          // Multi-line text
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: txt,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600, // थोड़ा bold जैसा look
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// extension on _TickLine {
//   static Widget light({required String text}) => _TickLine(text: text).buildLight();
// }

class _SectionTitle extends StatelessWidget {
  final String leading;
  final String highlight;
  final bool light;
  final double lineWidth;
  final double lineHeight;

  const _SectionTitle({
    required this.leading,
    required this.highlight,
    this.lineWidth = 74,
    this.lineHeight = 3,
  }) : light = false;

  const _SectionTitle.light({
    required this.leading,
    required this.highlight,
    this.lineWidth = 74,
    this.lineHeight = 3,
  }) : light = true;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : _Palette.textDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: color,
                fontSize: 20,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: '$leading '),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(color: _Palette.brand),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // centered green divider
        Center(
          child: Container(
            width: lineWidth,
            height: lineHeight,
            decoration: BoxDecoration(
              color: _Palette.brand,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _LearnCard extends StatelessWidget {
  final IconData icon;
  final String title;
  const _LearnCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      // outer card
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Palette.card, // white
        borderRadius:
            BorderRadius.circular(24), // big rounded corners like screenshot
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        // no border (screenshot me subtle stroke nahi hai)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // green rounded square for icon
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // soft gradient + glow feel
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _Palette.brand.withOpacity(.95),
                  _Palette.brand.withOpacity(.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _Palette.brand.withOpacity(.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),

          const SizedBox(width: 16),

          // text
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _Palette.textDark.withOpacity(.92),
                fontSize: 16, // a bit larger like screenshot
                height: 1.35,
                fontWeight: FontWeight.w500,
                letterSpacing: .15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrItem {
  final String title;
  final int lessons;
  final int minutes;
  _CurrItem(this.title, {required this.lessons, required this.minutes});
}

class _Review {
  final String name;
  final String text;
  final String avatar;
  final double rating;
  const _Review(
      {required this.name,
      required this.text,
      required this.avatar,
      this.rating = 4.5});
}

class _ReviewCard extends StatelessWidget {
  final _Review r;
  const _ReviewCard(this.r);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.stroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Face(url: r.avatar, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(r.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                    _Stars(rating: r.rating),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.text,
                    style: TextStyle(color: _Palette.muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedCenter extends StatelessWidget {
  final String text;
  const _MutedCenter({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text, style: TextStyle(color: _Palette.textDark)));
  }
}
