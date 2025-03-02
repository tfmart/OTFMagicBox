/*
Copyright (c) 2021, Hippocrates Technologies S.r.l.. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributor(s) may
be used to endorse or promote products derived from this software without specific
prior written permission. No license is granted to the trademarks of the copyright
holders even if such marks are included in this software.

4. Commercial redistribution in any form requires an explicit license agreement with the
copyright holder(s). Please contact support@hippocratestech.com for further information
regarding licensing.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
 */

import Foundation
import OTFCloudClientAPI

typealias AuthType = Request.SocialLogin.AuthType
typealias SocialType = Request.SocialLogin.SocialType

class OTFTheraforgeNetwork {
    
    static let shared = OTFTheraforgeNetwork()
    
    var otfNetworkService: TheraForgeNetwork!
    
    private init() {
        
        configureNetwork()
        
    }
    
    // Configure the API with required URL and API key.
    public func configureNetwork() {
        guard let url = URL(string: Constants.API.developmentUrl) else {
            OTFLog("Error: cannot create URL")
            return
        }
        
        let configurations = NetworkingLayer.Configurations(APIBaseURL: url, apiKey: YmlReader().apiKey)
        TheraForgeNetwork.configureNetwork(configurations)
        otfNetworkService = TheraForgeNetwork.shared
    }
    
    // Login request
    public func loginRequest(email: String, password: String,
                             completionHandler:  @escaping (Result<Response.Login, ForgeError>) -> Void) {
        otfNetworkService.login(request: OTFCloudClientAPI.Request.Login(email: email,
                                                                         password: password)) { [weak self] result in
            self?.handleResponse(result, completion: completionHandler)
        }
        
    }
    
    public func socialLoginRequest(userType: UserType,
                                   socialType: SocialType,
                                   authType: AuthType,
                                   idToken: String,
                                   completionHandler: @escaping (Result<Response.Login, ForgeError>) -> Void) {
        let socialRequest = OTFCloudClientAPI.Request.SocialLogin(userType: userType,
                                                                  socialType: socialType,
                                                                  authType: authType,
                                                                  identityToken: idToken)
        otfNetworkService.socialLogin(request: socialRequest) { [weak self] result in
            self?.handleResponse(result, completion: completionHandler)
        }
    }
    
    
    // Registration request
    // swiftlint:disable all
    public func signUpRequest(firstName: String, lastName: String, type: String, email: String,
                              password: String, dob: String, gender: String,
                              completionHandler:  @escaping (Result<Response.Login, ForgeError>) -> Void) {
        otfNetworkService.signup(request: OTFCloudClientAPI.Request.SignUp(email: email, password: password, first_name: firstName,
                                                                           last_name: lastName, type: .patient, dob: dob, gender: gender, phoneNo: "")) { [weak self] result in
            self?.handleResponse(result, completion: completionHandler)
        }
    }
    
    
    // delete user account
    public func deleteUser(userId: String,
                           completionHandler:  @escaping (Result<Response.DeleteAccount, ForgeError>) -> Void) {
        otfNetworkService.deleteAccount(request: Request.DeleteAccount(userId: userId)) { [weak self] result in
            
            switch result {
            case .success(_):
                self?.moveToOnboardingView()
            case .failure(let error):
                if error.error.statusCode == 410 {
                    self?.moveToOnboardingView()
                }
            }
        }
    }
    
    
    // Forgot password request
    public func forgotPassword(email: String, completionHandler:  @escaping (Result<Response.ForgotPassword, ForgeError>) -> Void) {
        otfNetworkService.forgotPassword(request: OTFCloudClientAPI.Request.ForgotPassword(email: email)) { [weak self] result in
            self?.handleResponse(result, completion: completionHandler)
        }
    }
    
    // Reset password request
    public func resetPassword(email: String, code: String, newPassword: String, completionHandler:  @escaping (Result<Response.ChangePassword, ForgeError>) -> Void) {
        otfNetworkService.resetPassword(request: OTFCloudClientAPI.Request.ResetPassword(email: email,
                                                                                         code: code,
                                                                                         newPassword: newPassword)) { [weak self] result in
            self?.handleResponse(result, completion: completionHandler)
        }
    }
    
    // Signout request.
    public func signOut(completionHandler: ((Result<Response.LogOut, ForgeError>) -> Void)?) {
        otfNetworkService.signOut(completionHandler: { [weak self] result in
            switch result {
            case .success(_):
                self?.moveToOnboardingView()
            case .failure(_):
                self?.handleResponse(result, completion: completionHandler)
            }
        })
    }
    
    // Change password request.
    public func changePassword(email: String, oldPassword: String, newPassword: String, completionHandler:  @escaping (Result<Response.ChangePassword, ForgeError>) -> Void) {
        otfNetworkService.changePassword(request: OTFCloudClientAPI.Request.ChangePassword(email: email, password: oldPassword, newPassword: newPassword), completionHandler: { [weak self] result in
            self?.handleResponse(result, completion: completionHandler)
        })
    }
    
    func refreshToken(_ completionHandler: @escaping (Result<Response.Login, ForgeError>) -> Void) {
        guard (TheraForgeKeychainService.shared.loadAuth() != nil) else {
            completionHandler(.failure(.missingCredential))
            return
        }
        
        otfNetworkService.refreshToken { [weak self] response in
            self?.handleResponse(response, completion: completionHandler)
        }
    }
    
    func disconnectFromSSE() {
        NetworkingLayer.shared.eventSource?.disconnect()
    }
    
    func handleResponse<T: Decodable>(_ response: Result<T, ForgeError>, completion: ((Result<T, ForgeError>) -> Void)?) {
        switch response {
        case .success(_):
            break
        case .failure(let error):
            if error.error.statusCode == 410 {
                DispatchQueue.main.async {
                    self.moveToOnboardingView()
                }
                return
            }
        }
        
        completion?(response)
    }
    
    public func moveToOnboardingView() {
        DispatchQueue.main.async {
            UserDefaultsManager.setOnboardingCompleted(false)
            try? CareKitManager.shared.wipe()
            self.disconnectFromSSE()
            NotificationCenter.default.post(name: .onboardingDidComplete, object: false)
        }
    }
}
