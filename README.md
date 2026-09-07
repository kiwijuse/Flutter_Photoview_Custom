# Flutter_Photoview_Custom

[`bluefireteam/photo_view`](https://github.com/bluefireteam/photo_view) **0.15.0** 의 포크입니다.
여행 앱 [여행하게](https://github.com/kiwijuse/yeohaenghage)의 커뮤니티 사진 뷰어를 만들면서 필요했던 세 가지를 넣었습니다.

원본 대비 바뀐 파일은 두 개입니다.

| 파일 | 무엇을 |
|---|---|
| `lib/photo_view_gallery.dart` | 쓸어내려 닫기 · 확대 중 페이지 넘김 차단 |
| `lib/src/core/photo_view_gesture_detector.dart` | 손가락 떨림에 죽던 더블탭 |

나머지 13개 파일은 원본 그대로입니다.

---

## 1. 쓸어내려 닫기

원본 `PhotoViewGallery`에는 **세로 방향 제스처를 받는 코드가 없습니다.** `PageView.builder`가 좌우 넘김만 처리하고, `GestureDetector` 자체가 트리에 없습니다.

사진을 아래로 내려 닫는 동작을 넣으려면 갤러리가 **지금 이 사진이 확대돼 있는지**를 알아야 합니다. 확대돼 있으면 세로 드래그는 사진을 옮기는 동작이고, 원래 크기면 닫는 동작이기 때문입니다. 그런데 확대 배율은 사진 한 장을 그리는 안쪽 `PhotoView`가 들고 있어서 갤러리는 알 수 없습니다.

새 콜백을 만들어 배선을 새로 깔지 않고, 이미 갤러리를 지나가던 `scaleStateChangedCallback`을 **길목에서 가로채 읽고 원래 받을 사람에게 다시 넘기는** 방식으로 풀었습니다.

```dart
void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
  setState(() {
    _isScaled = scaleState != PhotoViewScaleState.initial;
  });

  if (widget.scaleStateChangedCallback != null) {
    widget.scaleStateChangedCallback!(scaleState);   // 원래 받을 사람에게 그대로
  }
}
```

쓰는 쪽에서 보면 달라진 것이 없습니다. 직접 등록한 콜백은 그대로 불리고, 갤러리가 그 앞에서 한 번 들여다볼 뿐입니다. `scaleStateChangedCallback`을 넘기지 않아도 쓸어내려 닫기는 동작합니다.

내린 거리가 `_dragThreshold`(100)를 넘으면 `Navigator.pop`, 못 미치면 `Curves.easeOut`으로 제자리에 돌아갑니다. 되돌아가는 애니메이션이 도는 중에 다시 잡으면 그 시점 위치를 새 출발점으로 이어받습니다.

```dart
if (_animationController.isAnimating) {
  _animationController.stop();
  _offset = _offsetAnimation.value;   // 지금 있는 자리에서 이어받는다
}
```

## 2. 손가락 떨림에 죽던 더블탭

두 번 두드려 확대하는 동작이 **미동 없이 정확히 같은 자리를 눌렀을 때만** 먹혔습니다.

한 화면에 제스처 인식기가 여럿 붙어 있고, 그중 하나가 "이건 내 제스처다"라고 선언하면 나머지는 물러납니다. 원본은 손가락이 움직였다는 신호가 오면 곧바로 확대 제스처로 확정합니다.

```dart
// 원본
void _decideIfWeAcceptEvent(PointerEvent event) {
  if (!(event is PointerMoveEvent)) return;
  final move = _initialFocalPoint! - _currentFocalPoint!;
  final bool shouldMove = hitDetector!.shouldMove(move, validateAxis!);
  if (shouldMove || _pointerLocations.keys.length > 1) {
    acceptGesture(event.pointer);
  }
}
```

사람 손가락은 화면에 닿는 순간에도 몇 픽셀씩 흔들립니다. 그 흔들림이 "움직였다"로 잡히면 확대 인식기가 제스처를 가져가 버리고, 두 번째 탭은 두드리기 인식기까지 도달하지 못합니다.

누른 자리를 기억해 두고 **거기서 10픽셀 안쪽이면 움직이지 않은 것으로 칩니다.**

```dart
if (event is PointerDownEvent) {
  _tabDown = event.position;
  return;
}

if (event is PointerMoveEvent) {
  final double distance = (_tabDown! - event.position).distance;

  const double doubleTapThreshold = 10.0;
  if (distance <= doubleTapThreshold) {
    return;   // 흔들린 것이지 움직인 게 아니다
  }
  ...
}
```

Flutter도 스크롤 시작 판단에 `kTouchSlop`(18)이라는 같은 종류의 여유값을 씁니다.

## 3. 확대 중 페이지가 넘어가던 문제

확대한 사진을 옆으로 밀어 가장자리를 보려고 하면 **다음 사진으로 넘어가 버렸습니다.** 확대 상태에서는 페이지 스크롤을 막았습니다.

```dart
ScrollPhysics _getScrollPhysics() {
  if (_isScaled) {
    return const NeverScrollableScrollPhysics();
  }
  return widget.scrollPhysics ?? const PageScrollPhysics();
}
```

같은 `_isScaled` 값 하나가 세로 드래그 수용 여부 · 좌우 페이지 스크롤 · 위젯 트리 분기를 한꺼번에 가릅니다.

---

## 쓰는 법

```yaml
dependencies:
  photo_view:
    git:
      url: https://github.com/kiwijuse/Flutter_Photoview_Custom.git
```

패키지 이름과 공개 API는 원본과 같습니다. `import 'package:photo_view/photo_view.dart';` 그대로 쓰면 됩니다.

## 알아둘 것

깃 주소로 가져오는 순간 **원본 업데이트가 자동으로 오지 않습니다.** 원본에 버그가 고쳐지거나 새 Flutter 버전 대응이 들어와도 손으로 합쳐야 합니다.

## 원본

[bluefireteam/photo_view](https://github.com/bluefireteam/photo_view) · 0.15.0 기준 · 원본 라이선스([MIT](LICENSE))를 그대로 따릅니다.

만들면서 어떤 순서로 원인을 찾았는지는 [여행하게 회고 — 포크한 라이브러리](https://github.com/kiwijuse/yeohaenghage/blob/main/docs/09-forked-libraries.md)에 적어 뒀습니다.
