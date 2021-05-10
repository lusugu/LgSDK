//
//  LGWireframe.swift
//  LgBaseSDK
//
//  Created by 鲁术光 on 2021/5/10.
//

import UIKit
import RxSwift

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

enum RetryResult {
    case retry
    case cancel
}

protocol Wireframe {
    func open(url: URL)
    func promptFor<Action: CustomStringConvertible>(_ title: String,
                                                    _ message: String,
                                                    cancelAction: Action,
                                                    actions: [Action]) -> Observable<Action>
}

class DefaultWireframe: Wireframe {
    static let shared = DefaultWireframe()
    
    func open(url: URL) {
        #if os(iOS)
            UIApplication.shared.open(url)
        #elseif os(macOS)
            NSWorkspace.shared.open(url)
        #endif
    }
    
    #if os(iOS)
    private static func rootViewController() -> UIViewController {
        // cheating, I know
        return UIApplication.shared.keyWindow!.rootViewController!
    }
    #endif
    
    static func presentAlert(_ title: String, _ message: String) {
        #if os(iOS)
            let alertView = UIAlertController(title: title,
                                              message: message,
                                              preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "确定", style: .cancel) { _ in
            })
            rootViewController().present(alertView, animated: true, completion: nil)
        #endif
    }

    func promptFor<Action : CustomStringConvertible>(_ title: String,
                                                     _ message: String,
                                                     cancelAction: Action,
                                                     actions: [Action]) -> Observable<Action> {
        #if os(iOS)
        return Observable.create { observer in
            let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: cancelAction.description, style: .cancel) { _ in
                observer.on(.next(cancelAction))
            })

            for action in actions {
                alertView.addAction(UIAlertAction(title: action.description, style: .default) { _ in
                    observer.on(.next(action))
                })
            }

            DefaultWireframe.rootViewController().present(alertView, animated: true, completion: nil)

            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
        #elseif os(macOS)
            return Observable.error(NSError(domain: "Unimplemented", code: -1, userInfo: nil))
        #endif
    }
}

extension RetryResult : CustomStringConvertible {
    var description: String {
        switch self {
        case .retry:
            return "Retry"
        case .cancel:
            return "Cancel"
        }
    }
}

