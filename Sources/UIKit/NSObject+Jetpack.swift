//
//  Created by Pavel Sharanda on 17.09.16.
//  Copyright © 2016. All rights reserved.
//

import Foundation

private var NSObject_jx_objects: UInt8 = 0

extension NSObject {
    
    private var jx_objects: NSMutableDictionary {
        switch (objc_getAssociatedObject(self, &NSObject_jx_objects) as? NSMutableDictionary) {
        case .some(let p):
            return p
        case .none:
            let dict = NSMutableDictionary()
            objc_setAssociatedObject(self, &NSObject_jx_objects, dict, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return dict
        }
    }
    
    public func jx_reset() {
        jx_objects.removeAllObjects()
    }
    
    public func jx_removeObject(forKey: String) {
        jx_objects.removeObject(forKey: forKey)
    }
    
    public func jx_lazyObject<U>(key: String, creator: (()->U)) -> U {
        if let val = jx_objects.object(forKey: key), let obj = val as? U {
            return obj
        } else {
            let object = creator()
            jx_objects.setObject(object, forKey: key as NSCopying)
            return object
        }
    }
}

extension Jetpack where Base: NSObject {
    
    public func makeReceiver<U>(key: String, _ action: @escaping (Base, U)->Void) -> Receiver<U> {
        return base.jx_lazyObject(key: key) {[unowned base] in
            return Receiver { value in
                action(base, value)
            }
        }
    }
    
    public func makeTargetActionObservable<U>(key: String,
                                           setup: (Base, AnyObject, Selector)->Void,
                                           cleanup: @escaping (Base, AnyObject, Selector)->Void,
                                           getter: @escaping (Base)->U) -> Observer<U> {
        return base.jx_lazyObject(key: key) { () -> SignalActionHandler<Base, U> in
            let controlHandler = SignalActionHandler(key: key, base: base, getter: getter, cleanup: cleanup)
            setup(base, controlHandler, #selector(SignalActionHandler<Base, U>.jx_handleAction))
            return controlHandler
        }.signal.asObserver
    }
    
    public func makeTargetActionProperty<T>(key: String,
                                         setup: (Base, AnyObject, Selector)->Void,
                                         cleanup: @escaping (Base, AnyObject, Selector)->Void,
                                         getter: @escaping (Base)->T) -> Property<T> {
        return base.jx_lazyObject(key: key) { () -> PropertyActionHandler<Base, T> in
            let controlHandler = PropertyActionHandler(key: key, base: base, getter: getter, cleanup: cleanup)
            setup(base, controlHandler, #selector(PropertyActionHandler<Base, T>.jx_handleAction))
            return controlHandler
        }.property
    }
}

extension NSObject: JetpackExtensionsProvider {}

fileprivate class SignalActionHandler<Base: AnyObject, T>: NSObject {
    
    let signal = Signal<T>()
    let getter: (Base)->T
    weak var base: Base?
    let key: String
    let cleanup: (Base, AnyObject, Selector)->Void
    
    init(key: String, base: Base, getter: @escaping (Base)->T, cleanup: @escaping (Base, AnyObject, Selector)->Void) {
        self.key = key
        self.getter = getter
        self.base = base
        self.cleanup = cleanup
    }
    
    @objc func jx_handleAction() {
        if let base = base {
            signal.update(getter(base))
        }
        
    }
    
    deinit {
        if let base = base {
            cleanup(base, self, #selector(jx_handleAction))
        }
    }
}

fileprivate class PropertyActionHandler<Base: AnyObject, T>: NSObject {
    
    let signal = Signal<T>()
    let property: Property<T>
    let getter: (Base) ->T
    weak var base: Base?
    let key: String
    let cleanup: (Base, AnyObject, Selector)->Void
    
    init(key: String, base: Base, getter: @escaping (Base)->T, cleanup: @escaping (Base, AnyObject, Selector)->Void) {
        self.key = key
        self.getter = getter
        self.base = base
        self.cleanup = cleanup
        property = Property(signal: signal) {
            getter(base)
        }
    }
    
    @objc func jx_handleAction() {
        if let base = base {
            signal.update(getter(base))
        }
    }
    
    deinit {
        if let base = base {
            cleanup(base, self, #selector(jx_handleAction))
        }
    }
}
