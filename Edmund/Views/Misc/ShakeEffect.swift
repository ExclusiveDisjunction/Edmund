//
//  ShakeModifier.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/25/25.
//

import SwiftUI

struct ShakeEffect : GeometryEffect {
    var travelDistance: CGFloat = 8;
    var shakesPerUnit = 3;
    var animatableData: CGFloat;
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travelDistance * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
