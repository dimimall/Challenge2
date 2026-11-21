//
//  RemoteUserLogin.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 11/11/26.
//

import Foundation

class RemoteUserLogin: UserLogin {
    private let client: HTTPClient
    private let url: URL


    public enum Error: Swift.Error {
        case invalidCredentials
        case connectivity
        case invalidData
    }

    public typealias Result = UserLoginResult

    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    func login(username: String, password: String, completion: @escaping (UserLoginResult) -> Void) {
        let loginCredentials = LoginCredentials(username: username, password: password)
        guard !loginCredentials.username.isEmpty,
              !loginCredentials.password.isEmpty else {
            completion(.failure(RemoteUserLogin.Error.invalidCredentials))
            return
        }

        client.login(from: url, loginCredentials: loginCredentials) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data, response):
                do {
                    let user = try UserMapper.map(data: data, response: response)
                    completion(.success(user))
                } catch {
                    completion(.failure(Error.invalidData))
                }
            case .failure:
                completion(.failure(RemoteUserLogin.Error.connectivity))
            }
        }
    }

}
