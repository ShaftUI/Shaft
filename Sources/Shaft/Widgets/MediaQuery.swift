/// Whether in portrait or landscape.
public enum Orientation {
    /// Taller than wide.
    case portrait

    /// Wider than tall.
    case landscape
}

/// Information about a piece of media (e.g., a window).
///
/// For example, the ``MediaQueryData/size`` property contains the width and
/// height of the current window.
///
/// To obtain individual attributes in a ``MediaQueryData``, prefer to use the
/// attribute-specific functions of ``MediaQuery`` over obtaining the entire
/// ``MediaQueryData`` and accessing its members.
/// {@macro flutter.widgets.media_query.MediaQuery.useSpecific}
///
/// To obtain the entire current ``MediaQueryData`` for a given ``BuildContext``,
/// use the ``MediaQuery/of`` function. This can be useful if you are going to use
/// ``copyWith`` to replace the ``MediaQueryData`` with one with an updated
/// property.
///
/// ## Insets and Padding
///
/// ![A diagram of padding, viewInsets, and viewPadding in correlation with each
/// other](https://flutter.github.io/assets-for-api-docs/assets/widgets/media_query.png)
///
/// This diagram illustrates how ``padding`` relates to ``viewPadding`` and
/// ``viewInsets``, shown here in its simplest configuration, as the difference
/// between the two. In cases when the viewInsets exceed the viewPadding, like
/// when a software keyboard is shown below, padding goes to zero rather than a
/// negative value. Therefore, padding is calculated by taking
/// `max(0.0, viewPadding - viewInsets)`.
///
/// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/widgets/window_padding.mp4}
///
/// In this diagram, the black areas represent system UI that the app cannot
/// draw over. The red area represents view padding that the application may not
/// be able to detect gestures in and may not want to draw in. The grey area
/// represents the system keyboard, which can cover over the bottom view padding
/// when visible.
///
/// MediaQueryData includes three [EdgeInsets] values:
/// ``padding``, ``viewPadding``, and ``viewInsets``. These values reflect the
/// configuration of the device and are used and optionally consumed by widgets
/// that position content within these insets. The padding value defines areas
/// that might not be completely visible, like the display "notch" on the iPhone
/// X. The viewInsets value defines areas that aren't visible at all, typically
/// because they're obscured by the device's keyboard. Similar to viewInsets,
/// viewPadding does not differentiate padding in areas that may be obscured.
/// For example, by using the viewPadding property, padding would defer to the
/// iPhone "safe area" regardless of whether a keyboard is showing.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=ceCo8U0XHqw}
///
/// The viewInsets and viewPadding are independent values, they're
/// measured from the edges of the MediaQuery widget's bounds. Together they
/// inform the ``padding`` property. The bounds of the top level MediaQuery
/// created by [WidgetsApp] are the same as the window that contains the app.
///
/// Widgets whose layouts consume space defined by ``viewInsets``, ``viewPadding``,
/// or ``padding`` should enclose their children in secondary MediaQuery
/// widgets that reduce those properties by the same amount.
/// The [removePadding], [removeViewPadding], and [removeViewInsets] methods are
/// useful for this.
///
/// See also:
///
///  * [Scaffold], [SafeArea], [CupertinoTabScaffold], and
///    [CupertinoPageScaffold], all of which are informed by ``padding``,
///    ``viewPadding``, and ``viewInsets``.
public struct MediaQueryData: Equatable {
    /// Creates data for a media query with explicit values.
    ///
    /// In a typical application, calling this constructor directly is rarely
    /// needed. Consider using [MediaQueryData.fromView] to create data based on a
    /// [NativeView], or [MediaQueryData.copyWith] to create a new copy
    /// of ``MediaQueryData`` with updated properties from a base ``MediaQueryData``.
    public init(
        size: Size = .zero,
        devicePixelRatio: Float = 1.0,
        textScaler: any TextScaler = .noScaling,
        platformBrightness: Brightness = .light,
        padding: EdgeInsets = .zero,
        viewInsets: EdgeInsets = .zero,
        systemGestureInsets: EdgeInsets = .zero,
        viewPadding: EdgeInsets = .zero,
        alwaysUse24HourFormat: Bool = false,
        accessibleNavigation: Bool = false,
        invertColors: Bool = false,
        highContrast: Bool = false,
        onOffSwitchLabels: Bool = false,
        disableAnimations: Bool = false,
        boldText: Bool = false,
        navigationMode: NavigationMode = .traditional,
        gestureSettings: DeviceGestureSettings = DeviceGestureSettings(touchSlop: kTouchSlop),
        // displayFeatures: [DisplayFeature] = [],
        supportsShowingSystemContextMenu: Bool = false
    ) {
        self.size = size
        self.devicePixelRatio = devicePixelRatio
        self.textScaler = textScaler
        self.platformBrightness = platformBrightness
        self.padding = padding
        self.viewInsets = viewInsets
        self.systemGestureInsets = systemGestureInsets
        self.viewPadding = viewPadding
        self.alwaysUse24HourFormat = alwaysUse24HourFormat
        self.accessibleNavigation = accessibleNavigation
        self.invertColors = invertColors
        self.highContrast = highContrast
        self.onOffSwitchLabels = onOffSwitchLabels
        self.disableAnimations = disableAnimations
        self.boldText = boldText
        self.navigationMode = navigationMode
        self.gestureSettings = gestureSettings
        // self.displayFeatures = displayFeatures
        self.supportsShowingSystemContextMenu = supportsShowingSystemContextMenu
    }

    /// Creates data for a ``MediaQuery`` based on the given `view`.
    ///
    /// If provided, the `platformData` is used to fill in the platform-specific
    /// aspects of the newly created ``MediaQueryData``. If `platformData` is null,
    /// the `view`'s [PlatformDispatcher] is consulted to construct the
    /// platform-specific data.
    ///
    /// Data which is exposed directly on the [FlutterView] is considered
    /// view-specific. Data which is only exposed via the
    /// [FlutterView.platformDispatcher] property is considered platform-specific.
    ///
    /// Callers of this method should ensure that they also register for
    /// notifications so that the ``MediaQueryData`` can be updated when any data
    /// used to construct it changes. Notifications to consider are:
    ///
    ///  * [WidgetsBindingObserver.didChangeMetrics] or
    ///    [dart:ui.PlatformDispatcher.onMetricsChanged],
    ///  * [WidgetsBindingObserver.didChangeAccessibilityFeatures] or
    ///    [dart:ui.PlatformDispatcher.onAccessibilityFeaturesChanged],
    ///  * [WidgetsBindingObserver.didChangeTextScaleFactor] or
    ///    [dart:ui.PlatformDispatcher.onTextScaleFactorChanged],
    ///  * [WidgetsBindingObserver.didChangePlatformBrightness] or
    ///    [dart:ui.PlatformDispatcher.onPlatformBrightnessChanged].
    ///
    /// The last three notifications are only relevant if no `platformData` is
    /// provided. If `platformData` is provided, callers should ensure to call
    /// this method again when it changes to keep the constructed ``MediaQueryData``
    /// updated.
    ///
    /// In general, ``MediaQuery/of``, and its associated "...Of" methods, are the
    /// appropriate way to obtain ``MediaQueryData`` from a widget. This `fromView`
    /// constructor is primarily for use in the implementation of the framework
    /// itself.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.fromView], which constructs ``MediaQueryData`` from a provided
    ///    [FlutterView], makes it available to descendant widgets, and sets up
    ///    the appropriate notification listeners to keep the data updated.
    public init(from view: NativeView, platformData: MediaQueryData? = nil) {
        self.init(
            size: view.physicalSize / view.devicePixelRatio,
            devicePixelRatio: view.devicePixelRatio,
            textScaler: Self._textScalerFromView(view: view, platformData: platformData),
            // platformBrightness =
            //     platformData?.platformBrightness ?? view.platformDispatcher.platformBrightness
            // padding:EdgeInsets.fromViewPadding(view.padding, view.devicePixelRatio)
            // viewPadding:EdgeInsets.fromViewPadding(view.viewPadding, view.devicePixelRatio)
            // viewInsets:EdgeInsets.fromViewPadding(view.viewInsets, view.devicePixelRatio)
            // systemGestureInsets:EdgeInsets.fromViewPadding(
            //     view.systemGestureInsets,
            //     view.devicePixelRatio
            // )
            // accessibleNavigation =
            //     platformData?.accessibleNavigation
            //     ?? view.platformDispatcher.accessibilityFeatures.accessibleNavigation
            // invertColors =
            //     platformData?.invertColors ?? view.platformDispatcher.accessibilityFeatures.invertColors
            // disableAnimations =
            //     platformData?.disableAnimations
            //     ?? view.platformDispatcher.accessibilityFeatures.disableAnimations
            // boldText:platformData?.boldText ?? view.platformDispatcher.accessibilityFeatures.boldText
            // highContrast =
            //     platformData?.highContrast ?? view.platformDispatcher.accessibilityFeatures.highContrast
            // onOffSwitchLabels =
            //     platformData?.onOffSwitchLabels
            //     ?? view.platformDispatcher.accessibilityFeatures.onOffSwitchLabels
            // alwaysUse24HourFormat =
            //     platformData?.alwaysUse24HourFormat ?? view.platformDispatcher.alwaysUse24HourFormat
            navigationMode: platformData?.navigationMode ?? .traditional
                // gestureSettings:DeviceGestureSettings.fromView(view)
                // displayFeatures:view.displayFeatures
                // supportsShowingSystemContextMenu =
                //     platformData?.supportsShowingSystemContextMenu
                //     ?? view.platformDispatcher.supportsShowingSystemContextMenu
        )
    }

    private static func _textScalerFromView(view: NativeView, platformData: MediaQueryData?)
        -> any TextScaler
    {
        // let scaleFacto = :platformData?.textScaleFactor ?? view.platformDispatcher.textScaleFactor
        // return scaleFactor == 1.0 ? .noScaling : .linear(scaleFactor)
        return .noScaling
    }

    /// The size of the media in logical pixels (e.g, the size of the screen).
    ///
    /// Logical pixels are roughly the same visual size across devices. Physical
    /// pixels are the size of the actual hardware pixels on the device. The
    /// number of physical pixels per logical pixel is described by the
    /// [devicePixelRatio].
    ///
    /// Prefer using [MediaQuery.sizeOf] over ``MediaQuery/of```.size` to get the
    /// size, since the former will only notify of changes in [size], while the
    /// latter will notify for all ``MediaQueryData`` changes.
    ///
    /// For widgets drawn in an [Overlay], do not assume that the size of the
    /// [Overlay] is the size of the ``MediaQuery``'s size. Nested overlays can have
    /// different sizes.
    ///
    /// ## Troubleshooting
    ///
    /// It is considered bad practice to cache and later use the size returned by
    /// `MediaQuery.sizeOf(context)`. It will make the application non-responsive
    /// and might lead to unexpected behaviors.
    ///
    /// For instance, during startup, especially in release mode, the first
    /// returned size might be [Size.zero]. The size will be updated when the
    /// native platform reports the actual resolution. Using [MediaQuery.sizeOf]
    /// will ensure that when the size changes, any widgets depending on the size
    /// are automatically rebuilt.
    ///
    /// See the article on [Creating responsive and adaptive
    /// apps](https://docs.flutter.dev/ui/adaptive-responsive)
    /// for an introduction.
    ///
    /// See also:
    ///
    /// * [FlutterView.physicalSize], which returns the size of the view in physical pixels.
    /// * [FlutterView.display], which returns reports display information like size, and refresh rate.
    /// * [MediaQuery.sizeOf], a method to find and depend on the size defined for
    ///   a ``BuildContext``.
    public let size: Size

    /// The number of device pixels for each logical pixel. This number might not
    /// be a power of two. Indeed, it might not even be an integer. For example,
    /// the Nexus 6 has a device pixel ratio of 3.5.
    public let devicePixelRatio: Float

    /// The font scaling strategy to use for laying out textual contents.
    ///
    /// If this ``MediaQueryData`` is created by the [MediaQueryData.fromView]
    /// constructor, this property reflects the platform's preferred text scaling
    /// strategy, and may change as the user changes the scaling factor in the
    /// operating system's accessibility settings.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.textScalerOf], a method to find and depend on the
    ///    [textScaler] defined for a ``BuildContext``.
    ///  * [TextPainter], a class that lays out and paints text.
    public var textScaler: any TextScaler

    /// The current brightness mode of the host platform.
    ///
    /// For example, starting in Android Pie, battery saver mode asks all apps to
    /// render in a "dark mode".
    ///
    /// Not all platforms necessarily support a concept of brightness mode. Those
    /// platforms will report [Brightness.light] in this property.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.platformBrightnessOf], a method to find and depend on the
    ///    platformBrightness defined for a ``BuildContext``.
    public var platformBrightness: Brightness

    /// The parts of the display that are completely obscured by system UI,
    /// typically by the device's keyboard.
    ///
    /// When a mobile device's keyboard is visible `viewInsets.bottom`
    /// corresponds to the top of the keyboard.
    ///
    /// This value is independent of the ``padding`` and ``viewPadding``. viewPadding
    /// is measured from the edges of the ``MediaQuery`` widget's bounds. Padding is
    /// calculated based on the viewPadding and viewInsets. The bounds of the top
    /// level MediaQuery created by [WidgetsApp] are the same as the window
    /// (often the mobile device screen) that contains the app.
    ///
    /// {@youtube 560 315 https://www.youtube.com/watch?v=ceCo8U0XHqw}
    ///
    /// See also:
    ///
    ///  * [FlutterView], which provides some additional detail about this property
    ///    and how it relates to ``padding`` and ``viewPadding``.
    public var viewInsets: EdgeInsets

    /// The parts of the display that are partially obscured by system UI,
    /// typically by the hardware display "notches" or the system status bar.
    ///
    /// If you consumed this padding (e.g. by building a widget that envelops or
    /// accounts for this padding in its layout in such a way that children are
    /// no longer exposed to this padding), you should remove this padding
    /// for subsequent descendants in the widget tree by inserting a new
    /// ``MediaQuery`` widget using the [MediaQuery.removePadding] factory.
    ///
    /// Padding is derived from the values of ``viewInsets`` and ``viewPadding``.
    ///
    /// {@youtube 560 315 https://www.youtube.com/watch?v=ceCo8U0XHqw}
    ///
    /// See also:
    ///
    ///  * [FlutterView], which provides some additional detail about this
    ///    property and how it relates to ``viewInsets`` and ``viewPadding``.
    ///  * [SafeArea], a widget that consumes this padding with a [Padding] widget
    ///    and automatically removes it from the ``MediaQuery`` for its child.
    public var padding: EdgeInsets

    /// The parts of the display that are partially obscured by system UI,
    /// typically by the hardware display "notches" or the system status bar.
    ///
    /// This value remains the same regardless of whether the system is reporting
    /// other obstructions in the same physical area of the screen. For example, a
    /// software keyboard on the bottom of the screen that may cover and consume
    /// the same area that requires bottom padding will not affect this value.
    ///
    /// This value is independent of the ``padding`` and ``viewInsets``: their values
    /// are measured from the edges of the ``MediaQuery`` widget's bounds. The
    /// bounds of the top level MediaQuery created by [WidgetsApp] are the
    /// same as the window that contains the app. On mobile devices, this will
    /// typically be the full screen.
    ///
    /// {@youtube 560 315 https://www.youtube.com/watch?v=ceCo8U0XHqw}
    ///
    /// See also:
    ///
    ///  * [FlutterView], which provides some additional detail about this
    ///    property and how it relates to ``padding`` and ``viewInsets``.
    public var viewPadding: EdgeInsets

    /// The areas along the edges of the display where the system consumes
    /// certain input events and blocks delivery of those events to the app.
    ///
    /// Starting with Android Q, simple swipe gestures that start within the
    /// [systemGestureInsets] areas are used by the system for page navigation
    /// and may not be delivered to the app. Taps and swipe gestures that begin
    /// with a long-press are delivered to the app, but simple press-drag-release
    /// swipe gestures which begin within the area defined by [systemGestureInsets]
    /// may not be.
    ///
    /// Apps should avoid locating gesture detectors within the system gesture
    /// insets area. Apps should feel free to put visual elements within
    /// this area.
    ///
    /// This property is currently only expected to be set to a non-default value
    /// on Android starting with version Q.
    ///
    /// {@tool dartpad}
    /// For apps that might be deployed on Android Q devices with full gesture
    /// navigation enabled, use [systemGestureInsets] with [Padding]
    /// to avoid having the left and right edges of the [Slider] from appearing
    /// within the area reserved for system gesture navigation.
    ///
    /// By default, [Slider]s expand to fill the available width. So, we pad the
    /// left and right sides.
    ///
    /// ** See code in examples/api/lib/widgets/media_query/media_query_data.system_gesture_insets.0.dart **
    /// {@end-tool}
    public var systemGestureInsets: EdgeInsets

    /// Whether to use 24-hour format when formatting time.
    ///
    /// The behavior of this flag is different across platforms:
    ///
    /// - On Android this flag is reported directly from the user settings called
    ///   "Use 24-hour format". It applies to any locale used by the application,
    ///   whether it is the system-wide locale, or the custom locale set by the
    ///   application.
    /// - On iOS this flag is set to true when the user setting called "24-Hour
    ///   Time" is set or the system-wide locale's default uses 24-hour
    ///   formatting.
    public var alwaysUse24HourFormat: Bool

    /// Whether the user is using an accessibility service like TalkBack or
    /// VoiceOver to interact with the application.
    ///
    /// When this setting is true, features such as timeouts should be disabled or
    /// have minimum durations increased.
    ///
    /// See also:
    ///
    ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting originates.
    public var accessibleNavigation: Bool

    /// Whether the device is inverting the colors of the platform.
    ///
    /// This flag is currently only updated on iOS devices.
    ///
    /// See also:
    ///
    ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
    ///    originates.
    public var invertColors: Bool

    /// Whether the user requested a high contrast between foreground and background
    /// content on iOS, via Settings -> Accessibility -> Increase Contrast.
    ///
    /// This flag is currently only updated on iOS devices that are running iOS 13
    /// or above.
    public var highContrast: Bool

    /// Whether the user requested to show on/off labels inside switches on iOS,
    /// via Settings -> Accessibility -> Display & Text Size -> On/Off Labels.
    ///
    /// See also:
    ///
    ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
    ///    originates.
    public var onOffSwitchLabels: Bool

    /// Whether the platform is requesting that animations be disabled or reduced
    /// as much as possible.
    ///
    /// See also:
    ///
    ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
    ///    originates.
    public var disableAnimations: Bool

    /// Whether the platform is requesting that text be drawn with a bold font
    /// weight.
    ///
    /// See also:
    ///
    ///  * [dart:ui.PlatformDispatcher.accessibilityFeatures], where the setting
    ///    originates.
    public var boldText: Bool

    /// Describes the navigation mode requested by the platform.
    ///
    /// Some user interfaces are better navigated using a directional pad (DPAD)
    /// or arrow keys, and for those interfaces, some widgets need to handle these
    /// directional events differently. In order to know when to do that, these
    /// widgets will look for the navigation mode in effect for their context.
    ///
    /// For instance, in a television interface, [NavigationMode.directional]
    /// should be set, so that directional navigation is used to navigate away
    /// from a text field using the DPAD. In contrast, on a regular desktop
    /// application with the [navigationMode] set to [NavigationMode.traditional],
    /// the arrow keys are used to move the cursor instead of navigating away.
    ///
    /// The [NavigationMode] values indicate the type of navigation to be used in
    /// a widget subtree for those widgets sensitive to it.
    public var navigationMode: NavigationMode

    /// The gesture settings for the view this media query is derived from.
    ///
    /// This contains platform specific configuration for gesture behavior,
    /// such as touch slop. These settings should be favored for configuring
    /// gesture behavior over the framework constants.
    public var gestureSettings: DeviceGestureSettings

    /// {@macro dart.ui.ViewConfiguration.displayFeatures}
    ///
    /// See also:
    ///
    ///  * [dart:ui.DisplayFeatureType], which lists the different types of
    ///  display features and explains the differences between them.
    ///  * [dart:ui.DisplayFeatureState], which lists the possible states for
    ///  folding features ([dart:ui.DisplayFeatureType.fold] and
    ///  [dart:ui.DisplayFeatureType.hinge]).
    // public var displayFeatures: List<ui.DisplayFeature>

    /// Whether showing the system context menu is supported.
    ///
    /// For example, on iOS 16.0 and above, the system text selection context menu
    /// may be shown instead of the Flutter-drawn context menu in order to avoid
    /// the iOS clipboard access notification when the "Paste" button is pressed.
    ///
    /// See also:
    ///
    ///  * [SystemContextMenuController] and [SystemContextMenu], which may be
    ///    used to show the system context menu when this flag indicates it's
    ///    supported.
    public var supportsShowingSystemContextMenu: Bool

    /// The orientation of the media (e.g., whether the device is in landscape or
    /// portrait mode).
    public var orientation: Orientation {
        size.width > size.height ? .landscape : .portrait
    }

    /// Creates a copy of this media query data but with the given ``padding``s
    /// replaced with zero.
    ///
    /// If all four of the `removeLeft`, `removeTop`, `removeRight`, and
    /// `removeBottom` arguments are false (the default), then this
    /// ``MediaQueryData`` is returned unmodified.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.removePadding], which uses this method to remove ``padding``
    ///    from the ambient ``MediaQuery``.
    ///  * [SafeArea], which both removes the padding from the ``MediaQuery`` and
    ///    adds a [Padding] widget.
    ///  * [removeViewInsets], the same thing but for ``viewInsets``.
    ///  * [removeViewPadding], the same thing but for ``viewPadding``.
    public func removePadding(
        removeLeft: Bool = false,
        removeTop: Bool = false,
        removeRight: Bool = false,
        removeBottom: Bool = false
    ) -> MediaQueryData {
        if !(removeLeft || removeTop || removeRight || removeBottom) {
            return self
        }

        var result = self
        result.padding = padding.copyWith(
            left: removeLeft ? 0.0 : padding.left,
            top: removeTop ? 0.0 : padding.top,
            right: removeRight ? 0.0 : padding.right,
            bottom: removeBottom ? 0.0 : padding.bottom
        )
        result.viewPadding = viewPadding.copyWith(
            left: removeLeft ? max(0.0, viewPadding.left - padding.left) : viewPadding.left,
            top: removeTop ? max(0.0, viewPadding.top - padding.top) : viewPadding.top,
            right: removeRight ? max(0.0, viewPadding.right - padding.right) : viewPadding.right,
            bottom: removeBottom
                ? max(0.0, viewPadding.bottom - padding.bottom) : viewPadding.bottom
        )
        return result
    }

    /// Creates a copy of this media query data but with the given ``viewInsets``
    /// replaced with zero.
    ///
    /// If all four of the `removeLeft`, `removeTop`, `removeRight`, and
    /// `removeBottom` arguments are false (the default), then this
    /// ``MediaQueryData`` is returned unmodified.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.removeViewInsets], which uses this method to remove
    ///    ``viewInsets`` from the ambient ``MediaQuery``.
    ///  * [removePadding], the same thing but for ``padding``.
    ///  * [removeViewPadding], the same thing but for ``viewPadding``.
    public func removeViewInsets(
        removeLeft: Bool = false,
        removeTop: Bool = false,
        removeRight: Bool = false,
        removeBottom: Bool = false
    ) -> MediaQueryData {
        if !(removeLeft || removeTop || removeRight || removeBottom) {
            return self
        }
        var result = self
        result.viewPadding = viewPadding.copyWith(
            left: removeLeft ? max(0.0, viewPadding.left - viewInsets.left) : viewPadding.left,
            top: removeTop ? max(0.0, viewPadding.top - viewInsets.top) : viewPadding.top,
            right: removeRight ? max(0.0, viewPadding.right - viewInsets.right) : viewPadding.right,
            bottom: removeBottom
                ? max(0.0, viewPadding.bottom - viewInsets.bottom) : viewPadding.bottom
        )
        result.viewInsets = viewInsets.copyWith(
            left: removeLeft ? 0.0 : viewInsets.left,
            top: removeTop ? 0.0 : viewInsets.top,
            right: removeRight ? 0.0 : viewInsets.right,
            bottom: removeBottom ? 0.0 : viewInsets.bottom
        )
        return result
    }

    /// Creates a copy of this media query data but with the given ``viewPadding``
    /// replaced with zero.
    ///
    /// If all four of the `removeLeft`, `removeTop`, `removeRight`, and
    /// `removeBottom` arguments are false (the default), then this
    /// ``MediaQueryData`` is returned unmodified.
    ///
    /// See also:
    ///
    ///  * [MediaQuery.removeViewPadding], which uses this method to remove
    ///    ``viewPadding`` from the ambient ``MediaQuery``.
    ///  * [removePadding], the same thing but for ``padding``.
    ///  * [removeViewInsets], the same thing but for ``viewInsets``.
    public func removeViewPadding(
        removeLeft: Bool = false,
        removeTop: Bool = false,
        removeRight: Bool = false,
        removeBottom: Bool = false
    ) -> MediaQueryData {
        if !(removeLeft || removeTop || removeRight || removeBottom) {
            return self
        }
        var result = self
        result.padding = padding.copyWith(
            left: removeLeft ? 0.0 : padding.left,
            top: removeTop ? 0.0 : padding.top,
            right: removeRight ? 0.0 : padding.right,
            bottom: removeBottom ? 0.0 : padding.bottom
        )
        result.viewPadding = viewPadding.copyWith(
            left: removeLeft ? 0.0 : viewPadding.left,
            top: removeTop ? 0.0 : viewPadding.top,
            right: removeRight ? 0.0 : viewPadding.right,
            bottom: removeBottom ? 0.0 : viewPadding.bottom
        )
        return result
    }

    /// Creates a copy of this media query data by removing [displayFeatures] that
    /// are completely outside the given sub-screen and adjusting the ``padding``,
    /// ``viewInsets`` and ``viewPadding`` to be zero on the sides that are not
    /// included in the sub-screen.
    ///
    /// Returns unmodified ``MediaQueryData`` if the sub-screen coincides with the
    /// available screen space.
    ///
    /// Asserts in debug mode, if the given sub-screen is outside the available
    /// screen space.
    ///
    /// See also:
    ///
    ///  * [DisplayFeatureSubScreen], which removes the display features that
    ///    split the screen, from the ``MediaQuery`` and adds a [Padding] widget to
    ///    position the child to match the selected sub-screen.
    public func removeDisplayFeatures(_ subScreen: Rect) -> MediaQueryData {
        assert(
            subScreen.left >= 0.0 && subScreen.top >= 0.0 && subScreen.right <= size.width
                && subScreen.bottom <= size.height,
            "'subScreen' argument cannot be outside the bounds of the screen"
        )

        if subScreen.size == size && subScreen.topLeft == .zero {
            return self
        }

        let rightInset = size.width - subScreen.right
        let bottomInset = size.height - subScreen.bottom

        var result = self
        result.padding = EdgeInsets(
            left: max(0.0, padding.left - subScreen.left),
            top: max(0.0, padding.top - subScreen.top),
            right: max(0.0, padding.right - rightInset),
            bottom: max(0.0, padding.bottom - bottomInset)
        )
        result.viewPadding = EdgeInsets(
            left: max(0.0, viewPadding.left - subScreen.left),
            top: max(0.0, viewPadding.top - subScreen.top),
            right: max(0.0, viewPadding.right - rightInset),
            bottom: max(0.0, viewPadding.bottom - bottomInset)
        )
        result.viewInsets = EdgeInsets(
            left: max(0.0, viewInsets.left - subScreen.left),
            top: max(0.0, viewInsets.top - subScreen.top),
            right: max(0.0, viewInsets.right - rightInset),
            bottom: max(0.0, viewInsets.bottom - bottomInset)
        )
        // result.displayFeatures = displayFeatures.filter { displayFeature in
        //     subScreen.overlaps(displayFeature.bounds)
        // }
        return result
    }

    public static func == (lhs: MediaQueryData, rhs: MediaQueryData) -> Bool {
        lhs.size == rhs.size && lhs.devicePixelRatio == rhs.devicePixelRatio
            && lhs.textScaler.isEqualTo(rhs.textScaler)
            && lhs.platformBrightness == rhs.platformBrightness
            && lhs.padding == rhs.padding && lhs.viewInsets == rhs.viewInsets
            && lhs.systemGestureInsets == rhs.systemGestureInsets
            && lhs.viewPadding == rhs.viewPadding
            && lhs.alwaysUse24HourFormat == rhs.alwaysUse24HourFormat
            && lhs.accessibleNavigation == rhs.accessibleNavigation
            && lhs.invertColors == rhs.invertColors && lhs.highContrast == rhs.highContrast
            && lhs.onOffSwitchLabels == rhs.onOffSwitchLabels
            && lhs.disableAnimations == rhs.disableAnimations && lhs.boldText == rhs.boldText
            && lhs.navigationMode == rhs.navigationMode
            && lhs.gestureSettings == rhs.gestureSettings
            // lhs.displayFeatures == rhs.displayFeatures &&
            && lhs.supportsShowingSystemContextMenu == rhs.supportsShowingSystemContextMenu
    }
}

/// Establishes a subtree in which media queries resolve to the given data.
///
/// For example, to learn the size of the current view (e.g.,
/// the [FlutterView] containing your app), you can use [MediaQuery.sizeOf]:
/// `MediaQuery.sizeOf(context)`.
///
/// Querying the current media using specific methods (for example,
/// [MediaQuery.sizeOf] or [MediaQuery.paddingOf]) will cause your widget to
/// rebuild automatically whenever that specific property changes.
///
/// {@template flutter.widgets.media_query.MediaQuery.useSpecific}
/// Querying using ``MediaQuery/of`` will cause your widget to rebuild
/// automatically whenever _any_ field of the ``MediaQueryData`` changes (e.g., if
/// the user rotates their device). Therefore, unless you are concerned with the
/// entire ``MediaQueryData`` object changing, prefer using the specific methods
/// (for example: [MediaQuery.sizeOf] and [MediaQuery.paddingOf]), as it will
/// rebuild more efficiently.
///
/// If no ``MediaQuery`` is in scope then ``MediaQuery/of`` and the "...Of" methods
/// similar to [MediaQuery.sizeOf] will throw an exception. Alternatively, the
/// "maybe-" variant methods (such as [MediaQuery.maybeOf] and
/// [MediaQuery.maybeSizeOf]) can be used, which return null, instead of
/// throwing, when no ``MediaQuery`` is in scope.
/// {@endtemplate}
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=A3WrA4zAaPw}
///
/// See also:
///
///  * [WidgetsApp] and [MaterialApp], which introduce a ``MediaQuery`` and keep
///    it up to date with the current screen metrics as they change.
///  * ``MediaQueryData``, the data structure that represents the metrics.
public class MediaQuery: InheritedModel {
    public typealias AspectType = PartialKeyPath<MediaQueryData>

    public let key: (any Key)?

    public let child: any Widget

    /// Creates a widget that provides ``MediaQueryData`` to its descendants.
    public init(
        key: (any Key)? = nil,
        data: MediaQueryData,
        @WidgetBuilder child: () -> Widget
    ) {
        self.key = key
        self.data = data
        self.child = child()
    }

    /// Creates a new ``MediaQuery`` that inherits from the ambient ``MediaQuery``
    /// from the given context, but removes the specified padding.
    ///
    /// This should be inserted into the widget tree when the ``MediaQuery`` padding
    /// is consumed by a widget in such a way that the padding is no longer
    /// exposed to the widget's descendants or siblings.
    ///
    /// The [context] argument must have a ``MediaQuery`` in scope.
    ///
    /// If all four of the `removeLeft`, `removeTop`, `removeRight`, and
    /// `removeBottom` arguments are false (the default), then the returned
    /// ``MediaQuery`` reuses the ambient ``MediaQueryData`` unmodified, which is not
    /// particularly useful.
    ///
    /// See also:
    ///
    ///  * [SafeArea], which both removes the padding from the ``MediaQuery`` and
    ///    adds a [Padding] widget.
    ///  * [MediaQueryData.padding], the affected property of the
    ///    ``MediaQueryData``.
    ///  * [MediaQuery.removeViewInsets], the same thing but for [MediaQueryData.viewInsets].
    ///  * [MediaQuery.removeViewPadding], the same thing but for
    ///    [MediaQueryData.viewPadding].
    public static func removePadding(
        key: (any Key)? = nil,
        context: BuildContext,
        removeLeft: Bool = false,
        removeTop: Bool = false,
        removeRight: Bool = false,
        removeBottom: Bool = false,
        @WidgetBuilder child: () -> Widget
    ) -> MediaQuery {
        MediaQuery(
            key: key,
            data: MediaQuery.of(context).removePadding(
                removeLeft: removeLeft,
                removeTop: removeTop,
                removeRight: removeRight,
                removeBottom: removeBottom
            ),
            child: child
        )
    }

    /// Creates a new ``MediaQuery`` that inherits from the ambient ``MediaQuery``
    /// from the given context, but removes the specified view insets.
    ///
    /// This should be inserted into the widget tree when the ``MediaQuery`` view
    /// insets are consumed by a widget in such a way that the view insets are no
    /// longer exposed to the widget's descendants or siblings.
    ///
    /// The [context] argument must have a ``MediaQuery`` in scope.
    ///
    /// If all four of the `removeLeft`, `removeTop`, `removeRight`, and
    /// `removeBottom` arguments are false (the default), then the returned
    /// ``MediaQuery`` reuses the ambient ``MediaQueryData`` unmodified, which is not
    /// particularly useful.
    ///
    /// See also:
    ///
    ///  * [MediaQueryData.viewInsets], the affected property of the
    ///    ``MediaQueryData``.
    ///  * [MediaQuery.removePadding], the same thing but for [MediaQueryData.padding].
    ///  * [MediaQuery.removeViewPadding], the same thing but for
    ///    [MediaQueryData.viewPadding].
    public static func removeViewInsets(
        key: (any Key)? = nil,
        context: BuildContext,
        removeLeft: Bool = false,
        removeTop: Bool = false,
        removeRight: Bool = false,
        removeBottom: Bool = false,
        @WidgetBuilder child: () -> Widget
    ) -> MediaQuery {
        MediaQuery(
            key: key,
            data: MediaQuery.of(context).removeViewInsets(
                removeLeft: removeLeft,
                removeTop: removeTop,
                removeRight: removeRight,
                removeBottom: removeBottom
            ),
            child: child
        )
    }

    /// Creates a new ``MediaQuery`` that inherits from the ambient ``MediaQuery``
    /// from the given context, but removes the specified view padding.
    ///
    /// This should be inserted into the widget tree when the ``MediaQuery`` view
    /// padding is consumed by a widget in such a way that the view padding is no
    /// longer exposed to the widget's descendants or siblings.
    ///
    /// The [context] argument must have a ``MediaQuery`` in scope.
    ///
    /// If all four of the `removeLeft`, `removeTop`, `removeRight`, and
    /// `removeBottom` arguments are false (the default), then the returned
    /// ``MediaQuery`` reuses the ambient ``MediaQueryData`` unmodified, which is not
    /// particularly useful.
    ///
    /// See also:
    ///
    ///  * [MediaQueryData.viewPadding], the affected property of the
    ///    ``MediaQueryData``.
    ///  * [MediaQuery.removePadding], the same thing but for [MediaQueryData.padding].
    ///  * [MediaQuery.removeViewInsets], the same thing but for [MediaQueryData.viewInsets].
    public static func removeViewPadding(
        key: (any Key)? = nil,
        context: BuildContext,
        removeLeft: Bool = false,
        removeTop: Bool = false,
        removeRight: Bool = false,
        removeBottom: Bool = false,
        @WidgetBuilder child: () -> Widget
    ) -> MediaQuery {
        MediaQuery(
            key: key,
            data: MediaQuery.of(context).removeViewPadding(
                removeLeft: removeLeft,
                removeTop: removeTop,
                removeRight: removeRight,
                removeBottom: removeBottom
            ),
            child: child
        )
    }

    // /// Wraps the [child] in a ``MediaQuery`` which is built using data from the
    // /// provided [view].
    // ///
    // /// The ``MediaQuery`` is constructed using the platform-specific data of the
    // /// surrounding ``MediaQuery`` and the view-specific data of the provided
    // /// [view]. If no surrounding ``MediaQuery`` exists, the platform-specific data
    // /// is generated from the [PlatformDispatcher] associated with the provided
    // /// [view]. Any information that's exposed via the [PlatformDispatcher] is
    // /// considered platform-specific. Data exposed directly on the [FlutterView]
    // /// (excluding its [FlutterView.platformDispatcher] property) is considered
    // /// view-specific.
    // ///
    // /// The injected ``MediaQuery`` automatically updates when any of the data used
    // /// to construct it changes.
    // public static func fromView(
    //     key: (any Key)? = nil,
    //     view: NativeView,
    //     @WidgetBuilder child: () -> Widget
    // ) -> Widget {
    //     _MediaQueryFromView(
    //         key: key,
    //         view: view,
    //         child: child()
    //     )
    // }

    /// Wraps the `child` in a ``MediaQuery`` with its [MediaQueryData.textScaler]
    /// set to [TextScaler.noScaling].
    ///
    /// The returned widget must be inserted in a widget tree below an existing
    /// ``MediaQuery`` widget.
    ///
    /// This can be used to prevent, for example, icon fonts from scaling as the
    /// user adjusts the platform's text scaling value.
    public static func withNoTextScaling(
        key: (any Key)? = nil,
        @WidgetBuilder child: () -> Widget
    ) -> Widget {
        func noScaling(_ context: BuildContext) -> MediaQueryData {
            assert(debugCheckHasMediaQuery(context))
            var data = MediaQuery.of(context)
            data.textScaler = .noScaling
            return data
        }
        let child = child()
        return Builder(key: key) { context in
            MediaQuery(data: noScaling(context)) {
                child
            }
        }
    }

    // /// Wraps the `child` in a ``MediaQuery`` and applies [TextScaler.clamp] on the
    // /// current [MediaQueryData.textScaler].
    // ///
    // /// The returned widget must be inserted in a widget tree below an existing
    // /// ``MediaQuery`` widget.
    // ///
    // /// This is a convenience function to restrict the range of the scaled text
    // /// size to `[minScaleFactor * fontSize, maxScaleFactor * fontSize]` (to
    // /// prevent excessive text scaling that would break the UI, for example). When
    // /// `minScaleFactor` equals `maxScaleFactor`, the scaler becomes
    // /// `TextScaler.linear(minScaleFactor)`.
    // public static func withClampedTextScaling(
    //     key: (any Key)? = nil,
    //     minScaleFactor: Double = 0.0,
    //     maxScaleFactor: Double = .infinity,
    //     @WidgetBuilder child: () -> Widget
    // ) -> Widget {
    //     assert(maxScaleFactor >= minScaleFactor)
    //     assert(!maxScaleFactor.isNaN)
    //     assert(minScaleFactor.isFinite)
    //     assert(minScaleFactor >= 0)

    //     func clamp(_ context: BuildContext) -> MediaQueryData {
    //         assert(debugCheckHasMediaQuery(context))
    //         var data = MediaQuery.of(context)
    //         data.textScaler = data.textScaler.clamp(
    //             minScaleFactor: minScaleFactor,
    //             maxScaleFactor: maxScaleFactor
    //         )
    //         return data
    //     }
    //     return Builder(key: key) { context in
    //         MediaQuery(data: clamp(context)) {
    //             child()
    //         }
    //     }
    // }

    /// Contains information about the current media.
    ///
    /// For example, the ``MediaQueryData/size`` property contains the width and
    /// height of the current window.
    public let data: MediaQueryData

    /// The data from the closest instance of this class that encloses the given
    /// context.
    ///
    /// You can use this function to query the entire set of data held in the
    /// current ``MediaQueryData`` object. When any of that information changes,
    /// your widget will be scheduled to be rebuilt, keeping your widget
    /// up-to-date.
    ///
    /// Since it is typical that the widget only requires a subset of properties
    /// of the ``MediaQueryData`` object, prefer using the more specific methods
    /// (for example: [MediaQuery.sizeOf] and [MediaQuery.paddingOf]), as those
    /// methods will not cause a widget to rebuild when unrelated properties are
    /// updated.
    ///
    /// Typical usage is as follows:
    ///
    /// ```swift
    /// let media = MediaQuery.of(context)
    /// ```
    ///
    /// If there is no ``MediaQuery`` in scope, this method will throw a [TypeError]
    /// exception in release builds, and throw a descriptive [FlutterError] in
    /// debug builds.
    ///
    /// See also:
    ///
    /// * [maybeOf], which doesn't throw or assert if it doesn't find a
    ///   ``MediaQuery`` ancestor. It returns null instead.
    /// * [sizeOf] and other specific methods for retrieving and depending on
    ///   changes of a specific value.
    public static func of(_ context: BuildContext) -> MediaQueryData {
        Self._of(context)
    }

    private static func _of(_ context: BuildContext, aspect: PartialKeyPath<MediaQueryData>? = nil)
        -> MediaQueryData
    {
        assert(debugCheckHasMediaQuery(context))
        return Self.inheritFrom(MediaQuery.self, context: context, aspect: aspect)!.data
    }

    /// The data from the closest instance of this class that encloses the given
    /// context, if any.
    ///
    /// Use this function if you want to allow situations where no ``MediaQuery`` is
    /// in scope. Prefer using ``MediaQuery/of`` in situations where a media query
    /// is always expected to exist.
    ///
    /// If there is no ``MediaQuery`` in scope, then this function will return null.
    ///
    /// You can use this function to query the entire set of data held in the
    /// current ``MediaQueryData`` object. When any of that information changes,
    /// your widget will be scheduled to be rebuilt, keeping your widget
    /// up-to-date.
    ///
    /// Since it is typical that the widget only requires a subset of properties
    /// of the ``MediaQueryData`` object, prefer using the more specific methods
    /// (for example: [MediaQuery.maybeSizeOf] and [MediaQuery.maybePaddingOf]),
    /// as those methods will not cause a widget to rebuild when unrelated
    /// properties are updated.
    ///
    /// Typical usage is as follows:
    ///
    /// ```swift
    /// let mediaQuery = MediaQuery.maybeOf(context)
    /// if mediaQuery == nil {
    ///   // Do something else instead.
    /// }
    /// ```
    ///
    /// See also:
    ///
    /// * [of], which will throw if it doesn't find a ``MediaQuery`` ancestor,
    ///   instead of returning null.
    /// * [maybeSizeOf] and other specific methods for retrieving and depending on
    ///   changes of a specific value.
    public static func maybeOf(_ context: BuildContext) -> MediaQueryData? {
        Self._maybeOf(context)
    }

    private static func _maybeOf(
        _ context: BuildContext,
        aspect: PartialKeyPath<MediaQueryData>? = nil
    )
        -> MediaQueryData?
    {
        Self.inheritFrom(MediaQuery.self, context: context, aspect: aspect)?.data
    }

    /// Returns ``MediaQueryData/size`` from the nearest ``MediaQuery`` ancestor or
    /// throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the ``MediaQueryData/size`` property of the ancestor ``MediaQuery`` changes.
    ///
    /// Prefer using this function over getting the attribute directly from the
    /// ``MediaQueryData`` returned from [of], because using this function will only
    /// rebuild the `context` when this specific attribute changes, not when _any_
    /// attribute changes.
    public static func sizeOf(_ context: BuildContext) -> Size {
        Self._of(context, aspect: \.size).size
    }

    /// Returns ``MediaQueryData/size`` from the nearest ``MediaQuery`` ancestor or
    /// null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the ``MediaQueryData/size`` property of the ancestor ``MediaQuery`` changes.
    ///
    /// Prefer using this function over getting the attribute directly from the
    /// ``MediaQueryData`` returned from [maybeOf], because using this function will
    /// only rebuild the `context` when this specific attribute changes, not when
    /// _any_ attribute changes.
    public static func maybeSizeOf(_ context: BuildContext) -> Size? {
        Self._maybeOf(context, aspect: \.size)?.size
    }

    /// Returns [MediaQueryData.orientation] for the nearest ``MediaQuery`` ancestor or
    /// throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.orientation] property of the ancestor ``MediaQuery`` changes.
    public static func orientationOf(_ context: BuildContext) -> Orientation {
        Self._of(context, aspect: \.orientation).orientation
    }
    /// Returns [MediaQueryData.orientation] for the nearest ``MediaQuery`` ancestor or
    /// null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.orientation] property of the ancestor ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeOrientationOf(_ context: BuildContext) -> Orientation? {
        Self._maybeOf(context, aspect: \.orientation)?.orientation
    }

    /// Returns [MediaQueryData.devicePixelRatio] for the nearest ``MediaQuery`` ancestor or
    /// throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.devicePixelRatio] property of the ancestor ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func devicePixelRatioOf(_ context: BuildContext) -> Float {
        Self._of(context, aspect: \.devicePixelRatio).devicePixelRatio
    }

    /// Returns [MediaQueryData.devicePixelRatio] for the nearest ``MediaQuery`` ancestor or
    /// null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.devicePixelRatio] property of the ancestor ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeDevicePixelRatioOf(_ context: BuildContext) -> Float? {
        Self._maybeOf(context, aspect: \.devicePixelRatio)?.devicePixelRatio
    }

    /// Returns the [MediaQueryData.textScaler] for the nearest ``MediaQuery``
    /// ancestor or [TextScaler.noScaling] if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.textScaler] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func textScalerOf(_ context: BuildContext) -> any TextScaler {
        Self._of(context, aspect: \.textScaler).textScaler
    }

    /// Returns the [MediaQueryData.textScaler] for the nearest ``MediaQuery``
    /// ancestor or null if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.textScaler] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeTextScalerOf(_ context: BuildContext) -> (any TextScaler)? {
        Self._maybeOf(context, aspect: \.textScaler)?.textScaler
    }

    /// Returns [MediaQueryData.platformBrightness] for the nearest ``MediaQuery``
    /// ancestor or [Brightness.light], if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.platformBrightness] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func platformBrightnessOf(_ context: BuildContext) -> Brightness {
        maybePlatformBrightnessOf(context) ?? .light
    }

    /// Returns [MediaQueryData.platformBrightness] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.platformBrightness] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybePlatformBrightnessOf(_ context: BuildContext) -> Brightness? {
        Self._maybeOf(context, aspect: \.platformBrightness)?.platformBrightness
    }

    /// Returns [MediaQueryData.padding] for the nearest ``MediaQuery`` ancestor or
    /// throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.padding] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func paddingOf(_ context: BuildContext) -> EdgeInsets {
        Self._of(context, aspect: \.padding).padding
    }

    /// Returns [MediaQueryData.padding] for the nearest ``MediaQuery`` ancestor
    /// or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.padding] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybePaddingOf(_ context: BuildContext) -> EdgeInsets? {
        Self._maybeOf(context, aspect: \.padding)?.padding
    }

    /// Returns [MediaQueryData.viewInsets] for the nearest ``MediaQuery`` ancestor
    /// or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.viewInsets] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func viewInsetsOf(_ context: BuildContext) -> EdgeInsets {
        Self._of(context, aspect: \.viewInsets).viewInsets
    }

    /// Returns [MediaQueryData.viewInsets] for the nearest ``MediaQuery`` ancestor
    /// or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.viewInsets] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeViewInsetsOf(_ context: BuildContext) -> EdgeInsets? {
        Self._maybeOf(context, aspect: \.viewInsets)?.viewInsets
    }

    /// Returns [MediaQueryData.systemGestureInsets] for the nearest ``MediaQuery``
    /// ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.systemGestureInsets] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func systemGestureInsetsOf(_ context: BuildContext) -> EdgeInsets {
        Self._of(context, aspect: \.systemGestureInsets).systemGestureInsets
    }

    /// Returns [MediaQueryData.systemGestureInsets] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.systemGestureInsets] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeSystemGestureInsetsOf(_ context: BuildContext) -> EdgeInsets? {
        Self._maybeOf(context, aspect: \.systemGestureInsets)?.systemGestureInsets
    }

    /// Returns [MediaQueryData.viewPadding] for the nearest ``MediaQuery`` ancestor
    /// or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.viewPadding] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func viewPaddingOf(_ context: BuildContext) -> EdgeInsets {
        Self._of(context, aspect: \.viewPadding).viewPadding
    }

    /// Returns [MediaQueryData.viewPadding] for the nearest ``MediaQuery`` ancestor
    /// or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.viewPadding] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeViewPaddingOf(_ context: BuildContext) -> EdgeInsets? {
        Self._maybeOf(context, aspect: \.viewPadding)?.viewPadding
    }

    /// Returns [MediaQueryData.alwaysUse24HourFormat] for the nearest
    /// ``MediaQuery`` ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.alwaysUse24HourFormat] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func alwaysUse24HourFormatOf(_ context: BuildContext) -> Bool {
        Self._of(context, aspect: \.alwaysUse24HourFormat).alwaysUse24HourFormat
    }

    /// Returns [MediaQueryData.alwaysUse24HourFormat] for the nearest
    /// ``MediaQuery`` ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.alwaysUse24HourFormat] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeAlwaysUse24HourFormatOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.alwaysUse24HourFormat)?.alwaysUse24HourFormat
    }

    /// Returns [MediaQueryData.accessibleNavigation] for the nearest ``MediaQuery``
    /// ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.accessibleNavigation] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func accessibleNavigationOf(_ context: BuildContext) -> Bool {
        Self._of(context, aspect: \.accessibleNavigation).accessibleNavigation
    }

    /// Returns [MediaQueryData.accessibleNavigation] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.accessibleNavigation] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeAccessibleNavigationOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.accessibleNavigation)?.accessibleNavigation
    }

    /// Returns [MediaQueryData.invertColors] for the nearest ``MediaQuery``
    /// ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.invertColors] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func invertColorsOf(_ context: BuildContext) -> Bool {
        Self._of(context, aspect: \.invertColors).invertColors
    }

    /// Returns [MediaQueryData.invertColors] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.invertColors] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeInvertColorsOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.invertColors)?.invertColors
    }

    /// Returns [MediaQueryData.highContrast] for the nearest ``MediaQuery``
    /// ancestor or false, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.highContrast] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func highContrastOf(_ context: BuildContext) -> Bool {
        maybeHighContrastOf(context) ?? false
    }

    /// Returns [MediaQueryData.highContrast] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.highContrast] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeHighContrastOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.highContrast)?.highContrast
    }

    /// Returns [MediaQueryData.onOffSwitchLabels] for the nearest ``MediaQuery``
    /// ancestor or false, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.onOffSwitchLabels] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func onOffSwitchLabelsOf(_ context: BuildContext) -> Bool {
        maybeOnOffSwitchLabelsOf(context) ?? false
    }

    /// Returns [MediaQueryData.onOffSwitchLabels] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.onOffSwitchLabels] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeOnOffSwitchLabelsOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.onOffSwitchLabels)?.onOffSwitchLabels
    }

    /// Returns [MediaQueryData.disableAnimations] for the nearest ``MediaQuery``
    /// ancestor or false, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.disableAnimations] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func disableAnimationsOf(_ context: BuildContext) -> Bool {
        Self._of(context, aspect: \.disableAnimations).disableAnimations
    }

    /// Returns [MediaQueryData.disableAnimations] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.disableAnimations] property of the ancestor
    /// ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeDisableAnimationsOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.disableAnimations)?.disableAnimations
    }

    /// Returns the [MediaQueryData.boldText] accessibility setting for the
    /// nearest ``MediaQuery`` ancestor or false, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.boldText] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func boldTextOf(_ context: BuildContext) -> Bool {
        maybeBoldTextOf(context) ?? false
    }

    /// Returns the [MediaQueryData.boldText] accessibility setting for the
    /// nearest ``MediaQuery`` ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.boldText] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeBoldTextOf(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.boldText)?.boldText
    }

    /// Returns [MediaQueryData.navigationMode] for the nearest ``MediaQuery``
    /// ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.navigationMode] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func navigationModeOf(_ context: BuildContext) -> NavigationMode {
        Self._of(context, aspect: \.navigationMode).navigationMode
    }

    /// Returns [MediaQueryData.navigationMode] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.navigationMode] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeNavigationModeOf(_ context: BuildContext) -> NavigationMode? {
        Self._maybeOf(context, aspect: \.navigationMode)?.navigationMode
    }

    /// Returns [MediaQueryData.gestureSettings] for the nearest ``MediaQuery``
    /// ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.gestureSettings] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func gestureSettingsOf(_ context: BuildContext) -> DeviceGestureSettings {
        Self._of(context, aspect: \.gestureSettings).gestureSettings
    }

    /// Returns [MediaQueryData.gestureSettings] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.gestureSettings] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeGestureSettingsOf(_ context: BuildContext) -> DeviceGestureSettings? {
        Self._maybeOf(context, aspect: \.gestureSettings)?.gestureSettings
    }

    /// Returns [MediaQueryData.displayFeatures] for the nearest ``MediaQuery``
    /// ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.displayFeatures] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    // public static func displayFeaturesOf(_ context: BuildContext) -> [DisplayFeature] {
    //     Self._of(context, aspect: \.displayFeatures).displayFeatures
    // }

    /// Returns [MediaQueryData.displayFeatures] for the nearest ``MediaQuery``
    /// ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.displayFeatures] property of the ancestor ``MediaQuery``
    /// changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    // public static func maybeDisplayFeaturesOf(_ context: BuildContext) -> [DisplayFeature]? {
    //     Self._maybeOf(context, aspect: \.displayFeatures)?.displayFeatures
    // }

    /// Returns [MediaQueryData.supportsShowingSystemContextMenu] for the nearest
    /// ``MediaQuery`` ancestor or throws an exception, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.supportsShowingSystemContextMenu] property of the
    /// ancestor ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseOf}
    public static func supportsShowingSystemContextMenu(_ context: BuildContext) -> Bool {
        Self._of(context, aspect: \.supportsShowingSystemContextMenu)
            .supportsShowingSystemContextMenu
    }

    /// Returns [MediaQueryData.supportsShowingSystemContextMenu] for the nearest
    /// ``MediaQuery`` ancestor or null, if no such ancestor exists.
    ///
    /// Use of this method will cause the given [context] to rebuild any time that
    /// the [MediaQueryData.supportsShowingSystemContextMenu] property of the
    /// ancestor ``MediaQuery`` changes.
    ///
    /// {@macro flutter.widgets.media_query.MediaQuery.dontUseMaybeOf}
    public static func maybeSupportsShowingSystemContextMenu(_ context: BuildContext) -> Bool? {
        Self._maybeOf(context, aspect: \.supportsShowingSystemContextMenu)?
            .supportsShowingSystemContextMenu
    }

    public func updateShouldNotify(_ oldWidget: MediaQuery) -> Bool {
        data != oldWidget.data
    }

    public func updateShouldNotifyDependent(
        _ oldWidget: ProxyWidget,
        _ dependencies: Set<PartialKeyPath<MediaQueryData>>
    ) -> Bool {
        let oldWidget = oldWidget as! Self
        return dependencies.contains { dependency in
            return switch dependency {
            case \.size:
                data.size != oldWidget.data.size
            case \.orientation:
                data.orientation != oldWidget.data.orientation
            case \.devicePixelRatio:
                data.devicePixelRatio != oldWidget.data.devicePixelRatio
            case \.textScaler:
                !data.textScaler.isEqualTo(oldWidget.data.textScaler)
            case \.platformBrightness:
                data.platformBrightness != oldWidget.data.platformBrightness
            case \.padding:
                data.padding != oldWidget.data.padding
            case \.viewInsets:
                data.viewInsets != oldWidget.data.viewInsets
            case \.viewPadding:
                data.viewPadding != oldWidget.data.viewPadding
            case \.invertColors:
                data.invertColors != oldWidget.data.invertColors
            case \.highContrast:
                data.highContrast != oldWidget.data.highContrast
            case \.onOffSwitchLabels:
                data.onOffSwitchLabels != oldWidget.data.onOffSwitchLabels
            case \.disableAnimations:
                data.disableAnimations != oldWidget.data.disableAnimations
            case \.boldText:
                data.boldText != oldWidget.data.boldText
            case \.navigationMode:
                data.navigationMode != oldWidget.data.navigationMode
            case \.gestureSettings:
                data.gestureSettings != oldWidget.data.gestureSettings
            // case \.displayFeatures:
            //     data.displayFeatures != oldWidget.data.displayFeatures
            case \.systemGestureInsets:
                data.systemGestureInsets != oldWidget.data.systemGestureInsets
            case \.accessibleNavigation:
                data.accessibleNavigation != oldWidget.data.accessibleNavigation
            case \.alwaysUse24HourFormat:
                data.alwaysUse24HourFormat != oldWidget.data.alwaysUse24HourFormat
            case \.supportsShowingSystemContextMenu:
                data.supportsShowingSystemContextMenu
                    != oldWidget.data.supportsShowingSystemContextMenu
            default:
                false
            }
        }
    }
}

/// Describes the navigation mode to be set by a ``MediaQuery`` widget.
///
/// The different modes indicate the type of navigation to be used in a widget
/// subtree for those widgets sensitive to it.
///
/// Use `MediaQuery.navigationModeOf(context)` to determine the navigation mode
/// in effect for the given context. Use a ``MediaQuery`` widget to set the
/// navigation mode for its descendant widgets.
public enum NavigationMode {
    /// This indicates a traditional keyboard-and-mouse navigation modality.
    ///
    /// This navigation mode is where the arrow keys can be used for secondary
    /// modification operations, like moving sliders or cursors, and disabled
    /// controls will lose focus and not be traversable.
    case traditional

    /// This indicates a directional-based navigation mode.
    ///
    /// This navigation mode indicates that arrow keys should be reserved for
    /// navigation operations, and secondary modifications operations, like moving
    /// sliders or cursors, will use alternative bindings or be disabled.
    ///
    /// Some behaviors are also affected by this mode. For instance, disabled
    /// controls will retain focus when disabled, and will be able to receive
    /// focus (although they remain disabled) when traversed.
    case directional
}
