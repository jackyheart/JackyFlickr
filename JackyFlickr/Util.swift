//
//  Util.swift
//  JackyFlickr
//
//  Created by Jacky on 24/1/17.
//
//

import UIKit

class Util: NSObject {

    //http://stackoverflow.com/questions/32163848/how-to-convert-string-to-md5-hash-using-ios-swift
    static func getMD5(string:String) -> Data? {
        
        guard let messageData = string.data(using:String.Encoding.utf8) else { return nil }
        
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    //http://stackoverflow.com/questions/26970807/implementing-hmac-and-sha1-encryption-in-swift
    static func getHmacSHA1(key: String, input: String) -> String {
        
        let ccHMacAlgorithm = CCHmacAlgorithm(kCCHmacAlgSHA1)
        let digestLen = CC_SHA1_DIGEST_LENGTH
        
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = input.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(digestLen))
        CCHmac(ccHMacAlgorithm, cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData:NSData = NSData(bytes: result, length: (Int(digestLen)))
        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
        return String(hmacBase64)
    }
    
    //http://stackoverflow.com/questions/39515173/how-to-use-unsafemutablepointer-in-swift-3
    static func getNonce() -> String {
    
        var data = Data(count: 64)
        _ = data.withUnsafeMutableBytes { (unsafeMutablePointer) in
            SecRandomCopyBytes(kSecRandomDefault, data.count, unsafeMutablePointer)
        }
        
        let base64String = data.base64EncodedString(options: Data.Base64EncodingOptions.endLineWithCarriageReturn)

        return base64String
    }
    
    //TODO
    static func random9DigitString() -> String {
        let min: UInt32 = 100_000_000
        let max: UInt32 = 999_999_999
        let i = min + arc4random_uniform(max - min + 1)
        return String(i)
    }
}