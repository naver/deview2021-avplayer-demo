//
//  SampleError.swift
//  dashloader-avplayer
//
//  Created by USER on 2021/09/25.
//

import Foundation

enum SampleError: Error {
    case unknown

    case failedToCreateM3U
    case failedToString
    case failedToData
}
