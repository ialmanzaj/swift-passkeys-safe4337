//
//  safe4337_passkeysApp.swift
//  safe4337-passkeys
//
//  Created by Isaac Almanza on 08/20/24.
//

import SwiftUI
import swift4337
import web3
import BigInt
import AuthenticationServices

class PasskeyManager: ObservableObject {
    @Published var smartAccount: SafeAccount?
    @Published var isLoading = false
    @Published var error: String?
    
    private let domain = "sample.zeneca.app"
    private let rpcClient: EthereumHttpClient
    private let bundler: BundlerClient
    
    init() {
        let clientUrl = URL(string: "https://ethereum-sepolia-rpc.publicnode.com")!
        self.rpcClient = EthereumHttpClient(url: clientUrl, network: .sepolia)
        
        let bundlerUrl = URL(string: "https://api.pimlico.io/v2/sepolia/rpc?apikey=pim_4KTiSnR1er1r772aBN9MWe")!
        self.bundler = BundlerClient(url: bundlerUrl)
    }
    
    @MainActor
    func setupSmartAccount() async {
        isLoading = true
        error = nil
        
        do {
            let signerPasskey = try await SafePasskeySigner(domain: domain, name: "New", isSharedWebauthnSigner: false, rpc: rpcClient)
            smartAccount = try await SafeAccount(signer: signerPasskey, rpc: rpcClient, bundler: bundler)
            print(smartAccount?.address)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func sendTransaction() async {
        guard let smartAccount = smartAccount else {
            error = "Smart account not set up"
            return
        }
        
        isLoading = true
        error = nil
        
       
    }
}


@main
struct safe4337_passkeysApp: App {
    @StateObject private var swift4337Manager = PasskeyManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(swift4337Manager)
                .task {
                    await swift4337Manager.setupSmartAccount()
                }
        }
    }
}
