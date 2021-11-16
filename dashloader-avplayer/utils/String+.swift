//
//  String+.swift
//  dashloader-avplayer
//
//  Created by USER on 2021/11/10.
//

import Foundation

extension String {
    var toData: Result<Data, Error> {
        guard let data = data(using: .utf8) else {
            return .failure(SampleError.failedToData)
        }

        return .success(data)
    }
}
