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
    
    @State private var balance: Double = 1200.00
       
       var body: some View {
           NavigationView {
               VStack(spacing: 20) {
                   if passkeyManager.isLoading {
                       ProgressView()
                   } else if let error = passkeyManager.error {
                       Text("Error: \(error)")
                           .foregroundColor(.red)
                   } else if passkeyManager.smartAccount != nil {
                       // Balance Card
                       VStack {
                           Text("$\(balance, specifier: "%.2f")")
                               .font(.system(size: 40, weight: .bold))
                               .foregroundColor(.white)
                           
                           Text("USDC")
                               .font(.subheadline)
                               .foregroundColor(.white.opacity(0.8))
                           
                           HStack(spacing: 20) {
                               Button(action: {
                                   Task {
                                       await passkeyManager.setupSmartAccount()
                                   }
                               }) {
                                   Text("Depositar")
                                       .foregroundColor(.white)
                                       .padding(.horizontal, 20)
                                       .padding(.vertical, 10)
                                       .background(Color.white.opacity(0.2))
                                       .cornerRadius(20)
                               }
                               
                               Button(action: {
                                   Task {
                                       await passkeyManager.sendTransaction()
                                   }
                               }) {
                                   Text("Enviar")
                                       .foregroundColor(.white)
                                       .padding(.horizontal, 20)
                                       .padding(.vertical, 10)
                                       .background(Color.white.opacity(0.2))
                                       .cornerRadius(20)
                               }
                           }
                       }
                       .frame(maxWidth: .infinity)
                       .padding()
                       .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                       .cornerRadius(20)
                       
                       // Transactions List
                       VStack(alignment: .leading, spacing: 10) {
                           Text("HOY")
                               .font(.caption)
                               .foregroundColor(.gray)
                           
                       }
                       .padding()
                   } else {
                       Text("Smart Account Not Set Up")
                           .font(.headline)
                       
                      
        
                   }
                   
                   Spacer()
               }
               .padding()
               .navigationBarItems(leading:
                   Image(systemName: "person.crop.circle")
                       .foregroundColor(.gray)
               )
           }
       }
}

#Preview {
    ContentView()
}
