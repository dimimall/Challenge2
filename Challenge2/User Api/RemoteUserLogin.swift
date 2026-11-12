//
//  RemoteUserLogin.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 11/11/26.
//

import Foundation

class RemoteUserLogin {
    private let client: HTTPClient
    private let url: URL

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }

    func login(loginCredentials: LoginCredentials, completion: @escaping (Error) -> Void){
        guard !loginCredentials.username.isEmpty,
              !loginCredentials.password.isEmpty else {
            return
        }

        client.login(from: url, loginCredentials: loginCredentials) { result in

            switch result {
            case .success:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
        }
    }
}
