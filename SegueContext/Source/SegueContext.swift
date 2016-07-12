//
//  SegueContext.swift
//
//  Created by ToKoRo on 2015-07-14.
//

import UIKit

// MARK: - Context

public class Context {
    public let object: Any?
    public var callback: Any?
    public var segueIdentifier: String?

    public init<T>(object: T?) {
        self.object = object
    }

    public convenience init() {
        self.init(object: nil as Any?)
    }

    public convenience init(callback: Any?) {
        self.init(object: nil as Any?)
        self.callback = callback
    }

    public convenience init(anyCallback: Any) {
        self.init(object: nil as Any?)
        self.callback = anyCallback
    }

    public convenience init<T, A, R>(object: T?, callback: (A) -> R) {
        self.init(object: object)
        self.callback = callback
    }

    public subscript(key: String) -> Any? {
        get {
            if let dictionary = self.object as? [String : Any] {
                return dictionary[key]
            } else if let dictionary = self.object as? [String : AnyObject] {
                return dictionary[key]
            } else if let dictionary = self.object as? NSDictionary {
                return dictionary[key]
            } else {
                return nil
            }
        }
    }

    public subscript(index: Int) -> Any? {
        get {
            if let array = self.object as? [Any] {
                return array[index]
            } else if let array = self.object as? [AnyObject] {
                return array[index]
            } else if let array = self.object as? NSArray {
                return array[index]
            } else {
                return nil
            }
        }
    }

}

public func toContext(_ object: Any?) -> Context {
    if let context = object as? Context {
        return context
    } else {
        return Context(object: object)
    }
}

public func toContext(_ object1: Any?, _ object2: Any?, _ object3: Any? = nil, _ object4: Any? = nil, _ object5: Any? = nil) -> Context {
    var dict = [String : Any]()
    dict["1"] = object1
    dict["2"] = object2
    dict["3"] = object3
    dict["4"] = object4
    dict["5"] = object5
    let context = Context(object: dict)
    return context
}

// MARK: - PresentType

public enum PresentType {
    case popup
    case push
    case custom((UIViewController) -> Void)
}

// MARK: - UIViewController

extension UIViewController {

    struct CustomProperty {
        static var context = "CustomProperty.context"
        static var callback = "CustomProperty.callback"
        static var sendContext = "CustomProperty.sendContext"
        static var sendCallback = "CustomProperty.sendCallback"
    }

    public func contextValue<T>() -> T? {
        return self.customContext?.object as? T
    }

    public func contextValue<A, B>() -> (A?, B?) {
        if let context = self.customContext {
            let object1 = context["1"] as? A
            let object2 = context["2"] as? B
            return (object1, object2)
        }
        return (nil, nil)
    }

    public func contextValue<A, B, C>() -> (A?, B?, C?) {
        if let context = self.customContext {
            let object1 = context["1"] as? A
            let object2 = context["2"] as? B
            let object3 = context["3"] as? C
            return (object1, object2, object3)
        }
        return (nil, nil, nil)
    }

    public func contextValueForKey<T>(_ key: String) -> T? {
        return self.customContext?[key] as? T
    }

    public var rawCallback: Any? {
        if let customContextForCallback = self.customContextForCallback {
            return customContextForCallback.callback
        } else {
            return self.customContext?.callback
        }
    }

    public func callback<A, R>() -> ((A) -> R)? {
        if let callback = self.customContextForCallback?.callback as? ((A) -> R) {
            return callback
        } else {
            return self.customContext?.callback as? ((A) -> R)
        }
    }

    public private(set) var context: Context? {
        get {
            return self.customContext
        }
        set {
            self.customContext = context
        }
    }

    private var customContext: Context? {
        get {
            if let object: AnyObject = objc_getAssociatedObject(self, &CustomProperty.context) {
                if let context = object as? Context {
                    return context
                } else {
                    return Context(object: object)
                }
            }
            return nil
        }
        set {
            if let context = newValue {
                objc_setAssociatedObject(self, &CustomProperty.context, context, .OBJC_ASSOCIATION_RETAIN)
            } else {
                objc_setAssociatedObject(self, &CustomProperty.context, nil, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    private var customContextForCallback: Context? {
        get {
            if let object: AnyObject = objc_getAssociatedObject(self, &CustomProperty.callback) {
                if let context = object as? Context {
                    return context
                } else {
                    return Context(object: object)
                }
            }
            return nil
        }
        set {
            if let context = newValue {
                objc_setAssociatedObject(self, &CustomProperty.callback, context, .OBJC_ASSOCIATION_RETAIN)
            } else {
                objc_setAssociatedObject(self, &CustomProperty.callback, nil, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    private var sendCustomContext: Context? {
        get {
            if let object: AnyObject = objc_getAssociatedObject(self, &CustomProperty.sendContext) {
                if let context = object as? Context {
                    return context
                }
            }
            return nil
        }
        set {
            if let context = newValue {
                objc_setAssociatedObject(self, &CustomProperty.sendContext, context, .OBJC_ASSOCIATION_RETAIN)
            } else {
                objc_setAssociatedObject(self, &CustomProperty.sendContext, nil, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    private var sendCustomContextForCallback: Context? {
        get {
            if let object: AnyObject = objc_getAssociatedObject(self, &CustomProperty.sendCallback) {
                if let context = object as? Context {
                    return context
                }
            }
            return nil
        }
        set {
            if let context = newValue {
                objc_setAssociatedObject(self, &CustomProperty.sendCallback, context, .OBJC_ASSOCIATION_RETAIN)
            } else {
                objc_setAssociatedObject(self, &CustomProperty.sendCallback, nil, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }

    public func performSegue(withIdentifier identifier: String, sender: AnyObject? = nil, context: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender, context: context, callback: nil)
    }

    public func performSegue(withIdentifier identifier: String, sender: AnyObject? = nil, callback: Any?) {
        self.performSegue(withIdentifier: identifier, sender: sender, context: nil, callback: callback)
    }

    public func performSegue(withIdentifier identifier: String, sender: AnyObject? = nil, context: Any?, callback: Any?) {
        objc_sync_enter(self.dynamicType)

        self.replacePrepareForSegueIfNeeded()

        let customContext: Context
        if let context = context as? Context {
            customContext = context
        } else {
            customContext = Context(object: context)
        }
        customContext.segueIdentifier = identifier
        self.sendCustomContext = customContext

        let customContextForCallback = Context(callback: callback)
        customContextForCallback.segueIdentifier = identifier
        self.sendCustomContextForCallback = customContextForCallback

        self.performSegue(withIdentifier: identifier, sender: sender)

        objc_sync_exit(self.dynamicType)
    }

    public func present(storyboardName: String, viewControllerIdentifier: String? = nil, bundle: Bundle? = nil, animated: Bool = true, transitionStyle: UIModalTransitionStyle? = nil, context: Any? = nil, callback: Any? = nil) {
        self.present(presentType: .popup, storyboardName: storyboardName, viewControllerIdentifier: viewControllerIdentifier, bundle: bundle, animated: animated, transitionStyle: transitionStyle, context: context, callback: callback)
    }

    public func present(withViewControllerIdentifier viewControllerIdentifier: String, animated: Bool = true, transitionStyle: UIModalTransitionStyle? = nil, context: Any? = nil, callback: Any? = nil) {
        if let storyboard = self.storyboard {
            self.present(storyboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, animated: animated, transitionStyle: transitionStyle, context: context, callback: callback)
        }
    }

    public func present(storyboard: UIStoryboard, viewControllerIdentifier: String? = nil, animated: Bool = true, transitionStyle: UIModalTransitionStyle? = nil, context: Any? = nil, callback: Any? = nil) {
        self.present(presentType: .popup, storyboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, animated: animated, transitionStyle: transitionStyle, context: context, callback: callback)
    }

    public func pushViewController(withStoryboardName storyboardName: String, viewControllerIdentifier: String? = nil, bundle: Bundle? = nil, animated: Bool = true, context: Any? = nil, callback: Any? = nil) {
        self.present(presentType: .push, storyboardName: storyboardName, viewControllerIdentifier: viewControllerIdentifier, bundle: bundle, animated: animated, context: context, callback: callback)
    }

    public func pushViewController(withViewControllerIdentifier viewControllerIdentifier: String, animated: Bool = true, context: Any? = nil, callback: Any? = nil) {
        if let storyboard = self.storyboard {
            self.pushViewController(withStoryboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, animated: animated, context: context, callback: callback)
        }
    }

    public func pushViewController(withStoryboard storyboard: UIStoryboard, viewControllerIdentifier: String? = nil, animated: Bool = true, context: Any? = nil, callback: Any? = nil) {
        self.present(presentType: .push, storyboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, animated: animated, context: context, callback: callback)
    }

    public func present(presentType type: PresentType, storyboardName: String, viewControllerIdentifier: String? = nil, bundle: Bundle? = nil, animated: Bool = true, transitionStyle: UIModalTransitionStyle? = nil, context: Any? = nil, callback: Any? = nil) {
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        self.present(presentType: type, storyboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, animated: animated, transitionStyle: transitionStyle, context: context, callback: callback)
    }

    private var _navigationController: UINavigationController? {
        if let navi = self.navigationController {
            return navi
        } else if let navi = self.parent as? UINavigationController {
            return navi
        } else if let navi = self.presentingViewController as? UINavigationController {
            return navi
        } else if let tabBarController = self as? UITabBarController {
            if let navi = tabBarController.selectedViewController as? UINavigationController {
                return navi
            } else if let navi = tabBarController.selectedViewController?.navigationController {
                return navi
            }
        }
        return nil
    }

    public func present(presentType type: PresentType, storyboard: UIStoryboard, viewControllerIdentifier: String? = nil, animated: Bool = true, transitionStyle: UIModalTransitionStyle? = nil, context: Any? = nil, callback: Any? = nil) {
        guard let viewController = UIViewController.viewController(fromStoryboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, context: context, callback: callback) else {
            return
        }

        switch type {
        case .push:
            _navigationController?.pushViewController(viewController, animated: animated)
        case .custom(let customFunction):
            customFunction(viewController)
        default:
            if let transitionStyle = transitionStyle {
                viewController.modalTransitionStyle = transitionStyle
            }
            self.present(viewController, animated: animated, completion: nil)
        }
    }

    public class func viewController(fromStoryboardName storyboardName: String, viewControllerIdentifier: String? = nil, bundle: Bundle? = nil, context: Any? = nil, callback: Any? = nil) -> UIViewController? {
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        return self.viewController(fromStoryboard: storyboard, viewControllerIdentifier: viewControllerIdentifier, context: context, callback: callback)
    }

    public class func viewController(fromStoryboard storyboard: UIStoryboard, viewControllerIdentifier: String? = nil, context: Any? = nil, callback: Any? = nil) -> UIViewController? {
        let viewController: UIViewController?
        if let viewControllerIdentifier = viewControllerIdentifier {
            viewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        } else {
            viewController = storyboard.instantiateInitialViewController()
        }
        if let viewController = viewController {
            if let context = context as? Context {
                viewController.configureCustomContext(context)
            } else if let context = context {
                let customContext = Context(object: context)
                viewController.configureCustomContext(customContext)
            }
            if let callback = callback {
                let context = Context(callback: callback)
                viewController.configureCustomContext(forCallback: context)
            }
        }
        return viewController
    }

    public func sendContext(_ object1: Any?, _ object2: Any?, _ object3: Any? = nil, _ object4: Any? = nil, _ object5: Any? = nil) -> Context {
        return self.sendContext(toContext(object1, object2, object3, object4, object5))
    }

    public func sendContext(_ object: Any?) -> Context {
        let context = toContext(object)
        self.configureCustomContext(context)
        return context
    }

    private func configureCustomContext(_ customContext: Context) {
        let viewController = self
        viewController.customContext = customContext
        for viewController in viewController.childViewControllers {
            viewController.configureCustomContext(customContext)
        }
        if let navi = viewController as? UINavigationController {
            if let viewController = navi.viewControllers.first {
                viewController.configureCustomContext(customContext)
            }
        } else if let tab = viewController as? UITabBarController {
            if let viewControllers = tab.viewControllers {
                for viewController in viewControllers {
                    viewController.configureCustomContext(customContext)
                }
            }
        }
    }

    private func configureCustomContext(forCallback customContextForCallback: Context) {
        let viewController = self
        viewController.customContextForCallback = customContextForCallback
        for viewController in viewController.childViewControllers {
            viewController.configureCustomContext(forCallback: customContextForCallback)
        }
        if let navi = viewController as? UINavigationController {
            if let viewController = navi.viewControllers.first {
                viewController.configureCustomContext(forCallback: customContextForCallback)
            }
        } else if let tab = viewController as? UITabBarController {
            if let viewControllers = tab.viewControllers {
                for viewController in viewControllers {
                    viewController.configureCustomContext(forCallback: customContextForCallback)
                }
            }
        }
    }

}

// MARK: - Swizzling

var SWCSwizzledAlready: UInt8 = 0

extension UIViewController {

    public func contextSender(forSegue segue: UIStoryboardSegue, callback: (String, UIViewController, (Any?) -> Void) -> Void) {
        if let segueIdentifier = segue.identifier {
            let viewController = segue.destinationViewController
            let sendContext: (Any?) -> Void = { context in
                let _ = viewController.sendContext(context)
            }
            callback(segueIdentifier, viewController, sendContext)
        }
    }

    class func replacePrepareForSegueIfNeeded() {
        if nil == objc_getAssociatedObject(self, &SWCSwizzledAlready) {
            objc_setAssociatedObject(self, &SWCSwizzledAlready, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let original = class_getInstanceMethod(self, #selector(prepare(for:sender:)))
            let replaced = class_getInstanceMethod(self, #selector(swc_wrapped_prepareForSegue(_:sender:)))
            method_exchangeImplementations(original, replaced)
        }
    }

    class func revertReplacedPrepareForSegueIfNeeded() {
        if nil != objc_getAssociatedObject(self, &SWCSwizzledAlready) {
            objc_setAssociatedObject(self, &SWCSwizzledAlready, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let original = class_getInstanceMethod(self, #selector(prepare(for:sender:)))
            let replaced = class_getInstanceMethod(self, #selector(swc_wrapped_prepareForSegue(_:sender:)))
            method_exchangeImplementations(original, replaced)
        }
    }

    func replacePrepareForSegueIfNeeded() {
        self.dynamicType.replacePrepareForSegueIfNeeded()
    }

    func revertReplacedPrepareForSegueIfNeeded() {
        self.dynamicType.revertReplacedPrepareForSegueIfNeeded()
    }

    func swc_wrapped_prepareForSegue(_ segue: UIStoryboardSegue, sender: AnyObject?) {
        self.swc_wrapped_prepareForSegue(segue, sender: sender)
        self.swc_prepareForSegue(segue, sender: sender)

        self.revertReplacedPrepareForSegueIfNeeded()
    }

    func swc_prepareForSegue(_ segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController
        let source = segue.sourceViewController
        if let customContext = source.sendCustomContext {
            if let targetIdentifier = customContext.segueIdentifier where targetIdentifier != segue.identifier {
                return
            }

            destination.configureCustomContext(customContext)
            source.sendCustomContext = nil
        }
        if let customContextForCallback = source.sendCustomContextForCallback {
            if let targetIdentifier = customContextForCallback.segueIdentifier where targetIdentifier != segue.identifier {
                return
            }

            destination.configureCustomContext(forCallback: customContextForCallback)
            source.sendCustomContextForCallback = nil
        }
    }

}
