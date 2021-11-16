//
//  Data+.swift
//  dashloader-avplayer
//
//  Created by USER on 2021/11/10.
//

import Foundation

extension Data {
    var toString: Result<String, Error> {
        guard let result = String(data: self, encoding: .utf8) else {
            return .failure(SampleError.failedToString)
        }

        return .success(result)
    }
}
