//
//  LocaleManager.swift
//  LocaleManager
//
//  Created by Amir Abbas Mousavian.
//  Copyright © 2018 Mousavian. Distributed under MIT license.
//

import UIKit
import ObjectiveC

// MARK: -Languages

/**
 This class handles changing locale/language on the fly, while change interface direction for right-to-left languages.
 
 To use, first call `LocaleManager.setup()` method in AppDelegate's `application(_:didFinishLaunchingWithOptions:)` method, then use
 `LocaleManager.apply(identifier:)` method to change locale.
 
 - Note: If you encounter a problem in updating localized strings (e.g. tabbar items' title) set `LocaleManager.updateHandler` variable to fix issue.
 
 - Important: Due to an underlying bug in iOS, if you have an image which should be flipped for RTL languages,
     don't use asset's direction property to mirror image,
     use `image.imageFlippedForRightToLeftLayoutDirection()` to initialize flippable image instead.
 
 - Important: If you used other libraries like maximbilan/ios_language_manager before, call `applyLocale(identifier: nil)`
     for the first time to remove remnants in order to avoid conflicting.
*/

public class LocaleManager: NSObject {
    /// This handler will be called after every change in language. You can change it to handle minor localization issues in user interface.
    @objc public static var updateHandler: () -> Void = {
        return
    }
    
    /**
     This handler will be called to get localized string before checking bundle. Allows custom translation for system strings.
     
     - Important: **DON'T USE** `NSLocalizedString()` inside the closure body. Use a `Dictionary` instead.
    */
    @objc public static var customTranslation: ((String) -> String?)? = nil
    
    /// Returns Base localization identifier
    @objc public class var base: String {
        return "Base"
    }
    
    /**
     Iterates all localization done by developer in app. It can be used to show available option for user.
     
     Key in returned dictionay can be used as identifer for passing to `apply(identifier:)`.
     
     Value is localized name of language according to current locale and should be shown in user interface.
     
     - Note: First item will be `Base` localization.
     
     - Return: A dictionary that keys are language identifiers and values are localized language name
    */
    @objc public class var availableLocalizations: [String: String] {
        let keys = Bundle.main.localizations
        let vals = keys.map({ Locale.userPreferred.localizedString(forIdentifier: $0) ?? $0 })
        return [String: String].init(zip(keys, vals), uniquingKeysWith: { v, _ in v })
    }
    
    /**
     Reloads all windows to apply orientation changes in user interface.
     
     - Important: storyboardIdentifier of root viewcontroller in Main.storyboard must set to a string.
    */
    internal class func reloadWindows(animated: Bool = true) {
        let windows = UIApplication.shared.windows
        for window in windows {
            if let storyboard = window.rootViewController?.storyboard, let id = window.rootViewController?.value(forKey: "storyboardIdentifier") as? String {
                window.rootViewController = storyboard.instantiateViewController(withIdentifier: id)
            }
            for view in (window.subviews) {
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
        if animated {
            windows.first.map {
                UIView.transition(with: $0, duration: 0.55, options: .transitionFlipFromLeft, animations: nil, completion: nil)
            }
        }
    }
    
    /**
     Overrides system-wide locale in application setting.
     
     - Parameter identifier: Locale identifier to be applied, e.g. `en`, `fa`, `de_DE`, etc.
     */
    private class func applyLocale(identifier: String) {
        UserDefaults.standard.set([identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        Locale.cachePreffered = nil
    }
    
    /// Removes user preferred locale and resets locale to system-wide.
    private class func removeLocale() {
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        
        // These keys are used in maximbilan/ios_language_manager and may conflict with this implementation.
        // We remove them here.
        UserDefaults.standard.removeObject(forKey: "AppleTextDirection")
        UserDefaults.standard.removeObject(forKey: "NSForceRightToLeftWritingDirection")
        
        UserDefaults.standard.synchronize()
        Locale.cachePreffered = nil
    }
    
    /**
     Overrides system-wide locale in application and reload.
     
     - Parameter identifier: Locale identifier to be applied, e.g. `en` or `fa_IR`. `nil` value will change locale to system-wide.
     */
    @objc public class func apply(identifier: String?, animated: Bool = true) {
        let semantic: UISemanticContentAttribute
        if let identifier = identifier {
            applyLocale(identifier: identifier)
            let locale = Locale(identifier: identifier)
            semantic = locale.isRTL ? .forceRightToLeft : .forceLeftToRight
        } else {
            removeLocale()
            semantic = .forceLeftToRight
        }
        UIView.appearance().semanticContentAttribute = semantic
        UITableView.appearance().semanticContentAttribute = semantic
        
        reloadWindows(animated: animated)
        updateHandler()
    }
    
    /**
     This method MUST be called in `application(_:didFinishLaunchingWithOptions:)` method.
     */
    @objc public class func setup() {
        // Allowing to update localized string on the fly.
        Bundle.swizzleMethod(#selector(Bundle.localizedString(forKey:value:table:)),
                             with: #selector(Bundle.mn_custom_localizedString(forKey:value:table:)))
        // Enforcing userInterfaceLayoutDirection based on selected locale. Fixes pop gesture in navigation controller.
        UIApplication.swizzleMethod(#selector(getter: UIApplication.userInterfaceLayoutDirection),
                                    with: #selector(getter: UIApplication.mn_custom_userInterfaceLayoutDirection))
        // Enforcing currect alignment for labels which has `.natural` direction.
        UILabel.swizzleMethod(#selector(UILabel.layoutSubviews), with: #selector(UILabel.mn_custom_layoutSubviews))
    }
}

public extension UILabel {
    private struct AssociatedKeys {
        static var originalAlignment = "lm_originalAlignment"
        static var forcedAlignment = "lm_forcedAlignment"
    }
    
    var originalAlignment: NSTextAlignment? {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.originalAlignment) as? Int).flatMap(NSTextAlignment.init(rawValue:))
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.originalAlignment,
                    newValue.rawValue as NSNumber,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
    
    public var forcedAlignment: NSTextAlignment? {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.forcedAlignment) as? Int).flatMap(NSTextAlignment.init(rawValue:))
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.forcedAlignment,
                    newValue.rawValue as NSNumber,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
    
    @objc internal func mn_custom_layoutSubviews() {
        if originalAlignment == nil {
            originalAlignment = self.textAlignment
        }
        
        if let forcedAlignment = forcedAlignment {
            self.textAlignment = forcedAlignment
        } else if originalAlignment == .natural {
            self.textAlignment = Locale._userPreferred.isRTL ? .right : .left
        }
        
        self.mn_custom_layoutSubviews()
    }
}

extension UIApplication {
    @objc var mn_custom_userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        get {
            let _ = self.mn_custom_userInterfaceLayoutDirection // DO NOT OPTIMZE!
            return Locale._userPreferred.isRTL ? .rightToLeft : .leftToRight
        }
    }
}

extension Bundle {
    private static var savedLanguageNames: [String: String] = [:]
    
    @objc func mn_custom_localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        
        func languageName(for lang: String) -> String? {
            if let langName = Bundle.savedLanguageNames[lang] {
                return langName
            }
            let langName = Locale(identifier: "en").localizedString(forLanguageCode: lang)
            Bundle.savedLanguageNames[lang] = langName
            return langName
        }
        
        if let customString = LocaleManager.customTranslation?(key) {
            return customString
        }
        
        let userPreferred = Locale._userPreferred.identifier
        let current = Locale.current.identifier
        let bundle: Bundle
        // Check for user preferred locale (e.g en_GB, ru)
        if let _path = self.path(forResource: userPreferred, ofType: "lproj") {
            bundle = Bundle(path: _path)!
        } else
        // Check for user preferred locale if system uses old naming (e.g English, Japanese)
        if let _path = languageName(for: userPreferred).flatMap({ self.path(forResource: $0, ofType: "lproj") }) {
            bundle = Bundle(path: _path)!
        } else
        // Check for system-defined current locale
        if let _path = self.path(forResource: current, ofType: "lproj") {
            bundle = Bundle(path: _path)!
        } else
        // Check for system-defined current locale if system uses old naming (e.g English, Japanese)
        if let _path = languageName(for: current).flatMap({ self.path(forResource: $0, ofType: "lproj") }) {
            bundle = Bundle(path: _path)!
        } else
        // Check for base locale ("Base")
        if let _path = self.path(forResource: LocaleManager.base, ofType: "lproj") {
            bundle = Bundle(path: _path)!
        // No bundle, returning passed string
        } else {
            return key
        }
        return (bundle.mn_custom_localizedString(forKey: key, value: value, table: tableName))
    }
}

public extension Locale {
    /**
     Caching prefered local to speed up as this method is called frequently in swizzled method.
     Must be set to nil when `AppleLanguages` has changed.
    */
    fileprivate static var cachePreffered: Locale?
    
    fileprivate static var _userPreferred: Locale {
        if let cachePreffered = cachePreffered {
            return cachePreffered
        }
        
        cachePreffered = userPreferred
        return cachePreffered!
    }
    
    public static var userPreferred: Locale {
        return Locale.preferredLanguages.first.map(Locale.init(identifier:)) ?? Locale.current
    }
    
    public var isRTL: Bool {
        return Locale.characterDirection(forLanguage: self.languageCode!) == .rightToLeft
    }
}

public extension NSLocale {
    @objc public class var userPreferred: Locale {
        return Locale.userPreferred
    }
    
    @objc public var isRTL: Bool {
        return (self as Locale).isRTL
    }
}

public extension NSNumber {
    @objc public func localized(precision: Int = 0, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = precision
        formatter.numberStyle = style
        formatter.locale = Locale.userPreferred
        return formatter.string(from: self)!
    }
}

public extension String {
    public func localizedFormat(_ args: CVarArg...) -> String {
        if args.isEmpty {
            return self
        }
        return String(format: self, locale: Locale.userPreferred, arguments: args)
    }
}

internal extension NSObject {
    @discardableResult
    class func swizzleMethod(_ selector: Selector, with withSelector: Selector) -> Bool {
        
        var originalMethod: Method?
        var swizzledMethod: Method?
        
        originalMethod = class_getInstanceMethod(self, selector)
        swizzledMethod = class_getInstanceMethod(self, withSelector)
        
        
        if (originalMethod != nil && swizzledMethod != nil) {
            if class_addMethod(self, selector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!)) {
                class_replaceMethod(self, withSelector, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
            } else {
                method_exchangeImplementations(originalMethod!, swizzledMethod!)
            }
            return true
        }
        return false
    }
    
    @discardableResult
    class func swizzleStaticMethod(_ selector: Selector, with withSelector: Selector) -> Bool {
        
        var originalMethod: Method?
        var swizzledMethod: Method?
        
        originalMethod = class_getClassMethod(self, selector)
        swizzledMethod = class_getClassMethod(self, withSelector)
        
        if (originalMethod != nil && swizzledMethod != nil) {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
            return true
        }
        return false
    }
}

