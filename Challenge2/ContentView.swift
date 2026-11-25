//
//  ContentView.swift
//  Challenge2
//
//  Created by Dimitra Malliarou on 11/11/26.
//

import SwiftUI

struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 40)

            HStack {
                Image(systemName: "person.fill")

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
            }
            .padding()
            
            HStack {
                Image(systemName: "lock.fill")
                
                SecureField("Password", text: $password, onCommit: {
                    self.isSecure.toggle()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
            }
            .padding()

            Button(action: {
                isSecure.toggle()
            }) {
                Text(isSecure ? "Show Password" : "Hide Password")
                    .foregroundStyle(Color.blue)
            }
            .padding(.bottom, 20)

            Button(action: {

            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
            }
        }
        .padding()
    }

    func login() {
        // Add login action here
        print("Username: \(username), Password: \(password)")
    }
}

#Preview {
    ContentView()
}
