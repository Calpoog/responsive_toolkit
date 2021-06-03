# flutter_responsive

A flutter package for simplifying responsive layout changes.

Flutter's goal is to allow us to build software for any screen. Mobile
development typically depends on separate templates for varying screen sizes.
The web has to deal with even more screen size scenarios using CSS breakpoints.
Flutter Responsive provides you with tools to create responsive layouts
for any number of screen sizes and with whatever size names you prefer.

## Installation

Add `flutter_responsive` to your list of dependencies in `pubspec.yaml`

```yaml
dependencies:
    flutter_responsive:
```

## Usage

### `ResponsiveLayout` Widget
To start building different layouts depending on the screen size, use the
`ResponsiveLayout` widget. This allows you to specify separate Widgets to
render for each of the provided screen sizes (breakpoints).

```dart
// Import the package
import 'package:flutter_responsive/flutter_responsive.dart';

//  Use responsive layout widget
ResponsiveLayout(
    xs: Text('xs'),
    sm: Text('sm'),
    md: Text('md'),
    lg: Text('lg'),
    xl: Text('xl'),
    xxl: Text('xxl'),
)
```

The default breakpoints used for xs through xxl are as follows:
* xs:  < 576
* sm:  >= 578
* md:  >= 768
* lg:  >= 992
* xl:  >= 1200
* xxl: >= 1400

Not all breakpoints need to be specified. The smallest size `xs` *must* be provided, as
it is always the fallback Widget when the screen width does not match another breakpoint.
When a sceen width falls in the range of a size that was not provided, the next smallest
size and Widget are used. In other words, the breakpoints match >= to the widths specified
above, up to the width of the next provided breakpoint. In the following example, a screen size
of 900px would use the Widget provided for the `xs` screen size:
```dart
ResponsiveLayout(
    xs: Text('xs'), // < 992
    lg: Text('lg'), // >= 992
    xl: Text('xl'), // >= 1200
)
```

In some scenarios there may be a one-off width at which you need to adjust your layout without
adding a new breakpoint to the existing 6. You can accomplish this using the `custom` argument.
This argument is a mapping of `int` screen widths (using a >= calculation) to Widget for display.
```dart
ResponsiveLayout(
    xs: Text('xs'), // < 456
    lg: Text('lg'), // >= 992
    xl: Text('xl'), // >= 1200
    custom: {
        456: Text('>= 456'),
    },
)
```

Because all of the Widgets provided as arguments are constructed before `ResponsiveLayout` but only
one is displayed, you may want to use `WidgetBuilder`s for performance reasons. In this case,
use the named constructor `ResponsiveLayout.builder`. The builder is not called until a breakpoint
has been chosen so only one Widget will ever be constructed when the layout updates.
```dart
ResponsiveLayout.builder(
    xs: (BuildContext context) => Text('xs'), // < 456
    lg: (BuildContext context) => Text('lg'), // >= 992
    xl: (BuildContext context) => Text('xl'), // >= 1200
    custom: {
        456: (BuildContext context) => Text('>= 456'),
    },
)
```


### `ResponsiveLayout.value` Utility Method

In many scenarios you won't need a full different layout for the responsive design you are
trying to accomplish. For instance: you may want to change only a `Text` Widget's `fontSize` on
different screen widths. This could create a lot of repeated code:
```dart
ResponsiveLayout(
    xs: Text('Some text', style: TextStyle(fontSize: 10),),
    md: Text('Some text', style: TextStyle(fontSize: 14),),
    xl: Text('Some text', style: TextStyle(fontSize: 18),),
    custom: {
        456: Text('Some text', style: TextStyle(fontSize: 12)),
    },
),
```

In this case, use `ResponsiveLayout.value` to return values of *any* kind based on screen width.
```dart
Text(
    'Some text',
    style: TextStyle(
        fontSize: ResponsiveLayout.value(
            context, // A BuildContext
            xs: 10,
            md: 14,
            xl: 18,
            custom: {456: 12},
        ),
    ),
),
```
Now, only the values that change depending on screen width are calculated with no repeated code.

The `ResponsiveLayout.value` uses the same arguments and size logic as `ResponsiveLayout`.

## Creating your own breakpoints

### Changing widths of existing breakpoints
Most times the names of the existing breakpoints are just fine—but maybe you want to tweak
the screen sizes they are set to. In this simple case, you can override the existing sizes
by setting the `breakpoints` static property on `ResponsiveLayout`. Make sure to do this at
the beginning of your app (e.g your `main()` function)
```dart
void main() {
  ResponsiveLayout.breakpoints = [0, 100, 200, 300, 400, 500];
  runApp(MyApp());
}
```
There *must* be 6 breakpoints using this method, and the first size *must* be `0`.

### Create your own number of breakpoints with custom names and sizes
Sometimes 6 isn't enough. Sometimes you want to rename the sizes and change their widths.
In this case you'll need to create your own class.

The `ResponsiveLayout` is actually an extension of an abstract class that allows for *any*
number of breakpoints. You can extend this abstract class too to create your own names
(and even change the name of the `custom` argument as well). For instance if you wanted
names based on screen sizes identifying device type you could use code similar to `ResponsiveLayout`
and tweak accordingly:
```dart
class MyResponsiveLayout extends BaseResponsiveLayout {
  static final List<int> breakpoints = [0, 200, 600, 900]; // ** removed ResponsiveLayout bp requirement checks

  MyResponsiveLayout({
    required Widget watch,                  // **
    Widget? phone,                          // **
    Widget? tablet,                         // **
    Widget? desktop,                        // **
    Map<int, Widget>? custom,
    Key? key,
  }) : super(
          [watch, phone, tablet, desktop],  // **
          breakpoints,
          custom: custom,
          key: key,
        );

  MyResponsiveLayout.builder({
    required WidgetBuilder watch,           // **
    WidgetBuilder? phone,                   // **
    WidgetBuilder? tablet,                  // **
    WidgetBuilder? desktop,                 // **
    Map<int, WidgetBuilder>? custom,
    Key? key,
  }) : super.builder(
          [watch, phone, tablet, desktop],  // **
          breakpoints,
          custom: custom,
          key: key,
        );

  static T value<T>(
    BuildContext context, {
    required T watch,                       // **
    T? phone,                               // **
    T? tablet,                              // **
    T? desktop,                             // **
    Map<int, T>? custom,
  }) {
    return _choose(
      breakpoints,
      [watch, phone, tablet, desktop],      // **
      MediaQuery.of(context).size.width,
    );
  }
}
```

and use your new Widget accordingly:
```dart
MyResponsiveLayout(
  watch: Text('Watch'),
  phone: Text('Phone'),
  tablet: Text('Tablet'),
  desktop: Text('Desktop'),
  custom: { 1600: Text('>= 1600') },
);
```
