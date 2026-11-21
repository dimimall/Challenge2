//
//  HttpClient.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 11/11/26.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

protocol HTTPClient {
    func login(from url: URL, loginCredentials: LoginCredentials, completion: @escaping (HTTPClientResult) -> Void)
}
