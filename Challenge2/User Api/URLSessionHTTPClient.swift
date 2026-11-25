//
//  URLSessionHTTPClient.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 21/11/26.
//

import Foundation


class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(
        from url: URL,
        loginCredentials: LoginCredentials,
        completion: @escaping (HTTPClientResult) -> Void
    ) {
        var request = URLRequest(url: url)
        print("url: \(url)")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "username": loginCredentials.username,
                "password": loginCredentials.password
            ])
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let response = response as? HTTPURLResponse {
                completion(.success(data ?? Data(), response))
            } else {
                completion(.failure(URLError(.badServerResponse)))
            }
        }.resume()
    }
}
