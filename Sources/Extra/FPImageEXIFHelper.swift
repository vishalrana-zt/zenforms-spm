
//
//  FPImageEXIFHelper.swift
//  crm
//
//  Created by Claude Code
//  Copyright © 2026 SmartServ. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

/// Helper class for preserving EXIF metadata when converting UIImage to Data
class FPImageEXIFHelper {
    
    /// Adds EXIF metadata to image data
    /// - Parameters:
    ///   - imageData: The image data without metadata
    ///   - metadata: The EXIF metadata dictionary from UIImagePickerController
    /// - Returns: Image data with EXIF metadata embedded, or original data if operation fails
    static func addEXIFMetadata(to imageData: Data, metadata: [String: Any]) -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            return imageData
        }
        
        let mutableData = NSMutableData(data: imageData)
        guard let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else {
            return imageData
        }
        
        // Add image with metadata
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return imageData
        }
        
        return mutableData as Data
    }
    
    /// Converts UIImage to JPEG data while preserving EXIF metadata from camera
    /// - Parameters:
    ///   - image: The UIImage to convert
    ///   - metadata: Optional EXIF metadata from UIImagePickerController (camera only)
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: JPEG data with EXIF metadata if provided, or without if metadata is nil
    static func jpegData(from image: UIImage, metadata: [String: Any]?, compressionQuality: CGFloat = 1.0) -> Data? {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        // If no metadata provided, return original data
        guard let metadata = metadata else {
            return imageData
        }
        
        // Add EXIF metadata to the image data
        return addEXIFMetadata(to: imageData, metadata: metadata)
    }
}
