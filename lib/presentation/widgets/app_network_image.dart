import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageUrl == null || imageUrl!.isEmpty) {
      content = _placeholder(width: width, height: height);
    } else {
      content = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return _loading(width: width, height: height);
          }
          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loading(width: width, height: height);
        },
        errorBuilder: (context, error, stackTrace) {
          return _error(width: width, height: height);
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _placeholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.tertiaryBlack,
      child: Icon(
        Icons.local_movies,
        color: AppColors.grayWhite,
        size: 36,
      ),
    );
  }

  Widget _loading({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondaryBlack,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          ),
        ),
      ),
    );
  }

  Widget _error({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.secondaryBlack,
      child: Icon(
        Icons.broken_image,
        color: AppColors.grayWhite,
        size: 32,
      ),
    );
  }
}