//
//  HDPrivateKey.swift
//  Bitcoin
//
//  Created by Wolf McNally on 10/30/18.
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
import WolfFoundation

public enum HDKeyTag { }
public typealias HDKey = Tagged<HDKeyTag, String>

public func hdKey(_ string: String) -> HDKey { return HDKey(rawValue: string) }

public var minimumSeedSize: Int = {
    return _minimumSeedSize()
}()

public enum HDKeyVersion {
    case mainnet
    case testnet

    public var publicVersion: UInt32 {
        switch self {
        case .mainnet:
            return 0x0488B21E
        case .testnet:
            return 0x043587CF
        }
    }

    public var privateVersion: UInt32 {
        switch self {
        case .mainnet:
            return 0x0488ADE4
        case .testnet:
            return 0x04358394
        }
    }
}

/// Create a new HD (BIP32) private key from entropy.
public func newHDPrivateKey(version: HDKeyVersion) -> (_ seed: Data) throws -> HDKey {
    return { seed in
        var key: UnsafeMutablePointer<Int8>!
        var keyLength = 0
        try seed.withUnsafeBytes { (seedBytes: UnsafePointer<UInt8>) in
            if let error = BitcoinError(rawValue: _newHDPrivateKey(seedBytes, seed.count, version.privateVersion, &key, &keyLength)) {
                throw error
            }
        }
        return receiveString(bytes: key, count: keyLength) |> hdKey
    }
}

/// Derive a child HD (BIP32) private key from another HD private key.
public func deriveHDPrivateKey(isHardened: Bool, index: Int) -> (_ privateKey: HDKey) throws -> HDKey {
    return { privateKey in
        return try privateKey.rawValue.withCString { privateKeyString in
            var childKey: UnsafeMutablePointer<Int8>!
            var childKeyLength = 0
            if let error = BitcoinError(rawValue: _deriveHDPrivateKey(privateKeyString, index, isHardened, &childKey, &childKeyLength)) {
                throw error
            }
            return receiveString(bytes: childKey, count: childKeyLength) |> hdKey
        }
    }
}

/// Derive a child HD (BIP32) public key from another HD public or private key.
public func deriveHDPublicKey(isHardened: Bool, index: Int, version: HDKeyVersion = .mainnet) -> (_ key: HDKey) throws -> HDKey {
    return { parentKey in
        return try parentKey.rawValue.withCString { parentKeyString in
            var childPublicKey: UnsafeMutablePointer<Int8>!
            var childPublicKeyLength = 0
            if let error = BitcoinError(rawValue: _deriveHDPublicKey(parentKeyString, index, isHardened, version.publicVersion, version.privateVersion, &childPublicKey, &childPublicKeyLength)) {
                throw error
            }
            return receiveString(bytes: childPublicKey, count: childPublicKeyLength) |> hdKey
        }
    }
}

/// Derive the HD (BIP32) public key of a HD private key.
public func toHDPublicKey(version: HDKeyVersion) -> (_ privateKey: HDKey) throws -> HDKey {
    return { privateKey in
        return try privateKey.rawValue.withCString { privateKeyString in
            var publicKey: UnsafeMutablePointer<Int8>!
            var publicKeyLength = 0
            if let error = BitcoinError(rawValue: _toHDPublicKey(privateKeyString, version.publicVersion, &publicKey, &publicKeyLength)) {
                throw error
            }
            return receiveString(bytes: publicKey, count: publicKeyLength) |> hdKey
        }
    }
}

/// Derive the HD (BIP32) public key of a HD private key.
public func toHDPublicKey(_ privateKey: HDKey) throws -> HDKey {
    return try privateKey |> toHDPublicKey(version: .mainnet)
}

/// Convert a HD (BIP32) public or private key to the equivalent EC public or private key.
public func toECKey(version: HDKeyVersion) -> (_ hdKey: HDKey) throws -> ECKey {
    return { hdKey in
        try hdKey.rawValue.withCString { hdKeyString in
            var ecKey: UnsafeMutablePointer<UInt8>!
            var ecKeyLength = 0
            var isPrivate = false
            if let error = BitcoinError(rawValue: _toECKey(hdKeyString, version.publicVersion, version.privateVersion, &isPrivate, &ecKey, &ecKeyLength)) {
                throw error
            }
            let data = receiveData(bytes: ecKey, count: ecKeyLength)
            switch isPrivate {
            case true:
                return try ECPrivateKey(data)
            case false:
                return try ECCompressedPublicKey(data)
            }
        }
    }
}

/// Convert a HD (BIP32) public or private key to the equivalent EC public or private key.
public func toECKey(_ key: HDKey) throws -> ECKey {
    return try key |> toECKey(version: .mainnet)
}
