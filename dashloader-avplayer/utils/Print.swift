//
//  Print.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/09/09.
//

import Foundation

extension Error {
    func printDescription() {
        print("\nError occurred: \(self.localizedDescription)")
        let nsError = self as NSError
        print("Domain: \(nsError.domain)")
        print("Code: \(nsError.code)\n")
    }
}
