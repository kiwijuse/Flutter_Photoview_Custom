library photo_view_gallery;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_view/photo_view.dart'
    show
        LoadingBuilder,
        PhotoView,
        PhotoViewImageTapDownCallback,
        PhotoViewImageTapUpCallback,
        PhotoViewImageScaleEndCallback,
        ScaleStateCycle;

import 'package:photo_view/src/controller/photo_view_controller.dart';
import 'package:photo_view/src/controller/photo_view_scalestate_controller.dart';
import 'package:photo_view/src/core/photo_view_gesture_detector.dart';
import 'package:photo_view/src/photo_view_scale_state.dart';
import 'package:photo_view/src/utils/photo_view_hero_attributes.dart';
import 'package:flutter/services.dart';

/// A type definition for a [Function] that receives a index after a page change in [PhotoViewGallery]
typedef PhotoViewGalleryPageChangedCallback = void Function(int index);

/// A type definition for a [Function] that defines a page in [PhotoViewGallery.build]
typedef PhotoViewGalleryBuilder = PhotoViewGalleryPageOptions Function(
    BuildContext context, int index);

/// A [StatefulWidget] that shows multiple [PhotoView] widgets in a [PageView]
///
/// Some of [PhotoView] constructor options are passed direct to [PhotoViewGallery] constructor. Those options will affect the gallery in a whole.
///
/// Some of the options may be defined to each image individually, such as `initialScale` or `PhotoViewHeroAttributes`. Those must be passed via each [PhotoViewGalleryPageOptions].
///
/// Example of usage as a list of options:
/// ```
/// PhotoViewGallery(
///   pageOptions: <PhotoViewGalleryPageOptions>[
///     PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage("assets/gallery1.jpg"),
///       heroAttributes: const PhotoViewHeroAttributes(tag: "tag1"),
///     ),
///     PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage("assets/gallery2.jpg"),
///       heroAttributes: const PhotoViewHeroAttributes(tag: "tag2"),
///       maxScale: PhotoViewComputedScale.contained * 0.3
///     ),
///     PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage("assets/gallery3.jpg"),
///       minScale: PhotoViewComputedScale.contained * 0.8,
///       maxScale: PhotoViewComputedScale.covered * 1.1,
///       heroAttributes: const HeroAttributes(tag: "tag3"),
///     ),
///   ],
///   loadingBuilder: (context, progress) => Center(
///            child: Container(
///              width: 20.0,
///              height: 20.0,
///              child: CircularProgressIndicator(
///                value: _progress == null
///                    ? null
///                    : _progress.cumulativeBytesLoaded /
///                        _progress.expectedTotalBytes,
///              ),
///            ),
///          ),
///   backgroundDecoration: widget.backgroundDecoration,
///   pageController: widget.pageController,
///   onPageChanged: onPageChanged,
/// )
/// ```
///
/// Example of usage with builder pattern:
/// ```
/// PhotoViewGallery.builder(
///   scrollPhysics: const BouncingScrollPhysics(),
///   builder: (BuildContext context, int index) {
///     return PhotoViewGalleryPageOptions(
///       imageProvider: AssetImage(widget.galleryItems[index].image),
///       initialScale: PhotoViewComputedScale.contained * 0.8,
///       minScale: PhotoViewComputedScale.contained * 0.8,
///       maxScale: PhotoViewComputedScale.covered * 1.1,
///       heroAttributes: HeroAttributes(tag: galleryItems[index].id),
///     );
///   },
///   itemCount: galleryItems.length,
///   loadingBuilder: (context, progress) => Center(
///            child: Container(
///              width: 20.0,
///              height: 20.0,
///              child: CircularProgressIndicator(
///                value: _progress == null
///                    ? null
///                    : _progress.cumulativeBytesLoaded /
///                        _progress.expectedTotalBytes,
///              ),
///            ),
///          ),
///   backgroundDecoration: widget.backgroundDecoration,
///   pageController: widget.pageController,
///   onPageChanged: onPageChanged,
/// )
/// ```
class PhotoViewGallery extends StatefulWidget {
  /// Construct a gallery with static items through a list of [PhotoViewGalleryPageOptions].
  const PhotoViewGallery({
    Key? key,
    required this.pageOptions,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.allowImplicitScrolling = false,
    this.pageSnapping = true,
  })  : itemCount = null,
        builder = null,
        super(key: key);

  /// Construct a gallery with dynamic items.
  ///
  /// The builder must return a [PhotoViewGalleryPageOptions].
  const PhotoViewGallery.builder({
    Key? key,
    required this.itemCount,
    required this.builder,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.wantKeepAlive = false,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.allowImplicitScrolling = false,
    this.pageSnapping = true,
  })  : pageOptions = null,
        assert(itemCount != null),
        assert(builder != null),
        super(key: key);

  /// A list of options to describe the items in the gallery
  final List<PhotoViewGalleryPageOptions>? pageOptions;

  /// The count of items in the gallery, only used when constructed via [PhotoViewGallery.builder]
  final int? itemCount;

  /// Called to build items for the gallery when using [PhotoViewGallery.builder]
  final PhotoViewGalleryBuilder? builder;

  /// [ScrollPhysics] for the internal [PageView]
  final ScrollPhysics? scrollPhysics;

  /// Mirror to [PhotoView.loadingBuilder]
  final LoadingBuilder? loadingBuilder;

  /// Mirror to [PhotoView.backgroundDecoration]
  final BoxDecoration? backgroundDecoration;

  /// Mirror to [PhotoView.wantKeepAlive]
  final bool wantKeepAlive;

  /// Mirror to [PhotoView.gaplessPlayback]
  final bool gaplessPlayback;

  /// Mirror to [PageView.reverse]
  final bool reverse;

  /// An object that controls the [PageView] inside [PhotoViewGallery]
  final PageController? pageController;

  /// An callback to be called on a page change
  final PhotoViewGalleryPageChangedCallback? onPageChanged;

  /// Mirror to [PhotoView.scaleStateChangedCallback]
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  /// Mirror to [PhotoView.enableRotation]
  final bool enableRotation;

  /// Mirror to [PhotoView.customSize]
  final Size? customSize;

  /// The axis along which the [PageView] scrolls. Mirror to [PageView.scrollDirection]
  final Axis scrollDirection;

  /// When user attempts to move it to the next element, focus will traverse to the next page in the page view.
  final bool allowImplicitScrolling;

  final bool pageSnapping;

  bool get _isBuilder => builder != null;

  @override
  State<StatefulWidget> createState() {
    return _PhotoViewGalleryState();
  }
}

class _PhotoViewGalleryState extends State<PhotoViewGallery> with SingleTickerProviderStateMixin{
  late final PageController _controller;
  bool _isScaled = false; // 확대 상태를 추적하는 변수
  Offset _offset = Offset.zero;
  double _dragDistance = 0.0;
  bool _isVerticalDrag = false;
  final double _dragThreshold = 100.0;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  Tween<Offset> _offsetTween = Tween(begin: Offset.zero, end: Offset.zero);

  @override
  void initState() {
    super.initState();

    _controller = widget.pageController ?? PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // 복귀 애니메이션 지속시간
    );
    _offsetAnimation = _offsetAnimation = _offsetTween.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut, // <-- 천천히 부드럽게 끝나는 곡선
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setPhotoViewMode();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    FirstsetMode;
    super.dispose();
  }

  static Future<void> setPhotoViewMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static Future<void> FirstsetMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    // 확대 상태가 변경될 때 호출되는 콜백
    setState(() {
      _isScaled = scaleState != PhotoViewScaleState.initial;
    });

    if (widget.scaleStateChangedCallback != null) {
      widget.scaleStateChangedCallback!(scaleState);
    }
  }

  // 확대 상태에 따라 다른 물리 효과를 반환
  ScrollPhysics _getScrollPhysics() {
    if (_isScaled) {
      // 확대된 상태에서는 스크롤 불가
      return const NeverScrollableScrollPhysics();
    }
    // 기본 상태에서는 원래의 물리 효과 사용
    return widget.scrollPhysics ?? const PageScrollPhysics();
  }

  int get actualPage {
    return _controller.hasClients ? _controller.page!.floor() : 0;
  }

  int get itemCount {
    if (widget._isBuilder) {
      return widget.itemCount!;
    }
    return widget.pageOptions!.length;
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGestureDetectorScope(
      axis: widget.scrollDirection,
      child: PageView.builder(
        reverse: widget.reverse,
        controller: _controller,
        onPageChanged: widget.onPageChanged,
        itemCount: itemCount,
        itemBuilder: _buildItem,
        scrollDirection: widget.scrollDirection,
        physics: _getScrollPhysics(), // 확대 상태에 따라 다른 물리 효과 적용
        allowImplicitScrolling: widget.allowImplicitScrolling,
        pageSnapping: widget.pageSnapping,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final pageOption = _buildPageOption(context, index);
    final isCustomChild = pageOption.child != null;

    if(_isScaled)
      return GestureDetector(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final currentOffset = _isVerticalDrag
                ? _offset
                : _offsetAnimation.value;

            return Transform.translate(
                offset: currentOffset,
                child: ClipRect(
                  child: isCustomChild
                      ? PhotoView.customChild(
                    key: ObjectKey(index),
                    child: pageOption.child,
                    childSize: pageOption.childSize,
                    backgroundDecoration: widget.backgroundDecoration,
                    wantKeepAlive: widget.wantKeepAlive,
                    controller: pageOption.controller,
                    scaleStateController: pageOption.scaleStateController,
                    customSize: widget.customSize,
                    heroAttributes: pageOption.heroAttributes,
                    scaleStateChangedCallback: scaleStateChangedCallback,
                    enableRotation: widget.enableRotation,
                    initialScale: pageOption.initialScale,
                    minScale: pageOption.minScale,
                    maxScale: pageOption.maxScale,
                    scaleStateCycle: pageOption.scaleStateCycle,
                    onTapUp: pageOption.onTapUp,
                    onTapDown: pageOption.onTapDown,
                    onScaleEnd: pageOption.onScaleEnd,
                    gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
                    tightMode: pageOption.tightMode,
                    filterQuality: pageOption.filterQuality,
                    basePosition: pageOption.basePosition,
                    disableGestures: pageOption.disableGestures,
                  )
                      : PhotoView(
                    key: ObjectKey(index),
                    imageProvider: pageOption.imageProvider,
                    loadingBuilder: widget.loadingBuilder,
                    backgroundDecoration: widget.backgroundDecoration,
                    wantKeepAlive: widget.wantKeepAlive,
                    controller: pageOption.controller,
                    scaleStateController: pageOption.scaleStateController,
                    customSize: widget.customSize,
                    semanticLabel: pageOption.semanticLabel,
                    gaplessPlayback: widget.gaplessPlayback,
                    heroAttributes: pageOption.heroAttributes,
                    scaleStateChangedCallback: scaleStateChangedCallback,
                    enableRotation: widget.enableRotation,
                    initialScale: pageOption.initialScale,
                    minScale: pageOption.minScale,
                    maxScale: pageOption.maxScale,
                    scaleStateCycle: pageOption.scaleStateCycle,
                    onTapUp: pageOption.onTapUp,
                    onTapDown: pageOption.onTapDown,
                    onScaleEnd: pageOption.onScaleEnd,
                    gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
                    tightMode: pageOption.tightMode,
                    filterQuality: pageOption.filterQuality,
                    basePosition: pageOption.basePosition,
                    disableGestures: pageOption.disableGestures,
                    errorBuilder: pageOption.errorBuilder,
                  ),
                )
            );
          },
        ),
      );

    else return GestureDetector(
      onVerticalDragStart: (details) {
        if (!_isScaled) {
          setState(() {
            _isVerticalDrag = true;
            _dragDistance = 0.0;

            // 애니메이션이 진행 중이면, 멈추고 현재 위치를 가져온다
            if (_animationController.isAnimating) {
              _animationController.stop();
              _offset = _offsetAnimation.value; // 현재 애니메이션 위치로 이어받기
            }
          });
        }
      },
      onVerticalDragUpdate: (details) {
        if (!_isScaled && _isVerticalDrag) {
          setState(() {
            _dragDistance += details.delta.dy;
            _offset = Offset(0, _dragDistance);
          });
        }
      },
      onVerticalDragEnd: (details) {
        if (!_isScaled && _isVerticalDrag) {
          if (_dragDistance.abs() > _dragThreshold) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _isVerticalDrag = false;
              _offsetTween = Tween(begin: _offset, end: Offset.zero);
              _offsetAnimation = _offsetTween.animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                ),
              );
              _animationController
                ..value = 0.0
                ..forward();
            });
          }
        }
      },
      onVerticalDragCancel: () {
        if (!_isScaled && _isVerticalDrag) {
          setState(() {
            _isVerticalDrag = false;
            _offsetTween = Tween(begin: _offset, end: Offset.zero);
            _animationController
              ..value = 0.0
              ..forward();
          });
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final currentOffset = _isVerticalDrag
              ? _offset
              : _offsetAnimation.value;

          return Transform.translate(
            offset: currentOffset,
            child: ClipRect(
              child: isCustomChild
                  ? PhotoView.customChild(
                key: ObjectKey(index),
                child: pageOption.child,
                childSize: pageOption.childSize,
                backgroundDecoration: widget.backgroundDecoration,
                wantKeepAlive: widget.wantKeepAlive,
                controller: pageOption.controller,
                scaleStateController: pageOption.scaleStateController,
                customSize: widget.customSize,
                heroAttributes: pageOption.heroAttributes,
                scaleStateChangedCallback: scaleStateChangedCallback,
                enableRotation: widget.enableRotation,
                initialScale: pageOption.initialScale,
                minScale: pageOption.minScale,
                maxScale: pageOption.maxScale,
                scaleStateCycle: pageOption.scaleStateCycle,
                onTapUp: pageOption.onTapUp,
                onTapDown: pageOption.onTapDown,
                onScaleEnd: pageOption.onScaleEnd,
                gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
                tightMode: pageOption.tightMode,
                filterQuality: pageOption.filterQuality,
                basePosition: pageOption.basePosition,
                disableGestures: pageOption.disableGestures,
              )
                  : PhotoView(
                key: ObjectKey(index),
                imageProvider: pageOption.imageProvider,
                loadingBuilder: widget.loadingBuilder,
                backgroundDecoration: widget.backgroundDecoration,
                wantKeepAlive: widget.wantKeepAlive,
                controller: pageOption.controller,
                scaleStateController: pageOption.scaleStateController,
                customSize: widget.customSize,
                semanticLabel: pageOption.semanticLabel,
                gaplessPlayback: widget.gaplessPlayback,
                heroAttributes: pageOption.heroAttributes,
                scaleStateChangedCallback: scaleStateChangedCallback,
                enableRotation: widget.enableRotation,
                initialScale: pageOption.initialScale,
                minScale: pageOption.minScale,
                maxScale: pageOption.maxScale,
                scaleStateCycle: pageOption.scaleStateCycle,
                onTapUp: pageOption.onTapUp,
                onTapDown: pageOption.onTapDown,
                onScaleEnd: pageOption.onScaleEnd,
                gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
                tightMode: pageOption.tightMode,
                filterQuality: pageOption.filterQuality,
                basePosition: pageOption.basePosition,
                disableGestures: pageOption.disableGestures,
                errorBuilder: pageOption.errorBuilder,
              ),
            )
          );
        },
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildPageOption(
      BuildContext context, int index) {
    if (widget._isBuilder) {
      return widget.builder!(context, index);
    }
    return widget.pageOptions![index];
  }
}

/// A helper class that wraps individual options of a page in [PhotoViewGallery]
///
/// The [maxScale], [minScale] and [initialScale] options may be [double] or a [PhotoViewComputedScale] constant
///
class PhotoViewGalleryPageOptions {
  PhotoViewGalleryPageOptions({
    Key? key,
    required this.imageProvider,
    this.heroAttributes,
    this.semanticLabel,
    this.minScale,
    this.maxScale,
    this.initialScale,
    this.controller,
    this.scaleStateController,
    this.basePosition,
    this.scaleStateCycle,
    this.onTapUp,
    this.onTapDown,
    this.onScaleEnd,
    this.gestureDetectorBehavior,
    this.tightMode,
    this.filterQuality,
    this.disableGestures,
    this.errorBuilder,
  })  : child = null,
        childSize = null,
        assert(imageProvider != null);

  PhotoViewGalleryPageOptions.customChild({
    required this.child,
    this.semanticLabel,
    this.childSize,
    this.heroAttributes,
    this.minScale,
    this.maxScale,
    this.initialScale,
    this.controller,
    this.scaleStateController,
    this.basePosition,
    this.scaleStateCycle,
    this.onTapUp,
    this.onTapDown,
    this.onScaleEnd,
    this.gestureDetectorBehavior,
    this.tightMode,
    this.filterQuality,
    this.disableGestures,
  })  : errorBuilder = null,
        imageProvider = null;

  /// Mirror to [PhotoView.imageProvider]
  final ImageProvider? imageProvider;

  /// Mirror to [PhotoView.heroAttributes]
  final PhotoViewHeroAttributes? heroAttributes;

  /// Mirror to [PhotoView.semanticLabel]
  final String? semanticLabel;

  /// Mirror to [PhotoView.minScale]
  final dynamic minScale;

  /// Mirror to [PhotoView.maxScale]
  final dynamic maxScale;

  /// Mirror to [PhotoView.initialScale]
  final dynamic initialScale;

  /// Mirror to [PhotoView.controller]
  final PhotoViewController? controller;

  /// Mirror to [PhotoView.scaleStateController]
  final PhotoViewScaleStateController? scaleStateController;

  /// Mirror to [PhotoView.basePosition]
  final Alignment? basePosition;

  /// Mirror to [PhotoView.child]
  final Widget? child;

  /// Mirror to [PhotoView.childSize]
  final Size? childSize;

  /// Mirror to [PhotoView.scaleStateCycle]
  final ScaleStateCycle? scaleStateCycle;

  /// Mirror to [PhotoView.onTapUp]
  final PhotoViewImageTapUpCallback? onTapUp;

  /// Mirror to [PhotoView.onTapDown]
  final PhotoViewImageTapDownCallback? onTapDown;

  /// Mirror to [PhotoView.onScaleEnd]
  final PhotoViewImageScaleEndCallback? onScaleEnd;

  /// Mirror to [PhotoView.gestureDetectorBehavior]
  final HitTestBehavior? gestureDetectorBehavior;

  /// Mirror to [PhotoView.tightMode]
  final bool? tightMode;

  /// Mirror to [PhotoView.disableGestures]
  final bool? disableGestures;

  /// Quality levels for image filters.
  final FilterQuality? filterQuality;

  /// Mirror to [PhotoView.errorBuilder]
  final ImageErrorWidgetBuilder? errorBuilder;
}
