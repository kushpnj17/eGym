//
//  UserProfile.swift
//  eGym
//
//  Created by Aditya Patel on 10/30/25.
//

import Foundation

struct UserProfile: Codable {
  var onboardingCompleted: Bool = false
  var createdAt: Date? = nil        // set once on create (server timestamp)
}
