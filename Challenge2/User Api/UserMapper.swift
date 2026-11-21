//
//  UserMapper.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 15/11/26.
//

import Foundation

final class UserMapper {
    private struct UserResponse: Decodable {
        let id: UUID
        let username: String
        let token: String
        let expiresIn: Int

        var user: User {
            User(
                id: id,
                username: username,
                token: token,
                expiresIn: expiresIn
            )
        }
    }

    static func map(
        data: Data,
        response: HTTPURLResponse
    ) throws -> User {
        guard response.statusCode == 200 else {
            throw RemoteUserLogin.Error.invalidData
        }

        return try JSONDecoder()
            .decode(UserResponse.self, from: data)
            .user
    }
}
