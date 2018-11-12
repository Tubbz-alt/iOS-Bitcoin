//
//  OutputPoint.swift
//  Bitcoin
//
//  Created by Wolf McNally on 11/8/18.
//
//  Copyright © 2018 Blockchain Commons.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import CBitcoin
import WolfPipe

/// An OutputPoint is a component of a transaction input, and specifies
/// the output of the previous transaction that is being spent.
public struct OutputPoint: InstanceContainer {
    var wrapped: WrappedInstance

    init(instance: OpaquePointer) {
        wrapped = WrappedInstance(instance)
    }

    public init() {
        self.init(instance: _outputPointNew())
    }

    public init(data: Data) throws {
        let instance = try data.withUnsafeBytes { (dataBytes: UnsafePointer<UInt8>) -> OpaquePointer in
            var instance: OpaquePointer!
            if let error = BitcoinError(rawValue: _outputPointFromData(dataBytes, data.count, &instance)) {
                throw error
            }
            return instance
        }
        self.init(instance: instance)
    }

    public var data: Data {
        var dataBytes: UnsafeMutablePointer<UInt8>!
        var dataLength = 0
        _outputPointToData(wrapped.instance, &dataBytes, &dataLength)
        return receiveData(bytes: dataBytes, count: dataLength)
    }

    public init(hash: HashDigest, index: UInt32) {
        self.init()
        self.hash = hash
        self.index = index
    }

    /// This is a sentinel used in `index` to indicate no output, e.g. coinbase.
    public static let nullIndex = UInt32.max

    public var index: UInt32 {
        get {
            return _outputPointGetIndex(wrapped.instance)
        }

        set {
            if !isKnownUniquelyReferenced(&wrapped) {
                wrapped = WrappedInstance(_outputPointCopy(wrapped.instance))
            }
            _outputPointSetIndex(wrapped.instance, newValue)
        }
    }

    public var hash: HashDigest {
        get {
            var hashBytes: UnsafeMutablePointer<UInt8>!
            var hashLength = 0
            _outputPointGetHash(wrapped.instance, &hashBytes, &hashLength)
            return try! receiveData(bytes: hashBytes, count: hashLength) |> toHashDigest
        }

        set {
            if !isKnownUniquelyReferenced(&wrapped) {
                wrapped = WrappedInstance(_outputPointCopy(wrapped.instance))
            }
            newValue.data.withUnsafeBytes { hashBytes in
                _outputPointSetHash(wrapped.instance, hashBytes)
            }
        }
    }

    public var isValid: Bool {
        return _outputPointIsValid(wrapped.instance)
    }
}

extension OutputPoint: CustomStringConvertible {
    public var description: String {
        return "OutputPoint(hash: \(hash), index: \(index))"
    }
}

extension OutputPoint: Equatable {
    public static func == (lhs: OutputPoint, rhs: OutputPoint) -> Bool {
        return _outputPointEqual(lhs.wrapped.instance, rhs.wrapped.instance);
    }
}
