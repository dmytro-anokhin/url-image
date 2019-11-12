//
//  ImageProcessing.swift
//  URLImage
//  
//
//  Created by Dmytro Anokhin on 15/10/2019.
//  Copyright © 2019 Dmytro Anokhin. All rights reserved.
//

import CoreGraphics


public protocol ImageProcessing {

    func process(_ input: CGImage) -> CGImage
}
