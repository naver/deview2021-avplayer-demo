//
//  CustomLoader.swift
//  dashloader-avplayer
//
//  Created by 강성현 on 2021/11/03.
//

import Foundation

protocol CustomLoader {
    func loadResource(url: URL, completion: @escaping (Result<Data, Error>) -> Void)
}
