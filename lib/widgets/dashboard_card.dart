import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final String? badgeText;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (hasImage ? Colors.black : color).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.4),
          child: Stack(
            children: [
              // Background Wallpaper Image
              if (hasImage)
                Positioned.fill(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.8), color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.8), color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Rich Dual-tone Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: hasImage
                        ? LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.90),
                        Colors.black.withValues(alpha: 0.45),
                        color.withValues(alpha: 0.50),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    )
                        : LinearGradient(
                      colors: [
                        Theme.of(context).cardColor,
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Content Layer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasImage
                                ? Colors.white.withValues(alpha: 0.22)
                                : color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: hasImage
                                ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                                : null,
                          ),
                          child: Icon(
                            icon,
                            color: hasImage ? Colors.white : color,
                            size: 22,
                          ),
                        ),
                        if (badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasImage
                                  ? color.withValues(alpha: 0.9)
                                  : color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: hasImage
                                  ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: hasImage ? Colors.white : color,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: hasImage ? Colors.white : Theme.of(context).textTheme.titleMedium?.color,
                            shadows: hasImage
                                ? const [
                              Shadow(
                                color: Colors.black87,
                                offset: Offset(0, 1.5),
                                blurRadius: 4,
                              ),
                            ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasImage ? Colors.white70 : Colors.grey.shade600,
                            height: 1.25,
                          ),
                        ),
                      ],
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
