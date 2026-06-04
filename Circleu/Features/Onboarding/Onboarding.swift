//
//  Onboarding.swift
//  Circleu
//
//  Created by David Oyarekhua on 2/6/2026.
//

import SwiftUI

struct Frontpage: View{
    
    
    var body:some View{
        Text("First Page")
            .font(.title)
            .bold()
        Rectangle()
            .frame(width:120, height:40)
            .foregroundColor(.red)
    }
}

struct GuestView:View{
    var shirt:Color = Color.blue
    var body: some View{
        Circle()
            .frame(width:120)
        Rectangle()
            .frame(width:80, height:200)
            .foregroundStyle(shirt)
    }
}

#Preview{
    
}

