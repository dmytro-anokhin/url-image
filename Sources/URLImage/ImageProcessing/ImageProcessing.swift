//
//  ImageProcessing.swift
//  
//
//  Created by Dmytro Anokhin on 15/10/2019.
//

import CoreGraphics


public protocol ImageProcessing {

    func process(_ input: CGImage) -> CGImage
}
