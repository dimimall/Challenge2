//
//  UserLogin.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 19/11/26.
//

import Foundation

protocol UserLogin {
    func login(
        username: String,
        password: String,
        completion: @escaping (UserLoginResult) -> Void)
}

enum UserLoginResult {
    case success(User)
    case failure(Error)
}
