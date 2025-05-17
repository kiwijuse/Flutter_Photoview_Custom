import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'photo_view_hit_corners.dart';

class PhotoViewGestureDetector extends StatelessWidget {
  const PhotoViewGestureDetector({
    Key? key,
    this.hitDetector,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onDoubleTap,
    this.child,
    this.onTapUp,
    this.onTapDown,
    this.behavior,
  }) : super(key: key);

  final GestureDoubleTapCallback? onDoubleTap;
  final HitCornersDetector? hitDetector;

  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;

  final GestureTapUpCallback? onTapUp;
  final GestureTapDownCallback? onTapDown;

  final Widget? child;

  final HitTestBehavior? behavior;

  @override
  Widget build(BuildContext context) {
    final scope = PhotoViewGestureDetectorScope.of(context);

    final Axis? axis = scope?.axis;

    final Map<Type, GestureRecognizerFactory> gestures =
    <Type, GestureRecognizerFactory>{};

    if (onTapDown != null || onTapUp != null) {
      gestures[TapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(debugOwner: this),
                (TapGestureRecognizer instance) {
              instance
                ..onTapDown = onTapDown
                ..onTapUp = onTapUp;
            },
          );
    }

    gestures[DoubleTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
              () => DoubleTapGestureRecognizer(debugOwner: this),
              (DoubleTapGestureRecognizer instance) {
            instance..onDoubleTap = onDoubleTap;
          },
        );

    gestures[PhotoViewGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<PhotoViewGestureRecognizer>(
              () => PhotoViewGestureRecognizer(
              hitDetector: hitDetector, debugOwner: this, validateAxis: axis),
              (PhotoViewGestureRecognizer instance) {
            instance
              ..dragStartBehavior = DragStartBehavior.start
              ..onStart = onScaleStart
              ..onUpdate = onScaleUpdate
              ..onEnd = onScaleEnd;
          },
        );

    return RawGestureDetector(
      behavior: behavior,
      child: child,
      gestures: gestures,
    );
  }
}

class PhotoViewGestureRecognizer extends ScaleGestureRecognizer {
  PhotoViewGestureRecognizer({
    this.hitDetector,
    Object? debugOwner,
    this.validateAxis,
  }) : super(debugOwner: debugOwner); // `kind` 파라미터 제거

  final HitCornersDetector? hitDetector;
  final Axis? validateAxis;

  Map<int, Offset> _pointerLocations = <int, Offset>{};
  Offset? _initialFocalPoint;
  Offset? _currentFocalPoint;
  Offset? _tabDown; // 탭 다운 위치 저장

  bool ready = true;

  @override
  void addAllowedPointer(PointerDownEvent event) { // `PointerDownEvent`로 변경
    if (ready) {
      ready = false;
      _pointerLocations = <int, Offset>{};
    }
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    ready = true;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (validateAxis != null) {
      _computeEvent(event);
      _updateDistances();
      _decideIfWeAcceptEvent(event);
    }
    super.handleEvent(event);
  }

  void _computeEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (!event.synthesized) {
        _pointerLocations[event.pointer] = event.position;
      }
    } else if (event is PointerDownEvent) {
      _pointerLocations[event.pointer] = event.position;
      _tabDown = event.position; // 탭 다운 위치 저장
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
    }

    _initialFocalPoint = _currentFocalPoint;
  }

  void _updateDistances() {
    final int count = _pointerLocations.keys.length;
    Offset focalPoint = Offset.zero;
    for (int pointer in _pointerLocations.keys) {
      focalPoint += _pointerLocations[pointer]!;
    }
    _currentFocalPoint =
    count > 0 ? focalPoint / count.toDouble() : Offset.zero;
  }

  void _decideIfWeAcceptEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _tabDown = event.position; // 탭 다운 위치 저장
      return;
    }

    if (event is PointerMoveEvent) {
      // 탭 다운 위치와 현재 위치의 거리 계산
      final double distance = (_tabDown! - event.position).distance;

      // 거리가 임계값 이내인 경우 더블탭으로 간주
      const double doubleTapThreshold = 10.0; // 픽셀 단위 (조정 가능)
      if (distance <= doubleTapThreshold) {
        return; // 이동으로 간주하지 않음
      }

      final move = _initialFocalPoint! - _currentFocalPoint!;
      final bool shouldMove = hitDetector?.shouldMove(move, validateAxis!) ?? false;

      if (shouldMove || _pointerLocations.keys.length > 1) {
        acceptGesture(event.pointer);
      }
    }
  }
}
/// An [InheritedWidget] responsible to give a axis aware scope to [PhotoViewGestureRecognizer].
///
/// When using this, PhotoView will test if the content zoomed has hit edge every time user pinches,
/// if so, it will let parent gesture detectors win the gesture arena
///
/// Useful when placing PhotoView inside a gesture sensitive context,
/// such as [PageView], [Dismissible], [BottomSheet].
///
/// Usage example:
/// ```
/// PhotoViewGestureDetectorScope(
///   axis: Axis.vertical,
///   child: PhotoView(
///     imageProvider: AssetImage("assets/pudim.jpg"),
///   ),
/// );
/// ```
class PhotoViewGestureDetectorScope extends InheritedWidget {
  PhotoViewGestureDetectorScope({
    this.axis,
    required Widget child,
  }) : super(child: child);

  static PhotoViewGestureDetectorScope? of(BuildContext context) {
    final PhotoViewGestureDetectorScope? scope = context
        .dependOnInheritedWidgetOfExactType<PhotoViewGestureDetectorScope>();
    return scope;
  }

  final Axis? axis;

  @override
  bool updateShouldNotify(PhotoViewGestureDetectorScope oldWidget) {
    return axis != oldWidget.axis;
  }
}
