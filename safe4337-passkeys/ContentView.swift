//
//  ContentView.swift
//  safe4337-passkeys
//
//  Created by Isaac Almanza on 08/20/24.
//

import SwiftUI
import swift4337

struct ContentView: View {
    @EnvironmentObject var swift4337Manager: Swift4337Manager

    var body: some View {
           if swift4337Manager.isInitialized, let account = swift4337Manager.smartAccount {
               Text("Smart Account Address: \(account.address)")
           } else {
               ProgressView("Initializing Smart Account...")
           }
       }
}

#Preview {
    ContentView()
}
