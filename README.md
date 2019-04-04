# LocaleManager

This library handles changing locale/language on the fly.

User interface direction will be updated automatically for right-to-left languages.

<center>

[![Swift Version][swift-image]][swift-url]
[![Platform][platform-image]](#)
[![License][license-image]][license-url]
[![Release version][release-image]][release-url]

</center>

## Requirements

- Swift 5.0 or higher
- iOS 9.0
- XCode 10.2

## Installation

First you must clone this project from github:

```bash
git clone https://github.com/amosavian/LocaleManager
```

Then you can either install manually by adding `Sources/LocaleManager` directory to your project 
or create a `xcodeproj` file and add it as a dynamic framework:

```bash
swift package generate-xcodeproj
```

## Usage

### Initialization

First, Add this line to you AppDelegate class:

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Your initialization code here
        
        LocaleManager.setup()
        return true
    }

}

```

### Prepare storyboard

Set `Storyboard ID` for your root view controller in `Main.storyboard` to a non-nil string.

If you don't use storyboard, set `LocaleManager.rootViewController` to a closure or method that
returns an instance of root view controller of your application.

### Show available localizations to user

Your app should provide localizations' list to user.
You can fetch list of available localizations according to your project by:

```swift
let languages = LocaleManager.availableLocalizations
```

Now `languages` variable is a dictionary. If you don't have any localization, 
the dictionary will be `["Base": "Base"]`, all other localizations will be added after.

You must pass dictionary's key to `LocaleManager`'s methods, while dictionary values are localized name of corresponding key. 
E.g. "de" will be "German" for English environment while it will be "Deutsch" in German environment.

When user selected a localization, follow next step.

### Change localization on the fly

Nothing special here, just add following line:

```swift
let localeID = "fa"
LocaleManager.apply(identifier: localeID)
```

If you have `Locale` object instead of identifier:

```swift
let locale = Locale(identifier: "fa")
LocaleManager.apply(locale: locale)
```

This will cause a flip animation while changing language. If you don't want that:

```swift
let localeID = "en"
LocaleManager.apply(identifier: localeID, animated: false)
```

To remove any custom localization and allow iOS to select a localization according system language:

```swift
LocaleManager.apply(locale: nil)
```

If you used other libraries like [maximbilan/ios_language_manager](https://github.com/maximbilan/ios_language_manager) before,
call `LocaleManager.apply(locale: nil)` for the first time to remove remnants in order to avoid conflicting.

### Get active locale

```swift
let locale = Locale.userPreferred // e.g "en_US"
print(locale.languageCode)  // e.g "en"
```

### Localizing numbers

Numbers won't be localized by default, to show localized numbers:

```swift
// Int
let n = 10
label.text = (n as NSNumber).localized()

// Double with 2 fraction
let d = 10.12
label.text = (n as NSNumber).localized(precision: 2)

// Percentage
let d = 0.5 // 50%
label.text = (n as NSNumber).localized(style: .percent)
```


### Formatted strings (Swift only)

Using `NSLocalizedString()` method you can fetch localized string from `Localizable.strings` file.
In case the returned string is a formattable text, you can fill placeholders easily:

```swift
let completed = 10
let total = 15
let completedText = (completed as NSNumber).localized()
let totalText = = (total as NSNumber).localized()
let template = NSLocalizedString("Progress %@ out of %@ items", comment: "")
let formattedText = template.localizedFormat(completedText, totalText)
```

### Mirrored Images

Due to an underlying bug in iOS, if you have an image which should be flipped for RTL languages,
don't use asset's direction property to mirror image,
use `image.imageFlippedForRightToLeftLayoutDirection()` to initialize flippable image instead.

### Extra steps

If your app needs extra steps for updating interface (e.g. clearing caches), use `LocaleManager.updateHandler` property.

## Known issues

Check [Issues](https://github.com/amosavian/LocaleManager/issues) page.

## Contribute

We would love for you to contribute to LocaleManager, check the LICENSE file for more info.

[swift-image]: https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
[platform-image]: https://img.shields.io/badge/platform-ios-lightgray.svg
[license-image]: https://img.shields.io/github/license/amosavian/LocaleManager.svg
[license-url]: LICENSE
[release-url]: https://github.com/amosavian/FileProvider/releases
[release-image]: https://img.shields.io/github/release/amosavian/LocaleManager.svg

