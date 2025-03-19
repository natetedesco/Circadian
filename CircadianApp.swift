//
//  CircadianApp.swift
//  Circadian
//
//  Created by Developer on 3/18/25.
//

import SwiftUI

@main
struct CircadianApp: App {
    @State var model = Model()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .modifier(ContentContainerModifier())
        }
    }
}
