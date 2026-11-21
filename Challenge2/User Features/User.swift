//
//  User.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 15/11/26.
//

import Foundation

nonisolated struct User: Equatable {
    let id: UUID
    let username: String
    let token: String
    let expiresIn: Int
}
