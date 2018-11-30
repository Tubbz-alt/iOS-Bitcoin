//
//  ECPublicKey.swift
//  Bitcoin
//
//  Created by Wolf McNally on 11/1/18.
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

public let ecCompressedPublicKeySize: Int = { return _ecCompressedPublicKeySize() }()
public let ecUncompressedPublicKeySize: Int = { return _ecUncompressedPublicKeySize() }()

public class ECPublicKey: ECKey {
    public func decompress() throws -> ECPublicKey {
        return self
    }

    public func compress() throws -> ECPublicKey {
        return self
    }
}

public final class ECCompressedPublicKey: ECPublicKey {
    public init(_ rawValue: Data) throws {
        guard rawValue.count == ecCompressedPublicKeySize else {
            throw BitcoinError.invalidDataSize
        }
        super.init(rawValue: rawValue)
    }

    required init(rawValue: Data) {
        fatalError("init(rawValue:) has not been implemented")
    }

    public override func decompress() throws -> ECPublicKey {
        return try! rawValue.withUnsafeBytes { (compressedBytes: UnsafePointer<UInt8>) in
            var uncompressed: UnsafeMutablePointer<UInt8>!
            var uncompressedLength = 0
            if let error = BitcoinError(rawValue: _decompress(compressedBytes, &uncompressed, &uncompressedLength)) {
                throw error
            }
            return try ECUncompressedPublicKey(receiveData(bytes: uncompressed, count: uncompressedLength))
        }
    }
}

public final class ECUncompressedPublicKey: ECPublicKey {
    public init(_ rawValue: Data) throws {
        guard rawValue.count == ecUncompressedPublicKeySize else {
            throw BitcoinError.invalidDataSize
        }
        super.init(rawValue: rawValue)
    }

    required init(rawValue: Data) {
        fatalError("init(rawValue:) has not been implemented")
    }

    public override func compress() throws -> ECPublicKey {
        return try! rawValue.withUnsafeBytes { (uncompressedBytes: UnsafePointer<UInt8>) in
            var compressed: UnsafeMutablePointer<UInt8>!
            var compressedLength = 0
            if let error = BitcoinError(rawValue: _compress(uncompressedBytes, &compressed, &compressedLength)) {
                throw error
            }
            return try ECCompressedPublicKey(receiveData(bytes: compressed, count: compressedLength))
        }
    }
}

public func toECPublicKey(_ data: Data) throws -> ECPublicKey {
    switch data.count {
    case ecCompressedPublicKeySize:
        return try ECCompressedPublicKey(data)
    case ecUncompressedPublicKeySize:
        return try ECUncompressedPublicKey(data)
    default:
        throw BitcoinError.invalidFormat
    }
}

/// Derive the EC public key of an EC private key.
///
/// This is a curried function suitable for use with the pipe operator.
public func toECPublicKey(isCompressed: Bool) -> (_ privateKey: ECPrivateKey) throws -> ECPublicKey {
    return { privateKey in
        return try privateKey.rawValue.withUnsafeBytes { (privateKeyBytes: UnsafePointer<UInt8>) in
            var publicKeyBytes: UnsafeMutablePointer<UInt8>!
            var publicKeyLength: Int = 0
            if let error = BitcoinError(rawValue: _toECPublicKey(privateKeyBytes, privateKey.rawValue.count, isCompressed, &publicKeyBytes, &publicKeyLength)) {
                throw error
            }
            let data = receiveData(bytes: publicKeyBytes, count: publicKeyLength)
            if isCompressed {
                return try ECCompressedPublicKey(data)
            } else {
                return try ECUncompressedPublicKey(data)
            }
        }
    }
}

/// Derive the compressed EC public key of an EC private key.
///
/// This is a single-argument function suitable for use with the pipe operator.
public func toECPublicKey(_ privateKey: ECPrivateKey) throws -> ECPublicKey {
    return try privateKey |> toECPublicKey(isCompressed: true)
}

public enum ECPaymentAddressVersion: UInt8 {
    case mainnetP2KH = 0x00
    case mainnetP2SH = 0x05
    case testnetP2KH = 0x6f
    case testnetP2SH = 0xc4
}

/// Convert an EC public key to a payment address.
public func toECPaymentAddress(version: ECPaymentAddressVersion) -> (_ publicKey: ECPublicKey) throws -> String {
    return { publicKey in
        return try publicKey.rawValue.withUnsafeBytes { (publicKeyBytes: UnsafePointer<UInt8>) in
            var addressBytes: UnsafeMutablePointer<Int8>!
            var addressLength: Int = 0
            if let error = BitcoinError(rawValue: _toECPaymentAddress(publicKeyBytes, publicKey.rawValue.count, version.rawValue, &addressBytes, &addressLength)) {
                throw error
            }
            return receiveString(bytes: addressBytes, count: addressLength)
        }
    }
}

public func decompress(_ key: ECPublicKey) throws -> ECPublicKey {
    return try key.decompress()
}

public func compress(_ key: ECPublicKey) throws -> ECPublicKey {
    return try key.compress()
}
