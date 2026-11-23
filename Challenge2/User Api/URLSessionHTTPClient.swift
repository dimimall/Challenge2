//
//  URLSessionHTTPClient.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 21/11/26.
//

import Foundation


class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func login(
        with request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        session.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
            } else if let data {
                completion(.success(data))
            } else {
                completion(.failure(URLError(.badServerResponse)))
            }
        }.resume()
    }
}
