//
//  PersistenceKit
//
//  Copyright (c) 2018-Present Teknasyon Teknoloji.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// KeychainAccessibilityOption.
public enum KeychainAccessibilityOption: CaseIterable {

	/// The data in the keychain item can always be accessed regardless of whether the device is locked.
	case always

	/// The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on the device.
	case alwaysThisDeviceOnly

	/// The data in the keychain item can be accessed only while the device is unlocked by the user.
	case whenUnlocked

	/// The data in the keychain item can be accessed only while the device is unlocked by the user.
	case whenUnlockedThisDeviceOnly

	/// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
	case afterFirstUnlock

	/// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
	case afterFirstUnlockThisDeviceOnly

	/// The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on the device.
	case whenPasscodeSetThisDeviceOnly

	/// Create a `KeychainAccessibilityOption` from a `CFString` attribute object
	///
	/// - Parameter attribute: `CFString` attribute object.
	init?(attribute: CFString) {
		for item in KeychainAccessibilityOption.allCases where item.attribute == attribute {
			self = item
			return
		}
		return nil
	}

}

// MARK: - Helpers
internal extension KeychainAccessibilityOption {

	/// `CFString` attribute for a `KeychainAccessibilityOption`
	var attribute: CFString {
		switch self {
		case .always:
			return kSecAttrAccessibleAlways
		case .alwaysThisDeviceOnly:
			return kSecAttrAccessibleAlwaysThisDeviceOnly
		case .whenUnlocked:
			return kSecAttrAccessibleWhenUnlocked
		case .whenUnlockedThisDeviceOnly:
			return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
		case .afterFirstUnlock:
			return kSecAttrAccessibleAfterFirstUnlock
		case .afterFirstUnlockThisDeviceOnly:
			return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
		case .whenPasscodeSetThisDeviceOnly:
			return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
		}
	}

}
