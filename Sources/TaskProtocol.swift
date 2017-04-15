//
//  TaskProtocol.swift
//  Jetpack
//
//  Created by Pavel Sharanda on 12.04.17.
//  Copyright © 2017 Jetpack. All rights reserved.
//

import Foundation

public protocol TaskProtocol {
    associatedtype ResultValueType
    func start(_ completion: @escaping (Result<ResultValueType>) -> Void) -> Disposable
}

extension TaskProtocol {
    public var asObserver: Observer<Result<ResultValueType>> {
        return Observer { observer in
            return self.start(observer)
        }
    }
}
