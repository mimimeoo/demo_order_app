import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../theme/app_colors.dart';
//import 'package:google_fonts/google_fonts.dart';

class CustomCarouselSlider extends StatelessWidget {
  final List<Map<String, String>> items = [
    {
      'image': 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=800&q=80',
      'title': 'Caramel Macchiato',
      'subtitle': 'Sự kết hợp hoàn hảo giữa espresso và sữa béo',
      'badge': '🔥 Bán chạy nhất',
    },
    {
      'image': 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?auto=format&fit=crop&w=800&q=80',
      'title': 'Trà Thạch Đào',
      'subtitle': 'Tươi mát, ngọt dịu cho ngày hè năng động',
      'badge': '⭐ Yêu thích',
    },
    {
      'image': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=800&q=80',
      'title': 'Matcha Đá Xay',
      'subtitle': 'Đậm vị trà xanh Nhật Bản, mịn màng khó cưỡng',
      'badge': '🌱 Mới',
    },
  ];

  CustomCarouselSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final sliderHeight = MediaQuery.of(context).size.height * 0.22;
    
    return CarouselSlider(
      options: CarouselOptions(
        height: sliderHeight,
        autoPlay: true,
        enlargeCenterPage: false,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 1.0,
      ),
      items: items.map((item) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand, 
                  children: [
                    Image.network(
                      item['image']!,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['badge']!,
                          // Body: Inter
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            // Title: Be Vietnam Pro
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, 
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['subtitle']!,
                            // Body: Inter
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade300,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}