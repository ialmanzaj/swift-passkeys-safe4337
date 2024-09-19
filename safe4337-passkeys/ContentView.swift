//
//  ContentView.swift
//  safe4337-passkeys
//
//  Created by Isaac Almanza on 08/20/24.
//

import SwiftUI
import swift4337

struct ContentView: View {
    @EnvironmentObject var passkeyManager: PasskeyManager

    var body: some View {
            VStack {
                if passkeyManager.isLoading {
                    ProgressView()
                } else if let error = passkeyManager.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if passkeyManager.smartAccount != nil {
                    Text("Smart Account Set Up")
                    Button("Send Transaction") {
                        Task {
                            await passkeyManager.sendTransaction()
                        }
                    }
                } else {
                    Text("Smart Account Not Set Up")
                }
            }
            .padding()
        }
}

#Preview {
    ContentView()
}
