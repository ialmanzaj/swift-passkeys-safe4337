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

@MainActor
class Swift4337Manager: ObservableObject {
    @Published private(set) var isInitialized = false {
            willSet {
                DispatchQueue.global().async {
                    self.objectWillChange.send()
                }
            }
        }
    @Published private(set) var smartAccount: SmartAccountProtocol?
    
    private let domain = "sample4337.cometh.io"
    
    func setupSmartAccount() async {
        Task{do {
                
    
            let clientUrl = URL(string: "https://ethereum-sepolia-rpc.publicnode.com")
            let rpcClient = EthereumHttpClient(url: clientUrl!, network: EthereumNetwork.sepolia)
            
            print("rpcClient ", rpcClient)
            
            // Replace these with your actual RPC and bundler setup
            let bundlerUrl = URL(string: "https://api.pimlico.io/v2/sepolia/rpc?apikey=pim_4KTiSnR1er1r772aBN9MWe")
            let bundler = BundlerClient(url: bundlerUrl!)
            
            print("bundler ", bundler)

            let passkey = try await requestPasskey()

            let keyStorage = EthereumKeyLocalStorage()
            //todo: request user for passkeys
            let signerEOA = try! EthereumAccount.init(keyStorage: keyStorage, keystorePassword: "12345").toSigner()
            
            print("signerEOA ", signerEOA)
            
            let smartAccountEOA = try await SafeAccount(signer: signerEOA, rpc: rpcClient, bundler: bundler)
            print("smartAccountEOA ", smartAccountEOA)
            // Now you can use the passkey signer with the safe. Specify the address of the smart account to use the same instance. Otherwise, it will calculate a new safe address based on the signer address
            smartAccount = try await SafeAccount(address: smartAccountEOA.address, signer: signerEOA, rpc: rpcClient, bundler: bundler)
            print("smartAccountEOA ", smartAccountEOA.address)
            
            let signerPasskey = try await SafePasskeySigner(domain: domain, name: "New", isSharedWebauthnSigner: false, rpc: rpcClient)
            
            // This will deploy the Safe Webauthn Contract and add its address as the owner of the safe
            let userOpHash = try await smartAccountEOA.deployAndEnablePasskeySigner(
                x: signerPasskey.publicX,
                y: signerPasskey.publicY
            )
            
            print("userOpHash", userOpHash)
            
            // Now you can use the passkey signer with the safe. Specify the address of the smart account to use the same instance. Otherwise, it will calculate a new safe address based on the signer address
            let smartAccountPasskeys = try await SafeAccount(address: smartAccount?.address, signer: signerPasskey, rpc: rpcClient, bundler: bundler)
            

            let smartAccountAddress = smartAccountPasskeys.address
            print("passkey - smartAccountAddress ", smartAccountAddress)
            
            
            await MainActor.run {
                self.smartAccount = smartAccount
                self.isInitialized = true
            }
        } catch {
            print("Error setting up Smart Account: \(error)")
            // Handle error appropriately
            await MainActor.run {
                                print("Error setting up Smart Account: \(error)")
                // Handle error appropriately, maybe update a published error property
            }
        }
        }
    }

       
    private func requestPasskey() async throws -> ASAuthorizationPlatformPublicKeyCredentialRegistration {
        let challenge = Data() // You should generate a proper challenge
        let userID = Data() // Generate a unique user ID
        
        let registrationRequest = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            .createCredentialRegistrationRequest(challenge: challenge, name: "User", userID: userID)
        
        let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
        return try await withCheckedThrowingContinuation { continuation in
            authController.delegate = PasskeyDelegate(continuation: continuation)
            authController.performRequests()
        }
    }
    
    private func createSignerFromPasskey(_ passkey: ASAuthorizationPlatformPublicKeyCredentialRegistration) async throws -> SignerProtocol {
        // Here you would create a signer using the passkey
        // This is a placeholder implementation

        let clientUrl = URL(string: "https://ethereum-sepolia-rpc.publicnode.com")
        let client = EthereumHttpClient(url: clientUrl!, network: EthereumNetwork.sepolia)
        
        let signerPasskey = try await SafePasskeySigner(domain: domain, name: "User Passkey", isSharedWebauthnSigner: false, rpc: client)
        return signerPasskey
    }
}

class PasskeyDelegate: NSObject, ASAuthorizationControllerDelegate {
    private var continuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>
    
    init(continuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration else {
            continuation.resume(throwing: NSError(domain: "PasskeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            return
        }
        continuation.resume(returning: credential)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

@main
struct safe4337_passkeysApp: App {
    @StateObject private var swift4337Manager = Swift4337Manager()
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
