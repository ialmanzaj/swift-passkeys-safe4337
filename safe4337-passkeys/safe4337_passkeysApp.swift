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
    private let pimlico = "https://api.pimlico.io/v2/11155111/rpc?apikey=pim_Yh43x8iEhJBoa3LEH5bVy2"
    private let rpcClient: EthereumHttpClient
    private let bundler: BundlerClient
    private let paymaster: PaymasterClient
    
    init() {
        let clientUrl = URL(string: "https://ethereum-sepolia-rpc.publicnode.com")!
        self.rpcClient = EthereumHttpClient(url: clientUrl, network: .sepolia)
        
        let bundlerUrl = URL(string: pimlico)!
        self.bundler = BundlerClient(url: bundlerUrl)
        
        let paymasterURL = URL(string: pimlico)!
        self.paymaster = PaymasterClient(url: paymasterURL)
    }
    
    @MainActor
    func setupSmartAccount() async {
        isLoading = true
        error = nil
        
        do {
            let keyStorage = EthereumKeyLocalStorage()
            // Private key signer
            let signer = try EthereumAccount.create(replacing: keyStorage, keystorePassword: "12345asa").toSigner()
            smartAccount = try await SafeAccount(signer: signer,
                                                     rpc: rpcClient,
                                                     bundler: bundler, 
                                                     paymaster: paymaster)
            // passkey signer
            let signerPasskey = try await SafePasskeySigner(domain: domain, 
                                                            name: "Zeneca 4337",
                                                            isSharedWebauthnSigner: false,
                                                            rpc: rpcClient)
            
            
            print("smartAccount 1 address", smartAccount?.address.asString())
            
            print("signer 1", smartAccount?.signer.address.asString())
            
            // This will deploy the Safe Webauthn Contract and add its address as the owner of the safe
            let userOpHash = try await smartAccount?.deployAndEnablePasskeySigner(
                x: signerPasskey.publicX,
                y: signerPasskey.publicY
            )
            
            print("userOpHash", userOpHash)
            // Now you can use the passkey signer with the safe. Specify the address of the smart account to use the same instance. Otherwise, it will calculate a new safe address based on the signer address
            smartAccount = try await SafeAccount(
                address: smartAccount?.address,
                signer: signerPasskey,
                rpc: rpcClient,
                bundler: bundler,
                paymaster: paymaster
            )
            
            print("smartAccount 2 address", smartAccount?.address.asString())
           
            print("signer 2", smartAccount?.signer.address.asString())

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func sendTransaction() async {
        print("sendTransaction")
        isLoading = true
        error = nil
        guard let smartAccount = smartAccount else {
            error = "Smart account not set up"
            print("Smart account not set up")
            return
        }
        

        let DEST_ADDRESS = "0x02C48c159FDfc1fC18BA0323D67061dE1dEA329F"
        do {
            
            let userOp = try await smartAccount.sendUserOperation(to: EthereumAddress(DEST_ADDRESS), value: BigUInt(1))
            print("sent ops", userOp)
            isLoading = false
        }catch {
            print(error)
            print("error sending user ops", error.localizedDescription)
            isLoading = false
        }
        
       
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
