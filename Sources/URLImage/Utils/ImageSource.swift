//
//  ImageSource.swift
//  
//
//  Created by Dmytro Anokhin on 12/11/2019.
//

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif


#if canImport(Cocoa)
import Cocoa
#endif


func preferredFileExtension(forTypeIdentifier uti: String) -> String? {
    UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeUnretainedValue() as String?
}
