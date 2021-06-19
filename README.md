# responsive_toolkit

[![responsive_toolkit](https://img.shields.io/badge/responsive-toolkit-brightgreen.svg)](https://github.com/Calpoog/responsive_toolkit)
[![Pub release](https://img.shields.io/pub/v/responsive_toolkit.svg)](https://pub.dev/packages/responsive_toolkit)
[![GitHub Release Date](https://img.shields.io/github/release-date/Calpoog/responsive_toolkit.svg)](https://github.com/Calpoog/responsive_toolkit)
[![GitHub issues](https://img.shields.io/github/issues/Calpoog/responsive_toolkit.svg)](https://github.com/Calpoog/responsive_toolkit/issues)
[![GitHub top language](https://img.shields.io/github/languages/top/Calpoog/responsive_toolkit.svg)](https://github.com/Calpoog/responsive_toolkit)
[![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/Calpoog/responsive_toolkit.svg)](https://github.com/Calpoog/responsive_toolkit)
[![Libraries.io for GitHub](https://img.shields.io/librariesio/github/Calpoog/responsive_toolkit.svg)](https://libraries.io/github/Calpoog/responsive_toolkit)
[![License](https://img.shields.io/github/license/Calpoog/responsive_toolkit)](https://libraries.io/github/Calpoog/responsive_toolkit)

A flutter package for simplifying responsive layout changes.

Flutter's goal is to allow us to build software for any screen. Mobile
development typically depends on separate templates for varying screen sizes.
The web has to deal with even more screen size scenarios using CSS breakpoints.
Flutter Responsive provides you with tools to create responsive layouts
for any number of screen sizes and with whatever size names you prefer.

<br /><br />
<img src="https://user-images.githubusercontent.com/3476942/120811952-8c623500-c51a-11eb-9fe1-8816e5358ea3.gif" width="100%" />

## Installation

Add `responsive_toolkit` to your list of dependencies in `pubspec.yaml`

```yaml
dependencies:
  responsive_toolkit:
```

## Responsive layouts

### `ResponsiveLayout` Widget

To start building different layouts depending on the screen size, use the
`ResponsiveLayout` widget. This allows you to specify separate Widgets to
render for each of the provided screen sizes (breakpoints). All responsive
utilities use the `Breakpoints` class to specify the mapping from breakpoint
sizes to other values and Widgets.

```dart
// Import the package
import 'package:responsive_toolkit/responsive_toolkit.dart';

//  Use responsive layout widget
ResponsiveLayout(
    Breakpoints(
        xs: Text('xs'),
        sm: Text('sm'),
        md: Text('md'),
        lg: Text('lg'),
        xl: Text('xl'),
        xxl: Text('xxl'),
    ),
)
```

The default breakpoints used for xs through xxl are as follows:

- xs: < 576
- sm: >= 576
- md: >= 768
- lg: >= 992
- xl: >= 1200
- xxl: >= 1400

Not all breakpoints need to be specified. The smallest size `xs` _must_ be provided, as
it is always the fallback Widget when the screen width does not match another breakpoint.
When a screen width falls in the range of a size that was not provided, the next smallest
size and Widget are used. In other words, the breakpoints match >= to the widths specified
above, up to the width of the next provided breakpoint. In the following example, a screen size
of 900px would use the Widget provided for the `xs` screen size:

```dart
ResponsiveLayout(
    Breakpoints(
        xs: Text('xs'), // < 992
        lg: Text('lg'), // >= 992
        xl: Text('xl'), // >= 1200
    ),
)
```

In some scenarios there may be a one-off width at which you need to adjust your layout without
adding a new breakpoint to the existing 6. You can accomplish this using the `custom` argument.
This argument is a mapping of `int` screen widths (using a >= calculation) to Widget for display.

```dart
ResponsiveLayout(
    Breakpoints(
        xs: Text('xs'), // < 456
        lg: Text('lg'), // >= 992
        xl: Text('xl'), // >= 1200
        custom: {
            456: Text('>= 456'),
        },
    ),
)
```

Because all of the Widgets provided as arguments are constructed before `ResponsiveLayout` but only
one is displayed, you may want to use `WidgetBuilder`s for performance reasons. In this case,
use the named constructor `ResponsiveLayout.builder`. The builder is not called until a breakpoint
has been chosen so only one Widget will ever be constructed when the layout updates.

```dart
ResponsiveLayout.builder(
    Breakpoints(
        xs: (BuildContext context) => Text('xs'), // < 456
        lg: (BuildContext context) => Text('lg'), // >= 992
        xl: (BuildContext context) => Text('xl'), // >= 1200
        custom: {
            456: (BuildContext context) => Text('>= 456'),
        },
    ),
)
```

<br /><br />

### `ResponsiveLayout.value` Utility Method

In many scenarios you won't need a full different layout for the responsive design you are
trying to accomplish. For instance: you may want to change only a `Text` Widget's `fontSize` on
different screen widths. This could create a lot of repeated code:

```dart
ResponsiveLayout(
    Breakpoints(
        xs: Text('Some text', style: TextStyle(fontSize: 10),),
        md: Text('Some text', style: TextStyle(fontSize: 14),),
        xl: Text('Some text', style: TextStyle(fontSize: 18),),
        custom: {
            456: Text('Some text', style: TextStyle(fontSize: 12)),
        },
    ),
),
```

In this case, use `ResponsiveLayout.value` to return values of _any_ kind based on screen width.

```dart
Text(
    'Some text',
    style: TextStyle(
        fontSize: ResponsiveLayout.value(
            context, // A BuildContext
            Breakpoints(
                xs: 10,
                md: 14,
                xl: 18,
                custom: {456: 12},
            ),
        ),
    ),
),
```

Now, only the values that change depending on screen width are calculated with no repeated code.

If you'd like to make a choice between multiple values based on screen size without
`ResponsiveLayout.value` you can also use the `choose` method on the `Breakpoints` class. In
this case you can control what width is used for the choice more explicitly.

```dart
final int fontSize = Breakpoints(
    xs: 10,
    md: 14,
    xl: 18,
    custom: {456: 12},
).choose(MediaQuery.of(context).size.width);
```

### Controlling the breakpoint axis

Up until this point we've mostly talked about screen sizes in terms of width (this is most common).
However, you may want to control layout in the vertical axis as well. `ResponsiveLayout`,
`ResponsiveLayout.builder` and `ResponsiveLayout.value` all support an `axis` argument. This
defaults to `Axis.horizontal` (breakpoints on screen width), but you can also use
`Axis.vertical` to have your breakpoints operate on screen height. Usually you'll have different
expectations for what sizes breakpoints use in the vertical axis. Because cases like this are more
rare, you may be able to just use the `custom` argument. If you need to use different breakpoints for
the vertical axis more frequently, consider creating your own as shown in
[creating your own breakpoints](#creating-your-own-breakpoints).

```dart
ResponsiveLayout(
    Breakpoints(
        xs: ..., // xs still required (covers 0-300)
        custom: {
            300: ...,
            500: ...,
        }
    ),
    axis: Axis.vertical,
),
```

<br /><br />

## Using contraints instead of screen size

It may make sense for some layouts to be dependent on their allotted max width or height. In this
case you can use `ResponsiveConstraintLayout` that has an API much like `ResponsiveLayout`
(there is no `.value()` utility method).
However, the `ResponsiveConstraintLayout` chooses which Widget to display using the breakpoints
based on the constraints (max width or height) passed to it from parent Widgets. This can be quite
useful in scenarios where you may not know where a Widget will be placed and therefore can't know
what sizes it may be expected to display correctly in. If your Widget starts looking bad when
displayed less than 300px wide – you can control that explicitly.

```dart
ResponsiveConstraintLayout(
    Breakpoints(
        xs: ...,
        custom: {
            300: ...,
            500: ...,
        }
    ),
),
```

<br /><br />

## Creating your own breakpoints

Sometimes 6 isn't enough. Sometimes you want to rename the sizes and change their widths.
In this case you'll need to create your own class.

The `Breakpoints` class is actually an extension of another class that allows for _any_
number of breakpoints. You can extend this base class to create your own names and sizes
(you can even change the name of the `custom` argument or eliminate it entirely to enforce a design system).
For instance if you wanted names based on screen sizes identifying device type you can copy
`Breakpoints` code and tweak accordingly:

```dart
class MyBreakpoints<T> extends BaseBreakpoints<T> {
  MyBreakpoints({
    required T watch,                                   // **
    T? phone,                                           // **
    T? tablet,                                          // **
    T? desktop,                                         // **
    Map<int, T>? custom,
  }) : super(
          breakpoints: [0, 200, 600, 900],              // **
          values: [watch, phone, tablet, desktop],      // **
          custom: custom,
        );
}
```

and use your new Widget accordingly with `ResponsiveLayout` (including `.builder` and `.value`):

```dart
ResponsiveLayout(
    MyBreakpoints(
        watch: Text('Watch'),
        phone: Text('Phone'),
        tablet: Text('Tablet'),
        desktop: Text('Desktop'),
        custom: { 1600: Text('>= 1600') },
    ),
);
```

When extending `BaseBreakpoints`, the first breakpoint size **must** be 0. This is enforced by the call to `super()` but make sure to have a 0 in the breakpoints list argument. The base class also enforces that the smallest breakpoint's Widget/value **must** not be null. Make sure to prevent any errors by using `required` for the smallest breakpoint argument in your extending class.

<br /><br />

## Responsive grid

Web developers will be familiar with the concept of a 12 column grid. This is a popular format for providing consistency in design that translates well to code. The columns can span any number of the 12 slots of the grid, offset to create space, and reorder independently of widget code order – all controllable with breakpoints to provide the best layout for the current screen. The toolkit provides a full-fledged responsive grid system including everything previously stated **as well as** auto-width and fill-width (filling remaining row space) columns with wrapping capabilities.

<br />

### `ResponsiveRow` Widget

A grid consists of a series of rows and columns. The `ResponsiveRow` Widget wraps a group of `ResponsiveColumn` objects that collectively represent a full grid. As with web-based grid systems like Bootstrap grid, a `ResponsiveRow` is not visually limited to a single run of items on the screen (like a Flutter Row Widget would be). This is important as you control how much space each column takes up as well as its offset, which allows for precise control of when Widgets wrap to prevent bad visuals and overflow errors.

A simple responsive row with a single column that takes up half the screen would be created like this:

```dart
ResponsiveRow(
    columns: [
        ResponsiveColumn.span(
            span: 6,
            child: Container(
                width: double.infinity,
                color: Colors.green,
                padding: EdgeInsets.all(16.0),
                child: Text('A column'),
            ),
        ),
    ],
);
```

A row lays out its columns in a left to right, top to bottom fashion. If the width of a column is too wide to fit on the same line as the previous columns, it will wrap to a new line. The following arguments to `ResponsiveRow` help to fully control how the columns are laid out. Many of these will be familiar as they also apply to the Flutter Widget, `Wrap`.

- `spacing`: The space between columns in the horizontal direction (default 0).
- `runSpacing`: The space between runs when columns wrap to a new line within the `ResponsiveRow` (default 0).
- `alignment`: How the remaining space in a run is distributed (default is `WrapAlignment.start`).
- `crossAxisAlignment`: How the columns within a run are aligned to one another vertically (default is `WrapCrossAlignment.start`).
- `runAlignment`: How the runs are aligned vertically within the `ResponsiveRow` when the total run height is less than the height of the row (default is `WrapAlignment.start`).
- `clipBehavior`: How to clip columns that fall outside row vertically (default is `Clip.none`).
- `breakOnConstraints`: When using columns with breakpoints, whether to use the parent constraints to determine breakpoints instead of screen width (default is `false`).

### `ResponsiveColumn`

`ResponsiveColumn` is actually definition of column rather than a Widget. It cannot be rendered independently of `ResponsiveRow`. Understanding columns, how they're sized and when they wrap is fundamental to taking full advantage of responsive grids.

#### Column types

There are 3 types of columns which match expectations set by other frameworks and also provide ultimate layout flexibility.

- Span: A column that **spans** a portion of a 12 column grid. A span of 6 would mean it consumes half the width of the row.
- Auto: A column that sizes itself to its child.
